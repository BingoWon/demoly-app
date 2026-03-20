# Demoly

> **Just Demo It.** — Create and share interactive web projects with AI.

Demoly is a creative platform where anyone can build and share interactive web projects. Describe your idea, AI generates the code, and you share living, breathing web experiences with the world.

<p align="center">
  <img src="screenshots/discover.png" width="230" alt="Discover Feed" />
  &nbsp;&nbsp;
  <img src="screenshots/create.png" width="230" alt="AI Creation" />
  &nbsp;&nbsp;
  <img src="screenshots/profile.png" width="230" alt="Profile" />
</p>

## Features

- **AI-Assisted Creation** — Describe what you want, AI builds it in real-time
- **Interactive Content** — Every project is a live web page you can touch, click, and play with
- **Discover Feed** — Browse a masonry feed of interactive creations from the community
- **Social** — Like, collect, comment, and follow creators
- **No Coding Required** — AI handles HTML, CSS, and JavaScript for you

## Tech Stack

| Layer | Technology |
|-------|------------|
| Platform | iOS / iPadOS |
| UI Framework | SwiftUI |
| Content Rendering | WKWebView |
| Code Editor | Runestone + Tree-sitter |
| Authentication | Clerk (Apple Sign-In, Google Sign-In) |
| Backend | Cloudflare Workers + Hono |
| Database | Cloudflare D1 |
| Storage | Cloudflare R2 |
| Package Manager | Swift Package Manager |

## Getting Started

### Prerequisites

- Xcode 16.0+
- iOS 18.0+ deployment target

### Setup

1. Clone the repository
2. Open `Demoly.xcodeproj` in Xcode
3. Copy `Config/Debug.xcconfig.example` to `Config/Debug.xcconfig` and fill in your keys
4. Build and run

## Project Structure

```
demoly-app/
├── Demoly/                    # Main app target
│   ├── DemolyApp.swift        # App entry point
│   ├── Models/                # Data models
│   ├── Services/              # API & AI services
│   ├── ViewModels/            # View models
│   └── Views/                 # SwiftUI views
│       ├── Create/            # AI creation flow
│       ├── Feed/              # Discover feed
│       ├── Profile/           # User profile
│       └── Share/             # Share sheet
├── Config/                    # Build configurations
├── SupportingFiles/           # Info.plist
└── screenshots/               # App screenshots
```

## License

Copyright © 2026 Demoly. All rights reserved.
