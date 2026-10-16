# OpenHarmony .NET/MAUI 移植终版一览（STATE-OF-PORT，2026-10-03；当前口径 = kit #58 / 2026-10-16）

> 一页纸（≤60 行）：三路径终局（§1）· kit #58 交付与四波（BUNDLE-SWITCH / TOUCH-PASTE-DEFAULT / SECURE-STORAGE-ASSET / CLIPBOARD-ACL）+ kit #57 全量（§2）· 修复全景（§3）· 外部项（§4）· 已知限制（§5）· 历史快照（§6）。
> 当前数字 = release「## Integrity（kit #58）」与随包校验；已与 FINAL（`2026-10-05-ohos-maui-completion-verdict.md`「kit #58 终态」）、`2026-10-16-ohos-tester-handoff-kit58.md` 交叉一致。**#58 波 = BUNDLE-SWITCH（bundle `mauidemo.dotnet.springmin.com` = AGC 应用 = 发布 Profile；壳 abc 637,300/`4070204a…`、headless 24,340/`944529ae…`；五包同源；宿主 375,712/`1e156f42…`，导出 167/167）+ TOUCH-PASTE-DEFAULT（触屏粘贴默认开 + opt-out）+ SECURE-STORAGE-ASSET（Asset Store 后端 + FailClosed 默认 true）+ CLIPBOARD-ACL（`READ_PASTEBOARD` Acl-gated，默认/all 不含）+ kit #57 全量（官方 rc.2 重切 `.105`/`.29` + 三卡；maui `44da5f74f5` / ow `83ee7d0`）**；实测：kit tar **70,449,999 / `d7e3311b…`**、树 `25f3159a…`、bundle 重打包 **46,368,700 / `8772ef23…`**（sdk-ohos 锚 `def202206b`；`ohos-install-tests` CI 绿）；设备冒烟 = 预签通道全绿 + **release-signed 主 hap `9568322 not trusted app source` 边界（如实记录）**；详见 `2026-10-16-ohos-tester-handoff-kit58.md`。
> kit #57 旧数字（历史）：release「## Integrity（kit #57）」（tar **70,428,755 / `bc0e8c47…`**、bundle 复用 **46,365,380 / `21e2d128…`**（sdk 锚 `49df3e8220`）；官方 rc.2 重切 `.105`/`.29` + JIT/interp 件与三卡）。
> kit #56 旧数字（历史）：release「## Integrity（kit #56）」；旧描述行保留于下方历史节。**#56 波 = rc.2 官方包对齐（RC2-ALIGN）+ ENG-WAVE（loopback/fail-closed）+ TOUCH-PASTE**（maui `1c5ff3cbeb` / ow `cc6ca34`；详见 `2026-10-14-rc2-official-release-assessment.md`、`2026-10-13-ohos-touch-paste.md`、`2026-10-13-ohos-eng-wave-consolidation.md`）；**下一刀 = 待定触发**（RC2-OFFICIAL 官方戳重切为候选）。证据/明细见各专题报告（README 索引置顶行指向本页）。
> 历史节（§1 表、§3 表、§6 快照）按快照保留；旧轮判定点继续有效。

## 1. 三路径终局（kit #42 基线；机制与定位未变）

同一 2in1 / API 26 / debug 签名域；冷启 payload→canvas ≈3.2 s（三路径同档）；AOT/JIT = 60 fps vsync（呈现:回调 1:1、零丢帧），interp ≈21 fps。

| 路径 | 定位与边界 | 关键数字 |
|---|---|---|
| **AOT（推荐默认）** | 出包/分发默认（`--runtime-mode aot`；kit 根 + 每 hap `runtime-mode.txt=aot`）；release 域/手机域/坚盾模式唯一形态 | RSS 比 JIT **−74.8 MB（15 s）/ −84.1 MB（42 s）**；首帧 3534 ms、`jitfort: skipped`、`canvas presented` 765、0 崩 |
| **JIT（性能形态）** | `prctl(0x6a6974)` JITFORT 默认开 + 无 ICU 自动 invariant → **首帧**；debug/内测域免 ACL；release 域需 AGC ACL（`ALLOW_WRITABLE_CODE_MEMORY`，2in1/平板）或厂商豁免，否则回落 AOT | `jitfort rc=0 errno=0 state=off`、探针 `1=OK 2=OK`、8/8 race=0、60.00 fps |
| **interp（实验）** | rc2b pack 独立分发，不进主包；**渲染受限** | 首帧 `canvas presented (2090x1324)`；21.47 fps（渲染+呈现 32 ms/帧，平台量化到 ~50 ms） |

