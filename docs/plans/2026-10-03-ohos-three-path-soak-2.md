# 独占窗口三路径浸泡（SOAK2）：AOT / JIT / interp 各 45 min — 0 崩溃 / 0 冻结 / 0 重启（2026-10-03/04）

> 设备 HAD-W32（OpenHarmony-7.0.0.111 / API 26 / 2in1），hdc `127.0.0.1:35111`；独占窗口 2026-10-03 22:52:32 → 2026-10-04 01:39:42。
> 资产（自签；三件均换 FRAMEPACING 宿主 `aa6f485`，host sha256 `7b1694d9…`）：AOT `aot-soak2-signed.hap` 22,308,504 B `2061d904…`；
> JIT `jit-soak2-signed.hap` 134,191,428 B `8c39e968…`；interp `interp-soak2-signed.hap` 134,509,539 B `a2a83e2a…`。被测 P = `com.example.hellomauiapp`。
> 方法：每路径 uninstall→装→`hilog -r`→启动→45 min 采样窗；每 5 min 采 pid/VmRSS/线程/新崩溃/frame 增量（新宿主 5 s 汇总行）；
> 每 15 min 扰动（抽屉开合 + Back 前后台）；每轮 `updateTime` 检测外部重装。证据 scratch `soak2/`（out/{aot,jit,interp}、aux/、logs/）。

## 1. 控屏与互斥前置

- 常亮方法：`power-shell wakeup` + `power-shell timeout -o 21600000`（`bin/screen-keepawake.sh` 每 60 s 检查、每 5 min 重申；另每 5 min 采样兜底 wakeup）。
  全段采样 `pm=AWAKE / render=POWER_STATUS_ON`，0 次 `10106102`。`power-shell setmode` 仅设功耗模式（600–603）非常亮；设备无 `settings` 命令 → 两法不可用已记录（`out/screen-method.txt`）。
- 互斥：SCREEN-HYP 22:50 终局（`62febf1d4b0`，其遗留锁屏经 wakeup+截图确认已解锁）；JIT-ABORT 仅主机侧反汇编；全程他代理 device 进程 0、其 scratch 近 3 min 写入 0（15 min 巡检）。
- faultlog 过滤（按 JIT-ABORT §10）：已建三路径载荷/引擎签名 —— AOT=`libhello-maui-app.so`（无 coreclr）/ JIT=`hello-maui-app.dll`+`libclrjit` /
  interp=+`libclrinterpreter`（无 `libclrjit`）/ 外部 pre-fix 件=`hello-maui-app-jit.dll`；工具 `bin/classify-fault.sh`。本轮 `fault-new.txt` 三段全空，无需归属。

## 2. 三段结果（45 min 采样窗，10 采样点/段）

| 路径 | 采样窗 | pid / 失pid / 重启 | RSS 首→末（增量） | 峰 / 谷（t） | 线程 | 新崩溃/冻结 | frame |
|---|---|---|---|---|---|---|---|
| AOT | 22:53:08–23:38:08 | 39638 / 0 / 0 | 247,568→253,604 kB（**+5.9 MB**） | 295,500(t=300) / 242,840(t=900) | 70→68 | 0 / 0 | 6,601 |
| JIT | 23:48:53–00:33:53 | 49576 / 0 / 0 | 326,852→356,700 kB（**+29.2 MB**） | 405,636(t=601) / 356,484(t=2100) | 72→70 | 0 / 0 | 6,619 |
| interp | 00:44:34–01:29:34 | 5261 / 0 / 0 | 333,372→381,184 kB（**+46.7 MB**） | 393,764(t=900) / 367,360(t=1501) | 71→69 | 0 / 0 | 2,713 |

- 判读：三段均在启动后 5–10 min 热身上峰（AOT +47.9 / JIT +78.8 / interp +60.4 MB），随后进入锯齿带（AOT 242.8–261.5 / JIT 356.5–364.6 / interp 367.4–393.8 MB）；
  末点均落在带内，**无单调增长**（首末差主要来自"首点=冷启、末点=带内高点"的取样位置差）。
- 引擎归属（末次 smaps）：AOT 3 libs（libhello-maui-app 19.2 MB，无 coreclr）；JIT 7 libs（libclrjit 2.78 MB + libcoreclr 4.93 MB）；interp 7 libs（libclrinterpreter 268 KB + libcoreclr 5.13 MB，无 libclrjit）；启动行 `jitfort rc=0`（JIT）/ `runtime-mode=aot`（AOT）。
- frame：新宿主 5 s 汇总行仅活跃期产出，三段各 22 行且含 `[maui]/[managed]` 镜像重复（~2× 虚高）→ 仅作活跃度指标；interp `n≈137 avg≈36 ms`（~24 fps）vs AOT/JIT `n≈301 avg≈16 ms`（60 fps），与引擎预期一致。

## 3. 扰动与干扰判据

- 扰动 9/9（每段 t=15/30/45 min）：均 BACKGROUND→FOREGROUND、pid 不变、无 `10106102`、无崩溃；FG 后 RSS 回落 10.5–40.3 MB（后台回收）。
- 干扰全干净：每段 `updateTime` 首=末（1791039159045 / 1791042501473 / 1791045844580）无外部重装；`managed app hello` 每段 1 次（无重启）；
  `Failed to…` 命中均为系统 AppGallery remote configuration；hilog 已 `-G 512K` 还原；收尾捕获管道等 timeout 到期（每段 +~10 min，不影响采样窗）。

## 4. 结论 / 不确定项

- **发布背书：可以** —— 独占窗口 135 min（AOT+JIT+interp 各 45 min）0 CppCrash / 0 AppFreeze / 0 失 pid / 0 重启 / 0 外部件干扰，屏幕常亮受控，9/9 扰动通过；JIT/interp 的 RSS 波形为热身+GC 锯齿，非泄漏。
- 不确定：单设备（2in1、debug 签名域）、热缓存启动（start_ms 6.5–6.7 s）；frame 汇总受镜像重复与仅活跃期产出限制，非节奏测量（节奏见 FRAMEPACING）；未测锁屏/NAP 干预（见 SCREEN-HYP `62febf1d4b0`）。
