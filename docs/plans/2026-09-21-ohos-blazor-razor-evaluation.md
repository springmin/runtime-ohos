# 演示工程 `.razor` 变体评估（W1/V5，2026-09-21）

> 评估对象：`ohos-workload/test/hello-maui-app`（S1/T5 演示）的 **scratch 副本**。
> 变更内容：`Microsoft.NET.Sdk` → `Microsoft.NET.Sdk.Razor`，内联 `BlazorCounter.cs`
> （`ComponentBase`/`RenderTreeBuilder`）→ `BlazorCounter.razor`。
> 评估问题：静态 Web 资产管线是否改变"暂存 `wwwroot/**` 恰好 4 条"的载荷不变量；
> hap 暂存目标（`_OpenHarmonyStageBlazorAssets`）是否仍正确复制内容根。
> 约束：**真实演示、maui-ohos 切片、harness、脚本与两个仓库均未改动**；所有 publish/pack/sign
> 只在 scratch 副本内执行，真实演示仅只读引用。本文兑现审计 §38 待办第 1 条（V5）。
>
> **结论先行**：直接切 SDK 会**构建失败**（app 自带 `_framework/blazor.modules.json` 与
> WebView 包的 fallback 资产同路由冲突）；删除该重复文件后 publish/pack/sign 成功
> （`verify-app success`），`wwwroot/**` 仍是**恰好 4 条**（3 条字节一致，`blazor.modules.json`
> 由 `[]\n` 变为 `[]\r\n`），但 `dotnet.zip` 整体多出 **6 条**根级条目（Razor/Web SDK 默认
> Content 语义）。建议：**demo 默认保持 inline**；`.razor` 以独立 opt-in 工程（或等价开关）采纳，
> 并同步处理 `blazor.modules.json` 归属与载荷条目清单（见 §5）。

## 1. 背景与范围

审计 §38 记录 V5 为排队项：切 `Microsoft.NET.Sdk.Razor` 会激活静态 web 资产管线，有改变
"4 条 wwwroot"不变量之险，故先加开关 + 独立工程验证再评估。本文即该独立验证：

- 在 `/data/storage/el2/base/tmp/opencode/w1-razor/` 建立 demo 的 scratch 副本（不含 `bin/obj`），
  只替换 SDK 与组件写法；
- 依次尝试 **直接切换**（保留 app 自带 `wwwroot/_framework/blazor.modules.json`）与
  **适配后切换**（移除该重复文件），记录失败/成功日志；
- 用 `-p:OpenHarmonyHapPackage=true` 走完整 publish → hap 暂存 → 打包 → 签名链；
- 用 python `zipfile` 打开 hap 的 `resources/rawfile/dotnet.zip`，对比条目清单与逐文件 sha256。

版本环境（全部为当时实测）：

| 项 | 值 |
|---|---|
| SDK | `11.0.100-rc.1.26451.109`（`~/.dotnet`） |
| workload 清单 | `ohos-workload` `1.0.0-preview.24`（`d99580f`，经 `DOTNETSDK_WORKLOAD_*_ROOTS` 指向本地 packs） |
| `Microsoft.AspNetCore.Components.WebView` | `11.0.0-preview.7.26381.103` |
| `Microsoft.AspNetCore.Components.WebView.Maui` | `11.0.0-rc.1.26451.6` |
| TFM / RID | `net11.0-openharmony26.0`（publish+hap）、`net11.0-openharmony20.0`（build 对照）/ `openharmony-arm64` |
| 文档基线 | runtime-ohos `feature/openharmony` `bc3f3b58b02`；ohos-workload `master` `d99580f` |

## 2. 变更内容（仅 scratch）

