# MAUI → OpenHarmony 移植可行性分析（2026-09-16）

对象：`springmin/maui-ohos`（dotnet/maui 的新鲜 fork，创建于 2026-09-16，仅 `main`，
尚无任何 OHOS 代码；tree 28,731 条目 / 26,322 文件）。

## 0. 结论

**可行，但工作量集中在 UI 与应用模型层，而不是运行时层。** 运行时/工具链底座
（CoreCLR+JIT、SDK、apphost、Crossgen2/R2R、部分 NativeAOT、ELF 签名与 release 打包）
本项目已经具备；MAUI 的平台切片结构清晰、有 **Tizen 这个最小完整先例**可对标复制。
设备侧（HarmonyOS SDK 26.0.0.18）已核实具备做原生 UI 所需的全部关键 NDK：

- ArkUI NDK 节点 API：`ARKUI_NODE_BUTTON/TEXT/TEXT_INPUT/TEXT_AREA/TEXT_EDITOR/IMAGE/
  LIST/GRID/SCROLL/SWIPER/REFRESH/SLIDER/PROGRESS/RADIO/PICKER/DATE_PICKER/
  CALENDAR_PICKER/EMBEDDED_COMPONENT/CUSTOM`（含自定义绘制事件），
  `OH_ArkUI_NodeContent*` 可把 NDK 节点树嵌入 ArkTS 页面；
- 输入/手势/键事件/对话框/无障碍接口头：`native_gesture.h`、`ui_input_event.h`、
  `native_key_event.h`、`native_dialog.h`、`native_interface_accessibility.h`；
- 表面渲染：`ace/xcomponent/native_interface_xcomponent.h` + EGL/GLES；
- WebView：`web/native_interface_arkweb.h`（`OH_ArkWeb_GetNativeAPI`、RunJavaScript、
  JS proxy、cookie）→ **Blazor Hybrid 有官方 NDK 通道**；
- 打包签名：`bin/hap-sign-tool`、`build-tools/binary-sign-tool`。

三条路线按投入递增：**A. Blazor Hybrid 先行** → **B. ArkUI NDK 原生控件后端** →
**C. XComponent + Skia 自绘**（补齐复杂控件）。建议 A→B 递进，C 视需要。

## 1. 现状盘点（证据）

### 1.1 MAUI 的平台切片规模（API tree 统计）
| 平台 | 路径含平台名文件数 | `*.{Platform}.cs` |
|---|---|---|
| Tizen（最小完整先例） | 165 | 100 |
| Android | 354 | 215 |
| iOS | 329 | 195 |
| Windows | 312 | 189 |

Tizen 切片的分布：`src/Controls/src/Core` 99、`src/Core/src/Platform` 60、
`src/Compatibility` 48、`src/Core/src/Handlers` 44、`src/BlazorWebView/src/Maui` **仅 3**、
`src/Core/src/{Fonts,ImageSources,LifecycleEvents}` 12、`src/SingleProject/Resizetizer` 3。

### 1.2 平台接入点（复制 Tizen 模式）
- `Directory.Build.props`（根）：`_MauiTargetPlatformIs<Tizen>`、
  `Include<Tizen>TargetFrameworks`、`<Tizen>TargetFrameworkVersion(Previous)`、
  `DotNet<Tizen>Workload*` 探测——新平台需要一套同名块。
- `src/Workload/Microsoft.NET.Sdk.Maui.Manifest/WorkloadManifest.in.json`：
  `maui-mobile` 由 `maui-android/maui-ios/maui-tizen` 组成，`maui-tizen extends [maui-blazor]`；
  平台 TFM 本身由平台自己的 workload 提供（Tizen = Samsung 的 `samsung.net.sdk.tizen`）。
- `src/Workload/Microsoft.Maui.Sdk/Sdk/{Sdk.props,Sdk.targets,AutoImport.props,
  BundledVersions.in.targets,Microsoft.Maui.Sdk.*.targets}`：平台检测/版本/TFM 导入点。
