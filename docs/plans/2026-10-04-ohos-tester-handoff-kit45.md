# 测试方交接：kit #45、自动释放（FIX-AUTODISCONNECT：移除 web 控件即销毁槽 / 重挂重建）+ 渲染门控（INTERP-RENDER：interp 30 fps / CPU −13pt；JIT/AOT 60 fps 不变）+ 动态槽 3 控件 / 默认 AOT（承 #44）（2026-10-04）

> 日期口径：文件名按撰写日；**kit #45 发布实测（release「## Integrity（kit #45）」；发布已完成，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **67,695,181 B / `ca48a93c…`**、树
> **`ae0f7fce…`**、sidecar **`9741aced…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `9f677c40…`**
> （#44 = tar **67,680,863 B / `b777d8d8…`**、树 `db2604d5…`、sidecar `85d62a6e…`；#43 = tar
> **67,638,015 B / `57c7bf44…`** 对照）。重签/重打包后哈希必变；CI run id 见 §7。
> 构建基线（rc.2 线，同 #34–#44）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（结构修复后重出，承 #42）**：rc.2 runtime pack 现取 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；
> sha `09345f9515612f2b090fd0e0f54c815156105127cc1686240a3cad8521dab11c`，= sdk fetch 现锚）；结构修复
> `c1c85422715`（`FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分对象库）已入 runtime 源；旧的 `-r2`（601289590 / `542058cf…`）
> 与原包（`46d221f2…`）保留为历史、不再钉锚（重出记录见 `2026-10-03-ohos-aotpack-rebuild.md`）。
> **预签已刷新（#45，本波）**：dtk 上的 `preSigned-haps.tar.gz` 已重签为 **kit #45 件**（67,624,950 B / `e1ce8ab6…`，
> asset **609411819**；sidecar 88 B / `a7ab0943…`，asset **609416429**；替换 #44 件
> 608782132/608782732）——按 tester UDID `60CF7B27…` 预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**（非该
> UDID 报 `9568344`）。
> **在途/外部（明确）**：AGC App Linking 登记 + 真机 https 投递；镜像扩展分支 `m-web-mirror d47f1fcb3b`
> 尚未并入 `feature/openharmony`；rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；stock JIT 长跑/
> 后台唤醒未覆盖（JIT 现非默认）；第 5 槽超容量 LRU **已真机点验**（主动抢占→slot 0、Activate→恢复重放、活覆盖层 ≤4）——其余在途项登记「未测（在途）」不判失败。

> **2026-10-04 更新（FIX-AUTODISCONNECT + INTERP-RENDER；#45 增量，本包）**：
> **FIX-AUTODISCONNECT**（maui 切片 `189b87ca8a` + ohos-workload `64ee9c4`）：页面 / ContentView / Layout 处理链监听
> 元素子树的 `DescendantRemoved` / `DescendantAdded`，驱动切片本地 `IOpenHarmonyOverlaySlotLifetime` 契约——
> **移除的 web 控件发带 tag 的 hide、释放槽位**（动态槽在壳内 `web slot destroy` 销毁；热对 [0,1] 保留组件），
> **重新挂回自动重领槽并重放 load/注册**（`web slot create`）；handler 本身保持连接（MAUI 语义）、晚到的注册/属性
> pass 被忽略、LRU 抢占/恢复语义不变。真机（HAD-W24，kit 样例**无显式 `DisconnectHandler`**）：Remove web C →
> `web slot destroy: 2`（12:40:50）、覆盖层消失；re-add → `web slot create: 2`（12:41:00）并恢复交互（c1–c5 截图/JSON）。
> 套件 **+3 pin**（detach/rebuild + watcher 契约，双态编译）→ **587/589 floor 569**。
> **INTERP-RENDER**（maui `7c731a7ca3` + ow `8ed35f4`）：渲染布局门控——仅当渲染根/尺寸/safe-area insets/TitleBar 行变化、
> 根 `MeasureInvalidated` 或 `OpenHarmonyLayoutInvalidation.Version`（`IView.InvalidateMeasure` 与
> `ILayoutHandler.Add/Remove/Clear/Insert/Update` 递增）变化时才全树 Measure/Arrange；静态帧不再每帧重排。
> 真机：**interp 22.0 → 30.1 fps**（20.5–22.4 → 30.0–30.1）、**meas 13.0 → 0.0 ms/帧**、主线程 CPU
> **79.6–81.8% → 65.5–70.5%（−13pt）**；**JIT/AOT 60 fps 不变**（JIT 59–60，后段共享桌面争用 48 为噪声）、
> draw/pres 不变；交互双击 Count **0→1**、点击窗 meas max 10.8 ms；相位缝/`FPH` 探针 + `framepacing-stats.py` 增量解析。

