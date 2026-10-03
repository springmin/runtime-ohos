# 测试方交接：kit #42、JIT 解锁（JITFORT + ICU invariant → 三路径首帧）+ 解释器 rc2b + FIX-SLICERACE（2026-10-03）

> 日期口径：文件名按撰写日；**kit #42 发布实测（release「## Integrity（kit #42）」；发布已完成，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **376,256,128 B / `ea4e3b58…`**、树
> **`13f3a086…`**、sidecar **`878d05a1…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `9ce72b56…`**
> （#41 = tar **376,036,502 B / `bed460ae…`** 对照）。重签/重打包后哈希必变；CI run id 见 §7。
> 构建基线（rc.2 线，同 #34–#41）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（承 #36；结构修复已入源）**：修正版 `-r2`（28,904,657 / `542058cf…`，asset 601289590）保持；
> **结构性修复 `c1c85422715`（`FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分对象库）已入 runtime 源**——静态 `.a`
> 保留 dlopen shim、共享 `.so` 仍静态链 OpenSSL，sdk 构建在布局与 nupkg 两处校验 shim，**后续 runtime pack
> 无需再 `-r2` 重打包**。
> **预签未刷新（明确）**：本波未重签预签件；dtk 上的 `preSigned-haps.tar.gz` 仍是 **kit #41 件**
> （376,684,381 / `2075650a…`，asset 606183753；sidecar `4198a3ec…`/606192909，指向 #41 内容）——**#42 内容
> 请用 kit tar，或回传 UDID 代签 #42 预签件**。
> **在途/外部（明确）**：AGC App Linking 登记 + 真机 https 投递；镜像扩展分支 `m-web-mirror d47f1fcb3b`
> 尚未并入 `feature/openharmony`；rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；stock JIT 长跑/
> 后台唤醒未覆盖——相关项登记「未测（在途）」不判失败。

