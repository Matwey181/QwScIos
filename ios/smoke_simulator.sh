#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
sim_sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
sim_arch="$(uname -m)"
cmake -S ios/Native -B build/sim-native \
  -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sim_sdk" \
  -DCMAKE_OSX_ARCHITECTURES="$sim_arch" -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO
cmake --build build/sim-native --parallel 3
xcodebuild -project ios/QwScIos.xcodeproj -scheme QwScIos -configuration Debug \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/SimDerivedData \
  "LIBRARY_SEARCH_PATHS=$(pwd)/build/sim-native" CODE_SIGNING_ALLOWED=NO build
sim_id="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(x["udid"] for group in d["devices"].values() for x in group if x["name"].startswith("iPhone")))')"
xcrun simctl boot "$sim_id"
xcrun simctl bootstatus "$sim_id" -b
xcrun simctl install "$sim_id" build/SimDerivedData/Build/Products/Debug-iphonesimulator/QwScIos.app
xcrun simctl launch "$sim_id" com.matwey181.qwscios
# Wait for the first SwiftUI frame, then confirm the process still exists.
sleep 5
xcrun simctl spawn "$sim_id" launchctl list | grep 'com.matwey181.qwscios'
xcrun simctl io "$sim_id" screenshot build/iOS-launch.png
xcrun simctl shutdown "$sim_id"
