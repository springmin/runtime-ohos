# 可选 `.razor` 工程（X4，2026-09-21）

> 兑现 W1 评估 `2026-09-21-ohos-blazor-razor-evaluation.md`：把 `.razor` 变体落成**独立 opt-in 工程**
> `ohos-workload/test/hello-maui-razor/`（§5 建议 1），demo 默认保持 inline；同时复跑 W1 §7
> 不确定项 1 的载荷确定性对照。
> 变更范围：ohos-workload 新增一个目录，runtime-ohos 新增本文；demo、脚本、harness 与既有文档
> 均未改动（demo `git status` clean，脚本无本工程引用）。
>
> **结论先行**：26.0 `publish -p:OpenHarmonyHapPackage=true` 全链成功（`verify-app success`）；
> 暂存 `wwwroot/**` **恰好 4 条**；`dotnet.zip` **271 条**，相对 inline 基线新增 **6 条**根级条目，
> 与 W1 "after" 形状一致（仅程序集名 `hello-maui-app.* → hello-maui-razor.*` 4 条随工程名改名）；
> API 20 build 对照 **0 error**；固定提交下两次 publish 的 `dotnet.zip` **逐字节一致**
> （W1 不确定项 1 关闭）。

## 1. 工程角色与内容

W1 的结论是 demo 默认保持 inline：`<Project Sdk>` 在求值时固定，单工程内无法用属性切换 SDK，
所以 opt-in 的唯一落地形态是独立 csproj。本工程即该独立工程，与 demo 的关系：

| 项 | demo `test/hello-maui-app` | 本工程 `test/hello-maui-razor` |
|---|---|---|
| 角色 | 默认交付/设备链路（inline） | opt-in `.razor` 验证路径（手动发布，无脚本引用） |
| SDK | `Microsoft.NET.Sdk` | `Microsoft.NET.Sdk.Razor` |
| 组件 | `BlazorCounter.cs`（`ComponentBase`/`RenderTreeBuilder`） | `BlazorCounter.razor` |
| `wwwroot/_framework/blazor.modules.json` | app 自带（`[]\n`） | 不提供；包 `_AddBlazorWebViewModulesFallback` 提供（`[]\r\n`） |
| TFM / RID | `net11.0-openharmony20.0;net11.0-openharmony26.0` / `openharmony-arm64` | 同左 |
| 引用/切片 | `Microsoft.AspNetCore.Components.WebView.Maui` 11.0.0-rc.1.26451.6；`OPENHARMONY_BLAZOR_WEBVIEW` + 直编 `maui-ohos` 切片 `*.cs` | 同左（csproj 逐项一致） |

本工程是最小应用：一个 `ContentPage` 承载一个 `BlazorWebView`（`HostPage = wwwroot/index.html`，
`RootComponent { Selector = "#app", ComponentType = typeof(BlazorCounter) }`），`Program.cs` 是
与 demo 相同的 bridge 入口（`UseOpenHarmony` +
`AddMauiBlazorWebView().UsePlatformHandler<OpenHarmonyBlazorWebViewHandler>()`）。

文件清单：

| 文件 | 说明 |
|---|---|
| `hello-maui-razor.csproj` | Razor SDK；TFM/包引用/切片编译与 demo 相同；不引用 demo 的任何文件 |
| `Program.cs` | bridge 入口；handler 注册同 demo |
| `App.cs` | 最小 `Application`：单页、单 `BlazorWebView` |
| `BlazorCounter.razor` | 计数器（`@namespace HelloMauiRazor`），语义等价 inline 组件 |
| `wwwroot/index.html` | 宿主页（`#app` 挂载点；注释说明为何不手放 `modules.json`） |
| `wwwroot/js/app.js` | 小脚本：只报告 shell bridge 注入状态（不是 demo 的完整探针页） |
| `module.json`、`resources/**.json` | 与 demo 相同的暂存元数据 fixture，仅为让载荷条目清单可与 W1 "after" 逐条对照；inline 配置下不进 publish |

