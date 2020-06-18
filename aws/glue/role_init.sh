#!/bin/bash

export AWS_PROFILE="aws-gridu"
export AWS_DEFAULT_OUTPUT="text"
export AWS_DEFAULT_REGION="us-east-1"
#############################################
USER="ykumarbekov"
GLUE_ROLE=${USER}"-glue-role"
#############################################

echo "Creating Glue role..."
test -z $(aws iam get-role --role-name ${GLUE_ROLE} --output text --query Role.RoleName 2>/dev/null) && \
  aws iam create-role --role-name ${GLUE_ROLE} \
  --assume-role-policy-document file://aws/roles/policies/glue_trust_policy.json && \
  aws iam put-role-policy --role-name ${GLUE_ROLE} \
  --policy-name "glue_access" --policy-document file://aws/roles/policies/glue_access.json
echo "Finished"