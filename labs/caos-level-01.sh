#!/bin/bash

ENV_FILE="env_vars.sh"

source $ENV_FILE

echo "Removendo função 'Storage Blob Data Contributor' da identidade gerenciada..."
az role assignment delete \
--role "Storage Blob Data Contributor" \
--assignee $USER_ASSIGNED_CLIENT_ID \
--scope "${STORAGE_ACCT_ID}"