# MULTIWINDOW-L2 选项分析：三项降级 + 平台上限未知（只读，2026-10-06）

> 口径：只读分析（不实现/不改码/不用设备；设备被 SOAK50 占用）。素材 = `-l-consolidate.md` §5、`-l-m4.md`、
> `-l-m4-prestudy.md` §3/§6、平台限制 E5；代码走查 = ow `packs/.../preview.28/templates/ets/pages/{Index,SubWindow}.ets`、
> `src/OpenHarmonyHost/{host_napi.cpp,openharmony_host.c,host-exports.txt}`、maui `OpenHarmonyAccessibility.cs`；
> SDK `native_interface_accessibility.h` 的 `OH_ArkUI_AccessibilityProviderRegisterCallbackWithInstance`（@since 15）。
> 边界：2in1 debug 域单项结论；三项均为 #50 已文档化降级，不判缺陷。

## a) 子窗 a11y provider

- **价值/影响**：子窗是完整第二 MAUI 视觉树，但读屏读不到其内容（`Publish(非主窗)` 只本地留帧、不触宿主 provider）；
  影响 = 子窗内控件对读屏不可见/不可操作；主窗 a11y 零变化。价值 = 补齐第二视觉树的可访问性承诺面。
- **技术路径**（四步，沿用 `-l-m4.md` 下波路径）：
  1. 壳 `SubWindow.ets`：加 `NodeContent`+`ContentSlot`，`onPageShow` 经新 `host.attachAccessibilityNodeFor(instanceId, content)` 上报（对齐主窗 6190–6198 `setNodeContent` 模式）。
  2. 宿主 `host_napi.cpp`：第二 CUSTOM 节点 + `RegisterCallbackWithInstance`（@since 15，每回调携 `instanceId`）。
  3. `openharmony_host.c`：节点表按 instance/window 分区（现单静态表 + `begin/node/commit`）；新导出 + `host-exports.txt`/`check-host-exports.py`/宿主单测同步（157→+N）。
  4. maui `OpenHarmonyAccessibility.cs`：`Publish(windowId)` 子窗写自身 provider；`OnAction/TryFindNode/TryFindView/IsModalNode` 带窗（现只读主 `s_frame`）；SEC-4 密码脱敏 pin 复制到子窗。
- **可测性（无读屏机）**：离线绿 = headless 双窗各 Refresh/Publish 后 A/B 互不覆盖 + 动作按窗路由（扩现有 `m4 a11y partition`/`alert owner`）；宿主表分区 C 单测；
  红控 = 去掉窗参数 → A 被 B 覆盖断言 False。真机（无读屏）= per-instance attach status + per-instance nodeCount 自检；读屏 e2e 受平台限制 B1 → 需外部复跑。
- **成本/风险**：3–5pd（中置信 ≈0.5）。最大未知 = 主+子两 provider 并存与子窗 `ContentSlot` 挂接（平台拒绝 → 回退现状、主窗零回归）。
  回归面 = 主 provider 路径（pin 零变化）、动作路由、SEC-4；导出/契约变更需三处同步。
- **推荐：做**（残余价值最高）。波次：W0 并存首验（设备 0.5pd，失败即收）→ W1 离线全链（2–3pd，可与设备占用期并行）→ W2 真机自检（1–2pd，SOAK50 释放后）。
  rc.2：W1 离线不被阻塞；若官方 rc.2 先触发，先按 runbook 重锚，再在其上做 W2（每波只重编一次 abc）。

## b) 子窗 ArkWeb 第二宿主

- **价值/影响**：子窗内 Hybrid/Blazor WebView 不挂载（=现状，无回归也无渲染）；OAuth/`onWindowNew` 本已未接（E2）。
  影响面 = 把 web 内容放进子窗的应用形态；主窗 web/overlay 全链不受影响。
- **技术路径**：槽池（`WEB_SLOT_MAX=4/HOT=2`、per-slot 控制器/defer 队列、`registerDotNetHost(slot)`）全在 `Index.ets`（659 起，7.4k 行）；
  `SubWindow.ets` 重实现或抽共享 builder 模块；managed `OpenHarmonyBlazorWebViewHandler`/`OpenHarmonyOverlays` 领槽带窗（现全局 `s<slot>` 命令）；宿主导出面预计不变（待实现确认）；需设备调试（ArkWeb 在非主窗未证）。
