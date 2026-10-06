# MULTIWINDOW-L M4：焦点/生命周期/IME/a11y/叠加层分区 + 全量验证轮（2026-10-06）

> 口径：按预研 `-l-m4-prestudy.md` §5 顺序先做稳定面 M4-05→02→03→04（第一波），第二波收尾余项
> （pinch 按窗实施；子窗 a11y provider 与子窗 ArkWeb 按时间盒降级并文档化）并完成 M4-01/05上限/
> 06/07 证据轮、AOT 完整 publish（.28）与套件终态。
> 载体：ow `l/m4-focus-ime`（第一波 `2c0f1f5`+`27055f9`，第二波 `9738d7e`+`06859d4`）· maui
> `l/m4-per-window-focus`（第一波 `c7f440fc65`，第二波 `c2a59fbf27`）。未并 master、未重切 #49 资产。
> 提交：ow/maui 普通推送（未强推）；本文档（runtime `feature/openharmony`）。

## 逐项状态（M4×7 终态）

| 项 | 状态 | 实现要点 | 证据 |
|---|---|---|---|
| M4-05 suspend/resume | ✅ 完成 | 壳上报子窗 ACTIVE/INACTIVE（11/12）+ 既有 SUSPENDED/RESUMED；app host 路由为 per-window `IWindow.Activated/Deactivated/Stopped/Resumed` 状态机（幂等、主窗进程生命周期零变化）；SEC5B-L3 兜底：仅 Closed 也回收会话 | 套件 m4 life×5；真机 18:09 `main window hidden: subwindow suspended` → `aa start` → `main window shown: subwindow resumed`；**×10 每轮恰 1 hidden/1 shown**、pid 恒定；close→`[maui] subwindow closed`+`unregistered=1`；再 open 被应用级拒绝（`the managed child window is already open`） |
| M4-02 焦点/IME | ✅ 离线 / ◐ 真机（人工卡） | 子窗页：隐藏 TextInput + focusable XComponent(onKeyEvent) + onBackPress；AppStorage 焦点通道（managed op 6→Index→子窗 `requestFocus`/IME）；text/composition/submit/key/back 走既有 tagged 子窗通道；Entry/Editor/SearchBar 按窗解析路由 input/focus | 套件 m4 input×7；真机子窗隐藏输入节点 `sub-1__input` 在位（dumpLayout）+ 键盘跟随/失焦收起链路；**uitest `uiInput` 无子窗 XComponent/多点注入面**（help 仅 click/swipe/fling/keyEvent/inputText/text，click 未达子窗）→ IME 实敲见「人工验证卡」 |
| M4-03 a11y 分区 | ✅ 离线分区 / ⛔ 子窗 provider 降级 | 每窗影子帧：主窗保持既有 provider 路径零变化；子窗帧本地保持、不覆盖主窗；告警节点只进归属窗；action/模态只走主 provider | 套件 m4 a11y partition + alert owner（红控 X）；真机子窗渲染时 `window 'sub-1' keeps its shadow frame locally (no per-window provider yet; the main provider is unchanged)`；主 provider 路径零变化 |
| M4-04 overlay/alert/pinch | ✅ pinch 按窗 / ◐ ArkWeb 降级 | alert 按窗归属（第一波）；主窗 overlay 不再吞子窗触摸；字体重排；**第二波 pinch 按窗**：宿主每窗独立手势状态→`ohos_host_notify_window_pinch`→hosting `WindowPinch`→该窗 renderer | 套件 alert owner + **pinch routed / main+unknown+空 id 拒绝**（+2，红控）；`selftest-host-window-bridge` 26 script / 14 unit checks；真机多点注入不可用（uitest 无触点多点能力），ArkWeb 第二宿主降级（见下） |
| M4-01 双窗帧率 | ✅ 完成 | 双窗 ActivityIndicator 持续出帧；`WindowFrameStats` 每窗 5s 一行（fps/avg/max/long/longruns），主窗走 untagged、子窗走 tagged 帧通道 | JIT 稳态：主 60.0 fps（avg 16.7ms max 20–22ms long=0）、子 60.0 fps（max 17ms long=0）；AOT 稳态同（主 max 20–24ms）；单/双主窗均 60.0 → 退化 0%；启动首报告 54.7–59.3 fps（max≈54–223ms）为进程暖机（单/双同现，不计稳态） |
| M4-07 混合 JIT/AOT | ✅ 完成 | JIT/.28 与 AOT/.28 两次完整 publish；mode marker `libs/arm64-v8a/runtime-mode.txt` 各自校验；双窗主路径首帧/帧率对照 | JIT hap 123,267,728 B / `a4a3caac…`（marker=jit）；AOT hap（unsigned）30,909,710 B / `335c8ef1…`（marker=aot、IL2026/3050/3051=0）；两模式真机均 `windows=2`、`first frame=True`、双窗稳态 60 fps、0 fault |
| M4-06 40min 长稳 | ✅ 完成 | `device-round` 采样法（pid/VmRSS/threads/updateTime/fault diff）+ 每 5min 双窗交互脉冲；churn ×20 与 suspend ×10 同轮叠加 | 41 采样（t=0..40）：pid 64754 恒定、pid_lost=0、fault_new=0、updateTime 不变；RSS 310,116→275,664 kB（**净 −34 MB**、11 次回落、t=32 GC 337→274 MB）、threads 70–78；churn pid 60129 恒定、fault 71→71、WMS 子窗残留 0 |

