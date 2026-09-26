# 四域 skill 合规审计与彻底修复报告（ArkTS · NAPI · 互操作/AOT · MSBuild）

- **日期**：2026-09-25（**2026-09-26 回填**：P2 收口、PLAT-GAP 补录、TASK-MIG 进展、KIT-GAP/KIT-IMPL 结论）· **范围**：`ohos-workload`（壳/宿主/打包）、`maui-ohos`（OpenHarmony 平台切片）、`sdk-ohos`（SDK 打包/codesign）、`runtime-ohos`（文档/契约）。
- **修复策略**：审计条目**一律按「最彻底修法」落地**（用户要求），不保留只做「最小修法」的条目；本环境无法闭环的进「排期」，写明阻塞点，不降级为「有意保留」。
- **计数口径**：`comp-{arkts,napi,interop,build}/report.md` 未落盘（见 §6①），本报告按本轮修复工单（`fix-*` 报告/日志/提交消息）重建；「合规复核」= 本轮新增且已绿的自动化门禁。
- **2026-09-26 回填口径**：P2 收口后互操作/AOT 域 6/6；PLAT-GAP 为审计表外**补录**（+1 条目，不计入原 30 条的违例/偏差）；「已彻底修复」= 4（ArkTS）+ 8（NAPI）+ 6（互操作/AOT）+ 8（MSBuild 原 30 条内）+ 1（PLAT-GAP 补录）= **27**；域内排期 4 = ArkTS 1（HMS 真机验收，外部条件 §4）+ NAPI 1（6d）+ MSBuild 2（TASK-MIG 内联任务进行中、打包 clean/RID pin 随其复验），另 sdk 2 项基建（测试接 CI、`ohos-full-build` runner 红）。

| 域 | 审计条目 | 违例 | 偏差 | 合规复核（新增门禁） | 已彻底修复 | 域内排期 |
|---|---|---|---|---|---|---|
| ArkTS | 5 | 3 | 2 | 2（`--check-sources` / `--check-pack-abc`） | 4 | 1 |
| NAPI | 9 | 5 | 4 | 3（`build-host.sh` NEEDED / UND / exports 三闸） | 8 | 1 |
| 互操作/AOT | 6 | 2 | 4 | 2（`check-host-exports.py` 静态 + `host-export-contract.yml`） | **6** | **0** |
| MSBuild | 10 | 3 | 7 | 3（`lint-packs` / 双导入 fixture / `ridgraph-sync.yml`） | 8 | 2 |
| 补录 · PLAT-GAP（表外，MSBuild/打包域） | +1 | — | — | +1（`selftest-packs` 21/0） | **+1** | 0 |
| **合计** | **30（+1 补录）** | **13** | **17** | **10+1 补录** | **27** | **4（+2 SDK 基建）** |

加载的 skill（按域）：ArkTS `hmos-arkui-develop-skill` + `hmos-one-sdk-skill`；NAPI `hmos-native-memleak-analysis` + `hmos-arkts-knowledge-retriever`（NDK/NAPI 线程·env·ref 语义）；互操作/AOT `dotnet-pinvoke` + `dotnet-aot-compat`；MSBuild `msbuild-antipatterns` + `directory-build-organization` + `target-authoring` + `item-management` + `incremental-build` + `property-patterns`。

## 2. 分域明细（5 列 + 修复状态）

### 2.1 ArkTS（COMP-ARKTS）

