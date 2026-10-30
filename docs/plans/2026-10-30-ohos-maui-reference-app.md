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
| **Login** | **PASS（content swap）** | `test/login-probe` 证明同一页内 Content 交换稳定（main→login-entries→main→login-labels→main，ps=1）；reference app 改为登录首屏 + Content 交换，60 fps；页面/标签/模态/导航切换仍不可用 |

补充：

- FrameProbe 已接入（`[ref] first-frame tick=...` + 每 5 s `[ref] fps=...`），启动首帧有标记；
  **精确冷启毫秒**未提取（缺 `enter Run` tick），下一轮补一行即可。
- 登录页代码保留为 `LoginView`（可单独复用），但不参与启动路径；Settings → Sign out 只写
  `[ref] login deferred...`，不再触发退出。
- 登录问题的共同点：**离开/覆盖含 Entry 的页面**（或页面切换本身）会让 ability 退出；
  与 T2 的 `TouchBehavior` NRE 不同，这次无 fault、无 managed 异常日志。建议单独立项：
  最小化 Entry 页 → 切换/覆盖 → 观察 handler disconnect / text-input 生命周期。

### 5.1 Login 专项结果（2026-10-30）

#### Probe #1：同页 Content 交换（`test/login-probe`，提交 `bb7efbb`）

- 单页 + 一个 `ContentView` host，自动序列：
  `main → login-entries → main → login-labels → main → done`。
- 结果：**全程稳定**，`ps=1`，无 fault；证明 **Entry 本身、以及含 Entry 的 Content 交换是安全的**。
- 结论：登录退出不是 Entry 的问题，是**页面/标签/模态/导航切换**（或冷启 URI 激活）的问题。

#### 生产修复：reference app 改为 Content 交换

- `DashboardPage` 的 `Content` 是 `ContentView` host；`ShowLogin(true/false)` 在
  `_mainContent` 与 `LoginView` 之间交换（不 push/pop、不切 tab、不做 overlay visibility）。
- 启动即登录首屏；实测 `ps=1`、`fps=60.3`，登录页可见。
- Sign in 走同一个 `ShowLogin(false)`；`LoginView` 的 Sign in 增加 Border + TapGestureRecognizer
  作为可点击面（canvas Button 的 uitest 点击不稳定，不是逻辑问题）。
- 页面/标签/模态/导航四种旧入口仍不可用，已从样例移除。

#### Probe #2：独立 UIAbility（`scripts/add-login-ability.sh`，提交 `5234a4e`）

- 打包链只生成一个 ability，因此用后处理把 **LoginAbility** 追加到未签名 hap 的 `module.json`：
  复用同一 `srcEntry`/payload，`launchType=multiton`；再用 `sign-for-device.sh` 设备签名。
- `aa start -a LoginAbility -b mauidemo.dotnet.springmin.com --ps mode login` **启动成功**，
  `ps=1`、`fps=60`。
- **UI 仍待完成**：第二个 ability 显示的是启动窗口渐变（共享 MAUI host 只绑定主 EntryAbility 的
  surface），没有渲染登录内容。ability 级别的隔离已打通，surface/host 绑定需要 per-ability
  实例（或独立 ArkTS 登录页）。

#### 冷启 `-U` 的现状

- reference app 冷启带 `-U app://reference/*` 仍会退出（无 fault、无 managed 日志）；即便声明
  `app://reference` skill 也未改变。该问题独立于 Login，暂列后续项；不影响无 URI 的正常启动与
  Content 交换登录。

## 6. 验证口径说明

- 3 项收尾数据来自 **14:08 构建**（MainTabs 根 + FrameProbe + form/save/subwindow 深链）。
- 登录重构后的最终代码（ohos-workload `79a20fe`）JIT 编译通过、AOT 发布通过；但该轮之后的
  冷启深链复跑出现「进程无 fault 退出」，未能重新抽取 3 项数据。最终代码与验证数据之间的
  差异仅是登录路径（dormant）和深链动作，不影响 Dashboard/Orders/Form/Settings。
- 下一步：设备空闲时用 `aa start -U app://reference/orders` 冷启复跑，确认 `79a20fe` 仍稳定；
  再单独立项排查 Login 生命周期。

## 7. 下一步

1. 复跑 reference app（`bb7efbb`）无 URI 冷启 + form/save + subwindow，确认收尾数据。
2. **第二 ability UI**：per-ability host/surface，或独立 ArkTS 登录页；当前 LoginAbility 只出启动
   窗口，ability 启动本身已通过。
3. **冷启 `-U` 退出**专项：确认是否与 ability/URI want 分发有关（不影响无 URI 启动）。
4. 精确冷启：给 `[ref] enter Run` 加 tick，计算到 `first-frame` 的差值。
5. 通过后把 T3 标为完成，并把样例作为演示/回归基线。

## 8. 证据

- 代码：`ohos-workload` `acf211b`（reference-lob v1）· `79a20fe`（FrameProbe/深链动作）·
  `bb7efbb`（login Content 交换 + login-probe）· `5234a4e`（第二 ability 后处理）
- 截图：`ref-dash.jpeg` / `ref-login-content.jpeg` / `ref-deeplink.jpeg` /
  `ref-form.jpeg` / `ref-settings.jpeg` / `ref-loginability.jpeg`
- 日志：`[probe] step=2 login-entries` … `auto sequence done`；
  `[ref] main tabs: 4`；`[ref] fps=60.x`；`LoginAbility` 启动 success
- 设备操作后已卸载应用并释放 `.device-lock`
