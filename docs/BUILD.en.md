# Build from source

[中文版](BUILD.md)

This guide starts from a clean source checkout. Building and running the fake app-server tests do not require a Codex login or network access. A local Codex login is needed only for a live quota probe.

## Requirements

- macOS with Apple Command Line Tools: `xcrun`, `swiftc`, `clang`, `lipo`, `codesign`, and `ditto`. Tests also require `python3`; there are no Homebrew or third-party Swift package dependencies.
- Build targets: Intel macOS 10.14+ and Apple Silicon macOS 11+. Only Intel macOS 13.7.8 with Swift 5.8.1, SDK 13.3, and Python 3.9.6 has been tested here. Touch Bar hardware is optional for the menu bar; launch at login needs macOS 13+.

Install Command Line Tools if necessary:

```sh
xcode-select --install
xcrun --find swiftc
python3 --version
```

## Clean build and simulated tests

Clone the repository or extract its GitHub Source code ZIP:

```sh
git clone https://github.com/Allencc5658/CodexQuotaTouchBar.git
cd CodexQuotaTouchBar
./build.sh
./test.sh
```

`build.sh` compiles Intel and Apple Silicon slices, copies the bundled icon and localization resources, and adds a local **ad hoc** signature. `test.sh` runs model tests and a fake JSON-RPC server for Plus, Pro, missing plan fallback, unexpected disconnection, and language display. Its data is simulated. `Codex Quota.app` and `.build/` are generated; neither is needed in the source repository.

Verify the result:

```sh
lipo -info 'Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar'
plutil -lint 'Codex Quota.app/Contents/Info.plist'
codesign --verify --deep --strict 'Codex Quota.app'
```

The first command should list `x86_64` and `arm64`; the others should succeed. To put build caches elsewhere, set `CODEX_QUOTA_BUILD_DIR` to an absolute directory.

## Optional live probe and installation

Install and sign in to Codex locally. The following command prints your real plan and quota to the terminal; do not paste its output into a public issue:

```sh
'./Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar' --probe
```

The app first looks for `/Applications/Codex.app/Contents/Resources/codex`, then the Codex CLI bundled with `/Applications/ChatGPT.app`. For another trusted executable:

```sh
CODEX_QUOTA_CODEX_PATH='/absolute/path/to/codex' \
  './Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar' --probe
```

Move the built app to `/Applications` in Finder and open it from Launchpad or Spotlight. It runs in the menu bar. A missing Codex executable can be selected in Settings; a missing physical Touch Bar does not affect the menu bar. Language can be selected in Settings. The persistent Touch Bar depends on private macOS APIs and may be incompatible with a newer system release.

The checked-in icon files were drawn by `Assets/generate-icon.swift`. Regenerating them is optional for a normal build. For public binary distribution, follow [RELEASE.md](RELEASE.md): this local ad hoc build is not Developer ID signed or notarized.
