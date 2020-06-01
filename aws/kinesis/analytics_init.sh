#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

USER="ykumarbekov"
KINESIS_DSTREAM=${USER}"-dstream"
KINESIS_ANALYTICS=${USER}"-analytics"
ROLE="yk-project-analytics"

echo "Creating role..."
test -z $(aws iam get-role --role-name ${ROLE} --output text --query Role.RoleName 2>/dev/null) &&
aws iam create-role --role-name ${ROLE} \
--assume-role-policy-document file://aws/roles/policies/analytics_trust_policy.json &&
aws iam put-role-policy --role-name ${ROLE} \
--policy-name "analytics_access" --policy-document file://aws/roles/policies/analytics_access.json
echo "Finished"

echo "Re-creating Kinesis Stream..."
test ! -z $(aws kinesis describe-stream --stream-name ykumarbekov-dstream \
--output text --query StreamDescription.StreamName 2>/dev/null) && \
echo "Deleting..." && \
aws kinesis delete-stream --stream-name ${KINESIS_DSTREAM} --enforce-consumer-deletion
aws kinesis wait stream-not-exists --stream-name ${KINESIS_DSTREAM}
echo "Initializing..."
aws kinesis create-stream --stream-name ${KINESIS_DSTREAM} --shard-count 10 1>/dev/null
aws kinesis wait stream-exists --stream-name ${KINESIS_DSTREAM}
echo "Finished"

accountID=$(aws sts get-caller-identity --output text --query Account)
resource_arn="arn:aws:kinesis:"${AWS_DEFAULT_REGION}":"$accountID":stream/"${KINESIS_DSTREAM}
role_arn="arn:aws:iam::"$accountID":role/${ROLE}"
# echo $resource_arn
# echo $role_arn

echo "Creating Application..."
aws kinesisanalytics create-application --application-name ${KINESIS_ANALYTICS} \
--application-code \
"CREATE OR REPLACE STREAM \"TOP_VIEWS_BOOKS\" (ISBN VARCHAR(16), MOST_FREQUENT_VALUES BIGINT); \
CREATE OR REPLACE PUMP \"TOP_VIEWS_BOOKS_PUMP\" AS INSERT INTO \"TOP_VIEWS_BOOKS\" \
SELECT STREAM * FROM TABLE (TOP_K_ITEMS_TUMBLING(CURSOR(SELECT STREAM * FROM \"SOURCE_SQL_STREAM_001\"),'ISBN',20,60));"
echo "Finished"

echo "Adding Input..."
aws kinesisanalytics add-application-input \
--application-name ${KINESIS_ANALYTICS} \
--current-application-version-id 1 \
--input \
"{\"NamePrefix\":\"SOURCE_SQL_STREAM\",\"KinesisStreamsInput\":{\"ResourceARN\":\"${resource_arn}\",\"RoleARN\": \"${role_arn}\"}, \
\"InputSchema\":{\"RecordColumns\": \
[{\"Name\":\"ISBN\",\"Mapping\":\"$.ISBN\", \"SqlType\": \"VARCHAR(16)\"}, \
{\"Name\": \"COL_timestamp\",\"Mapping\": \"$.timestamp\",\"SqlType\": \"VARCHAR(32)\"}, \
{\"Name\": \"device_type\", \"Mapping\": \"$.device_type\", \"SqlType\": \"VARCHAR(8)\"}, \
{\"Name\": \"device_id\", \"Mapping\": \"$.device_id\", \"SqlType\": \"VARCHAR(64)\"}, \
{\"Name\": \"ip\", \"Mapping\": \"$.ip\", \"SqlType\": \"VARCHAR(16)\"}], \
\"RecordFormat\": {\"RecordFormatType\": \"JSON\",\"MappingParameters\": {\"JSONMappingParameters\": {\"RecordRowPath\":\"$\"}}}}}"
echo "Finished"