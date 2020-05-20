#!/bin/bash

export AWS_PROFILE="aws-gridu"

USER="ykumarbekov"
AUTH_FOLDER="./auth"
SG="yk-ec2-534348"
BUCKET="ykumarbekov-534348"

test ! -e ${AUTH_FOLDER} && echo "Folder ${AUTH_FOLDER} not exist" && exit -1

# Create EC2 key pair
# aws ec2 create-key-pair --key-name ${USER}"_key" --output text  > ${AUTH_FOLDER}"/"${USER}"_keypair.pem"
# chmod 400 ${AUTH_FOLDER}"/"${USER}"_keypair.pem"

# Create security group
# aws ec2 create-security-group --group-name ${SG} --description "${USER} EC2 launch" > ./aws/sg.id
# SG_ID=$(cat ./aws/sg.id)
SG_ID="sg-0359b23eed93728bd"
######## Manually add rule for SSH local Access
######## Manually create role YKUMARBEKOV_EC2, Assign Policy: S3 BUCKET FULL ACCESS

# Create EC2 instance, Tag: ykumarbekov-gridu
aws ec2 run-instances \
--image-id ami-0915e09cc7ceee3ab \
--count 1 \
--instance-type t1.micro \
--key-name ${USER}"_key" --security-groups ${SG}
