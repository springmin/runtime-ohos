# dotnet-harmonyos vs dotnet/android：HAP targets 内容级对照（2026-11-28）

> 对比对象
>
> - **HMOS**：`dotnet-harmonyos` 快照（workload `harmonyos`，pack `23.0.0-preview.2`，bundled runtime `10.0.4`，API 23，RID `hmos-musl-arm64` / `hmos-musl-arm`）。
> - **Android**：`dotnet/android` 主线快照（2026-11-28 抓取；当前主线面向 net11/net12）。
>
> 说明：Android 基线比 HMOS 快照新一个产品周期，涉及 TFM/API 级别的差异（net10 → net11/net12、API 23 → API 37）不计入“移植改动”。本文件只做**目标/任务/构建图**级别的内容对照，不逐行 diff 版本相关代码。
>
> 本文件与配套的 `*-host.md`、`*-compare.md` 一并归档在 `docs/plans/`。

## 1. 对照文件与规模

| 文件 | 行数 | Target 数 | 作用 |
|---|---:|---:|---|
| HMOS `Microsoft.HarmonyOS.Sdk/targets/Microsoft.HarmonyOS.Hap.targets` | **1778** | **78** | HAP 构建、 staging、打包、签名、校验、安装、运行、publish |
| HMOS `Microsoft.HarmonyOS.Sdk/targets/Microsoft.HarmonyOS.RuntimeApp.targets` | 172 | 11 | runtime SDK（`Microsoft.NET.Sdk` 可执行项目）的 HAP 生命周期外壳 |
| HMOS `Microsoft.HarmonyOS.Sdk/targets/Microsoft.HarmonyOS.Sdk.Bindings.Hvigor.targets` | 525 | 19 | Har/Hvigor 工程构建与 Har 引用 |
| Android `src/Xamarin.Android.Build.Tasks/Xamarin.Android.Common.targets` | **2895** | 大量 | APK/AAB 主流水线（`_CreateBaseApk`、`_CompileDex`、`_CopyPackage`、`_Sign`…） |
| Android `Microsoft.Android.Sdk/targets/Microsoft.Android.Sdk.BuildOrder.targets` | 244 | 1（`HarmonyOSPrepareForBuild` 的对应物是纯属性） | `BuildDependsOn` / `SignAndroidPackageDependsOn` / `DeployToDeviceDependsOnTargets` 组合 |
| Android `.../Microsoft.Android.Sdk.Application.targets` | 179 | 6 | `Run`、设备发现、启动 Activity、adb 参数 |
| Android `.../Microsoft.Android.Sdk.Publish.targets` | 60 | 3 | `Publish` 与 `ApplicationArtifact` → `ResolvedFileToPublish` |
| Android `.../Microsoft.Android.Sdk.TypeMap.Trimmable.targets` | 608 | 16 | Trimmable type map、Java stubs、`RegisterAttribute` 处理 |
| Android `.../Microsoft.Android.Sdk.CoreCLR.targets` | 120 | 3 | 本地 runtime pack、Mibc |
| Android `.../Microsoft.Android.Sdk.NativeAOT.targets` | 377 | 13 | JNI bootstrap、type map、R8、`.so` 命名 |

结论先行：**Android 是一条“SDK/NDK → aapt2 → Java/javac → D8 → zip → zipalign → apksigner”的外置工具链流水线；HMOS 是一条“managed publish 子图 → 文件 staging → hvigor 打包 → hap-sign-tool 签名 → hdc 部署”的内嵌流水线。** 两者不是 1:1 target 映射，只有阶段级对应。

## 2. 构建图入口

### 2.1 Android

`BuildOrder.targets` 不定义真正的工作目标，只用属性把 Android 的阶段挂到标准 SDK 目标上：

```xml
<_AndroidBuildDependsOn>
  _ValidateLinkMode; _CheckNonIdealConfigurations; _SetupMSBuildAllProjects;
  _SetupDesignTimeBuildForBuild; AndroidPrepareForBuild; _BuildAndroidGradleProjects;
  _CategorizeAndroidLibraries; _CreatePropertiesCache; _CleanIntermediateIfNeeded;
  _CheckProjectItems; _CheckForContent; _CheckForObsoleteFrameworkAssemblies;
  _ValidateAndroidPackageProperties; AddLibraryJarsToBind;
  _CollectJavaSourceForBinding; _CompileBindingJava;
  ...
</_AndroidBuildDependsOn>

<_PrepareBuildApkDependsOnTargets>
  _SetLatestTargetFrameworkVersion; _GetLibraryImports; _RemoveRegisterAttribute;
  _ResolveAssemblies; _ResolveSatellitePaths; _CreatePackageWorkspace;
  _LinkAssemblies; _GenerateJavaStubs; _ManifestMerger; _ConvertCustomView;
  $(_AfterConvertCustomView); $(AfterGenerateAndroidManifest); _ReadAndroidManifest;
  _CompileJava; _CompileDex; $(_AfterCompileDex); _CreateBaseApk;
  _PrepareAssemblies; _ResolveSatellitePaths; _CheckApkPerAbiFlag;
  _IncludeNativeSystemLibraries; _AndroidGenerateCoreClrBootstrap;
  _CheckGoogleSdkRequirements; BuildAndroidAssetPacks;
</_PrepareBuildApkDependsOnTargets>

<SignAndroidPackageDependsOn>
  Build; Package; _Sign; _CreateUniversalApkFromBundle; _CollectApplicationArtifacts
</SignAndroidPackageDependsOn>

<DeployToDeviceDependsOnTargets>
  $(_MinimalSignAndroidPackageDependsOn); _GenerateEnvironmentFiles;
  _EnsureDeviceBooted; _Upload; _AndroidConfigureAdbReverse
</DeployToDeviceDependsOnTargets>
```

