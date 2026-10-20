#!/usr/bin/env bash
# Onboard a machine: install these skills.
#
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/petem24/skills/main/setup.sh)
#
# Safe to rerun.
set -euo pipefail

echo "Installing skills..."
npx -y skills add petem24/skills -g --all

echo "Done."
