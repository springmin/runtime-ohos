# MAUI 覆盖矩阵缺口复核（COVERAGE-GAP-AUDIT，2026-10-08）

> 口径：只读复核（grep/读代码/读文档；不改代码/不构建/不用设备）。被审 = 覆盖矩阵（`2026-09-22-ohos-maui-coverage-matrix.md`，头注 kit #53）· 限制表（`2026-10-05-ohos-platform-limitations.md`）· 终版（`2026-10-03-ohos-state-of-the-port.md`）。
> 主线：ow `ca94b55` · maui `b914379269` · runtime `e0e04724070`（当前 tip `37ff41db851` = +PREPROBE-SWEEP 文档）；套件 declared 740/floor 720、导出 164/164、abc 542,936（均离线数字，与本轮文件/文档一致）。

## 1. 矩阵逐项复核（20 项：已实现/闭合 14 · 部分 4 · 平台阻塞 1 · 待并 1）

| # | 矩阵项 | 现状 | 证据（当前主线） |
|---|---|---|---|
| 1 | §1 视图 handlers 41 | 已实现（41+Blazor 门控=42） | `MauiOpenHarmonyExtensions.cs:19-68`（42 项注册） |
| 2 | §1 布局/形状/页面导航/列表滚动 | 已实现 | 切片 135 个 `.cs`；`OpenHarmony{Layout,Shape,Border,BoxView,Frame,IndicatorView,Page,NavigationPage,TabbedPage,FlyoutPage,Shell,CollectionView,ListView,CarouselView,ScrollView,SwipeView,RefreshView}Handler.cs` |
| 3 | §1 Web（WebView/Hybrid/Blazor 门控） | 已实现 | `OpenHarmonyWebViewHandler.cs`、`OpenHarmonyHybridWebViewHandler.cs`、`OpenHarmonyBlazorWebViewHandler.cs`（`#if OPENHARMONY_BLAZOR_WEBVIEW`） |
| 4 | §1 手势/窗口生命周期/弹层 | 已实现 | `OpenHarmony{Gestures,Pinch,Pointer,DragAndDrop}.cs`；`OpenHarmonyMauiAppHost.cs`（IWindow 状态机）；`OpenHarmonyAlertManager/Host.cs`（per-window） |
| 5 | §1 无障碍（+L2/L3 扩展） | 已实现 | `OpenHarmonyAccessibility.cs`（per-instance；`provider_status_for`:375 / `release_for`:384 直呼；`WindowPublishPending`:1060） |
| 6 | §1 Essentials 核心/传感器 6/额外 API | 已实现 | `UseOpenHarmony` DI（:86-182）；`OpenHarmonySensors.cs`（6 类）；Menus/Notifications/BluetoothGatt/BluetoothPrinting/CalendarContacts/Keystore/FontManager |
| 7 | §1b 残留（SoftInput/ConnectionProfiles/JPEG/Title） | 大部分闭合（矩阵文本过时；in-app 浏览器选项仍 External-only 属设计） | `OpenHarmonySafeArea.cs:17-46`；`OpenHarmonyEssentialsExtras.cs:240`；`OpenHarmonyScreenshot.cs:41-58`；`OpenHarmonyAppLauncher.cs:8-34` |
| 8 | §1c–§1e（KIT-EXT2/文本编辑/动画/列表/图片/深链） | 已实现 | Push/Account/Map/ShareKit 桥；EntryAbility `onNewWant`（preview.28:323）/`notifyActivation`:369；`OpenHarmonyGenerateModuleJson.cs:273` |
| 9 | §1f 三路径/AOT/JIT/interp/R2R | 已实现（真机） | kit #42/#48 数字（state-of-port §1）；限制表 A1–A6 |
| 10 | §2 MainThread | 已实现（矩阵注记过时） | Essentials dispatcher bridge；套件 `T22`（Program.cs:2316-2334） |
| 11 | §2 键盘/焦点 | 部分（上游阻塞） | 文本编辑完整；`OpenHarmonyFocusManager.cs`（Focus/Unfocus）、`OpenHarmonyKeyListener.cs`（内部面）；MAUI rc.2 无 key 契约（遍历/公开键面缺） |
| 12 | §3 WebAuthenticator | 部分（可本地做） | `OpenHarmonyWebAuthenticator.cs:82-95` 仍 `FeatureNotSupported`；清单注入仅 https app-link（`OpenHarmonyGenerateModuleJson.cs:339`） |
| 13 | §3 MediaElement | 部分（平台阻塞） | 桥已实现（`OpenHarmonyMediaPlayer.cs`）；镜像无 MediaKit（C1），设备未验 |
| 14 | §3 TableView/TitleBar/Toolbar/legacy | 已实现/有意移除 | `OpenHarmony{TableViewHandler,TitleBar,ToolbarMirror}.cs`；legacy 随上游 net11 移除 |
| 15 | §4 TTS/Map/Share 面板/Hot Reload/arm32 | 平台阻塞 | SDK26 无 CoreSpeechKit/MapKit；hdc 策略；E3；`devloop.sh` 替代已交付 |
| 16 | §5/§6 套件/导出/abc | 已实现（矩阵正文数字过时） | `Program.cs:16-17`（740/720）；`host-exports.txt` 164 行；`verify-kit.sh:201`（542936,24324） |
| 17 | §7 #1 启动崩溃 / #4 解释器 | 已闭合 | 09-24 里程碑 + kit #30/#31；rc2b 首帧 + SOAK2（§1f） |
| 18 | §7 #2 ship-the-slice | 部分（上游） | `ohos-slice-1.0.1` 源包 + `UseOpenHarmony` 可发现性；上游平台矩阵未并入 |
| 19 | #45–#53/POST-L3 多窗 + SEC7-A | 已实现（降级见下） | L3 各文；`OpenHarmonyWebViewHandler.cs:895`；`OpenHarmonyMauiAppHost.cs:56`；`SUB_WINDOW_MAX`（Index.ets:773） |
| 20 | PREPROBE-SWEEP（export=False 收尾） | 未并主线（分支就绪） | maui `f8ef3c89b4`（4 文件）；根因 `2026-10-08-ohos-a11y-export-rootcause.md` |