| 文件 | 变更 |
|---|---|
| `hello-maui-app.csproj` | `Sdk="Microsoft.NET.Sdk"` → `Sdk="Microsoft.NET.Sdk.Razor"`；其余属性/引用/`Compile Include`（切片源码直编）与 `OPENHARMONY_BLAZOR_WEBVIEW` define 原样保留；因 scratch 在 `/data/...`，命令行以绝对路径覆盖 `OpenHarmonyMauiPlatformDir`/`OpenHarmonyHostingDir` 到真实切片与 hosting 输出（只读） |
| `BlazorCounter.cs` | 删除；由 `BlazorCounter.razor` 取代 |
| `BlazorCounter.razor`（新） | `@namespace HelloMauiApp`，等价语义：`<h2>` + `count: @_count` + `<button @onclick="Increment">`；`App.cs` 的 `typeof(BlazorCounter)` 不需改动 |
| `App.cs` | 只更新注释（说明 .razor 变体）；代码不变 |
| `wwwroot/` | 直接切换时保留全部 3 个文件；适配后移除 `_framework/blazor.modules.json`（2 个文件） |

publish 命令（scratch 内执行，日志见 §6）：

```sh
W=/storage/Users/currentUser/springsources/ohos-workload
MAUI_OHOS=/storage/Users/currentUser/springsources/maui-ohos
DOTNETSDK_WORKLOAD_MANIFEST_ROOTS=$W/manifests DOTNETSDK_WORKLOAD_PACK_ROOTS=$W/packs \
  ~/.dotnet/dotnet publish -c Release -f net11.0-openharmony26.0 -r openharmony-arm64 \
    -p:OpenHarmonyUIPage=pages/Index \
    -p:OpenHarmonyArktsModulesAbc=$W/dist/ets/modules.abc \
    -p:OpenHarmonyHapPackage=true \
    -p:OpenHarmonyMauiPlatformDir=$MAUI_OHOS/src/Core/src/Platform/OpenHarmony \
    -p:OpenHarmonyHostingDir=$W/src
```

## 3. 实测结果

### 3.1 直接切换（保留 app 自带 `blazor.modules.json`）→ 构建失败

`dotnet publish` 在静态 web 资产解析阶段硬失败，未产生 hap（`PUBLISH-EXIT=1`）：

```
Microsoft.NET.Sdk.StaticWebAssets.targets(699,5): error : Conflicting assets with the same target
path '_framework/blazor.modules.json'. ... 'Identity: <scratch>/wwwroot/_framework/blazor.modules.json,
SourceType: Discovered, ..., FileLength: 3, Fingerprint: l5stv3hc74, ...' and 'Identity:
~/.nuget/packages/microsoft.aspnetcore.components.webview/11.0.0-preview.7.26381.103/build/blazor.modules.json,
SourceType: Discovered, ..., FileLength: 4, Fingerprint: 79h83ocrro, ...'.
```

机制（包内源码）：`Microsoft.AspNetCore.Components.WebView` 的
`build/StaticWebAssets.Groups.targets` 用 `_AddBlazorWebViewModulesFallback` 在
`@(_ExistingBuildJSModules)` 为空时注入 `[]` fallback，路由 `_framework/blazor.modules.json`。
demo 手放的 `wwwroot/_framework/blazor.modules.json` 只是普通内容文件，不算
`_ExistingBuildJSModules`，因此两者同时声明同一路由 → 冲突。inline 配置下静态 web 资产管线
不运行，所以一直没暴露；切 SDK 必现。

### 3.2 适配后切换（移除重复的 `blazor.modules.json`）→ 全链成功

删除 app 自带的 `wwwroot/_framework/blazor.modules.json`，让包 fallback 拥有该路由后：

- `PUBLISH-EXIT=0`；pack 输出 `hello-maui-app-unsigned.hap`；
- 签名工具输出 **`verify-app success`**（`sign-profile success` / `sign-app success`）；
- 日志片段：`OpenHarmony: staged the Blazor content root (wwwroot) and _framework/blazor.webview.js
  into .../publish/wwwroot` → `OpenHarmony: staged .hap payload at obj/.../openharmony-hap/`；
- `net11.0-openharmony20.0` 对照构建 **0 error**（`BUILD20-EXIT=0`，62 warnings 均为既有
  obsolete/nullable 警告），说明适配不依赖 API 波段；
- `.razor` 编译成功：`hello-maui-app.dll`（302080 B）元数据含 `BlazorCounter` 类型；
  Razor 源生成器来自 SDK，无额外包引用。

### 3.3 载荷条目清单 before / after

