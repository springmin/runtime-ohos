# 测试方交接：kit #48、R2R/JIT 启动（CG2-R2R：1031→710 ms）+ AOT 首帧省时（AOT-STARTUP：796→534 ms）+ 帧率投票 60（FPS48：46.2→60.0）+ 多窗 S（MULTIWINDOW-S：3120×1955）+ FIXRR（承 #47 FIX-A11YFLYOUT / FIX-PREEMPT-RAW 与 #46/#45 全量）（2026-10-05）

> 日期口径：文件名按撰写日；**kit #48 发布实测（release「## Integrity（kit #48）」；发布已完成，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **67,735,148 B / `5c22704f…`**、树
> **`6b2b493c…`**、sidecar **`1c51cdbc…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `a05caba0…`**
> （#47 = tar 67,706,719 / `3d6bb58b…`、树 `0f266636…`、sidecar `4adb0b60…`；#46 = 67,708,823 / `c7c11814…` 对照）。
> **预签已刷新至 #48**（7 hap；**67,651,331 / `2f2f4c40…`**，asset **612061141**；sidecar 88 B /
> `50a1f38e…`，asset **612062470**；树 `cf853bad…`；替换 #47 件 610975429/610976421）——按 tester UDID
> `60CF7B27…` 预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**（非该 UDID 报 `9568344`）。
> 构建基线（rc.2 线，同 #34–#47）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（结构修复后重出，承 #42）**：rc.2 runtime pack 现取 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；
> `-r2`（601289590）/原包（`46d221f2…`）仅历史）；**本波新增 Crossgen2 rc.2 包**（43,792,647 / `6bb8a375…`，
> `crossgen2-packs-11.0.0-rc.2`，JIT R2R 经 folder feed 消费）。
> **在途/外部（明确）**：AGC App Linking 登记 + 真机 https 投递；镜像扩展分支 `m-web-mirror d47f1fcb3b`
> 尚未并入 `feature/openharmony`；rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；stock JIT 长跑/
> 后台唤醒未覆盖（JIT 现非默认）；解释器混合模式（`interp.txt=1|2`）保留默认。

> **结论先行**：kit #48 = **kit #47（FIX-A11YFLYOUT + FIX-PREEMPT-RAW；承 #46 INTERP-DRAW2/FIX-A11YBUTTON）
> + R2R/JIT 启动（CG2-R2R：JIT 冷启 1031→710 ms，−31%）+ AOT 首帧省时（AOT-STARTUP：AOT 796→534 ms，−33%）
> + 帧率投票 60（FPS48：干扰态 46.2→60.0 fps）+ 多窗 S（MULTIWINDOW-S：supportWindowModes + CanArrangeSurface；
> 真机 3120×1955）+ FIXRR（interp R2R=0）**，并承 #45 的自动释放/渲染门控/动态槽/默认 AOT/FRAMEPACING 与
> #42–#35 各批。指纹：壳 abc **375,268（`9cd2b4c3…`）/ headless 24,324（`798b2477…`）**、宿主
> **297,888（`319db8e5…`）**、导出 **151/151**、套件 **599/601 floor 581**、预签已刷新至 #48；
> 切片 `ed02203bfd`（maui，MULTIWINDOW-S ← `d5384d6cc3` FIX-A11YFLYOUT）+ ow `c42cfa43`（pin `a491cdaf4b`），
> sdk 锚 `767c03ee71`。判定点见 §2；承接 #47/#45/#44/…/#34 的判定点**继续有效**，本文覆盖 #48 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（AOT —— #43 起默认；无需 ACL，属推荐路径）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# #48 主判点 1：R2R/JIT 启动数字（需自建 R2R jit 变体：Crossgen2 folder feed 见 §3；
#   构建后用该 hap 替换 kit 主包装机执行常规一轮）
# #48 主判点 2/3/4：AOT 冷启计时 / 帧率投票 / 多窗尺寸（手动脚本见 §2）
# Blazor 探针（B2 走 MAUI WebView 内嵌 WASM；判定继续有效）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段用 kit 内 AOT hap；JIT 段需自建 jit 变体或 ACL；解释器轮改用 rc2b pack）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3-rc2.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；**已刷新至 #48**）

`device-test-kit` release 的并列预签资产 **`preSigned-haps.tar.gz`** 当前为 **kit #48 件**（2026-10-05 重签；
asset **612061141**，**67,651,331 B / `2f2f4c40…`**；sidecar 88 B / `50a1f38e…`，asset **612062470**；
树 `cf853bad…`；**内容 = kit #48 的 7 hap** + `preSigned-README.md` + `SHA256SUMS` 8/8；ZIP 条目与 kit
原件逐字节一致；7/7 `sign-hap.sh` + `verify-app` success、device-ids 单值 = tester UDID）。按 tester UDID
`60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19` 预签，`sha256sum -c SHA256SUMS` 后
`hdc install -r` **直装**；非 tester UDID 设备报 `9568344`。预签包是并列附加件，完整一轮仍用 kit tar。

## 1. kit #48 相对 #47 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **CG2-R2R（#48 主判点 1）** | rc.2 Crossgen2 包（43,792,647 / `6bb8a375…`，sdk-ohos `crossgen2-packs-11.0.0-rc.2`）作 folder feed，JIT 自建包加 `-p:PublishReadyToRun=true`：IL→R2R 冷启 **1031→710 ms（−321 / −31%；n=3）**，进程内 present 575→307 ms；R2R 件 +11 MB；interp 不执行 R2R 原生码，故不启用（见 1.5） | JIT R2R 变体冷启 AMS→首帧 ≈0.71 s 档（≤0.8 s）、`hello-maui-app.dll` 含 `RTR\0`、`canvas presented`；与 IL 件对照（本机交付方 A/B 已取） |
| 1.2 | **AOT-STARTUP（#48 主判点 2）** | 壳隐藏 ArkWeb 覆盖层声明保留、**首用才挂载**（`web overlays mounted on first use`）+ 宿主对相同 app-context **跳过 surface 重放**：CEF 初始化（~240 ms）移出首帧路径 → AOT **796→534 ms（−262 / −33%）**、Main→首帧 386→151、attach→surface 239→13 ms；JIT/interp 不回归（JIT 新宿主 0 次 THREAD_BLOCK） | AOT 冷启首帧 ≈0.53 s 档；首帧后 3–17 ms 才挂覆盖层、hybrid 注册/装载照常（`web cmd: hybrid`→`hybrid assets`→`web serve`）；无死锁（无 ThreadBlock6S） |
| 1.3 | **FPS48（#48 主判点 3）** | 宿主注册 XComponent onFrame 时声明期望 60 Hz（`{60,60,60}`）：RS 60/30 仲裁消失；第二持续重绘窗口干扰态 5s 窗均值 **46.2→60.0 fps**（清净态 60.1；app 每帧 draw/pres/work 不变） | 干扰态（另开持续重绘应用）帧统计 5s 窗 ≥58 fps 为主、无 30 窗；无动画时 0 app 帧（门控）不判失败 |
| 1.4 | **MULTIWINDOW-S（#48 主判点 4）** | 壳 `module.json` 声明 `supportWindowModes:["fullscreen","split","floating"]` + 订阅 `windowSizeChange`/`freeWindowModeChange`（日志 `[maui] window size change: WxH free=…`）；切片 `CanArrangeSurface`（Created/Changed 且尺寸>0 重排；Destroyed/0x0 保末帧）写 `[maui] window size WxH`；真机 2in1 最大化 **2090×1394→3120×1955**（`surface state=Changed 3120x1885` → `canvas presented (3120x1885)`） | 最大化/分屏拖拽后窗口内容跟随（截图 + `window size change` + `[maui] window size` + `canvas presented`）；恢复/收窗后**末帧保留**不白屏；a11y 自检 nodeCount 70、无新 fault |
| 1.5 | **FIXRR（interp R2R=0，ow `08ccbe8`）** | 宿主在 `DOTNET_InterpMode=3` 旁置 `DOTNET_ReadyToRun=0`；本 runtime `eeconfig.cpp:479-486` 对 `InterpMode>=2` 本就强制 `fReadyToRun=false`，该行是显式防御。真机 interp+R2R 件 Main→首帧均 614 ≈ IL 件 609（旧 +350 ms 未复现，归因 AMS/时点噪声）；套件 +1 pin | interp 轮（rc2b pack + rc.2 kit hap + `interp.txt=3`）：`canvas presented`、无 `SIGSEGV(NULL)`；首帧与 IL 件同档；JIT/混合 1/2 不受影响 |
| 1.6 | **承 #47：FIX-A11YFLYOUT（主判点）** | `PushChildren` 补 `FlyoutPage.Detail`（恒入树）/ `FlyoutPage.Flyout`（仅 `IsPresented`）分支；真机 `--a11y-probe` **nodeCount 1→70**（此前只发布根） | 同 #47 交接 §2：`accessibilityStatus: 1`、nodeCount=70；detail 恒发布、flyout 仅展开时发布且保 detail；读屏环境复跑 T2/L1/N1/F2/E1 |
| 1.7 | **承 #47：FIX-PREEMPT-RAW（主判点）** | 壳 `pollManagedStatus` 把 `dotnet-status.txt` 新增段含 `overlay preempted/restored/replay` 的行以 **`[maui-capacity]`** 前缀直写 hilog；加 C/D/E（E 抢 A 槽）→ Activate A 取到原文 `preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`（交付方一轮 5 行） | 同 #47 交接 §2：hilog 原文 + `hybrid assets slot=` 语义链 + 截图/JSON；512K 环噪声大时按「未测」登记 |
| 1.8 | **承 #46/#45：INTERP-DRAW2 / FIX-A11YBUTTON / 自动释放 / INTERP-RENDER / 动态槽 / 默认 AOT / FRAMEPACING** | 同 #46/#45 交接 §1：interp draw 14.4→9.4 ms、33.9→60.1 fps；按钮左下角两态可达；Remove→`web slot destroy`→re-add→`web slot create`；interp ≥30 fps、meas≈0；3 控件并发 + 第 5 槽 LRU；`runtime-mode.txt=aot`、无 JIT 运行时；60.00 fps | 同 `2026-10-05-ohos-tester-handoff-kit47.md` / `…kit45.md` §2；AOT kit 上继续适用 |
| 1.9 | **承 #42–#35：JIT 解锁 / 解释器 rc2b / FIX-SLICERACE / L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c / MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX / FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10** | 见对应交接文；判定点继续有效 | 同前各期望（套件自报行更新为 `599/601 floor 581`） |
| 1.10 | **门禁/指纹/7 hap/预签** | 交互套件 **599/601 floor 581**（#48 +1 CG2-R2R interp R2R=0 pin +2 MULTIWINDOW-S；另 WASM-MIME +2、AOT-STARTUP +1 计入链）、像素 `PIXEL ASSERTIONS PASSED`（43 PASS）、宿主导出契约 **151/151**、host UND **242**/DT_NEEDED 5/denylist 0；壳 abc **375,268（`9cd2b4c3…`）**/headless 24,324（`798b2477…`）、host **297,888（`319db8e5…`）**；**7 hap**：5 MAUI 全 AOT + Blazor 默认/`-nocsp`；**预签刷新至 #48** | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**（ui abc 期望 375268）；`[suite] checks=599 total=601 floor=581 assert=True`；`runtime-mode.txt=aot` |
| 1.11 | **在途/外部项（明确）** | ①AGC App Linking 登记 + 真机 https 投递；②镜像分支 `m-web-mirror d47f1fcb3b` 未并入；③rc.2 csc 并行活锁（`DOTNET_PROCESSOR_COUNT=1` 绕过）；④stock JIT 长跑/后台唤醒未覆盖；⑤解释器混合模式保留默认；⑥Crossgen2 包未本机重编（复用 rc.2 主线 CI 字节） | ①–⑥ 登记「未测（在途）」，**不判失败** |

> **2026-10-05 复测回填（交付方口径，交测前以此为准）**：
> ① **CG2-R2R（#48 主判点 1）**：设备 HAD-W32；4 件 StartupProbe hap（JIT/interp × IL/R2R，同 SDK/同 pin）
> JIT IL 均 **1031 ms** vs R2R 均 **710 ms**（−321/−31%）；in-proc `[startup] present` 575→307；R2R 未改
> AMS→Main 档；AOT 不消费 crossgen2（不受影响）；R2R 件 3×2 次运行 0 崩、pid 尾活；interp R2R 见 ③。
> ② **AOT-STARTUP（#48 主判点 2）**：同载荷/新壳宿主 A/B（pilot vs aot-opt）；AOT AMS→首帧 753–841（796）
> → 522–546（534）、Main→首帧 376–392（386）→ 146–155（151）、attach→surface 228–248（239）→ 12–14（13）；
> 首帧后 3–17 ms 挂覆盖层、hybrid 照常；JIT/interp 不回归、JIT 新宿主 0 次 ThreadBlock6S。
> ③ **FIXRR（interp R2R=0）**：interp+R2R 修复宿主 6 次 Main→首帧 578–682（614）≈ IL 件 595/593/640（609）；
> 去掉该行的对照宿主 569/564/612（582）→ 同档；显式行与 runtime 隐式 `fReadyToRun=false` 同效。
> ④ **FPS48（#48 主判点 3）**：同件同机对照——第二重绘件前台 60s 后 stock 5s 窗均值 **46.2** vs vote60
> **60.0**（清洁态 stock/vote 均 60.1；wait 12.0/28.9 ms、pres 2.5–4 ms、draw 恒定）；RS `activeMode=60`
> 无 48 模式；投票在注册期常驻（idle 动态撤票列为后续）。
> ⑤ **MULTIWINDOW-S（#48 主判点 4）**：真机 2in1 最大化 2090×1394→**3120×1955**；`surface: state=Changed
> 3120x1885` → `canvas presented (3120x1885)` → 壳 `window size change: 3120x1955 free=true` + 切片
> `[maui] window size 3120x1885`；a11y nodeCount 70、无新 fault；回归交互通过。
> ⑥ **承 #47 复测**：a11y nodeCount 1→70（probe5 AOT）、抢占原文 5 行 `[maui-capacity]`（细节见 #47 交接
> 回填）；INTERP-DRAW2 复测触 60 Hz 上界；SOAK-JI 三路径浸泡背书沿用。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **R2R/JIT 启动（主判点 1，CG2-R2R）** | 自建 JIT R2R 变体（rc.2 SDK + `crossgen2-packs-11.0.0-rc.2` folder feed + `-p:PublishReadyToRun=true`，见 §3）→ 冷启 3 次 | AMS→首帧 **≈0.71 s 档**（≤0.8 s；IL 对照 ~1.03 s）；in-proc present ≤350 ms；`canvas presented`、交互正常 | 冷启计时（`startup.json`/`[startup]` 行）+ 截图 + `hello-maui-app.dll` 含 `RTR\0`（可选 `r2r` 标记） |
| **AOT 首帧省时（主判点 2，AOT-STARTUP）** | 装默认 kit 主 hap（AOT）→ 冷启 3 次；观察首帧与覆盖层挂载次序 | AMS→首帧 **≈0.53 s 档**（≤0.6 s；旧 0.80 s）；`web overlays mounted on first use` 出现在首帧后；hybrid 装载照常 | 冷启计时 + hilog（`[startup-shell]`/`web overlays mounted`/`web cmd: hybrid`）+ 截图 |
| **帧率投票 60（主判点 3，FPS48）** | 另开一个持续重绘应用（干扰态）→ kit 主包动画页采样 ≥60 s | 5s 窗稳态均值 **≥58 fps**（交付方 46.2→60.0）；无整段 30 窗；draw/pres 不变 | FPH/帧统计（`FPH` 行）+ 截图；无动画态 0 app 帧属预期 |
| **多窗 S（主判点 4，MULTIWINDOW-S）** | 2in1：拖拽最大化/分屏/恢复（或不拖拽直接最大化）；采 hilog + 截图 | 窗口尺寸跟随（`window size change: WxH free=…` + `[maui] window size WxH` + `canvas presented (WxH)`）；收窗/0×0 **保末帧**；a11y 70 | 截图（最大化前后）+ hilog + `surface state=` 行 |
| **FIXRR：interp R2R=0（主判点 5）** | 解释器轮（rc2b pack + rc.2 kit hap + `interp.txt=3`）冷启；如自建 interp R2R 件对照 | `canvas presented`、无 `SIGSEGV(NULL)`；Main→首帧与 IL 件同档（交付方 614 vs 609）；无 +11 MB 无效映射 | hilog + 帧统计 + 截图 |
| **承 #47：FlyoutPage a11y 节点数** | 装默认 kit 主 hap（AOT）→ `--a11y-probe`（或 `uitest` 点 `A11Y` 自检按钮） | `a11y/selfcheck.txt`：`accessibilityStatus: 1`、**nodeCount=70**（此前 1）；带读屏环境复跑 T2/L1/N1/F2/E1 | `a11y/` 两文件 + 截图 + `summary a11y_*`；无读屏环境按「部分/未测」登记 |
| **承 #47：抢占/恢复/重放原文** | 加满 3 控件后加 C/D/E（E 抢 A 槽）→ Activate A；抓 hilog | `[maui-capacity]` 原文：`preempted: slot 0` / `preempted: slot 1` / `restored: slot 1` / `replay: slot 1`；活覆盖层 ≤4 | hilog 原文 + `hybrid assets slot=` 行 + 截图/JSON |
| **承 #46：INTERP-DRAW2** | 解释器轮出画稳定后统计 | interp **draw ≤10 ms/帧、稳态 60 fps**（14.4→9.4、33.9→60.1；JIT/AOT 60 fps 不回归、draw −15%） | `FPH`/帧统计 + 截图 + hilog |
| **承 #46：FIX-A11YBUTTON** | 有 web 控件（Home）与 no-web 变体两态点自检按钮 | 按钮在**左下角**且覆盖层之上可点（`[523,1622][607,1668]`）；点按出对话框 `status=1` | `uitest` dump/截图两态 |
| **承 #45：自动释放 / INTERP-RENDER** | 加满 3 控件 → 移除第 3 个 → 再加回；解释器轮 stats | `web slot destroy: 2` → `web slot create: 2` + 交互恢复；interp ≥30 fps、meas≈0、CPU −13pt；JIT/AOT 60 fps 不变 | 截图 + hilog + `FPH` |
| **动态槽 3 控件 / AOT 默认 / FRAMEPACING（承 #44/#43）** | 同页 3 控件；默认包冷启；present 聚合 | 3 控件各自出画/交互（`web slot create: 2`、`web capacity: 4`）；`runtime-mode.txt=aot` + 3 `.so`、无 libcoreclr/libclrjit；真实 60.00 fps | 截图 + hilog + `verify-kit` 深度断言 |
| **承 #42：JIT 解锁 / 解释器 rc2b / FIX-SLICERACE / L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c/镜像** | 自建 jit 变体（或 ACL）冷启；rc2b pack + rc.2 kit hap + `interp.txt=3`；JIT 8 轮 | JIT：`jitfort rc=0` + 探针 `1=OK 2=OK` + `canvas presented`；interp：`canvas presented`、无 `SIGSEGV(NULL)`；race=0 | 截图 + hilog |
| **承 #41–#35：MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX / FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10** | 见 `2026-10-05-ohos-tester-handoff-kit47.md`、`…kit45.md`、`…kit42.md` §2 | 同前各期望；套件自报行 `599/601 floor 581` | 截图 + hilog + `dotnet-status.txt` |
| **套件基座** | 有源码测试者跑 `test/maui-platform-verify` | `[suite] checks=599 total=601 floor=581 assert=True`；导出 151/151 | 终端输出 |
| **承 #34/#33：rc.2 自述 + W6/W7/W8 + Blazor A/B + 主体** | 包内自述；各卡 | SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；逐项同 #34/#33 | 自述原文 + 截图 + `--a11y-probe` |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。
> **读屏环境**：交付方沙箱无读屏客户端（AMS `accessible=0`、client=0）→ 朗读/焦点顺序/动作类（T2 开启态/L1/N1/F2/E1 role）
> **不可测**；nodeCount=70 为壳自检读数。测试方请带 ScreenReader 环境复跑并按各卡回传。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#47）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.1.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（结构修复后重出）**：当前用 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；sdk fetch
   现锚）；`c1c85422715` 起 `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分对象库；`-r2`（601289590）/原包（`46d221f2…`）仅历史。
