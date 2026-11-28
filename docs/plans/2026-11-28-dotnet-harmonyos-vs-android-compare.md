# dotnet-harmonyos vs dotnet/android：全子系统对照总览（2026-11-28）

> 基线
>
> - **HMOS**：`dotnet-harmonyos` 快照，workload `harmonyos`，pack `23.0.0-preview.2`，bundled runtime `10.0.4`，API 23，RID `hmos-musl-arm64` / `hmos-musl-arm`。
> - **Android**：`dotnet/android` 主线快照（2026-11-28 抓取，约 4366 个文件/5834 路径；当前主线面向 net11/net12）。
>
> 方法：先做**文件/目录级**盘点，再对 `Hap.targets` 与原生宿主做**目标级/函数级**内容对照。版本相关差异（net10 vs net11/net12、API 23 vs API 37）不计入移植改动。
>
> 本文件与两份深潜文档一并归档在 `docs/plans/`。

## 1. 结论摘要

| 问题 | 结论 |
|---|---|
| 两者是不是同一套 workload 改个名字？ | **不是**。只共享 .NET SDK/workload 的“壳”，打包模型、宿主模型、绑定方式、签名链、设备工具全部重写。 |
| 能否按同名文件做 1:1 diff？ | **不能**。`Mono.Android` 的 Java 绑定面与 `Microsoft.HarmonyOS` 的 NDK P/Invoke 面不是同一抽象；targets 也只是阶段级对应。 |
| 移植改动最大的三处是什么？ | ① JNI+Java runtime → NAPI+ArkTS 壳；② APK/Gradle/aapt2/D8 → HAP/hvigor/ArkTS；③ Java 生成绑定 → 手写 NDK P/Invoke。 |
| 被整体删除的官方组件？ | Java/R8/ProGuard/TypeMap/Java stubs/FastDev/Android SDK/adb/aapt2/zipalign/apksigner 相关任务与 targets；`Linker` 目录（改用 ILLink pack）。 |
| 新增的 HMOS 组件？ | 5 个 ArkTS Har 模块、NAPI 三宿主、Hvigor 集成、Har 打包、AGC 签名链、ICU transport pack、设备 TestHost 栈、Har/Bridge 模板。 |
| 最大结构风险？ | Build 内跑 publish 子图并写 `PublishDir`；签名/校验靠 AfterTargets 而非依赖链；`RuntimeController` 状态粘滞；原生工程被 SDK 写入 `.hmos-staged/`。 |

一句话：**Android 是“把 .NET 嵌进 Java/Android 应用模型”，HarmonyOS 是“把 .NET 运行时嵌进 ArkTS/HAP 应用模型”。**

## 2. 规模对照

| 子系统 | dotnet/android | dotnet-harmonyos |
|---|---|---|
| 总路径 | 5834 | 约 700 文件 / 154 MB |
| Build.Tasks | 494 文件 / **79 Task** | 104 文件 / **40 Task + 20 签名辅助** |
| Managed API | `Mono.Android` **414 文件** | `Microsoft.HarmonyOS` **101 文件** + `Ref.23`（1 个 csproj） |
| 原生宿主 | `native/clr` 56 + `common` 19 + `java-runtime/java` 16 | `load_runtime` 132（含 Mono 头文件） |
| 模板 | 7 个模板 / 185 文件 | 5 个模板 / 119 文件 |
| 测试 | `tests` 1254 文件 | `testframework` 95 + TestHost/Proxy/Protocol |

## 3. 工作负载清单

同名文件 `WorkloadManifest.in.json`：

| 项 | Android | HarmonyOS | 调整 |
|---|---|---|---|
| workload id | `android` | `harmonyos` | 改名 |
| SDK pack | `Microsoft.Android.Sdk.net12/net11` | `Microsoft.HarmonyOS.Sdk.net10` | 单版本 net10 |
| Ref pack | `Microsoft.Android.Ref.37` | `Microsoft.HarmonyOS.Ref.23` | API 23 |
| Runtime pack | `Microsoft.Android.Runtime.{37,CoreCLR/NativeAOT.37}.android-{arm,arm64,x64}` | 无独立 Runtime pack，**`Microsoft.HarmonyOS` framework pack** | 运行时随 framework pack |
| Templates | `Microsoft.Android.Templates` | `Microsoft.HarmonyOS.Templates.net10` | — |
| 主机平台 | 6 个（含 win-arm64/linux-arm64） | 3 个（win-x64/osx-arm64/linux-x64） | 缩减 |
| extends | `microsoft-net-runtime-mono-tooling*` | `microsoft-net-runtime-hmos-librarybuilder` | 换 Mono 工具链扩展 |
| RID | `android-arm/arm64/x64` | **`hmos-musl-arm/arm64`** | 新 RID，运行时回退 `linux-musl-*` |

