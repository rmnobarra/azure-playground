#!/bin/bash

echo "Corrigindo a porta do service dentro do ingress para 80..."

kubectl patch ingress blob-api-ingress -n default --type=json -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/port/number", "value": 80}]'

