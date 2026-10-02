# LEGACY：Core Toolbar 切片 + legacy 兼容层盘点（2026-10-03）
> 审计卡 `2026-10-03-ohos-maui-final-audit.md` §2 L7；矩阵 §3。pin `maui-ohos 07423dfe93` 不动、未强推。

## 1. 盘点
- **Core Toolbar：有缺口，本轮闭合。** 原镜像只有 `(Text, Activate)` 元组：ShellChrome/NavigationPage
  只镜像文字与激活，`IconImageSource`/`Order`/`Priority`/`IsEnabled` 丢失；Shell 标题栏只镜像、
  从不绘制/hit-test（`DrawTitleBar` 无工具栏路径）。
- **legacy compatibility renderers：判定为非缺口。** `src/Compatibility` 由平台骨架提交 `e55e1e27bb`
  有意移除（1138 文件），与上游 net11「Remove MAUI compatibility package」方向一致；本地未跟踪的
  `src/Compatibility/`（70 个 Tizen 文件）与基线 `1cd2e15ba4` 逐字节相同，是初检出残留而非在途工作；
  XF 兼容渲染层不属于 net11 切片。
- **TitleBar** 已由 N6/T9 闭合；**TableView** 已由 T8 闭合。

## 2. 实现（L 切片）
- `OpenHarmonyToolbarItem`（Text/IconBytes/Glyph/GlyphFontSize/GlyphColor/IsEnabled/IsSecondary/Activate）
  替代文字元组；`OpenHarmonyToolbarMirror` 按 MAUI 契约（Tizen/Windows 参考）镜像：Default+Primary
  按 Priority 停靠栏内，Secondary 进溢出；图标支持 FileImageSource 与 FontImageSource（字形）。
- 导航条与 Shell 标题栏共用 `DrawToolbarItems`（图标/文字/禁用暗显/矢量「更多」）；溢出下拉由渲染器
  延迟绘制并在内容之前 hit-test；激活沿用 `IMenuItemController.Activate`/Command，禁用项不激活；
  ShellChrome 改为事件驱动重建（去掉每帧文本 diff）。

## 3. 门禁
- 套件 +6 `[verify]`：提交版 563→569、floor 549；合并并行 SAMPLE-FIX 后实测
  `checks=570 total=572 floor=552 assert=True`、0 Unhandled、perf/a11y 全 `within=True`。
- 切片 Release + `-warnaserror:IL2026,IL3050`：0 error / 0 IL；host 导出 150/150；PublicAPI 同步。

## 4. 提交
- `maui-ohos 7064bb8c1c`（View/ShellChrome/NavigationPageHandler/WindowRenderer + ToolbarMirror +
  PublicAPI，不含并行 SAMPLE-FIX）、`ohos-workload 3112c03`（Program.cs/README）、
  `runtime-ohos`（本文件 + 矩阵 §3）。

## 5. 不确定 / 后续
- 无设备轮次，未做真机截图；绘制/hit-test 由套件与既有像素门禁覆盖。
- `IconImageSource` 的 Uri/Stream 源回退文字（异步图像服务；与 tab 图标策略一致），记后续小项。
- 不推进 workflow pin（不发布新 kit），pin 仍 `07423dfe93`。
