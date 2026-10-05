# 性能收尾：启动分解 · JIT 内存挖掘 · 功耗/帧率（PERF-FINISH，2026-10-05）

> 设备 HAD-W32（OpenHarmony-7.0.0.109 / API26 / 2in1），hdc 127.0.0.1:35111，debug 自签域；件 = kit #47 AOT（本机重签 `960721…`）+ #47 线 JIT/interp（maui pin d5384d6cc3、rc2b interp pack）。启动 = 新增 opt-in `-p:StartupProbe=true`：进程内 Stopwatch 取 Main→DI/build→窗口树→Created→surface→首帧，单行 `utc=… total=… main:0,built:…` 按 0.5 s 重发（壳 3 s 轮询只导出状态文件尾 60 行，单发会被 CEF 日志淹没）；内存 = `hidumper --mem-smaps` 启动 30 s PSS 分类；帧率 = FramePhaseProbe FPH 5 s 窗（长窗需 WindowMs 600 s + 壳 statusReads 12→400 的**测量专用** abc，默认件不受影响）、CPU=/proc/<pid>/stat、温度=BatteryService。证据 scratch `perf-finish/`（含 tar.gz）。

## 1. 启动分解（AMS StartAbility→首帧；每路径 3 冷 1 热，ms）

| 路径 | AMS→Main | Main→首帧 | AMS→首帧 | DI+build | 窗口树 | Created | 等 surface* | surface→present |
|---|---|---|---|---|---|---|---|---|
| AOT | 209–242 | 413–422 | 627–663 | 5–7 | 12–17 | 31–36 | 402–410 | 12 |
| JIT | 485–493 | 556–598 | 1049–1083 | 192–215 | 332–372 | 517–559 | ~0 | 35–39 |
| interp | 449–501 | 563–579 | 1028–1077 | 156–172 | 286–302 | 518–535 | ~0 | 41–45 |

- *JIT/interp 的 ArkUI 面在托管工作期间就绪（surface 101–186 < Created）；AOT 的 surface 是首帧前最后一段。旧表 1.56–1.69 s 系壳轮询滞后污染（n×avg 外推锚在 3 s 后的轮询时刻）；真值 AOT ≈0.63 / JIT ≈1.05–1.08 / interp ≈1.03–1.08 s，冷≈热，AOT 托管到 Created 仅 ~31 ms。
- 唯一系统性可控项 = R2R：框架 CoreLib/System.Runtime 已 R2R，MAUI/AspNetCore/app 未 R2R；`-p:PublishReadyToRun=true` 被 `NU1100 Microsoft.NETCore.App.Crossgen2.openharmony-arm64 (=11.0.0-rc.2.26451.112)` 拒绝（本机仅 rc.1 缓存、版本不匹配），需外部补包；AOT 默认已是最优。

## 2. JIT 内存挖掘（启动 30 s 稳态，`hidumper --mem-smaps` 分类，PSS kB）

| 类别 | AOT(kit47) | JIT | interp | JIT−AOT |
|---|---|---|---|---|
| PSS 合计 | 121,621 | 204,993 | 210,052 | **+83,372** |
| VmRSS | 234,580 | 317,300 | 322,320 | +82,720 |
| `.hap`：48 个框架/应用 dll 文件映射 | 670 | 38,732 | 38,772 | **+38,062** |
| AnonPage other（JIT code/GC/运行时） | 14,817 | 54,637 | 60,442 | **+39,820** |
| native heap | 34,073 | 40,965 | 42,204 | +6,892 |
| `.so`（引擎+ARKUI） | 44,738 | 41,816 | 40,146 | −2,922 |
| arkweb-pa + ark ts + 其它 | 27,323 | 28,843 | 28,488 | +1,520 |

- 引擎 PSS：AOT `libhello-maui-app` 8,392；JIT `libcoreclr` 2,660+`libclrjit` 2,240；interp `libcoreclr` 2,832+`libclrinterpreter` 228。+83 MB = dll file-backed 映射 +38 MB（页缓存背书可回收）+ JIT code/GC/运行时 anon +40 MB + native heap +7 MB；45 min 浸泡 JIT RSS 342→243 MB，30 s 是峰值。无安全旋钮可收（GC 硬限 OOM 风险、关 tiering 反噬），AOT 默认继续最低。

## 3. 功耗/帧率（10 min/路径，60 Hz 重绘负载）

| 路径 | FPH fps 稳态均值(min–max) | 主流 5 s 窗 | CPU%（单核） | 温度 ℃ | RSS MB 首→末 |
|---|---|---|---|---|---|
| AOT | 48.6（47.8–60.1） | 48×106/124 | 25.8 | 35.0 平 | 227→300 |
| JIT | 50.1（47.7–60.1） | 48×95/124（60×21） | 32.5 | 35.0 平 | 310→363 |
| interp | 50.6（47.0–60.0） | 48×79/120（60×32） | 73.4 | 35.0 平 | 314→378 |

- interp 长窗复核（#47 INTERP-DRAW2）：全程 47.0–60.0 fps、无 30 fps 档退化，与 AOT/JIT 同档——#46 的 33.9→60.1 fps 提升在 10 min 窗口保持；代价是 CPU 仍约 JIT 的 2.3×。
- 节奏/度量：首窗（启动期）三路径 60.1 fps，~60 s 后落到 ~48 fps 主节奏（20 ms 呈现间隔，native host 聚合 avg=20ms 与 FPH 一致），偶发 60 窗；旧「60 fps」取自前 45 s 窗口。RS WindowScene `VsyncId` 在 30 fps 的 interp45 上仍报 60 Hz（场景率≠App 呈现率），长窗只采信 FPH。设备接 AC（charging=3、nowCurrent=0、容量恒 100%）→ 绝放电量不可测，功耗以 CPU%/温度为代理：温度 10 min 全程 35.0 ℃。

## 4. 提交 / 证据 / 不确定

- 提交：ohos-workload `test/hello-maui-app/{StartupProbe.cs,Program.cs,App.cs,csproj}`（`e613a18` 已推，opt-in 默认零成本；AOT publish IL2026/3050/3051=0）；runtime-ohos 本文件。未强推。
- 证据 `perf-finish-evidence.tar.gz`：脚本、6 份 startup.json、3 份 mem class.json、3 份 fps10 summary/stream、R2R NU1100 原文。
- 不确定：单设备/共享桌面（第三方对旧 bundle 的安装会杀进程，测量改用独立 bundle `com.example.perf2` + 测量壳 abc，壳差异仅状态轮询）；FPH 首窗含启动不计；48 fps 主节奏与显示/动画定时器未二分；R2R 与解释器混合模式收益未实测。

> kit #48 发布回填（2026-10-05）：本项为 kit #48 前序（启动分解/内存/功耗）；后续专项 = CG2-R2R（JIT 1031→710 ms）、AOT-STARTUP（796→534 ms）、FPS48（46.2→60.0）、FIXRR（interp R2R=0），tester 复测见 `2026-10-05-ohos-tester-handoff-kit48.md` §2。