before = 真实 demo hap（inline，2026-09-21 12:08 构建，12:19 提取）；after = scratch 适配后
hap（12:29 构建）。两者外层 hap 均 9 条（`module.json`、`ets/modules.abc`、
`libs/arm64-v8a/libopenharmonyhost.so`、`resources/**` × 6）。

**`dotnet.zip` 内 `wwwroot/**` —— 不变量成立，恰好 4 条：**

| 条目 | before 大小 | before sha256（前 16） | after 大小 | after sha256（前 16） | 判定 |
|---|---|---|---|---|---|
| `wwwroot/index.html` | 8042 | `26ed71d826f9fad3` | 8042 | `26ed71d826f9fad3` | 字节一致 |
| `wwwroot/js/app.js` | 9450 | `f9758d151275f830` | 9450 | `f9758d151275f830` | 字节一致 |
| `wwwroot/_framework/blazor.webview.js` | 604610 | `713e519fcd217fa2` | 604610 | `713e519fcd217fa2` | 字节一致（同一包文件） |
| `wwwroot/_framework/blazor.modules.json` | 3 | `37517e5f3dc66819` | 4 | `a5338d955b09046e` | `[]\n` → 包 fallback `[]\r\n`，JSON 语义相同 |

- `dotnet.zip` 总条目：**265 → 271（+6）**；sha256：`aba6a1a9…` → `592469d4…`。
- `wwwroot` 之外**零丢失**（before 的 265 个名字全部保留），新增 6 条全部在根级：

| 新增条目 | 大小 | 来源 |
|---|---|---|
| `hello-maui-app.staticwebassets.endpoints.json` | 4469 | SDK 生成的静态 web 资产 publish 端点清单（无绝对路径，路由 + 相对 AssetFile） |
| `module.json` | 983 | 工程根 `module.json` 被 Razor/Web 默认 Content 收录（`CopyToPublishDirectory=PreserveNewest`） |
| `resources/base/element/color.json` | 83 | 同上（`resources/**` 默认 Content 收录） |
| `resources/base/element/string.json` | 263 | 同上 |
| `resources/base/profile/main_pages.json` | 29 | 同上 |
| `resources/rawfile/app.json` | 34 | 同上（`resources/rawfile/dotnet.zip` 因 zip 排除规则**未**被收录） |

归属已用 `msbuild -getItem:Content` 证实：Razor 内层构建的 `Content` 共 7 项 =
`wwwroot/index.html`、`wwwroot/js/app.js` + 上述 5 个 JSON；这正是新增条目的来源
（SDK 生成的 endpoints 清单为另 1 条）。inline 配置下这些文件是 `None`，不进 publish。

**未出现的东西**（同样重要）：publish/`dotnet.zip` 中**没有**指纹副本（如
`blazor.webview.33mr5l0uwg.js`、`index.unsrh2l48p.html`）、**没有** `.gz`/`.br` 压缩替代
（包 `StaticWebAssets.Groups.targets` 设 `CompressionEnabled=false`）、**没有** `_content/**`。
指纹只存在于 SDK 清单/端点的路由表中，落盘仍是规范名文件。静态 web 资产 publish 清单
（`staticwebassets.publish.json`）为 4 资产 + 8 端点（4 规范 + 4 指纹路由）；
`_framework/blazor.webview.js` 来自包 `staticwebassets/`（`SourceType: Package`）。

### 3.4 hap 暂存目标行为

`_OpenHarmonyStageBlazorAssets`（SDK preview.24 的 `OpenHarmony.Hap.targets`）在适配后仍按预期工作：

- 内容根仍取自 `$(MSBuildProjectDirectory)/wwwroot`，`/**/*` 复制到 `publish/wwwroot/`；
- 框架脚本仍被识别：`@(StaticWebAsset)` 中 `blazor.webview.js` 非空，命中
  "staged the Blazor content root (wwwroot) and _framework/blazor.webview.js" 消息，
  落到 `publish/wwwroot/_framework/blazor.webview.js`（该文件即包内
  `staticwebassets/blazor.webview.js`，sha256 与 inline 基线一致；日志无法区分
  `@(StaticWebAsset)` 与 NuGet 缓存两分支，但两者源文件相同）；