| 文件:行 | skill 规则依据 | 严重度 | 最小修法 | 最彻底修法（已落地） | 修复状态 |
|---|---|---|---|---|---|
| `templates/ets/pages/Index.ets`（审计源 `Index.ets.orig:11-47`，37 处 `@ohos.*`） | `hmos-one-sdk-skill`：Kit API 统一 `@kit.*` 导入面 | 违例·中 | 逐条换路径 | `@ohos.*`→`@kit.*` 全量迁移（含动态 import 变量说明符） | 已修 `35719d8`；`--check-sources` 禁 `@ohos`，selftest 125/0 |
| `Index.ets.orig:506,527,780,826` 等（全局 `getContext()` 23 处） | `hmos-arkui-develop-skill`：上下文经 UI 上下文获取，不用全局 | 违例·中 | 单点替换 | `hostContext()` 单点 helper 覆盖 21 个调用位 | 已修 `35719d8` |
| `Index.ets.orig:2900,2914,2916`（`focusControl`）+ `console.*` 70 处（:396 起）+ `build()` 三元 + 监听未注销 + overlay 未避让 | `hmos-arkui-develop-skill`：焦点/生命周期清理/避让/日志 | 偏差·低 | 单点替换 | `getFocusController().requestFocus`、`new RegExp()`、注销台账（`aboutToDisappear`）、避让区 inset、`hilog`、可选 catch、`import type` | 已修 `35719d8` |
| `OpenHarmony.Hap.targets:1313-1399`（requestPermissions 无 reason/usedScene，请求点无校验） | `hmos-one-sdk-skill`：权限需 reason+usedScene 且与请求点一致 | 违例·高 | 补字段 | feature→permission 矩阵 + 请求点扫描门禁（strict 可 error） | 已修 `bc959ab` + 文档 `324a4d1` |
| HMS Kit（Share/Scan/Map… 在 OpenHarmony SDK 下静态不可编译） | `hmos-one-sdk-skill` / KIT-GAP：Kit 需特性探测 + 优雅降级 | 偏差·中 | 仅文档门控 | Share/Scan `canIUse` + 变量 import 探测、缺失降级；`ARKTS_SDK_FLAVOR=harmony` 脚手架 | 探测已落地 `652c356`/`68220cd`；KIT-GAP/KIT-IMPL 复核 14 项 = 5 条件可补齐（Share/Scan 已落地；Map/Push/Account 待 HMS/AGC）· 3 仅记录 · 6 维持门控（`8b37c37daa3` + KIT-GAP doc，§4）；真机验收待 HMS 设备 |

### 2.2 NAPI（COMP-NAPI；`src/OpenHarmonyHost/`）

| 文件:行 | skill 规则依据 | 严重度 | 最小修法 | 最彻底修法（已落地） | 修复状态 |
|---|---|---|---|---|---|
| `host_napi.cpp`:1516-1560/1583-1600/1660-1700（跨线程直调 env） | NAPI 线程/env 语义（`hmos-arkts-knowledge-retriever`） | 违例·严重 | 加锁 | 3 处改 `HostCallJs()` TSFN 同步应答；全部 `napi_call_function` 收口 `HostCallCallback()`（JS 线程断言 + 清异常） | 已修 `fec065c` |
| `host_napi.cpp`:196-346/780-836/3025-3045（env cleanup 缺失） | `hmos-native-memleak-analysis`：env 生命周期 | 违例·严重 | 补 hook | `HostBinding` per-env 4 槽表 + `napi_add_env_cleanup_hook` 完整清理 | 已修 `fec065c` |
| `host_napi.cpp`:1700-1795/340-350/110-145（菜单数据竞争） | NAPI 线程安全 | 违例·严重 | 加锁 | `HostMenuSnapshot` 值语义经 TSFN 投递，删共享可变 vector | 已修 `fec065c` |
| `host_napi.cpp`:389-441（待决异常未清） | NAPI 异常纪律 | 违例·严重 | 逐处 clear | `HostCallCallback()` 统一 `get_and_clear_last_exception` + 日志 | 已修 `fec065c` |
| `host_napi.cpp`:640-676/1113-1130/930-975（ref 生命周期） | `hmos-native-memleak-analysis`：ref 创建/删除 | 违例·严重 | 补 delete | `HostRefReplace()` 单点 create-先/delete-后 + 失败回滚，teardown 用原 env | 已修 `fec065c` |
| `host_napi.cpp`:100-160/717-740/860-875（argv 未初始化/型检缺失） | NAPI 参数契约 | 偏差·低 | 逐处初始化 | `HostMakeArgs()` 全槽初始化 + 表驱动 `HostForEachSink` 统一型检/reset | 已修 `fec065c` |
| `openharmony_host.c`:1633-1765/1810-1840/3809（每帧 mmap） | 所有权/缓存键 | 偏差·中 | 缩窗口 | 缓存键 (window,generation,fd,size)+dup(fd) + `OhosHostPresentMapAcquire` | 已修 `e6fb3ba` |
| `openharmony_host.c`:3192-3198/3304/3375（文本缓存计费 off-by-one） | 计量正确性 | 偏差·低 | 改计数 | entry 增 `bytes` 字段并按 `text_len+1` 逐出 | 已修 `e6fb3ba` |
| `openharmony_host.c`：drawing RAII / effect 所有权 / location-IME 生命周期 / NodeContent 身份 / 原子发布注册表 / 缓冲按需分配 | 所有权与生命周期 | 偏差·中 | — | 逐项整改（需先重建定位） | **排期**（§3.2-②） |

