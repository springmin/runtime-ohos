# MAUI 移植完成度终审（FINAL-VERDICT，2026-10-05）

> 审计源：FINAL-AUDIT（上轮七项）· 覆盖矩阵（kit #47 口径）· STATE-OF-PORT · handoff #47 · 工具件
> A11Y-CLIENT（已交付）/ DEVICE-ROUND（在跑）。方法：逐项核对到提交/报告；本轮为核实类，无代码改动。

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
- 版本注：本判定不随 kit 版本号变化；现行发布为 kit #51（#43→#51 均为同一功能面 + 性能/工具增量）。

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

