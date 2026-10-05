# OpenHarmony 平台限制清单（PLATFORM-LIMITS，建议 1 落档，2026-10-05）

> 口径：kit #48（2026-10-05）发布件 + 2026-08→10 真机证据（HAD-W32 / HAD-W24：OpenHarmony 7.0.0.105–7.0.0.111 / API 26 / 2in1）；启动/帧率边界与数字见 kit #48 perf 文（`2026-10-05-ohos-cg2-r2r.md` / `…aot-startup.md` / `…fps48.md` / `…fixrr-consolidate.md`）与 `2026-10-05-ohos-tester-handoff-kit48.md` §2。
> 图例：现状 = **已缓解（随包）** · **需外部**（tester/AGC/上游） · **接受**（设计如此）。证据指针 = `docs/plans/*` · `scripts/*` · scratch（`/data/storage/el2/base/tmp/opencode/*`，未入库）· 五仓提交。
> 用法：本文是判定时的「预期边界」——命中 A–E 的现象先对照本表再判缺陷；tester/AGC/上游要点见末段。

## A. 可执行内存（exec-mem 墙）

| # | 限制 | 实测证据（doc / script / commit） | 影响 | 现状或缓解 |
|---|---|---|---|---|
| A1 | app 域匿名 exec 默认全封：匿名 RWX / RW→RX / RW→RWX 均 `EINVAL(22)`（XPM/JITFORT fortify） | `2026-10-03-ohos-wx-probe-matrix.md` §1–§2（默认 fortify 三路 22；hist 探针 `1=22`）· `2026-09-01-ohos-ondevice-verification.md` §1 | 默认形态下 JIT/解释器无法提交代码内存 → 只能 AOT | **已缓解**：宿主 JITFORT 解锁（A3）+ 发布件默认 AOT（无 JIT 运行时）；探针 `1=OK 2=OK` 后 CoreLib 可装载 |
| A2 | memfd / 文件 RX 恒拒（W^X 合规路径不可用）：memfd `RW→RX`/双映射/seal `13/13/1/13`、签名 `.so` RX `13`、tmpfile RX `1` | 同上矩阵 §2（13 条路无第二条）· `2026-10-03-ohos-wx-patch2-fallback.md`（设备 memfd RX 各域 `13`） | 无法用文件/共享内存形态实现 JIT；双映射预检需降级 | **接受**：`DOTNET_EnableWriteXorExecute=0` + 匿名 RWX 为唯一运行形态；runtime 降级补丁（WX-PATCH2）已在 |
| A3 | JITFORT = 隐藏 `prctl(0x6a6974)`：内核开源树无实现、NDK 无定义、状态非调用者隔离（跨 app 生效） | `2026-10-03-ohos-wx-probe-matrix.md` §3 · `2026-10-03-ohos-jitfort-enable.md` · `2026-10-03-ohos-jit-acl-prerec.md`（MAP_JIT 非解锁通道）· ow `3a4bcbf`（宿主调用） | 依赖未公开接口，不能作为分发合规路径 | **需外部**：宿主默认调用 + `DOTNET_OHOS_NO_JITFORT=1` 逃生；合规路径 = AGC ACL（A5） |
| A4 | release（发布）域 JIT 需华为发布证书 + ACL/豁免：自签 release × JIT 在 `coreclr_initialize` 崩 | `2026-10-04-ohos-release-domain-and-pidloss.md` §2（`managed app` +44 ms、`SIGSEGV(SEGV_ACCERR)` 落 PROT_NONE；scratch `release-domain/`；同 payload debug 域 `jitfort rc=0` 正常） | release/上架件不能开 JIT；不能由自签 release 外推 | **需外部**：发布件默认 AOT；JIT 保形态待 ACL 获批 + 华为发布 Profile 复验（先用试用调试 Profile） |
| A5 | 手机域无 JIT ACL 申请入口/先例：ACL 目标仅 PC/2in1/平板；无 ACL 时手机域只保 AOT | `2026-10-03-ohos-agc-acl-application-pack.md` §2/§5（单设备 2in1/debug 域；手机域未测） | 手机产品无 JIT 性能形态；审核实例无一手证据 | **需外部**：手机域维持 AOT；ACL 材料包（正文/技术附件/App Linking）已备，提交/审核在 AGC |
| A6 | 坚盾守护模式全局禁 JIT（已授权应用亦然，需重启开启） | 同 ACL 包 §2/§4.5 · `2026-10-03-ohos-wx-runtime-review.md` | 坚盾态下 JIT 不可用（含 ACL 获批后） | **接受**：AOT 兜底 + 普通/坚盾两态验收 |

