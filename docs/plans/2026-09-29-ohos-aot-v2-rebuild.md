# AOT-V2：含 TabbedPage 修复的 slice 重编 NativeAOT 包并发布（2026-09-29）

> 目的（真机验证结论行动项 ③）：用我们的工具链（`openharmony-arm64` RID，**非** tester 的
> `--targetos:linux` 本地重编路径）重编 `test/hello-maui-app` 的 NativeAOT hap，slice 含
> **TabbedPage 修复**，供 tester 复测「MAUI 主体渲染」；同时把 tester 本地重编的**三项链接修复**
> 作为「本地重编参考」入档（我们的工具链不需要这些 hack）。复测口径（结论 5.4）：**主体渲染看本包
> `aot-haps-v2.tar.gz`，`_framework/dotnet.js` 补丁进包看 kit #33（FIX-BLZ-JS）**。
>
> 关联：`2026-09-28-ohos-device-verification-results.md` §2/§4（结论 2/3、行动 ②③）、
> `2026-09-28-ohos-retest-taskcard.md`、`docs/openharmony-hap-packaging.md`「NativeAOT HAP variant」。

## 1. 输入与 provenance

| 项 | 值 |
| --- | --- |
| slice（MAUI 平台层） | `springmin/maui-ohos` `feature/openharmony` @ **`14bdb85f4f705426085fb2fedc3491eda736c979`**（"openharmony slice: enumerate the TabbedPage's CurrentPage in the compositor walk"；`ChildEnumerator` 补 `TabbedPage.CurrentPage` case + slice notes，+48/−11 两文件）；fetch 后为 origin tip 且祖先校验通过 |
| slice 冻结副本 | `aot-v2/slice-fix/`（对 `14bdb85f` 的 `git archive src/Core/src/Platform/OpenHarmony`；`OpenHarmonyWindowRenderer.cs` blob `3da77238…` == 提交 blob；**工作区在制 WIP 未入包**） |
| 工作仓 | `springmin/ohos-workload` @ `8d53d36f9cf5736374befa324dab9fc0aca2bc2c`（发布时 HEAD；与 `522bd74` 差异仅在 `test/maui-platform-verify/*`，不在 publish 输入路径） |
| SDK / packs | SDK `11.0.100-rc.2.26451.109`；workload packs `1.0.0-preview.24`（host `281,504 B / f6b3581a…`，含 `start_app` AOT 桥）；AOT packs `11.0.0-rc.1.26451.109`（NuGet cache） |
| 本机环境 hooks | 命令行本地文件（`CustomAfterMicrosoftCommonTargets=<scratch>/aot-local-hooks.targets`；无仓内改动）：① kit #32 的 `LocalRun`（hap 打包三步 Exec 旁路）+ AspNetCore KFR runtime 重定向 `26451.109`；② **本机新增 `Exec` 任务替换**——rc.2 SDK 在 HarmonyOS 宿主上把内建 `Exec` 写成 Windows 批处理包装（运行时既非 Windows 也非 Linux 判定），所有命令都回 `1`，且默认工作目录取导入文件目录：替换实现经 `/bin/sh` 执行并回传真实退出码/`ConsoleToMSBuild`/项目目录 cwd（ilc 的 linker 探测、`ilc @rsp`、链接、`llvm-objcopy` 去符号均走此路径） |
| publish 命令 | `dotnet publish test/hello-maui-app/hello-maui-app.csproj -f net11.0-openharmony26.0 -r openharmony-arm64 -c Release -m:1 -p:PublishAot=true -p:PublishAotUsingRuntimePack=true -p:CompressSymbols=false -p:CopyOutputSymbolsToPublishDirectory=false -p:OpenHarmonyHapPackage=true -p:OpenHarmonySdkRoot=$OHOS_SDK -p:OpenHarmonyMauiPlatformDir=<slice-fix> --source <空 feed>` |
| 日志 | `aot-v2/publish-aot-v2.log`（`EXIT=0`，2026-09-29 10:11:53）；scratch = `/data/storage/el2/base/tmp/opencode/aot-v2/` |

## 2. 产物指纹（发布值）

| 产物 | 大小 (B) | sha256 |
| --- | --- | --- |
| `libhello-maui-app.so`（publish） | 17,709,840 | `08962c2b0c2269e1ca38bf9b353c5a84544d75c3d317c690e5abd224065e8dbe` |
| `hello-maui-app-aot.hap`（已签，hap 内名） | 20,360,777 | `5db9c6721a512e4f60372374db38bea1de63dbd96b3e7f0c5aa664f6a16a714b` |
| `hello-maui-app-aot-unsigned.hap` | 20,100,211 | `b869f67bffc6f80a6f819d4fd4f9e2104b66554d76905db65a4f3974a73ba8a3` |
| hap 内宿主 `libopenharmonyhost.so` | 281,504 | `f6b3581a18720db105352e5da41e928723b4bf07af0467149dff1ee32441be69` |
| hap 内 `ets/modules.abc` | 20,916 | `54a1a2011cca4a96772b0ed9f99b36ddd7b655fde1e681676669f78ed8138bbb` |

- so：`nm -D` 含 `T openharmony_app_main@@V1.0`；带 `.codesign`（sections=1）；`NEEDED = libc.so`；
  IL 门禁 **IL2026/IL3050/IL3051 = 0**；`strings` 含 `TabbedPage`（类型名进反射数据）。
- hap 形态（两变体一致；`unzip -l` + 抽取核对）：仅 3 个 `.so`（app so + host + `libc++_shared.so`），
  **无** `libcoreclr.so`/`libhostfxr.so`/`libclrjit.so`；`ets/modules.abc`、`resources.index`、
  `libs/arm64-v8a/.dotnet-payload.json`（`assembly = hello-maui-app.dll`）在包；`module.json`
  `libIsolation=true`、无 `requestPermissions`；abc = pack 默认（headless，与既有 aot-haps 口径一致）。
