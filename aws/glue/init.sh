#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"
#############################################
USER="ykumarbekov"
BUCKET="ykumarbekov-534348"
#############################################
GLUE_DB_CATALOG=${USER}"_gluedb"
GLUE_ROLE=${USER}"-glue-role"
#############################################

accountID=$(aws sts get-caller-identity --output text --query Account)

db=$(aws glue get-database --name ${GLUE_DB_CATALOG} --output text --query Database.Name 2>/dev/null)
echo "DATABASE: ${db}"
echo "Tables info..."
n=0
test ! -z ${db} &&
for i in $(aws glue get-tables --database-name ${GLUE_DB_CATALOG} \
--output text --query TableList[*].Name|tr '\n' ' '); do
  echo "Name: ${i}"
  echo "Location: "$(aws glue get-table --database-name ykumarbekov_gluedb \
  --name ${i} --output text --query Table.StorageDescriptor.Location)
  let n=n+1
done

if [ -z ${db} ] && [ ${n} -eq 0 ]; then
  echo "Creating database..."
  aws glue create-database --database-input "{\"Name\":\"${GLUE_DB_CATALOG}\"}"
  echo "Finished"
fi

echo "Creating crawlers..."
aws glue create-crawler --name ${USER}"-s3-views-logs-cr" \
--role "arn:aws:iam::"$accountID":role/${GLUE_ROLE}" \
--database-name ${GLUE_DB_CATALOG} \
--targets "{\"S3Targets\": [ { \"Path\": \"s3://${BUCKET}/logs/views/\" } ]}"

table_arn=$(aws dynamodb describe-table --table-name "fraud-ip-"${USER} --output text --query Table.TableArn)

aws glue create-crawler --name ${USER}"-fraud-ip-cr" \
--role "arn:aws:iam::"$accountID":role/${GLUE_ROLE}" \
--database-name GLUE_DB_CATALOG \
--targets "{\"DynamoDBTargets\": [ { \"Path\": \"${table_arn}\" } ]}"
# ###############
aws glue start-crawler --name ${USER}"-s3-views-logs-cr"
aws glue start-crawler --name ${USER}"-fraud-ip-cr"
echo "Finished"