特征：

1. **构建与签名分离**：`dotnet build` 只到 `Build`；`SignAndroidPackage` 才追加 `_Sign`。
2. **部署是第三段**：`Install` → `_DeployApk`/`_DeployAppBundle`，`Run` 再通过 `Microsoft.Android.Run.dll` 启动。
3. **APK 打包内部有 23 步依赖链**，大部分是 Java/资源/Manifest 工具。
4. `Publish` 是独立目标（`Publish.targets`），把 `ApplicationArtifact` 转成 `ResolvedFileToPublish`。

### 2.2 HarmonyOS

HMOS 用两条 AfterTargets 钩子把 HAP 挂到标准 `Build` 之后：

```xml
<Target Name="_HmosBuildHapOnBuild"
        AfterTargets="Build"
        DependsOnTargets="_PrepareHmosManagedClosure;HmosBuildHap;HmosWritePublishManifest"
        Condition="'$(_HmosBuildOutputsHap)' == 'true'" />

<Target Name="_HmosStageHapProjectOnBuild"
        AfterTargets="Build"
        DependsOnTargets="_PrepareHmosManagedClosure;HmosStageDeveloperHapProject"
        Condition="'$(_HmosBuildStagesPayload)' == 'true' and '$(_HmosBuildOutputsHap)' != 'true'" />
```

三个开关决定行为：

| 属性 | 含义 |
|---|---|
| `HarmonyOSBuildOutputHap`（默认 `true`） | Build 是否产出 HAP |
| `HarmonyOSSkipHapOnBuild`（默认 `false`） | 只 staging，不产 HAP |
| `_HmosBuildStagesPayload` | 有 RID、非 design-time、且 `HarmonyOSBuildOutputHap=true` |
| `_HmosBuildOutputsHap` | `_HmosBuildStagesPayload` 且未 skip |

`HmosBuildHapDependsOn`（20 项）就是 HAP 的完整主链：

```xml
_HmosResolveHapProperties; _HmosPrepareGeneratedArtifactsRoot;
_HmosResolveNativeProject; HmosValidateBuildToolchain;
_PrepareHmosHarReferences; BeforeHmosBuildHap;
HmosValidateRuntimeHar; HmosValidateBridgeHarAssets; HmosResolveHarReferences;
HmosResolveNativeLibraries; HmosResolveRuntimeConfig;
HmosStageManagedAssemblies; HmosStageResources;
HmosCollectStartupTasks; HmosGenerateDotNetConfig; HmosGenerateStartupProfile;
HmosMergePermissions; _HmosValidateHapInputs;
AssembleHmosHap; AfterHmosBuildHap
```

`HmosStageHapProjectDependsOn` 是同一列表去掉 `Before/AfterHmosBuildHap` 和 `AssembleHmosHap`，保留全部 staging。

`_PrepareHmosManagedClosureDependsOn` 把 publish 文件列表子图搬进 Build：

```xml
ResolveReferences;
ComputeResolvedFilesToPublishList;
ILLink;
_HmosRunRuntimePublishGraph;      <!-- NativeAOT: IlcCompile; CoreCLR: CreateReadyToRunImages -->
GeneratePublishDependencyFile;
_HmosMaterializeManagedClosure;
_HmosRunPostClosureRuntimeGraph   <!-- Mono AOT: $(HmosBuildDependsOn) -->
```

**关键差异**：HMOS 明确注明“`Target=Publish` is never invoked”，构建期直接执行 publish 的**文件列表子图**；Android 的 Build 不包含 publish。

`HmosPublishHapDependsOn` 只有 3 项：

```xml
_HmosGuardPublishHapRequiresHapAssembly;
Build;
HmosWritePublishManifest
```

即 **Build 已经产出 HAP，Publish 只做复制**（`_HmosCopyHapOutputsToPublishDirectory`，AfterTargets=`Publish`）。

## 3. 阶段级 target 映射