3. **Crossgen2 rc.2 包（本波新增）**：`Microsoft.NETCore.App.Crossgen2.openharmony-arm64.11.0.0-rc.2.26451.112.nupkg`
   （43,792,647 / `6bb8a375…`；sdk-ohos release `crossgen2-packs-11.0.0-rc.2`，asset `RA_kwDOT39XK84kdPmt`）
   作本地 folder feed + `RestoreConfigFile` 供 `-p:PublishReadyToRun=true`（消除 NU1100）；只用于 JIT（interp 见 4）。
4. **解释器 pack（#42 更新；本波加 R2R=0）**：用 **`ohos-interpreter-pack-rc2b.tar.gz`**（2,410,595 / `5974430509…`，
   asset 606999003）+ **rc.2 kit hap**（重签）；`interp.txt=3` 时宿主置 `DOTNET_ReadyToRun=0`（FIXRR）；
   **勿用 rc.1 托管 CoreLib 的旧测试件**（QCall ABI 错配会 NULL 崩）；`interp.txt=1|2` 混合模式保留默认。
5. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`；enforcing 镜像直接装默认 kit 件
   （DEVCOMPAT-DEFAULT）；AOT 为默认（`-p:OpenHarmonyRuntimeMode=aot`）。
6. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 **未发布（WAIT，2026-10-04 复核）**：ohos-workload `rc2-watch`（`1d39eb7`）触发后按
   `2026-09-30-rc2-mainline-adoption.md` §8 换 pin、删 feed step。
7. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（manifest 刷新 **`14fa34e34765`**，父 `80b53b39ab1`；
   本交接文再补一笔 docs-only）；maui = **`ed02203bfd`**（MULTIWINDOW-S 切片；父 `d5384d6cc3` = FIX-A11YFLYOUT
   ← `6652017ca5` = INTERP-DRAW2 ← `189b87ca8a` = AUTODISCONNECT）；ohos-workload `master` **`c42cfa43`**
   （verifier 重锚；父 `a491cdaf4b` = pin，其下 `08ccbe8` = FIXRR-R2R host+test、`c5df1de` = MULTIWINDOW-S 壳，
   另 `67a1de8` FPS48 / `22ca602` AOT-STARTUP）；sdk 锚 **`767c03ee71`**（`WORKLOAD_BUNDLE_SHA256`
   27c54c62 → **3b62cee2**；父 `266b196106` = #47 锚；bundle 73,053,084 / `3b62cee2…`）；
   aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#47）：本机桌面 HAD-W32 / OpenHarmony-7.0.0.109–111 / API 26；hdc 无线
  `tconn 127.0.0.1:35111`（UDID 随轮次）；SDK `sign-hap.sh` 自签；AOT 为默认路径。
- **#48 本轮证据**（scratch `reg-kit48/` 与能力波形 scratch `cg2-r2r/`、`aot-startup/`、`fps48/`、`multiwindow/`）：
  CG2-R2R 4 件（JIT/interp × IL/R2R）冷启 A/B；AOT pilot/aot-opt 同载荷 A/B；FPS48 stock/vote60 双宿主 +
  第二重绘干扰件；多窗 2in1 最大化实测；构建/验证日志 `reg-kit48/build-*.log`、`verify-kit48-raw.log`。
- **#47 复测证据**（scratch `fix-a11yflyout/`）：probe5 AOT `--a11y-probe` nodeCount=70；抢占原文 5 行
  `[maui-capacity]`。
- **#46/#45 复测证据**（scratch `interp-draw2/`、`fix-a11ybtn/`、`autodisconnect/`、`interp-render/`）：
  interp 60.1 fps / draw 9.4 ms；A11Y 按钮两态；移除/重挂槽；interp 30 fps 门控。
- **已知（承 #34–#47）**：JIT 主包 enforcing 镜像可开箱安装（DEVCOMPAT-DEFAULT）；JIT 首帧依赖 JITFORT
  （#42 默认；release 域需 ACL）；状态文件/轮询可能含上一轮残留行——判读以时序内状态为准。
- **本机可直接闭环**：AOT/JIT（含 R2R 自建）/interp 出画、多覆盖层 3–5 控件 + 释放/重建 + 抢占原文、
  Blazor 标记、a11y/日志/截图回路、多窗尺寸跟随；命令模板 = `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`。

## 5. 自签与包布局要点（测试方视角；承 #34–#47）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap（全 AOT）**：payload-in-libs + DEVCOMPAT 重写；`libs/arm64-v8a` 3 `.so`（app.so + host
  297,888 + `libc++_shared.so` 1,267,392）、无 JIT 运行时；`ets/modules.abc` **375,268（`9cd2b4c3…`）**；
  AOT payload `libhello-maui-app.so` 19,217,168；kit 根 `runtime-mode.txt=aot`。新 hap sha 以 release/包内
  `SHA256SUMS` 为准。
- **AOT/解释器/Crossgen2 资产**：均为独立资产，不在 kit tar 内；AOT 用 **`-struct1`**（asset 607541145）、
  `aot-haps-v3-rc2.tar.gz`（18,185,012 / `3d24f716…`，dtk 599996905）本波未动；解释器用 **rc2b** + **rc.2 kit hap**；
  Crossgen2 用 `crossgen2-packs-11.0.0-rc.2`（folder feed）。安装会顶替 kit 主包，回 AOT 重装 kit hap。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #48）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准；
  **预签件本波已刷新（#48 件）**——非 tester UDID 设备仍 `9568344`，请回传 UDID 代签。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs/宿主依赖（UND 242）；5 MAUI hap 期望 `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；
   abc 期望 = **375,268（`9cd2b4c3…`）/24,324（`798b2477…`）**；脚本 76,707 B / `c25945d9…`，以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮（AOT）/ `--blazor-probe` / `--mode-matrix`
   （解释器轮用 **rc2b pack**）/ `--a11y-probe` 四件同 #42。
