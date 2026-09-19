# OpenHarmony 移植交接状态（2026-09-19）

三仓库：`runtime-ohos`（运行时/文档）、`sdk-ohos`（SDK）、`aspnetcore-ohos`，
外加本机 workload 仓库 `ohos-workload` 与 MAUI fork `maui-ohos`。

## 1. 主线与版本

| 项 | 状态 |
|---|---|
| 缺口 1（弹层/Swipe/ToolbarItem/SwipeView/RefreshView）| ✅ 完成并验证 |
| 缺口 2（Sensor：Accelerometer/Gyroscope/Shake；Notification：宿主→NAPI→ArkTS）| ✅ 完成并验证 |
| 缺口 3（相机拍摄：picker 管线 + 壳内 cameraPicker）| ✅ 完成并验证 |
| 受限项解除：`SwipeItem.Invoked`、Pointer 手势、真实悬停、Pinch（宿主直算）| ✅ 完成并验证 |
| workload 版本 | `1.0.0-preview.23`（bundle + release + 滚动 `workload-latest`）|
| 壳归档 | `dist/ets/modules.abc` → 包内 `modules.ui.abc`（含通知 sink、相机分支）|
| 签名 hap | `test/hello-maui-app/bin/Release/net11.0-openharmony26.0/openharmony-arm64/hello-maui-app.hap` |
| 测试基线 | 交互回归 **125 项全绿**；像素套件 PASSED（2 项 KNOWN 属测试侧）|

## 2. 架构级批次

| 批次 | 状态 | 说明 |
|---|---|---|
| D1 视觉诊断 overlay | ✅ | `OpenHarmonyDiagnostics.Enabled` → 每帧描边 + 类型名；`OutlinesDrawn` 计数（108/帧实证）|
| D2 无障碍 | 🟡 | 数据链完成（见 3），仅剩 provider 绑定 |
| D3 BlazorWebView/HybridWebView | ⏳ | 需 JS↔.NET 通道 + 资源服务 + 切片 handler |
| D4 Hot Reload | ⏳ | 依赖 `dotnet watch`/agent、设备通道（hdc 被策略拦截）、运行时 EnC |

## 3. 无障碍（D2）现状与剩余配方

已完成（全部有测试或构建证据）：

- `OpenHarmonyAccessibility.cs`：影子节点树（`Id/ParentId/Role/Text/Description/Hint/Bounds/IsEnabled/IsFocusable`），
  角色映射与标题级别（`header`），按角色动作掩码（`OpenHarmonyAccessibilityAction`，镜像 NDK 码值）。
- 渲染器每帧 `Refresh(content)` + `Publish()`；宿主入口 `ohos_host_accessibility_begin/node/commit`
  （UTF-8 封送，宿主库缺失时降级为 0 且不抛异常）。
- 宿主 `openharmony_host.c`：节点表 + 跨 TU 访问器 `ohos_host_accessibility_count/get`（构建+签名通过）。

剩余（配方，无未知项）：

1. 壳：`@ohos.arkui.node` 建 `NodeContent`（或以自定义节点）并下传（新增 NAPI，例如 `host.setAccessibilityContent(content)`）。
2. 宿主：`OH_ArkUI_GetNodeContentFromNapiValue` / `OH_ArkUI_GetNodeHandleFromNapiValue`
   → `OH_ArkUI_NativeModule_GetNativeAccessibilityProvider(node, &provider)`（**节点须 `ARKUI_NODE_CUSTOM`**，API 23+）。
3. `OH_ArkUI_AccessibilityProviderRegisterCallback(provider, &callbacks)`，7 个回调：
   `findAccessibilityNodeInfosById` / `ByText` / `findFocusedAccessibilityNode` /
   `findNextFocusAccessibilityNode` / `executeAccessibilityAction` / `clearFocusedFocusAccessibilityNode` /
   `getAccessibilityNodeCursorPosition`。
4. 回调内用 `count/get` 读节点表 → `OH_ArkUI_AddAndGetAccessibilityElementInfo(list)`（列表类）
   或 `OH_ArkUI_CreateAccessibilityElementInfo()`（焦点类）+ `Set*`（Text/Contents/ComponentType/
   ScreenRect/ChildNodeIds/ParentId/Clickable/Enabled/Focusable/Editable/Checked/OperationActions/HintText）。
