# Qwel v44 for iOS

Native SwiftUI/UIKit port of the uploaded Qwel-v44 source. Bundle ID: com.matwey181.qwelios. Minimum iOS 17. The generated IPA is unsigned; install through a sideloading tool that signs it for your device.

Implemented: project grid and persistence; JSON-compatible .qwel archive import/export with images and fonts from all pages; 81 original component definitions, 15 original templates and 42 exact cubic shapes; editable vector/text/image layers; groups and multi-selection; move/resize/rotate, pinch zoom and pan; undo/redo; layer order, visibility, locking; alignment and distribution; Core Graphics boolean operations; masks, gradients, shadows and layer blur; PNG/SVG export and Photos save; multi-page projects and action links; interactive native handling for switches, checks, radios, sliders, selections, counters and focus.

Platform differences and remaining gaps: native iOS chrome and SF Symbols replace Compose chrome and downloadable Material icon packs. Android wallpaper color extraction is replaced by a custom project seed color. Compose source-code export, onboarding gesture exercises and animated shape morphing are not ported. Interactive widgets use a native implementation; complex carousel/date-picker state and loading animations do not yet match every original behavior. SVG import supports geometry, text, groups and transforms; CSS stylesheets, SVG filters and external resources are not imported. SVG cannot express live backdrop blur. This initial port requires physical-device verification; simulator tests cover rendering, archives and editor actions.

Build: install Xcode and XcodeGen on macOS, then `cd ios && xcodegen generate`. ZIPFoundation is pinned to 0.9.20 (MIT). CI builds an arm64 IPA and runs unit/UI checks before publishing a prerelease.

The Kotlin sources under app/ are preserved from the provided archive. tools/ios-generator builds catalog.json by evaluating the original Components, Templates, ProjectStore and ShapeLibrary, with JVM adapters for Android context/localization and the archive's documented icon fallback. Font license: Resources/Figtree-OFL.txt.

## 0.2 interface and shared logic

The original UI palette, InterSA font, 70 procedural icons and three logo contours are now transferred from the Android sources. Floating editor chrome and inline panels follow the original dp dimensions. The original PlayMode, component tap handling, Echo and ComposeCode are compiled from Kotlin to a bundled script and run locally with JavaScriptCore; no network is needed. The platform adapters replace only JVM UUID, formatting and JSON APIs. tools/build_shared_core.py rebuilds this shared logic, and tools/extract_ui_assets.py extracts the original artwork.

The original AndroidX graphics-shapes 1.0.1 common sources are also compiled into the shared core, enabling the original morph calculations. The original ProjectExport produces Compose/CodeAssist archive contents, and Blend.kt handles contour interpolation with native length sampling. AndroidX source and license notices are preserved.

## 0.10.1 Apple component corrections

Apple catalog text now measures the bundled InterSA font, translates placeholder
keys, and preserves each label's center or edge when inserted. The v44 shared
engine receives temporary switch-role aliases; native iOS roles and geometry
remain in the document. Playback interpolates targets instead of snapping,
including the four-dp thumb stretch recovered from the supplied Vexel APK.
Exiting playback retains Apple styling and the selected state. Projects affected
by the previous Material-switch conversion are repaired when opened.

Backdrop buffers follow the actual canvas/thumbnail scale (capped at 2x and
4096 pixels), and Core Image renders each filtered result only over that layer's
bounds. Fonts and unchanged text layouts are reused during animation. These
changes reduce unnecessary rendering; physical-device frame rates still require
verification. AppleComponentTests cover layout, switch state persistence, legacy
repair, intermediate animation values, picker geometry and thumbnail scale.

## 0.10.2 alert rendering performance

CIContext is initialized lazily and reused, including across preview renderers.
Prepared Apple variants are reused per language and appearance. A glass layer on
a uniform page bypasses refraction and blur because those filters cannot alter
that backdrop. For detailed backgrounds, each layer reuses its filtered image
until its input layers, geometry or settings change; changing text above an
alert does not invalidate its backdrop. Unchanged composite scenes are also
reused during selection and panning. Layer-cache storage is bounded to 24 MiB.
Regression checks exercise both the uniform-page bypass and cache invalidation.

## 0.11 editable iOS-inspired components

New Apple presets and the iOS template use the system SF font, SF Symbols,
updated spacing, floating tab navigation and capsule dialog actions. Existing
saved designs are not automatically restyled. UI style iOS also uses the system
font. Symbols remain named, tintable layers in .qwel documents and native SF
Symbols in Swift exports; Compose archives embed rasterized PNGs.

The canvas glass optics now use a three-channel Core Image kernel for restrained
edge refraction, dispersion and saturation, plus a thin directional specular rim.
The resource includes research references and the MIT notice for the
BarredEwe/LiquidGlass optical approach. The existing uniform-background bypass,
scene cache and bounded backdrop cache remain in use. This is an imitation
compatible with iOS 17/18, not the operating system's iOS 26 material.

AppleComponentTests generate light/dark showcase images from the actual UIKit
renderer and exercise symbols, exports, the optics kernel and playback.
