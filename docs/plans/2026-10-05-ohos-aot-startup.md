# AOT 启动再省：ArkWeb 引擎初始化移出首帧路径（AOT-STARTUP，2026-10-05）

> 设备 HAD-W32（OpenHarmony-7.0.0.109 / API26 / 2in1），hdc 127.0.0.1:35111，debug 自签域；件 = kit #47 三路径
> 载荷 + 新壳 abc/宿主 .so 重签（同载荷 A/B）。度量 = StartupProbe + 壳 `[startup-shell]` + 框架 hilog；scratch `aot-startup/`。

## 1. 等待分解（AOT，Main=0，ms，3 冷启）

| 段 | 值 | 结论 |
|---|---|---|
| Main→Created | 31–36 | 托管建窗完成（远早于 surface） |
| Created→attach | ~60–90 | 壳页 build 到 XComponent 挂树（`AttachToMainTree`） |
| **attach→surface** | **228–248（均 239）** | 全在 **ArkWeb/CEF 引擎初始化**：首个 Web 组件实例化 → `InitWebViewWithSurface` → `CreateNWeb`/`CefContext::Initialize` 同步占 UI 线程 ~240 ms，surface 回调推迟到其后（`Root node request first frame` 后 +13 ms 起 CreateNWeb，+248 ms 才 `triggers onLoad and OnSurfaceCreated`） |
| surface→present | 12–21 | 不变 |

- 壳页 build 声明两个隐藏 ArkWeb 覆盖层，其创建即启动 CEF，与 AOT 托管就绪（Created=31）串行；JIT/interp 同
  ~240 ms 但托管启动慢、等 surface≈0，故只伤 AOT（旧表 280–310 即此段可控部分）。

## 2. 改动（壳 + 宿主）

- 壳（四包 `Index.ets`）：`@State webOverlaysMounted=false`；`ensureWebSlot`（defer/ensure 唯一漏斗）首用置
  true 并记 `[maui] web overlays mounted on first use`；build() 覆盖层 `ForEach` 包进 `if`。声明字面量
  `webSlots=[0,1]`、`webSlotCreated=[true,true,false,false]` 不变——覆盖层仍声明，ArkWeb 实例化延后到首用。
- 宿主（`openharmony_host.c`）：`set_app_context` 对**相同快照跳过 surface 重放**（不同仍重放）。否则 onLoad
  的 `publishAppContext` 会在 app 线程 `register_bridge` flush 期从壳线程重入托管；surface 提前后 JIT 必现死锁
  （`hidumper -e` ThreadBlock6S：UI=OnSurfaceNative × app=OhosHostBindAndFlushBridge）。

## 3. 真机 A/B（同载荷，冷启，AMS→首帧 ms；括号均值）

| 路径 | 壳 | n | AMS→Main | AMS→首帧 | Main→首帧 | attach→surface |
|---|---|---|---|---|---|---|
| AOT 基线 | pilot（探针） | 3 | 364–449 | 753–841 (796) | 376–392 (386) | 228–248 (239) |
| AOT 优化 | aot-opt | 3 | 371–391 | 522–546 (534) | 146–155 (151) | 12–14 (13) |
| AOT 优化（净） | aot-clean | 1 | 394 | 549 | 155 | 15 |
| JIT 基线→优化 | base-h→opt-h | 1→2 | 600→575/638 | 1118→1031/1164 | 518→456/526 | 232→14 |
| interp 基线→优化 | base-h→opt-h | 1→1 | 702→700 | 1331→1278 | 629→578 | 240→14 |

- AOT **−262 ms**（Main→首帧 −235）；首帧后 3–17 ms 才挂覆盖层，CEF 移出首帧路径，hybrid 注册/装载照常
  （`web cmd: hybrid`→`hybrid assets`→`web serve`）。JIT/interp 不回归（JIT 新宿主 0 次 THREAD_BLOCK）。

## 4. 提交 / 见证

- 提交：ohos-workload `22ca602`（四包 Index.ets+abc+provenance、`openharmony_host.c`、packaging 文档，
  `commit-paths.sh` 已推 master，导出 151 不变）；本文件在 runtime-ohos；套件钉（+1）见 `test/maui-platform-verify`。
- 见证：abc **371,860 B（`88f7c64b…`）**/headless 24,324 不变；宿主重建 297,888 B（`7a4984bd…`）；scratch `out/*.hap`（6 件）、三路径 stream、`logs/fault-jitopt-r2.txt`（死锁栈）。切片 0 IL。
- 不确定：单设备共享桌面（`com.example.perf2` 曾污染 JIT 首轮，已锁定+重测）；AOT 基线/优化非同轮交替（±20 ms 级漂移）；未认领覆盖层零成本仅由首用日志与冒烟覆盖，未做长时 soak。