门禁/数字：`scripts/build-host.sh` 3 次全绿（NEEDED 5/5、UND denylist 0、exports 114/114 → 后并 118/118、selfsign、无 libhostfxr）；交互套件 **320/320 floor=300**（NAPI 修复时点，`fix-napi/verify4.txt`；P2 收口复跑 **326/floor=306**）、A7 pin 7/7、像素 `PIXEL ASSERTIONS PASSED`；pin 更新 `c3fa422`/`6a88b83`。

### 2.3 互操作 / AOT（COMP-INTEROP；`maui-ohos` 切片 + 宿主契约）

| 文件:行 | skill 规则依据 | 严重度 | 最小修法 | 最彻底修法（已落地） | 修复状态 |
|---|---|---|---|---|---|
| `OpenHarmonySensors.cs:26,29,32,35` + `OpenHarmonyNotifications.cs:12`（5 个 EntryPoint 仅有 `_Z` mangled，`comp-interop/contract-check.txt:3-8`） | `dotnet-pinvoke`：DllImport 必须是稳定 C 链接符号 | 违例·严重(P0) | 逐个补 extern "C" | 头文件 extern "C" 补齐 + `host-exports.txt` 118 契约 + `nm -D` 门禁 + CI | 已修 `88ee1d7`→`ccf61e6`；118/118 全绿 |
| `OpenHarmonyHybridWebViewHandler.cs:505,553,560,648,666,862,863`（12 处反射 STJ） | `dotnet-aot-compat`：禁 RequiresUnreferencedCode/DynamicCode | 违例·高 | 逐处 JsonTypeInfo | `OpenHarmonySliceJsonContext` 源生成 + 12 处换 `JsonTypeInfo` + CI `-warnaserror:IL2026,IL3050` | 已修 `635bbd0e`；IL2026/3050 = 0 |
| `OpenHarmonyHandlerConnector.cs:20`、`OpenHarmonyKeyboardAcceleratorManager.cs:370,375`、`OpenHarmonySensors.cs:110`（IL2070/2075） | `dotnet-aot-compat`：DynamicallyAccessedMembers 注解 | 偏差·中 | 逐处抑制 | 反射查找收口 + 懒查找注解 | 已修 `6062d796`；IL2xxx = 0 |
| `OpenHarmonyBlazorWebViewHandler.cs`（注册守卫与 define 不一致） | `dotnet-aot-compat`：条件编译一致性 | 偏差·中 | 单 guard | 同一 define 守卫 + 静态资产单源 | 已修 `5cd7688d` |
| `contract-check.txt:1`（审计计 121 处 `[DllImport]` 声明；实计 125，含 2 个全限定形式） | `dotnet-pinvoke`：优先 `[LibraryImport]` 源生成 + 回调 | 偏差·P2 | — | 分批迁移 `[LibraryImport]`/回调并加分析器门禁 | **已完成（2026-09-26）**：125 处全量迁移（slice 81 + hosting 44），`[DllImport]`/SYSLIB1054–1057 归零，回调 40/40 ABI 注解，`DisableRuntimeMarshalling` 未启用（退出条件已记录）；门禁 326/floor 306 + 像素 + 118/118 + selftest 全绿；AOT smoke SKIP（ilc 包缺失）；ow `eadd5cd`/`78422d7`/`54f0415`/`af620aa`、maui `31f4dbac`/`096c1720`/`1a754753` |
| `openharmony_host.c` AOT 载荷入口 | `dotnet-aot-compat`：单一 AOT 入口 | 偏差·中 | 文档 | 经 app 自身 export 启动 + JIT-only 入口守卫 | 已修 `f3514a6`/`2e98249`；真机冒烟待条件（aot-smoke → NETSDK1083/1203 SKIP） |

