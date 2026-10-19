#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app_path="$project_dir/build/Build/Products/Release/toc.app"
output_dir="$project_dir/dist"

if [[ ! -x "$app_path/Contents/MacOS/toc" ]]; then
    printf 'Falta la app Release: %s\nCompila toc antes de empaquetar.\n' "$app_path" >&2
    exit 1
fi

bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_path/Contents/Info.plist")"
if [[ "$bundle_id" != "com.seba.toc" ]]; then
    printf 'Bundle ID inesperado: %s\n' "$bundle_id" >&2
    exit 1
fi
/usr/bin/codesign --verify --deep --strict "$app_path"

mkdir -p "$output_dir"
work_dir="$(mktemp -d "$project_dir/build/dmg-stage.XXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT
mkdir "$work_dir/payload"

/usr/bin/ditto "$app_path" "$work_dir/payload/Toc.app"
cp "$project_dir/LICENSE" "$work_dir/payload/LICENSE"
cp "$project_dir/docs/INSTALAR.txt" "$work_dir/payload/LEEME.txt"
ln -s /Applications "$work_dir/payload/Applications"

/usr/bin/hdiutil create \
    -volname Toc \
    -srcfolder "$work_dir/payload" \
    -fs HFS+ \
    -format UDZO \
    "$work_dir/toc.dmg"
/usr/bin/hdiutil verify "$work_dir/toc.dmg"

mv -f "$work_dir/toc.dmg" "$output_dir/toc.dmg"
(
    cd "$output_dir"
    /usr/bin/shasum -a 256 toc.dmg > toc.dmg.sha256
)
printf 'DMG generado: %s\nSHA-256: %s\n' "$output_dir/toc.dmg" "$output_dir/toc.dmg.sha256"