| 阶段 | Android | HarmonyOS | 说明 |
|---|---|---|---|
| 构建入口 | `Build` + `_AndroidBuildDependsOn` | `Build` + `_HmosBuildHapOnBuild` | HMOS 用 AfterTargets，而不是重写 `BuildDependsOn` |
| 程序集闭包 | `_ResolveAssemblies`、`_LinkAssemblies`、`_PrepareAssemblies`、`_RemoveRegisterAttribute` | `_PrepareHmosManagedClosure`（7 步）、`_HmosMaterializeManagedClosure` | HMOS 在 Build 内跑 `ComputeResolvedFilesToPublishList` + `ILLink` |
| NativeAOT 编译 | `_AndroidComputeIlcCompileInputs`…（13 个 target） | `_HmosRunRuntimePublishGraph` → `CallTarget IlcCompile` | HMOS 复用上游 ILC，只做 pack/RID 注入 |
| CoreCLR R2R | `_AndroidGenerateMibcProfile` 等 | `CallTarget CreateReadyToRunImages` | HMOS 不生成 Mibc |
| Mono AOT | 无（Android 用 Mono JIT/AOT 的旧链） | `_HmosRunPostClosureRuntimeGraph` → `$(HmosBuildDependsOn)` | HMOS 的 sidecar `.dll.so` |
| Java stubs / type map | `_GenerateJavaStubs`、`_GenerateTrimmableTypeMap`、`_RemoveRegisterAttribute` | **无** | ArkTS/NAPI 不需要 Java 桩 |
| 资源 | `_UpdateAndroidResgen`、`_BuildResourceDesigner`、`_CreateBaseApk`（aapt2） | `_GenerateHarmonyOSResourceDesigner`、`HmosStageResources` | 整数 ID → 字符串 ID |
| Manifest | `_ManifestMerger`、`_ConvertCustomView`、`_ReadAndroidManifest` | `HmosMergePermissions` | 权限合并 + 原生 `module.json5` |
| Java 编译 / Dex | `_CompileJava`、`_CompileDex`、`D8`、R8/ProGuard | **无** | 由 hvigor/ArkTS 工具链取代 |
| 打包 | `_CreateBaseApk`、`_CompileDex`、`_CopyPackage`、`_CreateAar` | `AssembleHmosHap` | ZIP 布局与工具不同 |
| 签名 | `_ResolveAndroidSigningKey`、`_PrepareForSign`、`_Sign`、`_CreateAndroidDebugSigningKey` | `HmosValidateManualSigning`、`EnsureHmosAutoSigning`、`SignHmosHap` | keystore → AGC + hap-sign-tool |
| 校验 | `AndroidApkSigner` 内部 sign+verify | `HmosValidateHapContents`、`HmosVerifyHap` | HMOS 有独立白/黑名单与证书链校验 |
| 安装 | `Install`、`_DeployApk`、`_DeployAppBundle`、`InstallApkSet` | `HmosInstallHap` | adb → hdc |
| 启动 | `Run`（`Microsoft.Android.Run.dll`） | `HmosStartHap`、`HmosRunHap` | HMOS 有 lifecycle log 目标 |
| 设备发现 | `ComputeAvailableDevices` | `HmosGetDevices` | adb devices → hdc list targets（JSON 契约） |
| Publish | `Publish` → `_CalculateAndroidFilesToPublish` → `CopyFilesToPublishDirectory` | `_HmosCopyHapOutputsToPublishDirectory` | HMOS 不重新打包/签名 |
| 增量 | target `Inputs/Outputs`（如 `_Sign`） | JSON incremental state + `UpToDateCheckInput/Built` | 机制不同 |
| 清理 | `_CleanMonoAndroidIntermediateDir` 等 | `HmosCleanGeneratedArtifacts` | 清理 staging 所有权清单 |

## 4. 关键阶段细节

### 4.1 属性与默认值：`_HmosResolveHapProperties`（867–976）

这是 HMOS 所有 HAP 目标共用的“属性计算中心”，没有 `DependsOnTargets`，只做纯属性/校验。

**签名模式**：

```xml
<HarmonyOSSigningMode Condition="... == '' and ...RequireSignedHap == 'true'">manual</HarmonyOSSigningMode>
<!-- 有 material 属性但没有显式 mode 时推断 manual，并给出弃用警告 -->
<HarmonyOSSigningMode Condition="'$(HarmonyOSSigningMode)' == '' and '$(_HmosSigningMaterialPropertySpecified)' == 'true'">manual</HarmonyOSSigningMode>
<HarmonyOSSigningMode Condition="'$(HarmonyOSSigningMode)' == ''">none</HarmonyOSSigningMode>
<HarmonyOSSigningMode>$([System.String]::Copy('$(HarmonyOSSigningMode)').ToLowerInvariant())</HarmonyOSSigningMode>
```

- 取值只能是 `none|manual|auto`。
- `HarmonyOSSigningMode=none` 时，若仍残留 `HarmonyOSSigningCert/KeyStore/Profile/KeyAlias/StorePass/KeyPass`，**直接报错**（967–974）。
- `auto` 在 Full MSBuild 下**不支持**（962）：安全下载与 AES-GCM material 路径依赖 Core MSBuild。
- `manual` 且**完全未提供** material 属性（Cert/KeyStore/Profile/KeyAlias 都为空）时，回退到原生工程 `build-profile.json5` 的 `signingConfigs`（`HmosValidateManualSigning` 1151–1154）。只要提供其中任意一个，`KeyAlias` 就必须非空（否则报错）；已提供的文件会逐一做 `Exists` 校验。

**产物命名与路径**：