- `PublicAPI/net-tizen/*`：平台 TFM 的公共 API 基线。
- Core：`src/Core/src/Platform/Tizen/*`（窗口/视图组/每控件 mapper/Dispatcher/
  Navigation/Modal/Gesture/字体/图像扩展）+ `src/Core/src/Handlers/**/*.Tizen.cs`。
- Controls：每控件 `*.Tizen.cs` + `Handlers/{Items,Shell,Shapes}/**/*.Tizen.cs` +
  `PlatformConfiguration/TizenSpecific/*` + Compatibility 渲染器。
- BlazorWebView：`src/BlazorWebView/src/Maui/Tizen/{BlazorWebViewHandler.Tizen.cs,
  TizenWebViewManager.cs,TizenMauiAssetFileProvider.cs}`（仅 3 文件 + 共享 handler）。

### 1.3 我们已有的底座（runtime-ohos / sdk-ohos）
- CoreCLR + JIT 在 OHOS 设备可运行（W^X 默认关闭、TMPDIR 契约、musl ABI）；
- SDK（workload 机制可用）、apphost、`Microsoft.NETCore.App.Runtime.openharmony-arm64`
  与 host pack、Crossgen2/CoreLib R2R、ILCompiler 部分支持（NativeAOT for OHOS）；
- 签名工具链：ELF `.codesign`（自签）+ 设备侧 `hap-sign-tool`（HAP 签名，已核实）；
- CI 使用的 OpenHarmony SDK 为 `ohos/os/6.0.0.1-Release` 的 **native/ only**
  （`ohos-ci-env.sh`），完整 OpenHarmony SDK 另带 ArkTS/打包工具。

## 2. 需要新增的组件（分块与规模）

1. **平台 TFM + workload（`net11.0-openharmony`）**
   - SDK 侧：平台识别（workload manifest + `AutoImport.props`/targets）、
     `Microsoft.OpenHarmony.Sdk`（平台 MSBuild：pack 选择、app 打包集成）、
     `Microsoft.OpenHarmony.Ref`（首版可为最小 P/Invoke 帮助库）、runtime/host pack
     别名（复用现有 release 产物）。
   - MAUI 侧：`Directory.Build.props` 平台块、`maui-openharmony` workload、
     `BundledVersions`/`AutoImport` 条目、`PublicAPI/net-openharmony`。
   - 规模：SDK/工作负载 ~10–20 文件；MAUI 基建 ~10 文件。
2. **应用模型宿主（Ability + NAPI）**：ArkTS `UIAbility` + `NodeContent`/`XComponent`
   加载 NAPI 模块 `libmaui_ohos.so` → 启动 hostfxr → 调 MAUI 入口；生命周期映射
   （Ability onCreate/Foreground/Background/Destroy ↔ MAUI Window/Lifecycle）、主线程
   Dispatcher 桥。规模：C/C++ 宿主 1–3k LoC + ArkTS 壳 ~200 LoC。
3. **Core 平台切片**（对标 Tizen 的 60+44 文件）：`Platform/OpenHarmony` 基础设施
   （Window/ViewGroup/Dispatcher/Gesture/Modal/Navigation/字体/图像/颜色/mappers）+
   `Handlers/**/*.OpenHarmony.cs`（每控件映射到 ArkUI NDK 节点）。
   首版 10–15 控件 ≈ 40–60 文件；完整 ≈ 100 文件。
4. **Controls 平台切片**：每控件 `*.OpenHarmony.cs`、Shell/导航、
   `PlatformConfiguration/OpenHarmonySpecific`、PublicAPI 基线（≈100 文件，可增量）。
5. **Essentials**：逐特性实现；多数能力在 OHOS **仅 ArkTS API**，需要统一 NAPI shim
   层（ArkTS 侧）+ `*.OpenHarmony.cs`。建议最小集：FileSystem/Preferences/DeviceInfo/
   Launcher/Clipboard/Connectivity（其余增量）。
