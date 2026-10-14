# MAUI 移植完成度终审（FINAL-VERDICT，2026-10-05）

> 审计源：FINAL-AUDIT（上轮七项）· 覆盖矩阵（kit #47 口径）· STATE-OF-PORT · handoff #47 · 工具件
> A11Y-CLIENT（已交付）/ DEVICE-ROUND（在跑）。方法：逐项核对到提交/报告；本轮为核实类，无代码改动。
>
> **2026-10-14 kit #57 更新（官方 rc.2 重切 + JIT/interp 件与三卡）**：终审结论继续有效——功能面 = kit #56 全量
> （rc.2 官方包对齐 + TOUCH-PASTE + WEBAUTH-LOOPBACK + SECURE-STORAGE-FAILCLOSED），本刀只换官方戳
> （SDK `.105` / workload `.29`）并补 JIT/interp 件（CG2-R2R / FIXRR）与 AOT-STARTUP 复跑；kit #57 数字见
> STATE-OF-PORT 与 `2026-10-14-ohos-tester-handoff-kit57.md`。

## 1. 结论

- **功能面：完成**（off-device 门禁 + 交付方真机口径）。MAUI 主要功能面——控件/布局/图形/动画/列表/
  WebView/Blazor/无障碍/Essentials/平台集成——无未实现功能；41 handler、套件 **593/595 floor 575**、
  导出 **151/151**、三路径真机与多覆盖层/Blazor/a11y 证据闭环。
- **本地可执行功能项 = 0**；剩余本地工程项 = 1（csc/VBCS 并行活锁，非功能面）。上轮七项 **6 闭合 + 1 在办**；
  矩阵 §2 的 MainThread/SoftInput/ConnectionProfiles 旧缺口已落地（文本未刷新）；handoff §7②「镜像未并入」已过期。

## 2. 已闭合（本轮核实，勿再复提）

- **L1 z-order**：真机争夺带 97.2% 像素翻转（ow `680f9ed`）。**L6 截图 JPEG/标题心跳**：kit #42。
- **L3 WebAuthenticator 本机面**：`module.json skills[].uris` 打包期声明（ow `d6384ee`；tasks 138/0）；真机投递归 AGC。
- **L4 AOT pack 结构修复**：`-struct1`（asset 607541145；`c1c85422715`/merge `7d62af56ba`）。
- **L5 镜像**：`d47f1fcb3b`（workload-* + sums 重写）已并入 sdk `feature/openharmony`（`caf4a0236e`）。
- **L7 Core Toolbar**：`7064bb8c1c`；legacy compat renderers = 上游 net11 有意移除（非缺口）。
- **承 #42–#47**：JIT/解释器 rc2b/动态槽/AOT 默认/FRAMEPACING/AUTODISCONNECT/INTERP-RENDER/DRAW2/
  FIX-A11YFLYOUT（nodeCount 1→70）/FIX-PREEMPT-RAW/SOAK-JI 三路径 45 min 0 崩；MainThread（dispatcher bridge）、
  SoftInput（`OpenHarmonySafeArea.cs`）、ConnectionProfiles、非文本焦点+硬件键（内部面）均已落地。

## 3. 剩余本地（1，非功能面）

- **L2 csc/VBCS 活锁**：watchdog（`cac0e0b2b08`）空闲 keep-alive 不误杀已验证；SIGSTOP 窗未捕获；
  绕过 = `DOTNET_PROCESSOR_COUNT=1`；不影响功能面与发布件，建议作为工程尾巴单列。

## 4. 剩余外部清单

- tester 轮（kit #47 判定点回传；读屏环境 T2/L1/N1/F2/E1 复核——A11Y-CLIENT 已给步骤）。
- AGC（App Linking 登记+https 投递、JIT ACL 提交、rc.2 正式 pin；现走 dnceng daily）。
- 上游（键契约 E6、Blazor WASM 发布链 E7、VisualDiagnosticsOverlay tap E8、Hot Reload E4、arm32 E5、
  真多窗 E3、ship-the-slice）；样例级（真触摸屏手势、异 bundle 壳复用 jscrash）。
- **上游 PR/分支“刷新”不是待办**：分支按纪律不可强推，只读预演已于 10-04 对当时最新 `upstream/main`
  （runtime `cfe8a6c4600`）复跑（39/39 merge-tree clean、20/21 rebase clean、0 支需重做）；该预演为
  **周期维护**（随 rc2-watch 周程/上游前进时重跑并更新 `2026-09-28-ohos-upstream-rebase-rehearsal.md`），
  PR 描述等上游写操作按既定约定不做。
- 版本注：本判定不随 kit 版本号变化；现行发布为 kit #56（#43→#56 均为同一功能面 + 性能/工具增量；#56 = rc.2 官方包对齐 + TOUCH-PASTE + ENG-WAVE）。

## 5. 平台限制清单

- 执行内存墙（HAP 域拒 exec）：AOT 默认；JIT 调试域可用，release 域需 ACL/豁免。
- a11y 启用门槛：本影像第三方 debug hap 无法启用扩展服务（无 CLI/设置路径；enableAbility 为
  @systemapi+系统签名）——客户端已装且 AAMS 可见（installed=3/enabled=0），需 stock OH/读屏机复跑。
