#!/usr/bin/env bash
#
# chrome-debullshit — strip the AI, ad-tracking, and nag "features" out of
# Google Chrome (and Chromium) using official enterprise policies.
#
# Usage:
#   sudo ./install.sh              install the policy
#   sudo ./install.sh --uninstall  remove it
#
# It does NOT touch sync, passwords, payments, bookmarks, or extensions.
#
set -euo pipefail

POLICY_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/policy/debullshit.json"
POLICY_NAME="debullshit.json"

# These policies are written in Google Chrome's policy vocabulary, so we target
# the browsers that speak it: Chrome and its direct upstream, Chromium.
TARGETS=(
  "Google Chrome:/etc/opt/chrome/policies/managed"
  "Chromium:/etc/chromium/policies/managed"
)

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
dim()   { printf '\033[2m%s\033[0m\n' "$*"; }

if [[ "${EUID}" -ne 0 ]]; then
  red "This needs root to write to /etc. Re-run with sudo:"
  echo "  sudo $0 $*"
  exit 1
fi

if [[ ! -f "${POLICY_SRC}" ]]; then
  red "Can't find ${POLICY_SRC} — run this from the repo root."
  exit 1
fi

ACTION="install"
[[ "${1:-}" == "--uninstall" || "${1:-}" == "-u" ]] && ACTION="uninstall"

touched=0
for entry in "${TARGETS[@]}"; do
  name="${entry%%:*}"
  dir="${entry#*:}"
  parent="$(dirname "$dir")"          # e.g. /etc/opt/chrome — only act if the browser's tree exists
  base="$(dirname "$parent")"

  if [[ "${ACTION}" == "install" ]]; then
    # Install everywhere plausible: create the managed dir even if the browser
    # isn't installed yet, but only under config roots that already exist.
    if [[ -d "$base" || -d "$parent" || -d "$dir" ]]; then
      mkdir -p "$dir"
      install -m 0644 -o root -g root "${POLICY_SRC}" "${dir}/${POLICY_NAME}"
      green "installed → ${dir}/${POLICY_NAME}  (${name})"
      touched=$((touched+1))
    fi
  else
    if [[ -f "${dir}/${POLICY_NAME}" ]]; then
      rm -f "${dir}/${POLICY_NAME}"
      green "removed   → ${dir}/${POLICY_NAME}  (${name})"
      touched=$((touched+1))
    fi
  fi
done

if [[ "${touched}" -eq 0 ]]; then
  if [[ "${ACTION}" == "install" ]]; then
    red "No Chromium-family browser config dirs found."
    dim "Chrome usually creates /etc/opt/chrome the first time it runs. Launch it once, then re-run."
  else
    dim "Nothing to remove — no debullshit policy was installed."
  fi
  exit 0
fi

echo
if [[ "${ACTION}" == "install" ]]; then
  green "Done. Fully quit the browser (Ctrl+Q) and relaunch."
else
  green "Done. Fully quit the browser (Ctrl+Q) and relaunch to restore defaults."
fi
dim "Verify at  chrome://policy  →  Reload policies. Every entry should read OK."
