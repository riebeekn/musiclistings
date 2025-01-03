#!/bin/bash

# This script is used to run a terraform apply command with the appropriate variables file based on the current workspace.

echo "************************"
echo "* CURRENT WORKSPACE: "
echo "*   $(terraform workspace show)"
echo "************************"

terraform apply -var-file=$(terraform workspace show).tfvars
