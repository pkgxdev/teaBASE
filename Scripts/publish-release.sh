#!/usr/bin/env -S pkgx +gh +create-dmg +npx bash -eo pipefail

if ! test "$APPLE_PASSWORD"; then
  echo "\$APPLE_PASSWORD must be set to an Apple App Specific Password"
  exit 1
fi
if ! test "$APPLE_USERNAME"; then
  echo "\$APPLE_USERNAME must be set to the Apple ID for the \$APPLE_PASSWORD"
  exit 2
fi

versions="$(git tag | grep '^v[0-9]\+\.[0-9]\+\.[0-9]\+')"
v="$(npx -- semver --include-prerelease $versions | tail -n1)"

tmp_xcconfig="$(mktemp)"
echo "MARKETING_VERSION = $v" > "$tmp_xcconfig"

xcodebuild \
  -scheme teaBASE \
  -configuration Release \
  -xcconfig "$tmp_xcconfig" \
  -derivedDataPath ./build \
  build

codesign \
  --entitlements ~/src/teaBASE/Sundries/teaBASE.entitlements \
  --deep --force \
  --options runtime \
  --sign "Developer ID Application: Tea Inc. (7WV56FL599)" \
  build/Build/Products/Release/teaBASE.prefPane

create-dmg \
  --volname "teaBASE v$v" \
  --window-size 435 435 \
  --window-pos 538 273 \
  --filesystem APFS \
  --format ULFO \
  --background ./Resources/dmg-bg@2x.png \
  --icon teaBASE.prefPane 217.5 223.5 \
  --hide-extension teaBASE.prefPane \
  --icon-size 100 \
  teaBASE-$v.dmg \
  build/Build/Products/Release/teaBASE.prefPane

codesign \
  --force \
  --sign "Developer ID Application: Tea Inc. (7WV56FL599)" \
  ./teaBASE-$v.dmg

xcrun notarytool submit \
  --apple-id $APPLE_USERNAME \
  --team-id 7WV56FL599 \
  --password $APPLE_PASSWORD \
  --wait \
  ./teaBASE-$v.dmg

xcrun stapler staple ./teaBASE-$v.dmg

gh release upload --clobber --repo pkgxdev/teaBASE v$v teaBASE-$v.dmg