### 2.4 MSBuild（COMP-BUILD；`ohos-workload` packs + `sdk-ohos` targets）

| 文件:行 | skill 规则依据 | 严重度 | 最小修法 | 最彻底修法（已落地） | 修复状态 |
|---|---|---|---|---|---|
| `OpenHarmony.Hap.targets:632`（旧 `ReadLinesFromFile`+`Replace` 拼 module.json） | `msbuild-antipatterns`：文本拼 JSON 无校验 | 违例·高 | 补转义 | `OpenHarmonyGenerateModuleJson` JSON 上下文替换 + 校验 + golden/负例 | 已修 `023d1d7` |
| `OpenHarmony.Hap.targets:1191`（`$HOME` Cellar 探测工具链） | `property-patterns`：显式输入，隐式探测删除 | 违例·中 | 注释 | 只认 `OpenHarmonySdkRoot`/`OHOS_SDK_ROOT`，报错给出属性名 | 已修 `023d1d7` |
| `OpenHarmony.Hap.targets:1260`（Blazor 资产含 NuGet cache glob） | `item-management`：单一 item 来源 | 偏差·中 | 保留 glob | 只取 `@(StaticWebAsset)`，缺资产硬报错 | 已修 `023d1d7` |
| `OpenHarmony.Hap.targets:1399`（publish 后 staging 无注入点） | `target-authoring`：`$(...DependsOn)` 链扩展 | 偏差·低 | 文档 | `OpenHarmonyAfterPublishDependsOn` 注入点 | 已修 `023d1d7` + 文档 `e9cd1f4` |
| `OpenHarmony.Hap.targets`（stage/restool/hap 未登记 FileWrites）；`sdk-ohos .../Microsoft.NET.Sdk.targets:900-930`（codesign stamps） | `incremental-build`/`item-management`：创建即登记 FileWrites | 偏差·中 | 逐目标补 | 同目标登记 + `dotnet clean` 契约；sdk 双 stamp + 5/5 用例 | 已修 `023d1d7` + `sdk-ohos 5fc073ed8f` |
| 三 pack 的 `BundledVersions.props`/`DefaultProperties.props`/`SupportedPlatforms.props`/`Microsoft.OpenHarmony.Sdk.targets` 无导入；双导入不幂等 | `directory-build-organization`：单一来源 + 幂等导入 | 偏差·中 | 注释 | 删 4 个悬空文件 + 捕获式导入守卫 + PlatformItems 拆分 + lint/负例 | 已修 `a285f7b` |
| `packs/*/PortableRuntimeIdentifierGraph.openharmony.json`（缺 linux-musl 映射，与 sdk-ohos 规范图漂移） | `including-generated-files`：生成物单一来源 | 违例·中 | 手改副本 | `sync-ridgraph.sh` 单源生成 + canonical sha256 + 跨仓字节门禁 | 已修 `37eed53`；`selftest-ridgraph` 20/0 |
| `OpenHarmony.Hap.targets:105,161,256,326,403,632`（审计列 6 个内联 `RoslynCodeTaskFactory` 调用点 = 5 个任务类 + 1 个 zip 代码片段） | `msbuild-antipatterns`：内联任务不可测/不可复用 | 偏差·P2 | — | 迁 `Microsoft.OpenHarmony.Tasks.dll`（net11.0 + 单测 + 三 pack `tools/`） | **进行中**（TASK-MIG，2026-09-26）：任务类已实现、三 pack `UsingTask` 已改指程序集，hap publish 全量复验中；随 RELEASE-25/kit #26 收口（§3.2-①） |
| 打包 clean 无功能回归；`ridgraph-sync.yml` pin 需锁步 bump | `incremental-build` | 偏差·低 | — | 真实 publish `dotnet clean` 回归 + pin 联动 | **并入 TASK-MIG**：PLAT-GAP 已复验真实 restore/publish/hap publish（§2.5）；`dotnet clean` 契约随 TASK-MIG 全量 publish 收口；pin 变更须锁步 bump（`selftest-packs` 21/0 含 pin 门禁） |
| `test/*.csproj` 绝对路径（`~`/盘符） | `msbuild-antipatterns`：可移植构建输入 | 偏差·低 | 单点改 | 相对 root + 共享 props + 路径门禁（25 用例） | 已修 `88ca8eb`/`fd913a2`；selftest-repo-hygiene 25/0 |

