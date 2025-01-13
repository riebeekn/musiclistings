#!/bin/bash

# This script is used to run a terraform destroy command with the appropriate variables file based on the current workspace.

echo "************************"
echo "* CURRENT WORKSPACE: "
echo "*   $(terraform workspace show)"
echo "************************"

terraform destroy -var-file=$(terraform workspace show).tfvars
