#!/bin/bash

#############################################
export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

USER="ykumarbekov"
ROLE="yk-project-lambda"
FUNC_NAME=${USER}"-trigger"
KINESIS_OUTPUT_DSTREAM=${USER}"-dstream-out"
SNS_TOPIC=${USER}"-alert"
#############################################

echo "Creating SNS topic..."
topic_arn=$(aws sns list-topics --output text --query Topics|grep ${SNS_TOPIC}|head -1)
test -z ${topic_arn} && topic_arn=$(aws sns create-topic --name ${SNS_TOPIC} --output text --query TopicArn)
echo 'Finished'

accountID=$(aws sts get-caller-identity --output text --query Account)
source_arn="arn:aws:kinesis:"${AWS_DEFAULT_REGION}":"${accountID}":stream/"${KINESIS_OUTPUT_DSTREAM}
role_arn=$(aws iam get-role --role-name ${ROLE} --output text --query Role.Arn)
dest_sns_arn=""
echo ${source_arn}

echo "Creating role..."
test -z $(aws iam get-role --role-name ${ROLE} --output text --query Role.RoleName 2>/dev/null) &&
aws iam create-role --role-name ${ROLE} \
--assume-role-policy-document file://aws/roles/policies/lambda_trust_policy.json &&
aws iam put-role-policy --role-name ${ROLE} \
--policy-name "lambda_access" --policy-document file://aws/roles/policies/lambda_access.json
echo "Finished"

echo "Creating function..."
test -z $(aws lambda get-function \
--function-name ${FUNC_NAME} --output text --query Configuration.FunctionName 2>/dev/null) &&
aws lambda create-function \
--function-name ${FUNC_NAME} \
--runtime python3.7 \
--handler lambda.sns_trigger \
--zip-file fileb://aws/kinesis/function.zip \
--role ${role_arn}
echo "Finished"

echo "Re-Creating mapping source event..."
uuid=$(aws lambda list-event-source-mappings \
--output text --query EventSourceMappings[*].[UUID,EventSourceArn]|grep ${source_arn}|cut -f 1)
test ! -z ${uuid} && aws lambda delete-event-source-mapping --uuid ${uuid}
aws lambda create-event-source-mapping \
--function-name ${FUNC_NAME} \
--batch-size 3 \
--event-source-arn ${source_arn} \
--starting-position LATEST
# ######
aws lambda put-function-event-invoke-config \
--function-name ${FUNC_NAME} \
--destination-config "{\"OnSuccess\":{\"Destination\": \"${topic_arn}\"}}"
echo "Finished"

