#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

USER="ykumarbekov"
BUCKET="ykumarbekov-534348"
GLUE_DB_CATALOG=${USER}"_gluedb"
QUERY=${USER}"-views-distribution"
OUTPUT="s3://${BUCKET}/athena/result/"


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
aws athena start-query-execution \
--work-group primary \
--query-execution-context "{\"Database\": \"${GLUE_DB_CATALOG}\"}" \
--result-configuration "{\"OutputLocation\":\"${OUTPUT}\"}" \
--query-string "select * from ${tbl} limit 10"
echo "Finished"