- 无 MediaKit 镜像：MediaElement 桥已实现、播放未验；HMS/AGC kit 真调用需 harmony flavor+权益（默认不抛）。
- 验证面：单设备 2in1/API 26 debug 域；release×JIT、手机域、跨重启未覆盖；覆盖层 N=2..4+LRU。

## 6. 工具件 / 建议

- **A11Y-CLIENT：已交付**（ow `ee8b865` + `2026-10-05-ohos-a11y-client.md`；hap `f3fbfad6…`，selftest 14/14）。
- **DEVICE-ROUND：已交付**（ow `6b6aed1` + `2026-10-05-ohos-device-round-script.md`；selftest 44/44、run2 rc=0、
  归档 `f23f0b9d…`）。
- **建议：本地可执行功能项 = 0，功能面无下一步**；唯一本地工程尾巴 = L2（csc/VBCS 活锁；已由 watchdog
  自愈覆盖，定位留档）；外部/平台按 §4/§5 推进，不判失败。

> kit #49 发布回填（2026-10-05）：M 多窗（MULTIWINDOW-M：应用内子窗 create/move/resize/close + 主窗协同；真机 `app://subwindow/demo` id=344 720×480→420,360→900×600→close）+ SEC-SCAN-4（a11y 密码脱敏）已随 kit #49 交付；tester 复测 = `2026-10-05-ohos-tester-handoff-kit49.md` §2（主判点 1–2）与 `2026-09-28-ohos-retest-taskcard.md`；平台边界见 `2026-10-05-ohos-platform-limitations.md` E2（S+M 已落地，L 余）。
>
> kit #48 发布回填（2026-10-05）：S 多窗（MULTIWINDOW-S）已随 kit #48 交付（真机 3120×1955；M/L 未实现）；tester 复测 = `2026-10-05-ohos-tester-handoff-kit48.md` §2（主判点 1–5）与 `2026-09-28-ohos-retest-taskcard.md`；平台边界见 `2026-10-05-ohos-platform-limitations.md`。

## 10-05/06 补强（kit #49 背书）

- **SOAK49**（`2026-10-06-ohos-kit49-soak.md`，`f672529f573`）：AOT 40 min 浸泡 0 崩 / 0 pid_lost / 0 重启 +
  子窗 churn **21/21** + 主窗 suspend/resume **10/10**；证据 `c9ee6efd…`。
- **DEVICE-ROUND-49**（`2026-10-05-ohos-device-round-49.md`，`18e0d4d4978`）：kit #49 AOT 全链通过——首帧 +
  子窗 create/move/resize/close 四操作 + 主窗协同。
- **tester 轮包 #49**（`2026-10-05-ohos-tester-round-kit49.md`，`6d592f6b97a`）：asset 613320136 / `155,893,607` / `6b9712ef…`。
- **上游复演 + 分支卫生**：`6e1e6a1230b`（复演，含 10-05 首现冲突草图）/ `3ae60c27ad5`；周期维护（非待办）。
- 判定不变：本机可执行项 = 0，余项纯外部（§4/§5）。

## kit #50 终态（MULTIWINDOW-L，2026-10-06）

- **功能面增量**：**真多窗 MULTIWINDOW-L 全套（M1–M4 + SEC-SCAN-5a/5b/5c）** 随 kit #50 交付——宿主每窗 XComponent surface 注册表（registry 84/84、bridge 26/26）、per-window `OpenHarmonyWindowSurface`/`Renderer` + 带窗事件路由（`RouteSurface/RouteTouch/RouteFrame`）、子窗挂 XComponent 得 **第二 MAUI 视觉树**（真机 `sub-1` 720×480 `first frame=True`）、每窗焦点/IME/生命周期（`IWindow.Activated/Deactivated/Stopped/Resumed` 状态机）、a11y 分区（主 provider 零变化、子窗影子帧本地）、per-window pinch（导出 **157/157**）；**polish-49**（建窗 E=0、close WARN 平台内部、Home 焦点丢失链 suspend）。真机 HAD-W32/W24：双窗稳态 **60/60 fps**、40 min 长稳（RSS 净 −34 MB、pid 恒定）、churn ×20 无残留、JIT 与 AOT 各过轮。
- **数字**：tar **68,264,136 / `d70dc786…`**、树 `b4b5055c…`、sidecar `2ffb3b6a…`、`SHA256SUMS` 18 项 / 1,600 B / `98fd0dd2…`；bundle **73,119,180 / `6a83c0f3…`**（sdk 锚 **`a3417a5489`**）；壳 abc **436,808（`289a5e5d…`）**/24,324、宿主 **330,656（`fdeb94eb…`）**、套件 **661/663 floor 643**、导出 157/157；预签 **68,157,557 / `028d29f4…`**（asset 615517779/615518466）；CI 5/5 @ `afa6d7a`（interaction 37460790068 / pixel 37460790072 / host-export 37460790087 / ridgraph 37460790138 / markdownlint 37460790028）+ sdk run `37465689708`；maui `74e0bde5b9`、ow `afa6d7a4`。
- **降级声明（必有）**：子窗 a11y provider、子窗 ArkWeb 第二宿主、平台级多子窗上限（应用级 N=1）、**子窗 IME 实敲人工卡**、SEC-5c B–F 报告项；明细见 `2026-10-06-ohos-multiwindow-l-m4.md`（末节人工卡）、`2026-10-06-ohos-security-scan-5c.md`、平台限制 E5。
- **数字口径注（不确定项）**：kit 内 5 MAUI AOT 用 `~/.dotnet.rc2-fix`（SDK `26451.112` = 声明基线）打包；构建机默认 `~/.dotnet`（`26451.109`）的 ILCompiler 为 `11.0.0-rc.1.26451.109` 有偏离（两安装的 preview.28 pack 已逐字节同步）。
- **剩余外部**：tester 轮（#50 判定点回传；读屏环境与 IME 人工卡）、AGC（App Linking/JIT ACL/rc.2 正式 pin）、上游（键契约/Blazor WASM/VisualDiagnosticsOverlay/Hot Reload/arm32/ship-the-slice）、`m-web-mirror` 并入；本地工程尾巴仅 csc/VBCS 活锁（非功能面）。**判定不变**：本机可执行功能项 = 0，多窗（S+M+L）全部落地，余项纯外部/已文档化降级。

