# WEBAUTH-LOOPBACK：WebAuthenticator loopback 重定向（127.0.0.1 单次监听，免 chooser）（2026-10-13）

> 结论：WebAuthenticator 新增 **http loopback 回跳路线**（RFC 8252）——`CallbackUrl = http://127.0.0.1:<port>/...`（或 `localhost`，v4 + v6 best-effort）时应用自起**单次监听**，系统浏览器的重定向 GET 直达应用完成回调；**无需** module.json5 回调 skill、无「选择打开方式」chooser。自定义 scheme 路线逐字不变（显式选择 = 回调 URL 形态）；https loopback / 非 loopback http(s) / 默认或特权端口**同步**抛 `InvalidOperationException`（安全默认 + 理由）。唯一权限需求 = INTERNET（LAUNCHER-IDENTITY 后默认；本轮 hap 实测 1 权限）。

## ① 实现（maui `2a195809db`；新文件 419 行 + 认证器 +133/−40）
- 新 `OpenHarmonyWebAuthenticatorLoopback.cs`：`OpenHarmonyWebAuthenticatorLoopback`（识别/校验 + 具名错误文案）+ `OpenHarmonyLoopbackListener`（单次 HTTP 服务，手建 socket 先置 SO_REUSEADDR 再 bind）。
- 路由匹配复用 `CanHandleCallback`（scheme/host/port/路径精确）；完成经共用 `TryComplete` 原子抢占（`Request.TryClaimCompletion`，含 activation 路线）——**单次、防回放**；异路/噪声请求答 404 后继续等待；每连接读头 3 s 上限（浏览器 preconnect 不楔死）；等待期 = 调用方 CancellationToken（MAUI 唯一超时机制），finally 释放端口；
- 限制（与 scheme 路线同口径）：form_post 405；https loopback 拒绝（127.0.0.1 无浏览器可信证书）；fragment 不进 HTTP（loopback 即授权码流）；本地任意进程可达端口 → PKCE + 应用侧 state 校验为标准防线（state 原样透传，不代判）。

## ② 离线（ow `feat/webauth-loopback` `5b2dc94`，新分支未并 master）
- 套件 `test/maui-platform-verify` +4 行：source/wiring pin；真实 socket 流（异路 404 + 未完成守卫 → 命中 200/成功页/解析）；取消释放端口 + 立即同端口重试（TIME_WAIT 再绑）；非法路由拒绝 + `localhost` 全链 → **checks=805（原 801，+4；total=804 未重锚，留合并波统一）**，floor 784、SUITE_RC=0。
- 红控 2：去 `StartLoopbackPump` 接线 → live=False rc=134；去 foreign-host 拒绝门 → invalid routes=False rc=134（均还原）。切片独立编译（Release + AoT/trim 分析器）0 error；并入兄弟 SECURE-STORAGE（merge `5cfb1b8991`）后套件仍 805/804 绿。

## ③ 真机（HAD-W32 / 7.0.0.111，锁独占 23:28–23:29；JIT 探针 hap = ow 分支 + maui 分支切片，`0dd8498e…`）
- 流：`aa start -U app://webauth/loopback/53199` → `pending (loopback 53199)`（监听已起）→ 应用经 ability bridge 打开系统浏览器（`com.haitai.htbrowser` onNewWant `uri=http://127.0.0.1:53199/callback?code=LOOPBACK-53199&state=lbstate`、caller=com.example.hellomauiapp；checkUrlSafety/Threat 通过）→ **0.28 s 后 `webauth: ok code=LOOPBACK-53199 state=lbstate`**（浏览器 GET 直达监听、完成回调并回成功页）。
- 浏览器侧直证：布局 dump 含 `Authentication complete` / `You can close this window and return to the app.`（`browser-layout.json`）+ 截图（地址栏即 loopback URL、成功页渲染，`browser-success.jpeg`）；WMS 含 browser 窗口。
- 主窗零回归：`canvas presented (2090x1324)` 60 fps、pid 恒定、fault diff=0；末态：pre55 `all` hap 回装、app 停止、hilog 512K、锁释放。证据 scratch `/data/storage/el2/base/tmp/opencode/webauth-loopback/round/`。

## ④ 提交 / 边界
- maui：`feat/webauth-loopback` `2a195809db` → `feature/openharmony` **merge `5cfb1b8991`**（兄弟 SECURE-STORAGE 已并，正常 merge；本地完成）。ow `5b2dc94` 未并 master（pin/套件重锚留合并波统一）。本文 + README 行 → runtime `feature/openharmony`（commit-paths）。
- 样例：`WebAuthProbe` 增 `app://webauth/loopback[/<port>]`；设备轮一次命中（脚本保留端口重试）。
- 不确定项：首轮启动遇一次 6 s 主线程 block（首帧 JIT 慢 + 主机负载；pre55 对照件与重试均健康）→ 轮次脚本改轮询；`localhost` 的 v6 半边未单独上机（合成流用 `127.0.0.1`）；「外部 IdP 授权页 → loopback 回跳」真端点一跳沿用 mail 同机实证（本轮为同机合成流）；推送经 API 旁路（github git 端点不可达）。