> **结论先行**：kit #45 = **kit #44（动态槽 SLOTS-DYNAMIC + 默认 AOT + FRAMEPACING）+ 自动释放（FIX-AUTODISCONNECT）
> + 渲染门控（INTERP-RENDER）**，并承 #44 对 #43–#35 的全量包含、#42 的
> **JIT 解锁（JITFORT）/解释器 rc2b/FIX-SLICERACE/L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c** 与更早各批。指纹：壳 abc
> **368,812（`1076a700…`）/ headless 24,324（`798b2477…`）**、宿主 **297,888（`7b1694d9…`）**、导出 **151/151**、
> 套件 **587/589 floor 569**、预签已刷新至 #45。判定点见 §2；承接 #44/#43/#42/…/#34 的判定点**继续有效**，
> 本文只覆盖 #44–#45 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（AOT —— #43 起默认；无需 ACL，属推荐路径）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 探针（B2 走 MAUI WebView 内嵌 WASM；判定继续有效）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段用 kit 内 AOT hap；JIT 段需自建 jit 变体或 ACL；解释器轮改用 rc2b pack）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；**已刷新至 #45**）

`device-test-kit` release 的并列预签资产 **`preSigned-haps.tar.gz`** 当前为 **kit #45 件**（2026-10-04 重签；
asset **609411819**，**67,624,950 B / `e1ce8ab6…`**；sidecar 88 B / `a7ab0943…`，
asset **609416429**；解包树 `399ef471…`；**内容 = kit #45 的 7 hap** + `preSigned-README.md` +
`SHA256SUMS` 8/8；ZIP 条目与 kit 原件逐字节一致）。按 tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`
预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**；非 tester UDID 设备报 `9568344`。预签包是并列
附加件，完整一轮仍用 kit tar。

## 1. kit #45 相对 #44 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **FIX-AUTODISCONNECT（主判点）** | 移除一个 web 控件（WebView/HybridWebView/BlazorWebView）后：覆盖层随槽释放消失（动态槽 `web slot destroy`；热对 [0,1] 保留组件），**再挂回自动重领槽并恢复交互**（`web slot create` + load/注册重放）；handler 保持连接、晚到注册被忽略 | Remove → `web slot destroy: <k>` + 覆盖层消失；re-add → `web slot create: <k>` + 交互回显；截图 + hilog |
| 1.2 | **INTERP-RENDER（渲染门控）** | 布局只在真实失效信号时重跑：**interp 20.7→30 fps（22.0→30.1；复测 38–44）**、meas 13.0→0.0 ms/帧、主线程 CPU **−13pt（79.6–81.8→65.5–70.5%）**；JIT/AOT 60 fps、draw/pres 不变；交互不变（Count 0→1） | 解释器轮：`FPH` 稳态 fps ≥30、meas≈0；JIT/AOT 轮 60 fps 不回归；截图/探针（可选 `/data/.../interp-render/` 同法） |
| 1.3 | **承 #44：动态槽 3 控件 + 释放/重建** | MAX/HOT 默认 4/2（env 可配，clamp 2..8 / 2..max）；按需创建、释放即拆、容量事件降级、延迟命令回放；**3 控件并发出画/交互**（A/B/C invoke/raw 回显）；第 3 槽回收/重建闭环 | 3 控件各自出画 + 交互；`web cmd: slot`→`web slot create: 2`→`web capacity: 4`；与 1.1 同轮可合测 |
| 1.4 | **承 #44：默认 AOT + FRAMEPACING（承 #43）** | 7 hap 全 AOT 线：5 MAUI hap 均 NativeAOT（`runtime-mode.txt=aot`、3 `.so`、无 JIT 运行时）、首帧/交互回归；`--runtime-mode jit` 自建仍可跑 JIT（release 域需 ACL/豁免）。FRAMEPACING：宿主 5 s present 聚合，真实 **60.00 fps**（旧 17.7 = 壳状态轮询伪影）；宿主逐字节同 #43/#44（297,888 / `7b1694d9…`） | AOT 首帧 + 交互；`runtime-mode.txt=aot`/无 libcoreclr/libclrjit；60 fps 口径 |
| 1.5 | **承 #42：JIT 解锁 / 解释器 rc2b / FIX-SLICERACE / L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c/镜像** | 同 #44 交接 §1.3（JITFORT、rc2b pack、8/8 race、JPEG/心跳、Toolbar、`blzProbe`/`#app`、双映射、`skills[].uris`） | 同 `2026-10-04-ohos-tester-handoff-kit44.md` §2；AOT kit 上继续适用 |
| 1.6 | **门禁/指纹/7 hap/预签** | 交互套件 **587/589 floor 569**（FIX-AUTODISCONNECT +3 pin；INTERP-RENDER 无新 pin）、像素 `PIXEL ASSERTIONS PASSED`（0 `Known`）、宿主导出契约 **151/151**、host UND 241/DT_NEEDED 5/denylist 0；壳 abc **368,812（`1076a700…`）**/headless 24,324（`798b2477…`）、host **297,888（`7b1694d9…`）**；**7 hap**：5 MAUI 全 AOT + Blazor 默认/`-nocsp`；**预签刷新至 #45**（67,624,950/`e1ce8ab6…`，asset 609411819） | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**；套件自报行 `[suite] checks=587 total=589 floor=569 assert=True`；`runtime-mode.txt=aot` |
| 1.7 | **门禁构建（本波记录）** | kit 构建首跑 16 s 失败（CS0234 Microsoft.OpenHarmony.Maui：slice csproj HintPath 指向 src/Microsoft.OpenHarmony.Hosting|Maui.Graphics 的 Release DLL，新 worktree 未产出）——补跑两个 Release 构建（hosting 73,728/7a5d595f、graphics 16,384/59f43c0e）后 rc=0（7 hap，~8.6 分钟）；bundle repack 首跑 prepare-packs 的 Ref 构建挂在 NuGet restore（无超时网络等待）——按 kit-build-env 文档加 `RestoreConfigFile=/data/storage/el2/base/tmp/opencode/fixtest/empty-nuget.config` 后 4.8 s 完成（已固化进本波 bundle-repack45.sh）；make-device-test-kit selftest 首跑 37/1 为已知环境伪影，默认 dotnet 复跑 37/0 | 构建日志 `reg-kit45/build-*.log`（交付方侧） |
| 1.8 | **在途/外部项（明确）** | ①AGC App Linking 登记 + 真机 https 投递；②镜像分支 `m-web-mirror d47f1fcb3b` 未并入；③rc.2 csc 并行活锁（`DOTNET_PROCESSOR_COUNT=1` 绕过）；④stock JIT 长跑/后台唤醒未覆盖；⑤第 5 槽超容量 LRU 已真机点验（a11y 轮，`2026-10-04-ohos-a11y-and-capacity.md` §2） | ①–④ 登记「未测（在途）」，⑤ 已闭环；**不判失败** |

