# 测试方交接：kit #44、动态槽（SLOTS-DYNAMIC：MAX/HOT 4/2 按需创建/释放销毁 + 3 控件并发）+ 默认 AOT / FRAMEPACING（承 #43）（2026-10-04）

> 日期口径：文件名按撰写日；**kit #44 发布实测（release「## Integrity（kit #44）」；发布已完成，一切数字以
> release 与随包 `SHA256SUMS` / `.tar.gz.sha256` sidecar 为准）**：tar **67,680,863 B / `b777d8d8…`**、树
> **`db2604d5…`**、sidecar **`85d62a6e…`**（89 B）、`SHA256SUMS` **18 项 / 1,600 B / `41c1f3c3…`**
> （#43 = tar **67,638,015 B / `57c7bf44…`**、树 `0c41f071…`、sidecar `bd1f8e33…`；#42 = tar
> **376,256,128 B / `ea4e3b58…`** 对照）。重签/重打包后哈希必变；CI run id 见 §7。
> 构建基线（rc.2 线，同 #34–#43）：SDK **`11.0.100-rc.2.26451.112`** / workload **`1.0.0-preview.28`** /
> MAUI **`11.0.0-rc.2.26478.12`**；rc.1 线（preview.24）保留回滚（默认根 `~/.dotnet` 未动）。
> **AOT 包（结构修复后重出，承 #42）**：rc.2 runtime pack 现取 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；
> sha `09345f9515612f2b090fd0e0f54c815156105127cc1686240a3cad8521dab11c`，= sdk fetch 现锚）；结构修复
> `c1c85422715`（`FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分对象库）已入 runtime 源；旧的 `-r2`（601289590 / `542058cf…`）
> 与原包（`46d221f2…`）保留为历史、不再钉锚（重出记录见 `2026-10-03-ohos-aotpack-rebuild.md`）。
> **预签已刷新（#44，本波）**：dtk 上的 `preSigned-haps.tar.gz` 已重签为 **kit #44 件**（67,627,789 B / `75a40110…`，
> asset **608782132**；sidecar 88 B / `b880a68f…`，asset **608782732**；替换 #43 件 608611945/608633135）——按
> tester UDID `60CF7B27…` 预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**（非该 UDID 报 `9568344`）。
> **在途/外部（明确）**：AGC App Linking 登记 + 真机 https 投递；镜像扩展分支 `m-web-mirror d47f1fcb3b`
> 尚未并入 `feature/openharmony`；rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；stock JIT 长跑/
> 后台唤醒未覆盖（JIT 现非默认）——相关项登记「未测（在途）」不判失败。

> **2026-10-04 更新（AOT-DEFAULT + FRAMEPACING；#43 交付内容，本包承）**：**出包/分发默认 AOT**（`make-device-test-kit.sh
> --runtime-mode aot`，默认；kit 根 `runtime-mode.txt=aot` + 每 hap marker；7 hap 全 AOT 线）——5 个 MAUI hap
> 全部 NativeAOT（`libs/arm64-v8a` 仅 3 `.so`：`libhello-maui-app.so` 19,208,976 + host 297,888 +
> `libc++_shared.so` 1,267,392；**无** `libcoreclr`/`libhostfxr`/`libclrjit`；payload `dotnet.zip` 200,144 B / 9 项）。
> **JIT 保形态**：`--runtime-mode jit` 可自建（debug/内测签名域免 ACL；release/生产域需 AGC ACL
> `ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`（2in1/平板）或厂商豁免；手机只发 AOT）；interp 仍不随主包
> （独立 pack rc2b）。**FRAMEPACING**（ow `aa6f485`）：宿主 present telemetry + `framepacing-stats.py` 统计装置——
> 旧口径 17.7 fps 系壳 `pollManagedStatus` 状态轮询伪影（每 3 s 重放末 60 行），5 s 桶聚合后真实呈现 **60.00 fps**；
> host **297,888**（`7b1694d9…`，逐字节同 #43）、导出 151/151、UND 241。判定点与证据见
> `docs/plans/2026-10-03-ohos-framepacing.md`、`docs/plans/2026-10-03-ohos-three-path-baseline.md` §5。

> **2026-10-04 更新（SLOTS-DYNAMIC；#44 增量）**：覆盖层池**动态槽**（ohos-workload `88e5aec` + maui 切片
> `3feb347414`）——托管 `OpenHarmonyOverlays` 上限可配（`OHOS_OVERLAY_MAX`/`OHOS_OVERLAY_HOT`，**默认 4/2**，
> clamp 2..8 / 2..max）：`Acquire(owner)` 无空闲槽 → **按需新建**（`slot ensure\n<k>`），达容量仍无槽 → 既有
> owner-LRU 抢占（#41 语义保持、被抢 suspend/恢复重放）；`Release` 后动态槽（>=hot）**立即销毁**
> （`slot destroy\n<k>`；热对 [0,1] 常驻，空闲 >2 不养 ArkWeb 引擎/文档）。壳：`@State webSlots`（热对）+ **`ForEach`
> 动态建 ArkWeb**（`WEB_SLOT_MAX=4/HOT=2`）、`ensureWebSlot/destroyWebSlot`、未 attach 命令**按槽排队（≤32）在
> `onControllerAttached` 按序重放**、`capacity` 事件带 3 次有界重试；线协议不变（`s<slot>`/`__OHNAV|s<slot>|…`）。
> 切片 `OnPageEvent("capacity")` → **`SetShellCapacity`**；容量下调按 suspend 抢占超容量 claim（旧 2 槽壳安全降级）。
> 宿主/native 零改动。**真机 HAD-W32：3 控件并发出画/可交互**（A/B/C 各自 invoke/raw 回显 + label；第 3 槽回收后
> `remove-c.jpeg`、重建后仍可交互；N=2 对照见 `slots-dyn/`）。**门禁 +6 pin**：ensure/destroy 命令、容量降级、
> 2/4 夹取、壳 lazy/defer、第 3 槽样例 → 套件 **584/586 floor 566**。

> 结论先行：kit #44 = **kit #43（默认 AOT + FRAMEPACING）+ 动态槽（SLOTS-DYNAMIC）**，并承 #42 的
> **JIT 解锁（JITFORT）/解释器 rc2b/FIX-SLICERACE/L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c**、#41 的
> **MULTI-OVERLAY-FULL/DEVCOMPAT-DEFAULT/INTERP-FIX**、#40–#35 的 FIX-JSCALL/BACKSIZE/BWVMount/DISMISS/WVP/HOME/
> ITOUCH/payload/a11y/像素/B2/W9-W10 全量。指纹：壳 abc **368,812（`1076a700…`）/ headless 24,324（`798b2477…`）**、
> 宿主 **297,888（`7b1694d9…`）**、导出 **151/151**、套件 **584/586 floor 566**、预签已刷新至 #44。判定点见 §2；
> 承接 #42/#41/#40/#39/#38/#37/#36/#35/#34/#33 的判定点**继续有效**，本文只覆盖 #43–#44 增量与判读引用。

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

## 0b. 预签直装（#34 起加发资产；**已刷新至 #44**）

`device-test-kit` release 的并列预签资产 **`preSigned-haps.tar.gz`** 当前为 **kit #44 件**（2026-10-04 重签；
asset **608782132**，**67,627,789 B / `75a40110…`**；sidecar 88 B / `b880a68f…`，asset **608782732**；解包树
`03abdce3…`；**内容 = kit #44 的 7 hap** + `preSigned-README.md`（65 行）+ `SHA256SUMS` 8/8；ZIP 条目与 kit
原件逐字节一致）。按 tester UDID `60CF7B27C58898C4CFE966087EFAACD9365B783F7328B2DBB8252919AE1F8A19`
预签，`sha256sum -c SHA256SUMS` 后 `hdc install -r` **直装**；非 tester UDID 设备报 `9568344`。预签包是并列
附加件，完整一轮仍用 kit tar。

## 1. kit #44 相对 #43 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **动态槽（SLOTS-DYNAMIC）** | 覆盖层池不再固定双槽：上限 **MAX/HOT 默认 4/2**（env 可配，clamp 2..8 / 2..max）。无空闲槽时**按需创建**（`slot ensure`）；**释放后动态槽立即销毁**（`slot destroy`；热对 [0,1] 常驻）；达容量仍无槽按 owner-LRU 抢占（#41 的 suspend/恢复重放不回归）；壳 `ForEach` 动态槽 + 未 attach 命令按槽排队（≤32）在 `onControllerAttached` 重放；切片 `SetShellCapacity` 接容量事件。**真机 3 控件并发出画/可交互**（A/B/C invoke+raw 回显），第 3 槽回收（C 区消失、label `removed (slot destroy)`）→ 重建（slot 2 重建后 C 仍 `sent raw C-raw-ping (stock)`）；N=2 对照 = #41 第 3 控件被抢空白 vs 本轮全在画 | 3 控件各自出画 + 交互回显；`web cmd: slot`→`web slot create: 2`→`web capacity: 4`；回收/重建截图闭环（`web slot destroy` 原文可能因日志轮转缺失，由截图+重建佐证） |
| 1.2 | **默认 AOT + FRAMEPACING（承 #43）** | 7 hap 全 AOT 线：5 MAUI hap 均 NativeAOT（`runtime-mode.txt=aot`、3 `.so`、无 JIT 运行时）、首帧与交互回归；`--runtime-mode jit` 自建仍可跑 JIT（JITFORT 承 #42；release 域需 ACL/豁免）。FRAMEPACING：宿主 5 s 帧聚合，真实呈现 **60.00 fps**（旧 17.7 fps = 壳状态轮询伪影）；宿主逐字节同 #43（297,888/`7b1694d9…`） | AOT 首帧 + 交互；`runtime-mode.txt=aot`/无 libcoreclr/libclrjit；60 fps 口径；JIT 复测走自建包或 ACL |
| 1.3 | **承 #42：JIT 解锁 / 解释器 rc2b / FIX-SLICERACE / L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c/镜像** | JITFORT + ICU invariant（JIT 首帧；现为形态保留）；解释器 rc2b 首帧（`ohos-interpreter-pack-rc2b.tar.gz` 2,410,595 / `5974430509…`，asset 606999003，配 rc.2 kit hap）；FIX-SLICERACE 8/8；L6（JPEG/心跳）、LEGACY Toolbar、SAMPLE-FIX（`blzProbe`/`#app`）、WX-PATCH2、P2c `skills[].uris` 判定不变 | 同 `2026-10-03-ohos-tester-handoff-kit42.md` §2；AOT kit 上 L6/SAMPLE-FIX 继续适用；JIT/interp 轮按对应资产 |
| 1.4 | **门禁/指纹/7 hap/预签** | 交互套件 **584 checks / 586 total / floor 566**（SLOTS-DYNAMIC +6：ensure/destroy、容量降级、2/4 夹取、壳 lazy/defer、第 3 槽样例）、像素 `PIXEL ASSERTIONS PASSED`（0 `Known`）、宿主导出契约 **151/151**、host UND **241**/DT_NEEDED 5/denylist 0；**新壳 abc 368,812（`1076a700…`）/ headless 24,324（`798b2477…`）**（`Index.ets 325,055/c29640dd`、provenance `ee41386e…`）、host **297,888（`7b1694d9…`）**；**7 hap**：5 MAUI 全 AOT（22.0–22.3 MB）+ Blazor 默认/-nocsp（27,216,958/`ea920cf6…` 与 27,216,659/`47b1e79d…`，未签名，同尺寸异哈希 vs #43）；**预签刷新至 #44**（67,627,789/`75a40110…`，asset 608782132） | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**；套件自报行 `[suite] checks=584 total=586 floor=566 assert=True`；`runtime-mode.txt=aot` |
| 1.5 | **门禁构建（#43 记录）** | 本波构建机 rc.2 + pack `.28` 同步；首跑 kit 构建因 Release DLL 未产出失败 17 s，补跑 hosting/graphics Release 后 rc=0（见 §7 备注）；selftests 全绿（一处已知环境伪影首跑 37/1，默认 dotnet 复跑 37/0） | 构建日志 `reg-kit44/build-*.log`（交付方侧） |
| 1.6 | **在途/外部项（明确）** | ①AGC App Linking 登记 + 真机 https 投递；②镜像分支 `m-web-mirror d47f1fcb3b` 未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1` 绕过未定位；④`web slot destroy` 原文未取到（截图+重建佐证，可静置复核）；⑤第 4 槽未真机点验（headless 限值 drill）；⑥stock JIT 长跑/后台唤醒未覆盖 | 登记「未测（在途）」，**不判失败** |

> 尺寸预算：以 release 资产表为准（#43 = 67,638,015 B；#44 = 67,680,863 B，delta = 新壳 abc/切片重建 + 套件；AOT 线无 libcoreclr，整包远小于 #42 的 376 MB）。

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **动态槽 3 控件并发（主判点 1）** | 装默认 kit 主 hap（AOT）→ 在同页/演示页加满 3 个 Web 控件 | **3 控件各自出画并可交互**（A、B、C 各自 invoke/raw 回显 label）；第 3 槽按需创建（`web cmd: slot`→`web slot create: 2`、容量事件 `web capacity: 4`） | 截图（3 控件同页）+ hilog |
| **释放即拆 / 重建（主判点 2）** | 移除第 3 控件 → 再加回 | 移除后动态槽释放（C 区消失、label `removed (slot destroy)`）；重建（slot 2）后可再次交互（`sent raw C-raw-ping (stock)`）；热对 [0,1] 不受影响 | 前后截图 + hilog（`slot destroy` 原文可能轮转缺失，以截图闭环为准） |
| **AOT 默认（主判点 3）** | 装默认 kit 主 hap（无需 ACL）→ 冷启 | `runtime-mode.txt=aot` + hap marker；`libs/arm64-v8a` 仅 3 `.so`、无 `libcoreclr`/`libclrjit`；**首帧 + 交互回归** | 截图 + `verify-kit` 深度断言 + hilog |
| **FRAMEPACING（#43 承）** | 宿主 present telemetry（5 s 桶）出画稳定后统计 | 真实呈现 **60.00 fps**（旧 17.7 系壳状态轮询伪影） | 帧统计/终端输出 |
| **套件基座** | 有源码测试者跑 `test/maui-platform-verify` | `[suite] checks=584 total=586 floor=566 assert=True`；导出 151/151 | 终端输出 |
| **承 #42：JIT 解锁 / 解释器 rc2b / FIX-SLICERACE** | 自建 jit 变体（或 ACL）冷启；rc2b pack + rc.2 kit hap + `interp.txt=3`；JIT 8 轮 | JIT：`jitfort rc=0` + 探针 `1=OK 2=OK` + `canvas presented`；interp：`canvas presented`、无 `SIGSEGV(NULL)`；race=0 | 截图 + hilog |
| **承 #42：L6 / LEGACY / SAMPLE-FIX / WX-PATCH2 / P2c** | 截图 JPEG、Toolbar 契约、`blzProbe`/`#app`、双映射、`module.json skills` | 同 #42 期望（AOT 线继续适用） | 截图 + hilog + `module.json` 摘录 |
| **承 #41：MULTI-OVERLAY-FULL / DEVCOMPAT / INTERP-FIX** | 双 Hybrid/抢占/恢复（3 控件场景已覆盖）；enforcing 装包；8 MB 栈 | 同 #41 期望；#44 的 3 控件为首个 >2 全交互版本 | 截图 + hilog |
| **承 #40/#39/#38/#37/#36/#35：FIX-JSCALL / BACKSIZE / BWVMount / DISMISS / WVP / HOME / ITOUCH / payload / a11y / 像素 / B2 / W9-W10** | 见 `2026-10-03-ohos-tester-handoff-kit42.md`/#41/#40/#36 §2 | 同前各期望；套件自报行 `584/floor 566` | 截图 + hilog + `dotnet-status.txt` |
| **承 #34/#33：rc.2 自述 + W6/W7/W8 + Blazor A/B + 主体** | 包内自述；各卡 | SDK `.112` / workload `.28` / MAUI `rc2.26478.12`；逐项同 #34/#33 | 自述原文 + 截图 + `--a11y-probe` |
| **无 hdc / 不能重签时** | 只有设备文件管理器 | 自动项登记「未测（无 hdc）」；人工项照做 | 截图 + 说明 |