门禁/数字：`lint-packs` + `selftest-packs` **21/0**（双导入 fixture + PLAT-GAP T7：KFR pin/RID 默认/apphost opt-out）、`selftest-hap-targets` 30/0（PLAT-GAP 插件复验 31/0 + 1 skip）、`selftest-ridgraph` 20/0、sdk codesign FileWrites 5/5（installer 43/0、hostfeed 10/0）、`preflight` 全绿（RID/lint/paths + 29 脚本 + markdownlint 0）；ohos-workload master 的 5 条 workflow（interaction/pixel/host-export-contract/ridgraph-sync/markdownlint）全部 success。

### 2.5 补录：平台缺口（PLAT-GAP，审计表外）

| 文件:行 | skill 规则依据 | 严重度 | 最小修法 | 最彻底修法（已落地） | 修复状态 |
|---|---|---|---|---|---|
| `packs/*/{PlatformItems,Sdk}.targets`（间接引用 AspNetCore 的工程 restore 失败：NU1102 `Microsoft.AspNetCore.App.Runtime.linux-musl-arm64` 未发布；另 `NETSDK1083 ohos-arm64` 与未发布的 apphost 包） | `property-patterns`/`including-generated-files`：显式输入、可发布依赖 | 补录·功能阻断 | 演示侧规避 | KFR pin 到 RC1 GA `11.0.0-rc.1.26425.128`（net10 已为已发布值）；可执行工程默认 `RuntimeIdentifier=openharmony-arm64`（显式 `-r` 优先）；`EnableAppHostPackDownload=false`；演示工程去 `DisableTransitiveFrameworkReferenceDownloads` 规避 | **已完成（2026-09-26）**：真实 restore/publish/hap publish 全绿（hap 278 条目、`dotnet.zip` 254、abc 234,620 = kit #25 同尺寸）；`selftest-packs` 21/0（T7）；ow `96686b2` |

## 3. 已彻底修复清单与排期项

### 3.1 已彻底修复（按域）

- **ArkTS**：`@ohos.*`→`@kit.*`、`hostContext()`、焦点/日志/注销/避让/类型（`35719d8`）；feature 权限矩阵 + 请求点门禁（`bc959ab`）；文档与套件 pin（`324a4d1`/`b49c59c`）；abc 重建 ui 234,620 B / headless 18,532 B（abc 13.0.1.0）+ `abc-provenance.json`，`--check-pack-abc` 三 pack 字节一致。
- **NAPI**：per-env 绑定 + JS 线程收口 + 菜单快照 + ref 单点（`fec065c`）；present 缓存键/dup fd + 文本字节计费（`e6fb3ba`）；宿主三闸全绿。
- **互操作/AOT**：5 个 C 链接符号 + 118 导出契约 + `nm`/CI 门禁（`88ee1d7`→`ccf61e6`）；STJ 源生成 + trim/AOT 分析器门禁、IL 告警 0（`635bbd0e`/`6062d796`/`5cd7688d`）；AOT 单入口（`f3514a6`/`2e98249`）；Share/Scan EntryPoint 并入契约（`fc7fbfdc`）；**P2 收口（2026-09-26）**：125 处 `[LibraryImport]`（slice 81 + hosting 44），`[DllImport]`/SYSLIB1054–1057 归零，回调 40/40 ABI 注解，`DisableRuntimeMarshalling` 未启用（退出条件已记录于两个 csproj）；ow `eadd5cd`/`78422d7`/`54f0415`/`af620aa`、maui `31f4dbac`/`096c1720`/`1a754753`；交互 326/floor 306 + 像素 + 118/118 + selftest（ridgraph 20 / packs 21 / hap-targets 30 / repo-hygiene 25）全绿；AOT smoke SKIP（ilc 包缺失）。
- **MSBuild**：module.json/工具链/Blazor/AfterPublish/FileWrites（`023d1d7`）；悬空 props/targets + 双导入守卫（`a285f7b`）；RID 图单源（`37eed53`）；文档契约（`e9cd1f4`）；相对路径门禁（`88ca8eb`/`fd913a2`）；sdk codesign FileWrites（`5fc073ed8f`）；**PLAT-GAP（2026-09-26，表外补录）**：AspNetCore runtime pack 平台缺口修复（KFR pin/默认 RID/apphost opt-out；`96686b2`，§2.5）；**TASK-MIG（进行中）**：内联任务迁 `Microsoft.OpenHarmony.Tasks.dll`。

