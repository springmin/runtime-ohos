# 三路径设备基线：AOT / JIT / 解释器（DECIDE-BASELINE，2026-10-03）

> 设备 HAD-W32（OpenHarmony-7.0.0.111(SP3ENTC293E104R2P1log) / API 26 / 2in1），hdc `127.0.0.1:35111`；签名 = rc.2 线 preview.28 `sign-hap.sh`（tester UDID）。
> 资产：JIT = kit #42 主件重签 `jit-kit42-signed.hap`（134,191,593 B / `81e3c7fc…`，含 prctl 宿主 `08abe185…`）；interp = rc2b 重组件 `interp-kit42-signed.hap`（134,509,532 / `69bb864d…`）；
> AOT = rc.2 `-r2` AOT `host2-aot-signed.hap`（21,849,484 / `e7cc9a5f…`；kit #42 无 AOT 件，取 WX-HOST-PRCTL 回归件）。被测 P = `com.example.hellomauiapp`；证据 scratch `decide-baseline/`（未提交）。
>
> 方法：每路径 3 轮 `aa force-stop` → `hilog -r` → 全量 hilog（`-v epoch`）→ `aa start`；启动时延 = 首条 `canvas presented` − 起跑壁钟（同设备钟）。
> 帧节奏 = 首帧 +2..42 s（行数、5 s 桶 min/max、最大相邻间隔）；VmRSS/Threads = `/proc/<pid>/status`；RSTree = `hidumper RenderService RSTree` + `allSurfacesMem`；
> 引擎判据 = `hidumper --mem-smaps`（`entry/libs/arm64/lib*` 行，名称截断 + Size）；长跑 = 31×60 s（16 M hilog，60 s 采 pid/VmRSS/Threads，`hidumper -e` 崩溃 diff）；
> 前后台 ×10 = Home 轮（状态未变，见 §2）＋ Back 轮（`uitest uiInput keyEvent Back` 至 `#BACKGROUND` → `aa start`）。

## 1. 三轮基线（同一设备，debug 签名域）

| 路径 | start ms r1/r2/r3 | payload→canvas r1 | fps40 r1/r2/r3 | 帧/40 s r1/r2/r3 | 5 s 桶 min/max | 最大间隔 ms | VmRSS kB r1/r2/r3 | Threads | buffer KiB |
|---|---|---|---|---|---|---|---|---|---|
| AOT | 3575/3508/521 | 3160 ms | 17.7/17.7/10.8 | 708/708/430 | 35–236 | 3039 | 254,868/260,436/233,328 | 68–70 | 54,620 |
| JIT | 6562/3530/515 | 3221 ms | 17.6/17.7/19.2 | 705/708/767 | 57–236 | 3012 | 328,888/333,416/323,884 | 66–76 | 54,620 |
| interp | 3657/3531/502 | 3172 ms | 17.5/17.6/19.0 | 701/704/759 | 57–234 | 3033 | 337,912/339,000/328,564 | 67–71 | 32,772–43,696 |

- r1/r2 = 冷缓存（payload→canvas ≈3.2 s，三路径同档）；r3 = 全热（payload→canvas ≈0.16 s）→ 首帧主要由 MAUI 启动与页缓存决定，本轮未见引擎级差异；JIT r1 偏慢（装后首启 6.6 s）属冷页。
- 帧节奏三路径同档（~17.6 fps / 700 帧），AOT r3 的 10.8 fps 为窗口抖动；5 s 桶多在 57–236，最大间隔 ~3.0 s = 空闲重绘节拍（非引擎卡顿）。

## 2. 长跑（31 min）与前后台 ×10

| 路径 | 长跑 start ms | 失 pid/重启 | VmRSS 首→末（增长） | canvas 行 | 新崩溃 | Back 轮 BG/FG | 循环 pid 变化 | 循环 RSS 增长 | 新崩溃 |
|---|---|---|---|---|---|---|---|---|---|
| AOT | 519 | 0/0 | 256,736→276,252（+19.5 MB；首/末 5 min 均值均 ~275 MB，平） | 790 | 0 | 4/10 验证 BG，FG 10/10 | 0 | +33.2 MB | 0 |
| JIT | 814 | 0/0 | 342,104→243,576（−98.5 MB，JIT 热身回落） | 805 | 0 | 10/10 | 0 | +15.4 MB | 0 |
| interp | 532 | 0/0 | 332,632→281,196（−51.4 MB） | 798 | 0 | 10/10 | 0 | +25.4 MB | 0 |

- 31 min 全部 0 失 pid/重启/崩溃；AOT 内存最低（~255–287 MB），JIT/interp ~280–360 MB 且 30 min 内回落（无泄漏）。
- Home 轮（10×）：本 2in1 桌面 Home 不产生 `#BACKGROUND`（状态恒 FOREGROUND，pid/RSS 稳定）；Back 轮补充验证真实前后台，pid 全程稳定；循环 RSS 增量 +15~33 MB 属热身幅度。
- canvas 行 = 启动/恢复后 ~35 s 活跃期约 800 帧，空闲不重绘。

## 3. 引擎证据（round1 `--mem-smaps`）

- JIT：`libcl…` 2720 KiB（libclrjit）、`libco…` 4816（libcoreclr）、`libho…` 320/308（宿主）；`jitfort rc=0`。
- interp：`libcl…` 268 KiB（libclrinterpreter，无 libclrjit 行）、`libco…` 5016、`libho…`。
- AOT：`libhe…` 18,372 KiB（libhello-maui-app）、无 `libco/libcl`；`jitfort skipped`。

## 4. 结论 / 不确定

- **AOT = 默认分发形态**（同帧率、内存最低 ~−75 MB、无隐藏接口/动态码依赖）；**JIT = 性能形态，以合规 ACL/内测域为界**；**interp = 实验形态**（可运行、稳定，不随主包分发）。
- 不确定：单设备（2in1、debug 签名域）单 harness；r3 为热缓存（0.5 s），冷启对比用 r1/r2；并发任务/共享桌面可能影响帧窗；未测 release 域、跨重启、坚盾模式与手机域。
