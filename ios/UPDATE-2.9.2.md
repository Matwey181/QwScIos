# Android 2.9.2 → iOS 0.13

Source APK: package `com.qwenz.qwel`, versionName `2.9.2`, versionCode `92`.
SHA-256: `ca802c53bb7d840d87bb7aa6f8a83606ee99a8c3cfed623812c52765adbd4c98`.
Compared against the previous uploaded APK, version 2.8.8 / 88.

The APK was extracted in full and decompiled with JADX 1.5.7. JADX reported 231
method recovery errors across application and third-party classes; recovered Java
is a reconstruction, not the author's original Kotlin project.

Implemented natively for iOS:

- The Android `motion` JSON format, per-layer/group tracks, relative translation,
  scale, rotation, opacity, radius, blur, dimensions, color and shape morphing.
- Timeline with key creation, editing/deletion, previous/next navigation,
  preview/scrubbing, auto-key dragging and layout dragging, duration/loop and timed
  page navigation.
- All 63 animation factories and 45 curve presets recovered from the APK's pure
  data factories. `tools/recover_motion_presets.py` reproduces the resource; it
  runs only recovered factory bodies against inert desktop model stubs.
- Bezier, chained Bezier, natural-duration springs, elastic, bounce and steps.
- H.264 MP4 and PNG sequence export at 24/30/60 fps; game preview recording with
  touch indicators, selectable 720/1080/1440/2160 long-edge resolution.
- Page-to-page video transitions; drawing uses the same document renderer,
  including fonts, blur and cached glass.
- Pen tool with editable knots, curve handles, open/closed paths and undoable
  commit; two-finger canvas navigation remains available.
- Configurable polygon/star tool and a locked, crop-to-fill background image.
- Independent rectangle corners and four glass optics parameters, retained by
  JSON archives and the legacy Kotlin/JS widget bridge.
- Visibility appearance effects and four motion choices.
- Independent canvas-edge, canvas-center, layer-edge and layer-center snapping.
- iOS 26 alert/context menu and five additional editable iOS screen templates.
- Tab count editing for one or multiple tab bars; smooth indicator stretching.
- Updated RU/EN strings, cached localization and cached stationary widget output
  during native timeline playback.

Platform adaptations: Android AGSL uses a Core Image implementation on iOS; the
Apple component catalog uses the public system font and SF Symbols. MP4 does not
record microphone/system audio. This is a native port, not a binary patch or an
assertion of pixel-identical rendering. SwiftUI export embeds the keyframe
player and curve evaluators; timelines are retained in the editable `.qwel`
document and exported to MP4/PNG. Compose export uses the existing Android v44
generator and does not yet generate the new 2.9.2 timeline playback code.

Validation: the CI workflow builds the arm64 IPA and runs motion/model/video
round-trip checks plus the existing Apple widget/rendering regression suite.
Real-device performance depends on project size, glass area and video resolution.
