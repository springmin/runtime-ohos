# 复测任务单（一页）：kit #45 一轮设备判定（**自动释放 = Remove→destroy→re-add→交互** + 动态槽 3 控件 + **INTERP-RENDER** + **AOT 默认** + 承 #44 FRAMEPACING + 承 #42 三路径回归）（2026-10-04）

> 目标：一轮拿全 **#45 主判点 = 自动释放（FIX-AUTODISCONNECT）**：①**移除 web 控件即销毁槽/隐藏覆盖层**（动态槽
> `web slot destroy`，热对 [0,1] 不受影响、handler 保持连接）；②**再挂回自动重建并恢复交互**（`web slot create` +
> load/注册重放）；③**动态槽 3 控件并发出画/交互**（承 #44）；④**INTERP-RENDER**（解释器轮布局门控：**20.7→30 fps**、
> meas≈0、CPU **−13pt**；JIT/AOT 60 fps 不变）；⑤**AOT 默认**（5 MAUI hap 全 NativeAOT、`runtime-mode.txt=aot`、无
> JIT 运行时；首帧/交互回归；JIT 走 `--runtime-mode jit` 自建，release 域需 ACL/豁免）
> + **承 #44** 的 FRAMEPACING（真实 60.00 fps；17.7 fps 系壳状态轮询伪影）与动态槽口径
> + **承 #42** 的 JIT 解锁（JITFORT；保形态）/解释器 rc2b/FIX-SLICERACE
> + **承 #41** 的 MULTI-OVERLAY-FULL / DEVCOMPAT-DEFAULT / INTERP-FIX（8 MB 栈 + 关写屏障 + rc2 pack 线）
> + **承 #40–#35** 的 FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10
> 与 **承 #34/#33** 的 rc.2 版本自述、W6/W7/W8、Blazor 双 hap A/B，并采 JIT/XWE/AOT/解释器/harmony 与无障碍。
> 执行入口 = `tester-run.sh`（版本/大小/摘要**以包内 `SCRIPT_VERSION` 与 release 资产页为准**；承 **v14**，
> 含 `--blazor-probe` / `--mode-matrix` / `--a11y-probe`）。
> 判定树与细节：`docs/plans/2026-10-04-ohos-tester-handoff-kit45.md`（逐项勾选 + §3 rc.2/AOT + §4 本机直测）、
> `docs/plans/2026-10-04-ohos-interp-render.md`（布局门控/相位拆解）、`…kit44` §DYNAMIC（动态槽设计/设备证据）、
> `…framepacing.md`（60 fps 归因）、`…jitfort-enable.md`、`…interp-null.md`、`…handler-race.md`、`…sample-fix.md`、
> `…legacy-toolbar.md`、`…wx-patch2-fallback.md`、`…m-web-mirror.md`、`…zorder-nav-device.md`、`…maui-final-audit.md`。
> 本页只给「取件 → 执行 → 回传 → 判定」。**kit #45 发布实测（release「## Integrity（kit #45）」；发布已完成，
> 一切数字以 release 与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准）**：tar **67,695,181 B / `ca48a93c…`**、
> 树 **`ae0f7fce…`**、sidecar **`9741aced…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `9f677c40…`**
> （#44 = tar 67,680,863 / `b777d8d8…`、#43 = tar 67,638,015 / `57c7bf44…` 对照）。
> **预签已刷新至 #45**（7 hap；67,624,950 / `e1ce8ab6…`，asset 609411819）；非 tester UDID 设备请回传 UDID 代签。
>
> **运行时口径（kit #43 起）**：**默认 AOT**；JIT 需 ACL/豁免（release/生产域 AGC ACL 或厂商豁免；debug/内测签名域免；亦可用 `--runtime-mode jit` 自建）；interp 为实验路径（独立 pack，不随主包）。

## 1. 取件清单（release `springmin/sdk-ohos` tag `device-test-kit`）

| 资产 | 大小 (B) | sha256（前缀） | 用途 |
|---|---|---|---|
| `device-test-kit.tar.gz`（kit #45，2026-10-04） | **67,695,181** | **`ca48a93c…`**（sidecar `9741aced…`；树 `ae0f7fce…`；`SHA256SUMS` 18 项 / 1,600 B / `9f677c40…`；dtk **392356147** / latest **392077166**；asset **609394479**/**609400064**） | **7 hap**（5 MAUI 全 AOT：`runtime-mode.txt=aot`、3 `.so`（app.so + host 297,888 + `libc++_shared.so` 1,267,392）、无 libcoreclr/libhostfxr/libclrjit；abc **368,812（`1076a700…`）**/24,324、宿主 **297,888（`7b1694d9…`）**、导出 **151**）+ **2 个 Blazor 对照 hap**（bundle `com.example.opendotnet`，无 INTERNET）+ `verify-kit.sh` + 文档 + `runtime-mode.txt=aot` |
| `preSigned-haps.tar.gz`（**预签直装**；#34 起加发；**本波已刷新至 #45**） | **67,624,950**（asset **609411819**；sidecar 88 B / `a7ab0943…`，asset **609416429**；树 `399ef471…`） | **`e1ce8ab6…`** | 7 hap = **kit #45 原名件**，按 tester UDID `60CF7B27…` 预签：`sha256sum -c SHA256SUMS` → `hdc install -r` **直装**；非本 UDID 设备仍 `9568344` |
| AOT 复测取件（`aot-haps*`；rc.2 pack 已重出 `-struct1`：结构修复 + shim） | **18,185,012**（`aot-haps-v3-rc2.tar.gz`；本批未动；dtk 599996905） | **`3d24f716…`** | AOT hap（含 UIPage 出画修复）；rc.2 设备/本机构建用 **`-struct1`**（`…rc.2.26451.112-struct1.nupkg` 28,905,116 / `09345f95…`，asset 607541145；sdk fetch 现锚、`versions.env` sha `09345f95…`）；`-r2`（28,904,657 / `542058cf…`，asset 601289590）与原包（`46d221f2…`）仅历史、不再钉锚；装前重签 |
| **解释器 pack** `ohos-interpreter-pack-rc2b.tar.gz` | **2,410,595**（asset **606999003**；README **606999004**；sidecar **606999001**） | **`5974430509…`** | **INTERP-NULL 修复 + WX-PATCH2**（`libcoreclr` `4b30a4c1…`/`e150558a…` + `libclrinterpreter` `11fc5052…`/`3e4b4d10…`）；配 #42+ 宿主（JITFORT + 8 MB 栈）使用；rc2 旧件（605924427）/rc.1 旧件（2,419,988 / `a10699b3…`）保留作对照 |
| `harmony-haps.tar.gz`（MAPFIX 重切 2026-09-28） | 196,898,796 | `9b0506fa…` | harmony 壳 5 变体（AGC 就绪时用；overlay 真编译，abc 291,628 B/`a637a513…`） |
| `tester-run.sh`（随包） | 以包内为准（承 v14 = 140,197 / `a174fcd0…`） | 以包内为准 | 执行器；`--blazor-probe`、`--mode-matrix`、`--a11y-probe` 承 #33 |

包内 7 hap（kit #45 发布实测，`SHA256SUMS` 18 项 / 1,600 B / `9f677c40…`）：`hello-maui-app.hap` **22,333,257 / `6fa99da2…`**（AOT）、`…-unsigned` **22,031,007 / `787c1c10…`**、`…-permissions` **22,333,270 / `8f3acf1a…`**、`…-api20` **22,333,246 / `3b8a7d4b…`**、`…-api20-permissions` **22,333,273 / `2e15d418…`**、Blazor 默认 **27,216,958 / `e7d5a62c…`**（未签名）、`-nocsp` **27,216,659 / `6840268e…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。