## B. 无障碍（a11y）

| # | 限制 | 实测证据（doc / script / commit） | 影响 | 现状或缓解 |
|---|---|---|---|---|
| B1 | 本影像对第三方 debug hap 关闭扩展服务启用（三路全闭）：无 `accessibility` CLI；PC 设置无「已安装的服务」入口；`accessibility.config.enableAbility` 为 `@systemapi` + `WRITE_ACCESSIBILITY_CONFIG` + 系统签名 | `2026-10-05-ohos-a11y-client.md` §2（AMS `accessible=0`/`client num=0`；settings 无入口；hap `83,279 / f3fbfad6…`、ow `ee8b865`） | 本机镜像无法启用读屏扩展跑影子树；AAMS 可见 `installed=3 / enabled=0` | **需外部**：客户端已交付 + tester 启用/采集步骤（同文 §4）；需 stock OH / 读屏机 / 系统签名复跑（kit #47/#48 自检 nodeCount 1→70 已证发布链） |

## C. 媒体 / Web

| # | 限制 | 实测证据（doc / script / commit） | 影响 | 现状或缓解 |
|---|---|---|---|---|
| C1 | 本机镜像无 MediaKit：`canIUse` Core 为真但运行时无 `createAVPlayer` 命名空间 | `2026-09-30-ohos-w9d-media-deeplink.md` §1（`media-kit=missing`、sink 降级 `-1`）· `2026-09-30-ohos-kit35-local-verification.md`（`[media-probe] load status=Unavailable`） | MediaElement 播放未验（E9） | **需外部**：桥已实现 + 诚实降级（`IsSupported=false` 不抛）；需 Kit 完整镜像 / HMS 设备复验 |
| C2 | 本机镜像无系统 ICU（`libicuuc` 缺失）：JIT/解释器托管启动即 FailFast | `2026-10-03-ohos-jitfort-enable.md` §ICU · `2026-10-03-ohos-jitwave-consolidation.md`（缺失即 invariant） | 全球化 locale 行为退化为 invariant 语义 | **已缓解**：宿主探测缺失即自动 `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`；`DOTNET_OHOS_ICU` 可覆盖 |
| C3 | `.wasm` 需显式 `application/wasm`；否则 Blazor `instantiateStreaming` 退化为 ArrayBuffer 加载 | `2026-09-28-blazor-wasm-arkweb-hosting-demo.md`（`mimeTypeOf` 映射；curl 实测含 br/gzip 协商）· `2026-09-29-ohos-arkweb-capability-matrix.md` #2 · **真机 A/B** `2026-10-05-ohos-mime-max-device.md` §1 | 首载性能/内存退化（功能可用） | **已缓解（正向真机）**：壳 `onInterceptRequest` 按扩展名直供；宿主新增 `wasm mime:`/`wasm fallback:` 探针（`pack-host.sh --bad-mime` 负控），真机取到 `-> application/wasm` + BLZ_BOOT/RENDERED、fallback=0；负控转发未闭环（见该文 §4） |
| C4 | 单 ArkWeb 控件 / 固定槽池容量局限（历史 N=2 时第 3 控件 LRU 抢占后空白） | `2026-10-02-ohos-multi-overlay.md` · `2026-10-04-ohos-tester-handoff-kit44.md` §1.1 | 多 WebView/混合控件页的出画与交互 | **已缓解**：动态槽 MAX/HOT 默认 4/2、按需 ensure/destroy、释放即拆；3 控件并发 + 第 5 槽抢占/恢复真机闭环 |