5. `executeAccessibilityAction` → 托管（新增桥回调）→ 复用既有命中/焦点/滚动路径；
   动作参数用 `OH_ArkUI_FindAccessibilityActionArgumentByKey`。
6. 事件：`OH_ArkUI_CreateAccessibilityEventInfo()` + `OH_ArkUI_SendAccessibilityAsyncEvent(provider, event, callback)`
   （CLICKED / TEXT_UPDATE / PAGE_CONTENT_UPDATE / SCROLLED）。
7. 重建壳归档与 hap；真机读屏遍历验收。

## 4. 操作规程（本机环境坑）

- **shell 是 toybox**：用 `grep -E`，不要 `grep "a\|b"`；比较用 `[ ]`。
- **`/tmp` 只读** → 临时文件放 `/data/storage/el2/base/tmp/opencode/`。
- **hvigor 404**：`https://repo.harmonyos.com/npm/@ohos/hvigor/-/@ohos-hvigor-6.26.4.tgz` 返回 404；
  用本地缓存建 file:// 镜像并设 `HVIGOR_MIRROR=file://<mirror>`（布局 `@ohos/<pkg>/-/@ohos-<pkg>-6.26.4.tgz`）。
- **壳脚本基路径**：`build-arkts-shell.sh` 中 `HVIGOR_DIR` 必须先于 `PROJ` 赋值（已修）。
- **相机枚举**：`camera.CameraPosition` 来自 `@ohos.multimedia.camera`（不是 `cameraPicker`）。
- **依赖安装副本**：demo app 解析 `~/.dotnet/packs/...` 的 pack；改动 Hosting/运行时后需覆盖
  `Runtime.*/runtimes/openharmony-arm64/lib/net11.0` 与 `Ref.*/ref/net11.0`（本会话覆盖 4 处）。
- **RID 归一化**：`prepare-packs.sh` 末尾会重写运行时包内 `*.deps.json` 的 `ohos-arm64` →
  `openharmony-arm64`；安装副本需同规则处理（否则 `NETSDK1083`）。
- **hap 打包**：`dotnet publish -r openharmony-arm64 -p:OpenHarmonyUIPage=pages/Index
  -p:OpenHarmonyArktsModulesAbc=dist/ets/modules.abc -p:OpenHarmonyHapPackage=true`（打包+签名）。
- **workload 版本源**：`manifests/11.0.100-rc.1/microsoft.net.sdk.openharmony/WorkloadManifest.json`。
- **自签名**：ELF 用 SDK `selfsign`（`scripts/selfsign.sh`，就地签名后不可覆盖，需换名）。

## 5. 验证入口

```bash
# 交互回归（125 项）
cd /data/storage/el2/base/tmp/opencode/maui-platform-verify && $HOME/.dotnet/dotnet build -v:q && \
  $HOME/.dotnet/dotnet bin/Debug/net11.0/verify.dll | grep -c '\[verify\]'

# 像素断言
cd /storage/Users/currentUser/springsources/ohos-workload/test/headless-render && \
  $HOME/.dotnet/dotnet run -c Release | grep -E 'PASS|KNOWN'

# 重建宿主（含签名）
cd /storage/Users/currentUser/springsources/ohos-workload && bash scripts/build-host.sh

# 壳归档
HVIGOR_MIRROR=file:///data/storage/el2/base/tmp/opencode/npm-mirror bash scripts/build-arkts-shell.sh

# 打包 + 发布 + hap
bash scripts/prepare-packs.sh && bash scripts/pack-workload-bundle.sh && bash scripts/publish-workload-release.sh
cd test/hello-maui-app && $HOME/.dotnet/dotnet publish -c Release -r openharmony-arm64 \
  -p:OpenHarmonyUIPage=pages/Index -p:OpenHarmonyArktsModulesAbc=../../dist/ets/modules.abc \
  -p:OpenHarmonyHapPackage=true
```

## 6. 阻塞与外部依赖

- **真机验收**：`hdc` 被组织策略拦截（"Operation restricted by the organization"）；
  `devecocli` 需 DevEco Studio 或 HarmonyOS Command Line Tools（本机均未安装）。
  验收清单：`docs/plans/2026-09-18-ohos-device-validation-checklist.md`。
- **D4 Hot Reload**：需设备连接通道 + 运行时 metadata update（EnC）。
- **无障碍**：仅剩绑定层（第 3 节配方）。
