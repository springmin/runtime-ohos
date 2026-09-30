# UI-AUTOMATION：uitest uiInput 真机驱动轮（kit #35「需人工点击」缺口，2026-09-30）

> 设备 HAD-W32（MateBook Pro）/ OpenHarmony-7.0.0.111 / API 26 / 2in1；hdc 无线 `127.0.0.1:35111`、UDID `1BCE13C8…AEA0`；
> **起始未锁屏**（桌面可见、无锁屏态，无需解锁）。方法：`hdc shell uitest uiInput click/dumpLayout/screenCap` + `hidumper RSTree` + `hilog -T`；
> 坐标取 `dumpLayout` bounds（ArkWeb DOM 可读时），否则按窗口分辨率推算。AOT 资产 = scratch `w10/device/`（W10 host + rc.1 pin）：
> `hello-maui-app-inv.hap` **21,621,069 B**、`hello-maui-wasm-diag5.hap` **105,098,069 B**（本机可装；JIT 主包本机仍 `9568393`）；
> Blazor 受控点击 = kit34 预签件 `blazor-default-signed.hap` **27,252,810 B / `1968732d…`**。证据 scratch
> `/data/storage/el2/base/tmp/opencode/uiauto-35/`（20+ 截图、h1–h5 布局 JSON、`rstree.txt`、`blz-hilog-now.txt`、`hilog-click1.txt`）。
> **前置事实**：本轮设备被并发占用（多应用窗口反复抢前台、pid 漂移），绝对坐标点击多次落到竞争窗口；结果按「操作→期望→证据」如实登记，
> **不据本机结果判 kit 失败**；未入口项按「需 JIT 机人工/未测」登记。

## 1. 判定表（操作 → 期望 → 证据/判定）

| 项 | 操作 | 期望 | 结果 / 证据 |
|---|---|---|---|
| ① TabbedPage 双页签/切页 | AOT hello-maui-app 启动（窗口 `w9d boot`→`activation N:`）；点 `Animations`（dump 坐标 (2400,1450)，另试 4 组坐标/长按/双击） | tab 切换、主体内容变化 | **部分**：AOT **出画** tab 栏（Home/Animations）+ 抽屉 + NavigationPage 标题栏（#34「页内控件未出画」的 W10 增量）；点击**注入到达应用**（`InputKeyFlow pointerAc: up`、`AceInputTracking Consumed`）但被**全窗 ArkWeb**（HybridWebView 404 覆盖层，`dumpLayout` Web=[578,414][2669,1738]）吞掉/被并发窗口抢前台 → 切页未达成。证据 `a1-01-start.png`、`a1-02..04-*.png`、`b3-s.png`、`b5-crop.png`、`hilog-click1.txt` |
| ② WebView 9 项卡 | 自动可达者：B2 wasm 站点（hello-maui-wasm AOT）+ MAUI WebView 启动与点击 | `BLZ_BOOT`/`BLZ_RENDERED`；history/Cookie/frame/导航事件/失败清屏 | **部分 / 需人工**：站点在 MAUI WebView 出画（`w1-s.png` 白底加载态），标记曾在 w10 双次齐（pid 6157）；本轮 hilog 512K 高噪声下 wasm 标记被挤出（未捕获），**未复跑成功**；wasm 页在 `dumpLayout` **无 Web/DOM 节点** → 无法 DOM 驱动；history/Cookie/frame/失败清屏**无应用内入口** → 登记「需 JIT 机人工」，离线由 540 套件 T2 断言（`w10/suite-run4.txt`） |
| ③ W6-W8 UI（T15/T16/N4/T18/N5/N6） | 以 AOT 样例可覆盖者为准 | 点击出画/交互 | **无法自动（本机）**：AOT hello-maui-app 无 TitleView/ToolbarItem/Map/Overlay/Decorations 入口（承 #34 注记）。可覆盖者 = FlyoutPage 抽屉（T14 形）、TabbedPage/NavigationPage chrome、窗口标题应用（WMS 可见 `activation N:`，T19/标题应用）——见 `b1/b3`；其余登记「需 JIT 机人工；套件离线 540/floor 520」 |
| ④ Blazor 受控点击 | 冷启动 opendotnet（`aa force-stop`→`aa start`）→ `dumpLayout` 取 DOM 坐标 → 点 `Open the interactive counter` → 点 `Click me` | Home→/counter→计数 0→1 | **通过 ✅**：两次 `uitest uiInput click` 命中（链接=Heading 底+495px 推得；按钮 bounds 取中心）；`Current count: 0 → 1`；同会话 `BlazorWebHost` 标记齐（pid 56763 / nonce `1c77f7ce…`）。证据 `blazor/h1.json`（Home）、`h3.json`（Counter）、`h5.json`（count 1）、`h4-s.png`、`blz-hilog-now.txt` |
| ⑤ 截图 + RSTree/hilog | 全过程取证 | 面 buffer=1、标记、截图 | **通过**：RSTree `ohos_dotnet_surface`×2 `hasSurfaceBuffer: 1`、Bounds 2090×1324（`rstree.txt`）；Blazor 标记（上）；壳 A11Y 自检可达（`a1-05-a11y-crop.png`，AOT 件 nodeCount=1，供 #34「nodeCount=0」对照） |

## 2. 判读与下一步

- **① 与 ④ 的差异根因（本机）**：纯 ArkWeb 窗口的 DOM 驱动稳定（④ 通过）；MAUI canvas 的 touch 目标被桌面窗口 z 序 + 全窗 ArkWeb 覆盖层吞掉（Hybrid/Blazor WebView 未收敛到控件 frame）。
- 平台侧 follow-up（新）：(a) WebView `frame` 命令下发/裁剪收敛（覆盖层不应全窗）；(b) `dumpLayout` 不暴露 MAUI WebView（wasm）的 DOM——自动化取证受阻。
- 复跑建议：选窗口空闲时段；①③ 仍以 **tester JIT 机人工**为主判定；④ 本机已可闭环（本页）。
- 诚实清单：本轮**未**取得 ① 切页、② 9 项全量、③ W6-W8 点击证据；④/⑤ 成立。JIT 主包本机装不上的限制承 `2026-09-30-ohos-jit-payload-install-policy.md`。
