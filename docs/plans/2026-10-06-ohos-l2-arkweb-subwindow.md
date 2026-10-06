# MULTIWINDOW-L2 实施 b：子窗 ArkWeb 第二宿主（2026-10-06）

> 口径：用户点名**直接实施**（不受分析稿 §b“推迟”结论约束）。载体：ow `l2/arkweb-subwindow`（自 `afa6d7a`）·
> maui `l2/arkweb-subwindow`（自 `74e0bde5b9`）· 本文档 runtime `feature/openharmony`。设备：SOAK50 两轮释放后取得
> `.device-lock`，真机为**部分证据**（§3）；未证余项 = §5 上机卡。边界：2in1 debug 域；主窗 web/overlay 全链零变化。

## 1. 实现面（四层）

- **宿主（ow `host_napi.cpp`，C 导出 157 不变）**：per-env `web_child`/`web_eval_child` sink；命令/eval 按 `"child:"`
  前缀路由并去前缀（主路径字节不变）；新 NAPI 属性 `registerChildWebSink`/`registerChildWebEvalSink`（旧宿主缺属性 →
  壳 `typeof` 探测失败 → 子宿主禁用，单主窗降级保留）；C 核心（`openharmony_host.c`）零改动。
- **managed 宿主层（新 `OpenHarmonyChildWeb.cs`，500 行）**：按窗（`sub-N`）槽池（Max=2、全动态、释放即 destroy）
  + 门面 `Acquire/Release/Touch/CommandForWindow`（主窗走原 `OpenHarmonyOverlays`/`OpenHarmonyBridge.WebCommand`
  逐字路径）+ 64 条预就绪队列（`w:<win>|capacity|<n>` 到达即冲刷）+ `w:<win>|s<slot>|<state>` 事件解析；AOT 安全。
- **maui 切片（5 文件）**：三 web handler 在 `ConnectHandler` 经 `ResolveWindowId` 解析窗口（表优先 + `Adopt` 在
  `ConnectTree` 前落表，deferred OpenWindow 连接期即可解析）；领槽/发送/事件过滤按窗（主窗只达主 handler、子窗只达
  该窗）；关窗 `Reset()`→`ReleaseWindowOverlays` 释放子窗 claim（`_overlayWindowClosed` 防再领）；迟到窗口迁移兜底。
- **壳（4 packs `SubWindow.ets`，+~550 行；`Index.ets` 零改）**：`SUB_WEB_SLOT_MAX=2` 全动态池（首 tagged 命令才挂
  ArkWeb）、per-slot controller/defer、与主池同 `s<slot>` 码；事件回 `notifyWebEvent("w:<surfaceId>|…")`；无页 eval
  立即回错；**hybrid/blazor 注册显式拒绝**。样例加 `app://subwindow/openweb`（子窗内联 HTML WebView）。

## 2. 离线红/绿

- **绿**：套件 +16 L2 checks（total 663→**679**、floor 643→**659**）；实跑 `checks=677 total=679 floor=659
  assert=True`、0 assert=False、0 Unhandled（`run-suite5.log`）。覆盖池/队列/就绪冲刷/按窗事件路由/主传输字节等价/
  真 WebView 子窗领**子池**槽（主池 `s_used` 快照不变）/子窗事件只达子窗/主 tagged 事件不达子窗/关窗释放+新
  `slot destroy`（`Skip(base)` 防旧命令假绿）/四 pack 壳·宿主·切片 pins/四 pack `SubWindow.ets` 字节一致。
- **红控**：临时去掉 `HandlerMatches` 主窗窗过滤 → `primary event isolated assert=False`、run 退出 1（`run-suite-red2.log`）。
- **门禁**：ridgraph 20 / packs 25 / hap-targets 80 / host-registry 6 / bridge 12 / hygiene 25 全 0 failed；像素
  **PIXEL ASSERTIONS PASSED**；`selftest-tasks` 在并发构建下两次卡于 S2 之后（环境，非本波改动）。
- **宿主/壳**：`build-host.sh` 157/157、UND 249、DT_NEEDED 白名单不变（签名件复用主树 330,656/`89438ade…`）；
  `CompileArkTS Finished`；ui abc **469,652 B / `d61ae0d2…`**、headless **24,324 B / `798b2477…`** 不变，四 pack 同字节。

## 3. 提交 / 构建 / 真机（部分）

- ow：`83f9fc9`（host / 壳+托管+测试 / abc / 样例触发器 / 壳诊断日志，五段普通推送）· maui：`483bb3a9f3`；
  #49/#50 发布资产未动、无强推；abc provenance `--check-pack-abc` 通过。
- **真机（01:0x，JIT hap 125,836,477）**：`openweb`（onNewWant）→ 子窗 create/bound `first frame=True` +
  `OHOS_MAUI_SUB: child web host registered: max=2 surface=sub-1` + `child web capacity advertised`×2；截图 = 子窗
  第二 MAUI 树；plain 轮主窗 `framestats main fps=60.0 long=0`。**未证**：managed 消费 capacity / `child web load`
  未出现（managed stdout 启动后停止可见 + 冷启 ThreadBlock6S 干扰；该 fault 10-05 已有旧记录）→ 见 §5。

## 4. 余项 / 风险 / 降级边界

- **子窗 hybrid/blazor 资产桥**显式拒绝（不建组件、命令丢弃、eval 立即回错）；下一波 = 壳侧 `onInterceptRequest`
  serving 移植 + managed 注册回放按窗。**子窗 B6 导航否决未接**（外部导航直载，主窗不变）；**子窗 web × a11y
  provider** 由实施 a 分支承担。子窗池满（>2 并发控件）多余控件不挂载；预就绪队列溢出丢 1 行日志。
- **未证/降级**：非主窗 ArkWeb 引擎与 managed→子窗命令链真机未闭环；失败即维持“子窗 web 不挂载”（主窗零回归）。

## 5. 上机卡（余项：managed 消费→load→交互→关闭；约 15–25 min）

前置：§3 的 JIT hap（含诊断日志）。① 主窗起稳 30s（避开冷启 ThreadBlock）→ `-U app://subwindow/openweb`
（onNewWant；冷启首帧 `-U` 未送达）→ 期望新增 `child web capacity: sub-1 2`（managed）与 `child web load (slot 0)`
/ `child web page (slot 0)`（壳）；② 截图子窗内 `CHILD WEB OK`；③ 点标题 → `CHILD WEB TAP`（或 managed eval
`document.title`）→ `child web eval title=`；④ 双窗帧率：主 ≥50 fps、较单窗退化 ≤10%、>33ms×3=0；既有 web/overlay
用例不回归；⑤ `-U app://subwindow/close` → `child web slot destroy: 0`、WMS 无残窗、fault 增量=0。回传：设备/包/
时间 + 每步 OK/FAIL + hilog ≤20 行 + 截图 2 张；失败附 `hilog -x > fail.raw` 与 `uitest dumpLayout`。
