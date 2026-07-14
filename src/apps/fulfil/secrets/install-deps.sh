#!/bin/bash
set -euo pipefail

# sops runs on the build host to encrypt/decrypt, so match the host arch,
# not the imx8mn target arch.
ARCH="$(dpkg --print-architecture)"
DEB="sops_3.12.2_${ARCH}.deb"

cd "$(dirname "$0")"

sudo apt-get update
sudo apt-get install -y gnupg
curl -LO "https://github.com/getsops/sops/releases/download/v3.12.2/${DEB}"
sudo apt-get install -y "./${DEB}"
rm "./${DEB}"

gpg --import sops-public-key.asc