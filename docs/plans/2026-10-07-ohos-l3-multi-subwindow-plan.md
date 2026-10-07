# L3-MULTI-SUBWINDOW：多 managed 子窗产品化立项（2026-10-07）

> 承接 L2CAP（`2026-10-06-ohos-l2-subwindow-capacity-probe.md`）：平台允许 **255 并发应用子窗**，
> 现壳契约 N=1（`app://subwindow/demo` 第二 managed id → 801）是**产品限制而非平台限制**。
> 本文立项把 N 提到 K（M1 先做 **N=2**）并复用 L/L2 资产：M1 宿主 window-id 注册表（163 导出面）·
> M2 切片 per-window surface/renderer · M3 壳 XComponent + 输入路由 · M4 焦点/IME/a11y 分区 ·
> L2 child web 槽池 + 子窗 a11y provider。
> 基线：ow `696ebc0` · maui `bb6b06990d`（套件 688/690 floor 670、导出 163、abc 473,048）。
> 口径：单人粗估人日（含自测/真机轮/文档，不含上游评审）；每 M 从 master/feature tip 切独立分支，
> 验证通过后单独合并；不并 master、禁强推；探针/日志不落库；真机按设备锁协议。

## 1. 范围（产品口径）

- **壳会话**：一个 managed 子窗 = 一个壳会话，键 = managed surface id（`sub-N`，唯一、最低空闲复用）；
  子窗名 `ohos_dotnet_subwindow__<surfaceId>`；容量 `SUB_WINDOW_MAX`（M1=2，可上调）。
- **managed 多窗**：`Application.OpenWindow` ×K → 每窗独立 surface/renderer/输入/生命周期；
  宿主 window-id 路由直接复用（**不加导出**）；超出容量诚实拒绝（801/NotSupported）。
- **每窗分区**：焦点/激活（Activated/Deactivated）、suspend/resume（主窗隐藏广播）、IME（按窗
  focus 请求 + tagged 文本/按键）、a11y（per-instance provider / 影子帧按窗）、overlay/alert 归属、safe-area。
- **child web**：子窗 ArkWeb 槽池按窗归属（现在是「单 child sink，后注册覆盖」），hybrid/blazor 资产桥
  维持主窗专用/拒绝（L2 边界不变）。
- 不在范围：`TYPE_FLOAT` 系统浮窗、跨窗纹理共享、手机/release 域外推（E1）。

## 2. 里程碑

| # | 范围 | 人日 |
|---|---|---|
| M1 | 壳会话注册表 + managed N=2 共存（创建/关闭/重开/容量） | 3–5 |
| M2 | 每窗身份握手 + 生命周期/焦点 N=2 闭环（并发/串扰/回收） | 3–5 |
| M3 | 每窗 IME/a11y/overlay/Back（第二 provider 并发） | 5–8 |
| M4 | child web 按窗槽池 + 长稳/性能 + 资产重建 + kit 收口 | 5–8 |
| 合计 | | **16–26（≈3–5 周）** |

### M1 壳会话注册表 + managed N=2 共存 —— 3–5 人日（**本轮完成**）

- 壳 `Index.ets`：`SubWindowSession{window,id,surfaceId}` + `Map<surfaceId,session>`（`''`=drawn M 路径）；
  create 幂等/容量 801；create/close/move/resize/show/text-focus 全按 `cmd.surfaceId` 定位
  （无 id 且唯一 session 才回落，否则拒绝）；每 session 的 state/closed/failure payload 带 surfaceId；
  child HIDDEN 只在「末个 session」时触发全局 suspend；page teardown 销毁全部 session。
- maui：`OpenHarmonyMauiAppHost.MaxManagedSubWindows=2`（deferred 满则诚实拒绝，不再单例短路）；
  `NotifyWindowClosed` 用 `OpenHarmonySubWindow.Close(shellCloseId)` 定向关会话；
  `OpenHarmonySubWindow.Close(string windowId)` 新 payload（表面新增 API，非 host 导出）。
- 样例：`test/hello-maui-app` 子窗列表 ≤2、每窗独立计数、open 追加/close 关最新。
- 测试：套件 +10 checks（双 session deferred/bind、输入/帧按窗、shell-Closed 定向、重开定向关、
  容量拒绝、shell/slice source pins）；**红控**（恢复单例短路上游/去掉定向关）→ 对应 assert=False。
