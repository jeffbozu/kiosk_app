#!/usr/bin/env bash
# Simple helper to install Flutter SDK locally and add it to PATH
# Usage: source ./setup_flutter.sh

set -euo pipefail

apt-get update
apt-get install -y curl git unzip xz-utils

FLUTTER_VERSION="3.19.2"
ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

if [ ! -d flutter ]; then
  curl -L -O "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${ARCHIVE}"
  tar -xJf "$ARCHIVE"
  rm "$ARCHIVE"
fi

export PATH="$PWD/flutter/bin:$PATH"

flutter --version