| 属性 | 默认 |
|---|---|
| `HarmonyOSHapNativeLibraryName` | `$(TargetName).so` |
| `HarmonyOSHapNativeEntryPoint` | `Run` |
| `HarmonyOSHapBuildTimeoutSeconds` | 240 |
| `HarmonyOSHvigorIncremental/Daemon/Parallel` | true |
| `HarmonyOSHvigorBuildMode` | Release→`release`，否则 `debug` |
| `HarmonyOSHapSignedOutput` | `$(OutputPath)$(MSBuildProjectName).signed.hap` |
| `HarmonyOSHapUnsignedOutput` | `$(OutputPath)$(MSBuildProjectName)-unsigned.hap` |
| `HarmonyOSHapOutput` | 有签名→signed，否则 unsigned |
| `HarmonyOSPublishManifestPath` | `$(OutputPath)publish-manifest.json` |
| `_HmosContentsManifestPath` | `$(OutputPath)<runtime>-contents.txt` |
| `HarmonyOSIncludeDebugFiles` | Debug=true，否则 false |

**Hvigor 只产 unsigned HAP**：

```xml
<_HmosHvigorRequireSignedHap>false</_HmosHvigorRequireSignedHap>
<_HmosAssembledHapOutput Condition="'$(_HmosSigningRequired)' == 'true'">$(_HmosResolvedHapUnsignedOutput)</_HmosAssembledHapOutput>
```

签名统一由 `SignHmosHap` 负责，避免 hvigor 和 hap-sign-tool 双重签名。

### 4.2 managed 闭包与 staging：469–544、1631–1666

`HmosStageManagedAssemblies` 的数据来源有三层：

1. `@(ResolvedFileToPublish)` 中的 `.dll` / `.config`（Debug 再加 `.pdb` / `.xml`）。
2. 当上面的列表**没有任何 `.dll`** 时，回退扫描 `$(_HmosPublishDir)**/*.dll`（直接调用 `HmosBuildHap` 的路径）。
3. `Microsoft.HarmonyOS.dll` 平台程序集兜底：仅当 publish 闭包里完全没有同名文件时加入，避免 ReadyToRun 产物被 SDK IL 覆盖。

落盘位置：`<module>/src/main/resources/rawfile/assemblies/`，并写 `.hmos-staged/managed-assemblies.json` 所有权清单。NativeAOT 模式 `RemoveAllOwnedFiles=true`，会撤回之前 staged 的 IL。

`HmosResolveRuntimeConfig` / `HmosGenerateRuntimeConfig`：

- `RuntimeConfigParserTask` 来自 `Microsoft.NET.Runtime.MonoTargets.Sdk`，把 `runtimeconfig.json` 转成 **`runtimeconfig.bin`**。
- 保留属性只有 `RUNTIME_IDENTIFIER`、`APP_CONTEXT_BASE_DIRECTORY`；不允许 runtimeconfig 覆盖宿主属性。
- NativeAOT 完全跳过该目标（`_HarmonyOSRuntime != 'NativeAOT'`）。
- 若 `runtimeconfig.bin` 已存在则不重生成（条件在 Target 上）。

对照 Android：Android 的 runtime 配置不是运行时读文件，而是构建期把 `coreclr_bootstrap` 二进制块编进应用（见 host 文档第 5 节）。

### 4.3 资源、权限、启动配置

| 目标 | 行为 |
|---|---|
| `_GenerateHarmonyOSResourceDesigner`（688） | 扫描 `resources/base/element/*.json`（string/color/float/integer/boolean/pattern）与 `media/*`，生成字符串常量：`app.string.xxx`、`app.color.xxx`、`app.media.xxx`。`BeforeTargets=CoreCompile`。 |
| `HmosStageResources`（551） | 把 `@(HarmonyOSResource)` / `@(HarmonyOSRawfile)` 复制进原生工程；与原生文件冲突即报错（native 权威）；清单 `.hmos-staged/staged-resources.json`。 |
| `HmosGenerateDotNetConfig`（576） | 生成 `DotNetHapConfig.ets` 到 `<module>/src/main/ets/generated/`，把 native library/entry point/env/runtime 从 MSBuild 传给 ArkTS。 |
| `HmosCollectStartupTasks`（599） | 读取每个 staged HAR 的 `startup_config.json`，合并 `@(HarmonyOSStartupTask)`，交给 `ValidateHmosStartupGraph` 排序并检测环。 |
| `HmosGenerateStartupProfile`（621） | 生成 HAP 根 `startup_config.json`、根 task `.ets`、config entry `.ets`、关闭注册表，并 patch `module.json5` 的 `appStartup`。空图只撤回未变化的 SDK-owned 文件。 |
| `HmosMergePermissions`（648） | 合并三类来源：① 每个 HAR 的**生效 manifest**（`package/src/main/module.json`）；② 托管 IL 的 `[assembly: HmosUsesPermission]`；③ `@(HarmonyOSPermission)` + SDK 必需权限（Mono 调试器需要 `ohos.permission.INTERNET`）。原生条目永远优先，SDK 追加项写入 `merged-permissions.json` 以便 NativeAOT 切换时撤回。 |

对照 Android：