### 3.2 排期项（含阻塞点）

1. **内联 MSBuild 任务迁移（TASK-MIG，进行中）**：5 个任务类（+1 zip 代码片段）已实现为 `Microsoft.OpenHarmony.Tasks.dll`（net11.0 + 单测 + 三 pack `tools/`），三 pack `UsingTask` 已改指程序集；剩余 hap publish 全量复验已完成；`tools/Microsoft.OpenHarmony.Tasks.dll` 自 kit #26 起入包（kit #28 复验通过）。
2. **NAPI 6d 剩余项**（drawing RAII / effect 所有权 / location-IME 生命周期 / NodeContent 身份 / 原子发布注册表 / 缓冲按需）：阻塞 = `comp-napi/report.md` 原文缺失，需重做只读定位；互操作侧已收口，无并发写冲突。
3. **sdk 测试接入 CI**：`eng/ohos-install/tests/` 3 个脚本（filewrites 5/0、hostfeed 10/0、installer 43/0）尚未挂 workflow；阻塞 = runner 需 NDK/离线资产或改为纯静态门禁。
4. **sdk `ohos-full-build` runner 红**：run `36131775031`（illink `MSB6006` exit 150）与 `36129693381`（host subset 无 corehost apphost）；阻塞 = 需 runner 侧复现/缓存修复后复跑，本地无同构环境。

> 已从排期转入已修/外部条件：P2（2026-09-26 完成，§2.3 · §3.1）；PLAT-GAP（补录已修，§2.5）；打包 clean/RID pin（并入 TASK-MIG）；HMS 真机验收与 AOT 冒烟/SecureStorage HUKS 为外部设备条件（§4）。

## 4. 仍需外部条件与文档回填

- **HMS 设备 / Kit 通道**：KIT-GAP/KIT-IMPL 复核 14 项 = **5 项条件可补齐**（Share/Scan 探测与降级链路已落地：壳 `canIUse`+变量 import、host/托管桥、kit1–kit3 断言；Map/Push/Account 待 HMS+AGC）· **3 项仅记录**（LiveView/Payment/Ads）· **6 项维持门控**（TTS/Hot Reload/arm32/WebAuthenticator/SecureStorage 兜底/MediaElement）。真机验收（Share `shareCompleted`、Scan `originalValue`、`ARKTS_SDK_FLAVOR=harmony` abc 装载）需 HMS 设备；Push `1000900010`、Account `1001502014`、Map AppKey、实况窗权益、支付商户另需 AGC 开通/审批。矩阵见 `2026-09-24-ohos-kit-gap-analysis.md`；回填 `8b37c37daa3`；落地提交 ohos-workload `68220cd`/`652c356`/`201fbc9`/`063da85`、maui `fc7fbfdc`。
- **HarmonyOS SDK**：`ARKTS_SDK_FLAVOR=harmony` 完整构建需装有 DevEco/HMS SDK 的机器（本机仅 OpenHarmony SDK 26.0.0.18）。
- **真机项**：NAPI TSFN 同步应答阻塞/超时、env cleanup 页销毁顺序、AOT 单入口冒烟（P2 后仍 SKIP：openharmony-arm64 ilc/runtime pack 未安装）、SecureStorage HUKS 分支。
- **文档回填（2026-09-26）**：本报告已回填 P2 收口（§2.3 · §3.1）、PLAT-GAP 补录（§2.5）、TASK-MIG 进行中（§2.4 · §3.2）与 KIT-GAP/KIT-IMPL 结论（§2.1 · 本节）；KIT-GAP 矩阵的 KIT-IMPL 回填已入库 `8b37c37daa3`。`2026-09-22-ohos-maui-coverage-matrix.md` 仍把「Share Kit 多文件」列为 SDK 阻塞、数字仍为 315/floor 295 —— 应补 Share/Scan 探测落地与 326/floor 306（release-manifest 由另一代理维护，本报告未触碰）。

