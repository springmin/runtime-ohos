# dotnet-harmonyos vs dotnet/android：原生宿主函数级对照（2026-11-28）

> 对比文件
>
> - **Android**：`dotnet/android` `src/native/clr/host/host.cc`（452 行，10 个函数）+ `host-jni.cc`（34 行，3 个导出）+ `coreclr-bootstrap.cc` + `host-environment.hh`。
> - **HarmonyOS**：`dotnet-harmonyos` `src/Microsoft.HarmonyOS.Runtime.Har/load_runtime/src/main/cpp/`
>   - `runtime_host.cpp`（200 行）
>   - `napi/runtime_napi.cpp`（216 行）
>   - `hosts/coreclr_host.cpp`（715 行）
>   - `hosts/mono_host.cpp`（520 行）
>   - `hosts/nativeaot_host.cpp`（215 行）
>   - `runtime_config_blob.cpp`（201 行）
>   - `runtime_environment.cpp`（39 行）
>
> 本文件只做**宿主层**（进程内嵌、初始化、配置、程序集加载、错误处理）对照，不含 IL 裁剪/编译管线。
>
> 归档在 `docs/plans/`。

## 1. 入口面：JNI → NAPI

### 1.1 Android：三个 JNI 导出 + `JNI_OnLoad`

`host-jni.cc` 全部内容就是三个入口：

```cpp
JNIEXPORT jint JNICALL
JNI_OnLoad (JavaVM *vm, void *reserved)
{
    return Host::Java_JNI_OnLoad (vm, reserved);
}

JNIEXPORT void JNICALL
Java_mono_android_Runtime_initInternal (
    JNIEnv *env, jclass klass, jstring lang, jobjectArray runtimeApksJava,
    jobjectArray appDirs, jint localDateTimeOffset, jobject loader,
    jboolean isEmulator, jboolean haveSplitApks)
{
    Host::Java_mono_android_Runtime_initInternal (...);
}

JNIEXPORT void JNICALL
Java_mono_android_Runtime_propagateUncaughtException (...)
{
    Host::propagate_uncaught_exception (...);
}
```

- 初始化是**Java 调用驱动**：`Java_mono_android_Runtime_initInternal` 由托管/Java 侧 `Runtime.initInternal` 调用。
- `JNI_OnLoad` 只做三件事：`CoreClrBootstrap::initialize()`、`RuntimeEnvironment::initialize(vm)`、`AndroidSystem::init_max_gref_count()`，返回 `JNI_VERSION_1_6`。
- 参数里有 `lang`、`appDirs`、`localDateTimeOffset`、`loader`、`isEmulator`、`haveSplitApks`——这些全部来自 Android/Java 运行时环境。

### 1.2 HarmonyOS：NAPI 模块 + 4 个 C 导出

`runtime_napi.cpp` 注册一个名为 `load_runtime` 的 NAPI 模块，导出 4 个 JS 函数：

| JS 函数 | 参数 | 返回 |
|---|---|---|
| `initializeRuntime` | `assemblyDirectory, nativeLibraryName, nativeEntryPoint, managedAssemblyName, applicationBaseDirectory` | `RuntimeStatus` 对象 |
| `getRuntimeStatus` | 无 | `RuntimeStatus` 对象 |
| `setEnvironmentVariable` | `name, value` | `true` |
| `runApplication` | 无 | `int32` 退出码 |

`RuntimeStatus` 的 NAPI 形态：

```cpp
SetString(env, result, "mode", ava::runtime::ToString(status.mode));
SetString(env, result, "state", ava::runtime::ToString(status.state));
napi_create_int32(env, status.errorCode, &errorCode);   // errorCode
SetString(env, result, "message", status.message.c_str());
```

另外，`runtime_napi.cpp` 还导出 4 个**稳定 C 符号**给 channel_base HAR 使用：

