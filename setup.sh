#!/usr/bin/env bash
# Onboard a machine: install these skills and store the keys they need.
#
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/petem24/skills/main/setup.sh)
#
# Safe to rerun. Keys go in ~/.config/secrets.env (readable only by you), which
# your shell profiles load. Set IMGBB_API_KEY before running to skip the prompt.
set -euo pipefail

secrets="$HOME/.config/secrets.env"
source_line='[ -f ~/.config/secrets.env ] && . ~/.config/secrets.env'

echo "Installing skills..."
npx -y skills add petem24/skills -g --all

mkdir -p "$(dirname "$secrets")"
touch "$secrets"
chmod 600 "$secrets"

key="${IMGBB_API_KEY:-}"
if [ -z "$key" ]; then
  if grep -q '^export IMGBB_API_KEY=' "$secrets"; then
    prompt="ImgBB API key (leave blank to keep the saved key): "
  else
    prompt="ImgBB API key from https://api.imgbb.com/ (leave blank to skip): "
  fi
  read -rsp "$prompt" key < /dev/tty
  echo
fi

if [ -n "$key" ]; then
  others="$(grep -v '^export IMGBB_API_KEY=' "$secrets" || true)"
  {
    [ -n "$others" ] && printf '%s\n' "$others"
    printf 'export IMGBB_API_KEY=%q\n' "$key"
  } > "$secrets"
  echo "Saved IMGBB_API_KEY to $secrets."
fi

for profile in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ "$profile" = "$HOME/.profile" ] || [ -f "$profile" ] || continue
  if ! grep -qF "$source_line" "$profile" 2>/dev/null; then
    printf '\n%s\n' "$source_line" >> "$profile"
    echo "Added secrets loader to $profile."
  fi
done

echo "Done. Open a new terminal (or run: . $secrets) to load the keys."
echo "Desktop-launched apps pick them up after you log out and back in."
