#!/usr/bin/env bash
set -euo pipefail

source dependencies.sh

mkdir -p ~/.byond/bin
# NSV13 - use fork
wget -O ~/.byond/bin/libauxmos.so "https://github.com/covertcorvid/auxmos/releases/download/v${AUXMOS_VERSION}/libauxmos.so"
chmod +x ~/.byond/bin/libauxmos.so
ldd ~/.byond/bin/libauxmos.so