设计约束（来自 W1 §3.1）：Razor SDK 下静态 web 资产管线会运行，`Microsoft.AspNetCore.Components.WebView`
的 fallback 声明 `_framework/blazor.modules.json` 路由；app 自带同名文件会硬失败
（`Conflicting assets with the same target path`），因此本工程**不**提供该文件。

## 2. publish 命令

```sh
W=/storage/Users/currentUser/springsources/ohos-workload
DOTNETSDK_WORKLOAD_MANIFEST_ROOTS=$W/manifests DOTNETSDK_WORKLOAD_PACK_ROOTS=$W/packs \
  "$HOME/.dotnet/dotnet" publish "$W/test/hello-maui-razor/hello-maui-razor.csproj" \
    -c Release -f net11.0-openharmony26.0 -r openharmony-arm64 -m:1 \
    -p:OpenHarmonyUIPage=pages/Index \
    -p:OpenHarmonyArktsModulesAbc="$W/dist/ets/modules.abc" \
    -p:OpenHarmonyHapPackage=true
```

环境（实测）：SDK `11.0.100-rc.1.26451.109`（`~/.dotnet`）、workload `1.0.0-preview.24`
（manifest/pack roots 指向本地 checkout）、`Microsoft.AspNetCore.Components.WebView.Maui`
`11.0.0-rc.1.26451.6`、`Microsoft.AspNetCore.Components.WebView` `11.0.0-preview.7.26381.103`。

## 3. 实测结果

### 3.1 publish / 打包 / 签名

- `PUBLISH-EXIT=0`；
- `OpenHarmony: staged the Blazor content root (wwwroot) and _framework/blazor.webview.js into .../publish/wwwroot`；
- `OpenHarmony: staged .hap payload at .../obj/Release/net11.0-openharmony26.0/openharmony-arm64/openharmony-hap/`；
- `OpenHarmony: packed .../hello-maui-razor-unsigned.hap` → `sign-profile success` → `sign-app success`
  → **`verify-app success`** → `OpenHarmony: signed .../hello-maui-razor.hap`（22 575 105 B）；
- `net11.0-openharmony20.0` build 对照：`BUILD20-EXIT=0`，**0 error**（54 warnings 全为切片既有
  obsolete/nullable 警告，与 W1 的 62 条同类）。

### 3.2 外层 hap（9 条）

与 W1 的 before/after 外层结构一致：

```
ets/modules.abc
libs/arm64-v8a/libopenharmonyhost.so
module.json
resources/base/element/color.json
resources/base/element/string.json
resources/base/media/app_icon.png
resources/base/profile/main_pages.json
resources/rawfile/app.json
resources/rawfile/dotnet.zip
```

### 3.3 暂存 `wwwroot/**`（不变量成立：恰好 4 条）

`dotnet.zip` 内 `wwwroot/**` 逐条（python `zipfile` 提取）：

| 条目 | X4 大小 | X4 sha256 | W1 after | 判定 |
|---|---|---|---|---|
| `wwwroot/index.html` | 2212 | `c487766b1391bea971154589a1fd0785575adfbc74c2d9e2258e03a184ca05bb` | 8042 / `26ed71d8…` | 本工程最小宿主页，内容不同（预期） |
| `wwwroot/js/app.js` | 1231 | `569a5a6433319d72650e179aee2729ffbf17e2953796072aec233537cfaf6bca` | 9450 / `f9758d15…` | 本工程最小脚本，内容不同（预期） |
| `wwwroot/_framework/blazor.modules.json` | 4 | `a5338d955b09046ec0b16f3a9625b7955c763aae07dc722e474e6078745f932f` | 4 / `a5338d95…` | **字节一致**（包 fallback，`[]\r\n`） |
| `wwwroot/_framework/blazor.webview.js` | 604610 | `713e519fcd217fa2ca56e8307a166ae89bb296008fd18f2b79f65daeaa7ae1aa` | 604610 / `713e519f…` | **字节一致**（同一包文件） |

