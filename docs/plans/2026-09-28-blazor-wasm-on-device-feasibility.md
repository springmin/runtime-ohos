# 设备端 Blazor WASM 可行性实测（2026-09-28）

**目标：** 在 OpenHarmony 设备上用本仓 SDK `dotnet publish` 一个 Blazor WebAssembly 应用（非 AOT）。
**结论：✅ 可行** —— 未裁剪与裁剪两种模式都成功产出可部署的静态站点，但需要一组**版本对齐 + TaskHostFactory 规避**配置。

## 1. 原始问题
- `dotnet new blazorwasm` 可创建（SDK 内置 `Microsoft.NET.Sdk.WebAssembly` / `BlazorWebAssembly`）
- `dotnet build` 在 restore 失败：5 个包 `NU1102`（fork 版本线 `11.0.0-rc.1.26451.109` / `11.0.0-rc.1.26452.110` 不在 nuget.org；官方最近为 `11.0.0-rc.1.26425.128`）

## 2. 可行配方

1. **NuGet 源**：加入 dnceng public `dotnet11` feed
   `https://pkgs.dev.azure.com/dnceng/public/_packaging/dotnet11/nuget/v3/index.json`
   （该 feed 提供 `11.0.0-rc.2.2645x.*` 系列的 wasm/Blazor 包）
2. **版本覆盖到 feed 可用 flight**（实测 `11.0.0-rc.2.26459.117`）：
   - `PackageReference`：`Microsoft.AspNetCore.Components.WebAssembly`、`Microsoft.AspNetCore.Components.Gateway`
   - `Directory.Build.targets` 覆盖 `KnownWebAssemblySdkPack` 的 `WebAssemblySdkPackVersion`、`KnownAspNetCorePack` 的 `AspNetCorePackVersion`
   - `dotnet publish -p:RuntimeFrameworkVersion=11.0.0-rc.2.26459.117`
3. **TaskHostFactory 规避**（OHOS 上 task host 无法启动，MSB4216）：
   - 对 `Microsoft.NET.Sdk.WebAssembly.Pack` 的 5 个 task 用 `UsingTask ... Override="true"`（省略 `TaskFactory` → 进程内执行）：
     `GenerateWasmBootJson` / `ComputeWasmBuildAssets` / `ComputeWasmPublishAssets` / `ConvertDllsToWebcil` / `AttachWebcilSizes`
   - 裁剪开启时同样覆盖 ILLink 的 `ILLink` / `ComputeManagedAssemblies`
4. **裁剪模式**：ILLink 工具子进程要求 `Microsoft.NETCore.App 11.0.0-rc.2.26459.117`；设备只有 rc.1 时，可临时把 rc.1 运行时目录复制/改名为该版本（长期方案 = 安装 rc.2 主机运行时，属 rc2 迁移的一部分）；或 `-p:PublishTrimmed=false`

## 3. 实测结果

| 模式 | 结果 |
|---|---|
| `PublishTrimmed=false` | ✅ `publish/wwwroot/_framework`：636 个文件（wasm/br/gz），63 MB |
| 默认裁剪 | ✅ 753 个文件，71 MB（配合 ILLink 覆盖 + rc.2 运行时目录） |

## 4. 未做 / 待办

- **浏览器/ArkWeb 承载**：`application/wasm` MIME、`fetch`/`instantiateStreaming`、可选多线程（COOP/COEP）、Service Worker —— 需 HAP+Web 组件或本地服务承载
- **TaskHostFactory 根因修复**（OHOS 上 task host 为何无法启动：IPC/命名管道限制？）：建议在 sdk-ohos 侧评估（SDK 补丁或提供全局 in-process 覆盖开关），否则任何使用 TaskHostFactory 的包在设备端构建都会失败
- AOT（`RunAOTCompilation`）未测：需要 wasm-tools/emsdk，且只能在桌面/CI 构建（本机 OHOS arm64 不可跑 Emscripten 工具链）
