#!/usr/bin/env bash
set -euo pipefail

# Rebuild script for Flutterando/modular
# Runs on existing source tree (no clone). Assumes CWD is the doc/ directory.

# --- Node version ---
# Docusaurus 2.4.1 uses webpack 4 which requires --openssl-legacy-provider on Node 17+
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    nvm use 18 2>/dev/null || nvm install 18
fi
export NODE_OPTIONS="${NODE_OPTIONS:-} --openssl-legacy-provider"

# --- Dependencies ---
npm install --legacy-peer-deps

# --- Build ---
npx docusaurus build

echo "[DONE] Build complete."