## 第二波：余项实施与降级

| 项 | 结果 | 实现/证据 |
|---|---|---|
| M4-04 pinch 按窗 | ✅ 实施 | 宿主 `host_napi.cpp` 每窗独立 pinch 状态（active/起始距离，8 槽 id 表，注销随窗释放），经 `host_window_bridge.c` 新 `ohos_host_notify_window_pinch` 上报；hosting 新导出 `ohos_host_register_window_pinch` + `WindowPinch` 事件（导出 156→**157**）；切片 `OpenHarmonyMauiAppHost.RoutePinch`→`OpenHarmonyWindowHost.HandlePinch` 只打该窗 renderer。单测 +2（id/相位/缩放/中心、NULL 禁用、空 id 丢弃）；套件 +2（pinch routed / main+unknown+空 id 拒绝）+离线红控。真机：`uitest uiInput` 无多点注入 → 真机 pinch 注入不可用，按窗路由由离线条目+宿主单测覆盖。 |
| 子窗 a11y provider | ⛔ 降级（文档化） | 平台面存在 `OH_ArkUI_AccessibilityProviderRegisterCallbackWithInstance`（`native_interface_accessibility.h`，@since 15；`ArkUI_AccessibilityProviderCallbacksWithInstance` 每回调携 instanceId），但当前 provider 为「单 NodeContent→单 CUSTOM 节点→单套全局节点表 + 单 action 监听」；接入第二 provider 需：节点表按 instance/window 分区（写路径新 window 导出、读路径 WithInstance 回调全链路 window 化、action 归属）+ 子窗 ContentSlot/`setNodeContent` 宿主导出，>2pd 时间盒 → 维持预研降级线：**主窗 provider 零变化**、子窗影子帧本地保持不覆盖主窗。下波路径 = 上述四步小步提交 + headless 红/绿（A 窗发布后 B 窗发布，A 仍完整）。 |
| 子窗 ArkWeb 第二宿主 | ⛔ 降级（文档化） | 槽池（WEB_SLOT_MAX=4/HOT=2）与 per-slot 控制器/defer 队列全部声明在主窗 `Index.ets`，managed web 句柄全局领槽（`s<slot>` 命令）；第二宿主需 `SubWindow.ets` 重实现槽池+控制器+defer 队列 + managed 带窗领槽通道 + 设备调试，超 ≤2pd 时间盒 → 维持单（主窗）overlay 宿主；子窗 web 控件不挂载（=现状，无回归）。下波路径 = 槽声明参数化到可复用 builder + 领槽命令带 surfaceId。 |
| M4-05 上限探测 | ◐ 应用级 N=1（真机复核）；平台级未探 | 样例 `OpenManagedSubWindow` 已开即拒（真机 status 行） + 切片 SEC-5b 拒第二 deferred + 壳第二 managed id 回 Failed 801；churn ×20 无残留（WMS 0 行、pid 恒定）。**平台级多子窗容量未探**（需 scratch 壳探针：临时 `Index.ets` 探针 create N=3/4 原始子窗记成败，跑后还原 abc/packs；超本轮时间盒）。降级路径=诚实拒绝、不留残窗。 |

## 验证轮（M4×7 真机 + 长稳；阈值冻结）

- **M4-01**：单窗基线主 60.0 fps（JIT/AOT 同）；双窗主 60.0、子 60.0。冻结阈值：主窗 **≥50 fps**、子窗 **≥40 fps**、主窗较单窗退化 **≤10%**、稳态连续长帧（>33ms×3）**=0**；启动暖机首个采样窗（单/双同现）不计。
- **M4-05**：Home→Suspended、resume→Resumed 事件序 ×10 每轮 1/1；close→`unregistered=1`、reopen 同 id（`registered=1`）；上限拒绝行见上。
- **M4-06**：见逐项表；内存冻结：双窗稳态 VmRSS ≤ **400 MB**（实测峰值 337.9 MB、末值 275.7 MB）、40 min 无单调增长（净 −34 MB、11 次回落）。
- **M4-07**：两模式 marker + 首帧 + 帧率对照；AOT 全程 0 IL gate、0 fault。
- **M4-03/04 真机面**：a11y 主窗 provider 路径不变 + 子窗不覆盖（status 行）；pinch 走单测+套件（注入面限制）；alert 归属离线 pin。