> 结论先行：kit #42 = **kit #41 + 三路径首帧 + 一大批收口**：①**JIT 解锁**（WX-HOST-PRCTL）：宿主在两条启动路径
> 共用处、hostfxr 初始化前调 `prctl(0x6a6974)`（`PR_SET_JITFORT`，默认开；NDK 无定义用字面量；失败不致命、保持
> xwe=0 路径并记录 `OHOS_DOTNET jitfort: rc= errno= state=`；逃生口 `DOTNET_OHOS_NO_JITFORT=1`；`runtime-mode=aot`
> 跳过）；无系统 ICU 镜像自动导出 `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`（`dlopen("libicuuc.so")` 探测，
> `DOTNET_OHOS_ICU=0|1` 可覆盖，状态行 `OHOS_DOTNET globalization: invariant= icu= source=`）→ **JIT 首帧**
> （设备：`jitfort rc=0 errno=0 state=off` + 探针 `1=OK 2=OK` + CoreLib 通过 + MAUI 初始化 + `canvas presented`
> 4–8 次 + UI 截图；逃生口/DOTNET_OHOS_NO_JITFORT 回退路径保留）。②**解释器 rc2b 首帧**：INTERP-NULL 根因 =
> **rc.1 托管 CoreLib × rc.2 原生 QCall ABI 错配**（`#132420` 起 QCall 经隐藏末参传异常状态；rc.2 CoreLib 调 4 参、
> rc.1 测试件调 3 参 → `*qcallError=0` 写 NULL），**非 interp 缺陷**；用 rc.2 kit hap + rc2b pack（含 WX-PATCH2）
> 重签后 → **`canvas presented (2090x1324)`**（九次启动无 `SIGSEGV`/无 CoreLib 加载失败）；新资产
> **`ohos-interpreter-pack-rc2b.tar.gz`**（2,410,595 / `5974430509…`，asset 606999003；README 606999004；
> sidecar 606999001；`libcoreclr` `4b30a4c1…`/`e150558a…` + `libclrinterpreter` `11fc5052…`/`3e4b4d10…`）。
> ③**FIX-SLICERACE**（maui `549967f2f0` + ow `f6cbbe8`）：MAUI 切片 handler 并发设置竞争（`Element.SetHandler`
> check-then-set 非重入；运行时 launch 线程 × ArkTS shell 线程并发触树；JIT 慢启动放大）→ 可重入 `s_connectSync`
> 串行化 + 宿主 `_sync`/`_ready` 门闩；设备 **8/8 JIT 轮 PASS**（`race=0 pvnull=0 conc=0 unhandled=0`、首帧
> 767–814、36 s 存活）；套件 +3。④收口：**L6**（截图 JPEG/标题心跳；壳 abc **356,468（`dd04dad1…`）**；新导出
> `ohos_host_screenshot_format` → 151/151）、**LEGACY Toolbar**（图标/Order/Priority/禁用/溢出下拉闭合；套件 +6）、
> **SAMPLE-FIX**（`blzProbe` 定义 → `dotnet-ref ok`；demo `#app` 恢复挂载（不是 modules.json 缺失，是 `0e0129e`
> 删了控件）；`dotnet.zip` 258 项）、**WX-PATCH2**（双映射预检 + 写屏障 Commit 检查，含于 rc2b pack）、
> **P2c `skills[].uris`**（打包期声明 browsable/viewData + https uri + domainVerify）、**镜像扩展**
> （`m-web-mirror d47f1fcb3b`：workload-only 重打包也镜像进 `-openharmony` 线 + 合并 SHA256SUMS 重写）、
> **AOT pack 结构修复**（入源，见上）。**宿主全量重建 297,888（`08abe185…`，导出 151/151、UND 240）**。
> **FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount/FIX-JSCALL/MULTI-OVERLAY-FULL/DEVCOMPAT 全量保留。
> 壳 abc 356,468（`dd04dad1…`）/ headless 24,324（未变）、宿主 297,888（`08abe185…`）、导出 151/151、
> 套件 578 checks / 580 total / floor 560**。判定点见 §2；承接 #41/#40/#39/#38/#37/#36/#35/#34/#33 的判定点
> **继续有效**，本文只覆盖 #42 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（JIT —— #42 起 JITFORT 默认解锁，首选路径）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 探针（B2 走 MAUI WebView 内嵌 WASM；判定继续有效）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段用 AOT 资产；解释器轮改用 rc2b pack —— #42 首帧）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3.tar.gz --interp-pack ./ohos-interpreter-pack-rc2b.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；**本波未刷新——仍 #41 件**）

`device-test-kit` release 的并列预签资产 **`preSigned-haps.tar.gz`** 当前仍是 **kit #41 件**（2026-10-03 刷新；
asset **606183753**，**376,684,381 B / `2075650a…`**；sidecar 88 B / `4198a3ec…`，asset **606192909**；解包树
`9923ad22…`；**内容 = kit #41 的 7 hap**）。按 tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`
预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**；非 tester UDID 设备报 `9568344`。**#42 内容请用
`device-test-kit.tar.gz`，或回传 UDID 代签 #42 预签件**；预签包是并列附加件，完整一轮仍用 kit tar。

