#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

###### Must be manually updated according with your values
USER="ykumarbekov"
BUCKET="ykumarbekov-534348"
SG_EC2="yk-ec2-534348"
#############################################
INSTANCE_TYPE="m4.large"
INSTANCE_CORE_CNT="2"
TABLE="fraud-ip-"${USER}
EMR_ROLE=${USER}"-emr-role"
KEY="test-emr-key"
#############################################

echo "Creating EMR role..."
test -z $(aws iam get-role --role-name ${EMR_ROLE} --output text --query Role.RoleName 2>/dev/null) && \
  aws iam create-role --role-name ${EMR_ROLE} \
  --assume-role-policy-document file://aws/roles/policies/emr_trust_policy.json && \
  aws iam put-role-policy --role-name ${EMR_ROLE} \
  --policy-name "emr_access" --policy-document file://aws/roles/policies/emr_access.json
echo "Finished"

groupID=$(aws ec2 describe-security-groups --group-names ${SG_EC2} \
--output text --query SecurityGroups[0].GroupId 2>/dev/null)

echo "Creating EMR Cluster..."
clusterID=$(aws emr create-cluster \
--name "${USER}-emr-cluster" \
--release-label emr-5.30.0 \
--instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=${INSTANCE_TYPE} InstanceGroupType=CORE,\
InstanceCount=${INSTANCE_CORE_CNT},InstanceType=${INSTANCE_TYPE} \
--applications Name=Spark Name=Zeppelin \
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

echo "Adding Spark job..."
stepID=$(aws emr add-steps --cluster-id ${clusterID} \
--steps Type=spark,Name=Fraud_ip_job,\
Args=[--deploy-mode,cluster,--master,yarn,\
s3://${BUCKET}/emr/code/fraud_ip_job_ec2.py,\
s3://${BUCKET}/logs/views/,\
s3://${BUCKET}/emr/result/],\
ActionOnFailure=CONTINUE)
stepID=$(echo ${stepID}|cut -f 2 -d " ")
echo "Running..."
aws emr wait step-complete --cluster-id ${clusterID} --step-id ${stepID}
echo "Finished"

echo "Uploading ip to dynamoDB table..."
python3 aws/emr/csv2dynamodb.py --bucket ${BUCKET} --input-key emr/result/ --table ${TABLE}
echo "Finished"

# Terminating cluster
echo "Terminating cluster..."
aws emr terminate-clusters --cluster-ids ${clusterID}
aws emr wait cluster-terminated --cluster-id ${clusterID}
echo "Finished"