> **2026-10-04 复测回填（交付方口径，交测前以此为准）**：
> ① **发布形态请用 AOT**——自签 release×AOT 正常出画；**release×JIT 在 `coreclr_initialize` 后 ~44 ms 崩**（`SIGSEGV(SEGV_ACCERR)`，PROT_NONE 保留区），**发布域 JIT 需华为发布证书/Profile + ACL/JIT 豁免后复验**（不能由自签 release 外推）；**覆盖装需先卸载**（release↔debug `9568286`）、**过期 p7b = `9568329`**（依据 `2026-10-04-ohos-release-domain-and-pidloss.md`）。
> ② **启动/帧率复测（#45 切片同源重出）**：三路径 cold/warm 首帧 **1.56–1.69 s**（JIT 1.68/1.68、interp 1.62/1.56、AOT 1.69/1.64）；interp 稳态 **38–44 fps**（安静桌面；≥30 判过）、JIT/AOT **60 fps**（依据 `2026-10-04-ohos-jit-interp-recheck.md`）。
> ③ **第 5 控件超容量已真机点验**：加第 5 控件 → 主动抢占（E 领 slot 0、A suspend 消失）→ Activate A → A 领 slot 1 + 恢复重放（B 被抢占），全程活覆盖层 ≤4（依据 `2026-10-04-ohos-a11y-and-capacity.md` §2）。
> ④ **a11y**：本沙箱**无读屏客户端**（AMS `accessible=0`/client=0）→ 朗读/焦点顺序/动作类**不可测**（未过 0）；测试方请带 **ScreenReader 环境**复跑 T2/L1/N1/F2 等；**A11Y 按钮临时经 suspend/hide 可达**（FIX-A11YBTN 未落地）。
> ⑤ **rc.2 监测**：官方 rc.2 **未发布（WAIT，2026-10-04 复核）**；ohos-workload 已加 `rc2-watch`（`1d39eb7`）；触发后按 `2026-09-30-rc2-mainline-adoption.md` §8 换 pin。

