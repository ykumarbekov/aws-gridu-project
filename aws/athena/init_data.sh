#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"
#############################################
USER="ykumarbekov"
BUCKET="ykumarbekov-534348"
GLUE_DB_CATALOG=${USER}"_gluedb"
QUERY=${USER}"-views-distribution"
OUTPUT="s3://${BUCKET}/athena/result/"
DATASOURCE_ID="5911728743"
DATASOURCE_NAME={USER}"-ds_qs"
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
test -z ${db} && [ ${n} -eq 0 ] && \
 echo "-------------------------------------" && \
 echo "You don't have configured GLUE DATA CATALOG or registered tables. Pls. configure it before!" && \
 echo "-------------------------------------" && exit -1
echo "Finished"

read -p "Please define table name (see above): " tbl && test -z ${tbl}
test -z ${tbl} && echo "Empty table name. Please define table for the next step!" && exit -1
echo ${tbl}

echo "Running query..."
aws s3 rm s3://${BUCKET}/athena/result/ --recursive
aws athena start-query-execution \
--work-group primary \
--query-execution-context "{\"Database\": \"${GLUE_DB_CATALOG}\"}" \
--result-configuration "{\"OutputLocation\":\"${OUTPUT}\"}" \
--query-string "select device_type,count(*) as cnt from ${tbl} group by device_type"
echo "Finished"

sleep 5s
uri="https://"${BUCKET}".s3.amazonaws.com/athena/result/"\
$(aws s3 ls s3://${BUCKET}/athena/result/|grep -e '.csv$'|head -1|awk '{print $4}')

echo ${uri}
read -p "Modify aws/athena/asn-manifest.json, add uri above to the URIs section and press Enter key"
aws s3 rm s3://${BUCKET}/athena/manifest/ --recursive && \
aws s3 cp aws/athena/asn-manifest.json s3://${BUCKET}/athena/manifest/

echo "https://ykumarbekov-534348.s3.amazonaws.com/athena/manifest/asn-manifest.json"
read -p "Use current manifest file (see above) for the new S3 Datasource. Press Enter for exit"

#echo "Set permissions to S3..."
#aws quicksight create-iam-policy-assignment \
#--aws-account-id ${accountID} \
#--assignment-name ${USER}"-quicksight-s3-policy-assignment" \
#--assignment-status ENABLED \
#--policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess \
#--identities "{\"users\":[\"${USER}\"]}" \
#--namespace default
#echo "Finished"

#echo "Creating Datasource..."
#aws quicksight create-data-source \
#--aws-account-id ${accountID} \
#--data-source-id ${DATASOURCE_ID} \
#--name ${DATASOURCE_NAME} \
#--type S3 \
#--data-source-parameters \
#"{\"S3Parameters\":{\"ManifestFileLocation\":{\"Bucket\":\"${BUCKET}\",\"Key\":\"athena/manifest/asn-manifest.json\"}}}"
#echo "Finished"

#echo "Creating dataset..."
#echo "Finished"