- 打包仍以 `publish/` 全量为 `dotnet.zip` 源（确定性 zip 任务未变），因此新 Content 条目
  一并进入载荷——这不是暂存目标的缺陷，而是 publish 输出本身变大；
- 20.0/26.0 两个 TFM 都能得到同构结果（20.0 只做了 build 对照，未打包）。

真实演示在本次评估期间（12:25）被**其他 agent** 重建过一次；其 `dotnet.zip` 条目集合与
`wwwroot` 4 条逐字节与 12:19 快照一致（`hello-maui-app.dll/.pdb` 因引用程序集并发重建
而变化，与本变体无关）。即 before 快照仍可代表 inline 基线。

## 4. 风险与影响

1. **必现的构建冲突（高）**：demo 现带 `wwwroot/_framework/blazor.modules.json`，
   直接切 Razor 会 `error : Conflicting assets with the same target path`，不产生 hap。
   采纳变体必须同步二选一：
   (a) 移除该文件、由 WebView 包 fallback 提供（本次验证路径，publish/pack/sign 全链通过）；或
   (b) 保留该文件并抑制 fallback（本次做了 26.0 build 级验证：`BUILD-ALT-EXIT=0`，0 error；
   未走 publish/hap，见 §6）。
2. **载荷不变量只在 `wwwroot/**` 子集成立（中）**：整体 `dotnet.zip` 265 → 271，新增 6 条
   根级文件。按 V5 的原始表述"4 条 wwwroot"不变量成立；若把不变量定义为"载荷逐条不变"，
   则不成立。`module.json`/`resources/**` 的副本只是暂存元数据，运行时从 hap 自身读取，
   落在 `AppDir` 根目录不参与 wwwroot 服务，功能风险低，但改变了交付物清单与体积。
3. **SDK 生成的端点清单进入载荷（中）**：`*.staticwebassets.endpoints.json` 的 schema/内容
   与 SDK 版本绑定，且是新的常驻文件；本次实测其不含绝对路径。若要求载荷最小化，需要显式
   `Content Remove`/`None`（本次未实现，见 §5 建议）。
4. **指纹路由未在设备验证（中）**：清单暴露 `index.unsrh2l48p.html` 等指纹路由，靠 T6
   `name.<hash>.ext → name.ext` 回退命中；落盘无指纹文件。ArkWeb 下行为未测。
5. **确定的指纹命名会随内容变化（低）**：指纹基于文件内容，改 `index.html`/`app.js` 会改变
   端点清单内容 → 载荷哈希变化；对"相同输入同输出"的确定性无影响（未复跑对照，见 §7）。
6. **默认 Content 语义扩散（低）**：切 Razor 后工程内所有 `*.json`（默认排除项之外）会进入
   publish。本 demo 只有暂存元数据；未来加 `appsettings.json` 等也会被发布（Web 工程属预期
   行为，但与本移植工程的 hap 载荷约定需对齐）。
7. **运行时等价性未证（中）**：`@onclick` 与手写 `EventCallback.Factory.Create` 生成的语义
   相同，编译与载荷已验证；但设备侧 `Blazor.start()`/点击回传与此前 S1/T5 一样仍受设备通道
   阻塞（审计 §38 不确定项），本次未新增设备证据。
8. **多目标 outer build（低）**：`Microsoft.AspNetCore.Components.WebView.Maui.props` 对
   outer build 关 `StaticWebAssetsEnabled`，内层才跑管线；26.0 publish 与 20.0 build 均通过。

## 5. 建议

**默认保持 inline**：inline 配置已在设备链路上验证过 S1/T5，且不引入任何载荷变化；
`.razor` 的收益只是作者体验，不足以承担内容根契约与载荷清单变化。

若确要采纳，建议**独立 opt-in 工程 + 开关**，而不是改 demo 默认：

1. **独立工程**：新增（例如）`hello-maui-app.razor.csproj`（`Sdk="Microsoft.NET.Sdk.Razor"`），
   链接/共享 `App.cs`、`Program.cs`、`BlazorCounter.razor` 与现有引用配置，保持默认
   `hello-maui-app.csproj` 完全不变——满足"默认构建不变 + 可切换验证"。注意 `<Project Sdk>`
   在求值时固定，单工程内无法用属性切换 SDK，开关的落地形态只能是独立 csproj（或双工程共享 props）。
