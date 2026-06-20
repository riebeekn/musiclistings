#!/bin/bash

# Runs `terraform destroy` for the current workspace, pulling that environment's
# variables live from 1Password (never written to git, only a temp file that is
# deleted on exit).

set -euo pipefail
cd "$(dirname "$0")"

source ./tf_common.sh

terraform destroy -var-file="$VARS_FILE"
