# 真·多窗口 L 里程碑计划（A′/B：同宿主模块 per-window 状态，2026-10-06）

## 状态（滚动）

M1 ✓（`df2a246`，门禁终 tip 全绿）· M2 ✓（`1a15f56b30` + exit `896f4e3`）· M3 ✓（ow `35df4f4` / maui `d4ff7d445e`；套件 643/645 floor 625）· M4 进行中（**第一波**：05/02/03/04 核心 + 套件 658/660 floor 640，见 `-l-m4.md`；01/06/07 与 a11y provider/ArkWeb/pinch 下波）· SEC-5a ✓ / 5b ✓。

> 数字随动（一次性注记）：套件 607/609 floor 589（#49）→ **629/631 floor 611（M2-exit）→ 643/645 floor 625（M3）**；导出 153（#49/M1）→ **154（M2-exit）→ 156（M3）**；abc **`e016db13…`/414,532（#49）→ `cee64297…`/417,416（nextkit）→ `38bdf7de…`/426,304（M3）**；SEC-5a 修复后注册表单测 61→**66** checks。

> 依据：`2026-10-06-ohos-multiwindow-l-feasibility.md`（P1/P2 真机探针 + 只读盘点）。路线 = 同一宿主模块多 XComponent + 每窗 surface/renderer/输入（window-id 化）；第二 `startApp` 与跨窗纹理共享不做。
> 口径：单人粗估人日（含自测/真机轮/文档，不含上游评审）；每个 M 从 `master` 切独立分支，验证通过后单独合并；完成定义 = 该 M 的退出标准全绿，不把未验证项滚入下一个 M。
> 不在计划内：`TYPE_FLOAT` 系统级浮窗（三方不可达）、跨窗 surface/纹理共享（C 路线，预研已否）、手机/release 域结论外推（E1，M4 收口）。

## 里程碑总览

| # | 范围 | 人日 |
|---|---|---|
| M1 | 宿主多 surface 注册表（window-id → surface/尺寸；多 XComponent 生命周期事件路由） | 3–5 |
| M2 | maui 切片 per-window surface/renderer/输入状态（每窗对象化，替换静态单槽桥） | 5–8 |
| M3 | 壳侧子窗挂 XComponent + 输入路由（`OpenWindow` → 子窗页 + 每窗生命周期） | 3–5 |
| M4 | 焦点/生命周期/IME/a11y/叠加层分区 + 全量验证轮（真机矩阵/回归/文档） | 8–15 |
| 合计 | | **19–33（≈4–7 周）** |

依赖：M1 → M2 → M3 → M4；M3 的静态子窗页骨架可与 M2 并行，合并顺序不变。每个 M 的提交范围按 `commit-paths.sh` 限定；探针/日志不落库。

## M1 宿主多 surface 注册表（window-id）——3–5 人日

- **范围**：`Init` 按 XComponent 登记（读 `OH_NATIVE_XCOMPONENT_OBJ`，`GetXComponentId` 取组件 id）；window-id → {component, surface, 尺寸, state, surface/touch/frame 计数}；surface 生命周期按 component 路由；主窗（首个登记 = `main`）继续走 `g_surface_*`/`bridge_surface` 原路径（零行为变化）；新增 `registerXComponent(id?)`/`unregisterXComponent(id?)`。
- **文件级改动**（ow）：新增 `src/OpenHarmonyHost/host_window_registry.{h,c}`（纯 C 注册表，无 NAPI/OH 头）与 `host_window_registry_test.c`；改 `host_napi.cpp`（Init 即登记、回调路由、NAPI 导出 `unregisterXComponent`）；`CMakeLists.txt`、`scripts/build-host.sh` 编入新源；新增 `scripts/selftest-host-registry.sh` 并接入 `preflight.sh`。**不改**：`openharmony_host.c/.h`、`host-exports.txt`（M1 无新 managed DllImport，153/153 不变）。
- **测试**：`selftest-host-registry`（66 checks，SEC-5a 后：双 surface 注册/注销、重复 id/组件、容量、surface 生命周期/乱序、per-owner 清理）；`rawfile-path` 43/43；`check-host-exports` 静态 + managed 153/153；真机探针（mw-l P1 子窗 XComponent：第二条 window 登记 + 双 surface 日志，主窗绘制零回归）。
- **退出标准**：单窗路径逐日志与 kit #49 一致（surface/触摸/帧/导出面）；第二 XComponent 事件只进注册表、不污染主窗；上列测试全绿；`build-host.sh` 三门禁（DT_NEEDED/UND/导出）通过。
- **风险/缓解**：同 env 多次 `Init` 的时序（探针已证每组件一次）→ 按组件指针去重；`GetXComponentId` 偶发失败 → 登记期取值，失败退 `surface-N`/`#n`；老壳无参 `registerXComponent()` → 首个 `main`，其后自动 id。

## M2 maui 切片 per-window renderer——5–8 人日