## AOT publish（workload .28）

- `publish-aot.sh`（NativeAOT + UI shell，`OpenHarmonyRuntimeMode=aot`，hooks 本机 Exec 绕行；`aot/publish-aot.log`）：`EXIT=0`、**IL2026/IL3050/IL3051=0**、marker `libs/arm64-v8a/runtime-mode.txt=aot`；hap（unsigned）**30,909,710 B / `335c8ef1…`**、签名件 31,271,678 B、应用 `libso` 19,495,696 B。
- 余下 126 warning 全为基线类（CS0618 55 / NETSDK1188 34 / CA2255 23 / 第三方 IL3053 3 / IL3000 3 / IL2104 3 / CS8604 2 / NETSDK1249 1 / CS8766 1 / CS8613 1），无本波源码新增告警。
- AOT 真机：安装/启动、双窗 `first frame=True`、稳态 60/60 fps、close 回收；faultlogger 0。

## 套件与门禁（绿/红）

- `test/maui-platform-verify` +2 checks（M4-04 pinch 按窗）：`verifyCheckTotal` 660→**662**、floor 640→**642**；实跑 `[suite] checks=660 total=662 floor=642 assert=True`、0 Unhandled、0 assert=False（declared==printed，delta=+2）。
- 单窗零回归：preflight（`preflight.log`）——repository gates PASS（ridgraph 20 / packs 25 / hap-targets 79 / tasks 9 / repo-hygiene 25 / host-registry 84 / **host-window-bridge 26**）、`sh -n` 50 scripts PASS、interaction **660/floor 642 PASS**、pixel **PIXEL ASSERTIONS PASSED**；导出 **157/157**（`check-host-exports.py --cross-check`）；markdownlint 唯一 FAIL 为未跟踪构建目录 `.a11y-build/**`（非本波文件，CI checkout 不含；本仓改动文档 MD009=0）。
- 离线红控（还原修复→断言 False）：去掉 `OpenHarmonyMauiAppHost` 的 `WindowPinch` 路由 → `m4 pinch routed`、`m4 source pins` 两条 `assert=False`、run exit 134（`red-run.log`）；随后恢复源码复跑全绿（`red-restore-run2.log`）。

## 真机证据（HAD-W24 / OpenHarmony 7.0.0.111 / 2in1；证据 scratch `mw-l/m4b/`，不入库）

- JIT 轮：open（`windows=2`、`first frame=True`、子窗 60 fps）→ IME 注入尝试（click/text 未达子窗，转人工卡）→ Home suspend/resume（含 ×10 序列 1/1）→ 二次 open 应用级拒绝 → close/reopen 同 id → churn ×20（pid 恒定、fault +0、WMS 残留 0）→ soak 40 min（见 M4-06）。
- AOT 轮：安装 → open（`first frame=True`）→ 双窗稳态 60/60 fps → close。
- `.device-lock` 协议持有（单轮一波一锁，轮末恢复 kit #49 hap 后释放；当前设备为 kit #49）。

## 人工验证卡（子窗 IME 实敲；不阻塞交付）

**前置**：安装 M4 终态 hap；设备解锁、无遮挡；`aa start -U app://subwindow/open` 打开子窗。
**步骤与期望**：

1. 鼠标/触摸点击子窗内 Entry（子窗 (120,160) 720×480，Entry 在标题/counter 下方）→ 期望系统键盘弹出、焦点在子窗；主窗无键盘。
2. 实敲 `hello-child` + 回车 → 期望子窗 Entry 显示文本、`subwindow event TextInput`/`TextSubmitted`、`child entry text` 行只出现在子窗。
3. 切到主窗再敲字 → 期望主窗文本不受子窗影响（跨窗事件=0）。
4. 关闭子窗 → 键盘收起；重开 → Entry 回到初始 `seed`。

**回传格式**（4 行）：设备/包/时间；每步 OK/FAIL+现象；关键 hilog（`hilog -x | grep -E 'OHOS_MAUI_SUB|hello-maui|text input focused|child entry'` ≤20 行）；截图 2 张（子窗聚焦键盘覆子窗、主窗无键盘）。失败时附 `hilog -x > ime-fail.raw` 与 `uitest dumpLayout` 输出。

## 边界与下波

- 仍是单 managed 子窗（壳 801 契约；应用级上限 N=1）；2in1 debug 域结论，不外推手机/release。
- 降级遗留（下波）：子窗 a11y provider、子窗 ArkWeb 第二宿主、平台级多子窗容量探针、子窗 safe-area 系统条、窗作用域 DI（仅失败才做）。