## 1. kit #42 相对 #41 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **JIT 解锁（WX-HOST-PRCTL）** | 此前 enforcing 镜像上 JIT 受 W^X 限制（RWX/mprotect 被拒 → `SEGV_ACCERR`）；本版 = 宿主 `prctl(0x6a6974)`（JITFORT）默认开（`OhosHostApplyExecMemoryPolicy` 内、两条启动路径共用、hostfxr 前；`runtime-mode=aot` 跳过；失败不致命），且无系统 ICU 镜像自动 invariant（`libicuuc.so` 探测 → `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`；JIT/解释器否则启动即 FailFast）。设备（HAD-W32 7.0.0.111，kit DeviceCompat 件 + 新宿主重签）：`jitfort rc=0 errno=0 state=off`、探针 `1=OK 2=OK`、CoreLib 通过、MAUI 初始化、**`canvas presented`（4–8 次）+ UI 截图**；AOT 对照 `jitfort: skipped` 不受影响 | JIT 主包启动出画（首帧）；`OHOS_DOTNET jitfort:`/`globalization:` 状态行；探针 `1=OK 2=OK` |
| 1.2 | **解释器 rc2b（首帧）** | 现象链：INTERP-FIX（8 MB 栈 + 关屏障）后 interp 存活但 canvas=0（INTERP-FRAME 定位到 `CoreLib 加载 0x800701E7`，并更正「411 行 canvas presented」为状态文件伪影）；JITFORT 解锁后 `0x800701E7` 消失但出现 `SIGSEGV(NULL)@coreclr_initialize+1064`（INTERP-NULL）。根因 = **rc.1 托管 CoreLib × rc.2 原生 QCall ABI 错配**（隐藏末参 `*qcallError`；stale 测试件 3 参 vs rc.2 CoreLib 4 参）——**非 pack/interp 缺陷**。修复 = 按 rc.2 kit hap 重组（rc2b pack 两库 + `runtime-mode.txt=interp` + JITFORT 宿主）并重签 → **首帧达成**（`canvas presented (2090x1324)`；九次启动无 `SIGSEGV`/无 CoreLib 失败；其余轮次为 handler 竞争 `SIGABRT`，即 #42 的 FIX-SLICERACE） | rc2b pack + rc.2 kit hap → `canvas presented`；`summary interp_mode=3(file)`；maps 含 `libclrinterpreter.so` |
| 1.3 | **FIX-SLICERACE（handler 并发设置竞争）** | 根因：`Run` 的 `ConnectTree`（app 线程）与 `SurfaceChanged/Frame → Arrange → ConnectTree`（shell 线程）并发；`Element.SetHandler` check-then-set 非重入 → `Handler is already being set elsewhere` + `PlatformView cannot be null here` + 集合并发腐坏（JIT 慢启动放大；修复前 7 次启动 5 pid 命中）。修复 = 可重入串行化（`s_connectSync`，核心下移 `ConnectCore/ConnectTreeCore`，二连幂等返回）+ 宿主 `_sync` 串行化触树入口 + `_ready` 门闩（surface/frame 在 Run 连接完成前不触树）；纯串行化/幂等、无语义改变；套件 +3（connect storm/host storm/源码 pin）。设备：**8 轮（4×inv → 2×plain → 重装 2×inv）8/8 PASS**，每轮 `race=0 pvnull=0 conc=0 unhandled=0 jitfort=1`、首帧 767–814、36 s 存活 | JIT 冷启/重启循环：race=0 + 首帧；无 `Handler is already being set elsewhere` |
| 1.4 | **L6 / LEGACY / SAMPLE-FIX / WX-PATCH2 / P2c / 镜像 / AOT 结构修复** | **L6**：截图格式 JPEG + 标题心跳 → 壳 abc **356,468（`dd04dad1…`）**、导出 +1（`ohos_host_screenshot_format`）至 **151/151**。**LEGACY**：Core Toolbar 闭合（`OpenHarmonyToolbarItem` 图标/文字/禁用；`OpenHarmonyToolbarMirror` 按 Order/Priority 停靠 + Secondary 溢出下拉（内容前 hit-test、禁用不激活）；Shell 标题栏事件驱动重建）；legacy compatibility renderers 判定非缺口（`e55e1e27bb` 有意移除）；套件 +6。**SAMPLE-FIX**：`blzProbe` 定义（`dotnet-ref ok`）；demo `#app` 恢复按需 BlazorWebView（更正旧结论：`modules.json` 一直在载荷里，缺的是 `0e0129e` 移除的控件）+ `hybridwebview.js` pack 期入载荷；`dotnet.zip` 257→258。**WX-PATCH2**（coreclr 4 文件）：双映射预检（memfd RW/none/RX 预检失败即回退并记录）+ `Commit(...,true)` 返回值检查/关副本回退；含于 rc2b pack。**P2c**：`skills[].uris` 打包期声明（browsable/viewData + 每 host https uri + `domainVerify`；home skill 保留；非法 host fail；未设时字节不变）。**镜像**：`m-web-mirror d47f1fcb3b`（workload-only 重打包进 `-openharmony` 线 + merged sums 两行重写；dispatch 冒烟三 job 全绿；未并入默认分支）。**AOT 结构修复**：见页首 | L6 截图 JPEG；Toolbar 契约；`blzProbe`/`#app`；WX-PATCH2 无 `ACCERR`；`module.json` skills 产物；镜像 workflow 绿 |
| 1.5 | **门禁/指纹/7 hap/预签** | 交互套件 **578 checks / 580 total / floor 560**（FIX-SLICERACE +3；累计 563→578、floor 543→560）、像素 `PIXEL ASSERTIONS PASSED`（无 `Known`）、宿主导出契约 **151/151**、host **UND 240**/DT_NEEDED 5/denylist 0；**新壳 abc 356,468（`dd04dad1…`）/ headless 24,324（`798b2477…`）**（`Index.ets 312,745/b1037b04`、provenance `9d3d9833…`）、hap 内宿主 **297,888（`08abe185…`）**、payload Hosting **71,680（`40caff06…`）**；`verify-kit` 期望 **15 `.so` / 258 zip / abc 356468/24324**（脚本 69,717 / `0995a406…`）；**7 hap 重签**（MAUI 5 + Blazor 默认/`-nocsp`）：见表 §6.3；**预签未刷新（§0b）** | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**；套件自报行 `[suite] checks=578 total=580 floor=560 assert=True` |
| 1.6 | **在途/外部项（明确）** | ①AGC App Linking 登记 + 真机 https 投递（P2c 本机产物已验）；②镜像分支 `m-web-mirror d47f1fcb3b` 未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；④stock JIT 长跑/后台唤醒未覆盖（本轮为 8/8 短轮 + 首帧）；⑤解释器混合模式（`interp.txt=1|2`）保留默认未覆盖 | 登记「未测（在途）」，**不判失败** |

