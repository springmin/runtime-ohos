# L8 预研：ArkWeb `window.open` 第二窗可行性（只读，2026-10-08）

> 口径：只读——本机 OH SDK **26.0.0.18 / API26** `ets/component/web.d.ts`（行号 `web:N`）+ 官方文档 `openharmony/docs` `zh-cn/application-dev/web/web-open-in-new-window.md` + `ohos-workload` 壳/套件走查；未构建、未用设备。基线：ow `master` `3ecec5c`（壳 = 四包 `preview.22/23/24/28` `Index.ets`/`SubWindow.ets` 字节一致）· maui `feature/openharmony` `619c40a483` · runtime `feature/openharmony` `98539cf041a`。
> 被审缺口：`2026-10-08-ohos-maui-coverage-gap-audit.md` L8「`window.open` 第二窗（`Index.ets:7500` 现为同组件回退；L，需 ArkWeb 预研）」。

## 1. 能力矩阵（API 面 × 权限 × 壳现状）

| 能力 | API（版本 / d.ts） | 语义 | 壳现状 |
|---|---|---|---|
| 弹窗总开关 | `multiWindowAccess(true)`（s9/11）`web:9837` | 页面可请求新窗；默认 false；开启后须实现 `onWindowNew` | 已开（`Index.ets:7499`，主窗 4 槽 `webOverlay:7290`） |
| 新窗事件 | `onWindowNew(Callback<OnWindowNewEvent>)`（事件对象 s12；旧回调 s9/11）`web:9777`/`web:6948` | `{isAlert,isUserTrigger,targetUrl,handler}`；`event.handler` 即接管柄 | 已接但**未调 handler**：`Index.ets:7500-7511` 把目标同窗 `loadUrl`（`navProgrammatic` 过导航网关） |
| 接管新窗 | `ControllerHandler`（s9/11）`web:2831`；`setWebController(controller)`（s9/11）`web:2861` | 传新组件的 `WebviewController` → 内核完成 `name` 绑定并把弹窗内容注入该组件；传 `null` = 不建窗；**不调用则渲染进程阻塞**（官方文档明示） | 未调用（OAuth 不可用的直接原因之一；W1A 起仅离线 pin，真机行为无记录） |
| 脚本弹窗 | `allowWindowOpenMethod(true)`（s10/11）`web:10336` | `window.open` 脚本触发必需；false 时仅「用户操作后 5 s 内」算用户行为，非用户行为不开窗 | 未开（无用户手势的弹窗今天不触发事件） |
| 关闭通知 | `onWindowExit(() => void)`（s11）`web:9817` | 新窗组件收到页面 `window.close()` | 未接 |
| 同名复用 | `onActivateContent(() => void)`（s20）`web:11073` | `window.open(url,name)` 命中已绑定组件 → 该组件收到，应置前台 | 未接 |
| 尺寸/策略扩展 | `onWindowNewExt`/`WindowFeatures`/`NavigationPolicy`（s23）`web:7072` | 取 width/height/x/y 与 NEW_POPUP/NEW_WINDOW 等策略 | 未用（API26 本机可用；API21 目标只能基础形 `onWindowNew`） |
| 承载窗 | 壳已有 `createSubWindowWithOptions`（M/L/L3）+ 子窗 ArkWeb 第二宿主（L2，`SubWindow.ets:275/2171`） | 应用内子窗可挂 Web 组件；官方另有「Web 组件跨窗迁移」（BuilderNode/NodeController）篇 | L3 会话表/身份/输入/IME/a11y/child web 全按窗 |

权限：以上均无 ACL/权限要求（syscap `SystemCapability.Web.Webview.Core`）。

## 2. 可行性路径

**A（推荐目标）：壳接管 `onWindowNew` → 新建应用子窗承载弹窗（复用 L3/L7 骨架）**
- 改动面（**壳 only**：零托管/宿主/导出改动，导出 164/164 不变）：
  - `Index.ets`（四包）：`.allowWindowOpenMethod(true)`；重写 `onWindowNew`（`7500`）→ 容量内 `createWebPopupWindow(event)`：复用 `createSubWindow`（`2754`）/`createSubWindowWithOptions`（`2795`）建**壳直管弹窗会话**（新 key 空间 `web:N`、加 `kind` 区分，避免混入 managed 身份握手/状态上报；计入 `SUB_WINDOW_MAX`（`773`））；主窗创建的新 `WebviewController` 经共享桥（模块态 registry 或 AppStorage；后者需探针）交子窗页；随后 `event.handler.setWebController(controller)`；容量满/建窗失败 → `setWebController(null)`（诚实）＋日志（同窗回退保留与否 = 产品口径）。
  - `SubWindow.ets`：新增 popup 模式（独立单槽 `Web({src:target,controller})` + `.multiWindowAccess(false)`（嵌套弹窗回落本地窗）+ `.onWindowExit` → 关窗 + `.onActivateContent` → show/front；**不**接入 `subWebControllers` 托管池/child sink）。或新页 `WebPopup.ets`（更净，+打包改动）二选一。
  - 测试/打包：套件 w6 旧同窗回退 pin 必须更新（`test/maui-platform-verify/Program.cs:6193`、`README.md:805`）+ 新 popup pin/红控；四包 abc/provenance + `verify-kit` EXPECT 重锚。
