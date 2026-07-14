#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KEY_FILE="${SOPS_PRIVATE_KEY_FILE:-$SCRIPT_DIR/sops-private-key.asc}"

INPUT_FILE="${1:?Usage: $0 <encrypted-file-sops>]}"
OUTPUT_FILE="${INPUT_FILE%.sops}"

if [[ ! -f "$KEY_FILE" ]]; then
    echo "SOPS private key not found: $KEY_FILE" >&2
    echo "Retrieve it from the fw-team 1password and then copy it to $KEY_FILE" >&2
    exit 1
fi

GNUPGHOME="$(mktemp -d)"
export GNUPGHOME

cleanup() {
    gpgconf --homedir "$GNUPGHOME" --kill gpg-agent >/dev/null 2>&1 || true
    rm -rf "$GNUPGHOME"
}
trap cleanup EXIT

chmod 700 "$GNUPGHOME"

gpg \
    --batch \
    --quiet \
    --homedir "$GNUPGHOME" \
    --import "$KEY_FILE"

echo "$OUTPUT_FILE"
echo "$INPUT_FILE"

sops decrypt --output "$OUTPUT_FILE" "$INPUT_FILE"