6. **BlazorWebView**：`BlazorWebViewHandler.OpenHarmony.cs` + `OhosWebViewManager`
   （ArkWeb NDK）+ `AssetFileProvider`（3–5 文件）——**里程碑 1**。
7. **SingleProject / Resizetizer / 打包**：资源 resize（宿主侧无关平台）+ `.hap`
   打包 targets（`hap-sign-tool`/`app_packing_tool`，或调 hvigor）、图标/签名配置、
   MAUI 应用模板（`src/Templates`）。
8. **测试**：DeviceTests 运行器平台切片 + 冒烟；MAUI 的 UITests 是 Appium 体系，
   OHOS 需自建或先省略（Tizen 的 CI 也受限——上游 CI 里 Tizen 默认被关）。

## 3. 建议分期（路线图）

| 阶段 | 目标 | 预估 | 关键交付 |
|---|---|---|---|
| **P0 PoC** | Ability+NAPI 宿主启动 CoreCLR，创建第一个 ArkUI NDK 节点 | 1–2 周 | 设备上跑通 "hostfxr → .NET → ArkUI 节点" |
| **P1 Blazor Hybrid** | ArkWeb NDK + `BlazorWebViewHandler.OpenHarmony` + 最小 Core/Controls（Window/Layout/Label/Button/WebView）+ `MauiApplication` + `.hap` 打包脚本 | 1–2 月 | "MAUI Blazor 应用跑在 OHOS"（可交付演示） |
| **P2 原生控件后端** | ArkUI NDK handlers：文本/输入/按钮/图片/列表/滚动/手势/导航/Shell/Shapes/Refresh | 3–6 月（2–4 人） | 常用控件原生外观 + Essentials 常用集 |
| **P3 完整度/上游化** | 动画/无障碍/主题、Resizetizer、模板、NativeAOT 发布、性能与内存 | 持续 | 可发布形态；视情上游（第三方平台 PR 模式） |
| **可选 C** | XComponent + SkiaSharp(OHOS) 自绘（复杂控件/图表） | 1–2 月 | Skia for OHOS 原生库 + 自绘 handler |

## 4. 关键风险与对策

| 风险 | 说明 | 对策 |
|---|---|---|
| 平台 TFM | MAUI 全链路依赖 `TargetPlatformIdentifier`；当前 SDK 无 OHOS TFM（S1a/S1b 是库侧权宜） | 在自有 SDK fork 上提供 `Microsoft.OpenHarmony.Sdk` workload（对标 Samsung Tizen）；PoC 期先用 `net11.0` + `TargetsOpenHarmony` 短路 hack |
| ArkTS-only 能力 | 权限、传感器、存储、Web 部分 API 只有 ArkTS 暴露 | 统一 NAPI shim 层（一个 ArkTS 模块 + C 桥），收敛所有跨语言调用 |
| 应用模型/沙箱 | Ability 生命周期、后台限制、权限弹窗与 Android 差异大 | P0 起就在真机验证；生命周期映射表先行 |
| `.hap` 打包/签名 | 正式 HarmonyOS 签名需开发者证书 | OpenHarmony 侧用 dev 证书 + `hap-sign-tool`（设备已具备）；MSBuild 集成或先用脚本 |
| 上游 rebase | dotnet/maui 迭代快 | 平台代码全部落在 `*.OpenHarmony.cs`/`Platform/OpenHarmony`/`OpenHarmony/` 目录，尽量少改共享文件；锁定 release 分支定期合并 |
| 反射/裁剪 | XAML/绑定大量反射；NativeAOT 需适配 | 首版用 CoreCLR JIT（OHOS 已支持，W^X 关闭）；AOT 作为 P3 |

## 5. 立即可做的下一步