- `_GenerateHarmonyOSResourceDesigner` ↔ `_BuildResourceDesigner` / `GenerateResourceDesigner`（R.txt + Java 平台 jar + CodeDom）。
- `HmosMergePermissions` ↔ `_ManifestMerger` + `_ConvertCustomView` + `_ReadAndroidManifest` 的组合。
- HMOS **没有** Java stubs / type map / `RegisterAttribute` 处理；对应能力由 ArkTS 桥 + 生成入口点承担。

### 4.4 打包：`AssembleHmosHap`（1273–1312）

```xml
<AssembleHmosHap
    NativeProjectDir="$(...)" ModuleDirectory="$(HmosHvigorModuleDirectory)"
    NodePath="$(...)" HvigorPath="$(...)" HvigorBuildDir="$(HarmonyOSHapBuildDir)."
    IncrementalStatePath="$(_HmosHapIncrementalStatePath)"
    Runtime="$(...)" HarmonyOSApiLevel="$(HarmonyOSApiLevel)"
    HapOutput="$(_HmosAssembledHapOutput)" RequireSignedHap="false"
    ProductName="$(HmosHvigorProduct)" ModuleName="$(HmosHvigorModule)"
    BuildMode="$(HarmonyOSHvigorBuildMode)" ... />
<Error Condition="!Exists('$(_HmosAssembledHapOutput)')" Text="HarmonyOS HAP was not produced..." />
```

前置校验 `_HmosValidateHapInputs`（1256）：

- RID 必须是 `hmos-musl-arm64` 或 `hmos-musl-arm`。
- `HarmonyOSAbi` 必须与 RID 匹配（arm64→`arm64-v8a`，arm→`armeabi-v7a`），否则 HAP 的 `abiFilters` 会与 `.so` 不符，设备上 `dlopen` 失败。
- NativeAOT 必须有 `HarmonyOSHapNativeLibraryPath`。
- CoreCLR 必须有 `libcoreclr.so` / `libclrjit.so` / `libclrgc.so`。
- Mono 必须有 `libmonosgen-2.0.so`。

打包后立即由 `HmosValidateHapContents`（1319，AfterTargets=`AssembleHmosHap`）做**按 runtime 的白/黑名单**校验，并写 `<runtime>-contents.txt`；校验参数包含 `RunAOTCompilation`、`UseInterpreter`、`PublishReadyToRun`、`RuntimeComponents`。

对照 Android：`AssembleHmosHap` 同时承担 `_CreateBaseApk` + `_CompileDex` + `_CopyPackage` 的角色，但工具是 hvigor，输入是已经 staged 的目录，不是 MSBuild item 流。

### 4.5 签名：`SignHmosHap`（1357–1389）

```xml
<Target Name="SignHmosHap"
        AfterTargets="AssembleHmosHap;HmosValidateHapContents"
        Condition="... and '$(HarmonyOSSigningMode)' != 'none'">
  <Error Condition="'$(_HmosAssembledHapOutput)' == '$(_HmosResolvedHapOutput)'"
         Text="HarmonyOSHapOutput must differ from the unsigned HAP staging path..." />
  <SignHmosHap
      JavaPath="$(_HmosSigningJavaPath)"
      HapSignTool="$(_HmosHapSignToolJar)"
      InputHapPath="$(_HmosAssembledHapOutput)"
      UseAutoMaterials="$(_HmosSignUseAutoMaterials)"
      OutputHapPath="$(_HmosResolvedHapOutput)"
      AppCertFile="$(HarmonyOSSigningCert)"
      KeystoreFile="$(HarmonyOSSigningKeyStore)"
      ProfileFile="$(HarmonyOSSigningProfile)"
      KeyAlias="$(HarmonyOSSigningKeyAlias)"
      StorePasswordReference="$(HarmonyOSSigningStorePass)"
      KeyPasswordReference="$(HarmonyOSSigningKeyPass)"
      SignAlg="SHA256withECDSA" ... />
</Target>
```

- 手工模式：密码只接受 `file:` / `env:` 引用；`AppCertFile/KeystoreFile/ProfileFile/KeyAlias` 必须成套提供。
- 自动模式：`EnsureHmosAutoSigning` 在 `SignHmosHap` 之前运行（BeforeTargets），产出 P12/CSR/证书/Profile，并写 SDK 状态文件；`SignHmosHap` 从状态文件读取。
- 签名增量状态：`hmos-sign-incremental-<runtime>.json`。
- unsigned HAP 保留，便于增量复用与审计。

对照 Android `_Sign`（Common.targets:2379）：

```xml
<Target Name="_Sign" Inputs="$(_SignInputs)" Outputs="$(_SignOutputs)"
        DependsOnTargets="_PrepareForSign;_ResolveAndroidSigningKey">
  <AndroidSignPackage .../>            <!-- jarsigner 路径 -->
  <AndroidZipAlign .../>               <!-- apksigner 路径：先 zipalign -->
  <AndroidApkSigner .../>              <!-- apksigner -->
</Target>
```

差异：