> 无对应资产/入口时按「未测（本包无入口/无 hdc）」登记，**不要判失败**；A/B 两变体互不冲突（同 bundle，装前卸载）。

## 3. rc.2 线判定点（构建/安装侧）

1. **设备测试栈**（同 #34–#43）：rc.2 线 = SDK `11.0.100-rc.2.26451.112` + workload `1.0.0-preview.28` + rc.2 packs；
   rc.1（`11.0.100-rc.2.26451.109` / preview.24）保留回滚（本机 `~/.dotnet` 未动）。
2. **AOT pack（结构修复后重出）**：当前用 **`-struct1`**（28,905,116 / `09345f95…`，asset 607541145；sdk fetch
   现锚，`versions.env` sha `09345f9515612f2b090fd0e0f54c815156105127cc1686240a3cad8521dab11c`）；`c1c85422715`
   起 `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` 拆分对象库（静态 `.a` 保 shim、共享 `.so` 静态 OpenSSL；sdk 布局+nupkg
   两处校验）；`-r2`（601289590）/原包（`46d221f2…`）仅历史；最小复现见 `2026-09-30-rc2-aotpack-openssl-shim-fix.md`、
   重出记录见 `2026-10-03-ohos-aotpack-rebuild.md`。
3. **解释器 pack（#42 更新；本波未动）**：用 **`ohos-interpreter-pack-rc2b.tar.gz`**（2,410,595 / `5974430509…`，
   asset 606999003）+ **rc.2 kit hap**（重签）+ #42+ 宿主；**勿用 rc.1 托管 CoreLib 的旧测试件**（QCall ABI 错配
   会 NULL 崩）；`interp.txt=1|2` 混合模式保留默认；判定见 `2026-10-03-ohos-interp-null.md`。
