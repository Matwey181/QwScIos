# Vexel v6 UX update

## Guided, in-context onboarding
- Replaced the three static quick-start explanation cards with a short welcome message that tells users to open or create a project.
- Added a two-step coachmark in the actual editor: it outlines the `+` button, then outlines the insertion panel.
- The highlighted controls remain interactive; tapping `+` advances the guide, and adding an object completes it.
- Added a skip action and persisted completion through the existing hints preferences. Replaying onboarding resets the guide.
- Added Russian and English copy.

## Design
- Coachmarks use Material 3 `secondaryContainer`, Material 3 typography, and the app's shape tokens.
- The target is outlined using the active theme's primary color, including dark and dynamic color schemes.

## Verification
- Language JSON files were parsed successfully.
- A Gradle/APK build could not be run because this exported Code Assist project does not include Gradle build scripts or a wrapper.