## 4. SDK targets

Android：`Microsoft.Android.Sdk/targets` **21 个文件**；HMOS：`Microsoft.HarmonyOS.Sdk/targets` **19 个**。

| 类别 | Android | HarmonyOS |
|---|---|---|
| 公共 | `Sdk.targets`、`DefaultProperties.targets`、`BuildOrder.targets`、`CoreCLR.targets`、`NativeAOT.targets` | 同名对应 + `Sdk.CoreClr.props/.targets`、`Sdk.Mono.props/.targets`、`Sdk.NativeAot.props/.targets` |
| 应用打包 | `Application.targets`、`Publish.targets`、`RuntimeConfig.targets` | **`Hap.targets`（1778 行）**、`RuntimeApp.targets`、`Sdk.RuntimeLayout.props` |
| Java/R8 | `R8JniRemapping.targets`、`TypeMap.*.targets`（4）、`NativeAOT.R8.targets`、`HotReload.targets`、`Tooling.targets` | **全部移除** |
| 新平台 | — | **`Bindings.Hvigor.targets`**、`Sdk.ILLink.targets`、`Sdk.Testing.props/.targets`、`BundledVersions.in.targets`、`BuildTasks.props` |
| 其他 | `After.targets`、`AssemblyResolution.targets`、`ProjectCapabilities.targets`、`AndroidLibraries.targets` | 合并进 `Sdk.props/.targets` |

### 4.1 构建图的关键差别

Android：

- `Build` 只到 APK 的 `_CopyPackage`；`_Sign` 在 `SignAndroidPackage` 里；`Publish` 独立。
- APK 打包是 `_PrepareBuildApkDependsOnTargets` 的 23 步，包含 `_ResolveAssemblies`、`_LinkAssemblies`、`_GenerateJavaStubs`、`_CompileJava`、`_CompileDex`、`_CreateBaseApk`、`_CopyPackage`。

HarmonyOS：

- `_HmosBuildHapOnBuild` 挂在 `Build` 之后，一次性完成 `_PrepareHmosManagedClosure;HmosBuildHap;HmosWritePublishManifest`。
- `_PrepareHmosManagedClosure` 在 **Build 内**执行 `ResolveReferences; ComputeResolvedFilesToPublishList; ILLink; _HmosRunRuntimePublishGraph; GeneratePublishDependencyFile; _HmosMaterializeManagedClosure; _HmosRunPostClosureRuntimeGraph`，明确“不调用 `Target=Publish`”。
- `HmosBuildHapDependsOn` 20 项，最后是 `AssembleHmosHap`；签名/校验通过 `AfterTargets="AssembleHmosHap"` 触发。
- `Publish` 只复制已产出的 HAP/manifest，不重新打包/签名。

详见 `2026-11-28-dotnet-harmonyos-vs-android-targets.md`。

## 5. 构建任务（79 → 40）