> 尺寸预算：以 release 资产表为准（#41 = 376,036,502 B；#42 = 376,256,128 B，delta = 新壳/宿主/切片重建 + 7 hap）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **JIT 首帧（主判点 1）** | 装默认 kit 主 hap（DeviceCompat）→ 冷启 | `OHOS_DOTNET jitfort: rc=0 errno=0 state=off` + `globalization: invariant=1 icu=0 source=…` + 探针 `1=OK 2=OK` + **`canvas presented`（4–8）+ UI 出画** | 截图 + hilog/status |
| **AOT 首帧（主判点 2）** | 装 AOT 资产（重签）→ 启动 | `aot=1` + `canvas presented`（回归不变；`jitfort: skipped runtime-mode=aot`） | 截图 + hilog |
| **解释器首帧（主判点 3）** | rc2b pack 换入 + rc.2 kit hap 重签 + `interp.txt=3` | **`canvas presented`（2090x1324）**、无 `cppcrash`、无 `SIGSEGV(NULL)@coreclr_initialize`；`summary interp_mode=3(file)` | 截图 + faultlog + maps |
| **FIX-SLICERACE** | JIT 冷启/force-stop/再启（8 轮） | `race=0 pvnull=0 conc=0 unhandled=0 jitfort=1` + 首帧；无 `Handler is already being set elsewhere` | 每轮 hilog + 截图 |
| **L6** | 截图请求（默认/JPEG） | 截图按 JPEG 落盘；标题心跳正常 | 截图文件 + hilog |
| **LEGACY Toolbar** | NavigationPage/Shell 标题栏工具栏 | 图标（File/Font）+ 文字 + Order/Priority + 禁用暗显 + Secondary 溢出下拉（禁用不激活） | 截图 + 激活结果 |
| **SAMPLE-FIX** | razor 页 probe / demo `#app` | `probe: dotnet-ref ok`；计数 0→1→2；demo `#app` 挂载（AttachPage/AttachToDocument/渲染） | 截图 + hilog |
| **P2c `skills[].uris`** | 设 `OpenHarmonyAppLinkHosts` 构建 | `module.json` 含 browsable/viewData + https uri + domainVerify（负例拒绝） | `module.json` 摘录 |
| **套件基座** | 有源码测试者跑 `test/maui-platform-verify` | `[suite] checks=578 total=580 floor=560 assert=True`；导出 151/151 | 终端输出 |
| **承 #41：MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX** | 双 Hybrid/抢占/恢复；enforcing 装包；8 MB 栈 | 同 #41 期望（z-order 重叠已由 ZORDER-NAV 取 97.2% 证据） | 截图 + hilog |
| **承 #40/#39/#38/#37/#36/#35：FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10** | 见 `2026-10-03-ohos-tester-handoff-kit41.md`/#40/#36 §2 | 同前各期望；套件自报行 `578/floor 560` | 截图 + hilog + `dotnet-status.txt` |
| **承 #34/#33：rc.2 自述 + W6/W7/W8 + Blazor A/B + 主体** | 包内自述；各卡 | SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；逐项同 #34/#33 | 自述原文 + 截图 + `--a11y-probe` |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#41）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.2.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（承 #36；结构修复入源）**：当前用修正版 `-r2`（asset 601289590）；`c1c85422715` 起
   `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分对象库（静态 `.a` 保 shim、共享 `.so` 静态 OpenSSL；sdk 布局+nupkg
   两处校验），后续 pack 无需 `-r2` 重打包；最小复现见 `2026-09-30-rc2-aotpack-openssl-shim-fix.md`。
3. **解释器 pack（#42 更新）**：用 **`ohos-interpreter-pack-rc2b.tar.gz`**（2,410,595 / `5974430509…`，asset 606999003）
   + **rc.2 kit hap**（重签）+ #42 宿主；**勿用 rc.1 托管 CoreLib 的旧测试件**（QCall ABI 错配会 NULL 崩）；
   `interp.txt=1|2` 混合模式保留默认；判定见 `2026-10-03-ohos-interp-null.md`。
4. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`（CoreLib `417ab220532` 起）；
   enforcing 镜像直接装默认 kit 件（DEVCOMPAT-DEFAULT）。
5. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 上架后换 pin、删 feed step（承 #34 注记）。
6. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（本文随附；kit #42 manifest 刷新
   **`ed504b85a46`**）；maui = **`549967f2f0`**（FIX-SLICERACE 切片；父 `96034e2acf` L6 / `1926cf68b6` SAMPLE-FIX /
   `7064bb8c1c` LEGACY / `07423dfe93` MULTI-OVERLAY-FULL）；ohos-workload master **`740980d`**（验证器期望
   356,468/258；其上 `f80f0d2` pin / `65be592` merge / `f6cbbe8` FIX-SLICERACE / `3a4bcbf` WX-HOST-PRCTL /
   `e5d1d62` L6）；sdk 锚 **`35101fe1f5`**（bundle 锚 c98375a5 → **570c0821**；`-r2`/interp pack 引用保留；
   镜像扩展分支 `m-web-mirror d47f1fcb3b`；SDK CI run `37096319182`）；aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#41）：本机桌面 HAD-W32 / OpenHarmony 7.0.0.111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`
  （UDID `1BCE13C8…AEA0`）；SDK `sign-hap.sh` 自签；**三路径均可达首帧**（JITFORT/JIT、AOT、interp rc2b）。
- **#42 本轮证据**（scratch）：WX-HOST-PRCTL `wx-prctl/`（jitfort 状态/探针/canvas/UI 截图 + interp 旧件 NULL +
  AOT 回归）；INTERP-NULL `fix-interp-null/`（NULL 符号化、CoreLib ABI 对照、rc2b 九启 + 首帧）；FIX-SLICERACE
  `fix-slicerace/`（8 轮 device 帧 3120×2080 + hilog）；SAMPLE-FIX `sample-fix/`（`dotnet-ref ok`、`#app` 链路）；
  ZORDER-NAV `zorder-nav/`（重叠 97.2% + 真实 Navigate）；LEGACY/SAMPLE/P2c 见各自文档。
