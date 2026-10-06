# 真·多窗口 L 验收矩阵（M1–M4 进入/退出、新增用例、放行，2026-10-06）

> 口径：验收对象 = `2026-10-06-ohos-multiwindow-l-plan.md`（M1–M4）；基线 = kit #49（interaction 607/609 floor 589、pixel 43 PASS、导出 153/153、宿主 301,984 / `cf4cc706…`）。真机轮按 `device-round.sh` 锁协议（`.device-lock` + owner），证据归档 scratch `mw-l/<M>-*`、不落库；套件 pin 按既有约定每 M 合并树抬升一次（floor=total−20，declared==printed）。
> 复用方法：DEVICE-ROUND-49、SOAK48/49（AOT 40 min + churn ×20 + suspend/resume ×10）；文档风格承 `2026-09-18-ohos-device-validation-checklist.md`。

## 1) 分层矩阵

| 层 | 范围 | 验收面 | 关键证据 | 状态 |
|---|---|---|---|---|
| M1 | 宿主多 surface 注册表（window-id → surface/尺寸/state） | 单测 / 导出 / 单窗兼容 | `selftest-host-registry` 61 checks（内部 floor 40）+ rawfile-path 43/43 + 导出 153/153 + `build-host.sh` 三门禁 + 双 XComponent 真机探针 | 已达成分支 `l/m1-window-registry`（`8ce4f58`+`82ef4e7`），待并 |
| M2 | maui 切片 per-window surface/renderer/输入状态 | 单元 / 切片构建 / 单窗零回归 | headless 双窗 22 checks（scratch）+ 切片 0 err/0 IL + suite 607/609 floor 589 + pixel PASS | 切片已落 `l/m2-per-window-renderer`；退出未达：用例未 pin、AOT publish 阻塞、M2-ow 未做 |
| M3 | 壳子窗挂 XComponent + 输入路由 | 真机 create / 焦点 / 触摸 / 关闭 | 第二 MAUI 视觉树首帧 + window-id 输入落点 + churn ×20 残留 0 + 主窗 #49 判定卡不变 | 未开始（3–5 人日） |
| M4 | 焦点/生命周期/IME/a11y/overlay 分区 + 全量验证轮 | 集成（多窗并行 / IME / a11y / overlay / suspend-resume / 混合 JIT-AOT） | 双窗判定卡全过 + 40 min 长稳 + 性能对照（单窗基线 vs 双窗） | 未开始（8–15） |

## 2) 每层进入/退出标准（门禁映射）

| M | 进入标准 | 退出标准（全绿才允许滚动） |
|---|---|---|
| M1 | 计划冻结、从 ow `master` 切分支 | 注册表用例 ≥floor；导出面 153 不变（无新 managed DllImport）；`build-host.sh`（DT_NEEDED/UND/导出）三门禁过；单窗 surface/touch/frame 日志逐项同 #49；第二组件只进注册表、不污染主窗 |
| M2 | M1 并入 ow `master`（复跑 preflight） | headless 双窗状态不交叉且 **22 checks pin 入 `maui-platform-verify`**；interaction 607/609 floor 589 与 pixel 43 PASS 零回归；M2-ow 桥事件带 window-id + `host-exports.txt`/`check-host-exports.py SOURCES`/selftest 同步；AOT 切片 0 warning/0 IL（解除 publish 环境阻塞） |
| M3 | M2 退出全绿（含带窗桥事件） | `OpenWindow`→子窗第二视觉树可交互；触摸/鼠标/键盘按窗归属、主窗输入不受影响；关窗回收（注册表无残留）；主窗 #48/#49 判定卡通过；churn ×20 0 fault |
| M4 | M3 并入 + 双窗基本闭环 | 双窗全交互 + IME/a11y/overlay/suspend 判定卡全过；性能不回退（阈值见 §3，M3 后冻结）；单窗全回归绿；混合 JIT/AOT 各过轮；E1（2in1 debug 域）边界标注 |

## 3) 新增用例清单（编号 / 目标 / 方法 / 证据）

