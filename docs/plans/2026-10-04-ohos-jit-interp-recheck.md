# JIT/interp 设备复核（DEV-JITINTERP 重试，2026-10-04）

> 前置：系统恢复 + 设备 21:36 重启后；hdc `127.0.0.1:35111`；bundle `com.example.hellomauiapp`。
> 件（kit #45 切片同源重出：ow `b6ad0b0` / maui `189b87ca8a` = INTERP-RENDER + AUTODISCONNECT，均带 FramePhaseProbe）：
> JIT = libcoreclr `5791c298…` + libclrjit + 宿主 `7b1694d9…`（JITFORT/prctl）；interp = rc2b pack（libcoreclr
> `1024af70…` / libclrinterpreter `6a424da7…`，`.codesign` 后哈希，与 kit42 验证件同源）；AOT = 仅宿主 + 200 KB payload。
> 方法：cold = uninstall+install+start；warm = force-stop+`bm clean -d`+start；hilog epoch 流按 (t0,pid) 锚定重解析；
> 首帧后截图；CPU = `/proc/<pid>/stat` 10 s 窗（整进程）；FPH = 探针 5 s 窗；host 5 s present 桶 = FRAMEPACING。
> 证据 scratch `/data/storage/el2/base/tmp/opencode/jitinterp-recheck/`（logs/markers/stream/screens/engine）。

## 1. JIT 路径（#45 主线件）
| run | jitfort | payload→app→run_app | 首帧 est | 截图 | FPH fps（稳态窗） | host 桶 | CPU 10 s 窗 |
|---|---|---|---|---|---|---|---|
| cold | rc=0 errno=0 state=off | 148→149→275 ms | 1496 ms | ✅ | 56.7–60.1 | 300 帧 / 16 ms | 46.9 / 52.1% |
| warm | rc=0 errno=0 state=off | 160→160→288 ms | 1512 ms | ✅ | 55.9–60.1 | 300 帧 / 16 ms | 53.8 / 44.2% |

- **60 fps 复核通过**（FPH ≈57–60 与 host 16 ms 桶一致）；CoreLib→MAUI→首帧链路无失败标记、无新 fault（前后 `hidumper -e` 差集空）。

## 2. interp 路径（rc2b pack + 优化后件）
| run | jitfort | 首帧 est | 截图 | FPH fps（全窗） | host 桶 | CPU 10 s 窗 |
|---|---|---|---|---|---|---|
| cold | rc=0 state=off | 1458 ms | ✅ | 36.4–42.5 | 232 帧 / 21 ms | 75.1 / 64.9% |
| warm | rc=0 state=off | 1377 ms | ✅ | 35.3–45.8（单窗 53.4） | 247 帧 / 20 ms | 85.4 / 77.0% |

- 引擎判据（engine smaps）：`libclrinterpreter.so` 268 KiB + `libcoreclr.so` 5016 KiB，**`libclrjit` 0 行** → 解释器确在运行。
- **fps 约 38–44（FPH 稳态），高于 #45 交接的 30.1**：本波 draw 14.3 ms / pres 1.4 ms（#45 时 18.6/3.2，属共享桌面争用态），
  meas 0.0 表明渲染门控在场；16 ms 级帧预算可常踩 1×vsync ⇒ 安静桌面下的上限提升，非回归。CPU 对照：interp 比 JIT（§1）高约 20–30 pt。

## 3. 启动分解（三路径 cold/warm 到首帧；ms，自 AMS `StartAbility` 行）

| 路径 | run | payload | app | run_app | 首帧 est | t0→首帧* |
|---|---|---|---|---|---|---|
| JIT | cold / warm | 148 / 160 | 149 / 160 | 275 / 288 | 1496 / 1512 | 1.68 / 1.68 s |
| interp | cold / warm | 165 / 151 | 166 / 152 | 295 / 277 | 1458 / 1377 | 1.62 / 1.56 s |
| AOT | cold / warm | 162 / 152 | 162 / 153 | 295 / 281 | 1517 / 1484 | 1.69 / 1.64 s |

- 口径：`t0` = 发 `aa start` 前的宿主墙钟；AMS 行 ≈ t0 + 0.16–0.18 s（`*首帧总量 = est + 该差值`）；payload/app 常同毫秒
  （宿主 payload-in-libs / 托管启动）；run_app = MAUI 线程入口；首帧 est 由 host 首个 5 s 桶（n×avg）外推——该宿主只发桶汇总、
  无裸 `canvas presented` 行；cold/warm 定义见文首。三路径差异 <200 ms（JIT/interp 无启动惩罚）。
- 重放注意：本机 hilog 未清且从缓冲回放开播，解析必须按 (t0,pid) 锚定，否则会静默取到上一轮 AMS/fps（本波已修）。

## 4. interp draw 深挖（可选）

未跑（设备锁排队 dev-a11y，需重编译带 `DrawCostTick` 切片）。FPH 相位已给 draw 均值 14.3 ms vs JIT 3.6 ms（≈4×）。

## 5. 提交 / 不确定

- 提交：本报告（runtime-ohos `docs/plans/`）；`commit-paths.sh` 限定路径提交、普通推送（未强推）。
- 不确定：单设备共享 2in1、每格冷/热各 1 轮；interp 与 #45 的 30.1 差异未二分（draw/pres 同降）；AOT 件未编入 FPH
  （60 fps 由 host 桶背书）；jitfort=rc=0 仅证启动前 prctl 成功，长跑/后台唤醒未覆盖。