## 2. 交付（当前 = kit #58；#42–#57 快照见 §6）

- 发布：tar **70,449,999 / `d7e3311b…`** · 树 **`25f3159a…`** · sidecar **`0da48a97…`**（89 B）· `SHA256SUMS` 18 项；bundle **重打包 46,368,700 / `8772ef23…`**（sdk 锚 **`def202206b…`**；`workload-1.0.0-preview.29` / `workload-latest` / SDK `.105 -ohos` 三处同值；rc.2 线 `.105`/`.29`）。
- 件/门禁：abc **637,300 / `4070204a…`** · headless **24,340 / `944529ae…`** · 宿主 **375,712 / `1e156f42…`**（导出 **167/167**）；套件 **826/829 floor 809**；权限矩阵 默认 **1**（INTERNET）/ permissions 件 **6** / `all` **8 非 ACL**；7 hap = 5 MAUI 全 AOT + Blazor 默认 / `-nocsp`；构建位 `~/.dotnet.rc2-105`（SDK `11.0.100-rc.2.26504.105` / workload `1.0.0-preview.29` / MAUI **官方 `26505.5`**）。
- 预签（#58）：**70,256,405 / `3dc2f08e…`**（asset 646181985；sidecar 88 B / `e3788ce4…`，asset 646183845）；**release-signed 主 hap（免 UDID）23,773,854 / `667e319b…`**（真机 `9568322 not trusted app source` 平台边界，如实记录；预签 debug 通道照旧）；轮包 `tester-round-kit58.tar.gz`（**214,609,739 / `3786f30c…`**，asset 646211333 + sidecar 646214775）；证据归档 `kit58-evidence-20261016.tar.gz`（108,772 / `a2a4c08f…`，asset 646216133 + sidecar 646216578）。
- 并列资产（保持未动）：rc2b interp pack `5974430509…`（asset 606999003）；`-struct1` AOT pack 28,905,116 / `09345f95…`（asset 607541145）；Crossgen2 rc.2 43,792,647 / `6bb8a375…`。
- **#58 波主题（BUNDLE-SWITCH + 三波功能项 + kit #57 全量）**：**BUNDLE-SWITCH**（demo/脚本/套件/五包壳 abc 全线切到 `mauidemo.dotnet.springmin.com` = AGC 应用 = 发布 Profile；ui abc **637,300/`4070204a…`**、headless **24,340/`944529ae…`**；Blazor/razor/wasm 样例 bundle 保持；发布通道 = `sign-for-device.sh --release` 免 UDID）· **TOUCH-PASTE-DEFAULT**（触屏粘贴入口默认开；opt-out = `touch-paste.disabled` / `OHOS_TOUCH_PASTE=0`）· **SECURE-STORAGE-ASSET**（新写入优先 Asset Store（`a1:` 索引 + `k1:` HUKS 二链；旧数据零迁移可读），**FailClosed 默认 true**（双强链失败 Set 抛错不落盘；显式 opt-out 才弱存）；宿主重建 375,712/`1e156f42…`、导出 164→167）· **CLIPBOARD-ACL**（`READ_PASTEBOARD` 改 Acl 标记特征：默认/all 不含；显式 `clipboard` 才声明，需 ACL profile）+ **承 kit #57 全量**（官方 rc.2 重切 `.105`/`.29` + JIT/interp 件与三卡（CG2-R2R / AOT-STARTUP / FIXRR，按文本沿用）；承 kit #56：rc.2 官方包对齐 / TOUCH-PASTE / WEBAUTH-LOOPBACK / SECURE-STORAGE-FAILCLOSED）。**降级/人工卡**：a11y 动作 e2e 平台限 · 实键盘敲击人工卡 · Back 平台路由边界 · 弹窗无托管树/面 · DRM 无 · >64 MiB 无 Range · 子窗池 2 槽 · SEC-5c·6 余留（有界） · 应用级 N=4 壳契约（平台 255） · **api20 镜像级边界** · **clipboard 真读=ACL（ACL 物料待 AGC 批准；触屏用户粘贴已由 PasteButton 默认开闭环）** · **release-signed 真机安装 = `9568322` 发布源信任边界（如实记录）** · 2in1 debug 域。

## 3. 修复全景（#42 基线落地表；#43–#54 增量见 §2 与各交接文）

