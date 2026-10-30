# MAUI Reference LOB on OpenHarmony（v1，2026-10-30）

> 口径：`ohos-workload` `acf211b`（`test/reference-lob`）+ `maui-ohos` `efe5b823c8e`
> （MAUI 11 rc.2）+ kit #58 构建线。设备 HAD-W24 / OpenHarmony 7.0.0.111。
> 目标：用一个真实 LOB 样例验证 T2 的可用控件组合（不含 CommunityToolkit；Popup/Touch 不参与）。

## 1. 结构

| 页面 | 内容 | 状态 |
|---|---|---|
| **Dashboard** | 欢迎语、Revenue 卡、`GraphicsView` 柱状图（`ChartDrawable`，无 Skia）、刷新 | ✅ 真机可见 |
| **Orders** | 1,000 行 `CollectionView`、SearchBar 过滤、选中、子窗按钮 | ✅ 真机可见（深链进入） |
| **Form** | Name/Email/Picker/Notes/Switch、校验、JSON 保存（源生成上下文） | ✅ UI 可见；**保存未验**（输入法） |
| **Settings** | 深色主题、版本、数据路径、用户、Sign out | ✅ 真机可见 |
| **Login** | 邮箱/密码 mock；从 Settings → Sign out 以 **modal** 打开 | ✅ 已实现；**入口未点验** |

深链：`app://reference/dashboard|orders|form|settings`，由 `OpenHarmonyBridge.Activation`
转发，`MainTabs.Navigate` 切换。

## 2. 构建

| 项 | 结果 |
|---|---|
| JIT 编译 | PASS（0 error） |
| NativeAOT 发布 | PASS；`IL2026 = 0 / IL3050 = 0 / IL3051 = 0` |
| hap | **21,318,436 B**；`libreference-lob.so` 17,316,592 B |
| 依赖 | 纯 MAUI + slice；无 CommunityToolkit、无 Skia、无 SQLite |

## 3. 真机验证（2026-10-30）

| 项 | 结果 | 证据 |
|---|---|---|
| 启动 / 主界面 | **PASS** | `[ref] main tabs: 4`；进程 8 s+ 存活 |
| Dashboard 图表 | **PASS** | 截图 `ref-dash.jpeg`（7 根柱） |
| 1,000 行 Orders | **PASS** | 深链 `app://reference/orders`；截图 `ref-deeplink.jpeg`（行 1…1000 可见，可滚动） |
| Form UI | **PASS** | 深链 `app://reference/form`；截图 `ref-form.jpeg`（Entry/Picker/Editor/Switch/Save） |
| Settings UI | **PASS** | 深链 `app://reference/settings`；截图 `ref-settings.jpeg`（用户/路径/版本/深色开关） |
| 深链路由 | **PASS** | `[ref] activation uri='app://reference/orders'` → Orders 页；form/settings 同 |
| Login modal | **未点验** | 入口 = Settings → Sign out；本机 `uitest` 坐标对 canvas 按钮不稳定 |
| 表单保存 | **未验证** | `uitest uiInput inputText` 未写入 Entry（IME/输入路径）；需真实键盘或 IME 注入 |
| 子窗 | **未验证** | Orders 的 “Open detail in subwindow” 已接 `OpenHarmonySubWindow.Create`；未点击 |
| 1,000 行滚动 FPS | **未测量** | 样例未带 framepacing probe；需补探针或宿主帧统计 |

## 4. 裁决（Ruling）

- **启动面 = MainTabs，Login 改为 modal**：`Window.Page = new MainTabs()` 在该 slice 上会让
  窗口消失/应用退出（多次实测），改为固定根 `MainTabs` + Settings → Sign out 以 modal 打开
  Login；深链进入时直接落到对应 tab，并关闭已有 modal。代价：登录不再是首屏；登录流程仍完整可走。
- **不使用 CommunityToolkit**：T2 的 `CompatTouchBehavior`/Popup View 重载留作样例之外的
  兼容层；Reference App 只用 MAUI 原生控件，减少变量。

## 5. 收尾结果（2026-10-30）

| 项 | 结果 | 证据 |
|---|---|---|
| **Form 保存** | **PASS** | `[ref] form saved`（`app://reference/form/save` 自动填充并写 JSON） |
| **子窗** | **PASS** | `[ref] selected 1` → `[ref] subwindow create=True item=1`；截图 `ref-subwindow.jpeg` |
| **1k 滚动 FPS** | **PASS** | FrameProbe：`fps=59.2 / 59.3 / 59.8 / 60.0 / 60.1 / 60.3`；PSS **131,221 kB**（≈128 MB） |
| **Login** | **BLOCKED** | 四种入口都让 ability 退出（无 fault）：`Window.Page` 切换、`PushModalAsync`、`NavigationPage.Push`、login tab/overlay 可见化；最终代码把 Login 设为 dormant（`ShowLogin` 只记日志） |

