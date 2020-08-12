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

GLUE_ROLE=$USER"-glue-role"
GLUE_DB_CATALOG=${USER}"_gluedb"
CRAWLER=${USER}"-s3-views-crawler"
JOB_NAME=$USER"-suspicious-ips"
TABLE="views"

echo "Uploading scripts"
aws s3 cp aws/glue/find-ips.py s3://$BUCKET/glue/code/
echo "Finished"

role=$(aws iam get-role --role-name ${GLUE_ROLE} --output text --query Role.Arn 2>/dev/null)
test -z ${role} && echo "Can't find role: ${ROLE_NAME}" && exit 1

echo "Initializing Job: Finding suspicious IP"
aws glue create-job --name ${JOB_NAME} \
--role ${role} \
--command Name="glueetl",ScriptLocation="s3://${BUCKET}/glue/code/find-ips.py",PythonVersion=3 \
--default-arguments \
"{\"--gluedb\":\"${GLUE_DB_CATALOG}\",\"--table\":\"${TABLE}\",\"--bucket\":\"${BUCKET}\"}" \
--number-of-workers 2 \
--worker-type "G.1X" \
--timeout 30
echo "Finished"

# Methods for running job:
# Realize partitioning for Glue catalog table: views / add partitioning supports to Spark job
# Invoke it by Lambda function:
# Steps:
# Create an AWS Lambda function and an Amazon CloudWatch Events rule
# https://aws.amazon.com/premiumsupport/knowledge-center/start-glue-job-crawler-completes-lambda/

# !! It's not possible to use AWS Glue triggers to start a job when a crawler run completes !!
# Glue trigger - conditional - Wrong !!
# Only Scheduled:
#--type SCHEDULED
#--schedule "cron(30 2 * * ? *)"
echo "Creating and starting trigger for the job: Finding suspicious IP / Scheduled"
#aws glue create-trigger \
#--name $USER"-suspicious-ips-trigger" \
#--type CONDITIONAL \
#--start-on-creation \
#--actions JobName=${JOB_NAME} \
#--predicate \
#"{\"Logical\": \"ANY\", \"Conditions\": [{\"LogicalOperator\": \"EQUALS\",\
#\"CrawlerName\": \"${CRAWLER}\",\"CrawlState\": \"SUCCEEDED\"}]}"
echo "Finished"

