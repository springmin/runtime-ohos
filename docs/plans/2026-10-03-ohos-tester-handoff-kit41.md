# 测试方交接：kit #41、MULTI-OVERLAY-FULL（LRU 槽池 + per-slot hybrid invoke）+ DEVCOMPAT-DEFAULT + INTERP-FIX（2026-10-03）

> 日期口径：文件名按撰写日；**kit #41 发布实测（release「## Integrity（kit #41）」；发布已完成，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **376,036,502 B / `bed460ae…`**、树
> **`7ce1946e…`**、sidecar **`2a95e764…`**（89 B）、`SHA256SUMS` **17 项 / 1,517 B / `421a819c…`**
> （#40 = tar **375,836,470 B / `31ab8732…`** 对照）。重签/重打包后哈希必变；CI run id 见 §7。
> 构建基线（rc.2 线，同 #34–#40）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（承 #36，保持）**：rc.2 NativeAOT OpenHarmony pack 用修正版资产
> **`Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.2.26451.112-r2.nupkg`**
> （28,904,657 B / `542058cf…`，asset 601289590）；**rc.1 钉保持撤销**。
> **预签刷新（#41）**：`preSigned-haps.tar.gz` 已刷新至 kit #41（tester UDID）——**376,684,381 B / `2075650a…`**
> （asset **606183753**；sidecar 88 B / `4198a3ec…`，asset **606192909**；树 `9923ad22…`；7/7 ZIP 条目与 kit 原件
> 逐字节一致）；**#40 旧件（`193f5fb1…`/asset 605502130）已被显式替换、旧哈希作废**。
> **在途/后续（明确）**：z-order 重叠控件真机截图在途；hello-maui-app 的 Blazor `#app` 因样例缺 `modules.json`
> 未挂载；stock JIT 路径未单独复测；rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位——相关项登记
> 「未测（在途）」不判失败。

> 结论先行：kit #41 = **kit #40 + 三大彻底修复 + 预签刷新**：①**MULTI-OVERLAY-FULL**（maui `07423dfe93` +
> ow `0e0129e`）：双槽 ArkWeb 覆盖层池 + **owner 感知 LRU 抢占/恢复**（`IOpenHarmonyOverlaySlotOwner`：
> 池满时优先抢未 engaged、其后最久未用；被抢 handler suspend 且 PlatformArrange 不再自动抢回——只有显式使用
> 才 `Acquire` 并重放 load/attach）、**per-slot hybrid serve/message/invoke 通道**（`requestId=((slot+1)<<24)|seq`，
> 托管 `TryDecodeInvokeRequestId` 派发到持槽 handler；旧无槽 id 回退"最后注册 hybrid"）、**激活序 z-order**
> （`webZOrder[]` + `noteWebActivation`，最近激活置顶）、payload-in-libs appDir 探测修复；>2 控件按 LRU 抢占退化，
> 同页两 Hybrid 各自 invoke/消息闭环（设备 r13 证据：双 Hybrid 交互、第三控件抢占、activate 恢复重放）。
> ②**DEVCOMPAT-DEFAULT**（ow `12be59c`）：payload 逐文件码签重写**默认化**（无扩展名→`.so`/`.bin`、恰 4096 B→+4 B、
> `dotnet.zip` 回退保原字节；逃生口 `-p:OpenHarmonyHapPayloadInLibsDeviceCompat=false`）——enforcing 7.0.0.111+
> **开箱可装**（A/B：同源未重写对照包 `9568393`；本机 install bundle successfully）；kit 现 **15 `.so` / 257 zip**。
> ③**INTERP-FIX**（ow `c9916cd` + sdk `3842c25b2e`）：解释器起步崩**与 pack 无关**（stock rc.2 libcoreclr 同样复现）；
> 根因 = OHOS musl 默认 1 MB 线程栈 vs PAL 1.5 MB 探针（`EnsureStackSize` `SIGSEGV_MAPERR`）+ 写屏障页 RWX 被 HAP 域
> 拒绝且 Commit 返回值未检查（`InitThreadManager` memcpy `SEGV_ACCERR`）；修复 = 宿主 **8 MB app 线程栈** +
> `interp=3` 时 `DOTNET_UseGCWriteBarrierCopy=0`；**rc.2 重建解释器 pack** 独立
> 资产 **`ohos-interpreter-pack-rc2.tar.gz`**（2,409,070 B / `34709a94…`，asset 605924427；`libcoreclr.so` 5,130,328 /
> `fd79f2bf…` + `libclrinterpreter.so` 268,320 / `75360e65…`）；设备：新 pack 启动存活、faultlogger 0 条新 `cppcrash`、
> 15 s 窗口 411 行 `canvas presented`。**FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount/FIX-JSCALL 全量保留。
> 壳 abc 356,140（`2a90f0d7…`）/ headless 24,324（未变）、宿主 293,792（`8d67def3…`，UND 239）、导出 150/150、
> 套件 563/floor 543（+4 MULTI-OVERLAY-FULL pin）**。判定点见 §2；承接 #40/#39/#38/#37/#36/#35/#34/#33 的判定点
> **继续有效**，本文只覆盖 #41 增量与判读引用。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
# 常规一轮（同 #40：runtime_mode 键、execmem、a11y 可选）
sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60
# Blazor 探针（B2 走 MAUI WebView 内嵌 WASM；判定继续有效）
sh tester-run.sh --kit-dir ./device-test-kit --blazor-probe
# 运行时四态一键（AOT 段用本轮 AOT 资产；解释器轮改用 rc2 pack —— INTERP-FIX）
sh tester-run.sh --mode-matrix --kit-tar ./device-test-kit.tar.gz \
    --aot-haps ./aot-haps-v3.tar.gz --interp-pack ./ohos-interpreter-pack-rc2.tar.gz --capture 60
