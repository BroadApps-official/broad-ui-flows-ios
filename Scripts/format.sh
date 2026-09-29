#!/usr/bin/env bash

set -euo pipefail

module_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sandbox_name="$(/usr/bin/ruby -rjson -e 'puts JSON.parse(File.read(ARGV.fetch(0))).fetch("sandbox")' "$module_root/ModuleContract.json")"

bash "$module_root/Scripts/install_swiftformat.sh"
"$module_root/.build/tooling/swiftformat-0.62.1/swiftformat" \
    --config "$module_root/.swiftformat" \
    "$module_root/Sources" \
    "$module_root/Examples/$sandbox_name/Sources"