- **已知（承 #34–#41）**：JIT 主包在 enforcing 镜像**已可开箱安装**（DEVCOMPAT-DEFAULT）；JIT 首帧依赖 JITFORT
  解锁（本版默认）；状态文件/轮询可能含上一轮残留行——判读以时序内状态为准。
- **本机可直接闭环**：三路径出画、race 轮询、多覆盖层、Blazor 标记、a11y/日志/截图回路；命令模板 =
  `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`（窗口竞态与 hilog 缓冲注见其 §4）。

## 5. 自签与包布局要点（测试方视角；承 #34–#41）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap**：payload-in-libs + DEVCOMPAT 重写（15 `.so` / 258 zip）；**壳 abc 356,468（`dd04dad1…`）**、
  宿主 **297,888（`08abe185…`）**、headless 24,324；新 hap sha 以 release/包内 `SHA256SUMS` 为准。
- **AOT/解释器资产**：均为独立资产，不在 kit tar 内；AOT 用 `-r2`（结构修复后无需重打）；解释器用 **rc2b** +
  **rc.2 kit hap**；安装会顶替 kit 主包，回 JIT 需重装 kit hap。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #42）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准；
  **预签件仍 #41 内容**——#42 预签请回传 UDID 代签。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs（**15 `.so` / 258 zip**）/宿主依赖（UND 240）；abc 期望 = **356,468（`dd04dad1…`）/24,324
   （`798b2477…`）**，脚本哈希 69,717 / `0995a406…` 以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮（JIT）/ `--blazor-probe` / `--mode-matrix`（解释器轮用
   **rc2b pack**）/ `--a11y-probe` 四件同 #41。
3. **7 hap 表（kit #42 发布实测；`SHA256SUMS` 17 项 / 1,517 B / `9ce72b56…`）**：`hello-maui-app.hap`
   **134,191,673 / `f94cbc0f…`**、`…-unsigned` **131,635,004 / `5a0a908b…`**、`…-permissions`
   **134,191,645 / `2b91a1a4…`**、`…-api20` **134,191,733 / `2180bc83…`**、`…-api20-permissions`
   **134,191,691 / `acc3f684…`**、Blazor 默认 **27,216,958 / `2b64bc5a…`**（own abc 21,200 B、site 213 files、
   未签名）、`-nocsp` **27,216,659 / `ec224092…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`；
   own abc 21,016 B）。整包 tar **376,256,128 / `ea4e3b58…`**、树 `13f3a086…`、sidecar `878d05a1…`；bundle
   `openharmony-workload-1.0.0-preview.28.tar.gz` **73,047,352 / `570c0821…`**（三处同步 versioned `607133062` /
   latest `607133915` / sdkrc2 `607134885`；dist sums 212 B / `b72a0e81…`；sdkrc2 合并 sums 1,960 B / `65bd6947…`；
   sdk-ohos 锚 **`35101fe1f5`**，`WORKLOAD_BUNDLE_SHA256` c98375a5 → 570c0821）；**解释器 pack rc2b**
   （asset 606999003）；**预签未刷新（仍 #41 件 606183753/606192909）**；发布已完成：kit tar/边车两处
   （dtk **392356147** / latest **392077166**；tar/边车 asset **607136666**/**607139045**，latest 同件
   **607139215**/**607141763**）+ bundle 三处；四条 release body 含 `## Integrity (kit #42)`（含 interp pack 引用）；
   by-id 抽验 0 FAIL + 公开直连抽验（dtk 边车 `878d05a1…`、preview.28 sums `b72a0e81…` 一致）。重签/重打包后必变，
   以 release 与随包校验为准；有 harmony flavor / HMS 的测试者请附壳构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#41）。