同样未出现指纹副本、`.br`/`.gz` 压缩替代与 `_content/**`（与 W1 §3.3 一致）。

### 3.4 `dotnet.zip` 271 条与 delta

- 总条目：**271**（W1 after 也是 271）；`dotnet.zip` sha256（提交 `4412b5b` 下）
  `827603fe4371408e42949277a43ec90e9721e672a82b2792b2e4c041c749bd37`，22 316 722 B；
- 相对 W1 **inline 基线**（265 条）：新增 6 条根级条目 + 3 条随工程名改名，**零丢失**：

| 新增条目 | 大小 | 来源 | W1 after 对应 |
|---|---|---|---|
| `hello-maui-razor.staticwebassets.endpoints.json` | 4469 | SDK 生成的静态 web 资产 publish 端点清单 | `hello-maui-app.staticwebassets.endpoints.json`（4469） |
| `module.json` | 985 | 工程根 fixture 被 Razor 默认 Content 收录 | `module.json`（983；bundleName 改为 `com.example.hello-maui-razor`） |
| `resources/base/element/color.json` | 83 | 同上 | 同（83） |
| `resources/base/element/string.json` | 271 | 同上（app 名改为 `hello-maui-razor`） | `resources/base/element/string.json`（263） |
| `resources/base/profile/main_pages.json` | 29 | 同上 | 同（29） |
| `resources/rawfile/app.json` | 36 | 同上（`assembly` = `hello-maui-razor.dll`） | `resources/rawfile/app.json`（34） |

| 改名条目（3 条，inline 基线 → X4） |
|---|
| `hello-maui-app.dll` → `hello-maui-razor.dll` |
| `hello-maui-app.pdb` → `hello-maui-razor.pdb` |
| `hello-maui-app.runtimeconfig.json` → `hello-maui-razor.runtimeconfig.json` |

- 相对 W1 **after 条目清单**：差异**只有**上表 4 条改名（`hello-maui-razor.*` 取代
  `hello-maui-app.*`）；其余 267 条名字完全一致。即 X4 的 `dotnet.zip` 与 W1 after 是同一个形状；
- `staticwebassets.publish.json` 同样是 **4 资产 + 8 端点**（4 规范 + 4 指纹路由），
  payload 端点清单无绝对路径（`b"/storage/Users" in endpoints == False`）。

### 3.5 载荷确定性（W1 §7 不确定项 1）

同一工程连续 publish 三次（同一命令）：

| 运行 | 时间 | HEAD commit | 结果 | 暂存 `dotnet.zip` sha256 |
|---|---|---|---|---|
| run1 | 13:44 | `6dbd725`（13:43:18 提交） | `PUBLISH-EXIT=0`，`verify-app success` | `92c0fa9b576df8d141c46416b05b385913533c0481d6844a52b6b68fa1d9ff59` |
| run2 | ~13:49 | `4412b5b`（13:46:32 提交） | pack 阶段遇环境 fork 失败（MSB6003，见 §6），暂存 zip 已完成 | `827603fe4371408e42949277a43ec90e9721e672a82b2792b2e4c041c749bd37` |
| run3 | 13:51 | `4412b5b` | `PUBLISH-EXIT=0`，`verify-app success` | `827603fe4371408e42949277a43ec90e9721e672a82b2792b2e4c041c749bd37` |

- run1 vs run2 的 `dotnet.zip` 逐条对比：271 条名字相同，**只有 `hello-maui-razor.dll` 与
  `.pdb` 内容不同**（大小同为 292352 / 260464 B）。原因是 .NET SDK 默认
  `IncludeSourceRevisionInInformationalVersion`，程序集里是 `1.0.0+6dbd72519b7e49ad…` vs
  `1.0.0+4412b5b4fadadd89…`（两次 publish 之间**其他 agent 提交了** ohos-workload）；
