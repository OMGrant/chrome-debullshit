#!/usr/bin/env bash
#
# chrome-debullshit — macOS installer
#
# macOS Chrome reads enterprise policies from the com.google.Chrome managed
# preference domain. This writes them into the system-wide domain at
# /Library/Preferences/com.google.Chrome so they apply to every user.
#
# Usage:
#   sudo ./install.sh              install
#   sudo ./install.sh --uninstall  remove
#
# The policy values are read from policies.list, which is generated from
# policy/debullshit.json by scripts/generate.sh — never edit it by hand.
#
# Does NOT touch sync, passwords, payments, bookmarks, or extensions.
#
set -euo pipefail

DOMAIN="/Library/Preferences/com.google.Chrome"
LIST="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/policies.list"

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
dim()   { printf '\033[2m%s\033[0m\n' "$*"; }

if [[ "${EUID}" -ne 0 ]]; then
  red "This needs root to write the system policy domain. Re-run with sudo:"
  echo "  sudo $0 $*"
  exit 1
fi

if [[ ! -f "${LIST}" ]]; then
  red "Can't find ${LIST} — run scripts/generate.sh, or run this from the repo's macos/ folder."
  exit 1
fi

ACTION="install"
[[ "${1:-}" == "--uninstall" || "${1:-}" == "-u" ]] && ACTION="uninstall"

while IFS=':' read -r name type value; do
  [[ -z "${name}" || "${name}" == \#* ]] && continue
  if [[ "${ACTION}" == "install" ]]; then
    defaults write "${DOMAIN}" "${name}" "-${type}" "${value}"
    green "set       ${name} = ${value}"
  else
    defaults delete "${DOMAIN}" "${name}" 2>/dev/null && green "removed   ${name}" || true
  fi
done < "${LIST}"

echo
if [[ "${ACTION}" == "install" ]]; then
  green "Done. Fully quit Chrome (Cmd+Q) and relaunch."
else
  green "Done. Fully quit Chrome (Cmd+Q) and relaunch to restore defaults."
fi
dim "Verify at  chrome://policy  →  Reload policies. Every entry should read OK."
dim "Note: managed-preference caching can lag; a logout/login guarantees it."
