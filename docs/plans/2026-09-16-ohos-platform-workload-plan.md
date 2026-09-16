# OpenHarmony 平台 workload 迁移规划（以 iOS 完整 workload 为参照，2026-09-16）

目标：给出从"最小骨架"走向"完整平台 workload"的完整迁移路径，参照 dotnet/macios（iOS）的
实际演进方式（workload 化、pack 拆分、TFM/版本命名、Bundle/安装器、MAUI 集成）。

## 0. 目标终态：一个"完整"平台 workload 应该长什么样

对标 iOS（`Microsoft.iOS.Sdk / Ref / Runtime.* / Bundle` + `Microsoft.NET.Sdk.iOS.Manifest-*`）：

| 组成 | iOS 实例 | OpenHarmony 终态 |
|---|---|---|
| Manifest | `microsoft.net.sdk.ios`（`WorkloadManifest.json`、`WorkloadManifest.targets`、`WorkloadDependencies.json`、Rollback） | `microsoft.net.sdk.openharmony`（同结构；依赖声明 NDK/hap 工具/hdc） |
| Sdk pack | `Microsoft.iOS.Sdk.net10.0_26.4`：`Sdk/AutoImport.props`（平台属性 + 隐式平台引用）+ `Sdk/Sdk.targets`（构建/打包/AOT/签名）+ `KnownFrameworkReference`/`KnownRuntimePack`/`KnownAppHostPack` | `Microsoft.OpenHarmony.Sdk.net11.0_<api>`：AutoImport（TFM/平台属性、注入 `Microsoft.OpenHarmony` 引用）+ targets（`publish → .hap`：`ohos_packing_tool` + `hap-sign-tool`，ArkTS 壳模板）+ 三条 Known* 绑定 |
| Ref pack | `Microsoft.iOS.Ref.net10.0_26.4`（`Microsoft.iOS.dll` 全量绑定） | `Microsoft.OpenHarmony.Ref.net11.0_<api>`：完整 OHOS API 绑定（NDK C API 手写 interop + `@ohos.*` 生成绑定；按 API level 分版本） |
| Runtime packs | `Microsoft.iOS.Runtime.ios-arm64.net10.0_26.4`（Mono AOT 运行时 + 平台实现程序集） | `Microsoft.OpenHarmony.Runtime.openharmony-arm64.net11.0_<api>`（CoreCLR + hostfxr/muxer + `Microsoft.OpenHarmony.dll` 实现） |
| Bundle/安装器 | `Microsoft.iOS.Bundle.<ver>.pkg`（含 SDK/Xcode 资源） | `Microsoft.OpenHarmony.Bundle`（OHOS SDK/NDK 引用、hap 工具；或仅 NuGet + `WorkloadDependencies`） |
| Templates | `Microsoft.iOS.Templates` | `Microsoft.OpenHarmony.Templates`（app 壳/NAPI 模板） |
| TFM | `net11.0-ios26.0`（平台版本 = Xcode SDK 版本；`SupportedOSPlatformVersion` 校验 + `TargetPlatformVersion`） | `net11.0-openharmony<api>`（建议平台版本 = OpenHarmony **API level**，如 `openharmony14.0`） |
| 多 band/多版本 | `Microsoft.iOS.Sdk.net8.0_17.0 / net9.0_18.0 …` + `alias-to`（PR #19765）；`KnownFrameworkReference` 精确版本（PR #15785）；AutoImport 按 `TargetFrameworkVersion` 条件导入（PR #15197） | 同模式：`net10/net11` × API level（12/14/…），alias-to + 条件导入 |
| 生态 | `dotnet workload install ios`、MAUI `maui-ios extends [ios]`、device tests、API diff、发布流程 | `dotnet workload install openharmony`、`maui-openharmony extends [maui-blazor, openharmony]`、同套生态 |

## 1. iOS 的迁移路径（可直接套用的四步）

1. **运行时 + 绑定打底**（Xamarin 时代 → .NET 5+）：
   Mono 运行时上平台 + `bgen`/`ApiDefinition.cs` 生成**全量绑定**（`Microsoft.iOS.dll`）。
2. **workload 化**（xamarin-macios PR #9897）：
   把平台拆成 `Microsoft.iOS.Sdk`（`Sdk.props` → `AutoImport.props`）/`Ref`/`Runtime.<rid>` 三类 pack
   + `WorkloadManifest.json`/`WorkloadManifest.targets`；先"本地安装"（`sdk-manifests/` + `packs/` 目录/符号链接）验证，
   再出 `Microsoft.iOS.Bundle.pkg` 安装器。
