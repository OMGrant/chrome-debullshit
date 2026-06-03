#!/usr/bin/env bash
#
# Regenerate the platform-specific installer artifacts from the single source
# of truth, policy/debullshit.json. Run this after editing the JSON.
#
#   ./scripts/generate.sh          regenerate the files
#   ./scripts/generate.sh --check  verify the committed files are in sync (CI)
#
# Generates:
#   windows/debullshit.reg            (install)
#   windows/debullshit-uninstall.reg  (uninstall)
#   macos/policies.list               (consumed at runtime by macos/install.sh)
#
# The Linux installer copies the JSON verbatim and the Windows PowerShell
# installer reads it directly, so neither needs generation.
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JSON="${ROOT}/policy/debullshit.json"
CHECK=0; [[ "${1:-}" == "--check" ]] && CHECK=1

gen() {  # $1 = target (reg | reg-uninstall | list)
  python3 - "$JSON" "$1" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
target = sys.argv[2]

def dword(v):
    if isinstance(v, bool): v = 1 if v else 0
    return "dword:%08x" % int(v)

if target == "reg":
    print("Windows Registry Editor Version 5.00\n")
    print("; chrome-debullshit — Google Chrome enterprise policies (Windows)")
    print("; GENERATED from policy/debullshit.json by scripts/generate.sh — do not edit by hand.")
    print("; Double-click to apply, then fully quit and relaunch Chrome. Verify at chrome://policy.")
    print("; Does NOT touch sync, passwords, payments, bookmarks, or extensions.\n")
    print(r"[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome]")
    for k, v in data.items():
        print('"%s"=%s' % (k, dword(v)))
elif target == "reg-uninstall":
    print("Windows Registry Editor Version 5.00\n")
    print("; chrome-debullshit — UNINSTALL (Windows)")
    print("; GENERATED from policy/debullshit.json by scripts/generate.sh — do not edit by hand.")
    print("; Removes every value chrome-debullshit set, restoring Chrome's defaults.")
    print("; Double-click to apply, then fully quit and relaunch Chrome.\n")
    print(r"[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome]")
    for k in data:
        print('"%s"=-' % k)
elif target == "list":
    print("# GENERATED from policy/debullshit.json by scripts/generate.sh — do not edit by hand.")
    print("# name:type:value  — consumed by macos/install.sh")
    for k, v in data.items():
        if isinstance(v, bool):
            print("%s:bool:%s" % (k, "true" if v else "false"))
        else:
            print("%s:int:%d" % (k, int(v)))
PY
}

dest_for() {
  case "$1" in
    reg)           echo "${ROOT}/windows/debullshit.reg" ;;
    reg-uninstall) echo "${ROOT}/windows/debullshit-uninstall.reg" ;;
    list)          echo "${ROOT}/macos/policies.list" ;;
  esac
}

status=0
for t in reg reg-uninstall list; do
  dest="$(dest_for "$t")"
  tmp="$(mktemp)"
  gen "$t" > "$tmp"
  if [[ "${CHECK}" -eq 1 ]]; then
    if diff -q "$dest" "$tmp" >/dev/null 2>&1; then
      echo "in sync : ${dest#$ROOT/}"
    else
      echo "DRIFT   : ${dest#$ROOT/}  (run ./scripts/generate.sh)"
      diff "$dest" "$tmp" || true
      status=1
    fi
    rm -f "$tmp"
  else
    mv "$tmp" "$dest"
    echo "wrote   : ${dest#$ROOT/}"
  fi
done
exit "${status}"
