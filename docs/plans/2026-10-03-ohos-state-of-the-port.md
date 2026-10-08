# OpenHarmony .NET/MAUI 移植终版一览（STATE-OF-PORT，2026-10-03；当前口径 = kit #53 / 2026-10-08）

> 一页纸（≤60 行）：三路径终局（§1）· kit #53 交付与 POST-L3（§2）· 修复全景（§3）· 外部项（§4）· 已知限制（§5）· 历史快照（§6）。
> 当前数字 = release「## Integrity（kit #53）」与随包校验；已与 FINAL（`2026-10-05-ohos-maui-completion-verdict.md`「kit #53 终态」）、`2026-10-08-ohos-l3-post-consolidate.md`、`2026-10-08-ohos-tester-handoff-kit53.md`（设备轮 = `2026-10-08-ohos-device-round-53.md`）交叉一致。证据/明细见各专题报告（README 索引置顶行指向本页）。
> 历史节（§1 表、§3 表、§6 快照）按快照保留；旧轮判定点继续有效。

## 1. 三路径终局（kit #42 基线；机制与定位未变）

同一 2in1 / API 26 / debug 签名域；冷启 payload→canvas ≈3.2 s（三路径同档）；AOT/JIT = 60 fps vsync（呈现:回调 1:1、零丢帧），interp ≈21 fps。

| 路径 | 定位与边界 | 关键数字 |
|---|---|---|
| **AOT（推荐默认）** | 出包/分发默认（`--runtime-mode aot`；kit 根 + 每 hap `runtime-mode.txt=aot`）；release 域/手机域/坚盾模式唯一形态 | RSS 比 JIT **−74.8 MB（15 s）/ −84.1 MB（42 s）**；首帧 3534 ms、`jitfort: skipped`、`canvas presented` 765、0 崩 |
| **JIT（性能形态）** | `prctl(0x6a6974)` JITFORT 默认开 + 无 ICU 自动 invariant → **首帧**；debug/内测域免 ACL；release 域需 AGC ACL（`ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）或厂商豁免，否则回落 AOT | `jitfort rc=0 errno=0 state=off`、探针 `1=OK 2=OK`、8/8 race=0、60.00 fps |
| **interp（实验）** | rc2b pack 独立分发，不进主包；**渲染受限** | 首帧 `canvas presented (2090x1324)`；21.47 fps（渲染+呈现 32 ms/帧，平台量化到 ~50 ms） |

## 2. 交付（当前 = kit #53；#42–#52 快照见 §6）

- 发布：tar **68,883,057 / `dba88961…`** · 树 **`9c67b5ec…`** · sidecar **`47ace1d0…`**（89 B）· `SHA256SUMS` 18 项 / 1,600 B / `39489081…`；bundle **73,213,144 / `031ba342…`**（sdk 锚 **`64f239eb28`**）。
- 件/门禁：abc **542,936 / `f18f0855…`** · headless 24,324 / `798b2477…` · 宿主 **367,520 / `ad7ab986…`**（导出 **164/164**、UND 252，同 #52 指纹）；套件 **737/740 floor 720**（POST-L3 = 731 + B6 5 + A11Y-SELFCHECK 1）；7 hap = 5 MAUI 全 AOT + Blazor 默认 / `-nocsp`；构建线 rc.2（SDK `.112` / workload `preview.28` / MAUI `rc2.26478.12`）。
- 预签（#53）：**68,755,353 / `d1732195…`**（asset 620760775；sidecar 88 B / `35b736b3…`，asset 620762418）；测试方单件轮包 `tester-round-kit53.tar.gz`（**157,866,589 / `0ce200a2…`**，asset 620790919 + sidecar 620794313）。
- 并列资产（保持未动）：rc2b interp pack `5974430509…`（asset 606999003）；`-struct1` AOT pack 28,905,116 / `09345f95…`（asset 607541145）；Crossgen2 rc.2 43,792,647 / `6bb8a375…`。
- **POST-L3 主题（#53）**：**A11Y-SELFCHECK 子窗首发布修复**（per-window 发布门禁的 `NativeLibrary` 预探针在托管 loader 误报 `export=False` → `PublishSecondary` 直连 `provider_status_for` + `WindowPublishPending` 强制重绘；真机诊断 `nodes=0` → 修复 **`nodes=10` ×2** + 定向关/重开稳定、主窗零回归）+ **B6 子窗导航否决**（壳 `onLoadIntercept` 网关 + managed `Navigating`/一次性批准；deny/ok 真机双链闭环）；承 **kit #52 全量**（MULTIWINDOW-L3 N=2 多子窗 M1–M4 + L3 尾项 a11y 分区 release/hybrid-Blazor 资产桥）。**降级/人工卡（沿用+新增）**：a11y 动作 e2e 平台限 · uitest Back/alert 注入限制 · 子窗 hybrid/Blazor 桥真机样例缺 · B6 `//host` 样例受限（deny/ok data: 已闭环）· 子窗 IME 人工卡 · `export=False` 预探针加载器层根因未追 · 多窗同槽 hybrid invoke fail-closed · 池满/队列溢出 · `loadData` 裸 `#` 截断 · SEC-6 原生 a11y 分区常驻（有界）· 应用级 N=2 壳契约（平台 255）。

