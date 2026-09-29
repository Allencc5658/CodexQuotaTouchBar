# 从零构建与验证 / Reproducible build

本教程从一个全新源码目录开始，不依赖仓库作者电脑上的构建缓存或登录数据。构建本身不需要 Codex 登录；只有读取真实额度时需要本机已登录的 Codex。

## 1. 前提条件

- 一台 macOS 电脑和 Apple Command Line Tools。编译需要 `xcrun`、`swiftc`、`clang`、`lipo`、`codesign`、`ditto`；测试另需 `python3`。不依赖 Homebrew 或第三方 Swift 包。
- `build.sh` 的目标为 Intel macOS 10.14+ 与 Apple Silicon macOS 11+。目前只在一台 Intel macOS 13.7.8、Swift 5.8.1、macOS SDK 13.3、Python 3.9.6 上运行了构建及测试；其他组合尚需实机验证。
- Touch Bar 硬件仅影响 Touch Bar 显示；菜单栏可在没有 Touch Bar 的 Mac 上运行。“登录时启动”需要 macOS 13+。

如未安装 Command Line Tools：

```sh
xcode-select --install
```

确认工具：

```sh
xcrun --find swiftc
xcrun --find clang
xcrun --find lipo
xcrun --find codesign
python3 --version
```

## 2. 获取源码

也可以下载 GitHub 的 Source code ZIP 并进入解压目录。

```sh
git clone https://github.com/Allencc5658/CodexQuotaTouchBar.git
cd CodexQuotaTouchBar
```

源码目录应有 `Sources/`、`Resources/`、`Assets/`、`Tests/`、`build.sh` 和 `test.sh`。`Codex Quota.app` 和 `.build/` 是生成物，不需要从仓库下载。

## 3. 构建与模拟测试

```sh
./build.sh
./test.sh
```

`build.sh` 编译两个架构、复制本地化文本及图标，再做 **ad hoc** 本地签名。`test.sh` 先测试额度计算，再启动模拟 app-server 验证 JSON-RPC 握手、Plus/Pro 行数、套餐缺失时的兜底请求、服务异常断开，以及英文/繁体中文显示。测试使用固定的假数据，不需联网或登录。

验证生成物：

```sh
lipo -info 'Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar'
plutil -lint 'Codex Quota.app/Contents/Info.plist'
codesign --verify --deep --strict 'Codex Quota.app'
```

`lipo` 应列出 `x86_64` 与 `arm64`；其余两个命令应成功。默认缓存写到 `.build/`，可用 `CODEX_QUOTA_BUILD_DIR=/path/to/cache` 改到别处。

## 4. 读取本机真实额度（可选）

本机需安装并登录 Codex。运行以下命令会把**真实**套餐和额度输出到终端，请勿把输出贴到公开仓库：

```sh
'./Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar' --probe
```

默认先用 `/Applications/Codex.app/Contents/Resources/codex`，不存在时尝试 `/Applications/ChatGPT.app` 包内的 Codex CLI。若在别处，使用：

```sh
CODEX_QUOTA_CODEX_PATH='/absolute/path/to/codex' \
  './Codex Quota.app/Contents/MacOS/CodexQuotaTouchBar' --probe
```

只设置你信任的可执行文件。测试脚本用同一环境变量指向仓库内的模拟服务。

## 5. 安装与排错

```sh
ditto 'Codex Quota.app' '/Applications/Codex Quota.app'
open -a '/Applications/Codex Quota.app'
```

若 `/Applications` 写入需要管理员权限，用 Finder 拖入“应用程序”。菜单栏出现额度后，可从“设置”改语言、指定可执行文件或开启登录时启动。

- **找不到 Codex 程序**：在菜单“设置 → 选择 Codex 程序”中指定已安装的 Codex 可执行文件；确认已在 Codex 登录。
- **Touch Bar 不显示**：确认机器有实体 Touch Bar，并试“重新显示 Touch Bar”；私有接口可能与该 macOS 版本不兼容。没有 Touch Bar 时菜单栏仍可用。
- **下载的 App 被 Gatekeeper 拦截**：源码本地构建为 ad hoc 签名；不要把它误认为已公证的正式安装包。公开二进制发布流程见 [RELEASE.md](RELEASE.md)。
- **语言不符**：菜单“设置 → 语言”可手动选择；自动模式使用 macOS 首选语言，而非 Codex 对话语言。

图标由 `Assets/generate-icon.swift` 绘制；仓库同时提交生成后的 PNG 和 ICNS，普通构建不依赖图标生成步骤。
