# MULTIWINDOW-L2 实施 b：子窗 ArkWeb 第二宿主（2026-10-06，07 闭环）

> 口径：用户点名**直接实施**（不受分析稿 §b“推迟”结论约束）。载体：ow `l2/arkweb-subwindow`（自 `afa6d7a`）·
> maui `l2/arkweb-subwindow`（自 `74e0bde5b9`）· 本文档 runtime `feature/openharmony`。设备：SOAK50 释放后取锁，首轮
> 暴露 **capacity wire 不一致**（§3a）→ 修复后**全链闭环**（§3）；kit #50 hap 已还原、锁已释放。边界：2in1 debug 域；主窗 web/overlay 全链行为零变化（主 transport 字节等价 pin + 既有全套 pin 绿）。
>
> **2026-10-07 收口（L2-CONSOLIDATE）：已并主线**——ow `master` ← `3c486cf`（merge `094ad51b2037`）、
> maui `feature/openharmony` ← `2e441c35c9`（merge `086d358dc3b3`）；与 a11y 线四 pack `SubWindow.ets` 并存整合，
> 合并树 abc 473,048、导出 163/163；见 `2026-10-07-ohos-l2-consolidate.md`。KIT51 已切（见 `2026-10-07-ohos-tester-handoff-kit51.md`）、#49/#50 资产未动。

## 1. 实现面（四层）

- **宿主（ow `host_napi.cpp`，C 导出 157 不变）**：per-env `web_child`/`web_eval_child` sink；命令/eval 按 `"child:"`
  前缀路由并去前缀（主路径字节不变）；新 NAPI 属性 `registerChildWebSink`/`registerChildWebEvalSink`（旧宿主缺属性 →
  壳 `typeof` 探测失败 → 子宿主禁用，单主窗降级保留）；C 核心（`openharmony_host.c`）零改动。
- **managed 宿主层（新 `OpenHarmonyChildWeb.cs`）**：按窗（`sub-N`）槽池（Max=2、全动态、释放即 destroy）+ 门面
  `Acquire/Release/Touch/CommandForWindow`（主窗走原路径逐字）+ 64 条预就绪队列 + `w:<win>|capacity|<n>` 就绪
  （URL 携带的旧形也接受）+ 事件解析；**keep** claim/非 frame 命令的 1 行状态诊断。
- **maui 切片（5 文件）**：三 web handler 按窗解析/领槽/发送/事件过滤（主窗只达主 handler、子窗只达该窗；`OnPageEvent`
  同时接受 state/URL 两种 capacity 形）；关窗 `Reset()`→`ReleaseWindowOverlays`（`_overlayWindowClosed` 防再领）；
  `ResolveWindowId` 表优先 + `Adopt` 在 `ConnectTree` 前落表。
- **壳（4 packs `SubWindow.ets`；`Index.ets` 零改）**：`SUB_WEB_SLOT_MAX=2` 全动态池（首 tagged 命令才挂 ArkWeb）、
  与主池同 `s<slot>` 码、事件 `w:<surfaceId>|…`、capacity 以 **state 携带计数**；child sink 收到命令/首帧/挂载各记 1 行；
  hybrid/blazor 注册显式拒绝。样例 `app://subwindow/openweb`：web 置顶 + eval 标题 + click+读回 DOM、HTML 无 `#`。

## 2. 离线红/绿

- **绿**：套件 +17 L2 checks（total 663→**680**、floor 643→**660**）；实跑 `checks=678 total=680 floor=660
  assert=True`、0 assert=False、0 Unhandled（`run-suite-fix6.log`）。新增 `capacity wire`（state/URL 两形各 1）；覆盖
  池/队列/就绪冲刷/按窗事件路由/主传输字节等价/真 WebView 子窗领**子池**槽/子窗事件只达子窗/主 tagged 事件不达子窗/
  关窗释放+destroy/四 pack 壳·宿主·切片 pins/四 pack `SubWindow.ets` 字节一致。
