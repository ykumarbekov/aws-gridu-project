#!/bin/bash

#############################################
# Script for Cleaning of created AWS Infructure
# Be sure you installed AWS CLI and configured AWS_PROFILE: aws-gridu
# Edit script variables, according with your values
#############################################

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

###### Must be manually updated according with your values
USER="ykumarbekov"
AUTH_FOLDER="./auth"
BUCKET="ykumarbekov-534348"
#############################################

echo "BUCKET Deleting..."
#if aws s3api head-bucket --bucket $BUCKET 2>/dev/null; then
#  aws s3 rb s3://$BUCKET --force
#fi
echo "Finished"

echo "Deleting RDS instances..."
t=$(aws rds describe-db-instances \
--db-instance-identifier rds-aws-${USER} \
--output text --query DBInstances[*].DBInstanceIdentifier 2>/dev/null)
for i in ${t[*]}; do
aws rds delete-db-instance \
--db-instance-identifier $i \
--skip-final-snapshot \
--delete-automated-backups 1>/dev/null
aws rds wait db-instance-deleted --db-instance-identifier $i
done
echo "Finished"

echo "Removing EC2 key pair..."
aws ec2 delete-key-pair --key-name ${USER}"-aws-course" && rm -f ${AUTH_FOLDER}"/"${USER}"-aws-course.pem" > /dev/null 2>&1
echo "Finished"

echo "Removing EC2 instance..."
Instances=$(aws ec2 describe-instances \
--output text --filters Name=tag-key,Values=Name Name=tag-value,Values=${USER}"-aws-course" \
--query Reservations[*].Instances[*].InstanceId)
for i in ${Instances[*]}; do
aws ec2 terminate-instances --instance-ids $i 1>/dev/null
aws ec2 wait instance-terminated --instance-ids $i
done
echo "Finished"

echo "Removing DynamoDB tables..."
tbl="fraud-ip-${USER} reviews-${USER}"
for i in ${tbl}; do
  test ! -z $(aws dynamodb describe-table --table-name ${i} --output json \
--query Table.TableName 2>/dev/null) && \
aws dynamodb delete-table --table-name ${i} && \
aws dynamodb wait table-not-exists --table-name ${i}
done
echo "Finished"