```cpp
HmosRuntimeNapiChannelInit(std::intptr_t envPtr)
HmosRuntimeNapiChannelRegisterTarget(const char* targetName, std::intptr_t targetRefPtr)
HmosRuntimeNapiChannelUnregisterTarget(const char* targetName)
HmosRuntimeNapiChannelDispatchEvent(std::intptr_t envPtr, const char* targetName,
                                    const char* eventName, const napi_value* argv, std::size_t argc)
```

结果分层规则（`CompleteNapiChannelOperation`）：**只有 `error` 非空才视为基础设施失败**；托管请求处理器返回的业务码（0 或负数）原样传回 ArkTS，由托管侧负责日志。这一点与 Android 的“异常穿透到 Java”完全不同。

模块注册使用构造函数：

```cpp
static napi_module RuntimeModule = {
    .nm_version = 1, .nm_flags = 0, .nm_filename = nullptr,
    .nm_register_func = Init, .nm_modname = "load_runtime",
    .nm_priv = nullptr, .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterRuntimeModule()
{
    napi_module_register(&RuntimeModule);
}
```

### 1.3 入口面对照

| 维度 | Android | HarmonyOS |
|---|---|---|
| 调用方 | Java/Kotlin（`Runtime.initInternal`） | ArkTS（`import load_runtime`） |
| 初始化时机 | `JNI_OnLoad` + Java 主动调用 | NAPI 模块注册 + ArkTS 主动调用 `initializeRuntime` |
| 参数来源 | Java 运行时（appDirs/lang/loader/offset） | ArkTS/HAR 常量（5 个字符串） |
| 异常回传 | `propagateUncaughtException` 回 Java | **无对等物**；`RunApplication` 返回退出码/错误字符串 |
| 生命周期 | 进程级，Java 侧驱动 | `RuntimeController` 单例状态机，ArkTS 可查询 |

## 2. 生命周期与并发模型

### 2.1 HarmonyOS `RuntimeController`

`runtime_host.cpp` 定义进程级单例：

```cpp
RuntimeController& RuntimeController::Instance()
{
    static RuntimeController instance;
    return instance;
}

RuntimeController::RuntimeController()
    : status_{ConfiguredMode(), RuntimeState::NotStarted, 0, "Runtime has not been initialized."}
{
}
```

状态：`NotStarted` → `Initializing` → `Ready` / `Failed`。

```cpp
RuntimeStatus RuntimeController::Initialize(const RuntimeInitializationOptions& options)
{
    std::lock_guard<std::mutex> lock(mutex_);
    if (status_.state == RuntimeState::Ready || status_.state == RuntimeState::Failed) {
        return status_;   // 首次结果粘滞，进程内不重试
    }
    status_ = {ConfiguredMode(), RuntimeState::Initializing, 0, "Runtime initialization started."};
    ...
    status_ = GetPlatformRuntimeHost().Initialize(options);
    ...
}
```

`RunApplication` 的并发设计：

- 第一次调用：在锁内把 `applicationStarted_ = true`，**解锁**后调用 `GetPlatformRuntimeHost().RunApplication()`，避免 `Program.Main` 回调 runtime 服务时死锁。
- 后续调用：等待 `applicationCompletedCondition_`，返回同一个退出码/错误。
- 捕获 `std::exception` 和 `...`，转成错误字符串。

### 2.2 Android

- 没有显式状态机；初始化由 `Java_mono_android_Runtime_initInternal` 一次完成。
- 线程模型依赖 `RuntimeEnvironment` 的 `pthread_key_t jni_env_key`：JNIEnv 按线程 TLS 绑定，需要时 `AttachCurrentThread`/`DetachCurrentThread`。
- `JNI_OnLoad` 里初始化 `RuntimeEnvironment`；`Java_JNI_OnLoad` 返回 JNI 版本。

**差异**：Android 的并发问题是“任何线程如何拿到 JNIEnv”；HMOS 的并发问题是“ArkTS 多次调用 initialize/run 如何幂等”。后者用互斥量 + 条件变量 + 状态机，前者用 TLS。