4. 离线证据（供复核）：套件 **578/580 floor 560**、像素 PASS（Known 清零）、导出 **151/151**、壳 abc
   **356,468/24,324**（四包一致 + provenance）、host **`08abe185`**/UND 240、`build-arkts-shell 185/0`、
   `verify-kit 108/0`、packs/repo-hygiene 25/0、tasks 9/0；#42 设备证据见 scratch `wx-prctl/`、`fix-interp-null/`、
   `fix-slicerace/`、`sample-fix/`、`zorder-nav/` 与 `docs/plans/2026-10-03-ohos-jitfort-enable.md`、`…interp-null.md`、
   `…handler-race.md`、`…sample-fix.md`、`…legacy-toolbar.md`、`…wx-patch2-fallback.md`、`…m-web-mirror.md`、
   `…zorder-nav-device.md`、`…maui-final-audit.md`；#41 证据见 `docs/plans/2026-10-03-ohos-tester-handoff-kit41.md` §4。

## 7. 风险 / 未验证（诚实清单）

- **本轮三路径首帧的 tester 机复核仍待做**：交付方在本机闭环（JITFORT/JIT、AOT、interp rc2b）；不同窗口形态与
  共享桌面环境请按 §2 同法复测；无入口按「未测」登记，不判失败。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递（P2c 本机产物已可验；自签包仍走显式 want）；
  ②镜像分支 `m-web-mirror d47f1fcb3b` 未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1`
  绕过未定位；④stock JIT 长跑/后台唤醒未覆盖（8/8 短轮 + 首帧为本轮证据）；⑤解释器混合模式（`interp.txt=1|2`）保留默认；
  ⑥另一代理准备的 pin 在超时后由本波代落盘（内容逐字节取自其工作区）——相关项登记「未测（在途）」。
- **JIT 解锁边界**：JITFORT 为平台接口（`prctl(0x6a6974)`；MAP_JIT 非解锁通道，WX-TOKENS 矩阵已验证）；失败不致命
  （保持 xwe=0 路径并记录）；`runtime-mode=aot` 跳过；无 ICU 镜像自动 invariant（应用预置 Invariant 兼容）。
- **解释器口径**：rc2b pack 只配 rc.2 kit hap + #42 宿主；旧 rc.1 托管 CoreLib 测试件会 QCall ABI NULL 崩（测试件问题）。
- **AOT pack 结构性缺陷（已修复入源）**：`c1c85422715` 拆分对象库；当前资产仍以 `-r2` 为准，后续 pack 无需重打。
- **ICU/InvariantGlobalization**：本镜像无系统 ICU——宿主自动 invariant（#42）；应用侧如遇 hosting FailFast 可参考。
- **hilog 缓冲/状态伪影**：512K 环噪声大时 ≈4–5 s；`dotnet-status.txt`/轮询可能含上一轮残留行（INTERP-FRAME 曾记录
  411 行同刻伪影）——以时序内状态为准。
- **门禁（本轮已跑）**：交互 578/580 floor 560（+3 fix pin）、像素 PASS（无 `Known(...)`）、导出 151/151、
  包内 `verify-kit.sh` 0 FAIL/0 WARN（15 `.so`/258 zip/abc 356468/24324）、`ohos-workload` master **`740980d`**；
  CI **5/5** @ `740980d`（interaction `37096467502` / pixel `37096467496` / host-export `37096467506` /
  ridgraph `37096467507` / markdownlint `37096467538`）、sdk `ohos-install-tests` @ `35101fe1f5` run
  `37096319182`（installer 43/43 · hostfeed 10/10 · codesign-filewrites 5/5）。
- 本次构建基线 = **rc.2 线**（SDK `.112` / workload `preview.28` / MAUI `rc2.26478.12`）；应用侧构建请同步该线
  （`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5；rc.1 回滚路径保留）。
