# GitHub 发布清单

源码仓库和可下载的 macOS 二进制是两种不同交付。源码可在完成隐私检查后公开；**当前 `build.sh` 产物是 ad hoc 签名的本地测试版，不应标成已公证的正式版本**。

## 公开源码前

1. 运行 `./build.sh`、`./test.sh`，并核对 `codesign --verify --deep --strict 'Codex Quota.app'`。
2. 用 `git status --short --ignored` 检查生成的 App、`.build/`、`.DS_Store`、真实额度截图及本机日志未进入提交。提交列表可用 `git ls-files` 检查。
3. 用 `git grep` 检查密钥、邮箱、本机绝对路径和真实额度输出；确认 `preview.png` 是模拟数据。
4. 检查 README、MIT LICENSE、PRIVACY、SECURITY、BUILD 文档；确认仓库仍为非官方项目，没有把 OpenAI 品牌写成官方背书。
5. 在 GitHub 仓库设置中启用私密漏洞报告（如可用），再公开仓库。

## 提供二进制下载前

1. 在受信任的 macOS 构建机上从公开提交重新构建。不要从开发者的旧 `.build/` 或现成 App 直接打包。
2. 把当前示例 Bundle ID `local.codex.quota.touchbar` 改为维护者控制的唯一标识，并测试已有用户设置的迁移。使用自己的 Apple **Developer ID Application** 证书，对 App 启用 Hardened Runtime 并签名；验证签名。`build.sh` 的 ad hoc 签名需替换。不要把证书、密码或 notarytool 凭据写进仓库。
3. 使用 Apple `notarytool` 将最终分发包送审，成功后 staple 公证票据并用 `spctl` 检查 Gatekeeper。参见 [Apple Developer ID](https://developer.apple.com/developer-id/) 和 [Apple 公证文档](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)。
4. 在另一台 Intel Mac 和一台 Apple Silicon Mac 上测试安装、启动、菜单栏、语言、登录时启动；有 Touch Bar 的机器还要测试私有接口。当前仅在 Intel macOS 13.7.8 上做过实机运行，不可把双架构编译成功等同于双架构运行验证。
5. 在 GitHub Release 写明支持的 macOS 范围、已测设备、私有 Touch Bar 接口的兼容风险、SHA-256 校验值和非官方身份。公开发行的 DMG/ZIP 必须由对应的已公证 App 构建。

## 目前状态

- 源码审计和本地模拟测试见 [AUDIT.md](AUDIT.md)。
- 没有 Developer ID 签名、公证票据或跨机器安装测试，因此**尚未达到公开二进制 Release 的门槛**。
- Touch Bar 使用私有系统接口；即使签名、公证成功，也需在目标系统上验证，且不适合 Mac App Store。
