# 不支持项逐条复核（UNSUPPORTED-RECHECK，2026-10-11）

> 口径：只读复核（文档/提交证据；不构建、不用设备、不处理上游 PR）。主线 = ow `04d1606` · maui `54631780a3`；套件 **788/791 floor 771**、abc **602,744/`d32981e6…`**/24,324、导出 **164/164**（#54 预刷；kit 未切，发布件仍 #53）。
> 输入：`2026-10-05-ohos-platform-limitations.md`（A–E）· `2026-09-22-ohos-maui-coverage-matrix.md` · `2026-10-10-ohos-maui-remaining-audit.md` · `2026-10-03-ohos-state-of-the-port.md` · 各 handoff 降级/人工卡。分类 = **翻案** / **部分** / **仍不支持·接受（含维持）** / **测试侧** / **外部** / **并行中**（原并行中 1 项由 `2026-10-11-ohos-media-micro-boundaries.md` 落档为翻案）。

## 1. 逐条现态（去重 32 条 = 翻案 14 · 部分 6 · 仍不支持/接受 7 · 测试侧 1 · 外部 4 · 并行中 0）

| 条目 | 旧声明 | 现态 | 证据 / 处置 |
|---|---|---|---|
| `C1 播放（MediaElement）` | 需外部（镜像无 MediaKit；未验） | **翻案（CEF 承载）**：ArkWeb overlay `<video>` 真机 H.264/AAC 播完 + pause/seek/volume/mute + 槽释放 | `-mediaelement-arkweb.md`（A-M1，10-10 并线） |
| `C1 子窗/HLS` | 子窗无媒体服务→Failed；HLS 须 MSE+hls.js | **翻案**：子窗 media 服务（复用 child web 会话/槽回收）+ 内置 hls.js 1.7.3（MSE/原生回退）；真机子窗播完 + 本地 CMAF 30.0 s 播完 | `-media-subwin-hls.md`（B-M1，2026-10-11，ow `04d1606`） |
| `C1 弹窗媒体 / m3u8 Range` | 弹窗无媒体；rawfile·file m3u8 无 Range/改写 | **翻案（MEDIA-MICRO）**：弹窗 Web 手势 opt-out（仅弹窗页自身媒体，无托管映射）；`/__src__` 单区间 206/416 + 注册播放列表 sibling + `hls=1`/stamp 路由（本地分段与单文件 byte-range 真机播至 ended） | `2026-10-11-ohos-media-micro-boundaries.md`（ow `1d7ec00`） |
| `C1 本体/DRM/MPEG-4P2/modal 像素` | 无 MediaKit；DRM 无声明；MPEG-4P2 不支持；modal overlay 像素未出画 | **仍不支持/余**：原生 Kit 路径需 HMS；EME/MPEG-4P2 无；modal 像素待复现（功能链不受影响） | Q1 探针；A-M1 §4；需 HMS 设备 |
| `C5 裸 # 截断` | 需外部（平台共性） | **翻案**：壳侧 `#`→`%23`（主+子）并线 + 真机 A/B；平台根因 = data: URL 解析 | `-l3l4-harden.md`；套件 pin；10-11 复核维持 |
| `B1 a11y 读屏动作` | 需外部（第三方服务无法启用） | **仍外部**：发布/自检链已证（nodeCount 1→70、W0/W2、`nodes=10` ×2）；动作 e2e 需读屏环境/tester | `-a11y-client.md`；handoff53 §2 |
| `E3 arm32` | PARKED（无设备/工具链） | **仍不支持**：只发 arm64/x64 | `2026-09-21-ohos-arm32-support-gap.md` |
| `E4 覆盖层容量` | 默认 4/2；8 未并；"平台 >4" 嫌疑 | **翻案**：定因 = 壳 bug（18 表硬编码 4）；修复后 8 槽全挂；**默认 8 并线**（开关可下调 2..8） | `-e4-attach-rootcause.md`/`-overlay-capacity8.md`/`-batch-consolidate.md` §3 |
| `E5② hybrid 样例` | 真机样例缺（离线绿） | **翻案**：`test/hello-maui-hybrid` 并线 + JIT/AOT 真机 PASS（B6 deny/ok/veto） | `-hybrid-sample.md`/`-l8-remainder.md` §3；ow `cf4b944` |
| `E5② 多窗同槽 invoke` | fail-closed | **翻案（设计内）**：按 `(windowIndex,slot)` 路由——两窗同 slot 各回各窗；未知窗/未领槽 fail-closed | `-l3-m4.md` §1；handoff53 口径保守 |
| `E5③ N 子窗上限` | N=2 壳契约 | **部分**：平台 255；应用默认 2、**可配 4**（`OHOS_SUBWINDOW_MAX`/rawfile；defer 重放，四窗真机） | `-n-subwindow-plan.md` §8/`-l7-m2.md`；默认不抬 |
| `E5④ export=False` | 加载器层根因未追 | **翻案**：根因 = 简单 `NativeLibrary` 重载误用（非加载器 bug）；PREPROBE 清除已并线 | `-a11y-export-rootcause.md`/`-preprobe-merge.md` |
| `E5④ IME/uitest/B6 //host` | 人工卡/注入限制 | **测试侧·已复核（2026-10-11）**：IME op6 直点链真机捕获（click 子窗 Entry→`show=1`）；Back=平台路由边界（keycode 2 达子窗但 `onBackPress` 不触发、`consumed:0`）；B6 `//host` 干净点选（`about:blank#blocked`、0 ask/cmd/批准） | `2026-10-11-ohos-uitest-inject.md`；handoff53 §2/§7 |
| `E5⑤ B6 导航否决` | #52 时未接 | **翻案**：已接；真机 deny/ok 双链 + veto | `-l3-b6-modes.md`；#53 起随包 |
| `E5⑤ 池满/队列溢出` | >2 控件不挂载、丢 1 行日志 | **接受（设计）**：子窗 child 池每窗 2 槽；满→Failed 不抛 | B-M1 §1；`-l3-m2.md` |
| `E5⑥/⑦ SEC-6 常驻 + SEC-5c B–F` | 常驻（有界）/报告级 | **接受**（不变） | `-security-scan-6.md`/`-security-scan-5c.md` |
| `E2 WebView 弹窗` | `onWindowNew` 未接；弹窗不可用 | **翻案**：L8-POPUP 弹窗子窗（`web:N`、容量同源、`onWindowExit` 关窗）已并线，待 #54 随包 | `-l8-popup.md`；余 = 同名复用非前置 `onActivateContent` |
| `矩阵 #12 WebAuthenticator` | 部分（FeatureNotSupported） | **翻案**：真流程（activation 回调/清单注入）+ 隐式 skill 投递真机 PASS | `-webauthenticator.md`/`-webauth-implicit.md`；并线 `cd73bc7` |
| `深链新页不落地（回归）` | 45 s 不落地（10-09 回归） | **翻案**：`RequestNavigation` 补 `Mark()`；真机 0 s 落地 | `-deeplink-regression.md`；并线 `4236f0b` |
| `L8 余项 postMessage/模态` | 弹窗 writer/模态不出画 | **翻案**：writer 占位符 + modal `RootView` 渲染修复并线；真机双向/落地 | `-l8-remainder.md` |
| `harmony-flavor workflow` | 自 10-05 红 | **翻案**：`FreeWindowProbe` 运行时探测；dispatch 绿 | `-harmony-flavor-fix.md`；B-M1 注 run 绿 |
| `D3 csc 活锁` | watchdog 缓解；SIGSTOP 窗未覆盖 | **部分**：watchdog 集成进 preflight（杀 spin→`DOTNET_PROCESSOR_COUNT=1` 重跑）；SIGSTOP 窗仍余 | `-csc-watchdog.md`（并线 `55044da`） |
| `TTS` | 平台阻塞（默认 SDK 无 Kit） | **部分**：harmony flavor 链路落地（CoreSpeechKit→hms TTS）；默认降级不抛；真机朗读需 HMS | 矩阵 §4；`-kit-gap-analysis.md` |
| `Map` | 平台阻塞 | **部分**：能力探测 + MapComponent overlay（需 harmony flavor + AGC AppKey）；默认降级 | 矩阵 §4 |
| `Share 面板` | 平台阻塞（无 systemShare） | **部分**：多文件 Share Kit 分支落地；系统面板需 HMS；默认 no-op+状态 | 矩阵 §4/§2 |
| `Hot Reload` | hdc 策略硬阻塞 | **仍不支持**：`devloop.sh` 替代已交付 | 矩阵 §4 |
| `A3–A5 JIT 合规` | 需外部（ACL/隐藏 prctl） | **仍外部**：发布件 AOT；ACL 材料包待提交；手机域仅 AOT | limits A3–A5；AGC |
| `E1 单设备/域` | 需外部 | **仍外部**：2in1 debug 域；手机/release 不外推 | limits E1 |
| `rc.2 正式包` | WAIT | **外部**：监测 WAIT（nuget/GitHub rc.1）；#54 待切 | `-maui-remaining-audit.md` §3 |
| `A1/A2/A6、C2–C4、D1/D2/D4–D6` | 限制表各行 | **维持**（已缓解/接受；行内无翻案） | limits A/C/D 各页 |
| `矩阵 #11 键盘焦点 / #18 ship-the-slice` | 部分（上游 rc.2/上游并入） | **仍部分（上游）** | `-coverage-gap-audit.md` #11/#18 |
| `宿主导出 164/164` | 门禁 | **维持**：A-M1/B-M1/N-4/弹窗均未改宿主导出 | 各 batch 门禁/`--cross-check` |

## 2. 文档更新 / 提交 / 不确定

- 更新：`2026-10-05-ohos-platform-limitations.md`（C1/C5/B1/D3/E2/E4/E5 行 + 头注复核行 + tester 段）；`2026-09-22-ohos-maui-coverage-matrix.md` 与 `2026-10-10-ohos-maui-remaining-audit.md` 加 1 行复核指针（正文未重写）；`docs/plans/README.md` 索引 +1 行。
- 提交：本文件 + 上述 4 文件 → runtime `feature/openharmony`（`commit-paths.sh` 限路径；直推，被拒 fetch/rebase + 旁路钉 `140.82.113.3`，不 force）；MD009=0（markdownlint）。
- 不确定：并行媒体微边界（弹窗媒体、m3u8 Range）未落档；modal overlay 像素未复现；handoff53 同槽口径保守（以 L3-M4 为准）；#54 kit 未切、发布件仍 #53；设备项以现有证据判（本 session 不触设备）。
