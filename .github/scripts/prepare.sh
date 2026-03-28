#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Flutterando/modular"
BRANCH="master"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Clone (skip if already exists) ---
if [ ! -d "$REPO_DIR" ]; then
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR/doc"

# --- Node version ---
# Docusaurus 2.4.1 uses webpack 4 which requires --openssl-legacy-provider on Node 17+
# Use Node 18 LTS with legacy OpenSSL provider
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
    nvm use 18 2>/dev/null || nvm install 18
fi
export NODE_OPTIONS="${NODE_OPTIONS:-} --openssl-legacy-provider"

# --- Dependencies ---
npm install --legacy-peer-deps

# --- Apply fixes.json if present ---
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
    echo "[INFO] Applying content fixes..."
    node -e "
    const fs = require('fs');
    const path = require('path');
    const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
    for (const [file, ops] of Object.entries(fixes.fixes || {})) {
        if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
        let content = fs.readFileSync(file, 'utf8');
        for (const op of ops) {
            if (op.type === 'replace' && content.includes(op.find)) {
                content = content.split(op.find).join(op.replace || '');
                console.log('  fixed:', file, '-', op.comment || '');
            }
        }
        fs.writeFileSync(file, content);
    }
    for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
        const c = typeof cfg === 'string' ? cfg : cfg.content;
        fs.mkdirSync(path.dirname(file), {recursive: true});
        fs.writeFileSync(file, c);
        console.log('  created:', file);
    }
    "
fi

# Write env vars needed by translate/build steps
# This repo requires Node 18 (Docusaurus 2.4.1 + webpack 4)
cat > .build-env << 'ENVEOF'
export N_PREFIX="$HOME/.n"
if [ ! -f "$N_PREFIX/bin/node" ] || [ "$(${N_PREFIX}/bin/node --version | cut -d. -f1 | tr -d v)" != "18" ]; then
  curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o /tmp/n && bash /tmp/n 18
fi
export PATH="$N_PREFIX/bin:$PATH"
export NODE_OPTIONS="${NODE_OPTIONS:-} --openssl-legacy-provider"
ENVEOF

echo "[DONE] Repository is ready for docusaurus commands."
