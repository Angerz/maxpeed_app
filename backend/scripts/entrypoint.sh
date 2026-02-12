#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "No command provided to entrypoint"
  exit 1
fi

first_arg="$1"

if [[ -f "$first_arg" ]]; then
  chmod +x "$first_arg" 2>/dev/null || true
  if [[ ! -x "$first_arg" ]]; then
    exec bash "$@"
  fi
fi

exec "$@"