- 成本（单人粗估）：跨窗绑定探针 0.5–1 pd · 壳实现 2–3 pd · 离线门禁/abc/kit 1 pd · 真机 1–2 pd → **合计 ≈4.5–7 pd（L）**。A2 托管中介变体（走 L3 OpenWindow/child web 路由，弹窗进 MAUI 窗口栈）再 +2–3 pd，不建议首版。
- 关键未知（探针先行，见 §3）：①「主窗创建的 `WebviewController` 绑定到另一窗口的 `Web` 组件」跨 UIContext 是否成立（官方样例仅同页 `CustomDialog`；第三方 PC 文有 `createSubWindow` 变体；无平台层承诺）；②原生 backing 的 controller 对象跨页传递（模块态 per-UI-instance 共享 vs AppStorage；兜底 = 子窗先建 controller、主窗延迟 `setWebController`）；③`window.opener`/`postMessage` 往返与 `name` 绑定在异步建窗时序下是否守恒。

**B（对照/降级）：主窗内嵌弹窗组件（官方 `CustomDialog` 形）**
- `Index.ets` 新增不与槽池冲突的弹窗 Web 组件，`setWebController(popController)`；恢复 `window.open` 语义（opener/close）但**不是第二窗**、不占子窗容量。成本 ≈1–2 pd + 0.5 设备；风险最低，可作 A 第一段抢修或 A 失败/容量满时的降级（优于现行同窗 `loadUrl`）。

**C（边界/不可行）**
- 放弃 handler 的同窗回退维持现状：官方口径下渲染进程阻塞且 opener/close 语义不可得；仅 `setWebController(null)` 为诚实兜底。
- 平台/产品边界：手机域与 release 未测（E1）；并发吃 `SUB_WINDOW_MAX`（默认 2，超限拒绝，与 L7 合并）；`isAlert`/tab-vs-popup 未映射；弹窗 a11y 依赖 ArkWeb 内建（壳 provider 不覆盖）；`setWebController` 参数在 d.ts 非 nullable（官方样例传 `null`，ArkTS 编译需实测）。

## 3. 推荐与依赖

- **推荐 A 两段走**：先 0.5–1 pd 真机探针（只证 §2-A ①②③，临时分支、不动 kit/资产）；成立后产品化壳直管弹窗（A1）；不成立即落 B 并记录平台边界。
- 依赖/关系：**L7 N 子窗** = 容量前提与开关同源（弹窗共享 `SUB_WINDOW_MAX`/rawfile 开关，不要第二上限；N>2 抬升同时抬高弹窗余量）；**B6/nav** = 弹窗导航策略（v1 建议浏览器式直载：不注入 `dotnetHost`、不做 managed `Navigating` 否决，否则 OAuth 跳转链被拦；保留 URL 长度/协议白名单；按 ArkWeb「新窗来源不可信」告警收紧默认）；**L2 子窗 child web / WebAuthenticator** = 不复用弹窗宿主，入口/收尾与 child web 池及 L3 会话上报隔离。

## 4. 风险

| 风险 | 等级 | 缓解 |
|---|---|---|
| 跨窗 controller 绑定不成立 | P0 | §3 探针先行；失败落 B |
| 不调 `setWebController` 阻塞 renderer / 调用时序 | P1 | 所有分支显式调用（controller/null）；探针记录时序 |
| 语义：opener/postMessage、`name` 复用、`window.close` | P1 | 真机矩阵（§5）+ 引擎绑定语义为官方保证项 |
| focus/IME：弹窗输入与壳 IME/焦点回主窗 | P1 | 弹窗用 ArkWeb 内建键盘；真机输入与焦点回切抽验 |
| 生命周期：用户关/主窗关/应用退、WMS 残留、同名重开 | P1 | `onWindowExit` + WMS 残留/ churn 检查；会话 kind 隔离 |
| 安全：不可信弹窗内容 | P1 | 无 `dotnetHost`、URL/协议白名单、容量与 `isUserTrigger` 口径 |

## 5. 测试策略

- 离线：w6 pin 更新 + 新 popup pin（源码契约：`setWebController`/`allowWindowOpenMethod`/容量与失败分支）+ 红控（去分支 → assert=False）+ 四包字节一致 + abc/provenance/`verify-kit` 重锚。
- 真机（HAD-W32 2in1 / API26、锁协议）：先探针（绑定成立 + 内容渲染）；再 e2e——用户点击/脚本/`target=_blank` 三态开窗、opener `postMessage` 往返、同名复用置前、`window.close`/用户关/主窗关、容量满不挂、弹窗内输入/IME、焦点回主窗、fps/RSS、churn ×10、0 fault、WMS 残留。域外不外推（E1）。

> 提交：本文件 + `README.md` 索引 → runtime `feature/openharmony`（`commit-paths.sh` 限路径；直推，被拒 fetch/rebase + 旁路钉 `140.82.112.3`，不 force）。不确定项：跨窗绑定（探针前不下结论）；现行回退真机行为无证据；API21/HarmonyOS 域 `onActivateContent`(@20)/`onWindowNewExt`(@23) 可用性需按目标设备复核。
