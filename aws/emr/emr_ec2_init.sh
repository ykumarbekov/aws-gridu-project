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
#############################################

# Check auth folder and password file
test ! -e ${AUTH_FOLDER} && echo "Folder ${AUTH_FOLDER} does not exist. Please create it before running script" && exit -1
test ! -e ${AUTH_FOLDER}"/pwd.id" && echo "File pwd.id not found" && exit -1

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



