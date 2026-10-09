# N-SUBWINDOW：managed 子窗壳契约 1→N 产品化立项（2026-10-08）

> 承接 L3（M1–M4 已并入主线：壳 `SUB_WINDOW_MAX=2`、maui `MaxManagedSubWindows=2`；每窗
> identity/输入/IME/a11y/overlay/child web 已按窗）+ L2CAP（平台允许 **255** 并发子窗，现 N=2 是产品
> 自限）+ E4 先例（`OHOS_OVERLAY_MAX` env / rawfile，默认 4、实测 8；默认维持、显式开关抬升）。
> 基线：ow `3ecec5c` · maui `619c40a483`（分支套件 738/741 floor 721；kit #53：737/740、abc 542,936/24,324、导出 164/164）；成本参考：L3-M4 双窗 40 min soak RSS 284–363 MB、59.9–60 fps。
> **主窗零回归为硬条件**；口径 = 单人粗估人日、每 M 独立分支、不并 master、禁强推、真机锁协议、
> #49–#53 资产不动。

## 1. 目标 N 与开关口径

- **N 取值**：默认 **2 不变**；开关抬升 **4**（M1 真机验证）→ 上限 **8**（未验，M3 候选）；平台 255 只作上界。**开关**（同 E4 模式）：`OHOS_SUBWINDOW_MAX`（env；托管与壳同源）或 HAP rawfile `ohos-subwindow-max.txt`
  （壳；包不可设 env 时）。壳 rawfile 页载即读、env 首托管命令惰性读，托管侧首 deferred `OpenWindow`
  惰性读；仅“抬升”生效，夹取 `[2,8]`。
- **诚实拒绝**：超过生效上限（客户端 offer 与壳会话表各自把关）→ `NotSupported`/801，不排队不伪装。

## 2. 改动面（壳 / 切片 / 宿主）

- **壳**（ow 四包 `Index.ets`）：`SUB_WINDOW_MAX=2` → `SUB_WINDOW_DEFAULT_MAX=2` + `SUB_WINDOW_MAX=8`
  （Map 会话表无逐槽数组，上限零成本）+ `SUB_WINDOW_MIN_MAX=2` + env/rawfile 惰性读；容量检查改
  `this.subWindowLimit`；抬升记 `subwindow capacity: N`。会话表仍为 `Map<surfaceId, SubWindowSession>`
  （唯一、最低空闲复用），create/close/move/resize/text-focus 定位逻辑不变。
- **切片（maui）**：`OpenHarmonyMauiAppHost.MaxManagedSubWindows` 常量 → 同源开关（默认 2、上限 8、
  首次容量检查惰性读）；`_awaitingWindows`/`_secondaryWindows` 表与按窗协议不变。
- **宿主（ow 原生）**：**零改动**，导出 **164/164** 不变。
- **示例/工具**：`test/hello-maui-app` 跟随开关（`app://subwindow/max/N` 或 `?max=N` 深链，demo 的
  open guard 同源）；构建脚本资源契约 + 套件 pin + `verify-kit` abc 重锚。

## 3. 每窗服务复用边界

- L3 已按窗、直接复用：per-window surface/renderer、焦点/生命周期（active/inactive、suspend/resume）、
  输入与 touch 路由、IME（op6 + AppStorage 请求带 surfaceId）、a11y per-instance provider/影子帧、
  overlay/alert 归属、Back、child ArkWeb 槽池。
- N 化新增负担只在**数量**：壳会话 Map `size`、托管 `_secondaryWindows` 计数；无共享单例。
- 不共享/不复用：主窗全局文本/插件通道、hybrid/Blazor 资产桥（L2 边界，主窗专用/子窗拒绝）。

## 4. 资源模型与阈值

- **内存**：每子窗 ≈ 托管树 + surface/renderer；每窗 web = 1 个 ArkWeb render 进程（E4 实测
  ~69–70 MB/render）。台账 = N=1/2/4 的 app RSS + render 进程数/RSS（M1 实测曲线）。
- **渲染**：每窗独立 60 fps 目标；混合负载参照 M4 双窗 59.9/60.0。多窗动画/帧统计为 M2 项。
- **焦点/输入**：任一时刻单一 active 窗（其余 inactive）；IME 全局通道按窗互斥；点击下窗暴露条 →
  该窗激活（提升 z）。
- **建议阈值**（2in1 debug）：N=4 稳态 app RSS ≤ 550 MB；render = 主窗基础（样例件 3）+ 每个 web
  子窗 1（N=4/2 web 实测 5 进程 ≈300 MB）；短稳无单调增长、pid 恒定、0 fault。超限则默认维持 2。

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

