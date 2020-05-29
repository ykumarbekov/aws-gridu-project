#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

###### Must be manually updated according with your values
USER="ykumarbekov"
AUTH_FOLDER="./auth"
SG_EC2="yk-ec2-534348"
BUCKET="ykumarbekov-534348"
ROLE="YKUMARBEKOV_EC2"
TABLE="fraud-ip-"${USER}
#############################################

# Check auth folder and password file
test ! -e ${AUTH_FOLDER} && echo "Folder ${AUTH_FOLDER} does not exist. Please create it before running script" && exit -1

# Test if not exists - create Security Group
echo "Creating Security Group for EC2..."
test -z $(aws ec2 describe-security-groups --group-names ${SG_EC2} \
--output json --query SecurityGroups[0].GroupId 2>/dev/null) && aws ec2 create-security-group \
--group-name ${SG_EC2} --description "${USER} EC2 launch" && \
aws ec2 authorize-security-group-ingress --group-name ${SG_EC2} --protocol tcp --port 22 --cidr 0.0.0.0/0

# Create EC2 key pair
echo "Creating EC2 key pair..."
aws ec2 delete-key-pair --key-name ${USER}"-aws-course-emr" && rm -f ${AUTH_FOLDER}"/"${USER}"-aws-course-emr.pem" > /dev/null 2>&1
aws ec2 create-key-pair --key-name ${USER}"-aws-course-emr" --query 'KeyMaterial' --output text  > ${AUTH_FOLDER}"/"${USER}"-aws-course-emr.pem"
chmod 400 ${AUTH_FOLDER}"/"${USER}"-aws-course-emr.pem"
echo "Finished"

echo "Creating EC2 instance..."
InstanceID=$(aws ec2 run-instances \
--image-id ami-0915e09cc7ceee3ab \
--count 1 \
--instance-type t2.micro \
--key-name ${USER}"-aws-course-emr" \
--security-groups ${SG_EC2} \
--user-data file://aws/emr/emr_ec2_configurator.sh \
--tag-specification \
'ResourceType=instance, Tags=[{Key=Name, Value='${USER}'-aws-course-emr}]' \
--query 'Instances[*].InstanceId')
echo "Initializing..."
aws ec2 wait instance-status-ok --instance-ids $InstanceID
echo "Finished"

# Associate Instance Profile
echo "Associating Profile with Instance..."
aws ec2 associate-iam-instance-profile --iam-instance-profile Name=${USER}"-aws-course-profile" --instance-id $InstanceID
echo "Finished"

DNS=$(aws ec2 describe-instances --output text \
--filters Name=tag-key,Values=Name Name=tag-value,Values=${USER}-aws-course-emr \
--query 'Reservations[*].Instances[*].PublicDnsName')

# echo ${DNS}
# Running Spark job
echo "Running Spark Job..."
ssh -o StrictHostKeyChecking=no \
ec2-user@${DNS} -i ${AUTH_FOLDER}"/"${USER}"-aws-course-emr.pem" \
"/opt/spark-2.4.5/bin/spark-submit \
--packages com.amazonaws:aws-java-sdk-pom:1.10.34,org.apache.hadoop:hadoop-aws:2.6.0 \
/opt/aws-gridu-project/aws/emr/fraud_ip_job_ec2.py s3a://${BUCKET}/logs/views/ ${TABLE}" > /dev/null 2>&1
echo "Finished"

# Uploading Spark result to DynamoDB
echo "Uploading to DynamoDB..."
# python3 aws/emr/csv2dynamodb.py --bucket ${BUCKET} --input-key emr/result/fraud_ip --table ${TABLE}
echo "Finished"

echo "Terminating EC2 instance..."
# aws ec2 terminate-instances --instance-ids $InstanceID
# aws ec2 wait instance-terminated --instance-ids $InstanceID
echo "Finished"

## s3a://${BUCKET}/emr/result/fraud_ip/