> 尺寸预算：以 release 资产表为准（#44 = 67,680,863 B；#45 = 67,695,181 B，delta = MAUI 5 hap 以新切片重建
> 的字节差；AOT 线无 libcoreclr，整包远小于 #42 的 376 MB）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **自动释放（主判点 1，FIX-AUTODISCONNECT）** | 装默认 kit 主 hap（AOT）→ 加满 3 个 Web 控件 → **移除第 3 个** → 再**加回** | 移除即释放：动态槽销毁（hilog `web slot destroy: <k>`）、覆盖层消失、热对 [0,1] 不受影响；再加回：`web slot create: <k>` 重建并恢复交互（raw/invoke 回显） | 移除前后 + 重挂后截图（c1–c5 同构）+ hilog 原文 |
| **动态槽 3 控件并发（主判点 2，承 #44）** | 同页加满 3 个 Web 控件 | 3 控件各自出画并可交互（A、B、C 各自 invoke/raw 回显 label）；第 3 槽按需创建（`web cmd: slot`→`web slot create: 2`、容量 `web capacity: 4`） | 截图（3 控件同页）+ hilog |
| **INTERP-RENDER（渲染门控，主判点 3）** | 解释器轮（rc2b pack + rc.2 kit hap + `interp.txt=3`）出画稳定后统计 | **interp 稳态 ≥30 fps（20.7→30；交付方复测 38–44）**、meas≈0 ms/帧、主线程 CPU 65.5–70.5%（−13pt）；JIT/AOT 轮 **60 fps 不变**；交互 Count 0→1 | `FPH`/帧统计 + 截图 + hilog（无对应入口登记「未测」） |
| **AOT 默认（主判点 4，承 #44）** | 装默认 kit 主 hap（无需 ACL）→ 冷启 | `runtime-mode.txt=aot` + hap marker；`libs/arm64-v8a` 仅 3 `.so`、无 `libcoreclr`/`libclrjit`；**首帧 + 交互回归** | 截图 + `verify-kit` 深度断言 + hilog |
| **FRAMEPACING（承 #43）** | 宿主 present telemetry（5 s 桶）出画稳定后统计 | 真实呈现 **60.00 fps**（旧 17.7 系壳状态轮询伪影） | 帧统计/终端输出 |
| **套件基座** | 有源码测试者跑 `test/maui-platform-verify` | `[suite] checks=587 total=589 floor=569 assert=True`；导出 151/151 | 终端输出 |
| **承 #42：JIT 解锁 / 解释器 rc2b / FIX-SLICERACE** | 自建 jit 变体（或 ACL）冷启；rc2b pack + rc.2 kit hap + `interp.txt=3`；JIT 8 轮 | JIT：`jitfort rc=0` + 探针 `1=OK 2=OK` + `canvas presented`；interp：`canvas presented`、无 `SIGSEGV(NULL)`；race=0 | 截图 + hilog |
| **承 #42：L6 / LEGACY / SAMPLE-FIX / WX-PATCH2 / P2c** | 截图 JPEG、Toolbar 契约、`blzProbe`/`#app`、双映射、`module.json skills` | 同 #42 期望（AOT 线继续适用） | 截图 + hilog + `module.json` 摘录 |
| **承 #41：MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX** | 双 Hybrid/抢占/恢复（3 控件场景已覆盖）；enforcing 装包；8 MB 栈 | 同 #41 期望 | 截图 + hilog |
| **承 #40/#39/#38/#37/#36/#35：FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10** | 见 `2026-10-03-ohos-tester-handoff-kit42.md`/#41/#40/#36 §2 | 同前各期望；套件自报行 `587/floor 569` | 截图 + hilog + `dotnet-status.txt` |
| **承 #34/#33：rc.2 自述 + W6/W7/W8 + Blazor A/B + 主体** | 包内自述；各卡 | SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；逐项同 #34/#33 | 自述原文 + 截图 + `--a11y-probe` |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#44）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.2.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（结构修复后重出）**：当前用 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；sdk fetch
   现锚，`versions.env` sha `09345f9515612f2b090fd0e0f54c815156105127cc1686240a3cad8521dab11c`）；`c1c85422715`
   起 `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分对象库（静态 `.a` 保 shim、共享 `.so` 静态 OpenSSL；sdk 布局+nupkg
   两处校验）；`-r2`（601289590）/原包（`46d221f2…`）仅历史。
3. **解释器 pack（#42 更新；本波未动）**：用 **`ohos-interpreter-pack-rc2b.tar.gz`**（2,410,595 / `5974430509…`，
   asset 606999003）+ **rc.2 kit hap**（重签）+ #42+ 宿主；**勿用 rc.1 托管 CoreLib 的旧测试件**（QCall ABI 错配
   会 NULL 崩）；`interp.txt=1|2` 混合模式保留默认；INTERP-RENDER 判定见 `2026-10-04-ohos-interp-render.md`。
4. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`（CoreLib `417ab220532` 起）；
   enforcing 镜像直接装默认 kit 件（DEVCOMPAT-DEFAULT）；AOT 为默认（`-p:OpenHarmonyRuntimeMode=aot`）。
5. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   **官方 rc.2 未发布（WAIT，2026-10-04 复核）**：ohos-workload 已加 `rc2-watch`（`1d39eb7`；`scripts/rc2-official-watch.sh` +
   `.github/workflows/rc2-watch.yml`，周一 03:17 UTC + dispatch；状态 `docs/rc2-official-watch.md`）；触发后按
   `2026-09-30-rc2-mainline-adoption.md` §8 换 pin、删 feed step（承 #34 注记）。
6. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（本文随附；kit #45 manifest 刷新
   **`7b0c76a5fd6`**，父 `b486c6561e8` = #44）；maui = **`189b87ca8a`**（AUTODISCONNECT 切片；父 `7c731a7ca3`
   = INTERP-RENDER ← `3feb347414` = SLOTS-DYNAMIC）；ohos-workload master **`b6ad0b0`**（pin；父 `64ee9c4`
   = AUTODISCONNECT 套件/打包文档 ← `8ed35f4` = INTERP-RENDER 相位探针/stats ← `86b0e89`）；sdk 锚 **`c7ac81ccdf`**
   （`WORKLOAD_BUNDLE_SHA256` 3b3008a4 → **a8334c4c**；-r2/struct1 pack 与 interp rc2b 引用保持；
   父 `2abf4fcaa3` = #44 锚）；aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#44）：本机桌面 HAD-W24 / OpenHarmony 7.0.0.111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`
  （UDID `1BCE13C8…AEA0`）；SDK `sign-hap.sh` 自签；AOT 为默认路径，JIT/解释器按各自资产。
