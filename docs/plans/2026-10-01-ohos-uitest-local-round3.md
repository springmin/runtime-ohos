# UI-LOCAL-3：Home 出画后剩余 UI 项（WebView/抽屉/pinch/carousel/回归）——kit #37 线 AOT（2026-10-01）

> 设备 HAD-W32 / OpenHarmony-7.0.0.111 / API 26 / 2in1；hdc 无线 `127.0.0.1:35111`；AWAKE；独占前台（opendotnet/hellomauiwasm/myapplication/cdgss force-stop）。
> 件 = kit #37 线本机重出 AOT：`hello-maui-app-kit37-signed.hap` **21,490,919 B / `ffd39d4b…`**（宿主 `4e9f3c3e`，本机 UDID 重签，同 KIT37-LOCAL §4 件）重装启动（pid 65167→10275）。
> 窗口 (515,281) 2090×1394、系统标题栏 70px → element 原点 (515,351)（RSTree 复核）；注入坐标=屏幕像素（FIX-ITOUCH 后=element+原点）。
> 证据 scratch `/data/storage/el2/base/tmp/opencode/uiauto-aot3/`：`shots/`（b0/d0/c1/m1–m5/n0–n3/q1–q4/w1–w4/k1–k9/a0）、`stream2/3.txt`、`rstree-current.txt`、`uitest-uiinput-help.txt`、`EVIDENCE.md`。

## 1. WebView/Hybrid 区（Home 页内白区）——未渲染/无入口 ⚠
- hilog（冷启段）：`[maui] web sink: true`；`web cmd: hybrid`；`web cmd: blazor`；`blazor assets: origin=https://0.0.0.0/ root=wwwroot base=…/libs/arm64 mode=hybrid`；
  `web serve https://0.0.0.0/ -> …/libs/arm64/wwwroot/index.html`（+`js/app.js`、`_framework/blazor.webview.js`、favicon）→ `web page: https://0.0.0.0/`；**hybrid origin `0.0.0.1` 零请求**；
  `hybrid bootstrap script extraction failed: … '_framework' is denied`（bundle 只读）；`BlazorWebHost`/`BLZ_` 标记 0 条（该 tag 属 Blazor 宿主页路径）。
- 判读：Home 同挂 HybridWebView+BlazorWebView，shell 单 Web sink/单 ArkWeb 组件，后注册的 blazor 顶掉 hybrid 的 `loadUrl` → hybrid 页从未加载；且 overlay 以 element px 当 vp 摆放
  ——RSTree `RosenWeb` surface abs (576,1704) **3849×1324** = element frame(32,y)×1.9(density)+窗口原点，落在窗口底(1675)之外 → 页内白区=HybridWebView 的 MAUI 白色底，无 Web 内容。
- 手势：白区内 drag 上/下 + click 两处（w1–w4）0 视觉变化（diff ≤0.027，差异区仅 a11y 按钮/时钟）→ 不可滚动/导航（无内容可交互）；BlazorWebView 控件区在页内未占位（hint 下直接 Count）。

## 2. 抽屉/汉堡——入口可出画 ✅（dismiss 未过 ⚠）
- 左上命中区注入 tap (545,381)=element(30,30) → flyout 面板出画：`Drawer`/`tap outside to close` + 灰 scrim（b0→m1 diff 21.7，`c1/m1/n0`）。
- 无可见汉堡图标（被紫 nav bar 盖住）；左缘 drag（命中区外）不开面板；贴窗左缘 drag 被桌面 WM 判为 resize（一次改成 x=1048/宽 1557，重启恢复——环境注意项，后续注入离窗缘 ≥9px）。
- 关闭：面板外 click/drag/doubleClick 均无效（q1–q4 diff ≤0.022；hilog 触摸已投递 eid 40–44）；`keyEvent Back` 只把窗口收后台（n3），再 `aa start` 后面板仍在 → plain-FlyoutPage dismiss 疑点（本轮未定位）。

## 3. pinch 多指注入——无入口（工具不支持）
- `uitest uiInput help`：仅 dircFling/click/doubleClick/longClick/swipe/drag/fling/keyEvent/inputText/text——**无 pinch/多指**；多指 element 坐标归一仍未上机（承 FIX-ITOUCH 不确定项）。

## 4. carousel 手势（Animations）——通过 ✅
- 注入 `swipe 2250→950@y535` → `swipe B`/`slide 2`/第 2 点；反向 → `swipe A`/`slide 1`；`drag` 双向同效（k1–k4；项/位置标签像素带 diff 2.1/4.7；文案拼图 `carousel-strips.png`）。

## 5. 回归（tab 往返 + Run animations）——通过 ✅
- Home⇄Animations 往返（k5/k9）内容 vs 冷启 Home 像素 diff 0.0；注入 (1560,730) → 0.6s `fading out…`（k7）→ 3.1s `animations done`（k8）。

## 不确定项 / 注意
- §2 dismiss 未生效未定位（renderer 理论有 plain-FlyoutPage dismiss 分支，触摸确已投递但不生效；需读代码/加桩复现）。
- §1 零 `0.0.0.1` 请求+单 sink 结构支持“hybrid 未加载”，但单冒烟无法穷尽“加载后被 blazor 顶掉”；白区判定限于本件本布局。
- hilog 512K 下 webview 日志秒级挤出启动段：启动证据需先挂 hilog 再起应用（本轮 stream2 重采）。
- 设备末态：目标应用已 force-stop；未改代码/未动 kit 资产、未强推。