4. **应用侧构建**：请同步 rc.2 线发布（不混装）；设备/本机 `OS Platform: Linux`（CoreLib `417ab220532` 起）；
   enforcing 镜像直接装默认 kit 件（DEVCOMPAT-DEFAULT）；AOT 为默认（`-p:OpenHarmonyRuntimeMode=aot`）。
5. **dnceng daily**：MAUI `11.0.0-rc.2.26478.12` 若仍未上 nuget.org，交付方 restore 走 dnceng `dotnet11` feed；
   官方 rc.2 上架后换 pin、删 feed step（承 #34 注记）。
6. **五仓 tip（本波）**：runtime = 本仓 `feature/openharmony` docs（本文随附；kit #44 manifest 刷新
   **`b486c6561e8`**，父 `23a80aa0017` = #43）；maui = **`3feb347414`**（SLOTS-DYNAMIC 切片；父 `549967f2f0`
   = FIX-SLICERACE）；ohos-workload master **`88e5aec`**（SLOTS-DYNAMIC 实现；父 `aa6f485` = FRAMEPACING；其上
   `86b0e89` 把三 workflow pin + `MAUI_OHOS_REF` fallback 推进到 `3feb347414`）；sdk 锚 **`2abf4fcaa3`**
   （`WORKLOAD_BUNDLE_SHA256` 929b7263 → **3b3008a4**；-r2/struct1 pack 与 interp rc2b 引用保持；父 `1c4f21ce13`
   = #43 锚）；aspnetcore `e10d030184`（以 release/仓库页为准）。

