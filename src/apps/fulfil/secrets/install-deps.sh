#!/bin/bash

sudo apt-get update
sudo apt-get install -y gnupg
curl -LO https://github.com/getsops/sops/releases/download/v3.12.2/sops_3.12.2_arm64.deb
sudo apt-get install -y ./sops_3.12.2_arm64.deb
rm ./sops_3.12.2_arm64.deb

gpg --import sops-public-key.asc