#!/bin/bash

source env_vars.sh

echo "Reatribuindo função 'Storage Blob Data Contributor' à identidade gerenciada..."
az role assignment create \
--role "Storage Blob Data Contributor" \
--assignee $USER_ASSIGNED_CLIENT_ID \
--scope "${STORAGE_ACCT_ID}"