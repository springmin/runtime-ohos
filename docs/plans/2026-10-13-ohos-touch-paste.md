# TOUCH-PASTE：触屏粘贴闭环（壳级 PasteButton 安全控件；opt-in）（2026-10-13/14）

> 结论：触屏粘贴真机闭环——**壳级 ArkUI `PasteButton` 安全控件**：用户点击时系统授予应用临时剪贴板读（与 ACL/`READ_PASTEBOARD` 无关），壳在点击回调内读取、按输入框当前 selection 插值，并用既有 `notifyTextInput` wire 把全文交给聚焦 Entry。入口 = 长按浮层（`LongPressGesture` + `onTouch` 兜底）；opt-in = 应用沙箱标记 `filesDir/touch-paste.enabled`（env `OHOS_TOUCH_PASTE` 为次源：**实测 .NET 侧 setenv 对 ArkTS process API 不可见**）；且仅在壳输入为文本 sink（IME 回退路径）时生效。四包 abc 620,908→**637,224**（`8503a3c2…`，headless 24,324 不变）；套件 **814/817 floor 797**；载体 ow `feat/touch-paste` → master merge **`cc6ca34`**（已推，CI 上跑）。

## ① 设计（壳，四包 `Index.ets`；无 host/切片/maui 改动）

- 入口：XComponent 上 `LongPressGesture({duration:550})`（真机实际触发路径）+ `.onTouch` 计时兜底；两者只观察不消费（taps/drags/flings 逐字不变）。到点后在屏内钳制的位置显示浮层 `PasteButton`（z=`webZOrderSeq+2`，盖过管理面与全部 ArkWeb overlay；新触面/失焦/完成即收）。
- 读取/投递：`onClick(result)` 的 `PasteButtonOnClickResult.SUCCESS` 门内 `pasteboard.getSystemPasteboard().getDataSync()`（**全文件仅此一处**，源码契约 + 红控强制），按 selection 替换插值、`setTextSelection` 落 caret，再 `host.notifyTextInput(全文)`（与键入同路；管理聚焦 Entry 直接置文）。
- 门禁：沙箱标记（或 env）**且**壳输入为当前文本 sink（`registerTextInputSink` show=1）——装了 API12+ IME 入口的镜像/未 opt-in 应用上气泡不出现（防向错误缓冲投递）；无 ACL 权限参与。
- 先导探针（scratch 最小 ArkUI 页）：真机 `PasteButton clicked result=0` + `readSync/readAsync ok`（自写数据），PBS 仍 `IsPermissionGranted READ_PASTEBOARD denied` → 安全控件授权路径成立。

## ② 真机（HAD-W32 / OH 7.0.0.111 / 2in1；互斥锁独占；JIT hap = 四包 abc + 样例三探针）

- 触屏闭环（跨应用数据 owner=`com.example.pasteprobe` → MAUI）：长按 → `touch paste: enabled (sandbox marker…)` · `long press optin=1 sink=true` · `bubble shown` → 点浮层（dump `[1066,463][1226,529]`）→ `pasted 13 chars, text 13 chars, caret 13` + 标题 `touchpaste: text='PROBE-SEED-42'` + 服务侧 denied→`GetLocalData# GetPasteData success`；隐藏输入=`PROBE-SEED-42`。证据 scratch `round3/`（日志/截图/dump）。
- 零回归：pid 恒定、fault diff=0、管理面按钮点击照常命中（状态行变 `hybrid B activated (eval: "Hybrid B")`）→ 触点不被 onTouch/手势吞掉。
- **loopback `localhost`（v6）一跳**：同件 `app://webauth/loopback-localhost/53213` → `pending` → **101 ms `webauth: ok`**；`/proc/net/tcp6` 捕获 `::1:53213` 建连（tcp4 无对应条目）→ 浏览器对 `localhost` 走 **IPv6**、壳 IPv4+best-effort IPv6 双绑监听服务；浏览器成功页在案。
- 末态：基线 pre55 `all` hap 回装、探针卸载、app 停止、hilog 512K、锁释放。

## ③ 离线（ow `feat/touch-paste`；红绿）

- 套件 +4（四包壳 pin 逐字节 + 单次读在点击回调内、点击/Grant/交付契约、样例 opt-in 接线、kit 重锚）→ **814/817 floor 797**；红控 = 旧 `EXPECT_ABC` → `touch-paste kit pins=False` rc=134（还原）。
- 壳自检 T15 红控 5：抽 opt-in 常量/`notifyTextInput(updated)`/SUCCESS 门/长按识别器 + 增第二处 `getDataSync()` → 各拒并具名；`selftest-build-arkts-shell` **219/0**、`selftest-verify-kit` **135/0**、`--check-pack-abc` 绿（四包源 `ee6fbc3f…`、abc `8503a3c2…`；两安装位同步）。

## ④ 提交 / 边界 / 不确定

- ow：`feat/touch-paste` `56f1624` → merge `a914a15`（唯一冲突 = 套件注释，保留 814/817/797 + RC2-ALIGN 注）→ `cc6ca34` master **ff 已推**（禁强推）；两四包模板 + 3 workflow 注释 + verify-kit/selftest/套件/README 全链随动。
- maui：**无改动**（loopback 主线已含；`loopback-localhost` 触发器在样例 `WebAuthProbe`）。
- 不确定：① env 不可见 ⇒ 壳 `OHOS_SUBWINDOW_MAX/OHOS_OVERLAY_MAX` 的 env 半边疑同（有 rawfile/URI 兜底，未复测）；② 浮层位置=手指处（未接输入几何 wire），产品化可换 caret 几何；③ 单机型 debug 域；④ 设备为多会话共享，窗口抢焦时终判需紧凑时序（本轮已按此取证）。
