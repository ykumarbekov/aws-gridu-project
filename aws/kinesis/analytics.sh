#!/bin/bash

#############################################
export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

USER="ykumarbekov"
KINESIS_INPUT_DSTREAM=${USER}"-dstream-in"
KINESIS_OUTPUT_DSTREAM=${USER}"-dstream-out"
KINESIS_ANALYTICS=${USER}"-analytics"
ROLE=${USER}"kinesis-role"
TRIGGER_OUT_NAME = "TRIGGER_TOP_VIEWS_100"
#############################################

echo "Creating role..."
test -z $(aws iam get-role --role-name ${ROLE} --output text --query Role.RoleName 2>/dev/null) &&
aws iam create-role --role-name ${ROLE} \
--assume-role-policy-document file://aws/roles/policies/analytics_trust_policy.json &&
aws iam put-role-policy --role-name ${ROLE} \
--policy-name "analytics_access" --policy-document file://aws/roles/policies/analytics_access.json
echo "Finished"

echo "Re-creating Kinesis Streams..."
inp_stream=$(aws kinesis describe-stream --stream-name ${KINESIS_INPUT_DSTREAM} \
--output text --query StreamDescription.StreamName 2>/dev/null)
out_stream=$(aws kinesis describe-stream --stream-name ${KINESIS_OUTPUT_DSTREAM} \
--output text --query StreamDescription.StreamName 2>/dev/null)
echo "Deleting..."
test ! -z  ${inp_stream} && \
aws kinesis delete-stream --stream-name ${KINESIS_INPUT_DSTREAM} --enforce-consumer-deletion && \
aws kinesis wait stream-not-exists --stream-name ${KINESIS_INPUT_DSTREAM}
test ! -z  ${out_stream} && \
aws kinesis delete-stream --stream-name ${KINESIS_OUTPUT_DSTREAM} --enforce-consumer-deletion && \
aws kinesis wait stream-not-exists --stream-name ${KINESIS_OUTPUT_DSTREAM}
echo "Initializing..."
aws kinesis create-stream --stream-name ${KINESIS_INPUT_DSTREAM} --shard-count 10 1>/dev/null
aws kinesis wait stream-exists --stream-name ${KINESIS_INPUT_DSTREAM}
aws kinesis create-stream --stream-name ${KINESIS_OUTPUT_DSTREAM} --shard-count 1 1>/dev/null
aws kinesis wait stream-exists --stream-name ${KINESIS_OUTPUT_DSTREAM}
echo "Finished"
#############################################

accountID=$(aws sts get-caller-identity --output text --query Account)
res_input_arn="arn:aws:kinesis:"${AWS_DEFAULT_REGION}":"$accountID":stream/"${KINESIS_INPUT_DSTREAM}
res_output_arn="arn:aws:kinesis:"${AWS_DEFAULT_REGION}":"$accountID":stream/"${KINESIS_OUTPUT_DSTREAM}
role_arn="arn:aws:iam::"$accountID":role/${ROLE}"
# echo $resource_arn
# echo $role_arn

echo "Creating Application..."
aws kinesisanalytics create-application --application-name ${KINESIS_ANALYTICS} \
--application-code \
"CREATE OR REPLACE STREAM \"TOP_VIEWS_BOOKS\" (ISBN VARCHAR(16), MOST_FREQUENT_VALUES BIGINT); \
CREATE OR REPLACE PUMP \"TOP_VIEWS_BOOKS_PUMP\" AS INSERT INTO \"TOP_VIEWS_BOOKS\" \
SELECT STREAM * \
FROM TABLE (TOP_K_ITEMS_TUMBLING(CURSOR(SELECT STREAM * FROM \"SOURCE_SQL_STREAM_001\"),'ISBN',10,60)); \
CREATE OR REPLACE STREAM \"${TRIGGER_OUT_NAME}\" (ISBN VARCHAR(16), HITS BIGINT); \
CREATE OR REPLACE PUMP \"TRIGGER_TOP_VIEWS_100_PUMP\" AS INSERT INTO \"TRIGGER_TOP_VIEWS_100\" \
SELECT STREAM ISBN, HITS FROM (SELECT ISBN, MOST_FREQUENT_VALUES as HITS FROM \"TOP_VIEWS_BOOKS\") WHERE HITS>=100;"
echo "Finished"

echo "Adding Input..."
aws kinesisanalytics add-application-input \
--application-name ${KINESIS_ANALYTICS} \
--current-application-version-id 1 \
--input \
"{\"NamePrefix\":\"SOURCE_SQL_STREAM\",\"KinesisStreamsInput\":{\"ResourceARN\":\"${res_input_arn}\",\"RoleARN\": \"${role_arn}\"}, \
\"InputSchema\":{\"RecordColumns\": \
[{\"Name\":\"ISBN\",\"Mapping\":\"$.ISBN\", \"SqlType\": \"VARCHAR(16)\"}, \
{\"Name\": \"COL_timestamp\",\"Mapping\": \"$.timestamp\",\"SqlType\": \"VARCHAR(32)\"}, \
{\"Name\": \"device_type\", \"Mapping\": \"$.device_type\", \"SqlType\": \"VARCHAR(8)\"}, \
{\"Name\": \"device_id\", \"Mapping\": \"$.device_id\", \"SqlType\": \"VARCHAR(64)\"}, \
{\"Name\": \"ip\", \"Mapping\": \"$.ip\", \"SqlType\": \"VARCHAR(16)\"}], \
\"RecordFormat\": {\"RecordFormatType\": \"JSON\",\"MappingParameters\": {\"JSONMappingParameters\": {\"RecordRowPath\":\"$\"}}}}}"
echo "Finished"

echo "Adding Output..."
aws kinesisanalytics add-application-output \
--application-name ${KINESIS_ANALYTICS} \
--current-application-version-id 2 \
--application-output \
"{\"Name\":\"${TRIGGER_OUT_NAME}\",\"KinesisStreamsOutput\":{\"ResourceARN\":\"${res_output_arn}\",\"RoleARN\":\"${role_arn}\"}, \
\"DestinationSchema\":{\"RecordFormatType\":\"JSON\"}}"
echo "Finished"