3. **7 hap 表（kit #48 发布实测；`SHA256SUMS` 18 项 / 1,600 B / `a05caba0…`）**：`hello-maui-app.hap`
   **22,334,997 / `b6bcf31a…`**（AOT）、`…-unsigned` **22,037,460 / `6a00cf66…`**、`…-permissions`
   **22,334,997 / `cd52ed56…`**、`…-api20` **22,334,996 / `9fad72f1…`**、`…-api20-permissions`
   **22,334,997 / `925d19df…`**、Blazor 默认 **27,218,497 / `036d7586…`**（未签名）、
   `-nocsp` **27,218,194 / `35413731…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`）。
   整包 tar **67,735,148 / `5c22704f…`**、树 `6b2b493c…`、sidecar `1c51cdbc…`；bundle
   `openharmony-workload-1.0.0-preview.28.tar.gz` **73,053,084 / `3b62cee2…`**（三处同步；dist sums
   `e8a37c40…`（212 B）；sdkrc2 合并 sums 1,960 B / `52425c89…`；sdk-ohos 锚 **`767c03ee71`**，
   `WORKLOAD_BUNDLE_SHA256` 27c54c62 → 3b62cee2）；**解释器 pack rc2b**（asset 606999003）、
   **`-struct1` AOT pack**（asset 607541145）与 **Crossgen2 rc.2 pack**（43,792,647 / `6bb8a375…`）保持；
   **预签已刷新（#48 件：asset 612061141 / 612062470）**；发布已完成：kit tar/边车两处（dtk **612050964** /
   latest **612052355**；asset 612050964/612052087、612052355/612053759）+ bundle 三处（preview.28
   612040629/612045359、latest 612045920/612048976、sdkrc2 612049215/612050659）；四条 release body 含
   `## Integrity (kit #48)`；by-id 抽验 0 FAIL + 零改动清单（dtk 44 资产 2 changed、latest 4 全 changed、
   sdkrc2 17 资产 2 changed）见 release。重签/重打包后必变，以 release 与随包校验为准；有 harmony flavor /
   HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#47）。
