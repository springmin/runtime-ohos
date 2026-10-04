# INTERP-RENDER：解释器 32 ms/帧拆解、布局门控与真机复测（2026-10-04）

> 输入：FRAMEPACING `2026-10-03-ohos-framepacing.md` §2（interp 回调→呈现 p50 32 ms、21.5 fps）；kit #42 本机验证 §5。
> 设备 HAD-W32（OpenHarmony-7.0.0.111 / API 26 / 2in1 / 60 Hz），hdc `127.0.0.1:35111`；被测 P=`com.example.hellomauiapp`（首页 ActivityIndicator 持续动画 ⇒ 回调每帧重绘）。
> 方法：切片加 `OpenHarmonyWindowRenderer.RenderPhaseTick` 缝（null 默认零成本）+ 测试 app `FramePhaseProbe`（`-p:FramePhaseProbe=true`：每 5 s 一行 `FPH` = pre/meas/surf/draw/chr/a11y/pres/wait 均值+窗内 max；不动既有 FPF/FPP 探针）。
> 构建：同 checkout/同 abc，仅 `-p:OpenHarmonyRuntimeMode=jit|interp`（interp = rc2b pack：libcoreclr `e150558a…` / libclrinterpreter `3e4b4d10…`）。证据 scratch `/data/storage/el2/base/tmp/opencode/interp-render/`。

## 1. 32 ms 拆解（稳态 5 s 窗加权均值，ms；JIT 对照 / interp 前 / interp 后）

| phase | JIT | interp 前 | interp 后 |
|---|---|---|---|
| pre 回调分发（dispatcher/animation loop） | 0.1 | 0.3 | 0.3 |
| meas Measure+Arrange 全树 | 0.6 | **13.0** | **0.0** |
| surf surface begin+底色 | 0.5 | 0.4 | 0.4 |
| draw 全树绘制 | 3.9 | **18.3** | **18.6** |
| chr 标题栏/浮层 | 0.0 | 0.0 | 0.0 |
| a11y Refresh+diff+发布 | 0.0 | 0.1 | 0.1 |
| pres 原生 present（request+memcpy 11 MB+flush） | 5.1 | 2.8 | 3.2 |
| wait 呈现后→下一回调 | 6.7 | 10.3 | 10.7 |
| Σ / fps | 16.9 / 59.5* | 45.2 / **22.0** | 33.3 / **30.1** |

- 回调→呈现 = pre+meas+surf+draw+chr+a11y ≈ 34 ms：与 FRAMEPACING 的 32 ms 同源，**全部在托管侧**；present 前后无隐藏 sleep/等待。
- 解释器放大（interp/JIT）：meas **~22×**、draw **~4.7×**；pre/a11y <1 ms ⇒ wasm/JS/跨语言回调与 a11y 影子树均非热点（32 ms 到点）。
- vsync 量化：总工作 ~37 ms > 33.3 ms（2×vsync）⇒ 错过 1 号 vsync，48–50 ms/20.5 fps；非额外节流。
*JIT 后段共享机会话争用（present 升到 7.4 ms）掉到 48 fps；前段干净窗 58.9–60.1。

## 2. 瓶颈判定与优化（切片内可控项）

- **解释器固有放大是主因**：draw 18.6 + present 3.2 已 > 16.7 ms vsync ⇒ 60 fps 在现架构不可达（未做脏区/裁剪）。
- **可去冗余 = 静态帧的全树 Measure/Arrange（~13 ms/帧）**：`IView.Measure` 不走 `_measureCache`，旧 Render 每帧重走全树。
- 实现（maui-ohos 切片）：Render 布局门控——仅当渲染根/尺寸/safe-area insets/TitleBar 行变化、根 `MeasureInvalidated`、或 `OpenHarmonyLayoutInvalidation.Version` 变化时 Measure/Arrange；版本由 `OpenHarmonyViewHandler.Invoke` 对 `IView.InvalidateMeasure` 与 `ILayoutHandler.Add/Remove/Clear/Insert/Update` 递增（覆盖 MAUI 虚拟失效+结构编辑；连接前子树由根事件兜底）。
- 真机前后：**22.0 → 30.1 fps**、帧间隔 45.2 → 33.3 ms（锁 2×vsync）、meas 13.0 → 0.0、draw/pres 不变；主线程 CPU 79.6–81.8%（基线段 78.5–83.6%）→ **65.5–70.5%**（4×10 s 窗）。
- 交互（真机）：双击 Count 按钮 → **Count 0→1**（截图）；点击窗 meas max **10.8 ms**（单帧重排）、次窗回 0.0、fps 仍 30。

## 3. 断言 / harness

- off-device 套件（改后切片）：`[suite] checks=584 total=586 floor=566 assert=True`；perf `within=True`（frame avg 17.8 ms、9,104 B/帧 < 13,824；静止帧 a11y skip 0.44 ms/402 节点）。
- 套件首跑抓出两处门控真回归并已修：①TitleBar 隐藏/显示不改内容 measure（→ 行可见性/高度入 gate key）；②`Layout.Add` 只走 `ILayoutHandler`、不触发 MeasureInvalidated（→ handler-invoke 版本信号）。
- harness：`framepacing-stats.py` 增量解析 FPH（`--min-fps` 同 gate；FPF/FPP/host 行为不变，回归实测）；`FramePhaseProbe.cs` 与既有探针零耦合。

## 4. 提交 / 不确定

- 提交：runtime-ohos 本报告；maui-ohos 切片 `7c731a7ca3`（门控+相位缝+失效版本）；ohos-workload `8ed35f4`（相位探针+stats+README）。均未强推、**未改任何 pin**（切片 tip 前进，workflow pin 仍 `3feb347414`，待父会话合并）；host/native 零改动 ⇒ 导出 151 不动。
- 不确定：单设备/共享 2in1（他会话并发重启同 bundle，多轮被截断；opt 稳态窗 3–5 个）；draw 18.6 ms 未按节点类型细分；未做脏区/裁剪；手机域/release/AOT 回归未测；JIT 后段 48 fps 系争用噪声。
