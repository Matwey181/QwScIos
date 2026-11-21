# Qwel v44 for iOS

Native SwiftUI/UIKit port of the uploaded Qwel-v44 source. Bundle ID: com.matwey181.qwelios. Minimum iOS 17. The generated IPA is unsigned; install through a sideloading tool that signs it for your device.

Implemented: project grid and persistence; JSON-compatible .qwel archive import/export with images and fonts from all pages; 81 original component definitions, 15 original templates and 42 exact cubic shapes; editable vector/text/image layers; groups and multi-selection; move/resize/rotate, pinch zoom and pan; undo/redo; layer order, visibility, locking; alignment and distribution; Core Graphics boolean operations; masks, gradients, shadows and layer blur; PNG/SVG export and Photos save; multi-page projects and action links; interactive native handling for switches, checks, radios, sliders, selections, counters and focus.

Platform differences and remaining gaps: native iOS chrome and SF Symbols replace Compose chrome and downloadable Material icon packs. Android wallpaper color extraction is replaced by a custom project seed color. Compose source-code export, onboarding gesture exercises and animated shape morphing are not ported. Interactive widgets use a native implementation; complex carousel/date-picker state and loading animations do not yet match every original behavior. SVG import supports geometry, text, groups and transforms; CSS stylesheets, SVG filters and external resources are not imported. SVG cannot express live backdrop blur. This initial port requires physical-device verification; simulator tests cover rendering, archives and editor actions.

Build: install Xcode and XcodeGen on macOS, then `cd ios && xcodegen generate`. ZIPFoundation is pinned to 0.9.20 (MIT). CI builds an arm64 IPA and runs unit/UI checks before publishing a prerelease.

The Kotlin sources under app/ are preserved from the provided archive. tools/ios-generator builds catalog.json by evaluating the original Components, Templates, ProjectStore and ShapeLibrary, with JVM adapters for Android context/localization and the archive's documented icon fallback. Font license: Resources/Figtree-OFL.txt.

## 0.2 interface and shared logic

The original UI palette, InterSA font, 70 procedural icons and three logo contours are now transferred from the Android sources. Floating editor chrome and inline panels follow the original dp dimensions. The original PlayMode, component tap handling, Echo and ComposeCode are compiled from Kotlin to a bundled script and run locally with JavaScriptCore; no network is needed. The platform adapters replace only JVM UUID, formatting and JSON APIs. tools/build_shared_core.py rebuilds this shared logic, and tools/extract_ui_assets.py extracts the original artwork.