## kit #51 终态（L2，2026-10-07）

- **功能面增量**：**MULTIWINDOW-L2 并存整合** 随 kit #51 交付——**a 子窗 a11y provider**（`host_a11y_table.c/h` 节点表按 provider instance 分区，legacy 主分区逐字保留；`RegisterCallbackWithInstance` 全链 + 带窗动作 `set_window_action_listener`；壳 NodeContent/ContentSlot 双点 attach；导出 157→**163**；真机 HAD-W32（OH 7.0.0.111）**W0 并存 PASS**（子 `status=1 instance=sub-1`、主 status=1/72 节点不回退）与 **W2 自检 PASS**（子 10 节点、主 72 零回归））；**b 子窗 ArkWeb 第二宿主**（child web/eval sink + `OpenHarmonyChildWeb` 按窗槽池 Max=2/64 条预就绪队列；**capacity wire 修复** + 回归 pin；真机全链闭环 `CHILD WEB TAP`、双窗 **60.0/60.0 fps**、主窗零回归）；**SEC-SCAN-6 A/B/C 全闭**（A 分区仅 `begin_for` 分配、B 主窗 id 子通道拒绝、C 关窗 **`ReleaseWindow` hooks** 清 child Capacity/Pending + a11y frame/first-publish，+2 checks、红控 3×assert=False）；**L2CAP 平台容量探针**——平台并发子窗上限 **255**（第 256 个 `1300002`、3 轮一致、destroy 255/255、0 残留、可恢复）⇒ **应用级 N=1 为壳契约而非平台限制**（产品化另立项、本波不动壳）。
- **数字**：tar **68,550,333 / `e5f6541c…`**、树 `a06d3897…`、sidecar `5c471871…`、`SHA256SUMS` 18 项 / 1,600 B / `5f8c1512…`；bundle **73,147,751 / `f4b4fe8d…`**（sdk 锚 **`a00e810c92`**）；壳 abc **473,048（`298622c0…`）**/24,324、宿主 **347,040（`36acfc1d…`，导出 163/163、UND 250）**、套件 **688/690 floor 670**、预签 **68,447,288 / `e9fb1e90…`**（asset 617093322/617094016）；CI 5/5 @ `696ebc0`（interaction 37548888210 / pixel 37548888313 / host-export 37548888169 / ridgraph 37548888051 / markdownlint 37548888104）+ sdk run `37553127808`；maui `bb6b06990d`、ow `696ebc0b`。
- **降级声明（必有）**：子窗 a11y **动作 e2e 平台限制**（读屏服务不可得；W0/W2 并存与节点计数已过）· **子窗 ArkWeb hybrid/blazor 资产桥显式拒绝**（下波壳侧 `onInterceptRequest` serving + 按窗注册回放）· 子窗 B6 导航否决未接 · **子窗 IME 实敲人工卡** · 子窗池满（>2 控件）不挂载 + 就绪队列溢出丢 1 行日志 · ArkWeb `loadData` 裸 `#` 截断（平台共性）· SEC-6 余留原生 a11y 分区常驻（有界）· 应用级 N=1 壳契约；明细见 `2026-10-07-ohos-l2-consolidate.md`、`2026-10-06-ohos-l2-a11y-provider.md`、`2026-10-06-ohos-l2-arkweb-subwindow.md`、`2026-10-06-ohos-l2-subwindow-capacity-probe.md`、平台限制 E5/C5。
- **剩余外部**：tester 轮（#51 判定点回传；读屏环境与 IME 人工卡）、AGC（App Linking/JIT ACL/rc.2 正式 pin）、上游（键契约/Blazor WASM/VisualDiagnosticsOverlay/Hot Reload/arm32/ship-the-slice）、`m-web-mirror` 并入；本地工程尾巴仅 csc/VBCS 活锁（非功能面）。**判定不变**：本机可执行功能项 = 0，多窗（S+M+L+L2）全部落地，余项纯外部/已文档化降级；当前发布 = kit #51（交接 = `2026-10-07-ohos-tester-handoff-kit51.md`）。

## kit #52 终态（L3，2026-10-07）