| 域 | 代表修复 | 状态 |
|---|---|---|
| 渲染族 | FIX-HOME / FIX-ITOUCH / FIX-DISMISS / FIX-BACKSIZE / FIX-WVP / FIX-SLICERACE；FRAMEPACING 归因「17.7 fps = 壳状态轮询伪影，真实 60.00 fps」 | ✅ 真机闭合 |
| WebView 族 | FIX-WVP（覆盖层出画/bridge/挂起）+ FIX-BWVMount + FIX-JSCALL + MULTI-OVERLAY-FULL（N=2 槽池 + owner LRU）+ ZORDER-NAV（重叠置顶 97.2% 翻转） | ✅ 真机闭合 |
| B2（MAUI WebView 承载 Blazor WASM） | WebView 六项接线 + `BLZ_BOOT`/`BLZ_RENDERED` 真机双标记；razor AOT 计数 0→1→2 | ✅ 真机闭合 |
| 安全 | SEC 收口（探针 pid+nonce、rawfile 路径校验/安全头、Blazor hap 无 INTERNET）；安全扫描 #1–#2 全修、#3 收口（仅余 1 条信息级 S3-IMG1 图片残余）；DEVCOMPAT-DEFAULT（enforcing 7.0.0.111 开箱可装） | ✅ 已闭环（余 1 信息级） |
| 构建链 | rc.2 主线（SDK `.112` / workload `.28` / MAUI `rc2.26478.12`）；msbuild-pipe-patch + Roslyn server 覆盖；AOT pack 结构修复（struct1）；`commit-paths.sh` 精确路径提交、禁强推 | ✅ 闭环（csc 活锁见 §5） |

## 4. 外部项（本地不可闭合；2026-10-11 口径）

1. **tester 轮**：kit #58 交接 + `tester-round-kit58.tar.gz` 已交付（含预签 + release-signed 主 hap + 三卡说明），等测试方回传（主判 = BUNDLE-SWITCH 复核 / TOUCH-PASTE-DEFAULT / SECURE-STORAGE-ASSET / CLIPBOARD-ACL + release-signed 接受性（本机 9568322 边界待外部环境再评）+ 承 #57 三卡 / #56 全部判定点；预签按 tester UDID 直装）。
2. **AGC**：ACL 申请包（正文 / 技术附件 / 提交顺序）就绪，待账号侧提交；App Linking 域名登记 + `domainVerify` 部署 + 真机 https 投递待办。
3. **上游**：A1 拆分完成——#132827 的 NamedMutex 部分已开 **dotnet/runtime#135321**（基于 main `b08c345c912`），告知评论已发；`#132827`（余 SharedMemoryManager + 测试）与 `#132953`/`#132866` 等仍 open；17 支 `pr/*` 重锚演练就绪。
4. **rc.2 正式 pin（✅ 已切 2026-10-14）**：MAUI 四包 → 官方 `11.0.0-rc.2.26505.5`（maui 切片 `1c5ff3cbeb`、ow `a914a15`；三 workflow pin + dispatch 默认随动，interaction/pixel dnceng feed step 已删；Blazor flight 同步换官方 `11.0.0-rc.2.26504.105`）；覆写此前的 `status: WAIT`（历史记录：2026-10-10 复核 nuget 四包 latest `11.0.0-rc.1.26451.6`（trigger=no）、GitHub `11.0.100-rc.1.26458.5`（trigger=no））。触发/落地记录见 `ohos-workload/docs/rc2-official-watch.md` 与 rc2-align-runbook 头注；下一刀 = 官方戳重切（`2026-10-14-rc2-official-release-assessment.md`）。

## 5. 已知限制