**预签直装捷径（可选）**：`sha256sum -c SHA256SUMS` 后 `hdc install -r` 直装，**§2 的「先重签」可跳过**（同 bundle
换件仍先卸载）；预签件已刷新至 #45，可直接用于本轮。完整一轮 / 源码复测请用 `device-test-kit.tar.gz`。

## 2. 执行顺序（每步「期望 → 回传」）

0. **自动释放（#45 主判点 0，FIX-AUTODISCONNECT）**：装默认 kit 主 hap（AOT）→ 加满 3 个 Web 控件（A/B/C 并发出画）→
   **移除第 3 个控件**：期望动态槽释放（hilog **`web slot destroy: 2`**）、覆盖层消失（C 区无节点）、热对 [0,1] 不受影响
   → **再加回**：期望 **`web slot create: 2`** 重建、C 恢复交互（`sent raw C-raw-ping (stock)` / `invoke: "C-echo:Echo:1"`）。
   → 回传移除/重挂前后截图（c1–c5 同构）+ hilog 原文（`web slot (create|destroy)`）。**注意**：512K hilog 可能秒级轮转
   丢失 destroy 行——以截图 + 重建交互闭环为准；必要时 `hilog -G 16M` 重跑后还原。
1. **动态槽 3 控件（承 #44 主判点）**：加满 3 个 Web 控件：期望**三控件并发出画/可交互**（A、B、C 各自 invoke/raw 回显
   label `A/B/C raw`）；hilog `web cmd: slot`→`web slot create: 2`→`web page (slot 2)`，容量 `web capacity: 4`；
   第 3 槽与「移除/重挂」同一轮合并测试。→ 回传 3 控件截图 + hilog。