## 3. 初始化顺序逐步对照

### 3.1 Android `Java_mono_android_Runtime_initInternal`（host.cc:238–434）

1. `HostCommon::init_logging_categories()`
2. 解包 `appDirs`、`lang`，取 `files_dir`、`cache_dir`
3. `HostEnvironment::setup_environment(language, files_dir, cache_dir)`
   - `LANG` = language
   - `TMPDIR` = cache_dir
   - `HOME` = files_dir
   - `XDG_DATA_HOME` = `$HOME/.local/share`
   - `XDG_CONFIG_HOME` = `$HOME/.config`
4. `DOTNET_CrashReportRootPath` = cache_dir（仅在未设置时）
5. `AndroidSystem::detect_embedded_dso_mode(appDirs)`
6. `AndroidSystem::set_running_in_emulator(isEmulator)`
7. `AndroidSystem::set_primary_override_dir(files_dir)`
8. `AndroidSystem::create_update_dir(...)`
9. `AndroidSystem::setup_environment()`
10. `AndroidSystem::setup_app_library_directories(runtimeApks, appDirs, haveSplitApks)`
11. `gather_assemblies_and_libraries(runtimeApks, haveSplitApks)`
    - 无 assembly store → 跳过
    - 非 embedded DSO → 从文件系统 `lstat` + `dlopen`
    - embedded DSO → `dlopen(_assembly_store)` + `dlsym`
12. `coreclr_set_error_writer(clr_error_writer)`
13. 把 `&runtime_contract` 格式化成字符串
14. 填 4 个固定 runtime property：
    - index 0：`HOST_RUNTIME_CONTRACT`
    - index 1：`RUNTIME_IDENTIFIER`（来自 `Constants::runtime_identifier`）
    - index 2：`APP_CONTEXT_BASE_DIRECTORY`（`files_dir` + `/`，`malloc` 分配，函数内 static 持有）
    - index 3：`LOCAL_DATE_TIME_OFFSET`（Java 传入的秒数）
15. Debug + FastDev：把 `TRUSTED_PLATFORM_ASSEMBLIES` 追加到 property 数组（`FastDevAssemblies::build_tpa_list()`）
16. `coreclr_initialize(package_name, "Xamarin.Android", prop_count, names, values, &clr_host, &domain_id)`
17. `abort_unless(clr_host != nullptr)`
18. `DsoLoader::init(env, NativeLibraryHelper class)`
19. `preload_jni_libraries()`
20. 组装 `JnienvInitializeArgs`：
    - `javaVm` / `env`
    - `logCategories`
    - `packageNamingPolicy`
    - `remapping`（`BinaryBlobLoader::load_optional("remapping_data")`）
    - `grefGcThreshold` / `maxGrefCount`
    - `initializeGCBridge = &GCBridge::initialize_callback`
    - `grefLoader = env->NewGlobalRef(loader)`
    - `grefIGCUserPeer`
21. `create_delegate(Mono.Android, JNIEnvInit, "Initialize")`
22. `initialize(&init)` 进入托管初始化
23. 保存 `propagateUncaughtExceptionFn`

### 3.2 HarmonyOS `CoreClrHost::Initialize`（coreclr_host.cpp:270–470）

1. `assemblyDirectory` 非空校验
2. `realpath(assemblyDirectory)` 规范化
3. `applicationBaseDirectory` 必须存在且是目录（错误码 1313）
4. 入口程序集存在性：`<assemblyDirectory>/<managedAssemblyName>` 可读（1303）
5. 去掉 `.dll` 后缀得到 `assembly_name_`
6. `ConfigureRuntimeEnvironment()`（1304）
   - 要求 `HOME`、`TMPDIR`、`XDG_DATA_HOME`、`XDG_CONFIG_HOME`、`XDG_CACHE_HOME` 全部存在
   - `LANG` 缺失则 `setenv("LANG", "C.UTF-8", 0)`
   - `setlocale(LC_ALL, "")`，失败回退 `"C"`