- **功能面增量**：**MULTIWINDOW-L3 N=2 多子窗产品化（M1–M4 全并入主线）+ L3 尾项** 随 kit #52 交付——**M1/M2** 壳会话注册表（`sub-N` 键控、`SUB_WINDOW_MAX=2`、全命令按 `cmd.surfaceId` 路由、容量 801、末会话 suspend）+ maui `MaxManagedSubWindows=2`；每窗身份握手/生命周期（会话 `generation` + per-child claim 表 + managed op7 ack，错名/旧代际/重复 fail-closed；宿主窗口 op 上限 `5→7`）；真机 HAD-W32（OH 7.0.0.111）**windows=2**（双端 `identity confirmed`、双 `accessibilityStatus: 1`）、输入分窗、定向关（`remaining=1`）、重开 gen 递进、churn ×20 0 残留、主窗零回归。**M3** 每窗 IME/a11y/overlay/Back（单键盘焦点窗 + 切窗 blur、per-window alert 槽/几何 + `Hide(string)`、Back 焦点窗、a11y per-instance 复用；真机 IME 切换 + 双 provider `status=1`；Back/alert 受 uitest 注入限制记人工卡）。**M4** 按窗 child ArkWeb 槽池（壳 surfaceId sink + 关窗注销、`ChildWebWindowSinks` 按 windowId、`child:<window>|<op>` 载荷校验、两窗同 slot 0 各回各窗；真机双窗各自 `CHILD-WEB-1/2` + `TAP 1/2`、定向关不动另一窗、**40 min 双窗 soak** RSS 284–363 MB 无单调增长、pid 恒定、0 crash/fault）。**尾项**：①a11y 分区 release（`ohos_host_accessibility_release_for`，导出 163→**164**；关窗 hook 释放命名分区 + 重置 per-instance 注册态；selftest 15/15 + 双红控）；②子窗 hybrid/Blazor 资产桥（`onInterceptRequest` serving + 按子槽 bootstrap + bit30 child invoke + 同槽 fail-closed；离线红/绿，**真机未抽验**——无现成样例 hap）。
- **数字**：tar **68,853,027 / `9e60fdc0…`**、树 `c1fa6421…`、sidecar `d10ae2e7…`、`SHA256SUMS` 18 项 / 1,600 B / `fbc035f8…`；bundle **73,199,515 / `5a00331f…`**（sdk 锚 **`9609da7a47`**）；壳 abc **534,192（`e6516424…`）**/24,324、宿主 **367,520（`ad7ab986…`，导出 164/164、UND 252）**、套件 **731/734 floor 714**、预签 **68,732,127 / `5abf7629…`**（asset 618854752/618855844）；CI 5/5 @ `0685d7b`（interaction 37625969429 / pixel 37625969211 / host-export 37625969178 / ridgraph 37625969029 / markdownlint 37625969127）+ sdk run `37631943842` @ `9609da7a47`；maui `277967cc56`、ow `0685d7b`；tester 轮包 `tester-round-kit52.tar.gz` **157,785,932 / `b16c9b25…`**（asset 618885974 + sidecar 618888765）。
- **降级/人工卡（必有）**：子窗 a11y **动作 e2e 平台限制**（读屏服务不可得；W0/W2/双窗 status=1 已过）· a11y selfcheck 3 s 探针 `nodes=0`（静态帧首发布时机）· **子窗 hybrid/Blazor 资产桥真机未抽验**（无样例 hap；离线红/绿）· uitest **Back/alert 注入限制**（人工卡）· 子窗 B6 导航否决未接 · 多窗同槽 hybrid invoke fail-closed · **子窗 IME 实敲人工卡** · 子窗池满（>2 控件）不挂载 + 就绪队列溢出丢 1 行日志 · ArkWeb `loadData` 裸 `#` 截断（平台共性）· SEC-6 原生 a11y 分区常驻（有界）· **应用级 N=2 为壳契约**（平台上限 255 已探明）；明细见 `2026-10-07-ohos-l3-consolidate-final.md`、`-l3-m2/m3/m4.md`、`-l3-tail-fixes.md`、平台限制 E5。
- **数字口径注（不确定项）**：同 #51——kit 内 5 MAUI AOT 用 `~/.dotnet.rc2-fix`（SDK `26451.112` = 声明基线）打包；构建机默认 `~/.dotnet`（`26451.109`）的 ILCompiler 为 `11.0.0-rc.1.26451.109` 有偏离（两安装的 preview.28 pack 已逐字节同步）。
- **剩余外部**：tester 轮（#52 主判点回传；读屏环境、IME 实敲与 hybrid/blazor 样例）、AGC（App Linking/JIT ACL/rc.2 正式 pin）、上游（键契约/Blazor WASM/VisualDiagnosticsOverlay/Hot Reload/arm32/ship-the-slice）、镜像分支并入状态；本地工程尾巴仅 csc/VBCS 活锁（非功能面）。**判定不变**：本机可执行功能项 = 0，多窗（S+M+L+L2+L3）全部落地，余项纯外部/已文档化降级；当前发布 = kit #52（交接 = `2026-10-07-ohos-tester-handoff-kit52.md`）。

## kit #53 终态（post-L3，2026-10-08）

