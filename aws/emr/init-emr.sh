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
INSTANCE_TYPE="m4.large"
INSTANCE_CORE_CNT="2"
EMR_ROLE=${USER}"-emr-role"
KEY=${USER}"-emr-key"
AUTH_FOLDER="./auth"
#############################################

echo "Creating EMR key pair..."
aws ec2 delete-key-pair --key-name ${KEY} && rm -f ${AUTH_FOLDER}"/${KEY}.pem" > /dev/null 2>&1
aws ec2 create-key-pair --key-name ${KEY} --query 'KeyMaterial' --output text  > ${AUTH_FOLDER}"/${KEY}.pem"
chmod 400 ${AUTH_FOLDER}"/${KEY}.pem"
echo "Finished"

echo "Creating EMR role..."
test -z $(aws iam get-role --role-name ${EMR_ROLE} --output text --query Role.RoleName 2>/dev/null) && \
  aws iam create-role --role-name ${EMR_ROLE} \
  --assume-role-policy-document file://aws/roles/policies/emr_trust_policy.json && \
  aws iam put-role-policy --role-name ${EMR_ROLE} \
  --policy-name "emr_access" --policy-document file://aws/roles/policies/emr_access.json
echo "Finished"

echo "Creating Security Group for EC2"
test -z $(aws ec2 describe-security-groups --group-names ${SG_EC2} \
--output json --query SecurityGroups[0].GroupId 2>/dev/null) && \
aws ec2 create-security-group --group-name ${SG_EC2} --description "${USER} EC2 security" && \
aws ec2 authorize-security-group-ingress --group-name ${SG_EC2} --protocol tcp --port 22 --cidr 0.0.0.0/0
#aws ec2 authorize-security-group-ingress --group-name ${SG_EC2} --protocol tcp --port 8088 --cidr 0.0.0.0/0 && \
#aws ec2 authorize-security-group-ingress --group-name ${SG_EC2} --protocol tcp --port 8090 --cidr 0.0.0.0/0
echo "Finished"

groupID=$(aws ec2 describe-security-groups --group-names ${SG_EC2} \
--output text --query SecurityGroups[0].GroupId 2>/dev/null)

echo "Creating EMR Cluster..."
clusterID=$(aws emr create-cluster \
--name "${USER}-emr-cluster" \
--release-label emr-5.30.0 \
--instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=${INSTANCE_TYPE} InstanceGroupType=CORE,\
InstanceCount=${INSTANCE_CORE_CNT},InstanceType=${INSTANCE_TYPE} \
--applications Name=Spark Name=Hadoop \
--service-role ${EMR_ROLE} \
--ec2-attributes InstanceProfile=EMR_EC2_DefaultRole,KeyName=${KEY},EmrManagedMasterSecurityGroup=${groupID},\
EmrManagedSlaveSecurityGroup=${groupID} \
--no-visible-to-all-users \
--log-uri s3://${BUCKET}/emr/logs/ \
--output text \
--query 'ClusterId')
echo "Initializing..."
aws emr wait cluster-running --cluster-id ${clusterID}
echo "Finished"







