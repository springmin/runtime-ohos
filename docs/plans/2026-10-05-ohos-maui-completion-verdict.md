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
- 版本注：本判定不随 kit 版本号变化；现行发布为 kit #49（#43→#49 均为同一功能面 + 性能/工具增量）。

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