2. **`blazor.modules.json` 归属随开关切换**：inline 工程保留 app 自带文件（暂存目标需要）；
   Razor 工程移除它，由 `Microsoft.AspNetCore.Components.WebView` fallback 提供。
3. **载荷清单显式化**：Razor 工程里对 `module.json`、`resources/**` 做 `Content Remove`
   或 `None`（若要求根条目与 inline 完全一致），并接受/记录
   `*.staticwebassets.endpoints.json`（如必须剔除，可在 `_OpenHarmonyStageHap` 前加一条
   Remove 或 `Content Remove`——未验证）。
4. **加一条载荷门禁**：对产物 hap 执行 `wwwroot/** == 4 条 + 规范名 + 无 .gz/.br/指纹副本`
   的断言（可复用本次 §3.3 的 python 检查），两个变体都跑。
5. **设备复验**：`.razor` 变体至少跑一次 S1/T5 的真机渲染与点击回传；在此之前不建议把它
   作为任何交付 hap 的默认。

## 6. 证据与复现

scratch（仅本机临时目录，未入库）：

- 适配后工程：`/data/storage/el2/base/tmp/opencode/w1-razor/hello-maui-app/`
  （`BlazorCounter.razor`、Razor SDK 的 csproj、`run-publish.sh`/`run-publish-v2.sh`）；
- 抑制 fallback 的备选工程：`/data/storage/el2/base/tmp/opencode/w1-razor/hello-maui-app-alt/`
  （`_SuppressBlazorWebViewModulesFallback` 目标注入 `_ExistingBuildJSModules`）；
- 证据目录：`/data/storage/el2/base/tmp/opencode/w1-razor/evidence/`
  - `before-inline-dotnet.zip`（`aba6a1a9…`）+ `before-inline-dotnetzip-entries.txt`（265 条）；
  - `publish-razor-attempt1-conflict.log`（直接切换的冲突错误全文）；
  - `publish-razor-v2.log`（适配后 publish/pack/sign，含 `verify-app success`）；
  - `after-razor-v2-dotnet.zip`（`592469d4…`）+ `after-razor-v2-dotnetzip-entries.txt`（271 条）；
  - `build-razor-20.log`（API 20 build 对照，0 error）；
  - `build-razor-alt-suppress.log`（备选 (b) 的 build 验证）。

复现要点：把 §2 的 csproj/组件改动复制到任一 demo 副本，运行 §2 的命令，然后：

```python
import zipfile, io
hz = zipfile.ZipFile("hello-maui-app.hap")
inner = zipfile.ZipFile(io.BytesIO(hz.read("resources/rawfile/dotnet.zip")))
www = sorted(n for n in inner.namelist() if n.startswith("wwwroot/"))
assert len(www) == 4, www
assert not any(".br" in n or ".gz" in n for n in inner.namelist())
```

## 7. 不确定项

1. **未复跑确定性对照**：没有对同一 Razor 配置 publish 两次比较 `dotnet.zip` 逐字节；
   确定性 zip 任务未变、新增内容来源可解释，但"两次一致"未实测。
2. **备选 (b)（保留 app 文件 + 抑制 fallback）只做了 build 级验证**：26.0 `dotnet build`
   0 error；未走 publish/hap，若选用该方案需补一条完整打包证据。
3. **未实现载荷"减重"**（剔除 endpoints 清单/暂存 JSON）——仅给出建议，未验证 Remove 写法。
4. **设备侧未验证**：`.razor` 编译产物的真机渲染/点击回传、指纹路由回退行为，均受设备通道
   阻塞（与审计 §38 的 S1/T5 不确定项同源）。
5. **其他 agent 并发扰动**：评估窗口内真实 demo 被重建（12:25）、ohos-workload 的 host/脚本
   有多处他人改动；本文只比较 `wwwroot` 4 条（逐字节一致）与条目集合（一致），
   未把 `hello-maui-app.dll/.pdb` 等内容差异归因于本变体。
