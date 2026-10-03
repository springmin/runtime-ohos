# JIT 解锁波 + 三路径收口（MAUI-CONSOLIDATE-JITWAVE，2026-10-03）

> 本波 = maui `549967f2f0`（+`96034e2acf`/`1926cf68b6`/`7064bb8c1c`）· ow `f6cbbe8`
> （+`3a4bcbf`/`e5d1d62`/`7de4b7d` 等）· runtime 对应 docs（WX-HOST-PRCTL/INTERP-NULL/SAMPLE-FIX/
> LEGACY/FIX-SLICERACE）。收口树 = ow `740980d`：`65be592` 合并并发已推 `4bfcd68`/`67381f9`，
> `f80f0d2` 把三 workflow pin 推进到 `549967f2f0`，`740980d` 刷新 kit #42 校验器（356468/258）；
> 三仓提交全部在主线（并发分叉已合并收口）、快进推送、未强推。

## 1. JIT 解锁（WX-HOST-PRCTL，ow `3a4bcbf`）
- 宿主 `OhosHostApplyExecMemoryPolicy` 在 hostfxr 前 `prctl(0x6a6974,0,0)`（默认开；
  `DOTNET_OHOS_NO_JITFORT=1` 逃生、`runtime-mode=aot` 跳过、失败回落 xwe=0，状态行 `jitfort rc/errno/state`）。
- 无系统 ICU：同点探测 `libicuuc` 缺失即导出 `DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1`（`DOTNET_OHOS_ICU` 可覆盖）。
- 真机 HAD-W32：`rc=0 errno=0 state=off`、探针 `1=OK 2=OK`、CoreLib/MAUI init、`canvas presented`（4–8）。

## 2. 三路径
- **JIT**：解锁后 RWX 提交可用（arm64 默认写屏障，不需要 `interp=3` 的 `UseGCWriteBarrierCopy=0`）；
  kit DeviceCompat 件 + 新宿主重签出帧。
- **解释器**：`0x800701E7` 墙消失；`SIGSEGV(NULL)@coreclr_initialize` 定性为 stale 件 rc.1 托管 ×
  rc.2 原生 QCall ABI 错配（`BEGIN_QCALL` 写 `*qcallError=0`）；按 rc.2 kit HAP 重组 rc2b pack 后无
  NULL、推进到 MAUI init、首帧 flaky。
- **AOT**：`jitfort: skipped`、`canvas presented`=765、无 CoreLib 失败；runtime 侧 WX-PATCH2
  （双映射预检 + 写屏障 Commit 降级，`07700380098`）。

## 3. race（FIX-SLICERACE，maui `549967f2f0` + ow `f6cbbe8`）
- 根因：`Run` 的 `ConnectTree`（app 线程）与 shell 线程 `SurfaceChanged/Frame→Arrange→ConnectTree`
  并发，`SetHandler` check-then-set 非重入 → “Handler is already being set elsewhere”/PlatformView-null/
  集合腐坏（JIT 慢启动放大）。
- 修复：连接器重入锁串行 `Connect/ConnectTree`；宿主 `_sync` 串行全部触树入口 + `_ready` 门闩。
- 真机 JIT 8/8（`race=0 pvnull=0 conc=0 unhandled=0 jitfort=1`）；套件 +3（connect storm/host storm/源码 pin）。

## 4. 收口清单
- 切片 trim/AOT 分析器 0 error / 0 IL；交互套件 `checks=578 total=580 floor=560 assert=True`（perf 全 `within=True`）。
- 像素 `PIXEL ASSERTIONS PASSED`；导出 `OK: all 151 expected exports`（L6 `96034e2acf` 经 `ohos_host_screenshot_format` +1）。
- 壳四包 preview.22/23/24/28：ui 356,468 B `dd04dad1…`、headless 24,324 B `798b2477…`；
  `abc-provenance.json` 四包一致、`--check-pack-abc` clean；kit #42 校验器期望 356468/258（`740980d`）。
- preflight 5/5（首轮 csc 活锁 → `DOTNET_PROCESSOR_COUNT=1` 重跑全绿）；CI 5/5（push `740980d`）：
  interaction `37096467502` / pixel `37096467496` / host-export `37096467506` / ridgraph `37096467507` /
  markdownlint `37096467538`。
- 推送：maui `549967f2f0`、ow `740980d`、runtime 本文件；fast-forward、未强推。

## 5. 不确定
- 解释器 rc2b + race 修复的组合未重跑（首帧 flaky 属修复前竞争）；race 锁启动期丢帧属预期。
- AOT 与长时后台未在本波重跑；csc 活锁仅以 `DOTNET_PROCESSOR_COUNT=1` 规避（非根治，见 M-ITEMS L2）。