```

## 0b. 预签直装（#34 起加发资产；**已刷新至 kit #41**）

`device-test-kit` release 的并列预签资产 **`preSigned-haps.tar.gz`** 已**刷新至 kit #41**（2026-10-03；asset
**606183753**，**376,684,381 B / `2075650a…`**；sidecar `preSigned-haps.tar.gz.sha256` 88 B / `4198a3ec…`，
asset **606192909**；解包树 `9923ad22…`；包内 `preSigned-README.md` 5,502 B / `b995c131…`、`SHA256SUMS`
8 项 / 764 B / `2c3cf6c8…`；#40 旧件 asset 605502130/605534061 已被**显式替换**、旧哈希 `193f5fb1…` 作废）：
7 hap 全部按 **tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`** 预签
（7/7 ZIP 条目与 kit #41 原件逐字节一致），`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装、无需重签**
（同 bundle 换件仍先卸载）；非 tester UDID 设备报 `9568344` → 回传 UDID 重出或按包内 README 自签；预签包是
并列附加件，完整一轮仍用 `device-test-kit.tar.gz`。

## 1. kit #41 相对 #40 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **MULTI-OVERLAY-FULL（多 WebView 覆盖层共存）** | 此前单 ArkWeb：同页多 web 控件只有一个能真出画（FIX-WVP 仲裁"已注册 hybrid 时 Blazor 只武装不加载"）。本版 = **双槽覆盖层池**：壳 `webOverlay(0/1)` 两个 ArkWeb，每槽独立 controller/可见性/frame/挂起快照/JS 代理/文档标记；托管 `OpenHarmonyOverlays` 槽池（Acquire/Release/Touch + **owner 契约** `IOpenHarmonyOverlaySlotOwner`）；线协议按槽（首行 `s<slot>`、注册 JSON `slot`、eval 前缀、页事件 `s<slot>|state`、导航 `__OHNAV|s<slot>|…`；全局命令不带 tag）。**设备（r13）**：① 同页两 Hybrid 各自交互——A/B 页 `invoke: "A-echo:Echo:1"`/`"B-echo:Echo:1"` + 托管 `A raw: A-raw-ping`/`B raw: B-raw-ping`（per-slot 消息与 invoke 请求/响应/回调闭环）；② "Add web C" → "web C added (3 web controls, 2 slots)"、**A 被 LRU 抢占（空白）**、B/C 出画；③ "Activate hybrid A" → A 恢复重放出画、B 被抢、C 仍在（B 对称）；z-order 按激活序（`webZOrder`），重叠页复核在途 | 两白区同时出画（`0.0.0.1` + `0.0.0.0`）；两 Hybrid 各自 invoke/消息不串槽；第三控件 LRU 抢占；activate 恢复重放 |
| 1.2 | **DEVCOMPAT-DEFAULT（enforcing 开箱可装）** | 此前 payload-in-libs 的"无扩展名/恰 4096 B"文件在 enforcing 7.0.0.111+ 被码签拒绝（`9568393`；kit #36 记录为本机已知）。本版 = `OpenHarmonyHapPayloadInLibsDeviceCompat` **默认 true**：构建时把无扩展名 ELF→`.so`、恰 4096 B→+4 B，`dotnet.zip` 回退保原字节；构建输出新增 `device compat: enabled … (N rewrite(s))`；逃生口 `false`（原名原字节 + 告警点名）。设备（HAD-W24 7.0.0.111）：hello-app JIT 默认设置 **install bundle successfully**（2 rewrite），同源未重写对照包 `9568393`（A/B 证明）；kit 现 **15 `.so` / 257 zip 条目**（`dotnet.zip` 257 项） | 默认设置直接装 kit 主 hap（enforcing 镜像不再 `9568393`）；逃生口行为符合文档 |
| 1.3 | **INTERP-FIX（解释器起步崩修复 + rc2 pack）** | 此前 interp（`interp=3`）起步崩 `SIGSEGV_MAPERR`（`coreclr_initialize+440`，判为 pack 兼容性——**不成立**）。根因 = ①OHOS musl 默认 pthread 栈 1 MB vs CoreCLR MUSL 的 PAL 1.5 MB `_alloca` 探针（`EnsureStackSize`）；②`FEATURE_DYNAMIC_CODE_COMPILED=1` 时 `Commit(…, isExecutable=true)` 请求 RWX 被 HAP 域拒绝且返回值未检查 → 页保持 PROT_NONE → `InitThreadManager` 写屏障 memcpy `SEGV_ACCERR`（纯解释不需要该拷贝）。修复 = 宿主 **8 MB app 线程栈** + `interp=3` 注入 `DOTNET_UseGCWriteBarrierCopy=0`；**rc.2 重建 interp 产物**并重打卡 `ohos-interpreter-pack-rc2.tar.gz`（2,409,070 / `34709a94…`；asset 605924427）。设备：新 pack + 新宿主 → `install bundle successfully`、启动存活、faultlogger **0 条新 `cppcrash`**、15 s 窗口 411 行 `canvas presented`（含 media self-test/ArkWeb 首帧）；旧 rc.1 pack + 新宿主亦存活（变量隔离证明修复在宿主） | `--mode-matrix` Run C（rc2 pack）存活出画、无新 `cppcrash`；maps 含 `libclrinterpreter.so`；`summary interp_mode=3(file)` |
| 1.4 | **门禁/指纹/7 hap/预签** | 交互套件 **563/floor 543**（+4 MULTI-OVERLAY-FULL：槽池/LRU、invoke id、双覆盖层壳、切片接线；`verifyCheckTotal` 555→563、floor 535→543，只增不降）、像素 `PIXEL ASSERTIONS PASSED`（无 `Known`）、宿主导出契约 **150/150**、host **UND 239**/DT_NEEDED 5/denylist 0；**新壳 abc 356,140（`2a90f0d7…`）/ headless 24,324（`798b2477…`）**（`Index.ets 312,260/3afcc8cf`、provenance `7df0f263…`）、hap 内宿主 **293,792（`8d67def3…`）**、payload Hosting **71,680（`1c05d261…`）**；`verify-kit` 期望 **15 `.so` / 257 zip / abc 356140/24324**（脚本 69,717 / `efa27d31…`）；**7 hap 重签**（MAUI 5 + Blazor 默认/`-nocsp`；站点 `dotnet.bx7u3hgxop.js`）：见表 §6.3；**预签刷新至 #41**（§0b） | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**；套件自报行 `[suite] checks=563 total=563 floor=543 assert=True` |
| 1.5 | **在途/后续项（明确）** | ①z-order 已实现并有断言/编译实测，但真机采用纵向不重叠布局、**重叠控件动态置顶截图在途**；②hello-maui-app 的 Blazor `#app`（BlazorCounter）因样例缺 `modules.json` 未挂载（razor 样例已挂载）；③stock JIT 路径未单独复测（8 MB 栈预期修复 `+440`；JIT 仍受 RWX 拒绝限制）；④匿名可执行映射未在 app 内枚举；⑤rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；⑥DEVCOMPAT 4096 B 规则仅本镜像实测（7.0.0.105 未复测） | 登记「未测（在途）」，**不判失败** |

