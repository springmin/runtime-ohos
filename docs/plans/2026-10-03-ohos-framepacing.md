# FRAMEPACING：17.7fps 归因、宿主修复与真机复测（2026-10-03）

> 设备 HAD-W32（OpenHarmony-7.0.0.111 / API 26 / 2in1，屏 60Hz），hdc `127.0.0.1:35111`；被测 P=`com.example.hellomauiapp`。
> 方法：宿主 5 s 帧聚合（本次修复）＋可选托管探针 `-p:FramepacingProbe=true`（每回调 FPF＋每次呈现 FPP，经 `<filesDir>/dotnet-status.txt`→壳轮询→hilog，40 s 后自卸载）；
> 解析/去重/门限 `ohos-workload/scripts/framepacing-stats.py`。证据 scratch `framepacing/`（未提交）。提交：ohos-workload `aa6f485`。

## 1. 归因：17.7fps 是壳状态轮询伪影，帧循环没有问题

- DECIDE-BASELINE 用 hilog `canvas presented` 行数/40 s 当 fps。壳 `pollManagedStatus` 每 3 s 读一次状态文件并重放**末 60 行**、上限 12 次（36 s）；宿主每帧往同一文件写 1 行 stderr。
  故每轮 ≈59 行 ×12 ＋ 9 s `[managed]` 120 行镜像 ≈ 700 行：708/705/701 正是三路径数出的“帧数”。5 s 桶 35–236、r3 的 10.8fps 同源。
- 复现对照（同载荷 jitfix3、无探针、旧宿主）：原始 canvas 行 816、壳尾行 708（与基线一致）；聚合显示真实呈现 60.0fps。

## 2. 真实帧节奏（探针 30 s 窗口，去重后）

| 路径 | 帧/呈现 | 回调间隔 p50 / p95 / max (ms) | 回调→呈现 p50/p95 (ms) | fps |
|---|---|---|---|---|
| JIT | 1830/1830 | 16.667 / 16.692 / 16.760 | 4 / 8 | **60.00** |
| AOT | 1829/1829 | 16.667 / 16.706 / 16.737 | 4 / 4 | **60.00** |
| interp | 662/662 | 49.994 / 50.023 / 50.119 | 32 / 36 | **21.47** |

- AOT/JIT＝XComponent 回调 vsync 锁相（`tgt` 16.66 ms），呈现:回调 1:1、零丢帧；`Frame→Render→Present` 同步，无 sleep/节流可去——帧循环本身无需修理。
- interp 并非同档：渲染+呈现 32 ms/帧，平台按 vsync 量化到 ~50 ms ⇒ ~21.5fps、CPU ~79%（渲染受限，与引擎相关）。基线“三路径同档”是轮询伪影掩盖的。

## 3. 修复（可控项）＋ harness

- `ohos-workload aa6f485`：`ohos_host_draw_present` 停止每帧 fprintf；首帧/尺寸变化仍写 `canvas presented (WxH)`（文档/首帧检查兼容），其后每 5 s 一行
  `... n=<帧数> avg=<ms> max=<ms>`——直接给出真实 fps/抖动，状态文件写入 ~3.6 KB/s→12 B/s（~13 MB/h→43 KB/h），也不再淹没壳诊断通道。
- 新增 `test/hello-maui-app/FramePacingProbe.cs`（默认零开销）与 `scripts/framepacing-stats.py`（解析两种通道、去重、`--min-fps/--max-gap-ms` 门限）；壳/harness 无需重建 abc。
- 未改 pin、未改帧循环、未动既有套件（只增文件/README）。

## 4. 真机前后对照（同载荷 jitfix3，3×10 s CPU 窗）

- 日志：816 raw canvas 行 → 8 聚合行/50 s（壳尾行 708 → <1 行/5 s）；帧率前后均 60.0fps（修复不触碰渲染路径）。
- CPU（主线程）：旧宿主 63.0/52.8/53.0%，新宿主 67.5/53.5/56.1%；共享机 load≈30，差在噪声内（去掉的 I/O 小于噪声）。
- interp（新宿主）：78.7/78.4/78.7%，聚合 avg 40–45 ms（22–25fps），与探针一致。

## 5. 断言/验证/不确定

- 已跑：build-host 三闸（DT_NEEDED/UND 黑白名单＋151 exports）＋ELF selfsign；探针 off/on 两配置 `-t:Compile` 0 错误；stats 对 JIT/AOT PASS（60.00）、对 interp FAIL（21.47<55）门限行为实测。
- 不确定：单设备/共享 2in1 单 harness；探针窗 40 s；AOT/JIT 的 4 ms 未细分 arrange/draw；interp 未优化（DECIDE-BASELINE 仍定实验形态）；release 域/手机域未测。