## D. 系统 / 构建

| # | 限制 | 实测证据（doc / script / commit） | 影响 | 现状或缓解 |
|---|---|---|---|---|
| D1 | ≥7.0.0.111 强制 libs 逐文件代码签名 + fs-verity：无扩展名条目无签名块、恰 4096 B 使能失败（`9568393`） | `2026-09-30-ohos-jit-payload-install-policy.md` §1–§3（`createdump` 漏签、4096 B `ret=-768`）· `2026-10-02-ohos-payload-sign-default.md` | payload-in-libs 包在 enforcing 镜像装不上（7.0.0.105 无此强制） | **已缓解**：DEVCOMPAT 默认开（无扩展名→`.so`/`.bin`、4096→+4 B；ow `12be59c`）；逃生口 `-p:OpenHarmonyHapPayloadInLibsDeviceCompat=false`；签名链不变 |
| D2 | `/tmp` 禁建 AF_UNIX socket（`bind`→`EACCES`）；UDS 路径上限 108 字节 | `2026-09-28-msbuild-taskhost-pipe-rootcause.md`（MSBuild/Roslyn 硬编码 `/tmp`；管道 43 + TMPDIR 25 = 68 < 108） | task host / MSBuild server / csc 共享编译失败（MSB4216）或 20 s 回退 | **已缓解**：sdk CI 打包补丁（`b52765daab`/`1cbc1b8a6a`）改 `Path.GetTempPath()`；前提 TMPDIR 可 bind |
| D3 | csc/VBCSCompiler 偶发活锁（并发 spin，或全 futex 0 CPU）；看门狗未覆盖 `SIGSTOP` 窗 | `scripts/ohos-csc-watchdog.sh`（头注三形态）· `scripts/ohos-csc-spin-repro.sh` · runtime `cac0e0b2b08` · `2026-10-05-ohos-maui-completion-verdict.md` §3 | 长构建可能挂死数分钟（非功能面） | **已缓解**：无进度看门狗杀编译器进程组；绕行 `DOTNET_PROCESSOR_COUNT=1`；SIGSTOP 窗登记为工程尾巴 |
| D4 | 本机镜像无 `libhilog_ndk.z.so`：宿主/`[maui]` 日志走 stderr，hilog 不可见 | `2026-09-29-ohos-local-device-test-runbook.md` §4 | 本机取证只能靠壳日志/截图；tester 机可见 `aot=`/`xwe=` 等行 | **接受**：本机 vs tester 机判读分流；壳新增 `[maui-capacity]` 原文直写 hilog 供双机判读 |
| D5 | `hdc shell` = uid 2000（shell）：`smode` 被拒、payload/filesDir 0600 不可读、`/data/local/tmp` 无 exec 标签 | runbook §1/§4 · `2026-10-03-ohos-wx-probe-matrix.md` 脚注¹ | 本机无法直读 app 沙箱、无法执行自带探针 | **接受**：取证走 hilog/截图/壳导出；探针放进 hap 由 app 域执行 |
| D6 | 锁屏（keyguard）拦截 `aa start` 返回 `10106102`；developer mode 不自动解锁 | `2026-10-03-ohos-screen-interference.md`（长跑 harness 失效）· `2026-10-05-ohos-device-round-script.md`（超时退 1 提示） | 长跑/浸泡被锁屏打断且无法自愈 | **已缓解**：长跑前置常亮/人工解锁；脚本对 `10106102` 快速失败 + 有限重试并归档 |

## E. 覆盖边界

