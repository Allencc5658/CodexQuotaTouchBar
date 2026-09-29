# 隐私说明 / Privacy

## 本应用读取什么

- 每两分钟启动一次**本机** Codex app-server，通过 stdio 请求 `account/rateLimits/read`。读取套餐、窗口时长、已用百分比和重置时间；剩余百分比在本机计算。
- 仅当额度响应缺少套餐字段时，请求 `account/read` 取得套餐。该接口的原始响应可能包含邮箱；本应用只解码套餐字段，不显示、记录或持久保存邮箱。
- 用户选择自定义 Codex 程序时，读取并保存其路径。语言选择也保存在 macOS `UserDefaults` 中。“登录时启动”状态由 macOS Service Management 管理。

## 数据去向与保留

- 额度数据仅留在应用进程内存中；退出应用后不保留。应用没有分析 SDK、遥测、崩溃上报、网页抓取、HTTP 客户端或网络监听端口。
- 应用不索取或存储 Codex 登录凭证；它运行用户本机已有的 Codex 可执行文件。该子进程沿用启动环境，并可能按 Codex 自身的认证和网络机制连接服务端。请只选择可信的可执行文件。
- 套餐、剩余百分比和重置时间会显示在菜单栏与 Touch Bar 上；旁观者或屏幕录制可能看到这些信息。`--probe` 会将这些信息打印到终端标准输出，请勿将真实输出贴到公开 issue。
- 本仓库的 `preview.png` 使用模拟数据。真实 Touch Bar 截图、构建缓存、App 和 DMG 都被 `.gitignore` 排除在源码提交之外。

## 删除本地设置

退出应用后，可在终端运行以下命令删除本应用保存的语言及自定义程序路径：

```sh
defaults delete local.codex.quota.touchbar
```

若启用了“登录时启动”，请先在应用菜单中关闭，或在 macOS“登录项”设置中关闭。删除本应用设置不会清除 Codex 自身的登录状态。

## English summary

Quota and reset data stay in process memory. The app persists only language and a user-selected executable path, and uses macOS to manage the optional login item. It does not collect credentials, scrape pages, run analytics, or open a network listener. The spawned Codex app-server may use its own authenticated network connection. `account/read` is called only when the quota response lacks a plan, and its possible email field is ignored. Quota values shown on the menu bar or Touch Bar can be seen by others nearby.
