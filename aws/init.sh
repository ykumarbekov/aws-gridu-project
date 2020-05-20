#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"

USER="ykumarbekov"
AUTH_FOLDER="./auth"
SG="yk-ec2-534348"
BUCKET="ykumarbekov-534348"
ROLE="YKUMARBEKOV_EC2"

test ! -e ${AUTH_FOLDER} && echo "Folder ${AUTH_FOLDER} not exist" && exit -1

# Create EC2 key pair
aws ec2 delete-key-pair --key-name ${USER}"-aws-course" && rm ${AUTH_FOLDER}"/"${USER}"-aws-course.pem" > /dev/null 2>&1
aws ec2 create-key-pair --key-name ${USER}"-aws-course" --query 'KeyMaterial' --output text  > ${AUTH_FOLDER}"/"${USER}"-aws-course.pem"
chmod 400 ${AUTH_FOLDER}"/"${USER}"-aws-course.pem"

# Create security group
# aws ec2 create-security-group --group-name ${SG} --description "${USER} EC2 launch"

######## Manually add rule for SSH local Access
######## Manually create role YKUMARBEKOV_EC2, Assign Policy: S3 BUCKET FULL ACCESS

# Create EC2 instance, Tag: ykumarbekov-gridu
aws ec2 run-instances \
--image-id ami-0915e09cc7ceee3ab \
--count 1 \
--instance-type t1.micro \
--key-name ${USER}"-aws-course" \
--security-groups ${SG} \
--user-data file://configurator \
--tag-specification \
'ResourceType=instance, Tags=[{Key=name, Value='${USER}'-aws-course}]'
