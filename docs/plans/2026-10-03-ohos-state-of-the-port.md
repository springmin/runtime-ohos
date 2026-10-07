# OpenHarmony .NET/MAUI 移植终版一览（STATE-OF-PORT，2026-10-03；当前口径 = kit #51 / 2026-10-07）

> 一页纸（≤60 行）：三路径终局（§1）· kit #51 交付与 L2（§2）· 修复全景（§3）· 外部项（§4）· 已知限制（§5）· 历史快照（§6）。
> 当前数字 = release「## Integrity（kit #51）」与随包校验；已与 FINAL（`reg-kit51/RELEASE-VALUES.txt`）、`2026-10-07-ohos-l2-consolidate.md`、`2026-10-07-ohos-tester-handoff-kit51.md` 交叉一致。证据/明细见各专题报告（README 索引置顶行指向本页）。
> 历史节（§1 表、§3 表、§6 快照）按快照保留；旧轮判定点继续有效。

## 1. 三路径终局（kit #42 基线；机制与定位未变）

同一 2in1 / API 26 / debug 签名域；冷启 payload→canvas ≈3.2 s（三路径同档）；AOT/JIT = 60 fps vsync（呈现:回调 1:1、零丢帧），interp ≈21 fps。

| 路径 | 定位与边界 | 关键数字 |
|---|---|---|
| **AOT（推荐默认）** | 出包/分发默认（`--runtime-mode aot`；kit 根 + 每 hap `runtime-mode.txt=aot`）；release 域/手机域/坚盾模式唯一形态 | RSS 比 JIT **−74.8 MB（15 s）/ −84.1 MB（42 s）**；首帧 3534 ms、`jitfort: skipped`、`canvas presented` 765、0 崩 |
| **JIT（性能形态）** | `prctl(0x6a6974)` JITFORT 默认开 + 无 ICU 自动 invariant → **首帧**；debug/内测域免 ACL；release 域需 AGC ACL（`ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）或厂商豁免，否则回落 AOT | `jitfort rc=0 errno=0 state=off`、探针 `1=OK 2=OK`、8/8 race=0、60.00 fps |
| **interp（实验）** | rc2b pack 独立分发，不进主包；**渲染受限** | 首帧 `canvas presented (2090x1324)`；21.47 fps（渲染+呈现 32 ms/帧，平台量化到 ~50 ms） |

## 2. 交付（当前 = kit #51；#42–#50 快照见 §6）

- 发布：tar **68,550,333 / `e5f6541c…`** · 树 **`a06d3897…`** · sidecar **`5c471871…`**（89 B）· `SHA256SUMS` 18 项 / 1,600 B / `5f8c1512…`；bundle **73,147,751 / `f4b4fe8d…`**（sdk 锚 **`a00e810c92`**）。
- 件/门禁：abc **473,048 / `298622c0…`** · headless 24,324 / `798b2477…` · 宿主 **347,040 / `36acfc1d…`**（导出 **163/163**、UND 250）；套件 **688/690 floor 670**；7 hap = 5 MAUI 全 AOT + Blazor 默认 / `-nocsp`；构建线 rc.2（SDK `.112` / workload `preview.28` / MAUI `rc2.26478.12`）。
- 预签（#51）：**68,447,288 / `e9fb1e90…`**（asset 617093322；sidecar 88 B / `96948b04…`，asset 617094016）；测试方单件轮包 `tester-round-kit51.tar.gz`（asset 617151248）。
- 并列资产（保持未动）：rc2b interp pack `5974430509…`（asset 606999003）；`-struct1` AOT pack 28,905,116 / `09345f95…`（asset 607541145）；Crossgen2 rc.2 43,792,647 / `6bb8a375…`。
- **L2 主题（#51）**：a 子窗 a11y provider 与主窗 provider **并存**（per-instance 分区 + `CallbackWithInstance`/带窗动作；导出 157→163；真机 W0 并存 / W2 自检 PASS）+ b 子窗 ArkWeb child web 第二宿主（按窗槽池 + capacity wire 修复；全链 `CHILD WEB TAP`、主窗零回归 60/60 fps）+ L2CAP 容量探针（平台并发上限 **255**、产品级 **N=1 为壳契约**）+ SEC-SCAN-6 A/B/C 全闭。**降级沿用**：a11y 动作 e2e 平台限 · hybrid/blazor 资产桥显式拒绝 · B6 未接 · IME 人工卡 · 池满/队列溢出 · `loadData` 裸 `#` 截断 · 原生 a11y 分区常驻（有界）。

## 3. 修复全景（#42 基线落地表；#43–#51 增量见 §2 与各交接文）