- **功能面增量**：**POST-L3 合并收口（A11Y-SELFCHECK 子窗首发布修复 + B6 子窗导航否决）** 随 kit #53 交付——**A11Y-SELFCHECK**（maui `l3/a11y-selfcheck` `8c7a859c91` → merge `4910d470db`）：根因 = per-window 发布门禁的独立 `NativeLibrary` 预探针 `WindowProviderExportAvailable` 在托管 loader 误报 “no export”（`export=False`）而 in-process host 已共享/attached，3s 子窗自检读 `status=1 nodes=0`；修法（最小、仅次窗路径）= `PublishSecondary` 直连 `ohos_host_accessibility_provider_status_for`（旧 host 由 `EntryPointNotFound` 缓存一次并保持本地帧降级）+ `OpenHarmonyWindowHost.OnFrame` 在 `WindowPublishPending` 强制重绘一次（覆盖 attach 晚于末帧的时序）；真机 HAD-W32：诊断 `nodes=0` → 修复 **`nodes=10` ×2**（sub-1/sub-2）+ 定向关/重开 `nodes=10`（instance=sub-2）+ 空闲轮复跑 `nodes=10` ×3 + 主窗零回归（主画布 n=297–301、pid 首=末、0 crash/fault）；离线 +1 check（`m4 a11y selfcheck pending repaint`，红控在案）；证据 `a11ysc/round2.log` + round1 诊断。**B6 子窗导航否决**（ow `l3/b6-nav-veto` `d25c0eb` + maui `b64c477f8e` → merges `96267f2`/`caa463434b`）：壳 `SubWindow.ets` child ArkWeb `onLoadIntercept` 网关——外部主帧导航取消并经 `w:<surface>|<slot>|navask|<id>` 问 managed（URL 在事件 URL 槽；一次性批准；pending 8/TTL 5s/URL 8KiB；槽销毁丢 pending）+ maui `HandleChildNavigationRequest`（同主 `__OHNAV` 校验、对 (window,slot) 同步抛 `Navigating`、批准键 `child|<win>|<slot>|<url>` 共享主表 cap/prune、child `started` 一次性消费；主窗键/编码/行为不变）；离线 `b6c` 5 checks（红控 3×assert=False exit 134）；真机 JIT：deny 链（ask 无 `nav` 命令/无批准、载荷保留）与 ok 链（ask→`nav approved`→重载→`child web error`→hide）双链闭环；证据 `b6/` + `-l3-b6-modes.md`。
- **数字**：tar **68,883,057 / `dba88961…`**、树 `9c67b5ec…`、sidecar `47ace1d0…`、`SHA256SUMS` 18 项 / 1,600 B / `39489081…`；bundle **73,213,144 / `031ba342…`**（sdk 锚 **`64f239eb28`**）；壳 abc **542,936（`f18f0855…`）**/headless 24,324（`798b2477…`）、宿主 **367,520（`ad7ab986…`，同 #52 指纹；导出 164/164、UND 252）**、套件 **737/740 floor 720**、预签 **68,755,353 / `d1732195…`**（asset 620760775/620762418）；CI 5/5 @ `7259a0f`（interaction 37724762076 / pixel 37724762158 / host-export 37724762150 / ridgraph 37724762139 / markdownlint 37724762089）+ sdk `ohos-install-tests` `37728679048` @ `64f239eb28`；maui `caa463434b`、ow `7259a0f`。
- **降级/人工卡（必有）**：子窗 a11y **动作 e2e 平台限制**（读屏服务不可得；W0/W2/双窗 status=1/selfcheck `nodes=10` 已过）· **子窗 hybrid/Blazor 资产桥真机样例缺**（无现成 child+hybrid 样例 hap；离线红/绿）· uitest **Back/alert 注入限制**（人工卡）· **子窗 B6 导航否决真机样例**（`//host` 探针受桌面控制台 z-order 抢占；deny/ok data: 链已闭环）· **子窗 IME 实敲人工卡** · a11y `export=False` 预探针**加载器层根因未追**（仅证托管 loader 结论错误）· 多窗同槽 hybrid invoke fail-closed（产品级）· 子窗池满（>2 控件）不挂载 + 就绪队列溢出丢 1 行日志 · ArkWeb `loadData` 裸 `#` 截断（平台共性）· SEC-6 原生 a11y 分区常驻（有界）· **应用级 N=2 为壳契约**（平台上限 255 已探明）；明细见 `2026-10-08-ohos-l3-post-consolidate.md`、`2026-10-07-ohos-l3-m3.md` §5、`2026-10-07-ohos-l3-b6-modes.md`、平台限制 E5。
- **数字口径注（不确定项）**：同 #52——kit 内 5 MAUI AOT 用 `~/.dotnet.rc2-fix`（SDK `26451.112` = 声明基线）打包；构建机默认 `~/.dotnet`（`26451.109`）的 ILCompiler 为 `11.0.0-rc.1.26451.109` 有偏离（两安装的 preview.28 pack 已逐字节同步）。
- **剩余外部**：tester 轮（#53 主判点回传；读屏环境、IME 实敲、hybrid/blazor 样例与 B6 样例）、AGC（App Linking/JIT ACL/rc.2 正式 pin）、上游（键契约/Blazor WASM/VisualDiagnosticsOverlay/Hot Reload/arm32/ship-the-slice）、镜像分支并入状态；本地工程尾巴仅 csc/VBCS 活锁（非功能面）。**判定不变**：本机可执行功能项 = 0，多窗（S+M+L+L2+L3+POST-L3）全部落地，余项纯外部/已文档化降级；当前发布 = kit #53（交接 = `2026-10-08-ohos-tester-handoff-kit53.md`）。

