#!/usr/bin/env nix-shell
#! nix-shell -i sh -p curl
# shellcheck shell=sh
log() {
  if [ -t 2 ]; then
    >&2 printf '\033[32m%s\033[0m\n' "$1"
  else
    >&2 printf '%s\n' "$1"
  fi
}

critical() {
  if [ -t 2 ]; then
    >&2 printf '\033[31m%s\033[0m\n' "$1"
  else
    >&2 printf '%s\n' "$1"
  fi
  exit "$2"
}

if ! command -v home-manager 1>/dev/null 2>&1; then
  log "Installing Home Manager"
  config_dir="${XDG_CONFIG_HOME-$HOME/.config}/nixpkgs"
  git clone git@gitlab.com:gcoakes/nixhome.git "$config_dir"
  nix run nixpkgs.home-manager -c 'home-manager switch'
fi