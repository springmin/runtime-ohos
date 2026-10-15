# TOUCH-PASTE-DEFAULT：触屏粘贴翻默认开（默认 ON + 显式 opt-out）（2026-10-15）

> 结论：TOUCH-PASTE 从"opt-in 默认关"翻转为**默认 ON**：壳 `Index.ets` 的闩锁无标记即开；显式退出 = 沙箱标记 `filesDir/touch-paste.disabled`（主源）或 env `OHOS_TOUCH_PASTE=0`（次源），禁用信号恒胜、两者全无即保持开启；**旧 opt-in 标记 `touch-paste.enabled` 已移除且被源码契约拒绝回退**。触发面不扩大：仍要求壳输入为当前文本 sink（聚焦管理的 Entry/IME 回退路径），未聚焦长按保持惰性。五包 abc 637,224/`8503a3c2…` → **637,256/`ab02cc20…`**（headless 24,324/`798b2477…` 不变）；套件 **816/819 floor 799**（+2；与同树并行未提交的 SECURE-STORAGE-ASSET +9 合并运行为 825/828/808）；`verify-kit` EXPECT **637256,24324**；ow `2311126`（CI 6/6 绿）。

## ① 设计（壳，五包 `Index.ets`；无 host/切片/maui 改动）

- 语义：默认 ON；`filesDir/touch-paste.disabled`（size>0）→ OFF（主源，实测 .NET setenv 对 ArkTS 不可见故标记优先）；`OHOS_TOUCH_PASTE=0` → OFF（次源）；无信号 → ON。
- 冲突/边界：仅在"壳输入为当前文本 sink"（聚焦可编辑 Entry）时出浮层——即既有"聚焦可编辑 Entry 才启用"设计，本次未放宽；观察者/识别器/安全控件/单次读/`notifyTextInput` 投递逐字节不变（契约 pin + 既有红控）。
- 红控：selftest T15 新增"旧标记回退"（默认关）与"opt-out env 比较回退"各 1，各拒并具名 → **223/0**；`selftest-verify-kit` **135/0**。

## ② 真机（HAD-W32 / OH 7.0.0.109；补丁 hdcp4；互斥锁独占后释放）

- 默认态（无标记、未聚焦）：长按 → `enabled (default; no opt-out)` + `sink=false`，0 浮层/0 节点（A 面）。
- 默认态（聚焦 Entry）：跨应用种子（owner `com.example.pasteprobe`，`PBC SetPasteData`）→ 长按 → `bubble shown` → 点浮层 → `pasted 13 chars` + 标题 `touchpaste: text='PROBE-SEED-42'` + 隐藏输入同值；服务侧 `READ_PASTEBOARD denied` → `GetLocalData# GetPasteData success`（安全控件授权路径）。
- opt-out：写标记 → 重启 → 长按 → `disabled (sandbox marker / OHOS_TOUCH_PASTE=0)`，0 浮层/0 节点；opt-in 删标记 → 浮层回归（默认恢复）。
- 零回归：同进程 pid 恒定（tap/drag/fling/长按+拖）、fault diff 0；探针件卸载、基线 PRE55 `all` hap（`6a628964…`）回装、hilog 512K、锁释放。

## ③ 提交 / 边界 / 不确定

- ow `2311126` master 普通推送（HTTP/1.1；禁强推）；CI 6/6 绿（interaction `38678893945` / pixel / host-export / ridgraph / markdownlint / harmony）。
- 边界：MAUI 自绘控件不在 uitest 布局树 → "管理按钮状态变化"面以 PasteButton 点按/种子点击/长按 diag + pid/fault 稳定为准；Web overlay 长按边界本轮因共享桌面抢焦未复测（设计上 overlay 位于 XComponent 之上自消费；原波已定）。
- 不确定：① 共享桌面注入焦点干扰（多轮复现，前台交互子证据按注记）；② env 半边对 ArkTS 不可见（沿用）；③ 单机型 debug 域。