4. 离线证据（供复核）：套件 **599/601 floor 581**、像素 PASS（43）、导出 **151/151**、壳 abc
   **375,268/24,324**（四包一致 + provenance `61b1bfb2`）、host **`319db8e5`**/UND 242、`build-arkts-shell`
   188/0、`verify-kit` 129/0、packs/repo-hygiene/tasks（make-device-test-kit 37/0 复跑）；selftests 全绿（细节 reg-kit48/selftest-*.log）；
   #48 设备证据见 reg-kit48 + `cg2-r2r/`、`aot-startup/`、`fps48/`；#47 见 scratch `fix-a11yflyout/`；
   #46 见 `interp-draw2/`、`fix-a11ybtn/`；#45 见 `autodisconnect/`、`interp-render/`；#42 证据见
   `2026-10-03-ohos-tester-handoff-kit42.md` §4。

## 7. 风险 / 未验证（诚实清单）

- **R2R 边界（CG2-R2R）**：单设备 n=3 冷启（pre-fix 窗口）；+11 MB 文件体积仍在（AMS→Main 或有 ~0.1 s 级差，未分离）；
  Crossgen2 包未本机重编（复用 rc.2 主线 CI 字节，已按官方 SHA256SUMS + release digest 双向核对）；R2R 只用于 JIT，
  interp 抑制（FIXRR）与 runtime 隐式行为同效；release 域 JIT 仍受 ACL/发布 Profile 限制。