- **#45 本轮证据（FIX-AUTODISCONNECT）**（scratch `autodisconnect/`，HAD-W24，12:40–12:41）：探针 hap
  **22,468,329 B / `f6d7a46f…`**（本地补丁构建件，判读限「机制可用」）；序列：12:40:26 `canvas presented` →
  12:40:28.900 `web cmd: slot` → **12:40:28.901 `web slot create: 2`** → 12:40:29 加 C → 12:40:40–43 C 交互
  （`sent raw C-raw-ping (stock)`、`invoke: "C-echo:Echo:1"`）→ **12:40:50.021 `web slot destroy: 2`**（Remove C，
  覆盖层消失）→ **12:41:00.634 `web slot create: 2`**（re-add，slot 2 重建）→ 12:41:11–14 C 交互恢复；截图
  `c0-startup`/`c1-add-c`/`c2-interactive`/`c3-remove-c`/`c4-readd-c`/`c5-readd-interactive` + 对应 JSON 节点树
  （c3 无 C 节点、c4/c5 C 回归）。**kit 样例（无显式 `DisconnectHandler`）同轮闭环**——这就是 #44 自验抓到的缺口
  （Remove 仅 label 翻转、0 条 destroy）在本波被修复的直接证据。
- **#45 本轮证据（INTERP-RENDER）**（scratch `interp-render/`，09:24–09:55）：interp 前 20.5–22.4 fps / meas 12.8–14.3 ms；
  interp 后 **30.0–30.1 fps / meas 0.0**；CPU 4×10 s 窗 79.6–81.8% → **65.5–70.5%**；JIT 对照 58.9–60.1（后段争用 48）；
  `phase-*/fph.txt` + `cpu.csv` + 交互截图（Count 0→1）；off-device 套件（当时切片）584/586 floor 566、perf `within=True`。
- **#44 复测证据**（scratch `kit44-local/`、`slots-dyn/`）：AOT 7 hap 首帧/Blazor A/B PASS；3 控件并发；第 4 槽
  `web slot create: 3` → 移除 `destroy: 3→2`（本地 probe `ce21422e…`）；AOT soak 35 min 0 crash/freeze（1 次无声 pid
  丢失未归因）。
- **已知（承 #34–#44）**：JIT 主包在 enforcing 镜像**已可开箱安装**（DEVCOMPAT-DEFAULT）；JIT 首帧依赖 JITFORT
  （#42 默认；release 域需 ACL）；状态文件/轮询可能含上一轮残留行——判读以时序内状态为准。
- **本机可直接闭环**：AOT/JIT/interp 出画、多覆盖层 3 控件 + 释放/重建、Blazor 标记、a11y/日志/截图回路；命令模板 =
  `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`（窗口竞态与 hilog 缓冲注见其 §4）。

## 5. 自签与包布局要点（测试方视角；承 #34–#44）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记；本波两 hap 随基线重建，
  哈希以 release/包内 `SHA256SUMS` 为准。
- **MAUI 5 hap（全 AOT）**：payload-in-libs + DEVCOMPAT 重写；`libs/arm64-v8a` 3 `.so`（app.so + host
  297,888 + `libc++_shared.so` 1,267,392）、无 JIT 运行时；`ets/modules.abc` **368,812（`1076a700…`）**；AOT payload
  `dotnet.zip` 200,144 B / 9 项；kit 根 `runtime-mode.txt=aot`。新 hap sha 以 release/包内 `SHA256SUMS` 为准。
