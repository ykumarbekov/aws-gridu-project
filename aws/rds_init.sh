#!/bin/bash

BUCKET="ykumarbekov-534348"
PROJECT_FOLDER="/opt/aws-gridu-project"

aws s3 mv s3://$BUCKET/config/rds.id /opt/

export ENDPOINT=$(cat /opt/rds.id|awk -F "|" '{ print $1 }')
export DBUSER=$(cat /opt/rds.id|awk -F "|" '{ print $2 }')
export PGPASSWORD=$(cat /opt/rds.id|awk -F "|" '{ print $3 }')
export DB="db1"

# Creating table
psql -h $ENDPOINT -p 5432 -U $DBUSER -w -d $DB -f ${PROJECT_FOLDER}/aws/rds_catalog.sql
# Populate table
export Q="copy catalog from stdin with delimiter as '|' NULL As '' CSV HEADER"
cat ${PROJECT_FOLDER}/catalog/books.csv | psql -h $ENDPOINT -p 5432 -U $DBUSER -w -d $DB -c "${Q}"

