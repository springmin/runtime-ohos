# kit #44 本机真机复测轮（KIT44-LOCAL-VERIFY：AOT 默认 + 动态槽，2026-10-04）

> 设备 HAD-W24（OpenHarmony-7.0.0.111(SP3ENTC293E104R2P1log) / API 26 / 2in1），hdc 无线 `127.0.0.1:35111`
> （在线），UDID `1BCE13C8…AEA0`；签名 = rc.2 线 preview.28 `sign-hap.sh` + ohos-sdk 26.0.0.18_2；tester-run =
> **v14**（140,197 B / `a174fcd0…`）；口径 = `reg-kit44/RELEASE-VALUES.txt`（FINAL）；证据 scratch
> `/data/storage/el2/base/tmp/opencode/kit44-local/`。共享桌面并发用机：INTERP-RENDER 09:24–09:54 装/启同 bundle
> （干扰已用时间线标注，首轮 soak 作废归档）；未改 kit 资产；hilog 16M 复核后已还原 512K。
## 1. 资产核验 ✅
- tar **67,680,863 B / `b777d8d8…`**（= VALUES）；sidecar 89 B / `85d62a6e…`；`SHA256SUMS` **18/18 OK**
  （1,600 B / `41c1f3c3…`）；tree digest **`db2604d5…`**；shipped `verify-kit.sh` 76,707 B / `b205ae64…` → **KIT OK**。
- 深断言：5 MAUI hap 均 `runtime-mode.txt=aot`、libs 仅 3 `.so`（app 19,208,976 + host 297,888 + libc++
  1,267,392）、`dotnet.zip` 200,144 B、abc **368,812 / `1076a700…`**、无 coreclr/clrjit；Blazor 2 hap own abc 21,200/21,016。

## 2. AOT 7 hap（首帧 + Blazor A/B）
- base/unsigned 变体重签后装/启 **PASS**：`canvas presented (2090x1324)` n≈293 avg=17ms（≈60 fps）、
  `jitfort: skipped runtime-mode=aot`、VmRSS 248–256 MB / 线程 69–72、0 SIGSEGV/ABRT/CoreCLR 失败；
  截图 `aot/{base,u-base}/frame.jpeg`（与 JIT 时代同 UI 对照）。
- permissions 变体装失败 **9568289**（grant `READ_CONTACTS`，本机签名域无该 ACL）；api20/api20p 装失败
  **9568297**（本机 API 26 与 api20 波段件不兼容）→ 3 项登记「未测（设备/签名域）」，非运行时失败。
- Blazor default/nocsp：重签装/启 **PASS**；`BLZ_BOOT`/`BLZ_RENDERED`=1、`BLZ_ERROR`=0；受控 click **0→1→2**
  （pid 33250 / 35923）。

## 3. 动态槽（SLOTS-DYNAMIC）
- **kit 件 3 控件并发**：A/B/C 三个 rootWebArea 同页；`web slot create: 2` + `hybrid assets … slot=2` +
  `web page (slot 2)` + `web capacity: 4` 原文；B raw、C raw、C invoke 回显（`sent raw C-raw-ping (stock)`、
  `invoke: "C-echo:Echo:1"`）。A 出画，但按钮区被 B 同格叠盖（样例布局所致）。
- **释放路径（关键发现）**：kit 样例 Remove web C 仅 label 翻转为 `removed (slot destroy)`：16M hilog + 220 s
  连续流 **0 条 `web slot destroy`**、C 覆盖层仍出画/可交互、re-add 无第二条 create → `extraHost.Children.Clear()`
  不触发 MAUI handler 断开（移除子项不自动 `DisconnectHandler`），**「释放即拆」在 kit 样例上不可复现**。
- **收口（MAUI-CONSOLIDATE-FINAL2）**：FIX-AUTODISCONNECT（maui `189b87ca8a` + ow `64ee9c4`）后，kit 样例
  （无显式 `DisconnectHandler`）真机 Remove web C → `web slot destroy: 2`（12:40:50）、覆盖层消失；
  re-add → `web slot create: 2`（12:41:00）并恢复交互（c1–c5 截图/JSON）；上述缺口闭合，套件 587/589 floor 569。
- **第 4 槽 + destroy 点验（本地 probe：第 4 控件 D + remove 显式 `DisconnectHandler`；worktree 隔离构建；
  abc=kit `1076a700`）**：unsigned 22,162,078 → 重签 22,464,241 / `ce21422e…`；hilog **`web slot create: 3`** +
  `web page (slot 3)`、四个 rootWebArea（C 左 / D 右 [1560,1206][2573,1486]）、D 页
  **`invoke: "D-echo:Echo:1"`**（第 4 槽 handler 生效）；移除后 **`web slot destroy: 3` → `web slot destroy: 2`**，
  节点 4→3→2；`web capacity: 4` 全程 18 次。
- 容量：MAX=4 由 shell 广播、热对 slot 0/1 常驻、释放即拆；超容量 LRU 抢占需第 5 控件（未测；headless 承 #41）。

## 4. tester-run v14（16M 复核 → 512K 还原）✅
- default/nocsp 两轮：`kit_sidecar_check=ok`、`verify_kit=ok`、`tree_digest=db2604d5…`、`blazor_install=ok` +
  boot/rendered=yes（pid 19348 / 23981）；归档 `16m-default-…094840`（`58082af1…`）/ `16m-nocsp-…094919`
  （`35c394a8…`）；**09:49:21 已还原 512K**。

## 5. AOT soak（35 min）⚠️ 1 次无声 pid 丢失
- kit AOT 件（22,324,989 B / `1151ab8a…`）：start_ms 6.7 s；采样 0–35 min + t=15/30 抽屉/Back 扰动；**0 新
  CppCrash/AppFreeze**（faultlog 前后 diff=0）、**无外部安装**（`updateTime` 首=末）、2/2 扰动 FG 恢复、
  0 `10106102`、全程 AWAKE；末态 smaps **3 libs（AOT，无 coreclr）**。
- RSS：pid1 248.2 → 293.3 → **331.3 峰** → 266.3 MB；**t=25 min 1 次无声 pid 丢失**（无 fault/无安装；桌面
  ✕ 可关窗属已知行为，不归因宿主），自动重启续采 pid2 234.7 → 281.8 → 268.5 MB；无单调增长（JIT 对照 #soak2
  45 min +29.2 MB）。

## 6. 复用 / 未覆盖 / 不确定
- 复用：发布门禁（套件 584/586 floor 566、像素 PASS、导出 151/151、CI 5/5 @`86b0e89`、bundle `3b3008a4…`）；
  api20/permissions 变体不可装（设备/签名域）。
- 未覆盖：第 5 控件超容量抢占、JIT/interp 路径（非本包默认）、a11y/W6–W10 逐项（承 #34–#43）、预签件安装
  （非 tester UDID）。
- 不确定：soak 1 次 pid 丢失未归因；第 4 槽/destroy probe 为本地补丁构建件（非 kit 原件，判读限「机制可用」）。
