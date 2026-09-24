# OpenHarmony NativeAOT：MAUI 平台切片源码的可发现性与接线（2026-09-24）

回应测试报告 `ohos-kit22-verification-summary.md` §4.2/§7.1：`UseOpenHarmony`、`OpenHarmonyMauiAppHost`、
`OpenHarmonyBlazorWebViewHandler` 在 maui-ohos `main` 不存在 —— 属实，原因是 `main` 为 dotnet/maui 上游镜像。

## 结论（分支与产物）

- `springmin/maui-ohos` 默认分支 `main` = 上游 dotnet/maui 提交 `1cd2e15b`（已对上游核验）；切片在 `feature/openharmony`。
- 不并入 main：`feature/openharmony` 首个切片提交删除了上游其余 26,317 个文件（slice-only 检出），快进 main 会丢掉上游树。
- 已发布标签 `ohos-slice-1.0.1` → release 资产 `ohos-slice-1.0.1.tar.gz`（前缀 `ohos-slice-1.0.1/`，129 项）+ `.sha256`
  （`a968c988…`）；1.0.0 保留并标注 Superseded。`README-openharmony-slice.md` 同时在 `main` 与切片分支。
- 类型名与测试方期望一致（无需兼容别名）：`MauiOpenHarmonyExtensions.UseOpenHarmony()`、`OpenHarmonyMauiAppHost`、
  `OpenHarmonyBlazorWebViewHandler`（需 `OPENHARMONY_BLAZOR_WEBVIEW` + BlazorWebView 包）。切片共 107 个 `.cs`。

## 接线（csproj / TFM 门控）

- 源码包含（ohos-workload `test/hello-maui-app`、`test/maui-platform-verify` 既有方式）：
  `<Compile Include="$(OpenHarmonyMauiPlatformDir)/*.cs" />` + `Microsoft.OpenHarmony.Hosting` / `.Maui.Graphics` 引用；
  默认路径 `../../../maui-ohos/src/Core/src/Platform/OpenHarmony`，`MAUI_SLICE_DIR` / `-p:MauiSliceDir=` 可覆盖。
- 整仓构建：`IncludeOpenHarmonyTargetFrameworks=true`（装 openharmony workload 时自动）→ `MauiPlatforms` 增加
  `net11.0-openharmony26.0`；`src/MultiTargeting.targets` 对非 OH TFM 移除 `Platform/OpenHarmony/**`，OH TFM 定义 `OPENHARMONY`。
- 独立构建（0 error；1.0.1 起 slice-only 树可直接构建）：
  `dotnet build …/Microsoft.Maui.Platform.OpenHarmony.csproj -p:OpenHarmonyHostingAssembly=… -p:OpenHarmonyGraphicsAssembly=…`。

## 验证与未决

- 本机：切片构建 0 error（仓库与解包 1.0.1 资产均验）；`clone --branch feature/openharmony` → 目录存在；
  release 下载资产 sha256 与本地一致。
- maui-ohos 提交：切片分支 `f70a60a3`（`e7fbc2ea` README + `f70a60a3` 部分检出构建修复），`main` `7de682ea`（README 指针）。
- 未决（非切片可解）：ilc 的 `linux-musl-arm64` NativeAOT 运行时包下载、`openharmony-arm64` 的 `PublishAot` 支持（SDK/RID 侧）。
