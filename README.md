# CleanSnap

A photo cleaner that finds your duplicates, screenshots, and storage hogs without uploading anything to the cloud. Built with the Photos framework, MVVM architecture, and Maestro-tested UI flows.

## Features

- **Duplicate detection** — finds similar and exact-match photos
- **Smart categorization** — screenshots, Live Photos, large files, old photos
- **Batch delete** with undo safety net
- **Storage savings calculator** — see how much space you'll free
- **Privacy-first** — all processing on-device, zero network calls
- **Before/after comparison** for similar photos

## Tech Stack

- SwiftUI
- Photos framework (PHAsset)
- Vision framework (perceptual hashing)
- MVVM architecture
- Maestro for UI testing

## Getting Started

```bash
git clone https://github.com/sebastiandoyle/cleansnap.git
cd cleansnap
open *.xcodeproj
```

Requires Xcode 15+ and iOS 17+. Photo library access required.

## Architecture

Clean MVVM with a `PhotoAnalyzer` service layer handling the Photos framework queries and a `DuplicateEngine` using perceptual hashing via the Vision framework. UI tests written in Maestro for automated screenshot capture and flow validation.

## License

MIT
