# 测试方交接：kit #24、JIT A/B 判定点与 NativeAOT 主路线（2026-09-24）

> 回应你的《ohos-kit22-verification-summary.md》（kit #22/#23，本机 `~/Download/com.haitai.htbrowser/`）§4/§6/§7。
> 结论先行：host 链路已全通（你的 §6 与我们一致）；JIT 是否可用改由 kit #24 的 **HAP 域探针 + W^X A/B** 判定；
> NativeAOT 三项阻塞（平台切片 / ilc pack / SDK RID）已闭环，仍是主路线。
> **kit #24（数字入口见 release「## Integrity」；本文写定时 kit #24 仍在发布流程中，拿到后以 release 说明与随包 `SHA256SUMS` 为准）。**

## 1. 里程碑与我们的闭环（回应三项请求）

- 你们侧（kit #22/#23）：so 加载 → napi 导出 → startApp → hostfxr → hostpolicy → coreclr dlopen 全通；
  JIT 崩在可执行内存；NativeAOT 三阻塞（§4.2/§7.1）。以下 6 项为我们的回应。

1. **MAUI 平台切片（请求 ①）**：`springmin/maui-ohos` tag `ohos-slice-1.0.1`，资产 `ohos-slice-1.0.1.tar.gz`
   （279,442 B / `a968c988…99992c`，前缀 `ohos-slice-1.0.1/`，129 项）+ `.sha256`；`main` 为上游镜像不合并的
   原因、`feature/openharmony` 分支与接线命令见 `docs/plans/2026-09-24-ohos-nativeaot-maui-slice.md`
   （类型名与你们期望一致：`UseOpenHarmony()`、`OpenHarmonyMauiAppHost`、`OpenHarmonyBlazorWebViewHandler`）。
2. **NativeAOT packs（请求 ②）**：`springmin/sdk-ohos` release `aot-packs-11.0.0-rc.1`（8 资产 = 7 nupkg + `SHA256SUMS`）：
   本机构建 `Microsoft.NETCore.App.Runtime.NativeAOT.openharmony-arm64.11.0.0-rc.1.26451.109.nupkg`
   （25,938,034 B / `5baad9e8…3681d5e4`）与 `runtime.openharmony-arm64.Microsoft.DotNet.ILCompiler.11.0.0-rc.1.26451.109.nupkg`
   （23,817,580 B / `999e73a7…b1b539e8`），另有官方 `linux-musl-arm64`/`win-x64` 组合；
   获取脚本 `sdk-ohos` → `eng/ohos-install/fetch-nativeaot-packs.sh`（sha256 锚 + gh-proxy 回退，支持 `--local`）。
3. **NETSDK1203（请求 ③）**：RID 图 `openharmony-*` → `#import` → `linux-musl-*` 已修（SDK 内
   `eng/PortableRuntimeIdentifierGraph.openharmony.json`，sdk-ohos 构建已内嵌；stock/旧 SDK 可显式加
   `-p:BundledRuntimeIdentifierGraphFile=eng/PortableRuntimeIdentifierGraph.openharmony.json`）；diag 输出
   `Best RID … is 'linux-musl-arm64'`；`dotnet publish -r openharmony-arm64 -p:PublishAot=true` 在设备端
   端到端验证，运行输出 `hello aot openharmony`；离线条件（仅 aot-packs feed）已复测。
4. **JIT 复核装置（kit #24）**：runtime-ohos `678ac21836c`（`TARGET_OPENHARMONY` 默认 `EnableWriteXorExecute=0`）
   + SDK 烘焙 + 宿主两条启动路径显式设置；A/B 开关 `<filesDir>/xwe.txt`（首字节 `1` = 强制 W^X=1）；
   exec-memory 探针每进程一次，输出 `OHOS_DOTNET probe: 1=… 2=… 3=… 4=…`（`tester-run.sh` 采集为 `hilog/hilog-execmem.txt`）。
5. **payload-in-libs**：hap `libs/arm64-v8a/` 直接携带 253 个 payload 文件 + `.dotnet-payload.json`
   （依据：唯一允许 dlopen 的路径 = el1 `libs/`）；`dotnet.zip` 保留为回退；签名 hap 由 ~32.7 MB 增至 ~75.3 MB。
   kit #24 **不含** seccomp 拦截器（不再需要；它会 strip `PROT_EXEC`）：请用 stock kit 测，不要叠加旧本地补丁。
6. **策略与部署文档**：部署模型对比 `docs/plans/2026-09-24-ohos-runtime-deployment-models.md`（A 自包含 + C NativeAOT 为主）；
   JIT 策略 `docs/plans/2026-09-24-ohos-runtime-strategy.md`（解释器 spike 有界；ACL 引用更正；Mono 不做）。

## 2. 下一步操作（拿到 kit #24 后）

1. 校验/重签/安装同 `快速开始.md` §1/§3；`verify-kit.sh` 会额外断言每个 hap 的 `.dotnet-payload.json`（缺失/不一致 = FAIL）。
2. 一条命令取证：`sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 60`
   → 证据包 `hilog/hilog-execmem.txt` 含 `xwe=` 与 `probe:` 行；`summary.txt` 有 `execmem_capture`/`execmem_lines`（0 = 未捕获，加长 `--capture` 重跑）。