- **红控**：临时去掉 `HandlerMatches` 主窗窗过滤 → `primary event isolated assert=False`、run 退出 1（`run-suite-red2.log`）。
- **门禁（逐项）**：ridgraph 20 / packs 25 / hap-targets 80 / tasks 9 / host-registry 6 / bridge 12 / hygiene 25
  全 0 failed；像素 **PIXEL ASSERTIONS PASSED**；`build-host.sh` 157/157、UND 249（宿主无改动）。
- **abc**：ui **470,720 B / `511b326c…`**、headless **24,324 B / `798b2477…`** 不变，四 pack 同字节，provenance 通过。

## 3. 提交 / 构建 / 真机（闭环）

- ow：`ee79a0a`（wire 修复+诊断+样例 / abc 两段）· maui：`2e441c35c9`；#49/#50 发布资产未动、无强推。
- **§3a 首轮根因（已修）**：壳发 `state="w:sub-1|capacity"`+`url="2"`，managed 只认 state 内 `capacity|<n>` → 事件被
  静默丢弃 → 槽池不就绪 → 已入队的 `child:data` 不冲刷（managed 只留 `claim`+`cmd`，壳无 `child web load`）。修复 =
  壳改发 `w:<win>|capacity|<n>` + 两侧兼容 URL 形 + 套件加 `capacity wire` 回归 pin。
- **闭环真机（02:2x，JIT hap）**：`openweb` → `child web host registered` + managed `child web capacity: sub-1 2`
  （消费）→ 壳 `child web cmd: data s0`（`child:` 前缀/同码投递）→ `defer`→`slot create: 0`→`attached: slot 0` →
  `child web page (slot 0): data:text/html,…CHILD WEB OK…` → managed `navigating/navigated: Success` + `eval
  title='"CHILD-WEB"'` + **click+读回 `tap text='"CHILD WEB TAP"'`**；截图 = 子窗内 `CHILD WEB TAP` 真帧。
- **主窗零回归（真机）**：双窗稳态 **主 60.0 / sub-1 60.0 fps**（avg 16.7ms、long=0）；本轮 0 新 fault；关窗
  `child web slot destroy: 0` + `subwindow closed`、WMS `ohos_dotnet_subwindow` 残留 **0**。

## 4. 余项 / 风险 / 降级边界

- **子窗 hybrid/blazor 资产桥**显式拒绝（不建组件、命令丢弃、eval 立即回错）；下一波 = 壳侧 `onInterceptRequest`
  serving 移植 + managed 注册回放按窗。**子窗 B6 导航否决未接**（外部导航直载，主窗不变）；**子窗 web × a11y
  provider** 由实施 a 分支承担。子窗池满（>2 并发控件）多余控件不挂载；预就绪队列溢出丢 1 行日志。
- **平台行为记录**：ArkWeb `loadData` 实为 data: URL，正文里的裸 `#` 会截断为 fragment（body 空、`getElementById`
  为 null）；主窗既有 `data` 路径同样如此，本轮样例以 `rgb()` 规避、未改壳语义（跨 host 修复另立项）。

## 5. 回归守卫（原上机卡，已闭环；复跑约 10 min）

前置：worktree 壳 abc + hosting 入 packs → `publish-jit.sh`（`-U` 触发需**先起主窗**，onNewWant 路径；冷启首帧 `-U` 不送达）。
期望行序：壳 `child web host registered` / `capacity advertised` → managed `child web capacity: sub-1 2` → 壳
`child web cmd: data s0` / `slot create: 0` / `attached: slot 0` / `child web page (slot 0)` → managed `navigated:
Success` / `eval title=` / `tap text=`；`framestats main/sub-1` 均 ≥50（60fps、long=0）；close 后 `slot destroy: 0`、
WMS 0 残留、fault 增量=0。失败回传：设备/包/时间 + 失败步 + `hilog -x > fail.raw` + `uitest dumpLayout` 截图。
