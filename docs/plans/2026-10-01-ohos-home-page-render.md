# FIX-HOME：AOT 件 Home 页页内不出画——根因与修复（2026-10-01）

> 症状（UI-LOCAL-2）：`app-k36.hap` 冷启首屏 Home tab 仅 chrome（白标题条/紫导航栏/底部 tab 栏），内容区全黑；
> Animations tab 页内完整出画。证据：`/data/storage/el2/base/tmp/opencode/uiauto-aot2/`（q0/q2）。
> 本轮 scratch：`/data/storage/el2/base/tmp/opencode/fix-home/`。

## 根因
- `TabbedPage`/`FlyoutPage`/`Shell` 容器 handler 的 `ArrangeContent()` 以 `content.Arrange(frame)` 直接摆当前页；
  `OpenHarmonyNavigationPageHandler` 没有 `PlatformArrange` 下钻：只摆导航页自己，不摆 `CurrentPage`。
- Home = `FlyoutPage -> TabbedPage -> NavigationPage(ContentPage)`，故 ContentPage 子树 frame 停留 `-1x-1`
  （page 感知 walk 未被走到），合成器只画到导航栏/tab 栏 → 黑。Animations 是 TabbedPage 的普通 ContentPage 子页，
  `OpenHarmonyPageHandler` 有下钻，所以正常。
- headless 复现（`fix-home/harness`，编译切片源码 + 真实合成器）：未修复时 `Describe` 为 `ContentPage frame=0,0,-1x-1`，
  标题/形状像素为背景色；修复后 frame 正常、矩形 `#FF4500` 在 32,489,48x48。
- 早先偶发的全屏 OrangeRed 闪现：修复前未排布子树可在后续布局 pass 以异常 frame 画出（推断）；修复后 frame 恒正常。

## 修复
- maui-ohos `68ec598037`：`OpenHarmonyNavigationPageHandler.PlatformArrange` 下钻 `CurrentPage`（导航栏下沿，含
  safe-area walk 与 `OpenHarmonyContentArrange.IsArranging` 防递归标记），与 `OpenHarmonyPageHandler` 同模式。
- ohos-workload `5d82f40`：交互套件 +4 FIX-HOME 断言（父容器 arrange 下钻 / 合成出画 / 切走、切回），
  `verifyCheckTotal` 540→544、floor 524（≥520，只增不降）；交互门禁注释同步。

## 验证
- headless：修复前新断言 `home={0,0,-1x-1} assert=False`（run exit 134）；修复后 `544/544 floor 524 assert=True`，
  pixel 套件 `PIXEL ASSERTIONS PASSED`。
- AOT 真机：用修复后切片重发 NativeAOT hap（`publish-aot-fix.sh`；IL2026/IL3050/IL3051=0），本机 UDID 重签
  （`scripts/sign-for-device.sh`）后安装启动：
  - `device/home-cold.jpeg` 首屏 Home 页内完整出画（标题/副标题/Hybrid 白区/Count 按钮/Entry/值控件/形状行/边框/媒体区）；
  - `device/anim.jpeg` Animations 出画；`device/home-back.jpeg` 切回 Home 仍出画。
- 件：`hello-maui-app-fixhome-signed.hap` 21,626,073 B / `13549f81…`；publish so 18,619,152 B。
- 提交：maui-ohos `68ec598037`（feature/openharmony）、ohos-workload `5d82f40`（master）；未改 pin、无强推。

## 不确定项
- 设备侧最终评估建议用 kit #36 线完整重打包件（本轮回发为 W10 AOT 基座 + 当前壳/宿主模板）。
- 未覆盖：Home 页内交互注入（承 #35 的 uitest→MAUI 触摸映射缺口）；抽屉/WebView 页内交互仍待人工。
