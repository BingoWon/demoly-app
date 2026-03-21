<p align="center">
  <a href="https://github.com/BingoWon/demoly-app">
    <img src=".github/assets/logo.png" width="80" alt="Demoly" />
  </a>
</p>

<h1 align="center">Demoly</h1>

<p align="center">
  <strong>Just Demo It.</strong>
</p>

<p align="center">
  Describe your idea. AI builds it. Share it with the world.
</p>

<p align="center">
  <a href="https://apps.apple.com/app/demoly">
    <img src="https://img.shields.io/badge/App_Store-0D96F6?style=flat&logo=app-store&logoColor=white" alt="App Store" />
  </a>
  &nbsp;
  <a href="README.zh-CN.md">简体中文</a>
</p>

<br />

<p align="center">
  <img src="screenshots/discover.png" width="220" alt="Discover" />
  &nbsp;
  <img src="screenshots/create.png" width="220" alt="Create" />
  &nbsp;
  <img src="screenshots/profile.png" width="220" alt="Profile" />
</p>

<br />

## What is Demoly?

Demoly is a creative platform for iOS where anyone can build and share interactive web projects — no coding needed. Just describe what you want in plain language, and AI turns it into a real, touchable web experience.

## Highlights

🤖 **AI Creation** — Describe your idea, watch AI build it live with HTML, CSS & JS

🎨 **Interactive** — Every project is a real web page you can tap, drag, scroll and play with

🌍 **Discover** — Browse a masonry feed of amazing creations from the community

💬 **Social** — Like, save, comment, and follow your favorite creators

## Tech Stack

| | |
|---|---|
| **App** | SwiftUI · WKWebView · Runestone · Tree-sitter |
| **Backend** | Cloudflare Workers · Hono · D1 · R2 |
| **Auth** | Clerk — Apple & Google Sign-In |

## Getting Started

> Requires **Xcode 16.0+** and **iOS 18.0+**

```bash
git clone https://github.com/BingoWon/demoly-app.git
cd demoly-app
open Demoly.xcodeproj
```

Add your API keys to `Config/Debug.xcconfig`, then build and run.

## Project Structure

```
Demoly/
├── Models/         Data models
├── Services/       API & AI services
├── ViewModels/     View models
└── Views/
    ├── Create/     AI creation flow
    ├── Feed/       Discover feed
    ├── Profile/    User profile & settings
    └── Share/      Share sheet
```

## Contributing

Contributions are welcome — feel free to open an issue or submit a pull request.

1. Fork the repo
2. Create your branch — `git checkout -b feature/my-feature`
3. Commit — `git commit -m 'feat: add my feature'`
4. Push — `git push origin feature/my-feature`
5. Open a Pull Request

We follow [Conventional Commits](https://www.conventionalcommits.org/).
