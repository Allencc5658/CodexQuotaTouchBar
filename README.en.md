# Codex Quota Touch Bar

[简体中文](README.md) · [Privacy](PRIVACY.md) · [Security](SECURITY.md) · [Build guide](docs/BUILD.en.md)

An unofficial Swift/AppKit menu bar utility that shows remaining Codex quota on a Mac with a Touch Bar. It launches the locally installed `codex app-server --listen stdio://` and calls `account/rateLimits/read` over JSON-RPC. It does not scrape websites or ask for your password or token.

![Preview with simulated Plus data](preview.png)

## Features

- Two segmented rows for a Plus account: five-hour and weekly limits. Pro hides the five-hour row. Other plans follow the windows returned by app-server.
- Remaining percentage is `max(0, min(100, 100 - usedPercent))`; reset times use the Mac's local time zone.
- Menu bar summary, manual refresh, and a Touch Bar restore action. Refreshes every two minutes while keeping the previous value visible until a new result arrives.
- Automatically follows the preferred macOS language, with manual Simplified Chinese, Traditional Chinese, and English choices. Optional launch at login on macOS 13 or later.
- Builds for Intel and Apple Silicon. The menu bar works without a Touch Bar.

## Build and run

Install and sign in to Codex locally, then run `./build.sh` and `./test.sh`. Move the generated `Codex Quota.app` into `/Applications` and open it from Launchpad or Spotlight. The app runs in the menu bar rather than the Dock.

The app first looks for `/Applications/Codex.app/Contents/Resources/codex`, then the Codex CLI bundled with `/Applications/ChatGPT.app`. You can choose a trusted executable in Settings. This repository does not bundle Codex or credentials. See the [step-by-step build guide](docs/BUILD.md) for requirements, verification commands, and troubleshooting.

## Privacy and distribution

The app stores only its language choice and a user-selected Codex executable path. Quotas remain in memory. It calls `account/read` only if the quota response lacks a plan; that response can contain an email, but the app only reads the plan field. See [PRIVACY.md](PRIVACY.md).

The persistent Touch Bar uses **private macOS APIs** and can break after a system update. The local build is **ad hoc signed**, not Developer ID signed or notarized. Follow the [release checklist](docs/RELEASE.md) before distributing a binary. This project is not affiliated with OpenAI and is not an official Codex client.

License: [MIT](LICENSE). For security reports, read [SECURITY.md](SECURITY.md).
