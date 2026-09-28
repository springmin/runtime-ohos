# MAUI W1A 状态：T1 InputView 映射补全 + T2 WebView 小缺口批（2026-09-28）

> Backlog：`2026-09-28-ohos-maui-port-backlog.md` §2 T1/T2。范围 = maui-ohos 切片 +
> OpenHarmony 在树 PublicAPI + ohos-workload 壳/套件/三 workflow pin。**未做真机验证**。

## 1. 提交

| 仓库 | 提交 | 内容 |
|---|---|---|
| maui-ohos `feature/openharmony` | `dcc7eaac` | T1：Entry/Editor/SearchBar 映射补全 + `OpenHarmonyView` 输入态/绘制/命中 + PublicAPI |
| maui-ohos `feature/openharmony` | `8241f1b3` | T2：`IWebView.Cookies` 双向同步（映射 + page-finished 回读）+ PublicAPI |
| ohos-workload `master` | `7cb1f31` | 三包壳接线（#11 文件选择/#12 媒体权限/#13 window.open）+ `webview-media` 权限特性 + abc/provenance + T1/T2 套件断言（405/385） |
| ohos-workload `master` | `1809ad6` | 三 workflow pin `33b0af79` → `8241f1b3` |
| runtime-ohos | 本文 | 状态记录 |

## 2. 实现要点

- **T1**：`MaxLength`（截断）、`IsReadOnly`（焦点保留/不开 IME/忽略输入）、`IsPassword`
  （按字符绘制 `•`，光标/选区同源度量）、`ClearButtonVisibility`（Never/WhileEditing：绘制 +
  命中 + 清空回写）、`ReturnType`（记录）、`PlaceholderColor`、`HorizontalTextAlignment`
  （Start/Center/End 的绘制与 `CursorIndexFromX`/`TextPositionX` 同源）、`Keyboard`
  （Numeric/Telephone 输入过滤；其余仅记录）。切片刻意不触壳：键盘类型/回车键标签仍由壳的
  `TextInput` 决定，未驱动。
- **T2**：#11 壳 `onShowFileSelector` → `DocumentViewPicker` → `handleFileList`；#12 壳
  `onPermissionRequest` → `abilityAccessCtrl.requestPermissionsFromUser`（仅
  `ohos.permission.CAMERA`/`MICROPHONE`，其余 deny），`webview-media` 特性矩阵 + 两个
  reason 字符串声明；#13 `multiWindowAccess(true)` + `onWindowNew` 把弹窗目标在**同窗**载入
  （单窗切片语义，`navProgrammatic` 走既有导航网关）；#14b `IWebView.Cookies`：
  container→`configCookieSync`（URL 由 domain/scheme/path 重建，单批 ≤64），page-finished
  时 `fetchCookieSync` 头按 `;` 拆对回填 container（恶意/超长/控制字符态惰性）。
- 残余（未在 T2 范围）：真多窗（仍单窗）、媒体权限真机弹窗、文件选择真机 URI 授权。

## 3. 验证（离线）

- 切片构建：`Microsoft.Maui.Platform.OpenHarmony.csproj -c Release`（+trim/AOT 分析器、
  `-warnaserror:IL2026,IL3050`）**0 error / 0 IL**。
- 交互套件：**405/405，floor 385，assert=True**（本批 +7：`i1`–`i3`、`w6`–`w9`；基线 398/378）。
  注：本地运行时另含 W1B（T3 GraphicsView）未提交的套件行，故用去 T3 的 405 口径验证通过。
- 壳：源码契约 + 三包字节一致 + abc provenance 门通过；ui abc 294,976 B /
  `6cf7dda2…`，headless 20,916 B / `54a1a201…`（不变）。
- 像素套件：`PIXEL ASSERTIONS PASSED`（2,399,269 次写像素）。
- 宿主契约：本批未新增导出（`host-exports` 143/143 不变）。

## 4. 未决/依赖

- 真机：`<input type=file>`、`getUserMedia` 授权弹窗、`window.open` 同窗行为、cookie 跨页/
  重启保持（外部设备项）。
- 交互套件提交时刻意未包含 W1B 的 T3 行（同文件并发），其落地后合计应为 409/389。