7. `BuildTrustedPlatformAssemblies(assemblyDirectory)`（1305）
   - `opendir` + `readdir`
   - 只要 `.dll`，排除 `.r2r.dll`
   - `stat` 确认是普通文件
   - 排序后用 `:` 拼接
   - 列表为空 → 错误
8. `LoadRuntimeConfigBlob(<assemblyDirectory>/runtimeconfig.bin)`（1306）
9. 加载 native 库（1307）：
   - 必需：`libcoreclr.so`、`libclrjit.so`、`libclrgc.so`
   - 可选：`libclrgcexp.so`、`libSystem.Native.so`、`libhmicuuc.z.so`、`libhmicui18n.z.so`、`libSystem.Globalization.Native.so`、`libSystem.IO.Compression.Native.so`
   - ICU 必须提前可见，因为 HMOS globalization shim 用 `RTLD_NOLOAD` 获取
10. `dlsym` 三个 hosting API：`coreclr_initialize`、`coreclr_create_delegate`、`coreclr_set_error_writer`（1308）
11. `setErrorWriter(CoreClrErrorWriter)`
12. `setenv("DOTNET_EnableWriteXorExecute", "0", 1)`
13. `setenv("DOTNET_UseGCWriteBarrierCopy", "1", 1)`
14. 填 `host_runtime_contract`（size/context/.../`ExternalAssemblyProbe`）
15. 格式化 contract 指针（1309）
16. 构造 8 个宿主属性 + runtimeconfig 属性（1310 拒绝保留键）
17. `coreclr_initialize(entryAssembly, "HarmonyOS.Application", ...)`（1311/1312）
18. `ready_ = true`

**顺序差异的实质**：

| 项 | Android | HarmonyOS |
|---|---|---|
| 入口程序集 | 不检查（程序集在 store/APK 内） | 必须先存在且可读 |
| 环境变量 | 自己设置 HOME/TMPDIR/XDG | **要求平台预先设置**，否则失败 |
| runtime 配置 | 编译期 blob，随应用加载 | 运行时读 `runtimeconfig.bin` 文件 |
| TPA | 来自 assembly store / FastDev | 目录扫描 + 排序拼接 |
| native 库 | DSO cache + `monodroid_dlopen` + JNI preload | 固定 `dlopen` 列表 + 可选 ICU |
| GC 桥 | `GCBridge::initialize_callback` + GREF 参数 | 无 GC 桥（由 `DOTNET_UseGCWriteBarrierCopy=1` 规避写屏障问题） |
| 托管入口 | `JNIEnvInit.Initialize(&init)` | `coreclr_create_delegate(... "InvokeManaged")` |

## 4. 错误处理：abort vs RuntimeStatus

### 4.1 Android

`host.cc` 中所有失败路径都是：

```cpp
Helpers::abort_applicationf (
    LOG_ASSEMBLY,
    std::source_location::current (),
    "Unable to dlopen() assembly store '%s': %s", ...);
```

或 `abort_unless(...)`。没有错误码，没有恢复路径；失败即进程终止，日志带源文件/行号。

### 4.2 HarmonyOS

每个 host 返回 `RuntimeStatus { mode, state, errorCode, message }`，失败不终止进程，ArkTS 可以拿到对象并展示。错误码按 runtime 分段：