## kit #54 终态（MediaElement + 模态修复 + 默认 4，2026-10-11）

- **功能面增量**：**MEDIAELEMENT 波 + 子窗/overlay 硬化尾** 随 kit #54 交付——**MEDIAELEMENT-ARKWEB A-M1**（ow `b674f80`/merge `0177a32`、maui `0adfe6c7fe`/merge `fbd91e17bc`）：缺 MediaKit（C1）的回退承载 = ArkWeb `<video>` 进既有 overlay 槽（`media` web 命令 + `https://media.local/?s=<slot>`；origin 服务 `/`+`/__src__`（rawfile/沙箱 file、扩展名 MIME、≤64 MiB）；`__OHMEDIA` 事件信封；每 overlay `.mediaPlayGestureAccess(false)`；`window.__ohMedia` 全 transport/状态 API）；maui `OpenHarmonyMediaElementSurface`/`Handler`（每元素 1 槽、URL/file/rawfile 归一、事件镜像、诚实降级不抛、AOT 安全）；真机 H.264/AAC 1 s/30 s 播完 + seek/pause/volume/mute/槽释放（平台硬解 NV12 + audio_server）、红控 gesture 翻 true 被抓。**MEDIA-SUBWIN+HLS B-M1**（ow `983d103`/合流 `04d1606`、maui `04106f8906`→`54631780a3`）：子窗媒体服务（子槽接 media 命令 + 同源服务 + docId 桥 + 槽销毁回收；slice 去子窗降级 `AcquireForWindow` + `ReleaseWindowOverlays`）+ 内置 **hls.js 1.7.3**（MSE；recover ≤2、原生回退 `fallback-native`）；真机本地 CMAF **30.0 s 播完** + 子窗 `openmedia` 播完/槽回收。**MEDIA-MICRO**（ow `a118ed8`/合流 `1d7ec00`）：弹窗 Web 手势 opt-out（仅页面级媒体，无托管映射）+ `/__src__` 单区间 **206/416** fail-closed + 注册播放列表 sibling 服务 + `hls=1`/`__ohMediaHls` 路由（rawfile m3u8 走 hls.js）；真机弹窗未静音 autoplay 播至 ended、本地分段与单文件 byte-range 均播至 ended + 206 日志。**MODAL-OVERLAY-FIX**（ow `fc848f0`/merge `357d7a9`、maui `01fd6034`）：根因 = 抽屉 suspend 粘滞且模态不解除 → `OpenHarmonyOverlaySuspension` 状态机（模态 push 抬升 / pop 重挂 / 无抽屉静默）；真机红/修对（同树同 abc，唯一变量 = maui 切片）：模态 WebView 白带 → DOM 文案、media 模态纯黑 → `#123456` 8.17% + 视频帧 853×480；pop/scrim 恢复链闭合。**SUBWINDOW-DEFAULT4**（ow `5c6289a`/merge `69e2916`、maui `144b5b6a09`）：managed 子窗默认 2→**4**（壳双向开关 + 非正数守卫；maui `DefaultMaxManagedSubWindows=4`/`MinManagedSubWindows=2`）；真机默认路径 4 窗全成（identity 4/4、关窗 `remaining=3`、重开复用 sub-4、0 fault、主窗 60.0 fps）。同波单行：**E4 8 槽默认**（定因 = 逐槽表硬编码 4）、**DEEPLINK `Mark()`**（0 s 落地）、**WebAuth 真流程+隐式**、**L8-POPUP/余项**、**L7-M2/N-SUBWINDOW/L3-L4**、**SEC-5c E/F**、PREPROBE-SWEEP/HYBRID-SAMPLE/harmony-flavor/csc watchdog（进 preflight）/cut-kit 自动化。
- **数字**：tar **70,345,291 / `583d6df4…`**、树 `251d0c43…`、sidecar `094165d7…`（89 B）、`SHA256SUMS` 18 项 / 1,600 B / `0d42d76d…`；bundle **73,465,150 / `09326398…`**（sdk 锚 **`977be2e31b`**；#53 = 68,883,057 / `dba88961…`、73,213,144 / `031ba342…` 对照）；壳 abc **623,784（`58c5829b…`）**/headless 24,324（`798b2477…`）、宿主 **367,520（`ad7ab986…`，同 #52/#53 指纹；导出 164/164、UND 252）**、套件 **796/799 floor 779**、预签 **70,180,932 / `8eb6dc80…`**（asset 630934768/630936005）；CI **6/6** @ `34b53ea`（interaction 38128268123 / pixel 38128268094 / host-export 38128268048 / ridgraph 38128267992 / markdownlint 38128268124 + harmony 38128268008）+ sdk `ohos-install-tests` `38131678032` @ `977be2e31b`；maui `36da77cba492`、ow `34b53ea`（pin `60dda54`）；runtime manifest `08b8b149c608`。
- **降级/人工卡（必有）**：per-window a11y **动作** e2e 平台限（镜像无读屏服务；发布/自检链 + 离线 pin/红控在案）· **实键盘敲击人工卡**（uitest/uinput 只动 caret/focus，无文本事件；IME op6 直点链已捕获）· **Back = 平台路由边界**（KEYCODE_BACK 达子窗节点 `return:0`/`consumed:0`、平台不转 `onBackPress`；主窗持焦走能力层后台化；离线 pin 覆盖归属/路由）· **弹窗会话无托管树/面**（仅页面级媒体边界）· **子窗+模态组合未上机** · **DRM/EME 与 MPEG-4 Part 2 不支持**（原生 MediaKit 需 HMS）· **>64 MiB 无 Range**（≤64 MiB 单区间 206/416）· 子窗池 2 槽（满 → Failed 不抛）· SEC-5c E/F 与 SEC-6 原生 a11y 分区常驻（有界）· **应用级 N=4 为壳契约**（平台上限 255 已探明）· 2in1 debug 域（E1）。
- **数字口径注（不确定项）**：同 #52/#53——kit 内 5 MAUI AOT 用 `~/.dotnet.rc2-fix`（SDK `26451.112` = 声明基线）打包；构建机默认 `~/.dotnet`（`26451.109`）的 ILCompiler 为 `11.0.0-rc.1.26451.109`（两安装的 preview.28 pack 已逐字节同步）。**打包工具注（供下轮）**：cut-kit P3 需 `--seed-bundle` 保持累积（本轮以 #53 发布 bundle 为种子）；sdk-anchor 正则与 `:=` 形式不兼容（本轮走 KIT53 等价脚本）；fresh worktree 需恢复 git-ignored 的 `packs/**/hosts/**` 宿主。
- **剩余外部**：tester 轮（#54 主判点回传；读屏环境、实键盘敲击、hybrid 样例复跑）、AGC（App Linking/JIT ACL/rc.2 正式 pin——rc2-watch 10-10 复核 WAIT）、上游（键契约/Blazor WASM/VisualDiagnosticsOverlay/Hot Reload/arm32/ship-the-slice）、镜像分支并入状态；本地工程尾巴仅 csc/VBCS 活锁（watchdog 已进 preflight）。**判定不变**：本机可执行功能项 = 0，多窗（S+M+L+L2+L3+POST-L3）全部落地、媒体波闭合（A-M1/B-M1/MEDIA-MICRO），余项纯外部/已文档化降级；当前发布 = kit #54（交接 = `2026-10-11-ohos-tester-handoff-kit54.md`）。