- run2 与 run3 在同一提交 `4412b5b` 下，暂存 `dotnet.zip` **逐字节一致**
  （`827603fe…`）。即：**固定输入 + 固定提交时载荷确定**；跨提交时只有 app 程序集（及其 PDB）
  随 `SourceRevisionId` 变化。这也解释了 W1 §3.4 观察到的 `.dll/.pdb` 漂移；
- hap 本体哈希不具可比性：签名嵌入时间戳，run1 `a3c6ba61…`、run3 `23401d97…`。

## 4. 与 W1 建议的对应

| W1 §5 建议 | 本文状态 |
|---|---|
| 1. 独立 opt-in 工程（不改 demo 默认） | ✅ `test/hello-maui-razor`（独立 csproj，不共享 demo 文件） |
| 2. `blazor.modules.json` 归属随开关切换 | ✅ Razor 侧不提供，由包 fallback 拥有（`[]\r\n`，与 W1 after 字节一致） |
| 3. 载荷清单显式化（Content Remove 减重） | ⛔ 未做：本工程刻意保留与 W1 after 相同的 6 条新增，以便形状可比对；如需减重见 §6 |
| 4. 载荷门禁（`wwwroot/** == 4` + 规范名 + 无 `.gz`/`.br`/指纹） | ✅ 本次用 python `zipfile` 检查（§3.3）；本工程可在 CI 中复用 |
| 5. 设备复验（S1/T5 渲染与点击回传） | ⛔ 仍受设备通道阻塞，与 W1/审计 §38 同源 |

## 5. 复现与证据

复现：创建/使用 `ohos-workload/test/hello-maui-razor/`，按 §2 的命令 publish，然后：

```python
import zipfile, io
hz = zipfile.ZipFile("hello-maui-razor.hap")
inner = zipfile.ZipFile(io.BytesIO(hz.read("resources/rawfile/dotnet.zip")))
www = sorted(n for n in inner.namelist() if n.startswith("wwwroot/"))
assert len(www) == 4, www
assert not any(n.endswith((".br", ".gz")) for n in inner.namelist())
assert not any(n.startswith("_content/") for n in inner.namelist())
```

证据（本机临时目录，未入库）：

- `/data/storage/el2/base/tmp/opencode/x4-razor/publish.log`（run1，含全部关键行与 `PUBLISH-EXIT=0`）；
- `publish-run2.log`、`publish-run3.log`（确定性与重试）、`build-20.log`（API 20 对照）；
- `final-dotnet.zip`、`final-dotnetzip-entries.txt`（271 条）、`final-outer-entries.txt`（9 条）、
  `final-hap.hap`、`first-hap.hap`、`run2-dotnet.zip`、`x4-razor-evidence.txt`。

## 6. 不确定项

1. **设备侧未验证**：`BlazorCounter.razor` 的真机渲染/点击回传、指纹路由回退行为未测（与 W1 §7.4 同源）；
2. **载荷仍是 +6**：本工程保持与 W1 after 相同的根级条目（`module.json`、`resources/**.json`、
   endpoints 清单），未做 W1 §5 建议 3 的 `Content Remove` 减重；若未来要求"根条目与 inline 一致"，
   可在此工程上实现并复测；
3. **未接入任何脚本/CI**：preflight、kit、verify-kit 均只引用 demo；本工程为手动 opt-in 发布；
4. **run2 的失败是环境性的**：`_OpenHarmonyPackHap` 启动 `sh` 时 `MSB6003 … Resource temporarily
   unavailable`（fork EAGAIN，与并发负载有关），同提交的 run3 重试成功；不影响 run1/run3 的结论；
5. **fixture JSON 的内容随工程名适配**（bundleName/assembly/app 名），与 W1 after 同名但字节不同
   （983 → 985、263 → 271、34 → 36 B），属预期。

