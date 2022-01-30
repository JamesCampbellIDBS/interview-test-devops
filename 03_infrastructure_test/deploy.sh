#!/usr/bin/env bash
ERROR_MESSAGE="Environment variables not set!"

: "${DEPLOYMENT_NAME?${ERROR_MESSAGE}}"
: "${DEPLOYMENT_VAR_FILE?${ERROR_MESSAGE}}"
: "${DEPLOYMENT_TYPE?${ERROR_MESSAGE}}"

terraform init -backend-config=/opt/SRE/backends/${DEPLOYMENT_TYPE}-backend.tfvars)

# Consider handling error. OR checking if workspace name is already present.
terraform workspace new ${DEPLOYMENT_NAME}

terraform workspace select ${DEPLOYMENT_NAME}

terraform apply -var-file=/opt/SRE/${DEPLOYMENT_VAR_FILE} -auto-approve