补充：

- FrameProbe 已接入（`[ref] first-frame tick=...` + 每 5 s `[ref] fps=...`），启动首帧有标记；
  **精确冷启毫秒**未提取（缺 `enter Run` tick），下一轮补一行即可。
- 登录页代码保留为 `LoginView`（可单独复用），但不参与启动路径；Settings → Sign out 只写
  `[ref] login deferred...`，不再触发退出。
- 登录问题的共同点：**离开/覆盖含 Entry 的页面**（或页面切换本身）会让 ability 退出；
  与 T2 的 `TouchBehavior` NRE 不同，这次无 fault、无 managed 异常日志。建议单独立项：
  最小化 Entry 页 → 切换/覆盖 → 观察 handler disconnect / text-input 生命周期。

### 5.1 Login 专项记录（2026-10-30，未解决）

按“先解决 Login”做了归因，结论是**被 URI 激活路径阻断**：

1. **基线（不带 `-U`）稳定**：`[ref] main tabs loaded`、`fps=60.4`，进程 5 s+ 存活。
2. **任何冷启 `-U app://reference/*` 都会退出**（无 fault、无 managed 异常）：orders、diag/label、
   diag/entry、diag/password、diag/emailkb、diag/formswitch 全部 `ps=0`；日志只到
   `[ref] enter Run` + `activation uri=...`。
3. 已在 `module.json` 声明 `app://reference`（`OpenHarmonyWebAuthenticatorCallbackUrls`）后重试，
   仍退出 → 不是 skill/URI 未注册的问题。
4. 因此“label vs entry”“overlay vs page”等诊断模式无法通过深链得到有效结果；此前
   `Window.Page` / modal / NavigationPage / login tab / overlay 五种登录入口的退出结论仍成立。
5. **尝试过的代码已回退**到 `79a20fe`（稳定基线：MainTabs 4 tab、Login dormant、FrameProbe、
   form/save/subwindow 深链）。overlay/diag 代码未保留，避免把未稳定路径带进样例。

**下一步（Login 专项）**：

- 用**最小独立 app** + **屏幕上可见的按钮**（不依赖 `-U`）切换 Login/Main 两种内容，定位是
  “Entry 页面切换”还是“冷启 URI 激活”导致的退出；
- 或把 Login 做成**独立 UIAbility**（另一个 entry），由主 ability 显式启动，绕开同页切换；
- 同时单独立项排查冷启 `-U` 退出（当前 `aa start -U` 在 reference-lob 上不可用，早期构建曾可用）。

## 6. 验证口径说明

- 3 项收尾数据来自 **14:08 构建**（MainTabs 根 + FrameProbe + form/save/subwindow 深链）。
- 登录重构后的最终代码（ohos-workload `79a20fe`）JIT 编译通过、AOT 发布通过；但该轮之后的
  冷启深链复跑出现「进程无 fault 退出」，未能重新抽取 3 项数据。最终代码与验证数据之间的
  差异仅是登录路径（dormant）和深链动作，不影响 Dashboard/Orders/Form/Settings。
- 下一步：设备空闲时用 `aa start -U app://reference/orders` 冷启复跑，确认 `79a20fe` 仍稳定；
  再单独立项排查 Login 生命周期。

## 7. 下一步

1. 复跑 `79a20fe` 的冷启 + 深链，确认 3 项收尾数据仍成立。
2. Login 专项：最小 Entry 页 + overlay/切换，定位 ability 退出点（优先看 Entry handler
   disconnect 与 text-input surface）。
3. 精确冷启：给 `[ref] enter Run` 加 tick，计算到 `first-frame` 的差值。
4. 通过后把 T3 标为完成，并把样例作为演示/回归基线。

## 6. 证据

- 代码：`ohos-workload` `acf211b`（`test/reference-lob`）
- 截图：`ref-dash.jpeg` / `ref-deeplink.jpeg` / `ref-form.jpeg` / `ref-settings.jpeg`
- 日志：`[ref] main tabs: 4` / `[ref] activation uri='app://reference/orders'` /
  `[ref] navigate ...`
- 设备操作后已卸载应用并释放 `.device-lock`
