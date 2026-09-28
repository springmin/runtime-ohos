# MSBuild task host / server 在 OpenHarmony 上失败（MSB4216）——根因与修复（2026-09-28）

**结论：** MSBuild 在 Unix 上把命名管道**硬编码到 `/tmp/<pipe>`**（`Microsoft.Build.Framework` 的
`Microsoft.Build.BackEnd.NamedPipeUtil.GetPlatformSpecificPipeName`）；OpenHarmony 的 LSM 策略
**禁止在 `/tmp` 创建 AF_UNIX socket**（`bind()` → `EACCES`），而 MSBuild 不使用
`TMPDIR`/`Path.GetTempPath()`。于是 task host / MSBuild server 子进程启动后 `bind` 失败、
未处理异常退出（134），父进程 connect 超时（30 s × 5 次）→ **MSB4216**。普通文件/FIFO 在
`/tmp` 可以创建，仅 socket 被拒（`/tmp` 标签 `tmp_file`）。

## 证据（设备实测）

- **IPC 能力**（Python 独立复现）：
  `uds bind /tmp/CoreFxPipe_probe → PermissionError(13)`；`mkfifo /tmp/fifo_probe → OK`；
  `uds bind /data/storage/el2/base/tmp/... → OK`
- **MSBuild 源码**（dotnet/msbuild main `src/Shared/NamedPipeUtil.cs`）：Unix 分支
  `return Path.Combine("/tmp", pipeName);`（`TMPDIR` 只影响 `Path.GetTempPath()`，MSBuild 未使用）
- **子进程崩溃栈**：`Socket.Bind → SocketException(13): Permission denied →
  NamedPipeServerStream.SharedServer..ctor → NodeEndpointOutOfProcTaskHost..ctor →
  OutOfProcTaskHostNode.Run`
- **父进程重试**：`Attempting connect to PID ... pipe /tmp/MSBuild<pid> with timeout 30000 ms`
  × 5（同时解释构建额外多花 ~3 分钟）
- **补丁验证**（1 条 IL：`IL_0007 ldstr "/tmp"` → `call string System.IO.Path::GetTempPath()`）：
  Blazor WASM 构建从 **5:06 失败** 变为 **15.4 s 成功、0 错误**；server/task host 均经
  `/data/storage/el2/base/tmp/MSBuild*` 连接成功

## 修复选项

| 方案 | 内容 | 状态 |
|---|---|---|
| **A（推荐）CI 打包补丁** | 在 sdk-ohos stage4 之后，对 SDK 内的 `Microsoft.Build.Framework.dll` 应用上面的 IL 补丁（Cecil 补丁器）；同时补 Roslyn 编译器服务器 DLL（见"实施"）。要求设备 `TMPDIR` 指向可建 socket 的目录（本机默认 `/data/storage/el2/base/tmp`） | **已实施并设备验证**（见下） |
| B 设备临时 | `taskhost-test/patcher/`（`dotnet patcher.dll <in> <out>`）+ `MBF.patched.dll`，覆盖前备份原文件 | 已完成使命（备用） |
| C 不改 SDK | 项目级 `UsingTask Override="true"`（现有规避）；`-p:UseSharedCompilation=false` 消除 Roslyn 服务器的 20 s 超时（非致命） | 仍有效（`test/hello-blazorwasm` 在旧 SDK 上自动回退此路径） |
| 上游（可选） | 向 dotnet/msbuild 提案"TMPDIR 感知 + 路径长度（108 字节）回退" | 未做 |

## 实施（2026-09-28，sdk-ohos `feature/openharmony`）

三个提交（`b52765daab` → `3fb944b658` → `1cbc1b8a6a`，均已推送；联合发布 run
[36367938255](https://github.com/springmin/sdk-ohos/actions/runs/36367938255)）：

1. **MSBuild 管道补丁**（`b52765daab`）：`eng/ohos-install/build/msbuild-pipe-patch/`
   （Cecil, `Microsoft.Build.Framework` 的 `NamedPipeUtil.GetPlatformSpecificPipeName`）+ 
   `patch-msbuild-pipe.py`（布局与 tarball 双覆盖、跳过 `ref/`、流式重写）+ stage4 钩子；
   补丁在 **签名前** 应用，`rc=0 已补 / 2 无类型 / 3 无方法 / 4 无需替换`。
2. **Roslyn 编译器服务器补丁**（`1cbc1b8a6a`）：同一条 IL 替换
   （`Microsoft.CodeAnalysis.NamedPipeUtil::GetPipeNameOrPath` 的 `ldstr "/tmp"` →
   `Path.GetTempPath()`），覆盖 `Roslyn/bincore/{csc,vbc,VBCSCompiler}.dll` 与
   `Roslyn/Microsoft.Build.Tasks.CodeAnalysis.dll`（客户端/服务器各有副本，需全部一致）；
   缺目标按 DLL 跳过（新增 `--scan` 诊断模式），补丁器按源码 mtime 失效缓存。
3. **`libdotnet-aot.so` 架构守卫**（`3fb944b658`）：布局陈旧 x86-64 残留清理（MSBuild target）
   + `check-sdk-arch.py verify` 在签名/发布前拒绝异架构 ELF + 21 项回归测试
   （根因：SDK 布局目录跨构建复用且从不清理）。

### 设备验证（arm64 OpenHarmony）

- **MSBuild**：把同一补丁器应用到设备 SDK 的 `Microsoft.Build.Framework.dll`，删除
  `blazor2/Directory.Build.targets` 中全部 7 条 `UsingTask Override` 后，
  `dotnet build`（Blazor WASM, Release）**rc=0 / 72 s（其中 40 s 为 restore）**、
  **0 次 task-host 重试、0 × MSB4216**、0 警告 0 错误。
- **Roslyn**：未补丁 `csc /shared` **22 s 回退** → 补丁后 **2 s**（socket 绑在 TMPDIR）；
  真实 hello 构建 **30 s → 11 s**。
- **端到端**：`test/hello-blazorwasm/run-smoke.sh`（ohos-workload）在补丁 SDK 上
  "publish succeeded **without** the task-host override"（642 文件 / 52 MB）。
- 前提：`TMPDIR` 可 bind（本机 `/data/storage/el2/base/tmp`）；管道名 43 字符 + TMPDIR(25) =
  68 < 108 字节 AF_UNIX 上限。

## 其他发现

- `libdotnet-aot.so`（arm64 SDK 内混入的 x86-64 库，每次启动报加载错误）：**已修**
  （`3fb944b658`，布局清理 + 发布前架构守卫；设备上坏文件已移走，`dotnet --version` 输出干净）
- Roslyn 编译器服务器（`csc/vbc/VBCSCompiler`）同类 `/tmp` 字面量：**已修**
  （`1cbc1b8a6a`），不再有每次编译 ~20 s 的服务器超时回退

## 验证产物（设备，未提交 git）

`/data/storage/el2/base/tmp/opencode/taskhost-test/`：`diag.log`、`diag2.log`、`comm-real/`（崩溃栈与
通信重试 trace）、`comm-patched/`（补丁后的成功 handshake）、`build-patched.log`、
`patcher/`（Mono.Cecil 补丁器）、`MBF.patched.dll`、`pipefix.c` 等。

设备已还原：`Microsoft.Build.Framework.dll` 恢复原文件（md5 `03910f5abc2deea083d06f49c3b36231`），
`blazor2/app/Directory.Build.targets` 恢复为覆盖版本（13.5 s 构建可用）。
