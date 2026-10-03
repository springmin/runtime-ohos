# WX-HOST-PRCTL：宿主 JITFORT 解锁落地（2026-10-03）

> 范围：ohos-workload `src/OpenHarmonyHost/openharmony_host.c`（启动序）+ `docs/openharmony-hap-packaging.md`（JIT 策略节）；
> 设备 HAD-W32 / 7.0.0.111(SP3ENTC293E104R2P1log) / API 26 / 2in1，hdc 无线 `127.0.0.1:35111`。
> 证据 scratch `/data/storage/el2/base/tmp/opencode/wx-prctl/`（`build-host.log`、`repack-*.log`、
> `logs/host2-*`、`logs/replay`）；平台矩阵见 `2026-10-03-ohos-wx-probe-matrix.md`。

## 1. 宿主改动

- `prctl(0x6a6974, 0, 0)`（NDK `sys/prctl.h` 无 `PR_SET_JITFORT` 定义，用字面量）加在两条启动
  路径共用的 `OhosHostApplyExecMemoryPolicy` 内、hostfxr 初始化前；默认开启、每进程一行
  `OHOS_DOTNET jitfort: rc= errno= state=`（hilog/stderr + `dotnet-status.txt`）。探针在其后运行，
  `1=OK 2=OK` 即解锁见证。
- 逃生口 `DOTNET_OHOS_NO_JITFORT=1`；失败不致命：保持 xwe=0 既有路径，rc/errno 记录后继续。
- 显式 `runtime-mode=aot` 跳过（`jitfort: skipped runtime-mode=aot`）：AOT 零动态 exec，不改平台态。
- ICU 回退：本镜像无系统 ICU，JIT/解释器托管启动即 FailFast（`Couldn't find a valid ICU package`）。
  宿主探测 `dlopen("libicuuc.so")`，缺失即导出 `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`
  （`DOTNET_OHOS_ICU=0|1` 可覆盖），状态行 `OHOS_DOTNET globalization: invariant= icu= source=`。
- xwe/写屏障协同：`interp=3` 的 `DOTNET_UseGCWriteBarrierCopy=0` 原样保留；JIT 保持 arm64 默认
  （解锁后 RWX 提交可用，无需该绕行；属宿主策略）。

## 2. 真机结论（决定性）

- **JIT（kit DeviceCompat 件 + 新宿主重签）**：`jitfort rc=0 errno=0 state=off`、探针 `1=OK 2=OK`、
  CoreLib 通过、MAUI 初始化、**`canvas presented`（4–8 次）**，UI 截图（drawer/按钮）；与 AOT 对照成立。
  首帧证据轮 HAP 的 runtimeconfig 亦预置 `System.Globalization.Invariant=true`（宿主同轮探测并置位）；
  无 config 轮全部实例输给 MAUI 切片处理器竞争 `Handler is already being set elsewhere`（status 回放
  证实非 ICU），如实登记为残留（与本改动无关，配置两路同样命中）。
- **解释器（rc2 pack + 新宿主）**：`0x800701E7`（CoreLib 执行墙）消失；新故障 SIGSEGV(NULL)
  @`coreclr_initialize`，首帧未达，如实登记。
- **AOT 回归**：`jitfort: skipped runtime-mode=aot`、`canvas presented`=765、无 CoreLib 失败 → 不受影响。

## 3. 门禁 / 提交

- build-host 契约：导出 151/151（并发 L6 提交新增 `ohos_host_screenshot_format`；本改动不改导出），
  DT_NEEDED/UND 白名单、selfsign 全通过。
- 交互套件：`[suite] checks=575 total=577 floor=557 assert=True`（≥ 563/543，本地最新基线；
  `wx-prctl/interaction-run2.log`）。
- 提交：本文件与 ohos-workload（宿主 + 打包/JIT 策略文），`commit-paths.sh`，未强推。

## 4. 不确定

- 设备在测试前已被并发探针置为解锁（未重启），fortified 基线取自 WX-PROBE A/B；未再测
  relock→新宿主 的完整因果序。
- JIT 首帧随实例竞争波动（截图 08:15 轮）；release/生产签名域与跨重启未测；解释器 NULL 栈未符号化。
