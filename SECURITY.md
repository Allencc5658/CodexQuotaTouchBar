# 安全说明 / Security

## 报告问题

请勿在公开 issue、PR、截图或日志里放入令牌、邮箱、真实额度、完整本机路径等信息。如果仓库启用了 GitHub 的私密漏洞报告，请使用 **Security → Report a vulnerability**；否则先开一个不含敏感细节的 issue，请维护者提供私下联系渠道。

## 安全边界

- 本应用只通过本机子进程的 stdio 使用 JSON-RPC，没有 WebSocket 或 HTTP 监听端口。
- 自定义可执行文件会以当前用户权限运行；只能选择你信任的 Codex 程序。环境变量 `CODEX_QUOTA_CODEX_PATH` 也能覆盖路径，主要用于本地测试。
- JSON-RPC 输入有 2 MB 行缓冲上限和 20 秒请求期限；超时会尝试终止子进程。界面只显示解析出的额度字段。
- Touch Bar 桥接使用私有 macOS selector 和系统私有框架。接口可能随系统更新改变，因此不支持通过 Mac App Store 分发。
- `build.sh` 使用 ad hoc 签名以便本地运行。ad hoc 签名不证明发布者身份，也不能替代 Developer ID 签名和公证。

维护者应保持 Codex CLI、macOS 和开发工具更新，审查依赖路径，并在发布二进制前完成 [发布清单](docs/RELEASE.md)。当前仓库没有第三方包管理依赖。

## English summary

Report vulnerabilities privately when GitHub private reporting is available. Never post credentials or real account output publicly. Only select trusted executables; the app launches them with the current user's privileges. Its local build is ad hoc signed, and persistent Touch Bar behavior depends on private macOS APIs. Developer ID signing, notarization, and external installation tests are required before a public binary release.
