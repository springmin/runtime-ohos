# N-SUBWINDOW：managed 子窗壳契约 1→N 产品化立项（2026-10-08）

> 承接 L3（M1–M4 已并入主线：壳 `SUB_WINDOW_MAX=2`、maui `MaxManagedSubWindows=2`；每窗
> identity/输入/IME/a11y/overlay/child web 已按窗）+ L2CAP（平台允许 **255** 并发应用子窗，
> 现 N=2 是产品自限）+ E4 容量开关先例（`OHOS_OVERLAY_MAX` env / `ohos-overlay-max.txt`
> rawfile，默认 4、实测 8；结论 = 默认维持、显式开关抬升）。基线：ow `3ecec5c` ·
> maui `619c40a483`（套件 737/740 floor 720、abc 542,936/24,324、导出 164/164、宿主 367,520）。
> 成本参考：L3-M4 双窗 web 40 min soak app RSS 284–363 MB、双窗 59.9–60 fps
> （DEVICE-ROUND-52）。**主窗零回归为硬条件**。口径：单人粗估人日（含自测/真机/文档，不含
> 上游评审）；每 M 独立分支、不并 master、禁强推；真机按设备锁协议；#49–#53 资产不动。

## 1. 目标 N 与开关口径

- **N 取值**：默认 **2 不变**；显式开关抬升 **4**（M1 真机验证）→ 上限 **8**（未验，M3 候选）。
  平台 255 只作上界参考，不追平。
- **开关**（同 E4 模式）：`OHOS_SUBWINDOW_MAX`（env；托管与壳同源）或 HAP rawfile
  `ohos-subwindow-max.txt`（壳；包不可设 env 时）。壳 rawfile 页面加载即读，env 首个托管命令
  惰性读；托管侧首个 deferred `OpenWindow` 惰性读。仅"抬升"生效，夹取 `[2,8]`。
- **诚实拒绝**：超过**生效上限**（客户端 offer 与壳会话表各自把关）→ `NotSupported`/801，
  不排队、不伪装、不留 ghost window。

## 2. 改动面（壳 / 切片 / 宿主）

- **壳**（ow 四包 `Index.ets`）：`SUB_WINDOW_MAX=2` 常量 → `SUB_WINDOW_DEFAULT_MAX=2` +
  `SUB_WINDOW_MAX=8`（Map 会话表无逐槽数组，上限零成本）+ `SUB_WINDOW_MIN_MAX=2` + env/rawfile
  惰性读；容量检查改 `this.subWindowLimit`；抬升记 `subwindow capacity: N`。会话表仍是
  `Map<surfaceId, SubWindowSession>`（唯一、最低空闲复用），create/close/move/resize/
  text-focus 定位逻辑不变。
- **切片（maui）**：`OpenHarmonyMauiAppHost.MaxManagedSubWindows` 常量 → 同源开关（默认 2、
  上限 8、首次容量检查惰性读）；`_awaitingWindows`/`_secondaryWindows` 表与按窗协议不变。
- **宿主（ow 原生）**：**零改动**，导出 **164/164** 不变。
- **示例/工具**：`test/hello-maui-app` 跟随开关（`app://subwindow/max/N` 或 `?max=N` 深链，
  demo 自己的 open guard 同源）；构建脚本资源契约 + 套件 pin + `verify-kit` abc 重锚。

## 3. 每窗服务复用边界

- L3 已按窗、直接复用：per-window surface/renderer、焦点/生命周期（active/inactive、
  suspend/resume）、输入与 touch 路由、IME（op6 + AppStorage 请求带 surfaceId）、a11y
  per-instance provider/影子帧、overlay/alert 归属、Back、child ArkWeb 槽池。
- N 化新增负担只在**数量**：壳会话 Map `size`、托管 `_secondaryWindows` 计数；无共享单例。
- 明确不共享/不复用的：主窗的全局文本/插件通道（保持主窗专用）、hybrid/Blazor 资产桥
  （L2 边界，主窗专用/子窗拒绝）。

## 4. 资源模型与阈值

- **内存**：每子窗 ≈ 托管树 + surface/renderer；每窗 web = 1 个 ArkWeb render 进程
  （E4 实测 ~69–70 MB/render）。台账 = N=1/2/4 的 app RSS + render 进程数/RSS（M1 实测曲线）。
- **渲染**：每窗独立 60 fps 目标；混合负载参照 M4 双窗 59.9/60.0。多窗动画/帧统计为 M2 项。
- **焦点/输入**：任一时刻单一 active 窗（其余 inactive）；IME 全局通道按窗互斥；点击下窗
  暴露条 → 该窗激活（提升 z）。
- **建议阈值**（2in1 debug）：N=4 稳态 app RSS ≤ 550 MB、web 窗数 ≤ 4 时 render ≤ 4 进程；
  短稳无单调增长、pid 恒定、0 fault。超限则默认维持 2、抬升档只作显式选择。

## 5. 里程碑与估算

| # | 范围 | 人日 |
|---|---|---|
| M1 | 上限可配置（壳 env/rawfile + maui 对齐）；默认 2；启用 4 真机：identity/输入分窗/定向关/重开/双窗 child web 抽验 + RSS 曲线（1/2/4）+ 短稳 | 3–5 |
| M2 | N=4 服务并发闭环（IME/a11y/overlay 四窗互斥与回收）+ churn/40 min 长稳 + 帧率 | 5–8 |
| M3 | 8 上限候选（内存曲线/阈值、降档策略、文档 + kit 收口） | 5–8 |
| 合计 | | **13–21（≈3–4 周）** |

## 6. 风险

| 风险 | 影响 | 缓解 |
|---|---|---|
| 焦点/IME/a11y 四窗并发 | 串窗/键盘跟错窗 | M1 抽验 + M2 全量；任一超时间盒 → 上限降回 2 |
| 内存曲线（每窗 render 引擎 + 托管树） | RSS 线性增长、低内存设备抖动 | 阈值冻结 + 曲线实测（M1）；超限不抬默认 |
| 混合 FPS（多窗动画 + web） | 帧率回落 | 每窗 60 fps 目标 + M2 实测对照 |
| 平台行为外推 | 手机/release 结论失真 | 仅 2in1 debug 域（E1）标注 |

## 7. kit 载体

- L3 = kit #52/#53 已切（abc 542,936）。N-SUBWINDOW 随下一 kit（**#54+**，RC2-ALIGN 之后）出包；
  每个 M 完成后按波次重建 abc/套件/`verify-kit` 重锚；#49–#53 资产不动。

## 8. M1 结果（2026-10-09）

- 分支：ow `feat/n-subwindow`（从 `3ecec5c`）· maui `feat/n-subwindow`（从 `619c40a483`）；
  均普通提交、未并 master、未强推。
- 落地：壳四包开关（默认 2 / 上限 8 / env+rawfile）+ maui 同源 cap + 示例 `?max=N` 深链 +
  构建资源契约 + 套件 pin + `verify-kit` 重锚；abc **545,728/`71eb1e0e…`**（+2,792）、headless
  24,324 不变；套件 **739/742 floor 722 assert=True**（红控：容量检查硬编码 `>= 2` → `m1 shell
  source assert=False` 并抛 M1 断言）；导出 164/164、宿主零改动。
- 真机（HAD-W32，锁协议）：见随轮报告（默认 2 拒绝第 3 窗 / 启用 4 身份·输入·定向关·重开·
  双 child web / RSS 曲线与短稳）。
