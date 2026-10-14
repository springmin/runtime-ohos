# 上游测试清点与实跑（UPSTREAM-TESTS，2026-10-13）

> 范围：dotnet/maui fork（maui-ohos `feature/openharmony` @ `5cfb1b8991`）与 dotnet/runtime fork（runtime-ohos）上游测试资产清点 + 本机可跑子集实跑。不用设备、不改上游源码。SDK = `~/.dotnet.rc2-fix`（11.0.100-rc.2.26451.112，rc.2 运行时）。
## 1) 清点：maui-ohos（`*test*` 路径 csproj 38 个）

| 组 | 工程 | 框架/TFM | 运行方式 | 平台依赖 | 本机可跑 |
|---|---|---|---|---|---|
| 单元（cake `dotnet-test` 清单＝10） | Core.UnitTests（657 Fact/Theory 属性）· Essentials.UnitTests（239）· Controls.Core.UnitTests（3448）· Controls.Xaml.UnitTests（886）· SourceGen / BindingSourceGen / Graphics.Tests / Resizetizer / MauiBlazorWebView(+ExternalHandler) / Essentials.ExternalBackend / UITest.Analyzers | xunit 2.9.3 + NSubstitute 5.1 + coverlet；net11.0 单 TFM；Arcade 隐式带 Microsoft.NET.Test.Sdk + xunit.runner.visualstudio | `dotnet test`；Arcade `/t:Test`＝xunit console | 无 | ✅（实跑 3） |
| 设备 | Core/Essentials/Controls/Graphics/BlazorWebView `*.DeviceTests(+.Shared)` | xunit + DeviceTests.Runners | xharness（eng/devices） | Android/iOS/MacCatalyst/Windows 真机 | ❌ 无设备 |
| UI | TestCases.{Shared,Android,iOS,Mac,WinUI}.Tests + HostApp | Appium UITest | cake uitests | 设备 + Appium | ❌ |
| 基准/集成 | Core/Graphics/Xaml Benchmarks、Benchmarks.Droid、Microsoft.Maui.IntegrationTests | BenchmarkDotNet / xunit | dotnet run / cake | 设备 / 全工作负载链 | △ / ❌ |
| 旧式 | Controls.DualScreen.UnitTests（NUnit·netcoreapp2.1）、Core.Design.UnitTests（net472） | — | — | Windows | ❌（不在 cake 清单） |

- OHOS 缺口：全部测试运行器无 openharmony 平台分支；测试树内 openharmony 引用数 **0**（`grep -ril`）；切片目录 `src/Core/src/Platform/OpenHarmony/` 无测试文件。

## 2) 实跑（环境旁路，全部为调用参数/环境变量，零源码改动）

1. `lib-dotnet-env.sh`（MSBuild server/node reuse 关、共享编译关、短 TMPDIR）——OHOS AF_UNIX 已知坑；
2. `DOTNET_NUGET_SIGNATURE_VERIFICATION=false`——NuGet 签名验证（PKCS）本机卡死（≥5 min）；
3. `-p:RestoreDisableParallel=true` + 备源配置（nuget.org + dotnet11；darc 源 100 s/请求超时）——冷并发 HTTP 死锁（需先热连接）；
4. `DOTNET_PROCESSOR_COUNT=1`——csc 高并发下 OpenSSL `digital envelope routines::initialization error` 崩 / 活锁；
5. 平台 TFM 关闭（android/iOS/maccatalyst 未装 workload）；6. VSTest/testhost 在沙箱不可用（host 路径＝内核规范路径）→ 用 Arcade 的 xunit console runner，CWD＝测试输出目录。

| 工程 | 结果 | 备注 |
|---|---|---|
| Core.UnitTests | **1077 total / 0 failed / 3 skipped** | 首跑 13 failed＝LocalizationTests 以 CWD 5×`..` 找 repo 根（沙箱拒枚举 `/`）→ CWD=输出目录复跑全绿；3 skip＝上游 "doesn't work on helix" |
| Essentials.UnitTests | **513 / 0 failed / 0 skipped** | 一次通过 |
| Controls.Core.UnitTests | **6441 / 0 failed / 30 skipped（`-parallel none`）** | 默认并行下同二进制 0↔7 摇摆：`CssDisabledTests` 翻转全局 `AppContext` CSS 开关、`IStylableTest`（7 条）未入同一 `Collection("StyleSheet")`——上游测试隔离竞态（net11.0 #33160 引入注释但漏加）；串行即全绿 |

## 3) 分诊

- Core 13 failed＝环境（CWD/沙箱枚举）→ 非缺陷，复跑消解。
- Controls 7 failed＝上游竞态（非 fork、非环境；同机复现 0/7 两态）+ 编译需 `-p:RunAnalyzers=false`：`eng/BannedSymbols.txt` 的 `AddHandler<>` 禁令（RS0030）来自上游自动合并快照 `56c6e6e91a`、今日 upstream main/net11.0 均无（曾 #17084 回滚）→ 快照遗留。
- **0 个 fork 引入的测试失败**。

## 4) runtime-ohos 侧（只读评估）

- 上游测试规模：`src/libraries` 190 个 `tests/` 目录、161 个 `.Tests.csproj`；`src/tests` CoreCLR 测试树自带 build.sh/run.sh。
- 本机现状：artifacts/bin 只有 clr/runtime 子集（无 libs）→ 任一 library tests 需先全量 `libs+libs.tests` 基线构建 + openharmony 测试宿主，超本轮预算 → 未实跑（只记结论）。

## 5) 结论

- **官方上游有测试代码且规模大**：maui 38 个 test csproj（10 个单元测试工程）；runtime 161 个测试工程 + CoreCLR 测试树。
- 上游单元测试在本机可跑且全绿：**Core 1077/0/3 · Essentials 513/0/0 · Controls 6441/0/30**；失败全部归因环境或上游自身（0 fork 引入）。
- **OHOS 集成缺口**：上游无 openharmony 设备/UI 测试平台与测试宿主（测试树零 OHOS 引用）；fork 的 OHOS 验证依赖自有套件（ohos-workload kit / maui-platform-verify），上游测试仅能作平台无关逻辑的回归背书。