| # | 目标 | 方法 | 证据要求 |
|---|---|---|---|
| M1-01 | 注册表单元：双 surface、重复 id/组件、容量、乱序、per-owner 清理 | `selftest-host-registry.sh`（61 checks、内部 floor 40、接入 preflight） | 0 fail 输出 + preflight step 行 + 源码接线 pin |
| M1-02 | 单窗零变化：首窗与 #49 同一日志面 | kit #49 流程对拍（surface/touch/frame/导出） | 对照表 + hilog 归档；差异仅允许新增注册行 |
| M1-03 | 第二 XComponent 只登记：双 surface 路由、注销回 1 | 真机双 XComponent 探针（M1 已跑） | `registered windows=2`、`unregister -> 1`、主窗 `canvas presented avg 16–17ms` |
| M2-01 | headless 双面：两窗 Render/Resize/Destroy/重建不交叉 | M2 scratch 22 checks（`OpenWindow` 降级→pending→绑定→独立出画→单窗 resize/touch 不串→关窗存活→同 id 重建）**pin 入套件** | `[suite] checks=… total=… floor=… assert=True`（declared==printed）+ 0 Unhandled |
| M2-02 | 单窗零回归 | 合并树跑 interaction + pixel + `check-host-exports` | 607/609 floor 589 保持、43 PASS、导出 declared==managed |
| M2-03 | 切片 AOT 干净 | Release + trim/AOT analyzer 打包（刷新 workload .28 后重跑） | 0 warning/0 IL + `runtime-mode.txt=aot` + probe 行 |
| M3-01 | OpenWindow→第二 MAUI 视觉树 | `device-round.sh --mode aot` + `app://subwindow/open` 判定卡 | 子窗首帧截图 + 每窗 surface/renderer window-id 日志 |
| M3-02 | 输入路由正确性 | 两窗各打触摸网格/滑动/滚轮/键盘、交叉验证 | window-id 标签日志 + 命中截图；跨窗事件=0 |
| M3-03 | 焦点/z-order/Back | 点窗切换、Back、主窗输入 | 焦点事件顺序日志 + 截图 |
| M3-04 | 窗口 churn ×20 无残留 | SOAK49 `bin/churn.sh` 双窗化（create/move/resize/close） | WMS 残留 0/20、`unregister`=建窗数、pid 恒定、0 崩；CSV+脚本归档 |
| M3-05 | 子窗数量上限 | 递增开窗至失败（N≥3 探测） | 上限结论 + 超限退化路径；回填 L 计划 |
| M4-01 | 双窗同时渲染帧率 | 双窗同时动画/滚动；framepacing + `canvas presented` | 对照表：主窗 ≥50 fps、子窗 ≥40 fps、主窗较单窗退化 ≤10%（M3 后冻结），连续长帧 ≤33ms×3=0 |
| M4-02 | 焦点/IME 切换 | 焦点窗唤起 IME 输入→切窗→再输入 | 输入只落焦点窗；IME 跟随/收起序列；截图+hilog |
| M4-03 | a11y 分区 | `--a11y` walk 两窗 + 密码脱敏复测 | 两窗节点树 nodeCount/焦点顺序；SEC-SCAN-4 pin 仍绿 |
| M4-04 | overlay/ArkWeb 分区 | 双窗各挂 web 控件、alert/flyout、触发抢占 | `web slot create/destroy` + `[maui-capacity]` 原文按窗归属；z-order 截图 |
| M4-05 | suspend/resume | 主窗 HIDDEN/SHOWN→每窗挂起/恢复；Home 键（focus-loss 链，post-#49）/最小化/锁屏/进程重启 | 事件顺序 ×10、残留 0；Home 路径留档（#49 已知差异） |
| M4-06 | 40 min 长稳 | `device-round.sh --soak-min 40` + 双窗 churn/suspend 叠加 | 41 采样 0 崩/0 失 pid/0 重启、updateTime 不变、RSS 无单调增长 |
| M4-07 | 混合 JIT/AOT 矩阵 | mode kit（aot/jit，interp 视 #50 能力）双窗主路径 | 各模式 probe + `runtime-mode.txt` + 首帧/帧率对照不回退 |

## 4) 回归风险与守卫

- **单窗零变化（硬门）**：每层合并树对拍首窗日志面（surface state/touch/`canvas presented`/导出）；红控=把首窗误接非 `main` 槽时新增用例必须红。
- **#49 资产不回退**：L 期间不重切/不覆盖 #49 release（tar `477974bb…`、tree `8d03cb4c…`、预签 `56aaf08f…`）；abc/provenance/预签在第 50 切包统一重锚；测试方 `--expected-abc 414532` 口径不变。
- **套件基线抬升**：每 M 一次——新增 pin 追加、`verifyCheckTotal`+N、floor=total−20、declared==printed；workflow/preflight 读打印行；旧 pin 只增不删不重编号；新增 pin 附离线红控（还原修复→断言 False）。
- **像素/导出门**：pixel 只增不减（43 PASS 起）；managed 导出 declared==printed 且静态/动态清单同步，不同步即 `build-host.sh` 三门禁失败。
- **设备纪律**：单设备 `.device-lock` + owner；每轮 tar + SUMMARY（门禁行、churn/suspend CSV、fault diff）；阈值 M3 冻结后只允许新证据上调，不允许放宽。

## 5) 放行一览表（L 全部完成后发布 kit 的判定）

| # | 判据（全部必需） | 来源 |
|---|---|---|
| 1 | M1–M4 各合并树退出标准全绿、未验证项不滚层 | §2 + 各 M 提交 |
| 2 | 单窗回归：interaction assert=True（新 total）、pixel 全 PASS、导出 declared==managed、preflight OK | 合并树 |
| 3 | 双窗判定卡：create/第二视觉树/焦点/输入路由/IME/a11y/overlay/suspend 全过 | HAD-W32 真机归档 |
| 4 | churn ×20 + 40 min 长稳 + 混合 JIT/AOT：0 崩/0 失 pid/0 残留/RSS 无单调增长 | soak 归档 |
| 5 | 性能对照：双窗帧率/内存阈值达标（冻结值） | M4-01/06 |
| 6 | `OpenWindow` 语义转正（不再 `CurrentWindowKept`）；TYPE_FLOAT/第二 `startApp` 边界如实声明 | 切片 + 文档 |
| 7 | 文档回填：L 计划时点状态、`ohos-platform-limitations.md` E2、feasibility、M2–M4 合并记录 | docs/plans |
| 8 | 发布资产：新 kit abc/provenance/预签重锚 + `verify-kit.sh` + kit 后 `device-round.sh`/soak | 切包流程 |
| 9 | 测试方交接件更新（新主判点与预期行） | handoff |

> 与计划的差异（验收口径）：M2 实际以 scratch 22 checks 交付、DI 工厂化与 M2-ow 带窗桥事件缓做——本矩阵把“pin 入套件 + M2-ow”钉进 M2 退出，不滚入 M3；M1 已在分支上先于矩阵达成。
> 提交：本文件（runtime-ohos `feature/openharmony`；`commit-paths.sh` 限路径、普通推送、被拒 fetch+rebase）；README 索引稍后批量补。不确定项：M2–M4 人日与帧率/内存阈值待 M3 首测校准；Home 键 suspend 依赖 #50 的 focus-loss 链（ow `b5928d1`）出包；AOT publish 阻塞需 workload .28。
