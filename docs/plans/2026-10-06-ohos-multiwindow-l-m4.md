# MULTIWINDOW-L M4 第一波：焦点/生命周期/IME/a11y/叠加层分区（2026-10-06）

> 口径：按预研 `-l-m4-prestudy.md` §5 顺序先做稳定面 M4-05→02→03→04；M4-01/07/06（双窗帧率/
> 混合 JIT-AOT/40min 长稳证据轮）与子窗 a11y provider、子窗 ArkWeb、per-window overlay/pinch
> 按预研时间盒/降级线留下波（降级路径见「余项」）。
> 载体：ow `l/m4-focus-ime`（基于 `l/m3-shell-xcomponent` @ `fb493e1`，先并 `origin/master`
> 拾取 nextkit polish/Home 链 `b5928d1`，已含）· maui `l/m4-per-window-focus`（基于
> `l/m3-per-window-content` @ `f2fa86cec5`）。未并 master、未重切 #49 资产。
> 提交：ow `l/m4-focus-ime` `2c0f1f5`+`27055f9` · maui `l/m4-per-window-focus` `c7f440fc65`
> · 本文档（runtime `feature/openharmony`）；均普通推送、未强推、未并 master、未重切 #49 资产。

## 逐项状态

| 项 | 状态 | 实现要点 | 证据 |
|---|---|---|---|
| M4-05 suspend/resume | ✅ 本波 | 壳上报子窗 ACTIVE/INACTIVE（11/12）+既有 SUSPENDED/RESUMED；app host 路由为 per-window `IWindow.Activated/Deactivated/Stopped/Resumed` 状态机（幂等、主窗进程生命周期零变化）；SEC5B-L3 兜底：仅 Closed 也回收会话 | 套件 m4 life×5（含幂等/主窗不受影响/Closed belt）；真机 17:07 Home→`Inactive`→`Suspended`、`aa start`→`Active/Resumed`；17:08 close→`window 'sub-1' closed` + `Closed` belt |
| M4-02 焦点/IME | ✅ 本波（离线）/◐ 真机 | 子窗页：隐藏 TextInput + focusable XComponent(onKeyEvent) + onBackPress；AppStorage 焦点通道（managed op 6→Index→子窗 `requestFocus`/IME）；text/composition/submit/key/back 复用既有 tagged 子窗通道（**无宿主新导出**）；Entry/Editor/SearchBar 按窗解析（`ResolveWindowId`）路由 input/focus；`OpenHarmonyWindowInputRouter` 按窗 text 端口 | 套件 m4 input×7；真机：子窗隐藏输入节点 `sub-1__input` 在位（dumpLayout）、`Active` 事件上线；**uitest 点击未达子窗 XComponent（环境注入面），IME 实敲留人工** |
| M4-03 a11y 分区 | ✅ 离线分区 | 每窗影子帧：主窗保持既有 provider 路径零变化；子窗帧本地保持、不再覆盖主窗（M3 后互毁回归修复）；告警节点只进归属窗；action/模态仍只走主 provider | 套件 m4 a11y partition + alert owner；红控 X；子窗 provider 留下波 |
| M4-04 overlay/alert/pinch | ◐ 部分 | alert 按窗归属（`CurrentFor`/`SetSurface(windowId)`，两窗不再同画/互改几何）；主窗 overlay 不再吞子窗触摸；子窗字体缩放重排（0.5pd）；pinch/ArkWeb/per-window overlay host 留下波 | 套件 alert owner；pinch/ArkWeb 未做（时间盒） |
| M4-01 双窗帧率 | ⏳ 未开始 | 留下波（需要 02–04 交互面稳定后做动画/滚动对照） | — |
| M4-07 混合 JIT/AOT | ⏳ 未开始 | 留下波（mode kit 双窗主路径） | AOT 安全见下 |
| M4-06 40min 长稳 | ⏳ 未开始 | 留下波（全栈最后） | — |

## 套件与门禁（绿/红）

- `test/maui-platform-verify` +15 checks：`verifyCheckTotal` 645→**660**、floor 625→**640**；
  实跑 `[suite] checks=658 total=660 floor=640 assert=True`、0 Unhandled、0 assert=False（declared==printed=658；
  total/floor 为声明口径，同 M3 的 2 行余量）。
- 单窗零回归：M2/M3 全部 check 保持；导出面 156 不变（本波无新宿主导出/NAPI，宿主源码未动）；
  host registry selftest 78/78（脚本 T1–T4 6/6）；pixel 套件 `PIXEL ASSERTIONS PASSED`（本波重跑）；
  pack 自检见 `selftest-packs`（四包 abc/provenance 同步）。
- 离线红控（还原修复→断言 False）：把 `FrameOf/StoreFrame` 改回单一全局帧 + 去掉 `Stopped()`
  幂等 guard → `m4 life suspend`、`m4 a11y partition`、`m4 a11y alert owner` 三条
  `assert=False`、run exit 134（`red2-run.log`）；随后恢复源码复跑全绿（`final2-run.log`）。

## 真机证据（HAD-W32 / OpenHarmony 7.0.0.111 / 2in1）

- 证据 scratch `mw-l/m4/`（`m4-open1.raw`/`m4-tag.raw`/`m4-home.raw`/`m4-close.raw` +
  `m4-open1.jpeg`/`m4-now1.jpeg`，不入库）；`.device-lock` 协议持有（05:51→08:16），轮末恢复
  kit #49 hap 后释放。
- M4-05：创建子窗 → `subwindow event Active: surface=sub-1`；`uitest uiInput keyEvent Home`
  → `Inactive`（600ms 宽限）→ `Suspended`；`aa start` → `Active`/`Resumed`；close →
  `[maui] window 'sub-1' closed` + `subwindow event Closed`（L3 兜底消费，无二次 Destroying）。
- M4-02：子窗页隐藏输入节点在 ArkUI 树中可见（`sub-1__input` [120,160][840,267]，dumpLayout）；
  M3 的宿主注册/首帧零回归（`windows=2`、`canvas presented [sub-1] (720x480)`、`first frame=True`）。
  **未证**：`uitest uiInput click` 注入未送达子窗 XComponent（焦点窗 `sub-1` 已置，点击后无
  touch/tap 日志；dock 点击证明 uitest 注入口本身可用）——IME 实敲与切窗留人工/下波。
- M4-03/04 真机面：a11y provider 主窗零变化（子窗 provider 降级）；alert 归属为离线 pin，
  真机弹窗交叉测试依赖下波。

## AOT 与余项

- AOT 安全：切片 AOT/trim 分析器编译（`Microsoft.Maui.Platform.OpenHarmony.csproj`，
  `IsAotCompatible/EnableAotAnalyzer/TreatWarningsAsErrors`）`RC=0` 且 **IL2026/IL3050/IL3051=0**；
  本波无反射/无新 NAPI/DllImport，native host 未改（导出面 156 不变）。
  完整 AOT hap publish 未在本波重跑（时间/共享机负载），留 M4 收尾轮。
- 余项（下波）：① 子窗 a11y provider（NodeContent/provider 并存探针 ≤2pd，失败即维持
  「主窗零回归 + 子窗不覆盖」降级）；② 子窗 ArkWeb/CEF 第二宿主（时间盒 ≤2pd，超限维持单
  overlay 主窗宿主）；③ per-window overlay host + pinch 带窗；④ 子窗 safe-area 系统条；
  ⑤ 窗作用域 DI（记录限制，仅失败才做）；⑥ M4-01/06/07 证据轮与阈值冻结。
- 边界：仍是单 managed 子窗（壳 801 契约）；2in1 debug 域结论，不外推手机/release。