3. 先读 `probe:` 行（token：**1**=匿名 `mmap(RWX)` · **2**=匿名 `RW→RX` · **3**=`memfd`+RX · **4**=文件 RX；每项为 `OK` 或失败 `errno`；定义见 `ohos-workload/docs/openharmony-hap-packaging.md` §Executable memory）：
   - `1=OK`：匿名 RWX 在 HAP 域可用 ⇒ JIT（默认 W^X=0）应可用。报证：managed app 运行（`managed app hello-maui-app.dll started (UI shell)`）+ 无 `SEGV_ACCERR`；若仍 `SEGV_ACCERR`，附 `xwe=` 行、`probe:` 行与崩溃点前后 200 行。
   - `1≠OK`（如 `1=1/12/13/38`）：HAP 域拒绝匿名可执行 ⇒ JIT 在本固件不可用；附 probe 行与固件版本，转 NativeAOT（§4）。
   - `3`/`4` 是旁证（本机 CLI 域实测 `1=OK 2=OK 3=13 4=13`：3/4=13 即 memfd/文件 exec 被拒，正是 W^X=1 的崩溃来源）。

## 3. A/B 指令（复现旧崩溃 / 证明默认正确）

1. 用 DevEco Device File Browser（调试应用可进 `files/`）在 `<filesDir>/xwe.txt` 写入首字节 `1`；
2. 重启应用 → hilog 出现 `xwe=1 source=file`，预期复现 `SEGV_ACCERR`（与你们本轮崩溃同形）；
3. 删除 `xwe.txt`（或写入非 `1`）→ 恢复 `xwe=0 source=default`，JIT 应恢复可用；
4. 两轮都请把 `xwe=` 行与 `probe:` 行入档；无写权限时跳过并在报告注明（探针行的 `1=` 已给出结论）。

## 4. NativeAOT 指引（主路线，并行推进）

1. **切片**：取 `ohos-slice-1.0.1.tar.gz`（§1.1）解包，按切片内 `README-openharmony-slice.md` 接线
   （整仓构建 `IncludeOpenHarmonyTargetFrameworks=true`，或独立构建 `Microsoft.Maui.Platform.OpenHarmony.csproj`）。
2. **packs**：`sh eng/ohos-install/fetch-nativeaot-packs.sh <dest>`（sdk-ohos 仓库；RID 图修复已在 SDK 内，离线机用 `--local <dir-with-nupkgs>`）。
3. **发布**：`dotnet publish -r openharmony-arm64 -p:PublishAot=true`（前置/host 交叉编译/`-p:CompressSymbols=false` 见
   `NATIVE-AOT.md`；stock/旧 SDK 另加 `-p:BundledRuntimeIdentifierGraphFile=eng/PortableRuntimeIdentifierGraph.openharmony.json`）。
4. **期望输出**：单个已签名原生 ELF；设备运行打印 `hello aot openharmony`。完整文档：`sdk-ohos/documentation/ohos-install/NATIVE-AOT.md`。
5. **未决（我们侧继续）**：MAUI 应用（非 hello console）的 NativeAOT HAP 打包与真机 E2E；请以你们设备结果为准。

## 5. 判定表（探针 × 日志 → 结论）

| `probe:` 第 1 个 token | `xwe=` 行 | managed app / 崩溃 | 结论 |
|---|---|---|---|
| `1=OK` | `xwe=0 source=default` | 运行、无 `SEGV_ACCERR` | JIT 可用；默认设置正确，JIT 路线收口 |
| `1=OK` | `xwe=1 source=file` | `SEGV_ACCERR` | A/B 成立：崩溃 = W^X=1 memfd 路径；保持默认 0 |
| `1=OK` | `xwe=0 source=default` | 仍 `SEGV_ACCERR` | 不是匿名 exec 策略；仍可能是 file-backed exec 请求或其它启动阻塞，附 maps/崩溃栈继续定位 |
| `1=1/12/13/38` | 任意 | 任意 | HAP 域禁匿名可执行；JIT 不可用 → NativeAOT |
| 无 `probe:` 行 / `execmem_lines=0` | 无 | 任意 | 取证窗口问题，不能判定；加长 `--capture` 重跑 |

## 6. 仍未验证（如实边界）

- HAP 应用域的 probe 实测（本机目前只有 CLI 域 `1=OK 2=OK 3=13 4=13`）；stock kit #24 的 JIT 全链（里程碑成功是 kit #18 + 你们本地 5 项修复）。
- stock kit（#22 起）的功能面复测：验收 A1–K2/N1–N7、新功能 M1–M13、P1–P4 与对照载荷。
- NativeAOT：MAUI 切片 × aot-packs × HAP 打包的首次真机 E2E；坚盾守护模式对 NativeAOT 预期无影响但未验。
- CoreCLR 解释器 spike（有界，策略文档 §2）未开始构建验证。
