# INTERP-NULL：解释器 pack 与 rc.1 托管 CoreLib 的 QCall ABI 错配（2026-10-03）

> 输入：`WX-HOST-PRCTL` §2「prctl 解锁后解释器 `SIGSEGV(NULL)@coreclr_initialize`，首帧未达」；
> 设备 HAD-W24 / 7.0.0.111 / `127.0.0.1:35111`；证据 scratch `/data/storage/el2/base/tmp/opencode/fix-interp-null/`。

## 1. NULL 点（符号化到语句）

故障 `cppcrash…20261003084156075.log`（interp 件 BuildID `bc5ff740…`）：`SIGSEGV(SEGV_MAPERR)@0`，
末帧 `coreclr_initialize+1064`，其下 `RuntimeFieldHandle_GetRVAFieldInfo`。用当前 `.dbg`
（BuildID `4b30a4c1…`，与旧件逐指令比对，本函数地址 +0x1c8）反查：故障指令
`str xzr, [x3]`（`+0x38`，= `reflectioninvocation.cpp` 的 `BEGIN_QCALL` 首句 `*qcallError = 0`），
寄存器 `x3=0`。即原生的「隐藏 QCall 状态参」第 4 参为空，落点即 NULL。

## 2. 判定：rc.1 托管 CoreLib × rc.2 原生 = QCall ABI 错配（非 interp 缺陷）

- 失败的测试件 `kit41-local/interp/interp-k41-signed.hap` 是旧 `--no-restore` 发布：
  `runtimeconfig.json` = `Microsoft.NETCore.App 11.0.0-rc.1.26451.109`，
  `System.Private.CoreLib.dll` sha256 `fc6a7607…`，**无** `QCallExceptionStatusMarshaller`/
  `ErrorHandlerAttribute`；其生成包装对 qcall 只传 **3** 参（IL dump：`28 <PInvoke> sig=000308…0f09`）。
- interp pack 按 rc.2 主线构建；`#132420`（`qcall.h` / `RuntimeHandles.cs`）起 QCall 经
  隐藏末参传异常状态，rc.2 CoreLib 调 4 参（`sig=000408…0f18` + `QCallExceptionStatusMarshaller.ConvertToManaged`）。
- 解释器为第 4 参寄存器填入 0 → `*qcallError=0` 写 NULL。kit 自带 HAP 是自洽的
  （CoreLib `c1727b53…` rc.2 + 原生 `8df41ced…`），只有这张 stale interp 测试件是 rc.1 托管 + rc.2 原生。
- `UseGCWriteBarrierCopy=0`/宿主线程栈/写屏障/precode 均非本次原因（jitfort rc=0、probe 1=OK 2=OK）。

## 3. 修复与设备推进（HAD-W24）

按 **rc.2 kit HAP**（`kit41-local/kit/hello-maui-app.hap`，CoreLib `c1727b53…`）重组：
本 pack 的 `libcoreclr.so`/`libclrinterpreter.so` + `runtime-mode.txt=interp` + JITFORT 宿主
（`fdb85582…`），重签为 `fix-interp-kitrc2-signed.hap`（134,410,755 B，sha256 `c0862087…`）。

- `OHOS_DOTNET jitfort: rc=0 errno=0 state=off`；本 pack 构建 `libcoreclr 4b30a4c1`（sha `e150558a…`）+
  `libclrinterpreter 11fc5052`（sha `3e4b4d10…`，含 WX-PATCH2）。
- 九次启动：**无 `SIGSEGV`、无 `Failed to load System.Private.CoreLib`、无 `Failed to create CoreCLR`**；
  interp 执行 CoreLib 并推进到 MAUI `OpenHarmonyMauiAppHost.Run`/handler connector；
  **首帧达成**：`canvas presented (2090x1324)`（10:38:03/10:38:12，pid 35037；另一次 47 次轮询命中）。
- 其余轮次 `SIGABRT`：未处理托管异常 `Handler is already being set elsewhere`/
  `PlatformView cannot be null here`（MAUI OpenHarmony handler connector 重入竞争），与
  `WX-HOST-PRCTL` 记录的 JIT 线残留同族，非 CoreCLR/interp 故障（首帧因该竞争呈 flaky）。

## 4. 资产 / 发布（新名 + by-id）

`springmin/sdk-ohos` release `device-test-kit`，新资产 `ohos-interpreter-pack-rc2b.tar.gz`
（2,410,595 B，sha256 `5974430509…`，asset `RA_kwDOT39XK84kLhHb`）+ `.sha256`（`RA_…kLhHZ`）+
`-README.md`（`RA_…kLhHc`）；旧 rc2 资产保留。README 明确要求托管 pack **11.0.0-rc.2.26451.112**，
并给出 rc.1 组合的故障指纹与开箱自检命令（runtimeconfig 版本 + `QCallExceptionStatusMarshaller` 计数）。

## 5. 提交 / 不确定

- runtime-ohos `feature/openharmony`：本报告 + `WX-HOST-PRCTL` §4 更正（`commit-paths.sh`，未强推）。
- 不确定：MAUI handler 竞争使首帧 flaky（9 中 2 次出帧）；`interp.txt=1|2` 混合模式未复测；
  tester handoff（kit41 §1.3/主判点 3）仍引用旧 rc2 pack 与伪造的 411 行 canvas 记录，待父会话按本报告改写。