| 功能 | Android | HarmonyOS |
|---|---|---|
| 资源/清单 | `Aapt2`（外部）、`GenerateResourceDesigner`、`ManifestMerger`、`MergeRemapXml` | `GenerateHmosResourceDesigner`、`MergeHmosPermissions`、`StageHmosResources` |
| 打包 | `BuildApkSet`、`CreateAar`、`AndroidZipAlign`、`CheckDuplicateJavaLibraries` | `AssembleHmosHap`、`DiscoverHmosPackageHars`、`Resolve/ClassifyHmosHarReferences` |
| 签名 | `AndroidCreateDebugKey`、`AndroidApkSigner`、`AndroidSignPackage` | `EnsureHmosAutoSigning`、`SignHmosHap`、`ValidateHmosSigningConfiguration` + `Tasks/Sign/**`（AGC、TokenStore、KeyMaterialGenerator、SignOrchestrator 等 20 个） |
| Java | `JavaCompileToolTask`、`Javac`、`JavaSourceUtils`、`D8`、`R8`、`GenerateProguardConfiguration`、`MavenDownload`、`ExtractJarsFromAar` | **全部移除** |
| 设备 | `GetAvailableAndroidDevices`、`InstallApkSet`、`BootAndroidEmulator`、`GetAndroidActivityName` | `GetHmosDevices`、`InstallHmosHap`、`StartHmosAbility`、`CaptureHmosLifecycleLog` |
| 工具链 | `ResolveAndroidTooling`、`ResolveSdksTask`、`RuntimeIdentifierToAbi` | `ResolveHmosToolchainSdk`、`ValidateHmosToolchain`、`ResolveHmosNativeProject/Libraries`、`ResolveHmosMonoRuntimePack` |
| Gradle | （无；Gradle 由外部） | **`Prepare/Build/CleanHarmonyOSHvigorProject`、`AlignHmosProjectSdkVersions`** |
| 运行时配置 | `GenerateRuntimeConfig`（部分在 targets） | `GenerateHmosDotNetConfig`、`GenerateHmosStartupProfile`、`CollectHmosStartupTasks`、`ValidateHmosStartupGraph` |
| 校验 | `VerifyApk` 类逻辑 | `ValidateHmosHapContents`、`VerifyHmosHap`、`InspectHarmonyOSArtifacts` |
| 桥接/VS | — | `GenerateHmosBridgeRegistry`、`WriteHmosPublishManifest`、`WriteHmosVisualStudioProjectInfo`、`WriteHmosTestModuleManifest` |

辅助代码量：Android `Utilities` 39 文件 + `Linker` 28 文件；HMOS `Utilities` 11 文件，**Linker 移除**（改用 ILLink pack）。

## 6. 托管 API：Java 绑定 → P/Invoke 绑定

| 项 | Android | HarmonyOS |
|---|---|---|
| 文件 | `Mono.Android` 414，`Android.*` 命名空间（`Android.App`、`Android.Bluetooth`、`Android.Net.Wifi`、`Android.Graphics`…） | `Microsoft.HarmonyOS` 101，仅 5 个顶层：`AppModel`、`Bluetooth`、`Native`、`Net`、`Runtime` |
| Native | 由 `generator`/`Java.Interop` 生成 JNI 绑定（138+79 文件） | **手写 P/Invoke**，20 个 NDK 目录共 **45 个文件**：`arkui`、`ace`、`IPC_Kit`、`UDMF`、`pasteboard`、`pixelmap`、`native_window`、`native_vsync`、`bluetooth`、`wifi`、`HiLog`、`ICU`、`ffrt`、`time_service`、`deviceinfo`、`display_manager`、`input_method`、`Core_File_Kit`、`NodeApi`、`libc` |
| Ref pack | `Microsoft.Android.Ref.37`（生成） | `Microsoft.HarmonyOS.Ref.23`（仅 csproj，打包时生成） |
| 应用模型 | `Android.App.Activity` 等 | `HarmonyAbility`、`HarmonyAbilityDispatcher`、`AbilityLifecycleChannelBridge`、`HmosUsesPermissionAttribute` |
| HTTP | `AndroidMessageHandler`（Java/OkHttp） | `HarmonyOSMessageHandler`、`HarmonyArkTsHttpBridge/Transport`、`HarmonyServerCertificateValidation`、`HarmonyDigestAuthentication` |
| 蓝牙 | `Android.Bluetooth.*` 直绑 | `HarmonyBluetoothBinding`、`HarmonyOSBle`、`HarmonyOSGattClientDevice/Server` |

## 7. 原生宿主：JNI → NAPI