3. **TFM/版本与多 band**（PR #15785、#19765、#15197）：
   pack 名带 TFM+平台版本（`…net8.0_17.0`）、`alias-to` 做多 band、`KnownFrameworkReference` 指精确 ref/runtime 版本、
   `AutoImport.props` 按 `$(TargetFrameworkVersion)` 条件导入避免重复导入。
4. **生态闭环**：Bundle/安装器、模板、MAUI 集成（`maui-ios` 只是 `extends [ios]` + MAUI 库包）、
   device tests、API diff（PublicAPI 基线）、NuGet 发布与 band 发布流程。

> 要点：**iOS 的"完整"体现在 Ref 的 API 覆盖度（全量 UIKit/Foundation）与打包工具链（actool/codesign/AOT）**；
> pack/manifest/TFM 这套"交付机制"本身很薄。

## 2. OpenHarmony 迁移分期（W0–W5）

| 阶段 | 内容 | 产出/验收 | 依赖/状态 |
|---|---|---|---|
| **W0 基线（已完成）** | CoreCLR+JIT（W^X 关闭/TMPDIR 契约）、SDK fork、runtime/apphost pack、CoreLib R2R、部分 NativeAOT、`.hap` pack+sign 链（设备验证 `verify-app success`）、ArkUI NDK/NAPI 探针、app 域 seccomp 对照、MAUI 分支骨架 | 见 `2026-09-16-maui-ohos-p0.md` / 本目录另两份文档 | ✅ |
| **W1 最小 workload** | 本地 `sdk-manifests/microsoft.net.sdk.openharmony/` + `Microsoft.OpenHarmony.Sdk`（`Sdk/AutoImport.props` + `Sdk/Sdk.props/targets`：TFM 识别、`KnownFrameworkReference/KnownRuntimePack/KnownAppHostPack`、`publish→.hap`）+ 薄 `Microsoft.OpenHarmony.Ref`（`SupportedOSPlatform("openharmony1.0")` + slice interop）+ runtime/apphost pack **别名**指向现有产物 | `dotnet build/publish -f net11.0-openharmony1.0`：编译 slice 成功、产出可安装 `.hap`；用 `DOTNETSDK_WORKLOAD_MANIFEST_ROOTS` 挂载不改设备 SDK | 1–2 周；验证起点=P0 宿主模板 |
| **W2 平台宿主与运行时契约** | NAPI 宿主（`libcoreclr`/hostfxr）、Ability 生命周期映射、ArkUI NDK UI 基座、Dispatcher/线程、权限、hap 打包集成进 targets、`PublishAot`（OHOS ILCompiler，已有部分）、设备部署/调试（hdc install、aa start、hilog）、MAUI `MauiApplication` 等价物 | 设备上跑通 **MAUI Blazor Hybrid Hello**（P1 里程碑）；`.hap` 由 MSBuild 一键产出 | 1–2 月；需可安装设备/开发板 |
| **W3 绑定与 API 面（Ref 完整化）** | 双轨：①NDK C API 手写 interop（ArkUI/window/vsync/web/napi/hilog…）打底；②`@ohos.*` ArkTS API 的**生成绑定**（IDL/ApiDefinition → NAPI shim → C#）；平台版本建模（`openharmony<api>`）、`SupportedOSPlatformVersion` 校验、`Microsoft.OpenHarmony.dll` 实现程序集、API diff/PublicAPI 基线 | Ref/Runtime pack 覆盖 MAUI slice 全量使用面；`dotnet build` 对未知 API 报版本错误而非静默 | 3–6 月+，可增量 |
| **W4 打包/发布完整化** | 资源（图标/启动图）、`.hap`/`.hsp`/多模块、签名 profile（OpenHarmony debug / HarmonyOS 商用）、SDK 安装器/Bundle、`WorkloadDependencies`（NDK/hap 工具/hdc）、多 band（net10/net11）与 `alias-to`、条件 AutoImport | 任意 `net*-openharmony*` 项目可 publish 出**可安装** hap；workload 可被 `dotnet workload install openharmony` 安装 | 与 W3 并行 |
| **W5 生态/上游化** | NuGet 发布、`dotnet/sdk` band 清单收录、MAUI `maui-openharmony extends [maui-blazor, openharmony]`、模板/文档、CI 矩阵（多 API level × 多 RID）、设备测试农场 | 上游可用形态（对标 dotnet/macios / dotnet/android 的独立仓 + 发布流程） | 持续 |

## 3. 关键决策点（建议值）