| 段 | 运行时 | 码表 |
|---|---|---|
| 1101–1104 | NativeAOT | 1101 `dlopen` 应用库失败；1102 app base 缺失；1103 `HmosSetAppContextBaseDirectory` 缺失；1104 设置 app base 失败 |
| 1201–1212 | Mono | 1201 目录为空；1202 目录不存在；1203 环境变量；1204 `MONO_PATH` setenv 失败；1205 `monovm_runtimeconfig_initialize` 失败；1206 `monovm_initialize` 失败；1207 domain 初始化失败；1208 corlib 未加载；1209 主程序集加载失败；1211 AOT fallback 注册失败；1212 app base 缺失（**1210 未使用**） |
| 1301–1313 | CoreCLR | 1301 目录为空；1302 `realpath` 失败；1303 入口程序集缺失；1304 环境变量；1305 TPA 为空；1306 runtimeconfig 解析失败；1307 native 库加载失败；1308 hosting API 缺失；1309 contract 指针格式化失败；1310 runtimeconfig 覆盖保留属性；1311 `coreclr_initialize` HRESULT；1312 host handle 为空；1313 app base 缺失 |

**注意**：

- 错误码不连续（1210、1300 空号），说明有历史删除或预留。
- `Failure()` 同时写 hilog（`OH_LOG_Print(LOG_APP, LOG_ERROR, ...)`），错误信息里包含路径或 loader error。
- `RuntimeController::Initialize` 对 `Failed` 也直接返回，**同一进程内不会重试**；ArkTS 若想重试只能重启进程。

## 5. runtimeconfig 解析：编译期 blob vs 运行时文件

### 5.1 Android `CoreClrBootstrap`

Android 的 runtime 配置不是 JSON，也不是运行时文件，而是 `BinaryBlobLoader::load("coreclr_bootstrap")` 载入的二进制块：

```cpp
struct BootstrapHeader {
    uint32_t magic;          // 0x47464358
    uint16_t version;        // 2
    uint16_t flags;          // bit0 split configs, bit1 assembly store
    uint32_t size;
    uint32_t env_count;
    uint32_t sys_count;
    uint32_t prop_count;
    uint32_t dso_count;
    uint32_t shared_count;
    uint32_t preload_count;
    uint32_t preload_stride;
    uint32_t env_offset;
    uint32_t sys_offset;
    uint32_t prop_offset;
    uint32_t dso_offset;
    uint32_t preload_offset;
    uint32_t strings_offset;
    uint32_t strings_length;
    uint32_t package_naming_policy;
    uint32_t assembly_count;
    uint32_t bundled_name_width;
    uint32_t package_offset;
};
static_assert (sizeof (BootstrapHeader) == 84);
```

特征：

- 固定要求 `prop_count >= 4`（`HOST_RUNTIME_PROPERTY_COUNT = 4`）。
- 前 4 个属性由 native 填充（contract/RID/AppContext/UTC offset），其余属性值直接从字符串池读。
- 同时携带 `environment_variable_count`、`system_property_count`、`DSO cache`、`preload` 表。
- 版本/魔数/offset 越界都会 `invalid()` → `abort_applicationf`。
- 没有“重复键”“尾随数据”概念，因为格式由构建期生成器保证。

### 5.2 HarmonyOS `LoadRuntimeConfigBlob`

HMOS 读取标准 `runtimeconfig.bin`（由 `RuntimeConfigParserTask` 生成），自己解析 ECMA-335 压缩整数：

```cpp
constexpr std::size_t MaxRuntimeConfigBytes = 4 * 1024 * 1024;
constexpr std::uint32_t MaxRuntimePropertyCount = 4096;
constexpr std::uint32_t MaxRuntimePropertyBytes = 1024 * 1024;
```

校验：

- 1/2/4 字节压缩整数必须**规范编码**（非规范直接报错）。
- 字符串长度 ≤ 1 MiB，不允许内嵌 NUL。
- 属性数 ≤ 4096，文件 ≤ 4 MiB。
- 键不能为空，不能重复。
- 读完声明数量后必须**恰好到文件尾**，尾随数据报错。
- 解析结果 `RuntimeConfigBlob { vector<RuntimeConfigProperty> }`。

合并进 `coreclr_initialize` 时，宿主属性优先：