- L3 = kit #52/#53 已切（abc 542,936）。N-SUBWINDOW 随下一 kit（**#54+**，RC2-ALIGN 之后）出包；每个
  M 完成后按波次重建 abc/套件/`verify-kit` 重锚；#49–#53 资产不动。

## 8. M1 结果（2026-10-09）

- 分支/提交：ow `feat/n-subwindow`（从 `3ecec5c`；`cc3ebe9` 壳+示例+资源契约、`06fddbd` 四包 abc、
  `8d8b945` 套件、`343fc21` verify-kit）· maui `feat/n-subwindow`（从 `619c40a483`；`8b6d4073cb`）；
  普通提交、未并 master、未强推；**三仓远端已推**（ow/maui 新支 + runtime `98495d4b99c`+`325987c4aea`）。
- 离线：abc ui **545,728 / `71eb1e0e…`**（原 542,936，+2,792）、headless 24,324 不变、四包 + provenance
  同步；套件 **739/742 floor 722 assert=True**（新增 `m1 n-subwindow switch`；红控：容量检查硬编码
  `>= 2` → `m1 shell source assert=False` 并抛 M1 断言，还原复绿）；`selftest-build-arkts-shell` 192/0、
  `selftest-verify-kit` 129/0；导出 164/164、宿主零改动。
- 真机（HAD-W32 2in1 / API26，锁协议，JIT 件（134.7 MB）重签安装；证据 scratch `nsub/device/`）：
  - **默认（无开关）**：2 会话（sub-1 g1 / sub-2 g2，identity 双端确认）；第 3 次 open 已投递
    （activation seq=4）但**无第 3 会话产生**（保持 2，超限不落地）；定向关 `closed: surface=sub-2
    remaining=1` + 重开 `sub-2 gen=3`；app RSS 314→325→332 MB。
  - **启用 4**（rawfile=4 + `app://subwindow/max/4`）：boot 即 `[maui] subwindow capacity: 4`（rawfile
    生效）；4 会话 sub-1..sub-4 created + identity 确认（gen 1–4）；输入分窗 active/inactive 覆盖 4 面；
    **双窗 child web**（sub-3/4 各自 capacity max=2 / slot create / attached / 页面 `CHILD-WEB-3`、
    `CHILD-WEB-4`）；定向关 sub-4 → 重开 `sub-4 gen=5`；RSS 曲线 **0/1/2/3(web)/4(web) =
    326/335/338/347/356 MB**，render 3→4→5（+4 ≈300 MB）；10 min 短稳 10 采样 app 303→245 MB（GC
    收敛、无单调增长）、线程 73–75、pid 恒定、**0 新 fault**。
  - env-only 轮受冷启动激活重放干扰（重放先于 `max=4`）；壳侧可靠抬升 = rawfile（4 轮中 maui 上限确由 env
    抬升）。**phase2 复跑（重装后）**：boot 无残留、深链 1:1 送达（seq2 max/4、seq3/4 open、seq5/6 openweb、
    seq7 close `remaining=3`、seq8+前台重试重开 `sub-4 gen=5`）、RSS 255→265→264→276→283→308 MB；原
    “深链未达”= 取证误报（grep 漏 `activation cold seq=` + 抓取早于创建），非回归；真坑 = 主窗 suspend 时
    create 被 `skipped: the main window is suspended` 丢弃且不重试（长间隙复现，前台重发成功）→ M2 项。
- 默认建议：**默认维持 2**；3–4 窗应用显式 `OHOS_SUBWINDOW_MAX=4`（env）+ 壳 rawfile（或改包）；5–8 上限保留（未验）。依据：4 窗（2 web）app RSS ≈356 MB、render 5 ≈300 MB、10 min 无增长；每 web 子窗 ≈1 render + ~40–65 MB。
- 未决/边界：env 对壳的可见性未单独隔离（rawfile 已覆盖该路径）；WMS 计数在本机镜像不可用（窗口数由 hilog created/closed + 截图为证）；第 3 窗拒绝逐字日志未被 status 镜像捕获（以无第 3 会话落地为准）；仅 2in1 debug 域（E1）；设备在我方 08:16 释放锁后由同机并发会话接管，未再触碰。

> **批合并注**：ow `feat/overlay-capacity8`（E4，未并）与本支在 abc/套件/`verify-kit` EXPECT 同点变化
> （E4 548,192、739/742；本支 545,728、739/742）→ 合并后按“**批合并一次重锚**”处理（重建 abc + 一次
> 套件/EXPECT 对账），勿各自重复重锚。`preflight --quick` 的 `selftest-ridgraph` T5 3 项在未改动的
> `3ecec5c` worktree 同样失败（继承的夹具/环境问题，非本支回归）。