- **可测性**：离线 = 槽池抽模块后 shell source pins + 套件 slot 用例可先行；真机 = 子窗载 web 页/overlay z-order（无需读屏）；
  红控 = 去掉窗标记 → 子窗命令落主槽。
- **成本/风险**：预研时间盒判定 >2pd；现估 3–5pd（低置信 ≈0.4：主壳最热文件重构 + 非主窗 ArkWeb 平台未知）。
  风险 = overlay/hybrid/Blazor 全链回归、ArkWeb 在子窗可能被平台限制。
- **推荐：推迟（本轮不做）**；只在出现明确子窗 web 需求时排 a) 之后，重设 ≤3pd 时间盒，超限维持降级。

## c) 平台级多子窗上限（仅探针设计）

- **价值/影响**：应用级 N=1 是切片/壳自设（801 拒绝、无残窗）；平台真上限未知 → 多 managed 子窗是否可行无法外推。探针只改结论，不改产品。
- **探针设计**：
  1. 目标：单 app 并发 `window.createSubWindowWithOptions` 的 N_max（1/2/3/4…）、首个失败 code/message、destroy 后 WMS 残留、与既有 managed 子窗的共存余量。
  2. 步骤：① 离线（≈0.5pd）用 preview.28 壳模板在 scratch（`mw-l/l2/probe/`，不入库）加 `app://probe/subwindow-capacity` 触发：顺序 N=1..5 create→记录→destroy，再并发 N 个（off-rect 小窗）记录成败，全部 destroy；
     ② 设备（≈0.5pd）装探针 hap、触发、`hidumper -s WindowManagerService` 查残留、pid/fault 前后对照；③ 跑完把 abc/packs 还原到 #50 锚并 `verify-kit.sh` 收口。
  3. 判据：报最大全成功 N 与首个失败 code；destroy 全 resolve、WMS 无残留、pid 恒定、fault +0、无残窗。N_max=1 ⇒ 应用级 N=1 与平台一致（降级永久化）；N_max≥2 ⇒ 标余量，产品化另行立项。
  4. 时长/依赖：**1–1.5pd，需设备**（SOAK50 释放后并入一轮设备窗）；探针与产品代码/分支隔离。
- **成本/风险**：低（scratch、不动产品/资产）；风险 = abc/packs 还原遗漏 → 以 `verify-kit.sh` + provenance 复核。
- **推荐：做**（小、独立、只关问题票）。

## d) 接受降级（现状）

- **价值/影响**：零成本、零回归；主窗/单子窗/主 provider/web 全链不受影响；#50 交接与 E5 已把三项标为「预期边界」。
- **成本/风险**：0；仅预期管理（tester/用户可能把子窗 a11y/web 当缺陷——E5/handoff 已缓释）。
- **推荐：兜底口径**：a/b/c 任一超盒即回到本项；不叠加、不重切 #50 资产。

## 建议的下一步排序

1. **c 探针**（1–1.5pd，需设备）：SOAK50 释放后第一优先——只读结论、不动产品；N_max=1 即永久关闭该问题。
2. **a provider**：W0/W2 需设备；W1 离线可并行于设备占用期。价值最高，且失败可零回归收口。
3. **b ArkWeb**：推迟，绑定明确需求；不排默认波次。
4. **全部接受降级**：若 2/3 缓做或超盒，维持 #50 现状 + E5「接受」口径，仅补指针到本文件 §c；不重切 kit、不动 README（索引稍后批）。
- 与 kit/rc.2 节奏：每波只重编一次 abc；rc.2 重切若先到，先重锚再排设备轮；任何情况下都不动 #49/#50 已发布资产。

## 备注（代码走查结论，供实现者）

- `Index.ets` 的 managed 子窗为单实例（`subWindow`/`subWindowCreating`，第二 surface → 801，2514–2522）；平台探针应绕开此层直接用 `createSubWindowWithOptions`。
- 现有 `s_windowFrames`/`NodesForWindow`/`FrameWindowCount`（`OpenHarmonyAccessibility.cs:158–223`）已给 a) 一半地基；缺口 = 宿主表分区 + 动作窗化 + 子窗 ContentSlot。
- `host-exports.txt` 现 167 行（含注释），导出基线 157/157；a) 新导出与 `check-host-exports.py --cross-check` 同步即门禁。