- 本机冒烟：`test/aot-smoke/run-local-smoke.sh`（`HOSTLIB_DIR` = 新 hap 内宿主）**9 PASS / 0 FAIL**
  （one-shot + bridged `aot=1` + `aot=0` 负控 + runtime-mode 轮次），另抓 `start_app: aot=1`
  （rc=7、payload 匹配）；日志 `aot-v2/smoke/run-local-smoke.log`、`aot-v2/smoke/bridge-aot1.log`。
- 静态核验：`aot-v2/verify-aot-v2.sh` → `ALL CHECKS PASSED`（`aot-v2/verify-aot-v2.log`）。

## 3. 修复内容（slice，`14bdb85f`）

`OpenHarmonyWindowRenderer.cs` 的 `ChildEnumerator.MoveNext` 在「导航页可见页」之后插入
「TabbedPage 当前页」（`tabbed.CurrentPage`，引用相同则跳过），原 FlyoutPage/平台子节点分支顺延。
根因（tester BITMAP-DIAG + IL）：FlyoutPage → TabbedPage 的 `Detail` 链路上，主体页从未进入绘制遍历，
只画了 tab 栏；tester 的 IL 级确认 `ChildEnumerator` 里 `isinst TabbedPage` 由 0 → 1（本修复
与 tester 设备机补丁同形）。已知未覆盖面（follow-up）：`OpenHarmonyAccessibility.PushChildren`
的同款枚举缺口（无障碍影子树不含当前页）。

## 4. 发布（release `springmin/sdk-ohos` tag `device-test-kit`，id 392356147）

新并列资产（**不动**旧包与其他资产；release assets 27 → 30）：

| 资产 | id | 大小 (B) | sha256 |
| --- | --- | --- | --- |
| `aot-haps-v2.tar.gz` | 596991567 | 17,323,220 | `265e014f8a52626836567175c469e2b5d022934c50dc59993f036c185abf1c2d` |
| `aot-haps-v2.tar.gz.sha256` | 596992543 | 85 | `720da730d96f90e54cf8c5720035ab37cd4ef25ee43a69ce71261cf51bb1e2a4`（内容 = `265e014f…`） |
| `aot-haps-v2-README.md` | 596993218 | 4,557 | `3e2cb2db84caa674da4e4ba61cbc40604d549eed6667b13b95f24eaec8fdb39f` |

- 校验（`aot-v2/verify-publish-v2.py`，日志 `verify-publish-v2.log`）：by-id（API digest+size = 本地）
  + changed/added/removed 集合 = **仅新增三项**（changed=[]、removed=[]）；gh-proxy 下载
  tar/sidecar/README 逐字节相等；tar 内 hap 指纹与本地一致；tar HEAD 200 + content-length 正确。
- 旧 `aot-haps.tar.gz`（17,093,146 B / `91e1b9d3…`，kit #28 宿主、无 TabbedPage 修复）**保留作对照**；
  tester 复测请取 **v2**（重签 → 安装 → `aot=1` → 主体渲染）。重签/重打包后哈希必变，数字以 release asset 为准。
- README（notes）已含一行 v2 说明：含 TabbedPage 修复、取代旧 `aot-haps.tar.gz`、dotnet.js 归 kit #33。

## 5. tester 本地重编的三项链接修复（本地参考，不在我们的路径）

> 来源：测试方《.NET MAUI 鸿蒙真机验证总结（kit #30 → kit #31）》结论 3；tester 侧本地
> `--targetos:linux` 重编 so 的修复记录（按总结转述）。**我们的工具链（§1/§2）无需这些 hack**，
> 记录仅供对比与本地复现参考。

1. **NetSecurity C stub**：链接期为 `System.Net.Security` 的原生依赖提供 C stub（本地工具链缺该
   原生面时补齐符号）。
2. **`__start/__stop___modules`**：lld 链接加 `--undefined=__start___modules`（把 `__modules` 段
   拉入），并关闭 gc-sections（去 gc），否则 `__start/__stop___modules` 对被 gc 掉而缺口。
3. **`sections.ld` KEEP `__modules`**：链接脚本里 `KEEP(__modules)`（与上一条配对，保证模块
   注册段在链接后仍存在）。

> 差异归因（tester 结论 3）：本地重编 so 已过加载与 MAUI 初始化，随后在 NativeAOT 运行时
> `TypeManager::GetModuleSection` NULL @0x8 崩溃；springmin 预编译 so（我们的工具链）可跑。
> 即工具链差异在 runtime-ohos 专用 ilc，而非上述链接修复本身。

## 6. 边界与未决

- **真机复测归 tester**：重签（华为调试证书 + Profile 绑定 UDID）→ 安装（会顶替 kit 主包）→
  启动 → `aot=1` → **主体渲染确认**（Flyout drawer 内的 TabbedPage 双页签 + 切页）。
- `_framework/dotnet.js` 静态资产路由属 **kit #33**（`fix-blzjs` 的 `pack-host.sh` 静态资产路由），
  不在本包口径；本包不含该变更。
- slice pin（ohos-workload CI 的 `MAUI_OHOS_REF` / workflow 默认）未随本任务改动。
- 本机 rc.2 SDK 的 `Exec` 批处理包装与 cwd 问题已用命令行 hooks 旁路（不落仓）；换干净环境重编时
  按 `docs/openharmony-hap-packaging.md`「Known environment quirks」复核。
- 本地 `test/hello-maui-app/bin/` 现为 AOT hap（JIT hap 备份在 `aot-v2/prejit/`）；kit 构建会按
  自己的 publish 覆盖，不影响出包流程。
