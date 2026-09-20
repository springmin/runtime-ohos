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

### 3b. 精确签名（已从 SDK 头文件核实，实现可直接照抄）

```c
// NAPI 桥（native_node_napi.h，API 12+）
int32_t OH_ArkUI_GetNodeHandleFromNapiValue(napi_env env, napi_value frameNode, ArkUI_NodeHandle* handle);
int32_t OH_ArkUI_GetNodeContentFromNapiValue(napi_env env, napi_value value, ArkUI_NodeContentHandle* content);

// provider 与回调（native_interface_accessibility.h，API 13+ / provider 取用 API 23+）
int32_t OH_ArkUI_NativeModule_GetNativeAccessibilityProvider(ArkUI_NodeHandle* node, ArkUI_AccessibilityProvider** provider);
int32_t OH_ArkUI_AccessibilityProviderRegisterCallback(ArkUI_AccessibilityProvider* provider, ArkUI_AccessibilityProviderCallbacks* callbacks);
ArkUI_AccessibilityElementInfo* OH_ArkUI_AddAndGetAccessibilityElementInfo(ArkUI_AccessibilityElementInfoList* list);
ArkUI_AccessibilityElementInfo* OH_ArkUI_CreateAccessibilityElementInfo(void);
ArkUI_AccessibilityEventInfo*   OH_ArkUI_CreateAccessibilityEventInfo(void);
void    OH_ArkUI_SendAccessibilityAsyncEvent(ArkUI_AccessibilityProvider* provider, ArkUI_AccessibilityEventInfo* eventInfo, void (*callback)(int32_t errorCode));
int32_t OH_ArkUI_FindAccessibilityActionArgumentByKey(ArkUI_AccessibilityActionArguments* arguments, const char* key, char** value);

// ElementInfo 填充（全部 int32_t，第一参数为 info）
SetElementId(info, int32_t) · SetParentId(info, int32_t) · SetComponentType(info, const char*)
SetAccessibilityText(info, const char*) · SetContents(info, const char*) · SetHintText(info, const char*)
SetScreenRect(info, ArkUI_AccessibleRect*)   // {leftTopX, leftTopY, rightBottomX, rightBottomY} 均为 int32_t
SetClickable(info, bool) · SetEnabled(info, bool) · SetFocusable(info, bool) · SetChecked(info, bool)
SetOperationActions(info, int32_t count, ArkUI_AccessibleAction* actions)  // {actionType, description}

// 回调结构体（7 项，均已测绘）
findAccessibilityNodeInfosById(int64_t, ArkUI_AccessibilitySearchMode, int32_t, ArkUI_AccessibilityElementInfoList*)
findAccessibilityNodeInfosByText(int64_t, const char*, int32_t, ArkUI_AccessibilityElementInfoList*)
findFocusedAccessibilityNode(int64_t, ArkUI_AccessibilityFocusType, int32_t, ArkUI_AccessibilityElementInfo*)
findNextFocusAccessibilityNode(int64_t, ArkUI_AccessibilityFocusMoveDirection, int32_t, ArkUI_AccessibilityElementInfo*)
executeAccessibilityAction(int64_t, ArkUI_Accessibility_ActionType, ArkUI_AccessibilityActionArguments*, int32_t)
clearFocusedFocusAccessibilityNode()
getAccessibilityNodeCursorPosition(int64_t, int32_t, int32_t*)
```

**实现进展（2026-09-19，宿主侧已完成）**：`host_napi.cpp` 已实现 `attachAccessibilityNode`
（`GetNodeHandleFromNapiValue` → `GetNativeAccessibilityProvider` → `RegisterCallback`）与 7 个回调
（ById 根节点/子节点、ByText 文本或描述子串、Focused/NextFocus 首个/下一个可聚焦、ExecuteAction
转发动作监听器、ClearFocus、CursorPosition），ElementInfo 用 `AddAndGetAccessibilityElementInfo`
+ id/parent/组件类型/文本/内容/屏幕矩形（来自发布边界）/可点击/可用/可聚焦 填充；
`accessibilityStatus` 回传附着状态。宿主构建与自签名通过 ✓。
**剩余**：壳调用 `host.attachAccessibilityNode(<自定义节点>)`（唯一平台绑定步骤）。

