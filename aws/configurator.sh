#!/bin/bash

yum update -y
yum install python36 -y
yum install postgresql96.x86_64 -y
yum install git -y
git clone https://github.com/ykumarbekov/aws-gridu-project.git /opt/aws-gridu-project
mkdir /opt/logs
chmod +x /opt/aws-gridu-project/code/runner.sh
echo "*/30 * * * * /opt/aws-gridu-project/code/runner.sh" > /tmp/usrcrontab
crontab /tmp/usrcrontab
# #####################
# #####################
export BUCKET="ykumarbekov-534348"
export PROJECT_FOLDER="/opt/aws-gridu-project"
aws s3 mv s3://$BUCKET/config/rds.id /opt/
export ENDPOINT=$(cat /opt/rds.id|awk -F "|" '{ print $1 }')
export DBUSER=$(cat /opt/rds.id|awk -F "|" '{ print $2 }')
export PGPASSWORD=$(cat /opt/rds.id|awk -F "|" '{ print $3 }')
export DB="db1"
# #####################
# ##### Creating table
psql -h $ENDPOINT -p 5432 -U $DBUSER -w -d $DB -f ${PROJECT_FOLDER}/aws/rds_catalog.sql
# ##### Populate table
export Q="copy catalog from stdin with delimiter as '|' NULL As '' CSV HEADER"
cat ${PROJECT_FOLDER}/catalog/books.csv | psql -h $ENDPOINT -p 5432 -U $DBUSER -w -d $DB -c "${Q}"
