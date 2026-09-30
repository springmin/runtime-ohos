# UI-LOCAL-2：本机 AOT 件 UI 人工项复测轮（kit #36 线，2026-10-01）

> 设备 HAD-W32 / OpenHarmony-7.0.0.111 / API 26 / 2in1；hdc 无线 `127.0.0.1:35111`；UDID `1BCE13C8…AEA0`；PowerManager AWAKE（未锁屏）。
> 目标件 = kit #36 线 AOT：`app-k36.hap` **21,626,076 B / `ec9c378d…`** —— W10 AOT 基座（`hello-maui-app-inv`）+ **最终壳 abc `fc54d2b8`** + **宿主 `cfbbe461`** 重打包 + 本机 UDID 签名（即 `aot-haps-v3-rc2` 的「kit #36 壳/宿主重建」线）。对照：`aot-haps-v3-rc2` 原签件（abc 311,424/pre-W10）本机截图仅渐变背景 + 「…」按钮，无 chrome、无页内。
> 修正上轮三项阻断：① 每步前 `aa force-stop` 竞争应用（opendotnet/hellomauiwasm/myapplication/cdgss）+ `aa start` 取回前台 → 目标窗口独占；② 全部用 `uitest uiInput click`（坐标取自截图/像素分析）；③ 冷启先截图判读首屏再交互；每步「操作→截图→判读」，hilog 全窗采集。
> 证据 scratch `/data/storage/el2/base/tmp/opencode/uiauto-aot2/`（`q0/q2`、`w0–w6`、`y0–y8`、`z0–z12` 截图 + `hilog-seq*.txt`/`seq*-hilog.txt` + `seq*.sh`/`EVIDENCE.md`）。

## 1. 首屏内容——Home 页页内未出画（「仅 chrome」复现）
- 冷启 12 s 截图：chrome 完整（白标题条、紫色导航栏 "MAUI on OpenHarmony"、底部 tab 栏 Home/Animations）+ **内容区全黑**，仅 1 个居中小蓝「…」按钮（= 壳 a11y 自检入口，见 §3）。
- 多次冷启复现（q0/w0/y0/z0）；判读：**Home（首 tab）页内控件未出画**。
- 异常一闪：一次 Home 激活出现全屏 `OrangeRed` 矩形（Home 的 `Rectangle` 控件被拉满幅）+ 黑圆角块，随后回黑底（p2/p3），判为 Home 异常渲染闪现。

## 2. Tab 栏切页——通过 ✅（内容随切页变化，AOT 页内首证出画）
- `uitest uiInput click 2030 1650`（Animations）→ 页内**完整出画**："animate me"、Carousel「swipe A」、圆点、「swipe the carousel」、绿色「Run animations」、「tap the button」（q2/w1/y1/z1）。
- `click 1030 1650`（Home）→ 导航栏/Home 恢复，内容仍黑（w6/y6）；多轮复现（seq3/6/7/8）。hilog：注入到达应用（`Add touchItem location:…` → `InputKeyFlow ac: down/up`）。

## 3. 人工项判定表
| 项 | 操作 | 判定 |
|---|---|---|
| 导航标题 | 观察 | **通过**："MAUI on OpenHarmony" 渲染于紫色导航栏 |
| 抽屉（FlyoutPage） | nav-left click (560,395)、左缘 swipe/fling | **未过/无入口**：无汉堡图标，抽屉未出（前后 diff=0） |
| 页内按钮（Run animations） | click/doubleClick/longClick、坐标 (1560,719/690/750/1087、780/2340)、Tab/Space/Enter | **未过（uitest 注入）**：0 视觉变化；事件已投递（`TTHNI: page→XComponent`、`Hitted recognizer info is empty`、`Consumed`）。同窗 ArkUI「…」按钮点击**有效**（弹 a11y 对话框）；更早一轮**真鼠标**点同一按钮**有效**（"fading out…"→"animations done"）→ 缺口在 uitest 触摸→MAUI 内容映射（承 #35） |
| WebView 项 | 观察 | **无入口**：Home 的 HybridWebView/BlazorWebView 未出画，页内无 WebView 入口 |
| a11y（额外） | 点蓝「…」 | 对话框 `Accessibility self-check`：`status=1 (attached)`、`nodeCount=1`（与 #36 本机证据一致） |

## 4. 过程风险 / 未决定项
- 共享桌面并发：轮内 JIT-LOCAL 子任务与物理鼠标多次重装/操作同一 bundle；一次脏 bundle 致启动 SIGSEGV（重装即恢复，非本件缺陷）；自建改名 bundle 隔离失败（ArkTS abc 入口按 bundle 编译，改名 `ReferenceError: Cannot find module 'ets/entryability/EntryAbility'`）。
- 未覆盖：Home 页内控件/列表（未出画不可测）、抽屉、WebView 页内交互、carousel 滑动手势（注入未生效）；主判定仍建议真鼠标或 tester 机人工复核。
