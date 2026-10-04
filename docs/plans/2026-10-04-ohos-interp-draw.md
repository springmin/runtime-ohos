# INTERP-DRAW2：interp draw 14.3 ms 拆分与面外绘制剔除（2026-10-04）

> 输入：DEV-JITINTERP §4（interp draw 14.3 ms vs JIT 3.6 ms ≈4×）。设备 HAD-W32（OpenHarmony-7.0.0.111 / API 26 / 2in1 / 60 Hz），hdc `127.0.0.1:35111`；bundle `com.example.hellomauiapp`。
> 件：interp = rc2b pack；基线 = `189b87ca8a` 切片（`base-clean`/`base-jit`）；优化 = 同切片 + 本波（`opt-clean`/`opt-jit`）；探针件另加 DRAWCOST。
> 方法：新增 `OpenHarmonyWindowRenderer.DrawCostTick` 缝（每节点 kind：0 文本/1 图/2 形状/3 容器/4 其他；不改既有 `RenderPhaseTick`/FPH 语义）+ 测试 app 计时画布按 canvas op 归属（`-p:DrawCostProbe=true`，DCH 行/5 s）。证据 scratch `interp-draw2/`。

## 1. draw 拆分（interp 基线，5 s 窗 / 帧）
| 类别 | nodes/帧 | ms/帧 | 说明 |
|---|---|---|---|
| 文本 k0 | 62 | 2.97 | 背景 fill 1.2 + 文本 1.6 |
| 形状 k2 | 4 | 2.43 | 全为 fPath/dPath（矩形/椭圆/线/Border） |
| 容器 k3 | 10 | 0.00 | 只递归 |
| 其他 k4 | 16 | 3.13 | 值控件/选择器/页面 chrome，fill 2.5 |
| canvas 合计 | — | 8.8 | FPH draw 14.8 ⇒ 遍历+属性+平台分发 **6.0** |

- op（ms/帧 · 次/帧）：fRect 2.49·23.3、fRound 1.46·6.0、fPath 1.16·2.0、dPath 1.20·4.0、text 1.77·68、dLine 0.20·9.2、dRound 0.27·1.0、clip 0.09·4。
- 单次成本：fPath ≈570 µs、fRound ≈243 µs、fRect ≈107 µs、DrawString ≈26 µs——形状的 PathForBounds+Flatten、圆角 cos/sin 多边形、每次新建原生 Path，全部吃解释器放大。

## 2. 热点
- **填充 33 次/帧 = 5.2 ms** 为首（形状路径 + 圆角 + 值控件底色）；文本 1.8 ms；walk 6.0 ms（每平台节点 ~65 µs：IView 绑定属性读 + 双次子枚举）。
- 页面内容高约 2900 px、视口 1324 px：约 1/3 节点（含全部形状/圆角按钮/滚动行）在面外仍逐帧绘制（shape/round/path op 几乎都来自面外区）。

## 3. 优化（maui 切片 `6652017ca5`）
- **面外剔除**：节点自身 Canvas 矩形（含 shadow 外延）不与 surface 相交、且无祖先平移/缩放/旋转/滚动（`shifted`）时跳过自身绘制；子树照走（负 margin 子节点各自判定）；opacity≤0 跳过；弹层/轮播/TitleView 与 **Image（渐进解码契约）** 永不剔除。
- 变换输入每节点只读一次（原 Opacity/Translation/Scale/Rotation 各读两遍）；叶子节点不再构造 childMap。
- 效果（cull 后探针）：绘制节点 92→62/帧、形状 4→0、DrawString 69→52/帧、canvas 8.8→4.1 ms。

## 4. 真机前后（同窗 A/B，50 s 采集 + 4×10 s CPU 窗）
| 路径 | 件 | draw ms | fps | canvas 桶 | CPU 10 s |
|---|---|---|---|---|---|
| interp 基线 | base-clean | 14.4 | 33.9 | 29–30 ms | 58.5–64.6% |
| interp 优化 | opt-clean | **9.4** | **60.1** | 16 ms | 75.8–76.3%（每帧 −27%） |
| JIT 基线 | base-jit | 3.2–3.6 | 60.1 | 41.2–44.1% |
| JIT 优化 | opt-jit | 2.9–3.0 | 60.1 | 38.9–39.7% |

- interp 触到 60 Hz 上界（帧 ~16.6 ms，wait 覆盖余量）；JIT draw −15%、CPU −3 pt、fps 不变 ⇒ 无回归。首帧截图 base vs opt 平均差 0.018/255（>24 差异 217/6.5M 像素，为活动指示器等动画元素）。

## 5. 套件 / 导出 / 提交
- 套件：interaction `[suite] checks=591 total=593 floor=573 assert=True`（+3：DrawCostTick kind、面外 cull、平移救回），perf 帧与 a11y `within=True`；pixel `PIXEL ASSERTIONS PASSED`（43 PASS）。
- 导出：native/host 零改动 ⇒ 导出 151 不动；未改任何 pin（切片 tip 前进到 `6652017ca5`，workflow pin 仍 `189b87ca8a`，待父会话合并）。
- 提交：maui `6652017ca5`、ow `c31d077`（均 fast-forward、普通推送，未强推）。

## 6. 不确定 / 后续
- 单设备共享 2in1、每格 1 轮（interp 6 个 5 s 稳态窗）；面外剔除只做 surface 级，ScrollView 子树仍随 `shifted` 走（clip 级剔除可再降 draw，但当前已触 60 Hz 上限）；未复测手机域/release/AOT。
