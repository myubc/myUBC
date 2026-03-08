#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
EXPORT_DIR="${1:-$ROOT_DIR/.open-source-export/myUBC}"

APP_BUNDLE_ID="${APP_BUNDLE_ID:-org.opensource.myubc}"
WIDGET_BUNDLE_ID="${WIDGET_BUNDLE_ID:-${APP_BUNDLE_ID}.widgets}"
TESTS_BUNDLE_ID="${TESTS_BUNDLE_ID:-${APP_BUNDLE_ID}Tests}"
UITESTS_BUNDLE_ID="${UITESTS_BUNDLE_ID:-${APP_BUNDLE_ID}UITests}"
LOGGER_SUBSYSTEM="${LOGGER_SUBSYSTEM:-org.opensource.myubc}"
SANITY_CHECK_URL="${SANITY_CHECK_URL:-https://example.com/myubc.json}"

echo "Preparing sanitized export at: $EXPORT_DIR"
rm -rf "$EXPORT_DIR"
mkdir -p "$EXPORT_DIR"

rsync -a \
  --exclude '.git/' \
  --exclude '.DS_Store' \
  --exclude 'build/' \
  --exclude 'DerivedData/' \
  --exclude '.open-source-export/' \
  --exclude 'xcuserdata/' \
  --exclude '*.xcworkspace/xcuserdata/' \
  --exclude '*.xcodeproj/xcuserdata/' \
  "$ROOT_DIR/" "$EXPORT_DIR/"

export EXPORT_DIR
export APP_BUNDLE_ID
export WIDGET_BUNDLE_ID
export TESTS_BUNDLE_ID
export UITESTS_BUNDLE_ID
export LOGGER_SUBSYSTEM
export SANITY_CHECK_URL

python3 <<'PY'
from pathlib import Path
import os
import re

root = Path(os.environ["EXPORT_DIR"])
pbxproj = root / "myUBC.xcodeproj" / "project.pbxproj"
info_plist = root / "myUBC" / "Resources" / "Info.plist"
constants = root / "myUBC" / "Shared" / "Support" / "Constants.swift"
logger = root / "myUBC" / "Shared" / "Support" / "AppLogger.swift"

pbx = pbxproj.read_text()

bundle_patterns = [
    (r'PRODUCT_BUNDLE_IDENTIFIER = "[^"]*widgets";', f'PRODUCT_BUNDLE_IDENTIFIER = "{os.environ["WIDGET_BUNDLE_ID"]}";'),
    (r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*widgets[^;]*;', f'PRODUCT_BUNDLE_IDENTIFIER = {os.environ["WIDGET_BUNDLE_ID"]};'),
    (r'PRODUCT_BUNDLE_IDENTIFIER = "[^"]*UITests";', f'PRODUCT_BUNDLE_IDENTIFIER = "{os.environ["UITESTS_BUNDLE_ID"]}";'),
    (r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*UITests;', f'PRODUCT_BUNDLE_IDENTIFIER = {os.environ["UITESTS_BUNDLE_ID"]};'),
    (r'PRODUCT_BUNDLE_IDENTIFIER = "[^"]*(?<!UI)Tests";', f'PRODUCT_BUNDLE_IDENTIFIER = "{os.environ["TESTS_BUNDLE_ID"]}";'),
    (r'PRODUCT_BUNDLE_IDENTIFIER = [^;]*(?<!UI)Tests;', f'PRODUCT_BUNDLE_IDENTIFIER = {os.environ["TESTS_BUNDLE_ID"]};'),
]

for pattern, replacement in bundle_patterns:
    pbx = re.sub(pattern, replacement, pbx)

pbx = re.sub(
    r'PRODUCT_BUNDLE_IDENTIFIER = (?!(?:org\.opensource\.myubc|org\.opensource\.myubcTests|org\.opensource\.myubcUITests|org\.opensource\.myubc\.widgets))[^;]+;',
    f'PRODUCT_BUNDLE_IDENTIFIER = {os.environ["APP_BUNDLE_ID"]};',
    pbx,
)
pbx = re.sub(r"\bDEVELOPMENT_TEAM = [A-Z0-9]+;\n", "", pbx)
pbxproj.write_text(pbx)

plist = info_plist.read_text()
plist = re.sub(
    r"<key>CFBundleURLName</key>\s*<string>[^<]+</string>",
    f"<key>CFBundleURLName</key>\n\t\t\t<string>{os.environ['APP_BUNDLE_ID']}</string>",
    plist,
)
info_plist.write_text(plist)

constants_text = constants.read_text()
constants_text = re.sub(
    r'static let sanityCheck = "https://[^"]+\.github\.io/[^"]+"',
    f'static let sanityCheck = "{os.environ["SANITY_CHECK_URL"]}"',
    constants_text,
)
constants.write_text(constants_text)

logger_text = logger.read_text()
logger_text = re.sub(
    r'subsystem: "[^"]+"',
    f'subsystem: "{os.environ["LOGGER_SUBSYSTEM"]}"',
    logger_text,
)
logger.write_text(logger_text)

header_extensions = {".swift", ".h", ".m", ".mm", ".xib", ".storyboard"}
excluded_parts = {".git", "Vendor", ".open-source-export", "SourcePackages"}
for path in root.rglob("*"):
    if (
        path.is_file()
        and path.suffix in header_extensions
        and not any(part in excluded_parts for part in path.parts)
    ):
        text = path.read_text(errors="ignore")
        updated = re.sub(
            r"Created by\s+(.+?)\s+on",
            "Created by myUBC on",
            text,
        )
        if updated != text:
            path.write_text(updated)
PY

echo "Sanitized export created."
echo "Next steps:"
echo "  1. Review the exported copy."
echo "  2. Initialize a fresh public repository from: $EXPORT_DIR"