2. **INTERP-RENDER（#45 主判点 1）**：解释器轮（rc2b pack + rc.2 kit hap + `interp.txt=3`）出画稳定后统计：期望
   **30 fps（20.7→30）**、meas≈0 ms/帧、主线程 CPU 65.5–70.5%（−13pt）、无 `SIGSEGV(NULL)`；JIT/AOT 轮 60 fps 不变；
   交互（双击 Count 0→1）正常。→ 回传帧统计/终端输出（`FPH` 行）+ 截图 + hilog（无入口按「未测」登记）。
3. **AOT 默认（承 #44 主判点）**：默认包冷启 → 期望 kit 根/逐 hap `runtime-mode.txt=aot`、无 libcoreclr/libclrjit、
   **首帧 + 交互回归**（`aot=1`、`canvas presented`）→ 回传截图 + hilog + `verify-kit` 输出。
4. **校验 kit**：包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap；5 MAUI hap 期望 `runtime-mode.txt=aot`、
   3 `.so`、无 libcoreclr/libclrjit；abc 期望 **368,812/24,324**）→ 回传终端输出。
5. **rc.2 版本自述**：读包内《最终状态.md》/`README-交付说明.md` + `tester-run.sh` summary → 期望 SDK `11.0.100-rc.2.26451.112`
   / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12`；无 rc.1 混装告警 → 回传自述原文 + summary。
6. **承 #44：FRAMEPACING**：出画稳定后统计呈现节奏 → 期望真实 **60.00 fps**（旧 17.7 系壳状态轮询伪影）；动画/滚动主观流畅
   → 回传帧统计（如可得）+ 录屏/截图。
7. **承 #42**：①JIT（自建 `--runtime-mode jit` 包或 ACL 域）：`jitfort rc=0` + 探针 `1=OK 2=OK` + 首帧；②解释器：
   rc2b pack + rc.2 kit hap + `interp.txt=3` → `canvas presented`、无 `SIGSEGV(NULL)`；③FIX-SLICERACE：JIT 8 轮
   `race=0 pvnull=0 conc=0 unhandled=0`；④L6/SAMPLE-FIX/WX-PATCH2/P2c 同 #42 判读 → 回传截图 + hilog。
8. **承 #41**：MULTI-OVERLAY-FULL（双 Hybrid 各自 invoke/消息；3 控件场景已覆盖；旧壳 >2 按 LRU 抢占）；DEVCOMPAT-DEFAULT
   （enforcing 开箱可装）；INTERP-FIX（8 MB 栈 + 关写屏障）→ 回传截图 + hilog。
9. **承 #40**：FIX-JSCALL = razor 页点 "Blazor click" 两次 → **count 0→1→2**（SAMPLE-FIX 后 `blzProbe` 报 `dotnet-ref ok`）
   → 回传截图 r0/r1/r2 + hilog。
10. **承 #39/#38/#37**：FIX-BACKSIZE = 抽屉开 → 系统 Back 关抽屉（仍 `#FOREGROUND`）；FIX-BWVMount = `.razor` 挂载；
    FIX-DISMISS = 抽屉外点关闭；FIX-WVP = Hybrid 出画 + bridge；FIX-HOME = Home tab 整页出画；FIX-ITOUCH = 注入点击命中
    → 回传截图 + hilog。