## kit #55 终态（off-cycle 维护波，2026-10-13）

- **功能面增量**：**off-cycle 维护波** 随 kit #55 交付——**LAUNCHER-IDENTITY**（ow `8a48a91`）：四包 targets 设备带 minAPIVersion floor `50002014`→`60000020`（restool 出 **RestoolV2** `resources.index`）+ restool 解析版 `module.json` 替换 staged 件（app labelId/iconId、module/ability descriptionId、startWindow\*Id；缺失 fail-closed）+ `OpenHarmonyFeatures` 默认 **`network`**（INTERNET + reason/usedScene；`none` 哨兵）+ Blazor 链 `pack-host.sh` V2-floor 重跑 restool；真机桌面名称/图标 + INTERNET granted。**PASTEBOARD-FIX**（ow `fa9916b`/merge `15237a5`）：剪贴板读移宿主 pasteboard NDK（`host_clipboard.{h,c}` + dlopen 表 + op0/1 本地应答）；ACL 级权限退出特性矩阵与 `all`（`<Acl>` 概念；`all` = 8 非 ACL；显式 `contacts` 仍可）；真机 `all` 装 rc=0、写通、读=服务 ACL（`GetPasteDataInner# check permission failed`；mail 免权限 NDK 读未复现——其读在用户粘贴窗内）。**MEDIA-RESIDUALS**（ow `d7df09c`；maui `44dcef8d15`）：HLS 同源 byte-range 本地切片装载（ArkWeb 拦截 ArrayBuffer 无法 CEF-skip 非零偏移 → -328 → fragLoadError；页面整取切片，壳 206 语义保留）+ 冷启首播有界等页（50 ms/1500 ms 上限）；真机 hlsrange/hlslocal 播完 + 两遍冷启首播 `Success`。**WEBAUTH-DECOUPLE**（ow `f66d67c`）：`myapp://callback` 回调路由从 `WebAuthProbe` 解耦为无条件（默认 hap 即带 skill）+ kit 组装期 `check_webauth()` 门禁。**SUBWIN-COMPLETED**（ow `34bcaa4`）：子窗 Entry `Completed` 探针（样例 + 套件 +3；maui/shell 零改动、abc 不变）。
- **流程件**：packs/cut-kit 加固随波（PACK-FULL-SYNC P0 安装 pack 门禁 + P1 宿主物化；CUT-KIT-HARDEN P3 三形态锚/累计 seed/P4–P6 预演/AOT InvariantGlobalization；P4 notes append 修复 `a4071cb`；AOT Exec 本地钩子同步修复）。
- **数字**：7 hap 全 AOT 线（5 MAUI NativeAOT + Blazor 默认/`-nocsp`）、ui/shell abc **620,908/`c473b7be…`**（headless 24,324/`798b2477…` 不变）、宿主 **367,520/`8826adde…`**（PASTEBOARD 重建；导出 164/164）、套件 **801/804 floor 784**、权限矩阵 1/6/8 非 ACL；kit tar **70,312,042 / `504ea1ae…`**、树 `7a226f94…`、sidecar `005cfecb…`、bundle **73,468,932 / `8aa53b67…`**（sdk 锚 `cd5bee91dc…`）；预签 70,151,840 / `fcfb6085…`；轮包 160,728,131 / `db585877…`。
- **CI**：ow 5/5 @ `fa21a1ab`（interaction 38282810663 / pixel 38282810760 / host-export 38282810742 / ridgraph 38282810697 / markdownlint 38282810671）+ harmony 38282449682 @ 15237a58（= pin 父提交；fa21a1ab 仅 docs）；sdk 锚 `cd5bee91dc…`。
- **剩余外部**：tester 轮（#55 主判点回传）、AGC（App Linking/JIT ACL/rc.2 正式 pin——rc2-watch 复核 WAIT）、上游（键契约/Blazor WASM/VisualDiagnosticsOverlay/Hot Reload/arm32/ship-the-slice）、镜像分支并入状态；本地工程尾巴仅 csc/VBCS 活锁（watchdog 已进 preflight）。**判定不变**：本机可执行功能项 = 0，多窗/媒体波闭合、off-cycle 维护波闭合，余项纯外部/已文档化降级；当前发布 = kit #55（交接 = `2026-10-13-ohos-tester-handoff-kit55.md`）。