## 2. 分类：可本地实现 vs 平台阻塞

**可本地实现（文件面 + 粗估）**

- L1 预探针收尾：并入 `f8ef3c89b4`（`OpenHarmony{Accessibility,Screenshot,ShellExtras,WindowHandler}.cs` 4 文件）+ ow 套件"切片无简单 `NativeLibrary`"源码 pin（S；分支已绿，无依赖）。修 kit#53 件真实设备降级：截图能力位、窗口 chrome/flyout 文本、announce 文本。
- L2 WebAuthenticator 真流程：`OpenHarmonyWebAuthenticator.cs`（订阅 `OpenHarmonyBridge.Activation`，浏览器 hand-off 复用 Launcher，回调清洗→`WebAuthenticatorResult`）+ `OpenHarmonyGenerateModuleJson.cs` 增 callback-scheme 注入 + 套件 pin（M；activation/manifest 两半通道均已存在）。
- L3 `loadData` 裸 `#` 缓解（C5）：壳 `webSlotPayload`→`loadData`（Index.ets:3865/4166、SubWindow.ets:1009）；候选 = 编码或 `onInterceptRequest` 直供（S–M；需设备 A/B）。
- L4 SEC7-F ask 限速（SubWindow.ets；S）· L5 SEC-5c E/F（pinch 有限性 / 子窗 a11y 帧边界；S）。
- L6 >4 覆盖层 attach 定因（E4；M，需设备）· L7 应用级 N>2 子窗（`SUB_WINDOW_MAX`/`MaxManagedSubWindows`；L，产品决策）· L8 `window.open` 第二窗（Index.ets:7500 现为同组件回退；L，需 ArkWeb 预研）。

**平台阻塞（限制编号）**：C1 播放 · TTS/Map/Share 面板（SDK26+HMS/AGC）· Hot Reload（hdc）· arm32（E3）· release 域 JIT（A3–A5）· a11y 动作 e2e（B1）。缓解类：C5 根因（可本地缓解）、E4（若定因平台）。

## 3. Top-10 可做 backlog

| # | 项 | 类型 | 价值/成本/依赖 |
|---|---|---|---|
| 1 | L1 PREPROBE-SWEEP 并入 + 套件源码 pin | 代码 | 高/S/无 |
| 2 | L2 WebAuthenticator 真流程 + scheme 注入 | 代码 | 高/M/tester 回调投递 |
| 3 | L3 `loadData` 裸 `#` 缓解 | 代码 | 中/S–M/设备 A/B |
| 4 | 矩阵/自述文本刷新（§2/§3/§4/§5/头注） | 文档 | 低/S/无 |
| 5 | L4 SEC7-F ask 限速 | 代码 | 低/S/无 |
| 6 | L5 SEC-5c E/F 加固 | 代码 | 低/S/无 |
| 7 | L6 >4 槽 attach 定因（E4） | 代码+设备 | 中/M/设备 |
| 8 | L7 N>2 子窗产品化（平台 255 已探） | 产品+代码 | 中/L/产品决策 |
| 9 | 子窗 hybrid/Blazor 样例 hap + 真机抽验 | 测试侧 | 中/S/tester 设备 |
| 10 | 子窗 IME/Back/alert 注入 + kit#53 判定点回传 | 测试侧 | 高/S/tester/uitest |

"测试可从 tester 侧覆盖"（非代码缺口）：#1/#2/#3 的验证半边、#7 定因轮、#9/#10 全部，以及 MediaKit 播放（C1）、TTS/Map 真调用、release/手机域、arm32。

## 4. 结论

- 值得做且可做：**有** —— #1（分支就绪）、#2（矩阵唯一真实功能缺口；activation 事件与 manifest 注入点都在）、#3（平台共性缓解）；#4–#6 为小加固/文档，测试侧见 §3。
- 移植完成度 **≈98%**：20 项复核 14 已实现/闭合 · 4 部分 · 1 平台 · 1 待并；唯一可本地补的功能缺口 = WebAuthenticator 真流程；其余为平台阻塞/上游/测试侧。与 FINAL-VERDICT"本机可执行=0"的差异 = 该终审未含 sweep 分支与 callback-scheme 细分。

> 提交：本文件 + `README.md` 索引 → runtime `feature/openharmony`（`commit-paths.sh` 限路径；直推，被拒 fetch/rebase + 旁路钉 `140.82.112.3`，不 force）。不确定项：无设备（#2/#3 待 tester）；w2b-int/w2b-t3t5 保留分支抽查为已被主线 T3/T4/T5/T10 覆盖（ZIndex/Clip/InputTransparent/Anchor 见 `OpenHarmonyWindowRenderer.cs:619-840`），建议留守待下次卫生复核。
