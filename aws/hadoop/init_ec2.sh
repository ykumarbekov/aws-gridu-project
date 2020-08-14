#!/bin/bash

if [ -z $AWS_PROFILE ] ||
   [ -z $AWS_DEFAULT_REGION ] ||
   [ -z $USER ] ||
   [ -z $BUCKET ]; then
echo -e "Before running this script you should set next environment variables:\n\
1.AWS_PROFILE\n\
2.AWS_DEFAULT_REGION\n\
3.USER, default AWS user\n\
4.BUCKET, default bucket\n\
Use export command to set it correctly"
exit -1
fi

#############################################
SG_EC2=${USER}"-sg-ec2"
AUTH_FOLDER="./auth"
ROLE_EC2=${USER}"-ec2-role"
KEY=${USER}"-ec2-hadoop"
INSTANCE_PROFILE=${USER}"-ec2-profile"
INSTANCE_TYPE="t3.micro"
IMAGE_AMI="ami-02354e95b39ca8dec"
#############################################

echo "Creating EC2 key pair..."
aws ec2 delete-key-pair --key-name ${KEY} && rm -f ${AUTH_FOLDER}"/${KEY}.pem" > /dev/null 2>&1
aws ec2 create-key-pair --key-name ${KEY} --query 'KeyMaterial' --output text  > ${AUTH_FOLDER}"/${KEY}.pem"
chmod 400 ${AUTH_FOLDER}"/${KEY}.pem"
echo "Finished"

echo "Creating EC2 role..."
test -z $(aws iam get-role --role-name ${ROLE_EC2} --output text --query Role.RoleName 2>/dev/null) && \
aws iam create-role --role-name ${ROLE_EC2} \
  --assume-role-policy-document file://aws/roles/policies/ec2_trust_policy.json && \
aws iam put-role-policy --role-name ${ROLE_EC2} \
  --policy-name "ec2_access" --policy-document file://aws/roles/policies/ec2_access.json
echo "Finished"

echo "Creating Security Group for EC2"
x=$(aws ec2 describe-security-groups --group-names ${SG_EC2} --output text --query SecurityGroups[0].GroupId 2>/dev/null)
test -n ${x} && aws ec2 delete-security-group --group-name ${SG_EC2}
aws ec2 create-security-group --group-name ${SG_EC2} --description "${USER} EC2 launch" && \
aws ec2 authorize-security-group-ingress --group-name ${SG_EC2} --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "Finished"

echo "Opening additional ports: HDFS: 50070; YARN RESOURCE MANAGER: 8088"
read -p "Please enter your public IP ADDRESS, visit: https://www.showmyip.com/ :" ip
test -z ${ip} && echo "Cannot identify IP address" && exit 1
test -z $(echo ${ip}|grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b") && echo "Incorrect IP address" && exit 1
aws ec2 authorize-security-group-ingress --group-name ${SG_EC2} --protocol tcp --port 8088 --cidr ${ip}"/32" 2>/dev/null
aws ec2 authorize-security-group-ingress --group-name ${SG_EC2} --protocol tcp --port 50070 --cidr ${ip}"/32" 2>/dev/null

echo "Creating Instance Profile & Attaching ROLE_EC2..."
test ! -z $(aws iam get-instance-profile \
--instance-profile-name ${INSTANCE_PROFILE} \
--output text --query InstanceProfile.InstanceProfileName 2>/dev/null) && \
aws iam remove-role-from-instance-profile --instance-profile-name ${INSTANCE_PROFILE} \
--role-name ${ROLE_EC2} && \
aws iam delete-instance-profile --instance-profile-name ${INSTANCE_PROFILE}
aws iam create-instance-profile --instance-profile-name ${INSTANCE_PROFILE}
aws iam add-role-to-instance-profile --instance-profile-name ${INSTANCE_PROFILE} --role-name ${ROLE_EC2}
echo "Finished"

echo "Creating EC2 instance..."
InstanceID=$(aws ec2 run-instances \
--image-id ${IMAGE_AMI} \
--count 1 \
--instance-type ${INSTANCE_TYPE} \
--key-name ${KEY} \
--security-groups ${SG_EC2} \
--user-data file://aws/hadoop/configurator_ec2_hadoop.sh \
--tag-specification \
'ResourceType=instance, Tags=[{Key=Name, Value='${USER}'-ec2-hadoop}]' \
--query 'Instances[*].InstanceId')
echo "Initializing..."
aws ec2 wait instance-status-ok --instance-ids $InstanceID
echo "Finished"

echo "Associating Profile with Instance..."
aws ec2 associate-iam-instance-profile --iam-instance-profile Name=${INSTANCE_PROFILE} --instance-id $InstanceID
echo "Finished"
