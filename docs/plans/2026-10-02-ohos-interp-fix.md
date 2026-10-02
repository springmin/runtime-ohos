# INTERP-FIX：解释器路径起步崩的根因与 rc.2 重建（2026-10-02）

> 输入：DEVCOMPAT-DEFAULT 记录「interp 两库换入后崩于 interp libcoreclr `coreclr_initialize+440`；
> 判为 pack/runtime 兼容性」。本轮结论：**该判断不成立** —— 起步崩与 interp pack 无关，stock rc.2
> libcoreclr 在同一设备、同一 app 线程上以完全相同的两处崩溃复现；修复 = 宿主阈值修复
> （ohos-workload）+ 用当前 rc.2 主线重建 interp 产物并重打 pack（本仓）。
> 证据 scratch：`/data/storage/el2/base/tmp/opencode/interp-fix/`。

## 1. 崩溃点（addr2line 到具体调用）

DEVCOMPAT 的 interp faultlog（`cppcrash-com.example.hellomauiapp-20220243-20261002203402339.log`，
interp libcoreclr BuildID `0b3291010a9b8ba189800f814f56d3348503a045`）反查：

```
#03 coreclr_initialize+440
#02 PAL_InitializeCoreCLR (pal.cpp:633, Initialize(PAL_INITIALIZE_CORECLR))
#01 Initialize (pal.cpp:357, flags & PAL_INITIALIZE_ENSURE_STACK_SIZE)
#00 EnsureStackSize (pal.cpp:233, _alloca(0x180000) 的落点写入)
```

即 `EnsureStackSize(g_defaultStackSize=1572864)` 的 `_alloca(1.5 MB)` 落到了线程栈映射之下
（`SIGSEGV_MAPERR`，寄存器 `x0=0x180000`、`sp==fault`）。用旧 pack 复跑 5 次：
1× `EnsureStackSize`（MAPERR）+ 4× `InitThreadManager`（`threads.cpp:1211` 的 GC 写屏障 memcpy，
`memcpy+312`，`SEGV_ACCERR@0x5ccc…`，`coreclr_initialize+996`）。

## 2. 根因（两条都与 pack 无关；stock 同样复现）

- **stock 对照**：同一 HAP 域，stock rc.2 libcoreclr（BuildID `8df41ced…`）在 2026-10-02
  19:57/20:02/20:03 三次崩在 `coreclr_initialize+440` 的同一 `EnsureStackSize`（stock 符号
  `0x46bf6c`），20:04/20:28 崩在同一 `InitThreadManager` memcpy（`+996`）。DEVCOMPAT 只把
  memcpy 那次记成「JIT 预期」，把 `+440` 记到了 interp 头上。
- **1 MB 线程栈 vs 1.5 MB PAL 探针**：本机 OHOS musl 的默认 pthread 栈 = 1 MB
  （`/system/lib/ld-musl-aarch64.so.1` 中 `pthread_attr_init` 读取的默认值：0x100000 / guard
  0x2000；已把该 libc 拉到 scratch 核对），而宿主 `pthread_attr_init` 后只设 detachstate。
  CoreCLR MUSL 构建带 `PAL_INITIALIZE_ENSURE_STACK_SIZE`，`InitializeDefaultStackSize` 固定
  1.5 MB → 探针必然越过映射；这也解释为什么偶发「通过」（调用深度/映射边界相差数 KB）。
- **RWX 写屏障页被 HAP 域拒绝**：`FEATURE_DYNAMIC_CODE_COMPILED=1` 时
  `ExecutableAllocator::Commit(..., isExecutable=true)` 请求 `PAGE_EXECUTE_READWRITE`；
  该 mprotect 在 HAP 域失败且 Commit 返回值未被检查，页保持 PROT_NONE，随后
  `InitThreadManager` 的 `memcpy`（arm64 `UseGCWriteBarrierCopy` 默认 1）以 ACCERR 崩溃。
  纯解释（InterpMode=3）不需要该拷贝。
- 解释器库、`DOTNET_InterpMode` 解析路径在两次崩溃中都尚未被触及，与 pack/版本差异无关。

## 3. 修复

- **ohos-workload 宿主**（`src/OpenHarmonyHost/openharmony_host.c`，提交 `c9916cd`）：
  1) app 线程 `pthread_attr_setstacksize(&attr, 8 MB)`（覆盖 PAL 1.5 MB 下限）；
  2) 解析为 `interp=3` 时 `setenv("DOTNET_UseGCWriteBarrierCopy","0")`（JIT 模式保持默认）。