11. **承 #36**：payload 原地直载 + `--a11y-probe`（`status=1`、nodeCount 正整数；wasm 5 / 主包 24）→ 回传 hilog + `a11y/` 两文件。
12. **B2：MAUI WebView 内嵌 Blazor WASM（承 #35 主判点）**：装含 WebView/WASM 入口的包内演示 hap，AOT 路径启动 →
    打开嵌入式 Blazor 页 → 期望 **`BLZ_BOOT` + `BLZ_RENDERED` 同 pid 双标记齐**（无 `BLZ_ERROR`）、首屏渲染、`/counter`
    类交互 +1 → 回传 hilog + 首屏/交互截图。
13. **W9B/W9C/W9D/W10（承 #35）**：T14/T21/T8/T20/T19/AOT 入口可观测 → 逐条截图/回传（无 MediaKit 属预期不判失败；
    热 `delivered=1`；`dotnet-status.txt` 托管行）。
14. **承 #34：W6/W7/W8**：W6 = T14/T12/N1/FIX-SHELL；W7/W8 = T15/T16/N4（`--a11y-probe`）/T18/N5/N6 → 逐条截图/终端输出
    （套件自报行 **`[suite] checks=587 total=589 floor=569 assert=True`**）。
15. **承 #33：Blazor A/B**：装默认件 → `--blazor-probe` → 记录 `BLZ_BOOT`/`BLZ_RENDERED`（pid+nonce）与人工首屏/`/counter`
    +1/截图；**卸载后**装 `-nocsp` 件 → 同命令 → 按 #33 判读表落结论。
16. **承 #33：MAUI 主体（TabbedPage/W5）**：双页签出画 + 切页；T13/N3/T21/T22。AOT 为默认路径。
17. **一键四 Run**：`sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60`
    → 期望四 Run 不中断、`mode-matrix/summary.txt` 键齐全 → 回传 `mode-matrix/` 全目录 + 四个 `tester-report-*.tar.gz`。
18. **无障碍（含 N4）**：加 `--a11y-probe` → `a11y/selfcheck.txt`（status=1 + 正整数节点数）+ `a11y/hilog-a11y.txt`
    → 回传 `a11y/` 两文件 + `summary a11y_*` + 录屏。
19. **WebView 六项 + B1 razor（承 #32）**；**harmony 变体（AGC 就绪时）**：按卡逐条 / 同指纹重签 → 回传截图 + hilog +
    Map/LiveView/TTS/HUKS 证据。

## 3. 判定表（逐 Run 填）