> 尺寸预算：以 release 资产表为准（#40 = 375,836,470 B；#41 = 376,036,502 B，delta = 新壳/宿主/切片重建 + 7 hap）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **双覆盖层出画（主判点 1）** | 打开含两个 web 控件的页 | 两白区同时出画（上 hybrid `origin https://0.0.0.1/ | readyState: complete`，下 Blazor `https://0.0.0.0/`）；hilog `web serve` 与 `web page (slot 0/1)` | 截图 + hilog |
| **per-slot invoke/消息（主判点 1b）** | 两 Hybrid 页内按钮/echo | A/B 各自 `invoke: "X-echo:Echo:1"` + 托管 `X raw: X-raw-ping`（互不串槽） | 截图 + hilog |
| **LRU 抢占/恢复（主判点 1c）** | "Add web C" → "Activate hybrid A"（再试 B） | C 出现后 A 空白、B/C 出画；Activate A → A 恢复、B 空白、C 仍在；B 对称 | 截图 r13-* + hilog |
| **DEVCOMPAT（主判点 2）** | enforcing 7.0.0.111+ 默认设置装主 hap | **开箱可装**（无 `9568393`）；构建日志 `device compat: enabled … (N rewrite(s))` | 安装 log + 构建 log |
| **INTERP-FIX（主判点 3）** | `--mode-matrix` Run C（rc2 pack） | 存活出画、0 条新 `cppcrash`、`canvas presented`；maps 含 `libclrinterpreter.so`；`summary interp_mode=3(file)` | faultlog + hilog + maps |
| **套件基座** | 有源码测试者跑 `test/maui-platform-verify` | `[suite] checks=563 total=563 floor=543 assert=True`；4 条新 pin 绿；导出 150/150 | 终端输出 |
| **承 #40：FIX-JSCALL** | razor 页点 "Blazor click" 两次 | count 0→1→2；`missing native code`=0 | 截图 r0/r1/r2 + hilog |
| **承 #39：FIX-BACKSIZE / FIX-BWVMount** | 抽屉开 → 系统 Back；打开 razor 页 | Back 关抽屉（再 Back 收后台）；`.razor` 挂载（组件区 + count + 按钮） | 截图 + hilog |
| **承 #38：FIX-DISMISS / FIX-WVP** | 抽屉外点关闭；Hybrid 出画 + bridge | 外点关、`origin 0.0.0.1`、`hybrid raw message`、挂起恢复 | 截图 + hilog |
| **承 #37：FIX-HOME / FIX-ITOUCH** | Home 首屏；注入点击页内元素 | Home 整页出画 + 切走/切回；注入命中（element 坐标） | 截图 + hilog |
| **承 #36：payload/a11y/像素/AOT `-r2`** | 见 `2026-10-01-ohos-tester-handoff-kit36.md` §2 | `payload-in-libs: running from …`；`status=1`/nodeCount 5/24；像素无 `Known`；`-r2` AOT 构建成立 | hilog + `a11y/` + 终端 |
| **承 #35/#34/#33：W9/W10、W6/W7/W8、Blazor A/B** | 按 handoff #36 §2 与 #34/#33 判定树 | 同前；套件自报行 `563/floor 543` | 截图 + hilog + `dotnet-status.txt` |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项（出画/点击/截图）照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#40）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.2.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（承 #36）**：用 `-r2` 修正版 pack（asset 601289590）；设备/本机 AOT 构建无需本地 hooks；
   最小复现与判据见 `docs/plans/2026-09-30-rc2-aotpack-openssl-shim-fix.md` §1/§4。