## 附录 A：`dotnet.zip` 完整条目清单（271 条，提交 `4412b5b`，run3）

```
Microsoft.AspNetCore.Authorization.dll
Microsoft.AspNetCore.Components.Forms.dll
Microsoft.AspNetCore.Components.Web.dll
Microsoft.AspNetCore.Components.WebView.Maui.dll
Microsoft.AspNetCore.Components.WebView.dll
Microsoft.AspNetCore.Components.dll
Microsoft.AspNetCore.Metadata.dll
Microsoft.CSharp.dll
Microsoft.Extensions.Caching.Abstractions.dll
Microsoft.Extensions.Configuration.Abstractions.dll
Microsoft.Extensions.Configuration.Binder.dll
Microsoft.Extensions.Configuration.FileExtensions.dll
Microsoft.Extensions.Configuration.Json.dll
Microsoft.Extensions.Configuration.dll
Microsoft.Extensions.DependencyInjection.Abstractions.dll
Microsoft.Extensions.DependencyInjection.dll
Microsoft.Extensions.Diagnostics.Abstractions.dll
Microsoft.Extensions.Diagnostics.dll
Microsoft.Extensions.FileProviders.Abstractions.dll
Microsoft.Extensions.FileProviders.Composite.dll
Microsoft.Extensions.FileProviders.Embedded.dll
Microsoft.Extensions.FileProviders.Physical.dll
Microsoft.Extensions.FileSystemGlobbing.dll
Microsoft.Extensions.Hosting.Abstractions.dll
Microsoft.Extensions.Localization.Abstractions.dll
Microsoft.Extensions.Logging.Abstractions.dll
Microsoft.Extensions.Logging.dll
Microsoft.Extensions.Options.ConfigurationExtensions.dll
Microsoft.Extensions.Options.dll
Microsoft.Extensions.Primitives.dll
Microsoft.Extensions.Validation.dll
Microsoft.JSInterop.dll
Microsoft.Maui.Controls.Xaml.dll
Microsoft.Maui.Controls.dll
Microsoft.Maui.Essentials.dll
Microsoft.Maui.Graphics.dll
Microsoft.Maui.dll
Microsoft.OpenHarmony.Hosting.dll
Microsoft.OpenHarmony.Maui.Graphics.dll
Microsoft.OpenHarmony.dll
Microsoft.VisualBasic.Core.dll
Microsoft.VisualBasic.dll
Microsoft.Win32.Primitives.dll
Microsoft.Win32.Registry.dll
System.AppContext.dll
System.Buffers.dll
System.Collections.Concurrent.dll
System.Collections.Immutable.dll
System.Collections.NonGeneric.dll
System.Collections.Specialized.dll
System.Collections.dll
System.ComponentModel.Annotations.dll
System.ComponentModel.DataAnnotations.dll
System.ComponentModel.EventBasedAsync.dll
System.ComponentModel.Primitives.dll
System.ComponentModel.TypeConverter.dll
System.ComponentModel.dll
System.Configuration.dll
System.Console.dll
System.Core.dll
System.Data.Common.dll
System.Data.DataSetExtensions.dll
System.Data.dll
System.Diagnostics.Contracts.dll
System.Diagnostics.Debug.dll
System.Diagnostics.DiagnosticSource.dll
System.Diagnostics.FileVersionInfo.dll
System.Diagnostics.Process.dll
System.Diagnostics.StackTrace.dll
System.Diagnostics.TextWriterTraceListener.dll
System.Diagnostics.Tools.dll
System.Diagnostics.TraceSource.dll
System.Diagnostics.Tracing.dll
System.Drawing.Primitives.dll
System.Drawing.dll
System.Dynamic.Runtime.dll
System.Formats.Asn1.dll
System.Formats.Tar.dll
System.Globalization.Calendars.dll
System.Globalization.Extensions.dll
System.Globalization.dll
System.IO.Compression.Brotli.dll
System.IO.Compression.FileSystem.dll
System.IO.Compression.ZipFile.dll
System.IO.Compression.dll
System.IO.FileSystem.AccessControl.dll
System.IO.FileSystem.DriveInfo.dll
System.IO.FileSystem.Primitives.dll
System.IO.FileSystem.Watcher.dll
System.IO.FileSystem.dll
System.IO.IsolatedStorage.dll
System.IO.MemoryMappedFiles.dll
System.IO.Pipelines.dll
System.IO.Pipes.AccessControl.dll
System.IO.Pipes.dll
System.IO.UnmanagedMemoryStream.dll
System.IO.dll
System.Linq.AsyncEnumerable.dll
System.Linq.Expressions.dll
System.Linq.Parallel.dll
System.Linq.Queryable.dll
System.Linq.dll
System.Memory.dll
System.Net.Http.Json.dll
System.Net.Http.dll
System.Net.HttpListener.dll
System.Net.Mail.dll
System.Net.NameResolution.dll
System.Net.NetworkInformation.dll
System.Net.Ping.dll
System.Net.Primitives.dll
System.Net.Quic.dll
System.Net.Requests.dll
System.Net.Security.dll
System.Net.ServerSentEvents.dll
System.Net.ServicePoint.dll
System.Net.Sockets.dll
System.Net.WebClient.dll
System.Net.WebHeaderCollection.dll
System.Net.WebProxy.dll
System.Net.WebSockets.Client.dll
System.Net.WebSockets.dll
System.Net.dll
System.Numerics.Vectors.dll
System.Numerics.dll
System.ObjectModel.dll
System.Private.CoreLib.dll
System.Private.DataContractSerialization.dll
System.Private.Uri.dll
System.Private.Xml.Linq.dll
System.Private.Xml.dll
System.Reflection.DispatchProxy.dll
System.Reflection.Emit.ILGeneration.dll
System.Reflection.Emit.Lightweight.dll
System.Reflection.Emit.dll
System.Reflection.Extensions.dll
System.Reflection.Metadata.dll
System.Reflection.Primitives.dll
System.Reflection.TypeExtensions.dll
System.Reflection.dll
System.Resources.Reader.dll
System.Resources.ResourceManager.dll
System.Resources.Writer.dll
System.Runtime.CompilerServices.Unsafe.dll
System.Runtime.CompilerServices.VisualC.dll
System.Runtime.Extensions.dll
System.Runtime.Handles.dll
System.Runtime.InteropServices.JavaScript.dll
System.Runtime.InteropServices.RuntimeInformation.dll
System.Runtime.InteropServices.dll
System.Runtime.Intrinsics.dll
System.Runtime.Loader.dll
System.Runtime.Numerics.dll
System.Runtime.Serialization.Formatters.dll
System.Runtime.Serialization.Json.dll
System.Runtime.Serialization.Primitives.dll
System.Runtime.Serialization.Xml.dll
System.Runtime.Serialization.dll
System.Runtime.dll
System.Security.AccessControl.dll
System.Security.Claims.dll
System.Security.Cryptography.Algorithms.dll
System.Security.Cryptography.Cng.dll
System.Security.Cryptography.Csp.dll
System.Security.Cryptography.Encoding.dll
System.Security.Cryptography.OpenSsl.dll
System.Security.Cryptography.Primitives.dll
System.Security.Cryptography.X509Certificates.dll
System.Security.Cryptography.dll
System.Security.Principal.Windows.dll
System.Security.Principal.dll
System.Security.SecureString.dll
System.Security.dll
System.ServiceModel.Web.dll
System.ServiceProcess.dll
System.Text.Encoding.CodePages.dll
System.Text.Encoding.Extensions.dll
System.Text.Encoding.dll
System.Text.Encodings.Web.dll
System.Text.Json.dll
System.Text.RegularExpressions.dll
System.Threading.AccessControl.dll
System.Threading.Channels.dll
System.Threading.Overlapped.dll
System.Threading.Tasks.Dataflow.dll
System.Threading.Tasks.Extensions.dll
System.Threading.Tasks.Parallel.dll
System.Threading.Tasks.dll
System.Threading.Thread.dll
System.Threading.ThreadPool.dll
System.Threading.Timer.dll
System.Threading.dll
System.Transactions.Local.dll
System.Transactions.dll
System.ValueTuple.dll
System.Web.HttpUtility.dll
System.Web.dll
System.Windows.dll
System.Xml.Linq.dll
System.Xml.ReaderWriter.dll
System.Xml.Serialization.dll
System.Xml.XDocument.dll
System.Xml.XPath.XDocument.dll
System.Xml.XPath.dll
System.Xml.XmlDocument.dll
System.Xml.XmlSerializer.dll
System.Xml.dll
System.dll
WindowsBase.dll
ar/Microsoft.Maui.Controls.resources.dll
ca/Microsoft.Maui.Controls.resources.dll
createdump
cs/Microsoft.Maui.Controls.resources.dll
da/Microsoft.Maui.Controls.resources.dll
de/Microsoft.Maui.Controls.resources.dll
el/Microsoft.Maui.Controls.resources.dll
es/Microsoft.Maui.Controls.resources.dll
fi/Microsoft.Maui.Controls.resources.dll
fr/Microsoft.Maui.Controls.resources.dll
he/Microsoft.Maui.Controls.resources.dll
hello-maui-razor.dll
hello-maui-razor.pdb
hello-maui-razor.runtimeconfig.json
hello-maui-razor.staticwebassets.endpoints.json
hi/Microsoft.Maui.Controls.resources.dll
hr/Microsoft.Maui.Controls.resources.dll
hu/Microsoft.Maui.Controls.resources.dll
id/Microsoft.Maui.Controls.resources.dll
it/Microsoft.Maui.Controls.resources.dll
ja/Microsoft.Maui.Controls.resources.dll
ko/Microsoft.Maui.Controls.resources.dll
libSystem.Globalization.Native.so
libSystem.IO.Compression.Native.so
libSystem.Native.so
libSystem.Security.Cryptography.Native.OpenSsl.so
libclrgc.so
libclrgcexp.so
libclrjit.so
libcoreclr.so
libhostfxr.so
libhostpolicy.so
libmscordaccore.so
libmscordbi.so
module.json
ms/Microsoft.Maui.Controls.resources.dll
mscorlib.dll
nb/Microsoft.Maui.Controls.resources.dll
netstandard.dll
nl/Microsoft.Maui.Controls.resources.dll
pl/Microsoft.Maui.Controls.resources.dll
pt-BR/Microsoft.Maui.Controls.resources.dll
pt/Microsoft.Maui.Controls.resources.dll
resources/base/element/color.json
resources/base/element/string.json
resources/base/profile/main_pages.json
resources/rawfile/app.json
ro/Microsoft.Maui.Controls.resources.dll
ru/Microsoft.Maui.Controls.resources.dll
sk/Microsoft.Maui.Controls.resources.dll
sv/Microsoft.Maui.Controls.resources.dll
th/Microsoft.Maui.Controls.resources.dll
tr/Microsoft.Maui.Controls.resources.dll
uk/Microsoft.Maui.Controls.resources.dll
vi/Microsoft.Maui.Controls.resources.dll
wwwroot/_framework/blazor.modules.json
wwwroot/_framework/blazor.webview.js
wwwroot/index.html
wwwroot/js/app.js
zh-HK/Microsoft.Maui.Controls.resources.dll
zh-Hans/Microsoft.Maui.Controls.resources.dll
zh-Hant/Microsoft.Maui.Controls.resources.dll
```
