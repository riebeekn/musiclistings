# Shared setup for the tf_* wrapper scripts. Sourced — not executed directly.
#
# Pulls the current workspace's variables live from 1Password (never written to
# git, only a temp file that is deleted on exit) and exports $VARS_FILE and
# $WORKSPACE for the caller to hand to terraform.

# The 1Password account and vault are kept out of this (public) repo — export
# them from .envrc (loaded by direnv or `source .envrc`), alongside the AWS creds.
OP_VAULT="${OP_VAULT:-}"
OP_ACCOUNT="${OP_ACCOUNT:-}"

if [ -z "$OP_VAULT" ] || [ -z "$OP_ACCOUNT" ]; then
  echo "ERROR: OP_VAULT and OP_ACCOUNT must be set." >&2
  echo "Export them in .envrc (see .example.envrc) and 'source .envrc' / use direnv." >&2
  exit 1
fi

# Fail closed: refuse to run terraform unless we can actually fetch the vars, so
# we never plan/apply against missing or partial variables.
command -v op >/dev/null 2>&1 || {
  echo "ERROR: 1Password CLI (op) not installed (try: brew install 1password-cli)." >&2
  exit 1
}

# Pin op to the account that owns the vault so multi-account setups resolve
# deterministically.
op_run() {
  op --account "$OP_ACCOUNT" "$@"
}

if ! op_run whoami >/dev/null 2>&1; then
  # No account configured at all (desktop app integration off and no manual
  # `op account add`). `op signin` would drop into its own multi-option
  # interactive prompt, which is confusing — fail closed with clear steps.
  if [ -z "$(op account list 2>/dev/null)" ]; then
    echo "ERROR: the 1Password CLI has no account to sign in to." >&2
    echo "Open the 1Password desktop app and:" >&2
    echo "  1. Sign in to your account." >&2
    echo "  2. Settings -> Developer -> enable 'Integrate with 1Password CLI'." >&2
    echo "  3. Restart your terminal." >&2
    echo "  4. When prompted, allow your terminal to access data from other apps." >&2
    echo "Then re-run this script." >&2
    exit 1
  fi

  # No active session: sign the user in (interactive prompt or 1Password app
  # unlock) instead of bailing. Capture the token before eval'ing it so a failed
  # sign-in is caught — `eval "$(op signin ...)"` would mask the failure.
  if ! session=$(op signin --account "$OP_ACCOUNT"); then
    echo "ERROR: 1Password sign-in failed for '$OP_ACCOUNT'. Add the account with 'op account add', or enable 'Integrate with 1Password CLI' in the 1Password app (Settings -> Developer)." >&2
    exit 1
  fi
  eval "$session"
fi

aws sts get-caller-identity >/dev/null 2>&1 || {
  echo "ERROR: no working AWS credentials. Export them (see .envrc) and retry." >&2
  exit 1
}

WORKSPACE=$(terraform workspace show)

LOCAL_VARS_FILE="${WORKSPACE}.tfvars"
if [ -f "$LOCAL_VARS_FILE" ]; then
  echo "ERROR: a local '${LOCAL_VARS_FILE}' exists in $(pwd)." >&2
  echo "Terraform variables are pulled from 1Password, not local files." >&2
  echo "Delete the local copy and re-run:" >&2
  echo "  rm '${LOCAL_VARS_FILE}'" >&2
  exit 1
fi

ITEM="${WORKSPACE}.tfvars"

VARS_FILE=$(mktemp -t "tfvars.${WORKSPACE}.XXXXXX")
trap 'rm -f "$VARS_FILE"' EXIT

op_run read "op://${OP_VAULT}/${ITEM}/notesPlain" >"$VARS_FILE" || {
  echo "ERROR: could not read '${ITEM}' from 1Password vault '${OP_VAULT}'." >&2
  exit 1
}

[ -s "$VARS_FILE" ] || {
  echo "ERROR: tfvars pulled from 1Password for '${WORKSPACE}' is empty." >&2
  exit 1
}

echo "************************"
echo "* CURRENT WORKSPACE: "
echo "*   ${WORKSPACE}"
echo "************************"