3. **解释器 pack（#41 更新）**：用 **`ohos-interpreter-pack-rc2.tar.gz`**（2,409,070 / `34709a94…`，asset 605924427）
   + 本轮宿主（8 MB 栈 + 关写屏障）；旧 rc.1 pack（2,419,988 / `a10699b3…`）保留作对照；RUN C 判定见
   `docs/plans/2026-10-02-ohos-interp-fix.md` §4。
4. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`（CoreLib `417ab220532` 起）；
   **enforcing 镜像直接装默认 kit 件**（DEVCOMPAT-DEFAULT；逃生口见 §1.2）。
5. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 上架后换 pin、删 feed step（承 #34 注记）。
6. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（本文随附；kit #41 manifest 刷新
   **`e6ed5d28aa7`**）；maui = **`07423dfe93`**（MULTI-OVERLAY-FULL 切片；父 `75c410e798` / `15d81f31b1` FIX-JSCALL）；
   ohos-workload master **`4bfcd68`**（验证器期望刷新 15 `.so`/257 zip；其上 `4674eba` pin / `0e0129e` MULTI-OVERLAY-FULL /
   `04d2199` INTERP-FIX 合并 / `12be59c` DEVCOMPAT / `c9916cd` INTERP-FIX）；sdk 锚 **`2222ba959f`**（bundle 锚
   434d2b6f → **c98375a5**；`-r2` pack 引用保留；interp pack packager `3842c25b2e`；SDK CI run `37042236958`）；
   aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#40）：本机桌面 HAD-W32 / OpenHarmony 7.0.0.111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`
  （UDID `1BCE13C8…AEA0`）；SDK `sign-hap.sh` 自签；AOT/解释器路径均可用（rc.2 线；`-r2` feed）。
