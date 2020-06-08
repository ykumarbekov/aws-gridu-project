#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"

USER="ykumarbekov"
SAGEMAKER_ROLE=${USER}"-sagemaker-role"

echo "Creating SageMaker role..."
test -z $(aws iam get-role --role-name ${SAGEMAKER_ROLE} --output text --query Role.RoleName 2>/dev/null) && \
  aws iam create-role --role-name ${SAGEMAKER_ROLE} \
  --assume-role-policy-document file://aws/roles/policies/sagemaker_trust_policy.json && \
  aws iam put-role-policy --role-name ${SAGEMAKER_ROLE} \
  --policy-name "sagemaker_access" --policy-document file://aws/roles/policies/sagemaker_access.json
echo "Finished"

