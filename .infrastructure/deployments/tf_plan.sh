#!/bin/bash

# This script is used to run a terraform plan command with the appropriate variables file based on the current workspace.

echo "************************"
echo "* CURRENT WORKSPACE: "
echo "*   $(terraform workspace show)"
echo "************************"

terraform plan -var-file=$(terraform workspace show).tfvars