- **#41 本轮证据**（scratch）：MULTI-OVERLAY-FULL `multi-ovl-full/device/`（`r13-hybrids-interactive.jpeg`、
  `r13-after-c.jpeg`、`r13-restore-a.jpeg`、`r13-restore-b.jpeg` + hilog）；DEVCOMPAT `devcompat-default/`
  （enforcing A/B：重写包 install 成功 vs 对照 `9568393`）；INTERP-FIX `interp-fix/`（stock 对照、旧 pack 5/5 崩、
  barrier 注入存活、新 pack 存活、faultlog/hilog）；合并对账见 `2026-10-02-ohos-final-consolidation.md`。
- **已知（承 #34–#40）**：JIT payload-in-libs 主包在本机新镜像曾装不上（`9568393`）——**DEVCOMPAT-DEFAULT 已默认修复**；
  AOT/解释器路径为交付方本机主判路径；命令模板 = `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`
  （窗口竞态与 hilog 缓冲注见其 §4）。

## 5. 自签与包布局要点（测试方视角；承 #34–#40）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记。
- **MAUI 5 hap**：payload-in-libs 布局不变；**DEVCOMPAT-DEFAULT 起默认重写**（无扩展名→`.so`、4096→+4 B），
  `libs/arm64-v8a/` 现 15 `.so` + 257 payload 条目；**壳 abc 升 356,140（`2a90f0d7…`）**（多覆盖层 FULL）、
  宿主升 **`8d67def3`**（INTERP-FIX，UND 239）、headless 24,324 不变；新 hap sha 以 release/包内 `SHA256SUMS` 为准。
- **AOT 资产**：独立资产，不在 kit tar 内；安装会顶替 kit 主包，回 JIT 需重装 kit hap；数字以 release asset
  与 AOT README 为准（pack 用 `-r2`）。**解释器 pack 亦为独立资产**（rc2，asset 605924427），Run C 前先换入并重签。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #41）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准；
  **预签件已刷新至 #41**（按 tester UDID；换 bundle 仍先卸载）。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs（**15 `.so` / 257 zip**）/宿主依赖（UND 239）；abc 期望 = **356,140（`2a90f0d7…`）/24,324
   （`798b2477…`）**，脚本哈希 69,717 / `efa27d31…` 以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮 / `--blazor-probe` / `--mode-matrix`（解释器轮改用
   **rc2 pack**）/ `--a11y-probe` 四件同 #40。
3. **7 hap 表（kit #41 发布实测；`SHA256SUMS` 17 项 / 1,517 B / `421a819c…`）**：`hello-maui-app.hap`
   **134,087,950 / `99691f13…`**、`…-unsigned` **131,564,335 / `9b489acb…`**、`…-permissions`
   **134,087,949 / `9d4224b1…`**、`…-api20` **134,088,542 / `6e0c23d2…`**、`…-api20-permissions`
   **134,088,499 / `7b0ac346…`**、Blazor 默认 **27,216,958 / `d6237e96…`**（own abc 21,200 B、site 213 files、
   dotnet.js 93,218 B == `dotnet.bx7u3hgxop.js` / `9f8a0ab4…`）、`-nocsp` **27,216,659 / `1d763d35…`**（包内名
   `hello-blazorwasm-host-nocsp-unsigned.hap`；own abc 21,016 B）。整包 tar **376,036,502 / `bed460ae…`**、
   树 `7ce1946e…`、sidecar `2a95e764…`；bundle `openharmony-workload-1.0.0-preview.28.tar.gz`
   **73,040,293 / `c98375a5…`**（三处同步 versioned `606143323` / latest `606145919` / sdkrc2 `606148969`；
   dist sums 212 B / `80ebfdf6…`；sdkrc2 合并 sums 1,960 B / `4be65073…`；sdk-ohos 锚 **`2222ba959f`**，
   `WORKLOAD_BUNDLE_SHA256` 434d2b6f → c98375a5）；**预签刷新至 #41**（§0b）；**解释器 pack rc2**（asset 605924427）；
   发布已完成：kit tar/边车两处（dtk **392356147** / latest **392077166**；tar/边车 asset **606151881**/**606161455**，
   latest 同件 **606161664**/**606170379**）+ bundle 三处；四条 release body 含 `## Integrity (kit #41)`（含
   interp pack 引用）；by-id 抽验 0 FAIL + 公开直连抽验（dtk 边车 `2a95e764…`、preview.28 sums `80ebfdf6…` 一致）。
   重签/重打包后必变，以 release 与随包校验为准；有 harmony flavor / HMS 的测试者请附壳构建出处与
   Map/LiveView/TTS/HUKS 证据（同 #29–#40）。