**动作与事件（已完成）**：托管侧 `SetActionHandler` 注册动作监听器，宿主
`executeAccessibilityAction` 转发；`HandleAccessibilityAction` 把 CLICK 还原为正常触摸路径
（节点中心点模拟点击，等价真实触摸），并已用 headless 断言验证（点 'tap me' 节点 → 触发其 Tap 手势）；
帧差标志经 `ohos_host_accessibility_send_event` 以 `SendAccessibilityAsyncEvent` 上报。

实现顺序（照抄上式）：壳传 `NodeContainer`/自定义节点的 NAPI 值 → 宿主 `GetNodeHandleFromNapiValue`
（若节点非 `ARKUI_NODE_CUSTOM` 则先 `NodeContent_AddNode` 挂自有 CUSTOM 根）→ `GetNativeAccessibilityProvider`
→ `RegisterCallback` → 回调读 `ohos_host_accessibility_count/get` → 填充 ElementInfo →
`executeAccessibilityAction` 回调托管（新增 `ohos_host_accessibility_set_action_listener`）→
`PendingEventCount` 转 `SendAccessibilityAsyncEvent`。

已就绪的事件源：`OpenHarmonyAccessibility.PendingEventCount`（帧间差异 → 页状态/页内容/文本更新
标志，托管状态、宿主不可用时也计算），宿主只需把它转成 `OH_ArkUI_SendAccessibilityAsyncEvent`。

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

## 5b. 发布物形态与第三方安装（重要更正）

发布的 `dist/openharmony-workload-<ver>.tar.gz` 是**一个 NuGet feed（116 个 nupkg）**，不是 `packs/` 目录：

- 版本号规则：**各 pack 有独立版本**（例如 feed 中的 `Microsoft.OpenHarmony.Sdk.1.0.0-preview.1.nupkg`），
  以 `WorkloadManifest.json` 声明的 id+version 为权威；`packs/` 是本机布局，`feed/` 是发布布局。
- 第三方安装方式：
  ```bash
  dotnet workload install openharmony --source <解压后的 feed 目录>
  ```
- 校验脚本：`scripts/verify-clean-install.sh`（解包 → 按 manifest 逐包核对 feed → 检查 SDK 包内的
  宿主/壳归档/hap 打包目标/签名脚本 → 打印安装命令），当前输出 **CLEAN INSTALL FEED OK** ✓。
- 演示应用的 **hap 签名**仍需按 `2026-09-19-ohos-signing-and-udid-guide.md` 注入目标设备 UDID（9568344 的根因）。

## 5c. 校验和附件状态（如实记录）

- `workload-1.0.0-preview.23`（版本化 release）：**已附 `SHA256SUMS`** ✓（实测资产列表含
  `openharmony-workload-1.0.0-preview.23.tar.gz` 与 `SHA256SUMS`）。
- `workload-latest`（滚动 release）：**已附 `SHA256SUMS`** ✓（实测：`openharmony-workload-latest.tar.gz`
  + `SHA256SUMS`）。补齐过程与事故记录：脚本用「删除再创建」刷新滚动 release，本次因 tag/目标分支
  问题在删除后创建失败，**导致该 release 短暂消失** ✗；已手工重建并上传校验和，两个 release 现均正常 ✓。
  **遗留加固项**：`publish-workload-release.sh` 的删除+创建流程应改为不删除（例如 create 时用
  `--target`/先清理 tag、或改用 `gh release upload --clobber`），避免刷新失败造成发布缺失。
- 本地 `dist/` 被 gitignore（属构建输出）：校验和文件由 `scripts/release-checksums.sh` 生成，
  随 release 附件分发，不入库。

## 6. 阻塞与外部依赖

- **真机验收**：`hdc` 被组织策略拦截（"Operation restricted by the organization"）；
  `devecocli` 需 DevEco Studio 或 HarmonyOS Command Line Tools（本机均未安装）。
  验收清单：`docs/plans/2026-09-18-ohos-device-validation-checklist.md`。
