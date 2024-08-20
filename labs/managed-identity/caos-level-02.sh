#!/bin/bash

ENV_FILE="env_vars.sh"

source $ENV_FILE

echo "Alterando a porta do service dentro do ingress para 5002..."

kubectl patch ingress blob-api-ingress -n default --type=json -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/port/number", "value": 5002}]'