- 验证面：单设备（2in1 / API 26）· debug 签名域；release 域、手机域、跨重启、坚盾模式未测；**release-signed 件在本镜像被 `9568322 not trusted app source` 拒绝（发布源信任边界，2026-10-16 实测，如实记录）**。
- 多覆盖层默认 **8 槽**（E4；`OHOS_OVERLAY_MAX` 可下调 2..8；第 9 个控件走 LRU 抢占/恢复，非真并发·恢复为重放）；子窗默认 **4**（`OHOS_SUBWINDOW_MAX` 2..8；第五窗诚实拒绝；平台上限 255 仅探针观测，2in1 debug 不外推）；子窗槽池 Max=2、弹窗会话无托管树/面、子窗+模态组合未上机；子窗 a11y 动作 e2e / IME 实敲需外部环境；POST-L3（#53）照旧（a11y selfcheck `nodes=10` ×2 + 关/重开稳定、B6 deny/ok 真机双链；`//host` 样例受限）；应用级 N=4 为壳契约、同槽 hybrid invoke fail-closed、池满不挂载沿降级。
- VBCSCompiler/csc 并行活锁：watchdog 已并入 preflight 防呆（`run-with-csc-watchdog.sh`：spin 480s → 杀卡死链 → `DOTNET_PROCESSOR_COUNT=1` 重跑一次、二次仍卡 fail-closed；selftest 34/34；runtime 侧 `scripts/ohos-csc-watchdog.sh`，VBCS server 覆盖 `cac0e0b2b08`）；根因定位**进行中**；空闲 keep-alive 不误杀已验证；**SIGSTOP 注入窗未捕获**（2026-10-04 补测：降载窗口 12/12 落回 csc——重跑：scratch `csc-watchdog-vbcs/` 下 `VBCS_E2E_ONLY=3 python3 vbcs-e2e.py`，或 `sh inject-until-pass.sh`）。
- SOAK：SOAK2（三路径 45 min/路径）已结——0 崩/0 冻结/0 重启；#51 AOT 发版浸泡 SOAK51（40 min、41 采样、pid 恒定、0 fault/0 重启）通过（`2026-10-03-ohos-three-path-soak-2.md` / `2026-10-07-ohos-device-round-51.md`）；#52 N=2 双窗浸泡（L3-M4 40 min、RSS 284–363 MB 无单调增长、线程 70–71、0 crash/fault）通过（`2026-10-07-ohos-l3-m4.md`）；#53 AOT 双窗 web 浸泡（40 min、41 采样、pid 恒定、0 fault/0 重启）通过（`2026-10-08-ohos-device-round-53.md`）；#54 AOT 双窗 web 浸泡（40 min、41 采样、pid 恒定、0 fault/0 重启；rev1 字节）通过（`2026-10-11-ohos-device-round-54.md`；rev2 抽验 = `2026-10-11-ohos-kit54-hap-verify.md` §7）；#55 发版抽验（互斥锁独占）= 发布件 digest 对口（asset 637184336）+ kit hap 本机重签安装（labelId=16777217 / iconId=16777231、1 权限 INTERNET、开始菜单渲染、`canvas presented`、0 fault），末态还原（证据 = `2026-10-13-ohos-tester-handoff-kit55.md` 预检回填）；#56 发版抽验（互斥锁独占）= 发布件 digest 对口（asset 639384793）+ kit hap 本机重签安装（launcher 身份 / 主窗 `canvas presented` / 0 fault），末态还原（证据 = `2026-10-14-ohos-tester-handoff-kit56.md` 预检回填）。

## 6. 历史快照（不随当前行改动；早于 #42 的轮次见各交接文）

| 轮次 | 发布 tar / 树 | 套件 | 导出 | abc（sha 前 8） | bundle（sdk 锚） |
|---|---|---|---|---|---|
| #55 | 70,312,042 / `504ea1ae…` / `005cfecb…` | 801/804 floor 784 | 164/164 | 620,908（`c473b7be…`） | 73,468,932 / `8aa53b67…`（`cd5bee91dc`） |
| #54 | 70,345,291 / `583d6df4…` / `094165d7…` | 796/799 floor 779 | 164/164 | 623,784（`58c5829b…`） | 73,465,150 / `09326398…`（`977be2e31b`） |
| #53 | 68,883,057 / `dba88961…` / `47ace1d0…` | 737/740 floor 720 | 164/164 | 542,936（`f18f0855…`） | 73,213,144 / `031ba342…`（`64f239eb28`） |
| #52 | 68,853,027 / `9e60fdc0…` / `d10ae2e7…` | 731/734 floor 714 | 164/164 | 534,192（`e6516424…`） | 73,199,515 / `5a00331f…`（`9609da7a47`） |
| #51 | 68,550,333 / `e5f6541c…` / `a06d3897…` | 688/690 floor 670 | 163/163 | 473,048（`298622c0…`） | 73,147,751 / `f4b4fe8d…`（`a00e810c92`） |
| #50 | 68,264,136 / `d70dc786…` / `b4b5055c…` | 661/663 floor 643 | 157/157 | 436,808（`289a5e5d…`） | 73,119,180 / `6a83c0f3…`（`a3417a5489`） |
| #49 | 67,888,851 / `477974bb…` / `8d03cb4c…` | 607/609 floor 589 | 153/153 | 414,532（`e016db13…`） | `7d06e781…`（`7abaf8132f`） |
| #42 | 376,256,128 / `ea4e3b58…` / `13f3a086…` | 578/580 floor 560 | 151/151 | 356,468（`dd04dad1…`） | 73,047,352 / `570c0821…`（`35101fe1f5`） |