## 3. 修复全景（#42 基线落地表；#43–#53 增量见 §2 与各交接文）

| 域 | 代表修复 | 状态 |
|---|---|---|
| 渲染族 | FIX-HOME / FIX-ITOUCH / FIX-DISMISS / FIX-BACKSIZE / FIX-WVP / FIX-SLICERACE；FRAMEPACING 归因「17.7 fps = 壳状态轮询伪影，真实 60.00 fps」 | ✅ 真机闭合 |
| WebView 族 | FIX-WVP（覆盖层出画/bridge/挂起）+ FIX-BWVMount + FIX-JSCALL + MULTI-OVERLAY-FULL（N=2 槽池 + owner LRU）+ ZORDER-NAV（重叠置顶 97.2% 翻转） | ✅ 真机闭合 |
| B2（MAUI WebView 承载 Blazor WASM） | WebView 六项接线 + `BLZ_BOOT`/`BLZ_RENDERED` 真机双标记；razor AOT 计数 0→1→2 | ✅ 真机闭合 |
| 安全 | SEC 收口（探针 pid+nonce、rawfile 路径校验/安全头、Blazor hap 无 INTERNET）；安全扫描 #1–#2 全修、#3 收口（仅余 1 条信息级 S3-IMG1 图片残余）；DEVCOMPAT-DEFAULT（enforcing 7.0.0.111 开箱可装） | ✅ 已闭环（余 1 信息级） |
| 构建链 | rc.2 主线（SDK `.112` / workload `.28` / MAUI `rc2.26478.12`）；msbuild-pipe-patch + Roslyn server 覆盖；AOT pack 结构修复（struct1）；`commit-paths.sh` 精确路径提交、禁强推 | ✅ 闭环（csc 活锁见 §5） |

## 4. 外部项（本地不可闭合；2026-10-08 口径）

1. **tester 轮**：kit #53 交接 + `tester-round-kit53.tar.gz` 已交付，等测试方回传（主判 = a11y selfcheck `nodes=10` / B6 子窗导航否决 / N=2 全链 / 门禁 737/740·164；预签按 tester UDID 直装）。
2. **AGC**：ACL 申请包（正文 / 技术附件 / 提交顺序）就绪，待账号侧提交；App Linking 域名登记 + `domainVerify` 部署 + 真机 https 投递待办。
3. **上游**：A1 拆分完成——#132827 的 NamedMutex 部分已开 **dotnet/runtime#135321**（基于 main `b08c345c912`），告知评论已发；`#132827`（余 SharedMemoryManager + 测试）与 `#132953`/`#132866` 等仍 open；17 支 `pr/*` 重锚演练就绪。
4. **rc.2 正式 pin**：MAUI `11.0.0-rc.2.26478.12` 仍走 dnceng daily feed；**监测记录（最近复核沿用 2026-10-07，`rc2-official-watch.sh` exit 0）**：`status: WAIT`——nuget 四包 latest `11.0.0-rc.1.26451.6`（trigger=no）、GitHub `11.0.100-rc.1.26458.5`（trigger=no）；官方发布后按 rc2-align-runbook 换 pin、删 feed step。

