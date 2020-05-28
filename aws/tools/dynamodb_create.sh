#!/bin/bash

export AWS_PROFILE="ykumarbekov"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

USER="ykumarbekov"

echo "Creating DynamoDB table..."
test -z $(aws dynamodb describe-table --table-name fraud-ip-${USER} --output json \
--query Table.TableName 2>/dev/null) && aws dynamodb create-table \
--table-name fraud-ip-${USER} \
--attribute-definitions AttributeName=ip,AttributeType=S \
--key-schema AttributeName=ip,KeyType=HASH \
--provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 1>/dev/null
echo "Initializing..."
aws dynamodb wait table-exists --table-name fraud-ip-${USER}
echo "Finished"