1. 在 `maui-ohos` 建 `feature/openharmony` 分支；先加 `Directory.Build.props` 平台块与
   `WorkloadManifest` 骨架（`IncludeOpenHarmonyTargetFrameworks` 条件短路，保证其余平台零影响）。
2. P0 宿主 PoC：ArkTS `UIAbility` + NAPI `libmaui_ohos.so` + hostfxr（可用 runtime-ohos
   的 host pack），目标：设备上打印日志并创建一个 ArkUI `Text` 节点。
3. 打通 BlazorWebView 最小路径（ArkWeb NDK）+ `.hap` 打包脚本（`hap-sign-tool`）。

## 6. 证据与参考

- API tree 统计与关键文件清单（本次分析，见 `final-evidence/maui-ohos-feasibility-20260916.txt`）；
- 设备 NDK（HarmonyOS SDK `26.0.0.18_2`）：`arkui/native_node.h`、`ace/xcomponent/`、
  `web/native_interface_arkweb.h`、`libace_ndk.z.so`、`bin/hap-sign-tool`；
- fork CI 的 OpenHarmony SDK 来源：`repo.huaweicloud.com/openharmony/os/6.0.0.1-Release`
  （`eng/ohos-install/build/ohos-ci-env.sh`）；
- 已有底座：runtime-ohos（CoreCLR/SDK）、apphost、R2R/AOT、ELF 签名与 release 流水线。

## 7. 附：syscall 与沙箱实测（2026-09-16）

- **设备侧探针**（fork-per-syscall，自签后运行；源码/原始输出见
  `final-evidence/maui-ohos-syscall-probe-20260916.{c,txt}`）：
  shell 域（`u:r:hishell_hap:s0`）下 `timerfd/eventfd/epoll/pidfd/inotify/AF_UNIX/AF_NETLINK/
  memfd/mmap/madvise/getrandom/...` 可用；`get_mempolicy/close_range/rseq/openat2/
  epoll_pwait2` 被 trap；`signalfd4/io_uring/sched_affinity/mlock/statx/getcpu/sendmmsg/
  ptrace/process_vm_readv/perf_event_open` 及图形设备节点（`/dev/dri`、`/dev/dma_heap`、
  `/dev/mali0`、`/dev/vsync`）EPERM。
- **权威对照**：OpenHarmony `app.seccomp.policy`（对所有应用进程生效，默认 TRAP）的
  `@allowList` **包含**上述全部 EPERM 项（`ioctl`/`futex` 为 `@priority`；`sendmmsg`/
  `sched_affinity`/`mlock`/`signalfd4`/`getcpu`/`statx`/`ptrace`/`process_vm_readv`/
  `perf_event_open` 均列名），app 基线黑名单只有 mount/module/uid/hostname/reboot 类。
  ⇒ **MAUI 托管侧与 UI 侧都不需要申请任何 syscall 放宽**；shell 探针的 EPERM 不代表
  app 域（详见 `2026-09-01-ohos-syscall-audit.md` Addendum 4/5）。
- **.NET 功能实测**（设备 `~/.dotnet` SDK）：`ProcessorCount=20`（与内核 0-19 一致）、
  `GetCurrentProcessorId` 正常、UDP 同步/异步 1500 包与 TCP loopback 全通；运行时源码
  `src/` 中**无 `sendmmsg` 使用** ⇒ `sendmmsg`/`sched_getaffinity` 无需放宽。
- **UI 设备节点**：属 SELinux 域能力（每个 OHOS 应用都能渲染），须在**真实 hap 的 app
  进程内**复验；本次设备上受限：`hdc list targets` 返回
  `Operation restricted by the organization`（组织策略），且本机 SDK 无
  `app_packing_tool`/`es2abc`，无法本地构建/安装测试 hap。
  P0 复验前置条件：可安装应用的设备（或 OpenHarmony 开发板）+ 完整 OHOS SDK 工具链
  （打包工具 + ArkTS 编译器）；签名可用 `hap-sign-tool` 自签 profile（工具已具备）。