- **AOT-STARTUP 边界**：AOT 基线/优化非同轮交替（±20 ms 级漂移）；覆盖层零成本仅由首用日志与冒烟覆盖，
  未做长时 soak；JIT 死锁由 surface 重放跳过修复（`hidumper -e` 记录），其他重入路径未穷举。
- **FPS48 边界**：单设备/共享桌面；抑制源是遮挡-可见性还是双渲染器仲裁未从 RS 投票 dump 直接证实；
  记录中均匀 20.8 ms（n=240）与 30/60 混叠（均值同≈48）两形态未归一；投票常驻（idle 动态撤票为后续项）。
- **MULTIWINDOW-S 边界**：`freeWindowModeChange` 与 split 真形态、手机域未测（S 项按设计仅形态响应）；
  M（应用内子窗）/L（真 OpenWindow 多窗）按预研排期（`2026-10-05-ohos-multiwindow-prestudy.md` §3/§5）；
  平台限制 E2 现记「S 部分落地、M/L 需外部」（`2026-10-05-ohos-platform-limitations.md`）。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递（P2c 本机产物已可验；自签包仍走显式 want）；
  ②镜像分支 `m-web-mirror d47f1fcb3b` 未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1`
  绕过未定位；④stock JIT 长跑/后台唤醒未覆盖（JIT 现非默认形态）；⑤解释器混合模式（`interp.txt=1|2`）保留默认。
- **AOT 默认边界**：JIT/解释器均需动态码；release/生产域请走 AOT 或申请 ACL
  （`ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）；手机只发 AOT。**发布域实测（2026-10-04）**：
  自签 release×AOT 正常；release×JIT `coreclr_initialize` 后 ~44 ms 崩（需华为发布 Profile + ACL/JIT 豁免后复验）；
  覆盖装先卸载（`9568286`）、过期 p7b=`9568329`（`2026-10-04-ohos-release-domain-and-pidloss.md`）。
