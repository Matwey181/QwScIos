#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 ios/generate_bridge.py
sdk_path="$(xcrun --sdk iphoneos --show-sdk-path)"
cmake -S ios/Native -B build/ios-native \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdk_path" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO
cmake --build build/ios-native --parallel 3
xcodegen generate --spec ios/project.yml
xcodebuild -project ios/QwScIos.xcodeproj -scheme QwScIos -configuration Release \
  -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO build
mkdir -p build/ipa/Payload
cp -R build/DerivedData/Build/Products/Release-iphoneos/QwScIos.app build/ipa/Payload/
test "$(lipo -archs build/ipa/Payload/QwScIos.app/QwScIos)" = arm64
plutil -lint build/ipa/Payload/QwScIos.app/Info.plist
(cd build/ipa && zip -qry ../QwScIos.ipa Payload)
shasum -a 256 build/QwScIos.ipa > build/QwScIos.ipa.sha256
echo 'IPA ready for signing with your sideload installer: build/QwScIos.ipa'