| Android 文件 | HarmonyOS 对应 | 调整 |
|---|---|---|
| `native/clr/host/host.cc`、`host-jni.cc`、`host-shared.cc` | `runtime_host.cpp`、`runtime_napi.cpp`、`hosts/coreclr_host.cpp` | JNI → **Node-API**（38 处 `napi_*`） |
| `coreclr-bootstrap.cc` | `hosts/coreclr_host.cpp` + `runtime_config_blob.cpp` | 编译期 blob → 运行时 `runtimeconfig.bin` |
| （Mono 走不同路径） | `hosts/mono_host.cpp` | 新增 Mono 宿主 |
| `native/nativeaot/*`（9 文件） | `hosts/nativeaot_host.cpp` | NativeAOT 宿主 |
| `fastdev-assemblies.cc`、`assembly-store.cc`、`gc-bridge.cc` | 无；`runtime_environment.cpp`、`runtime_config_blob.cpp` | FastDev/程序集存储 → **目录扫描 + runtime config blob + environment** |
| `java-runtime/java/*.java`（16） | `load_runtime/Index.ets`、`hvigorfile.ts`、`types/*.d.ts` | Java 运行时 → **ArkTS 壳** |
| `runtime-util.cc` 等 | `include/*.h`（host contract/status/config） | 重新定义宿主契约 |
| — | `third_party/mono/include/**` | 内置 Mono 头文件 |

关键行为差异（详见 `2026-11-28-dotnet-harmonyos-vs-android-host.md`）：

- Android 用 JNI 三导出 + `JNI_OnLoad`；HMOS 用 NAPI 模块四函数 + 四个 channel C 导出。
- Android 初始化由 Java 驱动；HMOS 由 ArkTS 显式调用 `initializeRuntime`，`RuntimeController` 状态机管理生命周期。
- Android 失败即 `abort_applicationf`；HMOS 返回 `RuntimeStatus` + 错误码（1101–1313），进程可存活。
- Android 运行时配置是 84 字节头的 `coreclr_bootstrap` blob；HMOS 是 ECMA-335 压缩整数的 `runtimeconfig.bin`（4 MiB/4096 属性/1 MiB 字符串上限，拒绝重复键、尾随数据、保留键）。
- HMOS 要求平台预置 `HOME/TMPDIR/XDG_DATA_HOME/XDG_CONFIG_HOME/XDG_CACHE_HOME`；Android 自己从 `files_dir`/`cache_dir` 推导。NativeAOT 不校验这组变量。

## 8. ArkTS/Har 模块（Android 无对应）

| 模块 | 文件数 | 作用 |
|---|---:|---|
| `Microsoft.HarmonyOS.Bridge.Har` | 19 | ability 生命周期/配置桥 |
| `Microsoft.HarmonyOS.ChannelBase.Har` | 31 | 桥接基类/类型 + NAPI channel |
| `Microsoft.HarmonyOS.BridgeRegistry.Har` | 11 | 桥接注册表 |
| `Microsoft.HarmonyOS.Bluetooth.Har` | 15 | `@ohos.bluetooth` BLE/GATT |
| `Microsoft.HarmonyOS.Http.Har` | 13 | `@ohos.net.http` |
| `Microsoft.HarmonyOS.Runtime.Har` | 132 | 运行时宿主 + ArkTS 壳 + ICU |

## 9. 签名：keystore/apksigner → AGC + hap-sign-tool

| Android | HarmonyOS |
|---|---|
| `AndroidCreateDebugKey`（keytool 调试密钥） | `EnsureHmosAutoSigning` + `KeyMaterialGenerator`（`hap-sign-tool.jar generate-keypair`，ECC P-256） |
| `AndroidApkSigner`/`AndroidSignPackage`（apksigner） | `SignHmosHap` + `SignOrchestrator` + `BuildProfileWriter` |
| keystore 本地管理 | AGC OAuth（`AuthService`/`AgcClient`/`TokenStore`）+ DPAPI/Keychain/SecretService 令牌保护 |
| APK 签名 | **HAP 签名 + ELF `.codesign`** |
| 密码可明文（也支持 `env:`/`file:`） | manual 模式**只接受** `env:`/`file:` 引用 |
| `Inputs/Outputs` 增量 | JSON 增量状态（`hmos-sign-incremental-<runtime>.json`） |
| — | `MaterialValidator`、`ValidateHmosSigningConfiguration`、证书链/profile 校验 |

## 10. ICU