| 项 | Android | HarmonyOS |
|---|---|---|
| 密钥 | 本地 keystore（调试密钥由 `_CreateAndroidDebugSigningKey` 生成） | P12 + CSR + AGC OAuth，或原生工程 `signingConfigs` |
| 签名工具 | `jarsigner` / `apksigner` | `hap-sign-tool.jar sign-app` |
| 对齐 | `zipalign` | HAP 无独立对齐步骤 |
| 算法 | 可配置（`AndroidApkSigningAlgorithm` / Digest） | 固定 `SHA256withECDSA` |
| 密码 | 可明文，也支持 `env:`/`file:` | 只允许 `env:`/`file:`（manual） |
| 额外产物 | 无 | ELF `.codesign`、证书链、profile |
| 增量 | `Inputs/Outputs` | JSON 状态 + `FileWrites` |

### 4.6 验证、安装、启动、publish

| HMOS 目标 | 行 | 行为 |
|---|---:|---|
| `HmosVerifyHap` | 1445 | 要求签名模式非 `none`；调用 `VerifyHmosHap` 校验 HAP 签名，输出证书链与 profile 到 `verify/` |
| `_HmosVerifyHapBeforeInstall` | 1472 | 仅在 `HarmonyOSSigningMode != none` 时把 verify 挂到 install 前 |
| `HmosInstallHap` | 1476 | `hdc install -r`；安装前把 HAP 暂存到 hdc 可读目录；解析 `install bundle successfully` / `failed to install bundle` / `verify signature failed` |
| `HmosStartHap` | 1490 | `StartHmosAbility`，传 package/ability/module/device/debug mode/mono debugger options；可清 hilog |
| `HmosCaptureLifecycleLog` | 1508 | 采集 hilog，要求出现 `DOTNET_HMOS_UIABILITY_ONCREATE`、`ONWINDOWSTAGECREATE`、`ONFOREGROUND` |
| `HmosRunHap` | 1527 | `HmosPublishHap;HmosInstallHap;HmosStartHap;HmosCaptureLifecycleLog` |
| `_HmosCopyHapOutputsToPublishDirectory` | 1708 | AfterTargets=`Publish`，只复制 signed/unsigned HAP、publish manifest、contents manifest；不重打包、不重签名 |

`_HmosValidateNoBuildPublishInputs`（1688）为 `dotnet publish --no-build` 提供输入/输出新鲜度校验：`Inputs` 包含项目文件、`@(Compile)`、`@(EmbeddedResource)`、`@(ProjectReference)`、`@(HarmonyOSResource/Rawfile/Library)` 与原生工程输入；`Outputs` 是 HAP + publish manifest + contents manifest。缺失或过期直接报错，提示先 `dotnet build -r <rid>`。

对照 Android：`Publish` 在 `Publish.targets` 中把 `ApplicationArtifact` 重新填进 `ResolvedFileToPublish`，由标准 `CopyFilesToPublishDirectory` 复制；HMOS 则保留标准 `ResolvedFileToPublish`，在 Publish 之后额外 Copy。

## 5. 增量与清理

HMOS 的增量机制分三层：

1. **target 级**：`_Sign` 式 `Inputs/Outputs` 在 HMOS 中只用于 `_HmosValidateNoBuildPublishInputsCore` 和 Hvigor 工程构建（`_BuildHarmonyOSHvigorProjects`）。
2. **状态文件级**：`hmos-hap-incremental-<runtime>.json`、`hmos-sign-incremental-<runtime>.json`、`.hmos-staged/*.json` 所有权清单。
3. **IDE 级**：`_HmosCollectUpToDateCheckItems` 把原生工程输入加入 `UpToDateCheckInput`，把 HAP/manifest 加入 `UpToDateCheckBuilt`，供 CPS Fast Up-to-Date 使用。

`HmosCleanGeneratedArtifacts`（1565，AfterTargets=`Clean`）：

- 只解析 metadata，不跑 staging/toolchain/hvigor，因此原生工程被删掉也能 clean。
- 清理 `HarmonyOSIntermediateRoot`、signed/unsigned HAP、publish manifest、contents manifest、lifecycle log。
- `CleanHmosGeneratedArtifacts` 接收 native project/module/ABI，用所有权清单撤回 SDK-owned 文件。

对照 Android：`CleanDependsOn` 里是 `_CleanMonoAndroidIntermediateDir`、`_CleanAndroidBuildPropertiesCache`、`_CleanAarCache`、`CleanBindingsOutput`、`CleanLibraryProjectIntermediaries`、`CleanNativeLibraryIntermediaries`、`_CleanAndroidGradleProjects`。

## 6. Hap.targets 78 个目标全量清单

> 行号来自 HMOS 快照。分组按职责，不按文件顺序。

### 6.1 编排（9）

| 目标 | 行 | 说明 |
|---|---:|---|
| `BeforeHmosBuildHap` | 258 | 空扩展点 |
| `AfterHmosBuildHap` | 259 | 空扩展点 |
| `_HmosBuildHapOnBuild` | 264 | Build 后钩子：闭包 + HAP + manifest |
| `_HmosStageHapProjectOnBuild` | 271 | skip 模式：只 staging |
| `HmosStageDeveloperHapProject` | 1609 | 只 staging 的公开目标 |
| `HmosBuildHap` | 1746 | 主目标 |
| `HmosPublishHap` | 1751 | Build + manifest |
| `HmosPrepareDebugHap` | 1756 | Publish 后返回 HAP |
| `HmosLaunchDebugHap` | 1769 | install + start |

