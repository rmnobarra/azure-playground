#!/bin/bash

source env_vars.sh

az group delete -y -n $RG

rm -vf env_vars.sh