```cpp
for (const RuntimeConfigProperty& property : runtimeConfig.properties) {
    if (IsReservedHostProperty(property.key)) {
        return Failure(1310,
            "runtimeconfig.bin attempts to override host property '" + property.key + "'.");
    }
    keys.push_back(property.key.c_str());
    values.push_back(property.value.c_str());
}
```

保留键共 11 个：

```cpp
constexpr std::array<const char*, 11> ReservedHostProperties = {
    HOST_PROPERTY_RUNTIME_CONTRACT,
    HOST_PROPERTY_TRUSTED_PLATFORM_ASSEMBLIES,
    HOST_PROPERTY_APP_PATHS,
    "APP_NI_PATHS",
    HOST_PROPERTY_NATIVE_DLL_SEARCH_DIRECTORIES,
    HOST_PROPERTY_PLATFORM_RESOURCE_ROOTS,
    "APP_CONTEXT_BASE_DIRECTORY",
    "RUNTIME_IDENTIFIER",
    HOST_PROPERTY_BUNDLE_PROBE,
    HOST_PROPERTY_ENTRY_ASSEMBLY_NAME,
    HOST_PROPERTY_PINVOKE_OVERRIDE,
};
```

Mono 不走这个解析器：它把 `runtimeconfig.bin` 路径直接交给 `monovm_runtimeconfig_initialize`，再单独传 3 个属性（`RUNTIME_IDENTIFIER`、`APP_CONTEXT_BASE_DIRECTORY`、`NATIVE_DLL_SEARCH_DIRECTORIES`）。NativeAOT 完全不读 runtimeconfig。

### 5.3 对照结论

| 维度 | Android | HarmonyOS |
|---|---|---|
| 格式 | 自定义 84 字节头 + 字符串池 + 表 | 标准 `runtimeconfig.bin`（ECMA-335 压缩整数） |
| 生成时机 | 构建期编进应用 | 构建期生成文件，运行时读取 |
| 解析方 | `CoreClrBootstrap::initialize` | `LoadRuntimeConfigBlob` |
| 宿主属性 | 固定 4 个槽位 | 8 个固定键 + 11 个保留键校验 |
| 环境变量 | blob 内 `env_count` 批量设置 | 不在 blob 内；要求平台预置 |
| DSO/程序集元数据 | blob 内 DSO cache/preload/store 标志 | 无；目录扫描或 `dlopen` |
| 失败行为 | abort | 返回错误码 1306/1310 |

## 6. 程序集加载

### 6.1 Android

- **Assembly store**：`dlopen(store_path, RTLD_NOW | RTLD_LOCAL)` + `dlsym(DLOPEN_ASSEMBLY_STORE_SYMBOL)`；store 以共享库形式打包，payload 通过动态符号暴露。
- **FastDev**（Debug）：从 `.__override__/<arch>/` 读取程序集，并构造 TPA 列表。
- **external assembly probe**：`AssemblyStore::open_assembly` 或 `FastDevAssemblies::open_assembly`，按路径查 store。
- 不做目录 TPA 扫描；APK/assembly store 是唯一权威。

### 6.2 HarmonyOS CoreCLR

- **TPA = 目录扫描**：`assemblyDirectory` 下所有 `.dll`（排除 `.r2r.dll`），排序后 `:` 拼接。
- **external probe** 只允许两个文件：
  - `<assembly_name>.dll`
  - `<assembly_name>.r2r.dll`
- 解析路径必须 `realpath` 后仍在 `assembly_directory_` 内，且以 `.dll` 结尾。
- 用 `mmap(PROT_READ, MAP_PRIVATE)` 映射，缓存到 `mappings_`，进程生命周期内不 `munmap`（析构时统一释放）。
- 其他程序集路径一律返回 `false`，由 CoreCLR 走 TPA。

### 6.3 HarmonyOS Mono

