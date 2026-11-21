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
  "LIBRARY_SEARCH_PATHS=$(pwd)/build/sim-native" "ARCHS=$sim_arch" ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
if [ -f build/simulator-id ]; then
  sim_id="$(cat build/simulator-id)"
else
  sim_id="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(x["udid"] for group in d["devices"].values() for x in group if x["name"].startswith("iPhone")))')"
  xcrun simctl boot "$sim_id"
fi
xcrun simctl bootstatus "$sim_id" -b
xcrun simctl install "$sim_id" build/SimDerivedData/Build/Products/Debug-iphonesimulator/QwScIos.app
xcrun simctl launch "$sim_id" com.matwey181.qwscios
# Wait for the first SwiftUI frame, then confirm the process still exists.
sleep 5
xcrun simctl spawn "$sim_id" launchctl list | grep 'com.matwey181.qwscios'
xcrun simctl io "$sim_id" screenshot build/iOS-launch.png
app_data="$(xcrun simctl get_app_container "$sim_id" com.matwey181.qwscios data)"
python3 - "$app_data" <<'PY'
import pathlib, struct, sys, zlib
folder = pathlib.Path(sys.argv[1]) / 'Documents'
folder.mkdir(exist_ok=True)
def chunk(kind, data):
    return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data) & 0xffffffff)
def png(color):
    header = struct.pack('>IIBBBBB', 8, 8, 8, 6, 0, 0, 0)
    rows = (b'\x00' + bytes(color) * 8) * 8
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', header) + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b'')
for name, color in [('import-test-a.png', (220, 60, 30, 255)), ('import-test-b.png', (30, 70, 220, 255))]:
    (folder / name).write_bytes(png(color))
PY
xcodebuild -project ios/QwScIos.xcodeproj -scheme QwScIos -configuration Debug \
  -sdk iphonesimulator -destination "platform=iOS Simulator,id=$sim_id" \
  -derivedDataPath build/SimDerivedData -resultBundlePath build/ImportTests.xcresult \
  -parallel-testing-enabled NO \
  "LIBRARY_SEARCH_PATHS=$(pwd)/build/sim-native" "ARCHS=$sim_arch" ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO test
xcrun simctl shutdown "$sim_id"
