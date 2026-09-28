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
| **A（推荐）CI 打包补丁** | 在 sdk-ohos stage4 之后，对 SDK 内的 `Microsoft.Build.Framework.dll` 应用上面的 IL 补丁（Cecil 补丁器）；可选同时补 Roslyn 编译器服务器 DLL。要求设备 `TMPDIR` 指向可建 socket 的目录（本机默认 `/data/storage/el2/base/tmp`） | 待实施 |
| B 设备临时 | `taskhost-test/patcher/`（`dotnet patcher.dll <in> <out>`）+ `MBF.patched.dll`，覆盖前备份原文件 | 已可用 |
| C 不改 SDK | 项目级 `UsingTask Override="true"`（现有规避）；`-p:UseSharedCompilation=false` 消除 Roslyn 服务器的 20 s 超时（非致命） | 已验证 |
| 上游（可选） | 向 dotnet/msbuild 提案"TMPDIR 感知 + 路径长度（108 字节）回退" | 未做 |

## 其他发现

- `libdotnet-aot.so` 是 **x86-64** 库却被 arm64 SDK 每次启动时尝试加载并报错（非致命，建议清理）
- Roslyn 编译器服务器（`csc/vbc/VBCSCompiler`）含同类 `/tmp` 字面量：失败后回退进程内编译
  （每次约 20 s 超时；`UseSharedCompilation=false` 可规避）

## 验证产物（设备，未提交 git）

`/data/storage/el2/base/tmp/opencode/taskhost-test/`：`diag.log`、`diag2.log`、`comm-real/`（崩溃栈与
通信重试 trace）、`comm-patched/`（补丁后的成功 handshake）、`build-patched.log`、
`patcher/`（Mono.Cecil 补丁器）、`MBF.patched.dll`、`pipefix.c` 等。

设备已还原：`Microsoft.Build.Framework.dll` 恢复原文件（md5 `03910f5abc2deea083d06f49c3b36231`），
`blazor2/app/Directory.Build.targets` 恢复为覆盖版本（13.5 s 构建可用）。
