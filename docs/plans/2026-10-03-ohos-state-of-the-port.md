# OpenHarmony .NET/MAUI 移植终版一览（STATE-OF-PORT，2026-10-03）

> 一页纸（≤60 行）：三路径终局 · kit #42 交付 · 修复全景 · 外部项 · 已知限制。
> 数字以 release「## Integrity（kit #42）」与随包校验为准；证据/明细见各专题报告（README 索引置顶行指向本页）。

## 1. 三路径终局

同一 2in1 / API 26 / debug 签名域；冷启 payload→canvas ≈3.2 s（三路径同档）；AOT/JIT = 60 fps vsync（呈现:回调 1:1、零丢帧），interp ≈21 fps。

| 路径 | 定位与边界 | 关键数字 |
|---|---|---|
| **AOT（推荐默认）** | 出包/分发默认（`--runtime-mode aot`；kit 根 + 每 hap `runtime-mode.txt=aot`）；release 域/手机域/坚盾模式唯一形态 | RSS 比 JIT **−74.8 MB（15 s）/ −84.1 MB（42 s）**；首帧 3534 ms、`jitfort: skipped`、`canvas presented` 765、0 崩 |
| **JIT（性能形态）** | `prctl(0x6a6974)` JITFORT 默认开 + 无 ICU 自动 invariant → **首帧**；debug/内测域免 ACL；release 域需 AGC ACL（`ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）或厂商豁免，否则回落 AOT | `jitfort rc=0 errno=0 state=off`、探针 `1=OK 2=OK`、8/8 race=0、60.00 fps |
| **interp（实验）** | rc2b pack 独立分发，不进主包；**渲染受限** | 首帧 `canvas presented (2090x1324)`；21.47 fps（渲染+呈现 32 ms/帧，平台量化到 ~50 ms） |

## 2. 交付（kit #42）

- 发布：tar **376,256,128 / `ea4e3b58…`** · 树 `13f3a086…` · sidecar `878d05a1…` · `SHA256SUMS` 17 项 / 1,517 B / `9ce72b56…`；bundle **73,047,352 / `570c0821…`**（sdk 锚 `35101fe1f5`；dtk 392356147 / latest 392077166；manifest `ed504b85a46`）。
- 件：abc **356,468 / `dd04dad1…`** · headless **24,324 / `798b2477…`** · 宿主 **297,888 / `08abe185…`**；导出 **151/151**；套件 **578 checks / 580 total / floor 560**；7 hap = MAUI 5 + Blazor 默认 / `-nocsp`。
- 并列资产：预签 **376,887,481 / `8f64fd5a…`**（asset 607199769，内容 = kit #42 的 7 hap）；rc2b interp pack **2,410,595 / `5974430509…`**（asset 606999003）；struct1 AOT pack **28,905,116 / `09345f95…`**（asset 607541145；release notes：结构修复后重出，不再需要 `-r2`）。
- AOT 默认：kit #42 本体仍为 JIT 件；AOT-DEFAULT 首个 7-hap 变体为旁路 tar **47,344,695 / `13eb41f2…`**（正式版随下一批量）。

## 3. 修复全景（一行一域；明细见各专题报告）

| 域 | 代表修复 | 状态 |
|---|---|---|
| 渲染族 | FIX-HOME / FIX-ITOUCH / FIX-DISMISS / FIX-BACKSIZE / FIX-WVP / FIX-SLICERACE；FRAMEPACING 归因「17.7 fps = 壳状态轮询伪影，真实 60.00 fps」 | ✅ 真机闭合 |
| WebView 族 | FIX-WVP（覆盖层出画/bridge/挂起）+ FIX-BWVMount + FIX-JSCALL + MULTI-OVERLAY-FULL（N=2 槽池 + owner LRU）+ ZORDER-NAV（重叠置顶 97.2% 翻转） | ✅ 真机闭合 |
| B2（MAUI WebView 承载 Blazor WASM） | WebView 六项接线 + `BLZ_BOOT`/`BLZ_RENDERED` 真机双标记；razor AOT 计数 0→1→2 | ✅ 真机闭合 |
| 安全 | SEC 收口（探针 pid+nonce、rawfile 路径校验/安全头、Blazor hap 无 INTERNET）；安全扫描 #1–#2 全修、#3 收口（仅余 1 条信息级 S3-IMG1 图片残余）；DEVCOMPAT-DEFAULT（enforcing 7.0.0.111 开箱可装） | ✅ 已闭环（余 1 信息级） |
| 构建链 | rc.2 主线（SDK `.112` / workload `.28` / MAUI `rc2.26478.12`）；msbuild-pipe-patch + Roslyn server 覆盖；AOT pack 结构修复（struct1）；`commit-paths.sh` 精确路径提交、禁强推 | ✅ 闭环（csc 活锁见 §5） |

## 4. 外部项（本地不可闭合）

1. **tester 轮**：kit #42 交接 + 复测任务单已交付（主判 = 三路径首帧 + JITFORT）；等测试方回传（预签件、DEVCOMPAT 4096 B 于 7.0.0.105、冷深链）。
2. **AGC**：ACL 申请包（正文 / 技术附件 / 提交顺序）就绪，待账号侧提交；App Linking 域名登记 + `domainVerify` 部署 + 真机 https 投递待办；先试 5 天调试 Profile 做 debug 域验证。
3. **上游评论**：回复草稿 A–C（#132827 / #132953 / #132866）**待用户许可、未发送**；#134670 已上游，`#132827`/`#132953` 仍 open；17 支 `pr/*` 重锚演练就绪。
4. **rc.2 正式 pin**：MAUI `11.0.0-rc.2.26478.12` 仍走 dnceng daily feed；官方上 nuget.org 后换 pin、删 feed step。

## 5. 已知限制

- 验证面：单设备（2in1 / API 26）· debug 签名域；release 域、手机域、跨重启、坚盾模式未测。
- 多覆盖层并发槽上限 **N=2**；第 3 个控件走 LRU 抢占/恢复（非真并发，恢复为重放）。
- VBCSCompiler/csc 并行活锁：watchdog（`scripts/ohos-csc-watchdog.sh`，VBCS server 覆盖 `cac0e0b2b08`）+ 根因定位**进行中**；空闲 keep-alive 不误杀已验证；**SIGSTOP 注入窗未捕获**（2026-10-04 补测：降载窗口 12/12 落回 csc——重跑：scratch `csc-watchdog-vbcs/` 下 `VBCS_E2E_ONLY=3 python3 vbcs-e2e.py`，或 `sh inject-until-pass.sh`）；`DOTNET_PROCESSOR_COUNT=1` 仍为绕过。
- SOAK2（三路径 45 min/路径、独占窗口）**进行中**（AOT 段 0 崩、扰动通过；结论未出，不作发布背书）。
