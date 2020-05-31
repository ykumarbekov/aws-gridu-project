#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

USER="ykumarbekov"
KINESIS_DSTREAM=${USER}"-dstream"
KINESIS_ANALYTICS=${USER}"-analytics"
ROLE=${USER}"-analytics"

# Build USER ARN: arn:partition:service:region:account-id:resource-type/resource-id
accountID=$(aws sts get-caller-identity --output text --query Account)
resource_arn="arn:aws:kinesis:"${AWS_DEFAULT_REGION}":"$accountID":stream/"${KINESIS_DSTREAM}
role_arn="arn:aws:iam:"$accountID":role/"${ROLE}
echo $resource_arn
echo $role_arn

echo "Create Application..."
aws kinesisanalytics create-application --application-name ${KINESIS_ANALYTICS}
echo "Finished"

echo "Add Input..."
aws kinesisanalytics add-application-name ${KINESIS_ANALYTICS} \
--input '{"NamePrefix": "SOURCE_SQL_STREAM", "KinesisStreamsInput" : {"ResourceARN": ${}}}'