| 态/项 | 判据 | 结论 |
|---|---|---|
| **自动释放（#45 主判点 0）** | Remove C → `web slot destroy: 2` + 覆盖层消失；re-add → `web slot create: 2` + 交互恢复 | #45 落地 |
| **动态槽 3 控件并发（承 #44 主判点 1）** | 3 控件各自出画 + 交互回显（A/B/C）；`web slot create: 2` / `web capacity: 4` | 承 #44 保持 |
| **INTERP-RENDER（#45 主判点 2）** | interp 30 fps（20.7→30）+ meas≈0 + CPU −13pt；JIT/AOT 60 fps 不变；交互 Count 0→1 | #45 落地 |
| **AOT 默认（承 #44 主判点 3）** | `runtime-mode.txt=aot` + 3 `.so`/无 libcoreclr/libclrjit + 首帧/交互回归 | 承 #44 保持 |
| **FRAMEPACING（承 #44/#43）** | 真实呈现 60.00 fps（17.7 = 壳状态轮询伪影） | 承 #43 保持 |
| **门禁（#45）** | `[suite] checks=587 total=589 floor=569 assert=True`；导出 151/151 | #45 基座 |
| **JIT 解锁（承 #42）** | 自建 jit 或 ACL 域：`jitfort rc=0` + 探针 `1=OK 2=OK` + 首帧 | 承 #42 保持 |
| **解释器首帧（承 #42）** | rc2b pack + rc.2 kit hap → `canvas presented`；无 `cppcrash`、无 `SIGSEGV(NULL)`；`summary interp_mode=3(file)` | 承 #42 保持 |
| **FIX-SLICERACE（承 #42）** | JIT 冷启/重启循环 8 轮：`race=0 pvnull=0 conc=0 unhandled=0` + 首帧 | 承 #42 保持 |
| **L6 / LEGACY / SAMPLE-FIX / WX-PATCH2 / P2c（承 #42）** | JPEG 落盘/标题心跳；Toolbar 契约；`blzProbe`=`dotnet-ref ok`、`#app`、计数 0→1→2；无 `ACCERR`；`module.json` skills | 承 #42 保持 |
| **MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX（承 #41）** | 双 Hybrid/per-slot invoke/z-order；enforcing 开箱可装；8 MB 栈 + 关写屏障 | 承 #41 保持 |
| **FIX-JSCALL（承 #40）** | razor 点两次 → count 0→1→2；`missing native code`=0 | 承 #40 保持 |
| **FIX-BACKSIZE / FIX-BWVMount（承 #39）** | Back 关抽屉；`.razor` 挂载 | 承 #39 保持 |
| **FIX-DISMISS / FIX-WVP / FIX-HOME / FIX-ITOUCH（承 #38/#37）** | 外点关；Hybrid 出画+bridge；Home 整页出画；注入命中 | 承 #37/#38 保持 |
| **payload / 像素 / a11y / AOT `-struct1`（承 #36）** | `payload-in-libs: running from …`；无 `Known`；`status=1`+nodeCount；`-struct1` 构建成立 | 承 #36 保持 |
| **B2 / W9 / W10（承 #35）** | 双标记齐；T14/T21/T8/T20/T19；AOT 入口行 | 承 #35 落地 |
| **rc.2 基线 + W6/W7/W8（承 #34）** | 版本自述；T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6 | rc.2 线成立 |
| **Blazor A/B + 主体（承 #33）** | 默认/nocsp 双标记；TabbedPage/W5；套件 `587 total=589 floor=569` | #33 保持 |
| **JIT / XWE / AOT / 解释器 / harmony / runtime_mode** | 各态判据同前；AOT 为默认、JIT 为形态保留 | 各判定成立 |
| **WebView / B1 razor（承 #32）** | 9 项卡 + B1 两标记 + JS 往返 | 按 #32 判据 |

> 失败 Run 保留报告 tar；无入口项登记「未测（本包无入口/无 hdc）」，不判失败。

## 4. 注意

- 包内 hap 为自签：**9568257 / 9568344 属预期**，先重签（需华为调试证书 + Profile 绑 UDID）；**预签件已刷新至 #45**——可直接
  `hdc install -r` 直装（非 tester UDID 仍 `9568344`，请回传 UDID 代签）；**Blazor 双变体同名（`com.example.opendotnet`），装前卸载**；
  两变体均无 INTERNET（重签保持）。
- **自动释放口径（#45）**：MAUI 移除子项只改子列表、handler 保持连接（MAUI 语义）；本波由页面/ContentView/Layout 子树
  watcher 驱动切片 `IOpenHarmonyOverlaySlotLifetime`——detach 时 hide + 释放槽（动态槽在壳内 destroy）、re-attach/后续 arrange
  时重领槽 + 重放 load/注册；晚到属性/挂载 pass 被忽略；LRU 抢占/恢复不变。热对 [0,1] 的移除只 hide、槽位保留。
- **动态槽口径（承 #44）**：MAX/HOT 默认 4/2（env 不可按应用注入；clamp 2..8 / 2..max）；热对 [0,1] 常驻、空闲 >2 不养
  ArkWeb 引擎/文档（重建只付一次组件+加载）；容量下调按 suspend 抢占超容量 claim（旧 2 槽壳安全降级）；`web slot destroy`
  原文可能秒级轮转丢失——以截图 + 重建交互闭环为准；第 5 槽未真机点验（headless 限值 drill 覆盖 2/4 夹取）。
- **INTERP-RENDER 口径（#45）**：解释器固有放大（draw 18.6 + present 3.2 > 16.7 ms vsync）是主因；本波去掉的是**静态帧
  全树 Measure/Arrange（13.0 ms/帧）**，非脏区/裁剪；30 fps 为当前上限。判定以 `FPH` 稳态窗 + 交互回归为准；JIT/AOT
  60 fps 不应回归。