## 5. 已知限制

- 验证面：单设备（2in1 / API 26）· debug 签名域；release 域、手机域、跨重启、坚盾模式未测。
- 多覆盖层并发槽上限 **N=2**；第 3 个控件走 LRU 抢占/恢复（非真并发，恢复为重放）；L3 子窗槽池 Max=2、平台 255 仅探针观测（2in1 debug，不外推）；子窗 a11y 动作 e2e / IME 实敲 / hybrid-blazor 真机需外部环境；N=2 为壳契约。POST-L3（#53）：a11y selfcheck 首发布已修（`nodes=10` ×2 + 关/重开稳定）、B6 子窗导航否决已接通（deny/ok 真机双链；`//host` 样例受限）；同槽 hybrid invoke fail-closed、池满不挂载沿降级。
- VBCSCompiler/csc 并行活锁：watchdog（`scripts/ohos-csc-watchdog.sh`，VBCS server 覆盖 `cac0e0b2b08`）+ 根因定位**进行中**（rc.2 线 #52 在途；`DOTNET_PROCESSOR_COUNT=1` 仍为绕过）；空闲 keep-alive 不误杀已验证；**SIGSTOP 注入窗未捕获**（2026-10-04 补测：降载窗口 12/12 落回 csc——重跑：scratch `csc-watchdog-vbcs/` 下 `VBCS_E2E_ONLY=3 python3 vbcs-e2e.py`，或 `sh inject-until-pass.sh`）。
- SOAK：SOAK2（三路径 45 min/路径）已结——0 崩/0 冻结/0 重启；#51 AOT 发版浸泡 SOAK51（40 min、41 采样、pid 恒定、0 fault/0 重启）通过（`2026-10-03-ohos-three-path-soak-2.md` / `2026-10-07-ohos-device-round-51.md`）；#52 N=2 双窗浸泡（L3-M4 40 min、RSS 284–363 MB 无单调增长、线程 70–71、0 crash/fault）通过（`2026-10-07-ohos-l3-m4.md`）；#53 AOT 双窗 web 浸泡（40 min、41 采样、pid 恒定、0 fault/0 重启）通过（`2026-10-08-ohos-device-round-53.md`）。

## 6. 历史快照（不随当前行改动；早于 #42 的轮次见各交接文）

| 轮次 | 发布 tar / 树 | 套件 | 导出 | abc（sha 前 8） | bundle（sdk 锚） |
|---|---|---|---|---|---|
| #52 | 68,853,027 / `9e60fdc0…` / `d10ae2e7…` | 731/734 floor 714 | 164/164 | 534,192（`e6516424…`） | 73,199,515 / `5a00331f…`（`9609da7a47`） |
| #51 | 68,550,333 / `e5f6541c…` / `a06d3897…` | 688/690 floor 670 | 163/163 | 473,048（`298622c0…`） | 73,147,751 / `f4b4fe8d…`（`a00e810c92`） |
| #50 | 68,264,136 / `d70dc786…` / `b4b5055c…` | 661/663 floor 643 | 157/157 | 436,808（`289a5e5d…`） | 73,119,180 / `6a83c0f3…`（`a3417a5489`） |
| #49 | 67,888,851 / `477974bb…` / `8d03cb4c…` | 607/609 floor 589 | 153/153 | 414,532（`e016db13…`） | `7d06e781…`（`7abaf8132f`） |
| #42 | 376,256,128 / `ea4e3b58…` / `13f3a086…` | 578/580 floor 560 | 151/151 | 356,468（`dd04dad1…`） | 73,047,352 / `570c0821…`（`35101fe1f5`） |