- **动态槽边界**：热对 [0,1] 常驻；空闲 >2 不养 ArkWeb 引擎/文档（重建只付一次组件+加载，无定时器）；容量下调按
  suspend 抢占超容量 claim（旧 2 槽壳安全降级）；env 不可按应用注入。
- **解释器口径**：rc2b pack 只配 rc.2 kit hap + #42+ 宿主；旧 rc.1 托管 CoreLib 测试件会 QCall ABI NULL 崩（测试件问题）。
- **AOT pack 结构性缺陷（已修复入源）**：`c1c85422715` 拆分对象库；当前资产 = **`-struct1`**（asset 607541145）。
- **ICU/InvariantGlobalization（承 #42）**：本镜像无系统 ICU——宿主自动 invariant；应用侧如遇 hosting FailFast 可参考。
- **hilog 缓冲/状态伪影**：512K 环噪声大时 ≈4–5 s；`dotnet-status.txt`/轮询可能含上一轮残留行——以时序内状态为准；
  临时 `hilog -G 16M` 复核后请还原 512K。
- **门禁（本轮已跑）**：交互 599/601 floor 581、像素 PASS（43 PASS / 0 FAIL）、导出 151/151、preflight OK
  （ridgraph 20 / packs 25 / hap-targets 79 / tasks 9 / repo-hygiene 25）、host 151/151，CI 5/5 @ `c42cfa43`
  （interaction `37285859421` / pixel `37285859467` / host-export `37285859406` / ridgraph `37285859443` /
  markdownlint `37285859423`；pin `a491cdaf4b` 5/5：`37281295386`/`37281295388`/`37281295382`/`37281295354`/`37281295380`）
  + sdk `ohos-install-tests` @ `767c03ee71` run `37286847476`；runtime manifest 提交 `14fa34e34765` 为 docs-only
  （无 workflow run）。