- **AOT 默认口径（#43 起）**：5 MAUI hap 全 NativeAOT（`runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libhostfxr/libclrjit）；
  JIT 保形态（`--runtime-mode jit` 自建；debug 域 JITFORT 默认；release 域需 AGC ACL
  `ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`（2in1/平板）或厂商豁免——手机只发 AOT）；interp 实验（独立 pack）。
- **解释器口径**：用 **rc2b pack** + **rc.2 kit hap**（重签）；勿用 rc.1 托管 CoreLib 的旧测试件（QCall ABI 错配会
  `SIGSEGV(NULL)@coreclr_initialize`，属测试件问题、非 pack 缺陷）。`interp.txt=1|2` 混合模式保留默认（不注入 barrier skip）。
- **AOT pack 结构修复**：`FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分（静态 `.a` 保留 dlopen shim、共享 `.so` 仍静态链 OpenSSL；
  sdk 构建在布局与 nupkg 两处校验）——**当前资产 = `-struct1`**（asset 607541145；`-r2`/原包仅历史），后续 runtime pack 无需再重打。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递（`skills[].uris` 本机产物已可验）；②镜像扩展分支
  `m-web-mirror d47f1fcb3b` 尚未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过（未定位）；
  ④stock JIT 长跑/后台唤醒未覆盖；⑤第 5 槽未真机点验。相关项登记「未测（在途）」不判失败。
- **rc.2 相关**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；rc.1 回滚线保留；
  应用侧构建请同步 rc.2 线（`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5）。
- **hilog 缓冲（探针误报防护）**：512K 环在噪声大时只保留 ≈4–5 s（`--blazor-probe` 曾丢 `BLZ_BOOT` 报 `boot=no`）；临时
  `hilog -G 16M -t app,core` 重跑（**跑完还原 512K**）。另注意**状态文件伪影**：`dotnet-status.txt`/壳轮询可能输出上一轮
  残留行——**以本轮时序内状态为准**。
- **本机直测（交付方）**：设备已可测（hdc 无线 `127.0.0.1:35111` + SDK 自签 + AOT/JIT/解释器三路径）；AOT 默认在 enforcing
  镜像开箱可装（DEVCOMPAT-DEFAULT，承 #41）。
- 所有数字 = **kit #45 发布实测（以 release「## Integrity（kit #45）」与随包校验为准）**：tar **67,695,181 / `ca48a93c…`**、
  树 `ae0f7fce…`、sidecar `9741aced…`、`SHA256SUMS` 18 项 / 1,600 B / `9f677c40…`；
  #44 = tar 67,680,863 / `b777d8d8…`、#43 = tar 67,638,015 / `57c7bf44…`、#42 = tar 376,256,128 / `ea4e3b58…`（对照）；
  tester-run v14 = 140,197 / `a174fcd0…` 仅作对照；bundle = `workload-1.0.0-preview.28` **73,058,366 / `a8334c4c…`**
  （三处同步；dist sums `1361579b…`；sdkrc2 合并 sums 1,960 B / `f7e35a42…`；sdk 锚
  **`c7ac81ccdf`**）；dtk **392356147** / latest **392077166**（asset **609394479**/**609400064**；预签
  **609411819**/**609416429**；interp pack rc2b asset **606999003**）；CI **5/5** @ `b6ad0b0`
  （interaction `37179088257` / pixel `37179088247` / host-export `37179088318` / ridgraph `37179088251` / markdownlint `37179088241`）；
  sdk `ohos-install-tests` @ `c7ac81ccdf` run `37186486446`。
- 细判（TTS/HUKS/自绘深度/权限/Share-Scan）：`docs/plans/2026-09-28-ohos-tester-handoff-kit30.md` §2 与 `…kit29/kit28/kit27/kit26/kit25`；
  无障碍逐项：`docs/plans/2026-09-27-ohos-accessibility-device-verification.md`（含 N4）；#45 细节：`2026-10-04-ohos-interp-render.md`
  与 `2026-10-04-ohos-tester-handoff-kit45.md`；#44 细节：`2026-10-02-ohos-multi-overlay.md` §DYNAMIC、`2026-10-03-ohos-framepacing.md`。
