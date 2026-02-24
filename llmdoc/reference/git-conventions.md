# Git Conventions

## Commit Scope

- Keep commits focused and behaviorally coherent.
- Do not include unrelated formatting or refactors with feature/bug changes.

## Validation Before Delivery

- Preferred local wrapper: `./scripts/verify-local.sh`
- `swift test --package-path Core`
- `xcodebuild -project demo.xcodeproj -scheme demo -destination 'platform=macOS' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build`
- `xcodebuild -project demo.xcodeproj -scheme demo -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build`
- `swiftlint lint demo Core/Sources Core/Tests`

If any command is skipped due environment limits, report it explicitly in handoff notes.