## 4. 本机直测（交付方自验能力）

- **设备已可直测**（承 #34–#43）：本机桌面 HAD-W32 / OpenHarmony 7.0.0.111 / API 26；hdc 无线 `tconn 127.0.0.1:35111`
  （UDID `1BCE13C8…AEA0`）；SDK `sign-hap.sh` 自签；AOT 为默认路径，JIT/解释器按各自资产。
- **#44 本轮证据**（scratch `slots-dyn/`）：① 3 控件并发出画/可交互（`addC.jpeg`、`abc-3controls-interactive.jpeg`、
  `abc-interactive.jpeg`、`round/r4-remove-c.jpeg`：A `invoke: "A-echo:Echo:1"`、B `sent raw B-raw-ping`、
  C `invoke: "C-echo:Echo:1" (stock)` + label `A/B/C raw`）；② 按需创建 `hilog-cycle2-add.txt`：
  `web cmd: slot`→`web slot create: 2`→defer hybrid/frame→`hybrid assets slot=2`→`web page (slot 2)`，容量 `web capacity: 4`；
  ③ 回收重建 `remove-c.jpeg`（C 区消失、label `removed (slot destroy)`）→`readd-c.jpeg`/`readd-raw.jpeg`
  （slot 2 重建后 C 仍 `sent raw C-raw-ping (stock)`）；④ N=2 对照：既有
  `multi-ovl-full/device/r13-after-c.jpeg`（N=2 加第 3 控件 A 被抢空白）vs 本轮 3 控件全在画。