- 退出：套件绿（`698/floor 681`，0 Unhandled）、导出 **163/163 不变**、宿主零改动（preflight 仓库门禁 + host 单测）；
  主窗零回归；真机 `windows=2`/close-reopen 抽验（无设备则顺延，见 §5）。

### M2 每窗身份握手 + 生命周期 N=2 闭环 —— 3–5 人日

> **结果（2026-10-07）**：已落地分支 ow/maui `l3/m2-identity`（离线套件 716/719、真机 N=2 全绿；含宿主 op 上限
> 修复）；详见 `2026-10-07-ohos-l3-m2.md`。M3–M4 未开工。

- 范围：子页身份由「名字前缀 + getLastWindow」升级为**确定性握手**（每窗 LocalStorage 可靠时优先，
  否则 per-child AppStorage 序号/claim 队列），并发 create 不串绑；`SUB_EVENT_*` 全量带 surfaceId；
  主窗隐藏 → 两子窗各停一次；聚焦切换 A→B 只动对应窗；WM 关闭按钮/悬停回收；churn ×20。
- 文件：`Index.ets`、`SubWindow.ets`、`host_window_registry.c`（如需按窗顺序）、maui `OpenHarmonyWindowHost`/app host、套件。
- 测试：离线双窗生命周期序列（幂等/无重复 Stopped）、身份握手负例（错名字 → 拒绝挂载）、真机 churn/回收。
- 退出：N=2 创建/关闭/重开/并发无串扰；套件增量；主窗与单窗路径零回归；WMS 关闭后 0 残留。
- 风险：getLastWindow 语义（预研未知项）→ 握手 + 负例红控。

### M3 每窗 IME/a11y/overlay/Back —— 5–8 人日

> **结果（2026-10-07）**：已落地分支 ow/maui `l3/m3-services`（离线套件 723/726 floor 706、真机 N=2 采到
> IME 切换/a11y status=1×2；Back/overlay 受 UI 注入限制记人工卡）；详见 `2026-10-07-ohos-l3-m3.md`。
> M4 未开工。

- 范围：IME 按窗（op 6 + AppStorage 请求已带 surfaceId，补两窗互斥/关闭清理）；a11y 第二
  per-instance provider 并发（节点表按 instance/window 分区、action 归属、发布互不覆盖）；
  overlay/alert 按窗归属（A 的 alert 不 gate B）；每窗 Back；safe-area 每窗。
- 文件：`Index.ets`/`SubWindow.ets`（重点 attachAccessibility/焦点通道）、`host_a11y_table.*`、
  maui `OpenHarmonyAccessibility`/`OpenHarmonyAlertHost`/`OpenHarmonyWindowInputRouter`、套件。
- 测试：离线双窗 a11y 发布/action/密码屏蔽、IME 焦点序列、alert 隔离；真机 a11y selfcheck
  status=1×2、键盘跟随点击窗、Back 归属；红控（第二窗覆盖第一窗帧/动作串窗）。
- 退出：双窗各自 a11y provider 就绪且互不覆盖；IME 只随聚焦窗；alert/Back 归属正确；主窗 provider 零变化。
- 风险：provider 并发（单 NodeContent/单 action 监听的历史结构）→ 时间盒 ≤2pd 原型，超限走降级线。

### M4 child web 按窗槽池 + 长稳/性能 + 收口 —— 5–8 人日

- 范围：child ArkWeb sink 按 surfaceId 注册/分发（现单 sink 后注册覆盖）、容量按窗、defer 队列按窗；
  hybrid/blazor 维持拒绝；双窗 overlay z-order/隐藏；40min 双窗长稳 + 帧率/内存对照；
  packs/abc/provenance 重建 + L3 consolidate 文档。
- 文件：`SubWindow.ets`（槽池声明参数化/按窗 sink）、`host_napi.cpp`（child sink 多路，如需则加 1 个
  导出并同步 163→N）、maui `OpenHarmonyChildWeb`/web handlers、套件、`verify-kit`/provenance。
- 测试：两窗各开 web（load/frame/history/eval 不串）、关 A 不动 B 的槽、长稳采样（RSS/线程/fd/fault）、
  AOT 切片 0 IL gate；套件 floor 上移；kit 资产重建校验（`--check-sources`/`--check-pack-abc`）。
