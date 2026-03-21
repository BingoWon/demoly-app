<p align="center">
  <img src="screenshots/discover.png" width="230" alt="Discover" />
  &nbsp;&nbsp;
  <img src="screenshots/create.png" width="230" alt="Create" />
  &nbsp;&nbsp;
  <img src="screenshots/profile.png" width="230" alt="Profile" />
</p>

<h1 align="center">Demoly</h1>

<p align="center">
  <strong>Just Demo It.</strong><br/>
  Create and share interactive web projects with AI.
</p>

<p align="center">
  <a href="README.zh-CN.md">中文</a>
</p>

---

Demoly is a creative platform where anyone can build and share interactive web projects — no coding skills needed. Describe your idea in plain language, AI generates real HTML/CSS/JS, and you publish a living, interactive experience for the world to explore.

## Features

- **AI-Powered Creation** — Chat with AI to build interactive web projects in real time
- **Interactive Content** — Every project is a live web page people can touch, click, and play with
- **Discover Feed** — Browse a masonry grid of creations from the community
- **Social** — Like, collect, comment, and follow your favorite creators
- **Zero Coding Barrier** — AI handles all the HTML, CSS, and JavaScript

## Tech Stack

| Layer | Technology |
|-------|------------|
| Platform | iOS / iPadOS |
| UI | SwiftUI |
| Rendering | WKWebView |
| Code Editor | Runestone + Tree-sitter |
| Auth | Clerk (Apple, Google) |
| Backend | Cloudflare Workers + Hono |
| Database | Cloudflare D1 |
| Storage | Cloudflare R2 |
| Packages | Swift Package Manager |

## Getting Started

**Prerequisites:** Xcode 16.0+, iOS 18.0+ target

```bash
git clone https://github.com/BingoWon/demoly-app.git
cd demoly-app
open Demoly.xcodeproj
```

Fill in your API keys in `Config/Debug.xcconfig`, then build and run.

## Project Structure

```
Demoly/
├── Models/            # Data models
├── Services/          # API & AI services
├── ViewModels/        # View models
└── Views/
    ├── Create/        # AI creation flow
    ├── Feed/          # Discover feed
    ├── Profile/       # User profile & settings
    └── Share/         # Share sheet
```

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

1. Fork the repository
2. Create your branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages.