- **runtime-ohos**：`scripts/ohos-runtime-interp-fullbuild.sh` 切到 rc.2 默认
  （`rc/2/20260901.112`），并加三项宿主侧修正：内网 dotnet-optimization 包版本夹持到缓存版本
  （OpenHarmony 不消费该数据）；`DOTNET_PROCESSOR_COUNT=1`（rc.2 csc 在本机并行跑仓库 task
  项目的 source generators 会活锁：整组分析器时单项目 >120 s 不返回，去掉任一生成器或
  `/parallel-` 秒回）；comment 记录（见脚本）。
- **重建产物**（`-subset clr.native --cross -clrinterpreter`，`FEATURE_INTERPRETER=1`）：
  - `libcoreclr.so` 5,130,328 B，sha256 `fd79f2bf…1056a0d`，BuildID `bc5ff740…0fcf4aee`；
    宽字符串 `clrinterpreter`/`InterpMode`/`InterpreterName` 全在；`DT_NEEDED` 与 stock 一致。
  - `libclrinterpreter.so` 268,320 B，sha256 `75360e65…048e7d4bc`，BuildID `ba83106b…1c70d753`；
    导出 `getJit@@V1.0`/`jitStartup@@V1.0`。

## 4. 本机端到端（HAD-W24 7.0.0.111，hdc 127.0.0.1:35111）

- **变量隔离**：旧 rc.1 pack HAP + 新宿主连跑 3 次全部存活并出画（修复前同一 HAP 5/5 崩）；
  barrier skip 仅在 `interp=3` 时注入 → 存活即证明解释器开关被解析。
- **新 pack HAP**：`runtime-mode.txt=interp`、staged BuildID `bc5ff740…`/`ba83106b…`、新宿主
  （sha256 `8d67def3…`）；`install bundle successfully` → 启动；t+25 s 进程存活、faultlogger
  **0 条新 `cppcrash`**（最新仍是 20:34 修复前记录）；15 s 窗口 **411 行
  `canvas presented (2090x1324)`**，含 `[maui] media self-test` 与 ArkWeb 首帧记录。
- 判定：`coreclr_initialize+440` 崩溃点消失、无后续 `InitThreadManager` 崩溃。本镜像 hilog 看不到
  `interp=3` 行（宿主 stderr 混流被 ArkWeb 日志淹没），以上行为链为本机判据。

## 5. 资产与发布

- `springmin/sdk-ohos` release `device-test-kit`（`gh release upload --clobber`，新名）：
  - `ohos-interpreter-pack-rc2.tar.gz` id `RA_kwDOT39XK84kHaxL`，2,409,070 B，
    sha256 `34709a949a4939a2f642e2911ce6393f5f2229d91f05e90cb66bdc94918d6cbf`（下载复核一致）
  - `ohos-interpreter-pack-rc2.tar.gz.sha256` id `RA_kwDOT39XK84kHaxW`
  - `ohos-interpreter-pack-rc2-README.md` id `RA_kwDOT39XK84kHaxZ`
- 旧 rc.1 资产（`ohos-interpreter-pack.tar.gz` id `RA_kwDOT39XK84jK3yN` 等）保留不动；新
  README 标注其记录的崩溃已更正诊断。

## 6. 提交（禁强推）

- ohos-workload `master`：`c9916cd`（host fix；已推）
- runtime-ohos `feature/openharmony`：本报告 + `scripts/ohos-runtime-interp-fullbuild.sh`
- sdk-ohos `feature/openharmony`：`eng/ohos-install/build/package-interp-pack.py` + 说明

## 7. 不确定项

- 宿主修复对 stock JIT 路径的效果未单独复测（预期 8 MB 栈修复 `+440`；JIT 仍受 RWX 拒绝限制）。
- `UseGCWriteBarrierCopy=0` 只随 `interp=3` 注入；`interp.txt=1|2`（混合模式）保留默认。
- 匿名可执行映射未在 app 内枚举（状态文件被 ArkWeb stderr 淹没）；Precode/UMEntryThunk 的残余
  可执行页仍是纯解释启动的已知开放点。
- 仅本镜像 7.0.0.111 实测；rc.2 构建在 OHOS 宿主上的 csc 并行活锁已用 `DOTNET_PROCESSOR_COUNT=1`
  绕过，但未定位到具体 generator/analyzer 组合。
