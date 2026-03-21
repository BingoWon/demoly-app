<p align="center">
  <img src="screenshots/discover.png" width="230" alt="发现" />
  &nbsp;&nbsp;
  <img src="screenshots/create.png" width="230" alt="创作" />
  &nbsp;&nbsp;
  <img src="screenshots/profile.png" width="230" alt="主页" />
</p>

<h1 align="center">Demoly</h1>

<p align="center">
  <strong>Just Demo It.</strong><br/>
  用 AI 创作和分享互动 Web 作品。
</p>

<p align="center">
  <a href="README.md">English</a>
</p>

---

Demoly 是一个面向所有人的创意平台——不需要写代码，只需要描述你的想法，AI 就能生成可交互的 Web 作品（HTML/CSS/JS），发布后全世界都能体验。

## 功能亮点

- **AI 驱动创作** — 用自然语言和 AI 对话，实时生成互动 Web 项目
- **可交互内容** — 每个作品都是真实的网页，可以点击、拖拽、滑动
- **发现信息流** — 瀑布流浏览社区中的精彩创作
- **社交互动** — 点赞、收藏、评论、关注你喜欢的创作者
- **零门槛** — HTML、CSS、JavaScript 全部交给 AI

## 技术栈

| 层面 | 技术 |
|------|------|
| 平台 | iOS / iPadOS |
| UI 框架 | SwiftUI |
| 内容渲染 | WKWebView |
| 代码编辑器 | Runestone + Tree-sitter |
| 登录认证 | Clerk（Apple 登录、Google 登录）|
| 后端 | Cloudflare Workers + Hono |
| 数据库 | Cloudflare D1 |
| 存储 | Cloudflare R2 |
| 包管理 | Swift Package Manager |

## 快速开始

**环境要求：** Xcode 16.0+，iOS 18.0+ 部署目标

```bash
git clone https://github.com/BingoWon/demoly-app.git
cd demoly-app
open Demoly.xcodeproj
```

在 `Config/Debug.xcconfig` 中填入你的 API 密钥，然后编译运行即可。

## 项目结构

```
Demoly/
├── Models/            # 数据模型
├── Services/          # API 与 AI 服务
├── ViewModels/        # 视图模型
└── Views/
    ├── Create/        # AI 创作流程
    ├── Feed/          # 发现信息流
    ├── Profile/       # 个人主页与设置
    └── Share/         # 分享功能
```

## 参与贡献

欢迎贡献代码！你可以提 Issue 或提交 Pull Request。

1. Fork 本仓库
2. 创建分支（`git checkout -b feature/amazing-feature`）
3. 提交改动（`git commit -m 'feat: add amazing feature'`）
4. 推送分支（`git push origin feature/amazing-feature`）
5. 发起 Pull Request

提交信息请遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范。