### 6.2 解析与校验（29）

| 目标 | 行 |
|---|---:|
| `HmosValidateRuntimeHar` | 276 |
| `_HmosResolveNativeProject` | 284 |
| `HmosResolveHmosMonoRuntimePack` | 308 |
| `HmosResolveHarReferences` | 329 |
| `HmosValidateBridgeHarAssets` | 360 |
| `HmosRemoveStaleMonoAotSidecars` | 372 |
| `HmosResolveNativeLibraries` | 382 |
| `HmosResolveRuntimeConfig` | 431 |
| `HmosGenerateRuntimeConfig` | 442 |
| `_HmosResolveHapProperties` | 867 |
| `_HmosCollectNativeProjectInputs` | 981 |
| `_HmosCollectUpToDateCheckItems` | 990 |
| `_HmosExcludeHapProjectFromManagedAssemblyResolution` | 1001 |
| `_HmosPrepareGeneratedArtifactsRoot` | 1020 |
| `HmosValidateBuildToolchain` | 1030 |
| `HmosValidateSigningToolchain` | 1049 |
| `HmosValidateDeviceToolchain` | 1060 |
| `HmosValidateToolchain` | 1070 |
| `_HmosResolveToolchainSdk` | 1081 |
| `HmosAlignNativeProjectSdkVersions` | 1099 |
| `HmosValidateManualSigning` | 1132 |
| `_HmosEnsureAutoSigningCore` | 1157 |
| `EnsureHmosAutoSigning` | 1184 |
| `HmosSignIn` | 1189 |
| `HmosSignOut` | 1201 |
| `HmosSignStatus` | 1213 |
| `HmosSignTeams` | 1228 |
| `HmosSignSelfTest` | 1240 |
| `HmosAutoSign` | 1252 |

### 6.3 staging（7）

| 目标 | 行 |
|---|---:|
| `HmosStageManagedAssemblies` | 469 |
| `HmosStageResources` | 551 |
| `HmosGenerateDotNetConfig` | 576 |
| `HmosCollectStartupTasks` | 599 |
| `HmosGenerateStartupProfile` | 621 |
| `HmosMergePermissions` | 648 |
| `_GenerateHarmonyOSResourceDesigner` | 688 |

### 6.4 runtime pack 注入（7）

| 目标 | 行 |
|---|---:|
| `_HmosUseLocalNativeAotRuntimePack` | 705 |
| `_HmosUseLocalCoreClrRuntimePack` | 733 |
| `_HmosUseLocalMonoRuntimePack` | 756 |
| `_HmosResolveLocalILCompilerPack` | 786 |
| `_HmosConfigureNativeAotRuntimePack` | 808 |
| `_HmosPopulateNativeAotRuntimePackAssemblies` | 828 |
| `_HmosDeduplicateUnmanagedEntryPointsAssemblies` | 856 |

### 6.5 打包、签名、校验（8）

| 目标 | 行 |
|---|---:|
| `_HmosValidateHapInputs` | 1256 |
| `AssembleHmosHap` | 1273 |
| `HmosValidateHapContents` | 1319 |
| `SignHmosHap` | 1357 |
| `CoreHmosBuildHap` | 1391 |
| `HmosWritePublishManifest` | 1396 |
| `_HmosBuildHapBeforeVerify` | 1441 |
| `HmosVerifyHap` | 1445 |

### 6.6 设备与 IDE（8）

| 目标 | 行 |
|---|---:|
| `_HmosVerifyHapBeforeInstall` | 1472 |
| `HmosInstallHap` | 1476 |
| `HmosStartHap` | 1490 |
| `HmosCaptureLifecycleLog` | 1508 |
| `HmosRunHap` | 1527 |
| `HmosGetProjectInfo` | 1533 |
| `HmosGetDevices` | 1555 |
| `HmosCleanGeneratedArtifacts` | 1565 |

### 6.7 闭包与 publish（10）

| 目标 | 行 |
|---|---:|
| `_PrepareHmosManagedClosure` | 1631 |
| `_HmosRunRuntimePublishGraph` | 1639 |
| `_HmosRunPostClosureRuntimeGraph` | 1652 |
| `_HmosMaterializeManagedClosure` | 1660 |
| `_HmosHintRidRequiredForHap` | 1669 |
| `_HmosValidateNoBuildPublishInputs` | 1688 |
| `_HmosValidateNoBuildPublishInputsCore` | 1693 |
| `_HmosCopyHapOutputsToPublishDirectory` | 1708 |
| `_HmosGuardPublishHapRequiresHapAssembly` | 1741 |
| `_HmosEnableDebugLaunch` | 1762 |

> 注：分组计数含少量跨组复用（如 `HmosValidateManualSigning` 在签名和校验中都出现），合计仍为 78 个 Target 定义。

## 7. 观察与风险

