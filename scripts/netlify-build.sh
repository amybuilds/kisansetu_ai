#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Keep the SDK outside the app so it cannot enter the published output.
sdk_dir="$(mktemp -d -t netlify-flutter.XXXXXX)"
trap 'rm -rf "$sdk_dir"' EXIT

# Use the official SDK archive because cloning is blocked in preview builds.
release_base="https://storage.googleapis.com/flutter_infra_release"
curl --fail --location --retry 3 "$release_base/releases/releases_linux.json" \
  --output "$sdk_dir/releases.json"
archive_url="$(python3 - "$sdk_dir/releases.json" <<'PY'
import json
import sys

with open(sys.argv[1]) as manifest:
    releases = json.load(manifest)
stable_hash = releases["current_release"]["stable"]
release = next(item for item in releases["releases"]
               if item["hash"] == stable_hash
               and item.get("dart_sdk_arch", "x64") == "x64")
print(releases["base_url"].rstrip("/") + "/" + release["archive"])
PY
)"
curl --fail --location --retry 3 "$archive_url" \
  --output "$sdk_dir/flutter.tar.xz"
tar -xJf "$sdk_dir/flutter.tar.xz" -C "$sdk_dir"
export PATH="$sdk_dir/flutter/bin:$PATH"

flutter config --enable-web

# Bootstrap may regenerate this cache without a usable Git-derived version.
# Restore the framework metadata from the same official release we downloaded.
python3 - "$sdk_dir/releases.json" "$sdk_dir/flutter/bin/cache/flutter.version.json" <<'PY'
import json
import sys
from pathlib import Path

with open(sys.argv[1]) as manifest:
    releases = json.load(manifest)
release = next(item for item in releases["releases"]
               if item["hash"] == releases["current_release"]["stable"]
               and item.get("dart_sdk_arch", "x64") == "x64")
version_file = Path(sys.argv[2])
version = json.loads(version_file.read_text())
version.update({
    "frameworkVersion": release["version"],
    "flutterVersion": release["version"],
    "frameworkRevision": release["hash"],
    "frameworkCommitDate": release["release_date"],
    "channel": release["channel"],
    "repositoryUrl": "https://github.com/flutter/flutter.git",
})
version_file.write_text(json.dumps(version))
PY

flutter pub get
flutter build web --release
