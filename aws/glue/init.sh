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
export AWS_DEFAULT_OUTPUT="text"
GLUE_ROLE=${USER}"-glue-role"
GLUE_DB_CATALOG=${USER}"_gluedb"
#############################################
echo "Creating Glue role..."
test -z $(aws iam get-role --role-name ${GLUE_ROLE} --output text --query Role.RoleName 2>/dev/null) && \
  aws iam create-role --role-name ${GLUE_ROLE} \
  --assume-role-policy-document file://aws/roles/policies/glue_trust_policy.json && \
  aws iam put-role-policy --role-name ${GLUE_ROLE} \
  --policy-name "glue_access" --policy-document file://aws/roles/policies/glue_access.json
echo "Finished"
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
echo "S3 crawler, set cron: running daily"
aws glue create-crawler --name ${USER}"-s3-views-crawler" \
--role "arn:aws:iam::"$accountID":role/${GLUE_ROLE}" \
--database-name ${GLUE_DB_CATALOG} \
--schedule "cron(30 1 * * ? *)" \
--targets "{\"S3Targets\": [ { \"Path\": \"s3://${BUCKET}/logs/views/\" } ]}"

#table_arn=$(aws dynamodb describe-table --table-name "fraud-ip-"${USER} --output text --query Table.TableArn)
#aws glue create-crawler --name ${USER}"-fraud-ip-cr" \
#--role "arn:aws:iam::"$accountID":role/${GLUE_ROLE}" \
#--database-name GLUE_DB_CATALOG \
#--targets "{\"DynamoDBTargets\": [ { \"Path\": \"${table_arn}\" } ]}"
# ###############
#aws glue start-crawler --name ${USER}"-s3-views-logs-cr"
#aws glue start-crawler --name ${USER}"-fraud-ip-cr"
echo "Finished"