1. **平台版本语义（已核实数据，2026-09-16）**：采用 `openharmony<API level>`，对齐 iOS 的 Xcode 版本语义：
   - **本机设备/SDK：API 26** — 设备 `const.ohos.apiversion=26`、`OpenHarmony-7.0.0.105`
     （产品 HAD-W24/W32）；本机 SDK `ohos-sdk 26.0.0.18`（Beta），
     `native/oh-uni-package.json`: `apiVersion "26" / platformVersion "26.0.0"`。
   - **CI 构建用 NDK：API 20** — `ohos-ci-env.sh` 下载 `os/6.0.0.1-Release` 的
     Public SDK `6.0.0.48 (API Version 20 Release)`（release notes），只提取 `native/`。
   - 规则：`TargetPlatformVersion` = **编译用 SDK 的 API level**（iOS 同义），
     `SupportedOSPlatformVersion` = 最低可运行 API level（暂定 20，随验证下探）；
     设备（API 26）可运行 API 20 目标的应用。
   - 版本带：`net11.0-openharmony20.0`（CI 公共 SDK）与 `net11.0-openharmony26.0`
     （设备 Beta SDK）可并存，用 pack 名 + `alias-to` 承载（iOS 多版本带做法）。
2. **绑定策略**：**NDK-first 薄 ref + 逐步生成绑定**。MAUI slice 用 NDK C API + NAPI 桥即可跑通，
   无需先绑定全量 ArkTS API；但 Ref 一旦公开就应"完整或明确标注子集+计划"（W3 的版本校验与 API diff 兜底）。
3. **AOT/运行时**：CoreCLR（JIT + R2R）先行（现状），`PublishAot` 走 NativeAOT-for-OHOS（已有 ilc pack）；
   不引入 Mono（本移植无 Mono-on-OHOS 计划）。
4. **OpenHarmony vs HarmonyOS**：签名/信任链/设备政策不同（OpenHarmony 可用 debug profile 自签；
   HarmonyOS 商用设备需开发者证书 + UDID 绑定）。workload 先面向 **OpenHarmony**，HarmonyOS 作为下游发行。
5. **上游归属**：建议独立仓（`dotnet/openharmony` 风格）承载 Ref/Runtime/Sdk/Manifest；
   短期在 fork 内自测（`DOTNETSDK_WORKLOAD_MANIFEST_ROOTS`）。
6. **BCL 完整化**：`OSPlatform.OpenHarmony` / `OperatingSystem.IsOpenHarmony()` /
   `SupportedOSPlatform("openharmony")` 需要 runtime/BCL 侧收尾（当前只有 `IsOSPlatform("openharmony")`）。

## 4. 近期可执行清单（与现有工作对接）

- **W1 文件清单**（sdk-ohos 或新仓）：
  `sdk-manifests/<band>/microsoft.net.sdk.openharmony/{WorkloadManifest.json,WorkloadManifest.targets,WorkloadDependencies.json}`
  + `packs/Microsoft.OpenHarmony.Sdk/<ver>/Sdk/{AutoImport.props,Sdk.props,Sdk.targets,KnownFrameworkReference…}`
  + `packs/Microsoft.OpenHarmony.Ref/<ver>/ref/net11.0/Microsoft.OpenHarmony.dll`
  + runtime/apphost pack 别名（指向已发布的 `Microsoft.NETCore.App.Runtime.openharmony-arm64`、
    apphost pack）。
- **验收脚本**：`dotnet build -f net11.0-openharmony1.0`（库）+ `dotnet publish -r openharmony-arm64`
  （产 `.hap` + `hap-sign-tool verify-app success`）。
- **MAUI 对接**：P0 宿主模板进 Sdk pack 的 app 模板；`maui-openharmony extends` 待 W1 完成后补 `openharmony`。
- **运行时对接**：BCL 完整化项（`IsOpenHarmony()`/`OSPlatform`/`SupportedOSPlatform`）列入 runtime 待办。

## 5. 参考（iOS 侧证据）

- pack 命名 TFM+平台版本 + `alias-to`：dotnet/macios PR #19765（`Microsoft.iOS.Sdk.net8.0_17.0` 等）。
- workload 化（Sdk/Ref/Runtime 拆分、`AutoImport.props` 取代 `Sdk.props`、本地 `sdk-manifests` 安装）：
  xamarin-macios PR #9897。
- `KnownFrameworkReference` 精确版本与多 band 别名：PR #15785；`AutoImport` 按 TFM 条件导入：PR #15197。
- 发布顺序/nuget 教训（先 packs 后 manifests）：dotnet/sdk issue #23820。