- `MONO_PATH = assemblyDirectory`
- `mono_set_assemblies_path(assemblyDirectory)`
- `mono_config_parse(nullptr)`
- 入口程序集：`mono_domain_assembly_open(domain_, "<assemblyDirectory>/<managedAssemblyName>")`
- AOT 模式注册 `mono_dl_fallback_register`：
  - `LoadAotSidecar` 只接受 `.dll.so`
  - 从 `AVA_BUNDLE_LIB_DIR` 拼路径 `dlopen`
  - `ResolveAotSidecarSymbol` → `dlsym`
  - `CloseAotSidecar` → `dlclose`
- 解释器模式：`mono_jit_set_aot_mode(MONO_AOT_MODE_INTERP_ONLY)`
- JIT 模式：`MONO_AOT_MODE_NONE`

### 6.4 HarmonyOS NativeAOT

- 预加载 `libz.so`、`libz.z.so`、`/system/lib64/libz.so`（失败仅 debug 日志）。
- `dlopen(nativeLibraryName, RTLD_NOW | RTLD_GLOBAL)`，默认 `libapp.so`。
- 必须找到 `HmosSetAppContextBaseDirectory` 并调用成功（1103/1104）。
- `RunApplication`：`dlsym(entryPointName)`，默认 `Run`。
- NAPI channel：`NapiChannelInit`、`NapiChannelRegisterTarget`、`NapiChannelUnregisterTarget`、`NapiChannelDispatchEvent`，首次使用时解析并缓存。

## 7. 托管入口点约定

| 运行时 | Android | HarmonyOS |
|---|---|---|
| Mono | `JNIEnvInit.Initialize(&init)`（`Mono.Android` 程序集） | `Microsoft.HarmonyOS.Generated.HarmonyOSNativeEntryPoint.InvokeManaged`；找不到则回退 CLI header entry point |
| CoreCLR | `JNIEnvInit.Initialize(&init)` | `Microsoft.HarmonyOS.Generated.HarmonyOSNativeEntryPoint.InvokeManaged` |
| NativeAOT | Android 自己的 bootstrap（JNI/type map） | `Run`（或 `HarmonyOSHapNativeEntryPoint`） |

HMOS 的 `InvokeManaged` 是**无参、返回 int** 的静态方法；Mono 通过 `mono_runtime_invoke` 调用并 unbox 返回值，CoreCLR 通过 `coreclr_create_delegate` 转函数指针。

## 8. 函数级映射表

| Android | HarmonyOS | 关系 |
|---|---|---|
| `Host::Java_mono_android_Runtime_initInternal` | `CoreClrHost::Initialize` / `MonoHost::Initialize` / `NativeAotHost::Initialize` | 初始化总入口，拆成三套 |
| `HostCommon::Java_JNI_OnLoad` | `RegisterRuntimeModule`（constructor）+ `initializeRuntime` | 注册/引导 |
| `Host::propagate_uncaught_exception` | **无** | HMOS 无异常回传通道 |
| `Host::create_delegate` | `CoreClrHost::CreateDelegate`；Mono `ResolveGeneratedMethod`；NativeAOT `ResolveManagedExport` | 托管方法解析 |
| `Host::clr_external_assembly_probe` | `CoreClrHost::ExternalAssemblyProbe` + `TryMapAssembly` | 外部程序集探测；HMOS 限制更严 |
| `Host::gather_assemblies_and_libraries` | `BuildTrustedPlatformAssemblies` / `mono_set_assemblies_path` / `dlopen` | 程序集发现 |
| `Host::map_assembly_store_via_dlopen` | **无** | HMOS 无 assembly store |
| `Host::load_assembly_store_from_filesystem` | **无** | 同上 |
| `Host::preload_jni_libraries` | `MonoHost::PreloadSystemLibraries`；`NativeAotHost::PreloadSystemLibrary`；CoreCLR 的 `LoadOptionalLibrary` | 预加载 native 库 |
| `RuntimeEnvironment`（JNIEnv TLS） | `runtime_environment.cpp`（环境变量校验） | 同名不同职责 |
| `CoreClrBootstrap::initialize` | `LoadRuntimeConfigBlob` | 配置载入 |
| `CoreClrBootstrap::setup_environment` | `ConfigureRuntimeEnvironment` + `setenv` + NAPI `setEnvironmentVariable` | 环境准备 |
| `Host::clr_error_writer` | `CoreClrErrorWriter` | 错误日志 |
| `GCBridge` / GREF 参数 | **无** | HMOS 无 Java GC 桥 |

