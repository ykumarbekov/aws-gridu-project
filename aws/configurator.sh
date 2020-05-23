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
echo "*** RDS Initializing ***"
BUCKET="ykumarbekov-534348"
PROJECT_FOLDER="/opt/aws-gridu-project"
echo "Copying rds.id to local folder..."
#aws s3 mv s3://$BUCKET/config/rds.id /opt/
aws s3api get-object --bucket ${BUCKET} --key config/rds.id /opt/rds.id
echo "Finished"
ENDPOINT=$(cat /opt/rds.id|awk -F "|" '{ print $1 }')
DBUSER=$(cat /opt/rds.id|awk -F "|" '{ print $2 }')
PGPASSWORD=$(cat /opt/rds.id|awk -F "|" '{ print $3 }')
DB="db1"
# #####################
echo "Creating table..."
psql -h $ENDPOINT -p 5432 -U $DBUSER -w -d $DB -f ${PROJECT_FOLDER}/aws/rds_catalog_table.sql
echo "Finished"
echo "Populating table..."
export Q="copy catalog from stdin with delimiter as '|' NULL As '' CSV HEADER"
cat ${PROJECT_FOLDER}/catalog/books.csv | psql -h $ENDPOINT -p 5432 -U $DBUSER -w -d $DB -c "${Q}"