1. **Build 会写 `PublishDir`**。`_HmosMaterializeManagedClosure` 在 Build 内把 `ResolvedFileToPublish` 复制到 `$(_HmosPublishDir)`，注释也承认这是为了 staging 消费。副作用是普通 `dotnet build` 也会填充 publish 目录，与标准 SDK 语义不同；增量/清理要依赖 ownership manifest 才能不留下脏文件。
2. **`HmosPublishHap` 等 4 个目标在 Hap.targets 与 RuntimeApp.targets 中重名**。`Sdk/Sdk.targets` 用 `_HmosImportRuntimeApp` 二选一导入，正常不会同项目冲突；但该标志必须准确，否则 MSBuild 会出现“后定义覆盖先定义”的隐式行为。
3. **签名模式依赖执行期条件**。`HmosVerifyHap` 的注释明确说明：`HarmonyOSSigningMode` 在 `_HmosResolveHapProperties` 执行时才解析，因此不能用 `DependsOnTargets` 的求值期条件，必须用 Target 条件。这类“属性在 target 里才成立”的模式在 Hap.targets 中大量出现，阅读时需要区分求值期/执行期。
4. **RID 是硬门槛**。`_HmosBuildStagesPayload` 要求 `RuntimeIdentifier != ''`；`_HmosValidateHapInputs` 只接受两个 hmos RID。没有 RID 时只编译托管代码并给出提示（`_HmosHintRidRequiredForHap`），不会产 HAP。
5. **所有权清单放在原生工程内**（`.hmos-staged/`），不是 `obj/`。这样做的好处是 clean obj 不会丢失“哪些文件是 SDK 写的”的记录；代价是原生工程目录被 SDK 写入，需要 `.gitignore`/清理策略配合。
6. **错误检查高度重复**。几乎每个目标都有 `HarmonyOSBuildTasksAssembly == '' or !Exists(...)` 的同款 `<Error>`。健壮但冗长，目标体可读性受影响。
7. **没有 Android 的 `_CreateUniversalApkFromBundle` / BundleTool 对应物**。HMOS 是一 RID 一 ABI 一 HAP；多 ABI 需要多次构建/合并，target 层未提供 universal 逻辑。
8. **HMOS 独有的质量门**：`HmosValidateHapContents`（runtime 白/黑名单）、`HmosVerifyHap`（证书链/profile）、`HmosCaptureLifecycleLog`（三类生命周期日志必须出现）。Android 侧没有等价的独立构建目标。
9. **签名/校验不在依赖链里**。`HmosBuildHapDependsOn` 只列到 `AssembleHmosHap` / `AfterHmosBuildHap`；`HmosValidateHapContents` 和 `SignHmosHap` 用 `AfterTargets` 挂载。实际执行顺序仍是 `AssembleHmosHap` → `HmosValidateHapContents` → `SignHmosHap` → `AfterHmosBuildHap`，但只看 `DependsOnTargets` 会低估实际工作量。要跳过签名只能设置 `HarmonyOSSigningMode=none`，不能靠直接调用 `AssembleHmosHap` 绕过（AfterTargets 仍会触发）。
10. **`HmosAlignNativeProjectSdkVersions` 会改开发者工程**。它把 `targetSdkVersion`/`compileSdkVersion`/`modelVersion` 对齐到本机命令行工具；`compatibleSdkVersion` 明确不动。默认开启，关闭开关是 `HarmonyOSAlignTargetSdkToToolchain=false`。

## 8. 与 Android 的“删除项”对照

HMOS 完全没有对应 target 的 Android 能力：

- Java 编译：`_CompileJava`、`Javac`、`JavaCompileToolTask`、`JavaSourceUtils`。
- Dex/压缩：`_CompileDex`、`D8`、`R8`、`GenerateProguardConfiguration`、`ProguardConfiguration`。
- Java 桩/类型映射：`_GenerateJavaStubs`、`_GenerateTrimmableTypeMap`、`_RemoveRegisterAttribute*`、`_RootResourceDesignerForTrimmableTypeMap`、`_ResolveImplementationAssembliesForTrimmableTypeMap`。
- AAPT2/资源：`_CreateBaseApkWithAapt2`、`_UpdateAndroidResgen`、`Aapt2`、`GenerateResourceCaseMap`、`RTxtFile`。
- Manifest：`_ManifestMerger`、`_ConvertCustomView`、`_ReadAndroidManifest`。
- 打包：`_CreateAar`、`BuildApkSet`、`_BuildApkSet`、`_CreateUniversalApkFromBundle`、`AndroidZipAlign`。
- 设备：`_DeployAppBundle`、`InstallApkSet`、`BootAndroidEmulator`、`GetAndroidActivityName`。
- 工具链：`_ResolveAndroidTooling`、`ResolveSdks`、`ResolveAndroidTooling`、`AndroidSdkBuildToolsVersion`。

这些能力在 HMOS 中被三类东西取代：

1. **hvigor/ArkTS 工具链**（Java/Dex/AAPT/Manifest 的替代）。
2. **NDK P/Invoke + NAPI 桥**（Java 绑定/类型映射的替代）。
3. **HAP 原生模型**（`module.json5`、`resources/base`、`rawfile`、`startup_config.json`）。

---

配套文档：

- `2026-11-28-dotnet-harmonyos-vs-android-host.md`：JNI vs NAPI、初始化顺序、错误码、runtimeconfig 解析。
- `2026-11-28-dotnet-harmonyos-vs-android-compare.md`：全部子系统的总览与结论。