- **#43 本轮证据**（scratch `framepacing/`）：present telemetry + `framepacing-stats.py`——旧 17.7 fps 复现为
  708/705/701 行（壳重放）伪影；同载荷聚合显示真实呈现 **60.0 fps**；AOT 变体指纹/真机对照见
  `docs/plans/2026-10-03-ohos-three-path-baseline.md` §5。
- **已知（承 #34–#42）**：JIT 主包在 enforcing 镜像**已可开箱安装**（DEVCOMPAT-DEFAULT）；JIT 首帧依赖 JITFORT
  （#42 默认；release 域需 ACL）；状态文件/轮询可能含上一轮残留行——判读以时序内状态为准。
- **本机可直接闭环**：AOT/JIT/interp 出画、多覆盖层 3 控件、Blazor 标记、a11y/日志/截图回路；命令模板 =
  `docs/plans/2026-09-29-ohos-local-device-test-runbook.md`（窗口竞态与 hilog 缓冲注见其 §4）。

## 5. 自签与包布局要点（测试方视角；承 #34–#42）

- **Blazor 组件**：bundle **`com.example.opendotnet`**（默认与 `-nocsp` 同名，装前卸载旧件）；仍无 INTERNET
  （重签保持）；标记带 per-launch nonce，`--blazor-probe` 只接受宿主 pid + nonce 的标记；本波两 hap 尺寸同 #43、
  哈希因重签更新（`ea920cf6…` / `47b1e79d…`，以 release/包内 `SHA256SUMS` 为准）。
