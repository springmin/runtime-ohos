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

## 5. 下一步（T3 收尾）

1. 用真实键盘/IME 填 Form 并保存，确认 `reference-form.json` 落在 `FileSystem.AppDataDirectory`。
2. 选中 Orders 行 → “Open detail in subwindow” → 截图/`OpenHarmonySubWindow.Changed` 证据。
3. 从 Settings → Sign out 打开 Login，填邮箱/密码 → Sign in 回主界面。
4. 为 Orders 加滚动帧率探针（复用 hello 的 FramePacingProbe 模式）或读宿主 `framestats`，
   给出 1k 行滚动 FPS；同时记录冷启（AOT）与 RSS。
5. 验收 8 项打勾后，把 T3 标为完成，并把样例作为演示/回归基线。

## 6. 证据

- 代码：`ohos-workload` `acf211b`（`test/reference-lob`）
- 截图：`ref-dash.jpeg` / `ref-deeplink.jpeg` / `ref-form.jpeg` / `ref-settings.jpeg`
- 日志：`[ref] main tabs: 4` / `[ref] activation uri='app://reference/orders'` /
  `[ref] navigate ...`
- 设备操作后已卸载应用并释放 `.device-lock`