- **范围**：`OpenHarmonyBridge` 的静态单槽（`s_context/s_surface/s_surfaceHandlers`）改为按 window-id 的 per-window 对象；每窗 `WindowSurface`/`Renderer`/输入/键盘/焦点状态；宿主把第二窗 surface 事件分发给对应 managed 窗（无窗时保持记录态）。
- **文件级改动**（maui-ohos）：`src/Core/src/Platform/OpenHarmony/OpenHarmonyMauiAppHost.cs`、`OpenHarmonyWindowRenderer.cs`、`OpenHarmonyWindowSurface.cs`、`OpenHarmonyApplicationHandler.cs`、`MauiOpenHarmonyExtensions.cs`（DI 单例改工厂/按窗注册）。ow：`openharmony_host.{h,c}` 增 per-window 状态/分发入口，`host_napi.cpp` 接 managed 桥，`host-exports.txt` + `check-host-exports.py` 的 `SOURCES` 同步（新 DllImport 需 selftest 覆盖）。
- **测试**：`test/maui-platform-verify` 增 headless 双面用例（两窗各自 Render/Resize/Destroy/重建、状态不交叉）；导出契约；AOT 切片编译 0 warning/0 IL。
- **退出标准**：headless 下 `OpenWindow` 两个 managed 窗各自帧输出/尺寸/销毁语义独立；单窗套件（现有 checks/floor）无回归；AOT 打包通过。
- **风险/缓解**：单例 DI 与静态回调的耦合面大 → 先抽 per-window 对象、再删静态槽，小步提交；slice 上游 rebase 冲突 → 每步小 diff + 锁定 pin 提交。

## M3 壳侧子窗挂 XComponent + 输入路由——3–5 人日

- **范围**：`OpenWindow` → 壳 `createSubWindowWithOptions` + 子窗页 XComponent（`libraryname=openharmonyhost`，`registerXComponent('sub-N')` / `onDestroy` 注销）；子窗生命周期（created/shown/hidden/moved/closed/suspended）按窗上报；触摸/鼠标/键盘进子窗 XComponent 后按 window-id 归属；主窗输入不受影响。
- **文件级改动**（ow）：`packs/.../templates/ets/pages/Index.ets`（控制器 + 每窗注册/事件）、`pages/SubWindow.ets`（挂 XComponent、touch 转发、注销）、abc 重建与 provenance 同步、`host-exports.txt`（新增 managed 事件入口时）+ selftest；maui：`OpenHarmonySubWindow`/handler 按窗路由。
- **测试**：真机（HAD-W32）双窗画面 + 触摸落点判定卡；窗口移动/缩放/关闭事件顺序；关窗后注册表无残留（`unregisterXComponent` 返回值）；10 分钟 churn 无 fault。
- **退出标准**：`app://subwindow/open` 子窗出现第二 MAUI 视觉树并可交互；关窗回收；主窗回归（kit #48/#49 判定卡）。
- **风险/缓解**：子窗 XComponent 的 Init/onLoad 时序与焦点穿透 → 显式 window-id 登记 + M1 服务端去重；子窗数上限（预研未知项）→ 在 M3 用 2 子窗做上限探测，结论写回计划。

## M4 焦点/生命周期/IME/a11y/叠加层分区 + 验证轮——8–15 人日

- **范围**：每窗焦点/激活与系统 Back；每窗 IME 镜像（键盘焦点窗）；a11y：多窗节点树并入 provider（子窗根挂接/焦点顺序）；overlay：ArkWeb/CEF 槽池、alert/flyout/菜单按窗归属；避让区/安全区按窗；多窗下 home/后台/销毁生命周期。
- **文件级改动**：ow（`Index.ets`/`SubWindow.ets`/`entryability`、a11y provider 与 overlay 控制、`SubWindow.ets` 判定卡）、maui（a11y 发布/IME 绑定/overlay 宿主的 per-window 化）；若 N4 某项需第二 overlay 宿主（预研风险），以独立子分支做原型后再定。
- **测试**：真机矩阵（双窗×显示/隐藏/移动/缩放/旋转/锁屏/Home 恢复/进程重启）、a11y 真机 walk（子窗节点）、IME 输入、overlay 交互与 z-order、性能/内存对照（单窗基线 vs 双窗）；全套件（interaction/pixel/宿主单测）回归。
- **退出标准**：双窗全交互闭环 + a11y/IME/overlay 各判定卡通过；性能不回退（帧率/内存阈值）；单窗全部回归绿；E1 结论（2in1 debug 域）明确标注。
- **风险/缓解**：N4 任一项可能上探成本（预研 §3）→ 每项时间盒（≤2 人日原型），超限降级为"单 overlay 宿主 + 后补"并记录；共享设备与并行会话干扰 → 设备锁 + 单轮归档。

## 验证与提交规则（各 M 通用）

- 代码门禁：该 M 的单元/套件全绿 + `preflight.sh`（或对应子集）；宿主改动必须过 `build-host.sh` 三门禁；managed 改动过 AOT 编译。
- 真机证据：按 `device-round.sh` 锁协议（`mkdir .device-lock` + owner，掉线端口扫，锁屏人工），证据归档 scratch、不落库。
- 提交：ow 分支禁强推、按 `commit-paths.sh` 限路径；runtime-ohos 文档走 `feature/openharmony`；合并前不并 `master`、不动既有 kit 资产。

## 本文件时点状态（2026-10-06）

- M1 已实现并推送 ow 分支 `l/m1-window-registry`（`8ce4f58` + `82ef4e7`；SEC-5a 修复 `df2a246`）：注册表 66 checks（SEC-5a 后）、rawfile 43/43、导出 153/153；真机 HAD-W32 探针（mw-l 子窗 XComponent + 主窗）——`window 'ohos_dotnet_sub_surface' registered ... windows=2`、surface `0→2` 路由、`unregisterXComponent ... -> 1`、关-开重注册通过、主窗 `canvas presented (2090x1324) avg=16–17ms` 零回归（证据 scratch `mw-l/m1-*`，未入库）。
- M2/M3 已完成（记录见 `-l-m2.md`、`-l-m2-exit.md`、`-l-m3.md`；套件 629/631 floor 611 → 643/645 floor 625）、M4 进行中（预研见 `-l-m4-prestudy.md`）；人日为待验证估计（M4 再估 13–20 人日）。
- 回退：M1 分支独立，若产品决定不做 L，主机零行为变化即无需回退（注册表不被单窗壳引用）。
