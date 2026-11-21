# QwSc iOS

Native iPhone/iPad port of [QwScDroid](https://github.com/Cheburek-Qwenz/QwScDroid).
Requires iOS 17 or later. This is a development port, not yet tested on a physical device.

## Features

- The original C++ processing engine, statically compiled for arm64 iOS.
- PNG ↔ SCTX/KTX, SC textures, split/join, extract, PNG → SC, GIF ↔ SC, MovieClip operations and sprite injection.
- Atlas and polygon-masked sprite previews, texture selector, PNG export, sprite replacement.
- Export-name editor: rename, add and delete; save to a new SC file.
- Files import, file sharing, Quick Look, and persistent results in the app's Documents folder.
- All native operations run on a background serial queue. Original files are not overwritten by the UI.

Import an SC and its companion `_tex.sc`/SCTX files **together**. They must remain in the same folder.
Choose the logic SC in the editor after importing.

### Known limitations

- **Downgrade is unavailable**: upstream supplies only an Android ELF `libScDowngrade.so`, with no implementation source. It cannot be loaded on iOS. The unrelated header-changing helper in `sc_ops.cpp` is deliberately not presented as a real format downgrade.
- Android's document provider, APK auto-updater, and Android dynamic theme are replaced with the iOS file picker, sharing and system appearance.
- Batch replacement is available through the original TXT list interface. The native syntax uses absolute imported file paths; copy them from the Files tab.
- No iPhone runtime, real game asset compatibility, peak memory or performance claim has been verified yet. Local tests create synthetic assets; they do not establish support for every Supercell version.

## Download and installation

The **Build iOS IPA** GitHub Actions workflow publishes `QwScIos.ipa` as an artifact and a prerelease download after a successful build.
The IPA is unsigned. Install it with an installer that signs for your device, such as iLoader/SideStore, or sign it with your own Apple development/distribution credentials.
An unsigned download cannot be installed by merely opening it in Files.

## Build

On macOS with Xcode, CMake and XcodeGen:

```sh
brew install cmake xcodegen
bash ios/build.sh
```

Output: `build/QwScIos.ipa`.

Portable engine tests (macOS/Linux):

```sh
cmake -S ios/Native -B build/host -DCMAKE_BUILD_TYPE=Release -DQW_BUILD_TESTS=ON
cmake --build build/host --parallel 3
ctest --test-dir build/host --output-on-failure
```

`ios/Native/compat/jni.h` is a small local string adapter, not a JVM. It lets the existing JNI entry-point bodies be reused without modifying their processing behavior. The Android-only downgrade loader is excluded.

## License

Upstream source and its changes remain MPL-2.0. New iOS adapter, Swift sources and build files are provided under MPL-2.0.
Bundled third-party notices are in `Resources/Licenses.txt` and in the upstream source tree.
Copyright notices remain in their respective upstream files. GIF ↔ SC idea and format: @Ghoul1337i.