- **D4 Hot Reload**：需设备连接通道 + 运行时 metadata update（EnC）。
- **无障碍**：仅剩绑定层（第 3 节配方）。

## 7. D3 配方：BlazorWebView / HybridWebView

已确认的 ArkWeb 能力：`registerJavaScriptProxy`、`runJavaScript`、`postMessage`
（`@ohos.web.webview.d.ts`）。建议实施顺序：

1. **壳（`templates/ets/pages/Index.ets` 的隐藏 Web 组件旁）**
   - `controller.registerJavaScriptProxy({ invokeDotNetMethod: (assembly, methodId, argsJson) => host.notifyJsInvoke(assembly, methodId, argsJson), dispatchEvent: (name, detailJson) => host.notifyJsEvent(name, detailJson) }, 'dotnetHost', ['invokeDotNetMethod', 'dispatchEvent'])`
   - 注入脚本：`controller.runJavaScript('window.__ohosDotNet = window.dotnetHost;')`
   - 用 `controller.onMessage`/`postMessage` 作为回传通道的备选。
2. **宿主 / NAPI**
   - `ohos_host_web_eval(const char* script)` → `OhosWebEval(script)` → 壳执行 `controller.runJavaScript(script)`（回传结果经 `notifyWebEvent('evalResult', result)`）。
   - `notifyJsInvoke` / `notifyJsEvent` → 托管回调（注册模式复用 `ohos_host_register_web_*`）。
3. **托管切片**
   - `OpenHarmonyWebViewHandler`：实现 `EvaluateJavaScriptAsync`（走 `ohos_host_web_eval`，结果以 TaskCompletionSource 等待 `evalResult`）。
   - 新增 `OpenHarmonyBlazorWebViewHandler : OpenHarmonyViewHandler<IBlazorWebView>`（SliceHandlers 注册）：
     `RootComponents` → `AddRootComponent`、`HostPage` → 载入 `app://`/`https://0.0.0.0/` + 资源服务
     （**待核实** ArkWeb 的请求拦截 API：`onInterceptRequest`/`WebResourceRequest`；不可用时的兜底：
     把 host page 与 `_framework` 以 `data:`/`blob:` 或本地临时文件 + `file://` 注入）。
   - `HybridWebView`：`SendRawMessage`/`RawMessageReceived` 复用同一 JS 通道（`invokeDotNetMethod('HybridWebView', 'SendRawMessage', …)`）。
4. **验证**
   - 离设备：断言 handler 注册、`EvaluateJavaScriptAsync` 在无宿主时优雅降级、Blazor 组件映射（`RootComponents` 计数）；
   - 真机：加载 Blazor 页面 → 断言 JS→.NET 往返（按钮点击触发 C# 方法）与渲染。
5. **依赖**：`Microsoft.AspNetCore.Components.WebView.Maui`（NuGet）；`blazor.webview.js` 资源随包发布；
   运行时使用已移植的 ASP.NET Core 组件栈（`aspnetcore-ohos`）。

## 8. D4 配方：Hot Reload

1. **工具链**：`dotnet watch` + `Microsoft.Extensions.HotReload`（agent）在设备侧进程内加载；
   XAML 热重载还需 `Microsoft.Maui.Controls.Xaml` 的元数据更新钩子与文件变更通知。
2. **连接通道**：agent 需与 `dotnet watch`（主机）通信 —— 当前依赖 `hdc`（`hdc fport` 转发）
   **被组织策略拦截**；备选：USB/TCP 直连（同样需设备可访问）。**这是 D4 的唯一硬阻塞**。
3. **运行时能力**：确认 CoreCLR 端口启用了 metadata update（`MetadataUpdater.IsSupported`
   与 `Microsoft.DotNet.HotReload` 所需接口）；未启用则需在运行时侧开启 EnC 支持并随 pack 发布。
4. **无工具链时的等价做法**：改动 → 重编译 → 重打包 hap → 重装（本仓库脚本已支持，见第 5 节）。

