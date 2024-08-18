#!/bin/bash

source env_vars.sh

kubectl logs -f `kubectl get pods --selector=app=blob-lab --output=jsonpath='{.items[0].metadata.name}'`