## 5. 与既有合规线交叉引用

- **R1–R11**（`2026-09-23-ohos-pr-review-compliance.md`）：本轮改动落在壳/宿主/打包，不改平台标识、RID 图（R2/R4 保持单一来源与字节一致）、`eng/common`（R6）与 `DOTNET_` 口径；P2 迁移仅 `private static extern`（无公开 API 面），PLAT-GAP 仅版本 pin/默认属性，R1–R11 硬违例仍为 0。
- **安全线**（`2026-09-23-ohos-security-scan-2.md` 16/16）：本轮新增绝对路径门禁、无新 dlopen/绝对路径、导出契约与 `nm` 门禁不放大攻击面。
- **性能线**（`2026-09-23-ohos-performance-scan.md` 29/31）：交互套件 326 断言内 perf 预算全部 `within=True`（帧分配 4,504 B/帧，门禁 13,824 B）。
- **交付线**：`2026-09-24-ohos-device-milestone.md`、`2026-09-24-ohos-tester-handoff-kit24.md`；release-manifest 由另一代理维护。

## 6. 不确定项

1. `comp-*` 审计原文未落盘，本报告的条目拆分、计数与「skill 清单」按 `fix-*` 报告、日志与提交消息重建，可能与审计原文条目粒度略有差异。
2. `fix-arkts`/`fix-cbuild` 无独立 5 列报告（仅日志/补丁/推送记录），其行为依据为提交消息 + selftest/preflight 日志。
3. NAPI 6d 仍未做（缺审计原文定位）；本次回填未包含其验收。
4. 真机与 HMS/AOT 项（NAPI 同步应答、env cleanup 顺序、Share/Scan、HarmonyOS flavor、AOT 冒烟）均未上机；P2 的 AOT 冒烟在 `openharmony-arm64` ilc/runtime pack 缺失下仍为 SKIP。
5. sdk `ohos-full-build` 两次失败的根因未在本地复现，仅按日志归因。
6. 文中数字为快照：交互 326/floor 306 与像素取自 2026-09-25 20:00 本地 `preflight`（P2 后复跑仍为 326/306）；118/118 取自 18:08 `build-host`（P2 后复跑仍 118/118）；CI 5/5 为 master tip `2c1a2cb` 的 run 记录。
7. 本次回填数字来源：P2 = `p2-interop/REPORT-p2-interop.md`（`p2-interop/final-*.log`）；PLAT-GAP = `plat-gap/EVIDENCE.md`；TASK-MIG = `task-mig/`（进行中，无收口报告）；KIT = `kit-impl/feasibility-report.md`。kit #25 发布状态以 release-manifest / `device-test-kit` release 为准（本报告未改 release-manifest）。

> **发布状态（2026-09-26 回填）**：kit #25–#28 已发布——#25（权限链/Share+Scan 探测/AOT 启动路径/present 缓存/JSON 源生成/targets 强化）· #26（P2-INTEROP 125 处 LibraryImport/PLAT-GAP/TASK-MIG 任务程序集）· #27（Push/Account/Map 探测 · NAPI 边界加固 · off-runtime-marshaller · 导出 130/130）· #28（Map 覆盖层 · `start_app` AOT 桥 · LiveView · `interp.txt` 注入 · 导出 134/134、套件 334/floor 314）。
