# JIT-ABORT：4 次 SIGABRT 定性 — 运行时未处理异常终止，非 JIT 缺陷（2026-10-03）

> 范围：SOAK 20:28–20:32 的 4 次 cppcrash（com.example.hellomauiapp，uid 20220261）；设备 HAD-W32 /
> 7.0.0.111，hdc 127.0.0.1:35111；原始 faultlog `soak/fl-now/cppcrash-…-20220261-*.log`，证据 scratch
> `/data/storage/el2/base/tmp/opencode/jit-abort/`（bin/ 提取件、dis/ 反汇编、hapcmp/ 清单比对）。

## 1. 崩溃栈 / 断言点（符号化）

- 4/4 同签名：`SIGABRT(SI_TKILL)` 自进程 raise；fault thread 是 .NET 线程（Tid 1069/4233/5950/13196，
  宿主 `OhosAppThread`，8 MB 栈仅用 ~15 KB）。`assertFaultTHR` 只是 Other thread info 中一个空闲
  AppExecFwk cond_wait 线程，非故障线程——SOAK 文档误读，特此更正。
- abort 路径（shipped libcoreclr build id `8df41ced…` 已 strip、无 .dbg；用本仓 rc.2+WX-PATCH2 件
  `4b30a4c1…` 做指令窗匹配后 addr2line）：`raise/abort` ← `PROCAbort`(`+0x479f3c`) ← `PROCEndProcess`
  ← `SfiNextWorker` ← `DispatchExSecondPass` ← `DispatchManagedException` ← `IL_Throw_Impl` ← `IL_Throw`
  ← JIT 托管帧（`[Unknown]`）→ … → `coreclr_execute_assembly`。即**托管 throw、无 handler → 运行时终止**。
- 无帧属于 `libclrjit.so`（它只在 Maps 里，表示 JIT 已启用）；`[Unknown]` 是 JIT 生成的匿名可执行页。

## 2. 实例归属：外部件，不是 SOAK kit42 的实例

- 4 份日志均映射 `hello-maui-app-jit.dll` span 827,392 B（=825,856 B 文件），与并发代理 framepacing 的
  `framepacing/out/jitnoprobe/jit-noprobe-hostfix-signed.hap` 完全一致（其 payload `"assembly":
  "hello-maui-app-jit.dll"`）；SOAK kit42 的 payload 是 `hello-maui-app.dll`(866,816)、无 `-jit` 条目。
  framepacing 的 install/stream（20:29/20:32）捕获了其中 2 次（4135/12787）启动；4 次 life 18–43 s，
  均在进入前台后 0.68–0.75 s 崩。
- 时序：20:24 SOAK 重启（pid 22036）→ 20:27+ 外部装件/启动风暴（4 崩）→ 20:34 SOAK 重启后 18 min 干净。
  SOAK 的 fault diff 把外部实例计入了 JIT 段；伴发 AppFreeze（21:17）亦为外部件、不在本窗口。

## 3. 判定与缺口

- **非 JIT 缺陷**：①路径为 .NET 未处理异常的常规终止；②同签名 abort 在解释器线（无 JIT）同样出现
  （`fix-interp-null/RESULT.md`：MAUI handler races, same as JIT line）；③当日完整托管轨迹为
  `System.InvalidOperationException: Handler is already being set elsewhere`
  @ `OpenHarmonyHandlerConnector.ConnectTree` ← `OpenHarmonyTabbedPageHandler.ArrangeContent`；
  根因/修复见 `2026-10-03-ohos-handler-race.md`（maui-ohos `549967f2f0` + ohos-workload `f6cbbe8`，
  修复件 8/8 无崩溃）。这 4 个实例的异常文本未直接捕获（宿主 status 停在 `notify evt=…`），按签名/时序归档。
- 缺口：SOAK fault diff 不区分“同 bundle 外部件实例”；建议按每轮安装件的 `.dotnet-payload.json`/
  app dll 名+大小过滤 faultlog（或独占设备重跑）。「assertFaultTHR / libclrjit」表述应更正。

## 4. 设备验证 / 提交

- 未另起加压：21:44 起设备被 sibling screen-hyp 占用（同 HAP A/B 轮；Arm A 前 8 轮 `new_c=0/new_f=0`，
  只读核对 rounds/faultlog）。既有：修复件 8/8 PASS；SOAK 20:34–20:52 干净窗 18 min 0 崩溃。
- 提交：本文件（runtime-ohos `feature/openharmony`，`commit-paths.sh`，未强推）。
- 不确定：4 实例托管异常文本未直接捕获；外部重装时序只到分钟级；外部件 MAUI/host 变体内容未逐字节核对。
