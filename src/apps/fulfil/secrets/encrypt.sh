#!/bin/bash
set -euo pipefail

PGP_FINGERPRINT="842A2C6A2E4D1DC036A2A6F81EE86A94D559200A"
INPUT="${1:?usage: ./encrypt.sh <file>}"

BASE="$(basename "$INPUT")"
OUT="$BASE.sops"

sops --encrypt \
  --pgp "$PGP_FINGERPRINT" \
  --input-type binary \
  --output-type binary \
  "$INPUT" > "./$OUT"

echo "Encrypted $INPUT -> $OUT"