| # | 限制 | 实测证据（doc / script / commit） | 影响 | 现状或缓解 |
|---|---|---|---|---|
| E1 | 单设备（2in1）、debug 签名域为主；镜像策略差异（7.0.0.105 vs 7.0.0.111）、跨重启未覆盖 | `2026-10-03-ohos-three-path-baseline.md`（不确定节）· `2026-10-03-ohos-agc-acl-application-pack.md` §5 · runbook §4 | 结论不能外推到手机/release/其它镜像 | **需外部**：tester 机（手机）复跑；自签 release × AOT 已实测 ✅；镜像差已归因（D1） |
| E2 | 真多窗口（自由窗 / OpenWindow 语义）未实现；WebView 弹窗 `onWindowNew` 未接；S 形态（窗口模式声明 + 尺寸跟随）已交付 | `2026-09-28-ohos-maui-port-backlog.md` #25（`ApplicationHandler` 诚实单窗语义；E3）· `2026-09-29-ohos-arkweb-capability-matrix.md` #13 · **预研** `2026-10-05-ohos-multiwindow-prestudy.md`（方案 A0 S / A1 M / B L；§5 = A0 落地：maui `ed02203bfd` + ow `c5df1de`；真机 2in1 3120×1955）| 自由窗/多窗工作流与 OAuth 弹窗流程不可用；M/L 无入口 | **部分落地（S）**：kit #48 MULTIWINDOW-S（`supportWindowModes` + `CanArrangeSurface`；split/floating 真形态与手机域未测）；M（应用内子窗）/L（真 OpenWindow）**需外部/上游**；单窗 + 同窗弹窗（`multiWindowAccess(true)` 同窗载入）如实降级 |
| E3 | arm32（`openharmony-arm`）无设备/工具链验证路径，已 PARKED | `2026-09-21-ohos-arm32-support-gap.md` §0–§2（本机 arm64 内核不支持 32 位 ELF） | 32 位设备无法交付 | **需外部**：只发 arm64/x64；拿到 32 位设备后按 gap 文档 §3/§4 启动 |
| E4 | 覆盖层槽容量夹取 2..8（默认 4/2）；真机并发验证到 3 控件 + 第 5 槽抢占/恢复，**N=8 实测不稳** | `2026-10-04-ohos-tester-handoff-kit44.md` §1.1（`clamp 2..8`）· `2026-10-04-ohos-a11y-and-capacity.md` §2（活覆盖层 ≤4）· **MAX=8 轮** `2026-10-05-ohos-mime-max-device.md` §2 | >4 槽无真机证据，退化按 owner-LRU | **上限维持 4**：壳/托管可建 8 槽并触发第 9 claim 抢占，但真机仅槽 0–3 attach/服务、槽 4–7 建而不挂（应用重启一次）→ 安全上限 = 4；先定因 >4 挂载再提升 |

## 对 tester / AGC / 上游的用法

**tester**：把本文当「预期边界」——命中 A–E 的现象先对照本表再判缺陷（a11y `enabled=0`=B1、MediaElement `Unavailable`=C1、enforcing 镜像 `9568393`=D1、锁屏 `10106102`=D6）；判定点与回传仍以 `2026-10-05-ohos-tester-handoff-kit48.md` / `2026-09-28-ohos-retest-taskcard.md` 为准，B1 启用/采集步骤见 a11y-client §4。**AGC**：A4/A5/A6 是上架前置——`ALLOW_WRITABLE_CODE_MEMORY` 材料包已备（ACL 包正文/技术附件/App Linking），获批前发布件保持 AOT、坚盾态按 A6 验收；D1 是设备兼容重写而非绕过审核（签名链不变）。**上游**：A2/A3 建议明示 JIT 权限契约（memfd/文件 RX 全拒、隐藏 prctl 非调用者隔离）；D2/D3 建议接受 TMPDIR 感知 + UDS 长度回退、Roslyn 服务器 OHOS 看门狗/诊断；E2/E3 见各自 backlog 文档。