- **MAUI 5 hap（全 AOT）**：payload-in-libs + DEVCOMPAT 重写；`libs/arm64-v8a` 3 `.so`（app.so 19,208,976 + host
  297,888 + `libc++_shared.so` 1,267,392）、无 JIT 运行时；`resources.index` 1,894（26.0）/2,102（20.0）B；
  `ets/modules.abc` **368,812（`1076a700…`）**；AOT payload `dotnet.zip` 200,144 B / 9 项；kit 根
  `runtime-mode.txt=aot`。新 hap sha 以 release/包内 `SHA256SUMS` 为准。
- **AOT/解释器资产**：均为独立资产，不在 kit tar 内；AOT 用 **`-struct1`**（asset 607541145；`-r2` 仅历史）、
  `aot-haps-v3-rc2.tar.gz`（18,185,012 / `3d24f716…`，dtk 599996905）本波未动；解释器用 **rc2b** + **rc.2 kit hap**；
  安装会顶替 kit 主包，回 AOT 重装 kit hap。
- **重建/重签后哈希必变**：一切数字以 release「## Integrity（kit #44）」与随包 `SHA256SUMS` / `.tar.gz.sha256` 为准；
  **预签件本波已刷新（#44 件）**——非 tester UDID 设备仍 `9568344`，请回传 UDID 代签。

