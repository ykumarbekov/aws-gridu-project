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
echo "Creating EC2 key pair..."
aws ec2 delete-key-pair --key-name ${USER}"-aws-course" && rm -f ${AUTH_FOLDER}"/"${USER}"-aws-course.pem" > /dev/null 2>&1
aws ec2 create-key-pair --key-name ${USER}"-aws-course" --query 'KeyMaterial' --output text  > ${AUTH_FOLDER}"/"${USER}"-aws-course.pem"
chmod 400 ${AUTH_FOLDER}"/"${USER}"-aws-course.pem"
echo "Finished"

# Create security group
# aws ec2 create-security-group --group-name ${SG} --description "${USER} EC2 launch"

######## Manually add rule for SSH local Access
######## Manually create role YKUMARBEKOV_EC2, Assign Policy: S3 BUCKET FULL ACCESS

# Create Instance profile
echo "Creating Instance Profile & Attaching ROLE..."
aws iam delete-instance-profile --instance-profile-name ${USER}"-aws-course-profile" > /dev/null 2>&1
aws iam create-instance-profile --instance-profile-name ${USER}"-aws-course-profile"
# Attach Role:
aws iam add-role-to-instance-profile --instance-profile-name ${USER}"-aws-course-profile" --role-name ${ROLE}
echo "Finished"
# Create EC2 instance, Tag: ykumarbekov-gridu
echo "Creating EC2 instance..."
aws ec2 run-instances \
--image-id ami-0915e09cc7ceee3ab \
--count 1 \
--instance-type t2.micro \
--key-name ${USER}"-aws-course" \
--security-groups ${SG} \
--user-data file://aws/configurator.sh \
--tag-specification \
'ResourceType=instance, Tags=[{Key=Name, Value='${USER}'-aws-course}]' > /dev/null 2>&1
echo "Finished"

# Associate Instance Profile
# Get instance ID: aws ec2 describe-instances --filters "Name=tag-key,Values=${USER}"-aws-course-profile"
# https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html
# aws ec2 associate-iam-instance-profile --iam-instance-profile Name=${USER}"-aws-course-profile" --instance-id i-012345678910abcde