Android：无（系统/NDK）。HarmonyOS：`src/icu-harmonyos`（14 文件）生成 `Microsoft.NETCore.Runtime.ICU.Transport.HarmonyOS`，带 `icudt72l.dat`（OH 6.0/ICU 72.1）、`icudt74l.dat`（OH 6.1/ICU 74.2）及 `libhmicui18n.z.so`、`libhmicuuc.z.so`。

## 11. 测试

| Android | HarmonyOS |
|---|---|
| `tests` 1254 文件（NUnit/xUnit + 设备测试） | `testframework` 95 文件 + `Microsoft.HarmonyOS.TestHost`、`TestHost.Proxy`、`Testing.Protocol`、`Testing.Xunit`、`Testing.Xunit.V3` |

## 12. 模板

| Android 模板（文件数） | HarmonyOS 模板 |
|---|---|
| `android`(42)、`android-activity`(18)、`android-layout`(18)、`android-bindinglib`(23)、`androidlib`(20)、`androidtest`(21)、`android-wear`(43) | `hmos`(22)、`hmoslib`(3)、`hmoshar`(14)、`hmostest`(24)、**`hmosbridge`(56)** |

调整：去掉 wear/layout/bindinglib；新增 **Har 库模板** 和 **ArkTS 桥模板**。

## 13. 移植调整汇总（10 条）

1. **平台标识**：`android-*` → `hmos-musl-arm/arm64`，API 37 → **23**，net12 → net10。
2. **包模型**：APK/AAB → **HAP**；Gradle → **hvigor**；AAR → **Har**。
3. **宿主模型**：JNI + Java runtime → **NAPI + ArkTS 壳**，三宿主（Mono/CoreCLR/NativeAOT）。
4. **绑定方式**：Java 生成器/JNI → **手写 OHOS NDK P/Invoke**（20 个 kit）。
5. **签名**：keystore/apksigner → **AGC + hap-sign-tool.jar + ELF `.codesign`**。
6. **运行时配置**：Java runtime/assembly-store → **runtime config blob + environment + startup profile**。
7. **工具链**：Android SDK/NDK/adb → **OHOS SDK 23 + hvigor + hdc**。
8. **ICU**：系统 ICU → **自带 ICU transport pack**。
9. **NativeAOT**：新增本地 ILCompiler/ILLink pack 解析、`NativeLib=Shared`、`UseAppHost=false`、**`StaticOpenSslLinking=true`**。
10. **测试/模板**：新增设备 TestHost 栈与 Har/Bridge 模板；删除 Java/R8/ProGuard/TypeMap/FastDev 相关任务与 targets。

## 14. 三份文档的分工

| 文档 | 内容 |
|---|---|
| 本文件 | 全子系统文件/目录级对照、10 条移植调整、总体结论 |
| `2026-11-28-dotnet-harmonyos-vs-android-targets.md` | `Hap.targets` 78 个目标逐组对照；Android `BuildOrder`/`Application`/`Publish`/`TypeMap`/`Common` 的阶段映射；签名/校验/安装/发布细节；增量与风险 |
| `2026-11-28-dotnet-harmonyos-vs-android-host.md` | JNI vs NAPI 入口；初始化顺序；错误码表；runtimeconfig blob 解析差异；程序集加载；托管入口点；函数级映射；行为风险 |

## 15. 后续可选

1. **单任务内容 diff**：`AssembleHmosHap` vs Android `aapt2 + D8 + zip` 的输入输出契约；`SignHmosHap` vs `AndroidApkSigner` 的参数校验差异。
2. **Workload 安装/解析链**：`Microsoft.HarmonyOS.Sdk` 的 `WorkloadManifest.in.json`/`WorkloadDependencies.json` 与 Android 的 pack 解析、`extends` 机制对照。
3. **测试栈对照**：`Microsoft.HarmonyOS.TestHost`/`Testing.Protocol` 与 Android 设备测试（`tests` 1254 文件）的能力矩阵。
4. **上游化视角**：把 HMOS 的 NAPI 宿主、runtimeconfig 解析、签名链分别对照 dotnet/runtime 与 dotnet/android 的上游评审标准，输出“可上游/需下游维护”的清单。

> 说明：三份文档同属 2026-11-28 对照结论，已归档在 `docs/plans/`；基线版本与统计口径见文首。