4. 离线证据（供复核）：套件 **563/543**（+4 MULTI-OVERLAY-FULL pin）、像素 PASS（Known 清零）、导出 **150/150**、
   壳 abc **356,140/24,324**（四包一致 + provenance）、host **`8d67def3`**/UND 239、`build-arkts-shell 185/0`、
   `verify-kit 108/0`、packs/repo-hygiene 25/0、tools 123/0；#41 设备证据见 scratch `multi-ovl-full/`、
   `devcompat-default/`、`interp-fix/` 与 `docs/plans/2026-10-02-ohos-multi-overlay.md`（§FULL）、
   `…payload-sign-default.md`、`…interp-fix.md`、`…final-consolidation.md`；#40 证据见
   `docs/plans/2026-10-02-ohos-tester-handoff-kit40.md` §4。

## 7. 风险 / 未验证（诚实清单）

- **三大修复的 tester 机复核仍待做**：交付方在本机 AOT 闭环（双 Hybrid/抢占/恢复、enforcing 安装、解释器存活）；
  不同窗口形态与共享桌面环境请按 §2 同法复测；无入口按「未测」登记，不判失败。
- **在途项（明确）**：①z-order 重叠控件真机截图（纵向不重叠布局只有断言/编译实测）；②hello-maui-app 的 Blazor
  `#app` 因样例缺 `modules.json` 未挂载（razor 样例正常）；③stock JIT 路径未单独复测（8 MB 栈预期修复 `+440`；
  JIT 仍受 RWX 拒绝限制）；④匿名可执行映射未在 app 内枚举（Precode/UMEntryThunk 残余可执行页为纯解释启动已知开放点）；
  ⑤rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；⑥DEVCOMPAT 4096 B 规则仅本镜像（7.0.0.105）——
  相关项登记「未测（在途）」。
- **MULTI-OVERLAY 上限 2**：第 3 个并发 web 控件按 LRU 抢占退化（未 engaged 优先、其后最久未用）；被抢者 suspend、
  显式使用才恢复并重放；旧无槽 invoke id 回退"最后注册 hybrid"（兼容旧壳/池满）。
- **payload 探针 `bundleCodeDir`（承 #36）**：模块布局命中后原地启动；两者皆 miss 时打一行提示并回退
  `dotnet.zip`（功能不丢，仅回到解压路径）——请附该行 hilog 回传。
- **AOT pack 结构性缺陷（上游面，未彻底；承 #36）**：共享 `.so` 与静态 `.a` 对 `FEATURE_DISTRO_AGNOSTIC_SSL`
  需求相反；当前以 fetch 端 shim 内容校验兜底（`-r2`），彻底解法见 `2026-09-30-rc2-aotpack-openssl-shim-fix.md` §5。
- **ICU/InvariantGlobalization**：无 ICU 镜像的 AOT demo 需 `InvariantGlobalization`（demo 配方已含）；
  应用侧如遇 hosting 模块初始化 FailFast 可参考。
- **门禁（本轮已跑）**：交互 563/floor 543（+4 fix pin）、像素 PASS（无 `Known(...)`）、导出 150/150、
   包内 `verify-kit.sh` 0 FAIL/0 WARN（15 `.so`/257 zip/abc 356140/24324）、`ohos-workload` master **`4bfcd68`**；
   CI **5/5** @ `4bfcd68`（interaction `37040903892` / pixel `37040904000` / host-export `37040904035` /
   ridgraph `37040903746` / markdownlint `37040904026`）、sdk `ohos-install-tests` @ `2222ba959f` run
   `37042236958`（installer 43/43 · hostfeed 10/10 · codesign-filewrites 5/5）。
- 本次构建基线 = **rc.2 线**（SDK `.112` / workload `preview.28` / MAUI `rc2.26478.12`）；应用侧构建请同步该线
  （`docs/plans/2026-09-30-rc2-mainline-adoption.md` §4/§5；rc.1 回滚路径保留）。