## 9. 行为差异与风险

1. **初始化前置条件更硬**。HMOS 要求 `HOME`、`TMPDIR`、`XDG_DATA_HOME`、`XDG_CONFIG_HOME`、`XDG_CACHE_HOME` 全部存在；Android 是自己从 `files_dir`/`cache_dir` 推导并创建。HAR/EntryAbility 必须保证这 5 个变量，否则 CoreCLR/Mono 初始化直接失败（1304/1203）。NativeAOT 不校验这些变量，行为不一致。
2. **`XDG_CACHE_HOME` 是 HMOS 新增要求**。Android 只设置 `XDG_DATA_HOME` 和 `XDG_CONFIG_HOME`，没有 `XDG_CACHE_HOME`；HMOS 把它列为必需项。
3. **状态粘滞**。`RuntimeController::Initialize` 一旦 `Failed` 就永远返回同一结果；ArkTS 侧没有 `reset`/`retry` API。调试时若首次初始化参数错误，必须重启应用。
4. **持锁初始化**。`RuntimeController::Initialize` 在整个 host 初始化期间持有 `mutex_`；如果托管初始化回调 `getRuntimeStatus`，会死锁。`RunApplication` 已经为 `Program.Main` 做了“解锁后调用”的处理，但 `Initialize` 没有。
5. **异常语义弱化**。Android 会把未捕获托管异常通过 `propagateUncaughtException` 回传 Java；HMOS 没有对应导出。Mono 只能检查 `MonoObject* exception` 并返回 `-1` + 字符串；CoreCLR 的 `InvokeManaged` 若抛出托管异常，宿主只捕获 C++ 异常，托管异常如何跨边界表现取决于 CoreCLR 的未处理异常策略。
6. **CoreCLR 专属环境开关**。`DOTNET_EnableWriteXorExecute=0`、`DOTNET_UseGCWriteBarrierCopy=1` 是 HMOS 宿主强制的；Android 没有这两个设置。它们与 OHOS 的 W^X/GC 写屏障限制有关，属于平台 workaround，不应视为通用最佳实践。
7. **NativeAOT 入口符号是硬契约**。`HmosSetAppContextBaseDirectory` 缺失直接 1103 失败；这意味着 NativeAOT 产物必须链接 HMOS 的 runtime 支持库，不能用任意 `dotnet publish` 产物替换。
8. **错误码是 API 的一部分**。NAPI 把 `errorCode` 暴露给 ArkTS；一旦发布，1101–1313 的语义应保持稳定，新增错误应避免复用空号（1210、1300）。
9. **Mono 调试器通过环境变量开启**。`DOTNET_HMOS_MONO_DEBUGGER_AGENT` 非空时拼接 `--debugger-agent=` 并 `mono_jit_parse_options`；这是 HMOS 独有的调试通道，Android 走 JDWP/`adb forward`。
10. **CoreCLR TPA 排除 `.r2r.dll`**。复合 R2R 镜像通过 external probe 的 `isCompositeImage` 分支处理；普通 R2R 单文件仍在 TPA 中。这个约定与 Android 的 assembly store 完全不同，排查 `FileNotFoundException` 时要先看文件命名。

---

配套文档：

- `2026-11-28-dotnet-harmonyos-vs-android-targets.md`：HAP targets 逐阶段对照。
- `2026-11-28-dotnet-harmonyos-vs-android-compare.md`：全部子系统总览。
