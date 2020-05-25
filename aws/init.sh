#!/bin/bash

#############################################
# Script for Initializing AWS Infructure for Big Data course
# 1. Be sure you installed AWS CLI and configured AWS_PROFILE: aws-gridu
# 2. Manually create IAM ROLES: {USER_NAME}_EC2, Assign Policy: S3 BUCKET FULL ACCESS
# 3. Edit script variables, according with your values
# 4. Create folder: auth, add file pwd.id (this file contains necessary logins and passwords)
#    Rules for pwd.id:
#    - Every row contains information in the columns: 1st: service type; 2nd: username; 3rd: password
#    - Example: rds user password
#############################################

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

###### Must be manually updated according with your values
USER="ykumarbekov"
AUTH_FOLDER="./auth"
SG_EC2="yk-ec2-534348"
SG_RDS="yk-rds-534348"
BUCKET="ykumarbekov-534348"
ROLE="YKUMARBEKOV_EC2"
#############################################

# Check auth folder and password file
test ! -e ${AUTH_FOLDER} && echo "Folder ${AUTH_FOLDER} does not exist. Please create it before running script" && exit -1
test ! -e ${AUTH_FOLDER}"/pwd.id" && echo "File pwd.id not found" && exit -1

# Creating Security Groups
echo "Creating Security Groups for EC2, RDS..."
test -z $(aws ec2 describe-security-groups --group-names ${SG_EC2} \
--output json --query SecurityGroups[0].GroupId 2>/dev/null) && aws ec2 create-security-group \
--group-name ${SG_EC2} --description "${USER} EC2 launch" && \
aws ec2 authorize-security-group-ingress --group-name ${SG_EC2} --protocol tcp --port 22 --cidr 0.0.0.0/0
# ##########
test -z $(aws ec2 describe-security-groups --group-names ${SG_RDS} \
--output json --query SecurityGroups[0].GroupId 2>/dev/null) && aws ec2 create-security-group \
--group-name ${SG_RDS} --description "${USER} RDS connections" && \
aws ec2 authorize-security-group-ingress --group-name ${SG_RDS} --protocol tcp --port 5432 --source-group ${SG_EC2}
echo "Finished"

# Bucket creating
echo "Re-Creating Bucket and Folders: logs/[views, reviews]; config; emr/[logs]"
if aws s3api head-bucket --bucket $BUCKET 2>/dev/null
then
  aws s3 rb s3://$BUCKET --force
fi
aws s3api create-bucket --bucket $BUCKET
aws s3api put-object --bucket $BUCKET --key "logs/views/"
aws s3api put-object --bucket $BUCKET --key "logs/reviews/"
aws s3api put-object --bucket $BUCKET --key "config/"
aws s3api put-object --bucket $BUCKET --key "emr/logs/"
aws s3 cp aws/fraud_ip_job.py s3://$BUCKET/emr/code/
echo "Finished"

# Creating RDS: PostgreSQL
##### Do not edit these values!
RDS_USER=$(cat ${AUTH_FOLDER}"/pwd.id"|tr "\n" "|"|awk -F "|" '{ split($1,v," "); if (v[1]=="rds") { print v[2] }}')
RDS_PWD=$(cat ${AUTH_FOLDER}"/pwd.id"|tr "\n" "|"|awk -F "|" '{ split($1,v," "); if (v[1]=="rds") { print v[3] }}')
(test -z ${RDS_USER} || test -z ${RDS_PWD}) && echo "Empty RDS_USER or/and RDS_PWD" && exit -1

SG_RDS_ID=$(aws ec2 describe-security-groups \
--group-names ${SG_RDS} --output json --query SecurityGroups[0].GroupId|tr -d "\042")

echo "Deleting RDS instance..."
test ! -z $(aws rds describe-db-instances --db-instance-identifier rds-aws-${USER} --output json 2>/dev/null) && \
aws rds delete-db-instance \
--db-instance-identifier rds-aws-${USER} \
--skip-final-snapshot \
--delete-automated-backups
aws rds wait db-instance-deleted --db-instance-identifier rds-aws-${USER}
echo "Finished"

echo "Creating RDS instance..."
aws rds create-db-instance \
--allocated-storage 20 --db-instance-class db.t2.micro \
--db-instance-identifier rds-aws-${USER} \
--db-name db1 \
--port 5432 \
--backup-retention-period 0 \
--vpc-security-group-ids ${SG_RDS_ID} \
--engine postgres \
--master-username ${RDS_USER} \
--master-user-password ${RDS_PWD} 1>/dev/null
echo "Initializing..."
aws rds wait db-instance-available --db-instance-identifier rds-aws-${USER}
echo "Finished"

echo $(aws rds describe-db-instances \
--db-instance-identifier rds-aws-${USER} \
--output text \
--query DBInstances[0].Endpoint.Address)"|"${RDS_USER}"|"${RDS_PWD}|aws s3 cp - s3://${BUCKET}/config/rds.id

# Create EC2 key pair
echo "Creating EC2 key pair..."
aws ec2 delete-key-pair --key-name ${USER}"-aws-course" && rm -f ${AUTH_FOLDER}"/"${USER}"-aws-course.pem" > /dev/null 2>&1
aws ec2 create-key-pair --key-name ${USER}"-aws-course" --query 'KeyMaterial' --output text  > ${AUTH_FOLDER}"/"${USER}"-aws-course.pem"
chmod 400 ${AUTH_FOLDER}"/"${USER}"-aws-course.pem"
echo "Finished"

# Create Instance profile
echo "Creating Instance Profile & Attaching ROLE..."
aws iam remove-role-from-instance-profile --instance-profile-name ${USER}"-aws-course-profile" --role-name ${ROLE}
aws iam delete-instance-profile --instance-profile-name ${USER}"-aws-course-profile"
aws iam create-instance-profile --instance-profile-name ${USER}"-aws-course-profile"
# Attach Role:
aws iam add-role-to-instance-profile --instance-profile-name ${USER}"-aws-course-profile" --role-name ${ROLE}
echo "Finished"
# Create EC2 instance
echo "Creating EC2 instance..."
InstanceID=$(aws ec2 run-instances \
--image-id ami-0915e09cc7ceee3ab \
--count 1 \
--instance-type t2.micro \
--key-name ${USER}"-aws-course" \
--security-groups ${SG_EC2} \
--user-data file://aws/configurator.sh \
--tag-specification \
'ResourceType=instance, Tags=[{Key=Name, Value='${USER}'-aws-course}]' \
--query 'Instances[*].InstanceId')
echo "Initializing..."
aws ec2 wait instance-status-ok --instance-ids $InstanceID
echo "Finished"

# Associate Instance Profile
echo "Associating Profile with Instance..."
aws ec2 associate-iam-instance-profile --iam-instance-profile Name=${USER}"-aws-course-profile" --instance-id $InstanceID
echo "Finished"

echo "Creating DynamoDB table..."
test -z $(aws dynamodb describe-table --table-name fraud-ip-${USER} --output json \
--query Table.TableName 2>/dev/null) && aws dynamodb create-table \
--table-name fraud-ip-${USER} \
--attribute-definitions AttributeName=ip,AttributeType=S \
--key-schema AttributeName=ip,KeyType=HASH \
--provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 1>/dev/null
echo "Initializing..."
aws dynamodb wait table-exists --table-name fraud-ip-${USER}
echo "Finished"