- **AOT/解释器资产**：均为独立资产，不在 kit tar 内；AOT 用 **`-struct1`**（asset 607541145；`-r2` 仅历史）、
  `aot-haps-v3-rc2.tar.gz`（18,185,012 / `3d24f716…`，dtk 599996905）本波未动；解释器用 **rc2b** + **rc.2 kit hap**；
  安装会顶替 kit 主包，回 AOT 重装 kit hap。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #45）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准；
  **预签件本波已刷新（#45 件）**——非 tester UDID 设备仍 `9568344`，请回传 UDID 代签。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs/宿主依赖（UND 241）；5 MAUI hap 期望 `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；
   abc 期望 = **368,812（`1076a700…`）/24,324（`798b2477…`）**，脚本哈希以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮（AOT）/ `--blazor-probe` / `--mode-matrix`（解释器轮用
   **rc2b pack**）/ `--a11y-probe` 四件同 #42。
3. **7 hap 表（kit #45 发布实测；`SHA256SUMS` 18 项 / 1,600 B / `9f677c40…`）**：`hello-maui-app.hap`
   **22,333,257 / `6fa99da2…`**（AOT）、`…-unsigned` **22,031,007 / `787c1c10…`**、`…-permissions`
   **22,333,270 / `8f3acf1a…`**、`…-api20` **22,333,246 / `3b8a7d4b…`**、`…-api20-permissions`
   **22,333,273 / `2e15d418…`**、Blazor 默认 **27,216,958 / `e7d5a62c…`**（未签名）、
   `-nocsp` **27,216,659 / `6840268e…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。
   整包 tar **67,695,181 / `ca48a93c…`**、树 `ae0f7fce…`、sidecar `9741aced…`；bundle
   `openharmony-workload-1.0.0-preview.28.tar.gz` **73,058,366 / `a8334c4c…`**（三处同步；dist sums
   `1361579b…`；sdkrc2 合并 sums 1,960 B / `f7e35a42…`；sdk-ohos 锚 **`c7ac81ccdf`**，
   `WORKLOAD_BUNDLE_SHA256` 3b3008a4 → a8334c4c）；**解释器 pack rc2b**（asset 606999003）与
   **`-struct1` AOT pack**（asset 607541145）保持；**预签已刷新（#45 件：asset 609411819 /
   609416429）**；发布已完成：kit tar/边车两处（dtk **392356147** / latest **392077166**；asset
   609394479/609400064，latest 同件 609400279/609407442）+ bundle
   三处；四条 release body 含 `## Integrity (kit #45)`（含预签行）；by-id 抽验 + 公开直连抽验见 release。重签/重打包
   后必变，以 release 与随包校验为准；有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据
   （同 #29–#44）。
4. 离线证据（供复核）：套件 **587/589 floor 569**、像素 PASS（0 Known）、导出 **151/151**、壳 abc
   **368,812/24,324**（四包一致 + provenance）、host **`7b1694d9`**/UND 241、`build-arkts-shell`、`verify-kit`、
   packs/repo-hygiene/tasks；selftests：build-arkts / make-mode-kit / make-device-test-kit / sign-for-device / devloop / commit-paths / tester-run / verify-kit 全绿（含 0 FAIL/0 WARN；细节 reg-kit45/selftest-*.log）；#45 设备证据见 scratch `autodisconnect/`（FIX-AUTODISCONNECT）
   与 `interp-render/`（INTERP-RENDER）；#44 见 `kit44-local/`、`slots-dyn/`；#43 见 `2026-10-03-ohos-framepacing.md`；
   #42 证据见 `2026-10-03-ohos-tester-handoff-kit42.md` §4。

## 7. 风险 / 未验证（诚实清单）

- **本轮自动释放（FIX-AUTODISCONNECT）的 tester 机复核仍待做**：交付方在本机闭环（kit 样例 Remove→destroy→re-add→
  create→交互，探针件另证第 4 槽）；不同窗口形态与共享桌面环境请按 §2 同法复测；无入口按「未测」登记，不判失败。
  **未知项**：`web slot destroy` 原文在 hilog 512K 环下秒级轮转可能缺失（本波已用流式采集取到原文；仍建议以截图 +
  重建闭环为准）；第 5 槽超容量 LRU **已真机点验**（主动抢占→slot 0、Activate→恢复重放、活覆盖层 ≤4；headless 限值 drill 覆盖 2/4 夹取）。
