#!/bin/sh
set -eu

PROJECT_DIR="${PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(pwd)"
fi

export PATH="$PROJECT_DIR/Tool/bin:$PATH"

if ! command -v rswift >/dev/null 2>&1; then
  echo "warning: rswift not installed; download from https://github.com/mac-cain13/R.swift" >&2
  exit 0
fi

OUTPUT_FILE="${PROJECT_DIR}/schedule-notes/R.generated.swift"
STRINGS_DIR="${PROJECT_DIR}/schedule-notes"

# 自动收集各 *.lproj/Localizable.strings（与 extends/string_extends.md 中语言增减对齐时无需改本脚本）
set --
if [ -d "$STRINGS_DIR" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    set -- "$@" --input-files "$f"
  done <<EOF
$(find "$STRINGS_DIR" -maxdepth 2 -type f -name Localizable.strings 2>/dev/null | LC_ALL=C sort)
EOF
fi

if [ "$#" -eq 0 ]; then
  echo "warning: no Localizable.strings under schedule-notes/*.lproj, skip R.generated.swift generation." >&2
  exit 0
fi

rswift generate \
  --generators string \
  --input-type input-files \
  "$@" \
  "$OUTPUT_FILE"

# Make call sites not depend on `RswiftResources`.
# Convert:
#   var <key>: RswiftResources.StringResource { .init(...) }
# into:
#   func <key>() -> String { .init(...)() }
python3 - "$OUTPUT_FILE" <<'PY'
import re
import sys
from pathlib import Path

out_path = Path(sys.argv[1])
text = out_path.read_text(encoding="utf-8")

pattern = re.compile(
    r'^(?P<indent>\s*)var\s+(?P<key>[A-Za-z0-9_]+)\s*:\s*RswiftResources\.StringResource\s*\{\s*\.init\((?P<args>[^)]*)\)\s*\}\s*$',
    re.MULTILINE
)

def repl(m: re.Match) -> str:
    indent = m.group("indent")
    key = m.group("key")
    args = m.group("args").strip()
    return (
        f"{indent}func {key}() -> String {{\n"
        f"{indent}  let resource: RswiftResources.StringResource = .init({args})\n"
        f"{indent}  return resource()\n"
        f"{indent}}}\n"
    )

new_text, _ = pattern.subn(repl, text)
out_path.write_text(new_text, encoding="utf-8")
PY
