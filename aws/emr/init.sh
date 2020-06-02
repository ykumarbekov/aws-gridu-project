#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

###### Must be manually updated according with your values
USER="ykumarbekov"
INSTANCE_TYPE="m4.large"
INSTANCE_CORE_CNT="1"
BUCKET="ykumarbekov-534348"
TABLE="fraud-ip-"${USER}
#############################################

echo "Creating EMR Cluster..."
clusterID=$(aws emr create-cluster \
--name "test-emr-cluster" \
--release-label emr-5.30.0 \
--instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=${INSTANCE_TYPE} InstanceGroupType=CORE,\
InstanceCount=${INSTANCE_CORE_CNT},InstanceType=${INSTANCE_TYPE} \
--applications Name=Spark Name=Zeppelin \
--use-default-roles \
--log-uri s3://${BUCKET}/emr/logs/ \
--output json \
--query 'ClusterId'|tr -d "\042")
echo "Initializing..."
aws emr wait cluster-running --cluster-id ${clusterID}
echo "Finished"

echo "Adding Spark job..."
stepID=$(aws emr add-steps --cluster-id ${clusterID} \
--steps Type=spark,Name=Fraud_ip_job,\
Args=[--deploy-mode,cluster,--master,yarn,\
--conf,spark.yarn.submit.waitAppCompletion=false,\
--num-executors,2,\
--executor-cores,2,\
--executor-memory,4g,\
s3://${BUCKET}/emr/code/fraud_ip_job_ec2.py,\
s3://${BUCKET}/logs/views/,\
s3://${BUCKET}/emr/result/],\
ActionOnFailure=CONTINUE)
stepID=$(echo ${stepID}|cut -f 2 -d " ")
echo "Running..."
aws emr wait step-complete --cluster-id ${clusterID} --step-id ${stepID}
echo "Finished"

# Uploading IP to DynamoDB table
# echo "Uploading ip to dynamoDB table..."
# python3 aws/csv2dynamodb.py --bucket ${BUCKET} --input-key emr/result/ip_fraud --table ${TABLE}
# echo "Finished"

# Terminating cluster
echo "Terminating cluster..."
aws emr terminate-clusters --cluster-ids ${clusterID}
aws emr wait cluster-terminated --cluster-id ${clusterID}
echo "Finished"