- **INTERP-RENDER 边界**：30.1 fps 系共享桌面争用态；复测（安静桌面）interp 稳态 **38–44 fps**（draw 14.3/pres 1.4，
  `2026-10-04-ohos-jit-interp-recheck.md`），未做脏区/裁剪；单设备/共享 2in1 采数（OPT 稳态窗 3–5 个）；JIT 后段 48 fps
  系争用噪声；手机域/release/AOT 组合未逐一复测。
  渲染门控正确性以套件 pin（TitleBar 行、`Layout.Add` 版本信号）+ 真机交互回归把关。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递（P2c 本机产物已可验；自签包仍走显式 want）；
  ②镜像分支 `m-web-mirror d47f1fcb3b` 未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1`
  绕过未定位；④stock JIT 长跑/后台唤醒未覆盖（JIT 现非默认形态）；⑤解释器混合模式（`interp.txt=1|2`）保留默认。
- **AOT 默认边界**：JIT/解释器均需动态码；release/生产域请走 AOT 或申请 ACL
  （`ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）；手机只发 AOT。`-p:OpenHarmonyRuntimeMode=jit`
  自建 jit 变体仍可复现 #42 三路径判定。**发布域实测（2026-10-04）**：自签 release×AOT 正常；release×JIT `coreclr_initialize`
  后 ~44 ms 崩（需华为发布 Profile + ACL/JIT 豁免后复验）；覆盖装先卸载（`9568286`）、过期 p7b=`9568329`
  （`2026-10-04-ohos-release-domain-and-pidloss.md`）。
- **a11y 边界（2026-10-04 设备轮）**：本沙箱无读屏客户端（AMS `accessible=0`/client=0）→ T2 读屏开启态/L1 Label 朗读/
  N1 List/F2 滚动焦点保持等「朗读/焦点顺序/动作」类不可测；**测试方需带 ScreenReader 环境复跑**；A11Y 按钮
  **临时经 suspend（抽屉）/hide（切 tab）可达**（FIX-A11YBTN 未落地；`2026-10-04-ohos-a11y-and-capacity.md` §1/§3）。
- **动态槽边界**：热对 [0,1] 常驻；空闲 >2 不养 ArkWeb 引擎/文档（重建只付一次组件+加载，权衡写在类头，无定时器）；
  容量下调按 suspend 抢占超容量 claim（旧 2 槽壳安全降级）；env 不可按应用注入。
- **解释器口径**：rc2b pack 只配 rc.2 kit hap + #42+ 宿主；旧 rc.1 托管 CoreLib 测试件会 QCall ABI NULL 崩（测试件问题）。
- **AOT pack 结构性缺陷（已修复入源）**：`c1c85422715` 拆分对象库；当前资产 = **`-struct1`**（asset 607541145）——
  `-r2`（601289590）/原包（`46d221f2…`）仅历史，后续 pack 无需重打。
- **ICU/InvariantGlobalization（承 #42）**：本镜像无系统 ICU——宿主自动 invariant；应用侧如遇 hosting FailFast 可参考。
- **hilog 缓冲/状态伪影**：512K 环噪声大时 ≈4–5 s；`dotnet-status.txt`/轮询可能含上一轮残留行——以时序内状态为准；
  临时 `hilog -G 16M` 复核后请还原 512K。
- **门禁（本轮已跑）**：交互 587/589 floor 569（+3 FIX-AUTODISCONNECT pin）、像素 PASS（无 `Known(...)`）、导出 151/151、
  preflight OK（ridgraph 20 / packs 25 / hap-targets 73 / tasks 9 / repo-hygiene 25）、CI 5/5 @ `b6ad0b0`
  （interaction `37179088257` / pixel `37179088247` / host-export `37179088318` / ridgraph `37179088251` /
  markdownlint `37179088241`）+ sdk `ohos-install-tests` @ `c7ac81ccdf` run `37186486446`；runtime manifest
  提交 `7b0c76a5fd6` 为 docs-only（无 workflow run）。
