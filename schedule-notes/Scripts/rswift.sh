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
LOCALIZABLE_EN="${PROJECT_DIR}/schedule-notes/en.lproj/Localizable.strings"
LOCALIZABLE_ZH="${PROJECT_DIR}/schedule-notes/zh.lproj/Localizable.strings"

if [ ! -f "$LOCALIZABLE_EN" ] && [ ! -f "$LOCALIZABLE_ZH" ]; then
  echo "warning: Localizable.strings not found under en.lproj/zh.lproj, skip R.generated.swift generation." >&2
  exit 0
fi

# Generate from localized strings only (avoid reading xcodeproj in Xcode sandbox).
rswift generate \
  --generators string \
  --input-type input-files \
  --input-files "$LOCALIZABLE_EN" \
  --input-files "$LOCALIZABLE_ZH" \
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
