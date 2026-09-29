# Codex Quota Touch Bar

[English](README.en.md) · [隐私说明](PRIVACY.md) · [安全说明](SECURITY.md) · [从零构建](docs/BUILD.md)

一个非官方的 Swift/AppKit macOS 菜单栏应用，在有 Touch Bar 的 Mac 上显示 Codex 剩余额度。它通过**本机** `codex app-server --listen stdio://` 的 JSON-RPC `account/rateLimits/read` 获取数据，不抓网页，也不要求你向本应用输入密码或令牌。

![模拟 Plus 数据的界面预览](preview.png)

## 功能

- Plus 显示 5 小时、周限额两行分段电量条；Pro 不显示 5 小时行。其他套餐按 app-server 实际返回的窗口显示。
- 剩余百分比为 `max(0, min(100, 100 - usedPercent))`；按本机时区显示重置时间。
- 菜单栏显示额度摘要，可立即刷新或重新显示 Touch Bar。默认每两分钟刷新；刷新失败时保留上一次额度。
- 自动跟随 macOS 首选语言，可手动选择简体中文、繁體中文、English。可选“登录时启动”（macOS 13 起）。
- 支持 Intel 与 Apple Silicon 构建。没有 Touch Bar 的 Mac 仍可使用菜单栏。

## 安装与使用

先确认本机已安装并登录 Codex。运行 [`./build.sh`](build.sh) 后，将生成的 `Codex Quota.app` 拖进“应用程序”，再从启动台或 Spotlight 打开。应用是菜单栏程序，不在 Dock 常驻。

它优先寻找 `/Applications/Codex.app/Contents/Resources/codex`；若不存在，尝试 `/Applications/ChatGPT.app` 内附的 Codex CLI。也可在菜单的“设置 → 选择 Codex 程序”中指定可信的可执行文件。选择 `.app` 时会寻找其中的 `Contents/Resources/codex`。

详细前提条件、完整命令、模拟测试和排错步骤见 [从零构建教程](docs/BUILD.md)。本仓库**不附带 Codex 可执行文件或登录凭证**。

## 数据与安全边界

应用只持久保存语言选项和用户指定的 Codex 程序路径；额度数据只保存在进程内存中。若额度响应没有套餐字段，才额外请求 `account/read` 以决定界面行数；该响应可能包含邮箱，但应用只读取套餐字段，不保存邮箱。应用自身不建立网络监听端口，子进程通过 stdio 交互。Codex app-server 可能按照其自身的认证和网络行为访问服务端。完整说明见 [PRIVACY.md](PRIVACY.md)。

Touch Bar 常驻依赖 macOS **私有接口**，系统更新可能使其失效，也不适合 Mac App Store。`build.sh` 生成的是仅用于本地测试的 **ad hoc 签名** App；公开提供可下载的二进制之前，需要 Developer ID 签名、公证和另一台 Mac 上的安装测试。见 [发布检查清单](docs/RELEASE.md)。

本项目与 OpenAI 无隶属关系，也不是官方 Codex 客户端。Codex app-server 的字段和本机 CLI 路径可能随版本改变。

## 项目结构

```text
Sources/       Swift/AppKit 界面、JSON-RPC 客户端、额度解析、Touch Bar 桥接
Resources/     三种语言的文本资源
Assets/        自绘图标及生成源码
Tests/         模型测试与模拟 app-server
build.sh       编译通用 App 并做本地 ad hoc 签名
test.sh        运行模型和 JSON-RPC 测试
docs/          从零构建、审计结果、发布清单
```

许可证：[MIT](LICENSE)。欢迎提交 issue 和 PR；安全问题请先看 [SECURITY.md](SECURITY.md)。
