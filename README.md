<img src="RadioLibre/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="200" />

# RadioLibre

Native iOS internet radio player powered by the [Radio Browser](https://www.radio-browser.info/) community database (30,000+ stations).
iOS counterpart to [RadioDroid](https://github.com/segler-alex/RadioDroid) (Android).

- iOS 16+, SwiftUI, no third-party dependencies
- License: GPL-3.0

## Development

This app is being built mostly using Claude Code. Relevant files:

- [SPEC.md](SPEC.md) — this is the behavioral truth. Every UI behavior, API call, and edge case defined here.
- [PLAN.md](PLAN.md) — this is the architectural guide. It defines the file structure, patterns, and phased delivery.
- [.claude/commands/implement.md](.claude/commands/implement.md) - Skill to implement new features by running `/implement audio playback`.

### Prerequisites

- Xcode 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — install with `brew install xcodegen`

### Generate the Xcode Project

The `.xcodeproj` is generated from `project.yml` using XcodeGen. Run this after cloning, and after adding or removing any `.swift` file:

```bash
xcodegen generate
```

### Build

```bash
xcodebuild -project RadioLibre.xcodeproj -scheme RadioLibre \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -quiet build
```

### Run Tests

```bash
xcodebuild -project RadioLibre.xcodeproj -scheme RadioLibre \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES test
```

To see just the summary (pass/fail counts and errors):

```bash
xcodebuild -project RadioLibre.xcodeproj -scheme RadioLibre \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES test 2>&1 \
  | grep -E '(error:.*\.swift|Executed|TEST SUCCEEDED|TEST FAILED)'
```

### Clean

```bash
xcodebuild -project RadioLibre.xcodeproj -scheme RadioLibre clean
```

### Open in Xcode

```bash
open RadioLibre.xcodeproj
```

### CI

GitHub Actions runs build and tests on every push and PR to `main` (see `.github/workflows/ios.yml`).

## Attribution

This app icon uses the svg version of [Levitating, Meditating, Flute-playing Gnu](https://www.gnu.org/graphics/meditate.html).

Special thanks to [Radio Browser](https://www.radio-browser.info/) which provides the radio data. You can make a
[donation (one time or repeating)](https://ko-fi.com/segleralex) or
[contribute in other ways](https://www.radio-browser.info/faq).

Also to [RadioDroid](https://github.com/segler-alex/RadioDroid) from which this project is inspired.