| 域 | 代表修复 | 状态 |
|---|---|---|
| 渲染族 | FIX-HOME / FIX-ITOUCH / FIX-DISMISS / FIX-BACKSIZE / FIX-WVP / FIX-SLICERACE；FRAMEPACING 归因「17.7 fps = 壳状态轮询伪影，真实 60.00 fps」 | ✅ 真机闭合 |
| WebView 族 | FIX-WVP（覆盖层出画/bridge/挂起）+ FIX-BWVMount + FIX-JSCALL + MULTI-OVERLAY-FULL（N=2 槽池 + owner LRU）+ ZORDER-NAV（重叠置顶 97.2% 翻转） | ✅ 真机闭合 |
| B2（MAUI WebView 承载 Blazor WASM） | WebView 六项接线 + `BLZ_BOOT`/`BLZ_RENDERED` 真机双标记；razor AOT 计数 0→1→2 | ✅ 真机闭合 |
| 安全 | SEC 收口（探针 pid+nonce、rawfile 路径校验/安全头、Blazor hap 无 INTERNET）；安全扫描 #1–#2 全修、#3 收口（仅余 1 条信息级 S3-IMG1 图片残余）；DEVCOMPAT-DEFAULT（enforcing 7.0.0.111 开箱可装） | ✅ 已闭环（余 1 信息级） |
| 构建链 | rc.2 主线（SDK `.112` / workload `.28` / MAUI `rc2.26478.12`）；msbuild-pipe-patch + Roslyn server 覆盖；AOT pack 结构修复（struct1）；`commit-paths.sh` 精确路径提交、禁强推 | ✅ 闭环（csc 活锁见 §5） |

## 4. 外部项（本地不可闭合；2026-10-07 口径）

1. **tester 轮**：kit #51 交接 + `tester-round-kit51.tar.gz` 已交付，等测试方回传（主判 = 子窗 a11y 并存 / child web 链 / 门禁 688/690·163；预签按 tester UDID 直装）。
2. **AGC**：ACL 申请包（正文 / 技术附件 / 提交顺序）就绪，待账号侧提交；App Linking 域名登记 + `domainVerify` 部署 + 真机 https 投递待办。
3. **上游**：A1 拆分完成——#132827 的 NamedMutex 部分已开 **dotnet/runtime#135321**（基于 main `b08c345c912`），告知评论已发；`#132827`（余 SharedMemoryManager + 测试）与 `#132953`/`#132866` 等仍 open；17 支 `pr/*` 重锚演练就绪。
4. **rc.2 正式 pin**：MAUI `11.0.0-rc.2.26478.12` 仍走 dnceng daily feed；**监测记录（2026-10-07，`rc2-official-watch.sh` exit 0）**：`status: WAIT`——nuget 四包 latest `11.0.0-rc.1.26451.6`（trigger=no）、GitHub `11.0.100-rc.1.26458.5`（trigger=no）；官方发布后按 rc2-align-runbook 换 pin、删 feed step。

## 5. 已知限制

- 验证面：单设备（2in1 / API 26）· debug 签名域；release 域、手机域、跨重启、坚盾模式未测。
- 多覆盖层并发槽上限 **N=2**；第 3 个控件走 LRU 抢占/恢复（非真并发，恢复为重放）；L2 子窗槽池 Max=2、平台 255 仅探针观测（2in1 debug，不外推）；子窗 a11y 动作 e2e / IME 实敲需外部环境。
- VBCSCompiler/csc 并行活锁：watchdog（`scripts/ohos-csc-watchdog.sh`，VBCS server 覆盖 `cac0e0b2b08`）+ 根因定位**进行中**（rc.2 线 #51 在途；`DOTNET_PROCESSOR_COUNT=1` 仍为绕过）；空闲 keep-alive 不误杀已验证；**SIGSTOP 注入窗未捕获**（2026-10-04 补测：降载窗口 12/12 落回 csc——重跑：scratch `csc-watchdog-vbcs/` 下 `VBCS_E2E_ONLY=3 python3 vbcs-e2e.py`，或 `sh inject-until-pass.sh`）。
- SOAK：SOAK2（三路径 45 min/路径）已结——0 崩/0 冻结/0 重启；#51 AOT 发版浸泡 SOAK51（40 min、41 采样、pid 恒定、0 fault/0 重启）通过（`2026-10-03-ohos-three-path-soak-2.md` / `2026-10-07-ohos-device-round-51.md`）。

## 6. 历史快照（不随当前行改动；早于 #42 的轮次见各交接文）

| 轮次 | 发布 tar / 树 | 套件 | 导出 | abc（sha 前 8） | bundle（sdk 锚） |
|---|---|---|---|---|---|
| #50 | 68,264,136 / `d70dc786…` / `b4b5055c…` | 661/663 floor 643 | 157/157 | 436,808（`289a5e5d…`） | 73,119,180 / `6a83c0f3…`（`a3417a5489`） |
| #49 | 67,888,851 / `477974bb…` / `8d03cb4c…` | 607/609 floor 589 | 153/153 | 414,532（`e016db13…`） | `7d06e781…`（`7abaf8132f`） |
| #42 | 376,256,128 / `ea4e3b58…` / `13f3a086…` | 578/580 floor 560 | 151/151 | 356,468（`dd04dad1…`） | 73,047,352 / `570c0821…`（`35101fe1f5`） |