## 9. 并行批次轨迹（2026-09-20 更新）

按"文件所有权切分 + 后台子代理"推进，每批强制：宿主 `selfsign ok` / 套件不回归 / 失败即回滚 / 禁强推 / 证据归档。

| 批次 | 内容 | 关键结论 | 套件 |
|---|---|---|---|
| A | 传感器扩展（Magnetometer/Compass/Barometer/Orientation）| 复用 `ohos_host_sensor_*`，宿主零改动；单位/语义不确定项已记录 | 132 |
| B | TextToSpeech | **本 SDK 无 Speech Kit**（两次真实 hvigor 编译拒绝）→ 链已接、sink 如实返回不可用 | 131 |
| C | Launcher / Browser / Share | `@ohos.app.ability.common`/`Want` 可编译；startAbility（`viewData`/`sendData`）；无 Share Kit → 文本键用生态惯例 | 138 |
| D | 桌面菜单 | `bindMenu` + 动态 `MenuElement[]`（宿主表 `begin/item/commit`）；模态感知刷新；子菜单展平 | 144 |
| E | 拖放 | **分发 API 公开**（无需反射）；长按 500 ms + slop 8 px；`DropResult` 为 internal | 147 |
| F | 触感 + 主题跟随 | 触感复用 `ohos_host_vibrate`（仅时长）；主题经 `colorMode` → `notifyTheme` | 152 |
| G | ArkWeb JS 桥 + 最小 HybridWebView | `dotnetHost.postMessage` + `EvaluateJavaScriptAsync`；proxy 须 `onControllerAttached`；**资源服务缺失** | 157 |
| ① | Orientation → ROTATION_VECTOR(259) 真四元数 w | 宿主监听器扩展第 4 分量；重建签名 | 158 |
| ② | `InstallEssentials` 技术债 | 改为显式 no-op（默认经 DI + `[ModuleInitializer]`）| 158 |
| ③ | 脚本 `log()/warn()` | 5 个自有脚本加时间戳助手；`sh -n` 全过 | 158 |
| H | 日历 + 联系人 | `@kit.ContactsKit`/`@kit.CalendarKit` **编译通过**；探测：**PrintingKit/MapKit 缺失**、**ConnectivityKit 可用**（避开未导出的 `GattClientDevice`）| 163 |

**§8 刷新链（含 `.so` 同步修正）**：`build-arkts-shell.sh` → 拷 abc 入包 → `build-host.sh` → **拷签名 `.so` 入包与 `~/.dotnet/packs` 安装副本** → `release-checksums.sh` → `pack-workload-bundle.sh` → `publish-workload-release.sh` → `dotnet publish … -p:OpenHarmonyHapPackage=true`；**校验点 = hap 内 `modules.abc` 与 `.so` 体积** ✓。

**发布物一致性（当前）**：hap 内 `modules.abc` **40,048 B** · `.so` **117,664 B** · bundle 30,018,685 B · 两 release 均含 `SHA256SUMS` ✓。

## 10. 剩余队列（按依赖）

1. **打包权限注入**（`-p:OpenHarmonyExtraPermissions=…`）→ 启用 H 的联系人/日历（**进行中：后台批次**）；
2. **HybridWebView 资源服务**（`onInterceptRequest` + `wwwroot`/`hybridwebview.js`）→ 之后才可能做 **BlazorWebView**（**同批探测中**）；
3. 蓝牙（ConnectivityKit ✓）/ 打印（`@ohos.print` ✓）/ 地图（本 SDK 无 MapKit → 自绘或 ArkWeb 方案评估）；
4. 无障碍 provider 真机判读（`[maui] accessibility provider status=N`：1 已附着 / 2 需 CUSTOM 节点 / 3 仅收到 NodeContent）；
5. **真机验收**（`hdc` 被组织策略关闭）与测试方按 UDID 重签（`scripts/sign-for-device.sh`）；
6. 上游：#132953（已批准，等 Helix 重跑/合并）· #132827（待复评）——两条无 @ 评论文案已备。