## 6. 校验与取证

1. 包内 `sh verify-kit.sh` → 期望 **0 FAIL / 0 WARN**（深度断言逐 hap：`resources.index`/abc/libs/`dotnet.zip`/
   payload-in-libs/宿主依赖（UND 241）；5 MAUI hap 期望 `runtime-mode.txt=aot`、3 `.so`、无 libcoreclr/libclrjit；
   abc 期望 = **368,812（`1076a700…`）/24,324（`798b2477…`）**，脚本哈希 76,707 / `b205ae64…` 以包内为准）。
2. `tester-run.sh`（版本以包内自述为准，承 v14）：常规轮（AOT）/ `--blazor-probe` / `--mode-matrix`（解释器轮用
   **rc2b pack**）/ `--a11y-probe` 四件同 #42。
3. **7 hap 表（kit #44 发布实测；`SHA256SUMS` 18 项 / 1,600 B / `41c1f3c3…`）**：`hello-maui-app.hap`
   **22,325,065 / `bbc2cd7c…`**（AOT）、`…-unsigned` **22,022,815 / `825e5ae9…`**、`…-permissions`
   **22,325,078 / `f5cf7271…`**、`…-api20` **22,325,069 / `adc42995…`**、`…-api20-permissions`
   **22,325,068 / `17f272b3…`**、Blazor 默认 **27,216,958 / `ea920cf6…`**（own abc 21,200 B，未签名）、
   `-nocsp` **27,216,659 / `47b1e79d…`**（包内名 `hello-blazorwasm-host-nocsp-unsigned.hap`；own abc 21,016 B）。
   整包 tar **67,680,863 / `b777d8d8…`**、树 `db2604d5…`、sidecar `85d62a6e…`；bundle
   `openharmony-workload-1.0.0-preview.28.tar.gz` **73,052,763 / `3b3008a4…`**（三处同步 versioned `608766692` /
   latest `608773977` / sdkrc2 `608774850`；dist sums 212 B / `fee52445…`；sdkrc2 合并 sums 1,960 B / `2c64c534…`；
   sdk-ohos 锚 **`2abf4fcaa3`**，`WORKLOAD_BUNDLE_SHA256` 929b7263 → 3b3008a4）；**解释器 pack rc2b**
   （asset 606999003）与 **`-struct1` AOT pack**（asset 607541145）保持；**预签已刷新（#44 件：asset 608782132 /
   608782732）**；发布已完成：kit tar/边车两处（dtk **392356147** / latest **392077166**；asset **608775822**/
   **608776466**，latest 同件 **608776640**/**608777124**）+ bundle 三处；四条 release body 含
   `## Integrity (kit #44)`（含预签行）；by-id 抽验 0 FAIL + 公开直连抽验（dtk 边车 = `b777d8d8…`、preview.28/latest
   sums `fee52445…` 一致）。重签/重打包后必变，以 release 与随包校验为准；有 harmony flavor / HMS 的测试者请附壳
   构建出处与 Map/LiveView/TTS/HUKS 证据（同 #29–#42）。
4. 离线证据（供复核）：套件 **584/586 floor 566**、像素 PASS（0 Known）、导出 **151/151**、壳 abc
   **368,812/24,324**（四包一致 + provenance `ee41386e…`）、host **`7b1694d9`**/UND 241、`build-arkts-shell 185/0`、
   `verify-kit 129/0`、packs/repo-hygiene 25/0、tasks 9/0；selftests 全绿（build-arkts 185/0、make-mode-kit 82/0、
   make-device-test-kit 37/0（首跑 37/1 为已知环境伪影）、sign-for-device 209/0、devloop 109/0、commit-paths 29/0、
   tester-run 683/0、verify-kit 129/0）；#44 设备证据见 scratch `slots-dyn/` 与
   `docs/plans/2026-10-02-ohos-multi-overlay.md` §DYNAMIC；#43 见 `2026-10-03-ohos-framepacing.md`；
   #42 证据见 `docs/plans/2026-10-03-ohos-tester-handoff-kit42.md` §4。

