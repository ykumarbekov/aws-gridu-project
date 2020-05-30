#!/bin/bash

BUCKET="ykumarbekov-534348"
PROJECT_FOLDER="/opt/aws-gridu-project"

test -e /opt/rds.id && exit 0

aws s3 mv s3://$BUCKET/config/rds.id /opt/
# #####################
ENDPOINT=$(cat /opt/rds.id|cut -f 1 -d '|')
export PGUSER=$(cat /opt/rds.id|cut -f 2 -d '|')
export PGPASSWORD=$(cat /opt/rds.id|cut -f 3 -d '|')
export PGDATABASE="db1"
export PGPORT=5432
# #####################
psql -h $ENDPOINT -w -f ${PROJECT_FOLDER}/aws/rds/rds_catalog_table.sql
export Q="copy catalog from stdin with delimiter as '|' NULL As '' CSV HEADER"
cat ${PROJECT_FOLDER}/catalog/books.csv | psql -h $ENDPOINT -w -c "${Q}"
# #####################