## kit #56 终态（rc.2 官方包对齐 + TOUCH-PASTE + ENG-WAVE，2026-10-14）

- **功能面增量**：**RC2-ALIGN**（官方 MAUI 四包 `11.0.0-rc.2.26505.5`（nuget.org）落地：切片 maui `1c5ff3cbeb`、ow 9 工程、三 workflow pin、interaction/pixel 删 dnceng feed step、`hello-blazorwasm` flight → 官方 `11.0.0-rc.2.26504.105`；零功能面改动）+ **TOUCH-PASTE**（ow `56f1624` → merge `cc6ca34`）：壳级 ArkUI `PasteButton` 安全控件闭环（长按 → 浮层 → 点击 = 系统临时授予剪贴板读 → 按 selection 插值 → `notifyTextInput` 落聚焦 Entry）；opt-in = 沙箱标记 `filesDir/touch-paste.enabled`；abc **620,908→637,224（`8503a3c2…`）**、套件 **814/817 floor 797**；真机跨应用闭环 + 零回归。**WEBAUTH-LOOPBACK**（maui `2a195809db`；ow `5b2dc94`）：loopback 单次监听回跳（免 chooser；https/特权端口拒绝；v6 `localhost` 101 ms）。**SECURE-STORAGE-FAILCLOSED**（maui `ad15ff83a3` → merge `ffa9f68a77`；ow `5ecf0b2`）：`OpenHarmonySecureStorage.FailClosed` opt-in（失败态 Set 抛错不落盘 / sealed 读抛错；默认关）。
- **流程件**：ENG-WAVE 合并（ow `630a10b`、maui `5cfb1b8991`、三 pin 随动）+ rc2-watch 收口 + 本条 kit 切包全链（P0 双安装门禁 + 红控、build/verify/bundle/sdk 锚、clobber 10 项、预签、manifest、CI、轮包）。
- **数字**：7 hap 全 AOT 线（5 MAUI NativeAOT + Blazor 默认/`-nocsp`）、ui/shell abc **637,224/`8503a3c2…`**（headless 24,324/`798b2477…` 不变）、宿主 **367,520/`8826adde…`**（导出 164/164）、套件 **814/817 floor 797**、权限矩阵 1/6/8 非 ACL；kit tar **70,420,041 / `aba73b61…`**、树 `99a37cec…`、sidecar `527b6e3a…`、bundle **73,470,627 / `c678a7ee…`**（sdk 锚 `d62bfe0b79…`）；预签 70,240,169 / `0e062b5e…`；轮包 160,943,858 / `7fd703cc…`。
- **CI**：ow 5/5 @ `cc6ca34`（interaction 38504581652 / pixel 38504581628 / host-export 38504581746 / ridgraph 38504581637 / markdownlint 38504581605）+ harmony 38504581686 @ cc6ca346；sdk 锚 `d62bfe0b79…`。
- **剩余外部**：tester 轮（#56 主判点回传）、AGC（App Linking/JIT ACL）、**RC2-OFFICIAL 官方戳重切（三仓 `.105`，另一会话推进中）**、上游（键契约/Blazor WASM/VisualDiagnosticsOverlay/Hot Reload/arm32/ship-the-slice）；本地工程尾巴仅 csc/VBCS 活锁（watchdog 已进 preflight）。**判定不变**：本机可执行功能项 = 0，多窗/媒体波闭合、rc.2 对齐与 ENG-WAVE/TOUCH-PASTE 闭合，余项纯外部/已文档化降级；当前发布 = kit #56（交接 = `2026-10-14-ohos-tester-handoff-kit56.md`）。
