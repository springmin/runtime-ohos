# JIT-ABORT：4 次 SIGABRT 定性 — 运行时未处理异常终止，非 JIT 缺陷（2026-10-03）

> 范围：SOAK 20:28–20:32 的 4 次 cppcrash（com.example.hellomauiapp，uid 20220261）；设备 HAD-W32 /
> 7.0.0.111，hdc 127.0.0.1:35111；原始 faultlog `soak/fl-now/cppcrash-…-20220261-*.log`，证据 scratch
> `/data/storage/el2/base/tmp/opencode/jit-abort/`（bin/ 提取件、dis/ 反汇编、hapcmp/ 清单比对）。

## 1. 崩溃栈 / 断言点（符号化，逐帧复验）

- 4/4 逐帧同签名（fault-thread：`479f3c 479de0 444940 441f84 441cd0 3d0694 4502e4`）；`SIGABRT(SI_TKILL)`
  自进程 raise；fault thread 是 .NET 主线程（Tid 1069/4233/5950/13196，宿主 `OhosAppThread`）。
  `assertFaultTHR` 只是 Other thread info 中一个空闲 AppExecFwk cond_wait 线程，非故障线程——更正。
- shipped libcoreclr build id `8df41ced…` 已 strip、无 .dbg；用本仓 rc.2+WX-PATCH2 件 `4b30a4c1…`
  （含 .dbg）做指令窗匹配后 llvm-addr2line 逐帧复验：`PROCAbort`(process.cpp:2074) ← `PROCEndProcess`(465)
  ← `SfiNextWorker`(exceptionhandling.cpp:4233) ← `DispatchExSecondPass`(4522) ← `DispatchManagedException`
  (1816) ← `IL_Throw_Impl`（帧 0x3d0694 处的 `bl 0x441b2c` 即 DispatchManagedException 入口）←
  `IL_Throw`(asmhelpers.S:3482) ← JIT 托管帧（裸地址 #09–#45）→ `coreclr_execute_assembly`。即托管 throw、
  无 handler → 运行时常规终止；无任何帧属于 libclrjit。
- 同 pre-fix JIT 线的完整托管轨迹（`wx-prctl/logs/host2-jit-inv/hilog.txt`，08:36–08:38 经 shell
  `[maui] status:` 镜像）：`System.InvalidOperationException: Handler is already being set elsewhere`
  @ `Element.SetHandler` ← `OpenHarmonyHandlerConnector.Connect/ConnectTree` ←
  `OpenHarmonyTabbedPageHandler.ArrangeContent` 与 `.../OpenHarmonyMauiAppHost.Run` 两入口并发；另
  `PlatformView cannot be null`。这 4 个实例未直接抓到（abort 前最后一次 status 轮询早于异常写入、进程
  即死），按同签名/payload 归档。

## 2. 实例归属：外部件，不是 SOAK kit42 的实例

- 4 份日志均映射 `hello-maui-app-jit.dll` span 827,392 B（=825,856 B 文件），与并发代理 framepacing 的
  `framepacing/out/jitnoprobe/jit-noprobe-hostfix-signed.hap` 完全一致（payload assembly
  `hello-maui-app-jit.dll`，zipSha256 `f897a072…`）；SOAK kit42 的 payload 是 `hello-maui-app.dll`
  (866,816 B)、无 `-jit` 条目。该外部件 app dll 无 `ConnectTreeCore/ConnectCore/s_connectSync`（pre-fix），
  kit42 JIT（`81e3c7fc…`）与 fix-slicerace 件都有 → 归属定案。
- 时序：20:24 SOAK 重启 → 20:27+ 外部装件/启动风暴（4 崩 20:28:26/29:07/29:24/32:18）→ 20:34 SOAK
  重启后 18 min 干净（0 崩）。framepacing install/stream 捕获 4135/12787 两次；4 次均在进入前台后 0.68–0.75 s 崩。

## 3. 判定与缺口

- **非 JIT 缺陷**：①路径为 .NET 未处理异常的常规终止（§1）；②同签名 abort 在解释器线（无 JIT）同样
  出现（`fix-interp-null/RESULT.md`）；③托管轨迹为 handler 竞争，根因/修复见
  `2026-10-03-ohos-handler-race.md`（maui-ohos `549967f2f0` + ohos-workload `f6cbbe8`，修复件 8/8 无崩溃）。
- 缺口：SOAK fault diff 不区分“同 bundle 外部件实例”，建议按每轮 `.dotnet-payload.json`/dll 名+大小
  过滤 faultlog；设备 `DeviceDebuggable:No`（`hdc smode` 拒绝、无 root），读不到 0600 dotnet-status.txt，
  4 实例异常文本只能靠下一次启动的 shell 轮询镜像而窗口不足——由 pre-fix 线全量轨迹代替；外部重装时序到分钟级。

## 4. 设备验证 / 提交
- 未另起加压：sibling screen-hyp 占用至 22:50（终局提交 `62febf1d4b0`；keyguard 锁需人工解锁）；本文件经 commit-paths.sh 提交（runtime-ohos `feature/openharmony`，未强推）。
