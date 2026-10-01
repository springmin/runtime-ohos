# FIX-WVP：WebView/Hybrid overlay 坐标错位 + hybrid origin 零请求（2026-10-01）

> 设备 HAD-W32 / OH-7.0.0.111 / API 26 / 2in1；hdc 127.0.0.1:35111；独前台。件 = 本机 AOT 重出
> （publish rc=0、IL2026/IL3050/IL3051=0）：`hello-maui-app-fixwvp-signed.hap`（壳 abc 341,560 / 24,324）；
> 窗口 (515,281) 2090×1394、系统标题栏 70 → element 原点 (515,351)。证据 scratch
> `/data/storage/el2/base/tmp/opencode/fix-wvp/`：`device/`（w0-home/s3c/ping/drawer/anim/f0..f6 +
> hilog-phase1/final + rstree-now）、`suite-run5.log`、abc 构建/签名日志。

## 根因（三处叠加 = UI-LOCAL-3 白区无内容）
1. **element px 当 vp**：合成器按设备像素布局（`RequestDisplayDensity`=1），`frame` 发像素；壳直接当
   ArkUI vp 用 → ×1.9 落窗外。RSTree 修复前 abs(576,1704) 3849×1324；修复后 `Bounds[0 0 2026 400]`、
   `innerAbsDrawRect [547,551,2026,400]`，与 HybridWebView element 重合。
2. **Blazor 注册顶掉 hybrid 页**：单 ArkWeb；hybrid `loadUrl(0.0.0.1)` 后被 blazor `loadUrl(0.0.0.0)`
   覆盖 → `0.0.0.1` 零请求。修复后 `hybrid assets: origin=https://0.0.0.1/` + `blazor origin armed…` +
   `web serve: https://0.0.0.1/…` → `web page: https://0.0.0.1/`。
3. **覆盖层画在托管表面之下**：`Web` 声明在 `XComponent/ContentSlot` 之前；Stack 后声明者在上 → 覆盖层
   一直被托管表面盖住（此前 frame 在窗外不可见）。把 `Web` 移到 `ContentSlot` 之后（Map overlay 前）→
   Hybrid 白区真正出画。
4. 连带：覆盖层上移后，托管自绘的抽屉/另一 tab 会被压住（抽屉打开时 flyout 自身的 arrange 周期会把
   详情页的 web frame 再发一次）。切片在 FlyoutPage 呈现/关闭发 **suspend/resume**、TabbedPage 切页发
   **hide**；壳 suspend 期间 frame/load 只更新几何不复显、resume 恢复挂起前可见性，hide 是普通隐藏
   （隐藏页不被 arrange，下一 tab 的 web 控件靠自己的 frame 复显）。

## 修复
- maui-ohos `47d79add01`（叠在 FIX-DISMISS `86b439ffc8` 上）：FlyoutPage/TabbedPage 覆盖层挂起/恢复。
- ohos-workload `acbe750`：壳 Index.ets（px2vp 换算 + 非正宽高 frame 忽略 + `Web` 后置 + hybrid 保留单
  覆盖层 + hybrid 注册/serve 日志 + suspend/resume/hide 状态机）；四包 preview.22/23/24/28 同步
  （modules.ui.abc **341,560** / modules.abc 24,324 + provenance）；hosting `WebCommandSent` 诊断事件
  （导出仍 149/149）；verify-kit 期望 341,560/24,324；交互套件 +4 → 550/floor 530 只增；打包文档补
  FIX-WVP 段。**未改 pin**。

## 验证
- headless：`[suite] checks=550 total=550 floor=530 assert=True`；4 条 fix-wvp 全绿；像素
  `PIXEL ASSERTIONS PASSED`；`selftest-verify-kit 108/0`、`selftest-build-arkts-shell 185/0`、exports 149/149。
- AOT 真机：`w0-home` 页显 `origin https://0.0.0.1/ | readyState: interactive` + probe 表对象；页内 drag
  → chromium `web page fling`、`s3c` 滚到 Send ping；click → 页内 `sent #1 via
  window.external.sendMessage … origin: https://0.0.0.1/` + 托管 label
  `hybrid raw message: {"kind":"ohos-bridge-ping",…}`（`ping.jpeg`）＝页→宿主闭环。
- 回归（根因 4）：`f1-drawer` 抽屉完整可见（覆盖层挂起）、`f2-dismiss` 外点关闭并恢复出画、
  `f3-anim` 切 Animations 后覆盖层隐藏、`f4/f5` Run animations "fading out…→animations done"、
  `f6-home-back` 切回再出画（f*.jpeg + hilog-final）。

## 不确定项
- 单覆盖层：同页多 web 控件共享一个 ArkWeb；已注册 Hybrid 时后到 Blazor 只武装不加载。多覆盖层后续。
- BlazorWebView 期望尺寸为 0（无 GetDesiredSize）→ frame 被忽略、自身仍不出画；Shell 抽屉与非 Tabbed/Flyout 页面切换未挂 suspend/hide；maui CI ref 未推进（按"不改 pin"）。
