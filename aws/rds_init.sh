#!/bin/bash

BUCKET="ykumarbekov-534348"
PROJECT_FOLDER="/opt/aws-gridu-project"

test -e /opt/rds.id && exit 0

aws s3 mv s3://$BUCKET/config/rds.id /opt/
#aws s3api get-object --bucket ${BUCKET} --key config/rds.id /opt/rds.id

ENDPOINT=$(cat /opt/rds.id|awk -F "|" '{ print $1 }')
DBUSER=$(cat /opt/rds.id|awk -F "|" '{ print $2 }')
PGPASSWORD=$(cat /opt/rds.id|awk -F "|" '{ print $3 }')
DB="db1"
# #####################
# #####################
psql -h $ENDPOINT -p 5432 -U $DBUSER -w -d $DB -f ${PROJECT_FOLDER}/aws/rds_catalog_table.sql
export Q="copy catalog from stdin with delimiter as '|' NULL As '' CSV HEADER"
cat ${PROJECT_FOLDER}/catalog/books.csv | psql -h $ENDPOINT -p 5432 -U $DBUSER -w -d $DB -c "${Q}"