## 7. 风险 / 未验证（诚实清单）

- **本轮动态槽的 tester 机复核仍待做**：交付方在本机闭环（3 控件互动/回收/重建）；不同窗口形态与共享桌面环境请按
  §2 同法复测；无入口按「未测」登记，不判失败。**未知项**：`web slot destroy` 原文未取到（日志秒级轮转；截图 +
  重建闭环佐证，可静置复核）；第 4 槽未真机点验（headless 限值 drill 覆盖 2/4 夹取）。
- **在途/外部项（明确）**：①AGC App Linking 登记 + 真机 https 投递（P2c 本机产物已可验；自签包仍走显式 want）；
  ②镜像分支 `m-web-mirror d47f1fcb3b` 未并入 `feature/openharmony`；③rc.2 csc 并行活锁以 `DOTNET_PROCESSOR_COUNT=1`
  绕过未定位（本波 gate-2 交互构建+运行在 `DOTNET_PROCESSOR_COUNT=1` 下首跑全绿，无 #43 的 csc 活锁）；④stock JIT
  长跑/后台唤醒未覆盖（JIT 现非默认形态）；⑤解释器混合模式（`interp.txt=1|2`）保留默认。
- **AOT 默认边界**：JIT/解释器均需动态码；release/生产域请走 AOT 或申请 ACL
  （`ohos.permission.kernel.ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）；手机只发 AOT。`-p:OpenHarmonyRuntimeMode=jit`
  自建 jit 变体仍可复现 #42 三路径判定。
- **动态槽边界**：热对 [0,1] 常驻；空闲 >2 不养 ArkWeb 引擎/文档（重建只付一次组件+加载，权衡写在类头，无定时器）；
  容量下调按 suspend 抢占超容量 claim（旧 2 槽壳安全降级）；env 不可按应用注入，真机 N=2 对照用既有证据 + headless
  限值 drill。
- **解释器口径**：rc2b pack 只配 rc.2 kit hap + #42+ 宿主；旧 rc.1 托管 CoreLib 测试件会 QCall ABI NULL 崩（测试件问题）。
- **AOT pack 结构性缺陷（已修复入源）**：`c1c85422715` 拆分对象库；当前资产 = **`-struct1`**（asset 607541145）——
  `-r2`（601289590）/原包（`46d221f2…`）仅历史，后续 pack 无需重打。
- **ICU/InvariantGlobalization（承 #42）**：本镜像无系统 ICU——宿主自动 invariant；应用侧如遇 hosting FailFast 可参考。
- **env 备注（本波构建）**：首跑 kit 构建 17 s 即失败（CS0234 `Microsoft.OpenHarmony.Maui`：csproj HintPath 指向
  `src/Microsoft.OpenHarmony.Hosting|Maui.Graphics` 的 Release DLL，而本波 selftest 未产出）——补跑两个 Release
  构建（hosting 73,728 / graphics 16,384）后 kit 构建 rc=0（7 hap，~7.3 分钟）；`make-device-test-kit` selftest
  首跑 37/1 为已知环境伪影（绝对 DOTNET 路径 vs 自测字面 `+ dotnet publish`），默认 dotnet 复跑 37/0。
- **hilog 缓冲/状态伪影**：512K 环噪声大时 ≈4–5 s；`dotnet-status.txt`/轮询可能含上一轮残留行——以时序内状态为准。
- **门禁（本轮已跑）**：交互 584/586 floor 566（+6 SLOTS-DYNAMIC pin）、像素 PASS（无 `Known(...)`）、导出 151/151、
  preflight OK（ridgraph 20 / packs 25 / hap-targets 73 / tasks 9 / repo-hygiene 25）、CI 5/5 @ `86b0e89`
  （interaction 37161898886 / pixel 37161898880 / host-export 37161898883 / ridgraph 37161898877 /
  markdownlint 37161898899）+ sdk `ohos-install-tests` @ `2abf4fcaa3` run 37164183212 success；runtime manifest
  提交 `b486c6561e8` 为 docs-only（无 workflow run）。
