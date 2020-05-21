#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
# export AWS_DEFAULT_REGION="us-east-1"

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
aws iam remove-role-from-instance-profile --instance-profile-name ${USER}"-aws-course-profile" --role-name ${ROLE} # > /dev/null 2>&1
aws iam delete-instance-profile --instance-profile-name ${USER}"-aws-course-profile" # > /dev/null 2>&1
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
--security-groups ${SG} \
--user-data file://aws/configurator.sh \
--tag-specification \
'ResourceType=instance, Tags=[{Key=Name, Value='${USER}'-aws-course}]' \
--query 'Instances[*].InstanceId')
echo "Initializing..."
aws ec2 wait instance-status-ok --instance-ids $InstanceID
echo "Finished"

# echo "InstanceID: "$InstanceID

# Associate Instance Profile
# InstanceIdArray=$(aws ec2 describe-instances --output json \
#--filters Name=tag-key,Values=Name Name=tag-value,Values=${USER}'-aws-course' \
#--query 'to_string(Reservations[*].Instances[*].InstanceId)'|tr -d "\133\135\134\042"|tr "\054" "  ")
echo "Associating Profile with Instance..."
aws ec2 associate-iam-instance-profile --iam-instance-profile Name=${USER}"-aws-course-profile" --instance-id $InstanceID
echo "Finished"

# Bucket creating
echo "Re-Creating Bucket and Folders: logs/views & logs/reviews"
if aws s3api head-bucket --bucket $BUCKET 2>/dev/null
then
  aws s3 rb delete-bucket --bucket $BUCKET --force
fi
aws s3api create-bucket --bucket $BUCKET
aws s3api put-object --bucket $BUCKET --key "logs/views/"
aws s3api put-object --bucket $BUCKET --key "logs/reviews/"
echo "Finished"