- 退出：两窗 web 独立可用；长稳无泄漏/单调增长；主窗 web 池零回归；L3 文档收口、下一 kit 可切。

## 3. 风险

| 风险 | 影响 | 缓解 |
|---|---|---|
| 子页身份（getLastWindow/名字前缀）双窗歧义 | 串绑 surface、输入串窗 | M2 确定性握手 + 负例红控；M1 已知边界 |
| a11y provider 并发（instance 表/action 单监听） | 帧覆盖、动作串窗 | 按 instance/window 分区 + 双窗离线红/绿；降级线 |
| IME 全局焦点通道与窗焦点竞争 | 键盘跟错窗、关窗后残留焦点 | 请求带 surfaceId+seq、页侧过滤；关最后会话清请求 |
| 每窗 overlay 隔离（主窗 overlay host 仍全局） | z-order/触摸穿透 | child web 按窗 sink；overlay 归属离线 pin + 真机 |
| 内存/性能（双窗 ≈ 双树+双 surface） | RSS/帧率回落 | 冻结阈值（2 窗稳态 VmRSS ≤ 400MB、60/60fps）；40min 长稳 |
| 平台行为外推 | 手机/release 结论失真 | 仅 2in1 debug 域结论；E1 标注 |

## 4. 与 kit 节奏

- L2 = kit #51（已切）。**下一 kit 即 L3 载体**：M1 本轮落分支不入 kit；M2–M3 验证后由
  consolidate 波次合并 `master`/`feature/openharmony`，再按既有节奏切 kit（#52），
  重建 packs/abc/provenance 并以 `verify-kit` 锚定；#51 资产不动。

## 5. M1 结果（2026-10-07，分支 `l3/multi-subwindow`，待并）

- 落地：见 §2 M1；host 导出 **163 不变**（零新增）；abc 重建 **ui 476,516 B / `eba25990…`**（四包一致 + provenance 同步）、headless 24,324 不变。
- 测试：套件 `checks=698 total=701 floor=681 assert=True`（新增 10 行全绿：双 session deferred/bind、输入/帧按窗、
  shell-Closed 定向、重开+定向关、容量拒绝、shell/slice source pins）；红控 2 组（恢复单例短路 → `second deferred/bound/input` False；
  去掉定向关 → `reopen targeted close`+`slice source` False）后还原复绿；`selftest-verify-kit` 129/0。
- 分支/提交：ow `l3/multi-subwindow` = `8cd9f1c`（shell+sample）+ `320a862`（4 pack abc）+ `60c5724`（套件）
  + `ec0a6e4`（verify-kit 重锚）· maui `l3/multi-subwindow` = `fd7451adbf`；均普通推送、未并 master、未强推。
- 环境注记：并行会话使优先的 `csc` 出现 >15min 病态慢编译（纯 CPU、非代码问题）；最终复跑以
  `-p:RunAnalyzers=false` 重建（IL/行为不变），preflight **5/5 全绿**（interaction `698/floor 681`、pixel PASS）。
- 真机：本环境无 hdc/设备不可达（锁空闲但无目标）→ N=2 真机抽验（windows=2/输入分窗/
  定向关/重开/主窗零回归）顺延至设备可用轮；不阻塞离线交付。
- 降级线：M1 若真机 create 第二子窗异常 → 保留 N=1（801 诚实拒绝，壳单实例行为），
  M2–M4 暂停；a11y/child web 任一超时间盒 → 该项独立降级（主窗路径零变化），其余照常。

> **L3-M1 收口（2026-10-07）**：三支（`l3/a11y-cleanup` + `l3/web-assets` + `l3/multi-subwindow`）已**一次并存合并主线**（ow `master` `5488b41`+`cf2c9d2`+`3a16d3c`、maui `feature/openharmony` `d1d485bb67`）；合并树 abc **512,304/`eae87765…`**、套件 **701/704 floor 684**、导出 **164/164**；真机 N=2 抽验通过（`windows=2`/输入分窗/定向关/重开/主窗零回归，HAD-W32）；**#52 待切**；见 `2026-10-07-ohos-l3-consolidate.md`。M2–M4 未开工。
