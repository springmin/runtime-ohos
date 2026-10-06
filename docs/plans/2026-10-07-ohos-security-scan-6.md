# runtime-ohos 新面具安全复查 #6：L2 a11y provider + 子窗 ArkWeb（SEC-SCAN-6，2026-10-07）

**范围：** ow `l2/a11y-provider` @ `b6c0ce9`（新 `host_a11y_table.c/h` 节点表按 instance 分区、legacy 主分区；WithInstance provider/CUSTOM 节点/带窗动作，导出 163；壳 `SubWindow.ets` NodeContent/ContentSlot 双点上报）· ow `l2/arkweb-subwindow` @ `ee79a0a`（子 ArkWeb 池 `SUB_WEB_SLOT_MAX=2`、`s<slot>` 同码、`w:<surfaceId>|…` 事件、`child:` 前缀传输、64 条预就绪队列、hybrid/blazor 显式拒绝；`host_napi.cpp` child sink + 2 NAPI 属性）· maui `l2/a11y-provider` `ba7581022c`（按窗 lookup/modal/action/status_for）· maui `l2/arkweb-subwindow` `2e441c35c9`（OpenHarmonyChildWeb 槽池/传输/过滤）。**口径：** 离线读码 + 1 次纯 C host selftest（a11y 表）；未上机、未跑 C# 套件。**修复已落 L2 分支**（ow `f5a892a`、`3c486cf`，普通推送；未并 master、未动 #49/#50）。

## Verdict

**PASS WITH FINDINGS（0 高 / 0 中 / 3 低（2 已修、1 报告）/ 3 信息）。** ① instance/槽号/容量校验双向 fail-closed；② 主↔子双向按窗隔离成立（含套件红控）；③ 队列有界、重开同 id 有残留（低）；④ `child:` 负载无注入面；⑤ 资源上限全部 fail-closed；⑥ 降级无部分挂接。

| 指标 | 数值 |
|---|---|
| 复查面 | 6（① 可信面 · ② 隔离 · ③ 队列/生命周期 · ④ 负载解析 · ⑤ 资源上限 · ⑥ 降级） |
| 候选 | 6（低 3 · 信息 3） |
| 已修 | 2（A、B）；新增 C 回归 pin 1 条、C# 套件 pin 1 条（未执行） |
| 构建/设备 | 1×host selftest（脚本 13/13、unit 12/12、红控 8 FAIL）；无设备 |

## 发现表

| 编号 | 面 | 严重度 | 标题 | 证据（扫描 tip） | 判定 |
|---|---|---|---|---|---|
| SEC6-A | ①/⑤ | 低 | a11y 分区可由无 begin 的 `node_for` 分配：可耗尽 8 个命名分区，合法窗口随后拿不到 provider 分区 | `host_a11y_table.c:486`（`PartitionForLocked(instance, 1)`）；上限 `host_a11y_table.h:29` | **已修** `f5a892a`：node 写改 create=0（仅 begin_for 分配）；selftest +1 用例（12/12 green，红控含该条 FAIL） |
| SEC6-B | ② | 低 | 子通道标签 `w:main\|…` 被解析为 child window，事件可落到主窗池 handler（缺主窗拒绝） | `OpenHarmonyChildWeb.cs:319-321`（无 PrimaryWindowId 拒绝）；`OpenHarmonyWebViewHandler.cs:1409-1443,1070-1079` | **已修** `3c486cf`：TryParseState 拒绝空/主窗 id；套件 pin `primary tag rejected`（本轮未跑、CI 生效）；无在树生产者（子页只标自身 surfaceId） |
| SEC6-C | ③ | 低 | 关窗不回收窗口表：child web `s_hosts.Capacity/Pending`、a11y `s_windowFrames`/`s_providerPublishedWindows` 与 ow 分区常驻；重开同 id 时 `IsReady` 先于新 sink 为真、过期命令可打旧 sink、eval 超时；a11y first-publish 门禁在 events==0 时可跳过重开首帧 | `OpenHarmonyChildWeb.cs:183-213,364-382,445-453`；`OpenHarmonyWebViewHandler.cs:232-254`；`OpenHarmonyAccessibility.cs:204-241,891-899`；`OpenHarmonyWindowHost.cs:171-181` | 报告：产品壳 app 级 N=1 + 最低空闲 `sub-N` 复用 ⇒ 内存有界、影响为窄竞态；建议下波加 close hook（清 Capacity/Pending 与发布门禁） |
| SEC6-D | ② | 信息 | `s_pendingNavigation` 为跨窗静态：子窗 Back/Refresh 与主窗 load 重叠时，下一个 page event 的 Navigated 事件类可能错配 | `OpenHarmonyWebViewHandler.cs:133,476-480,1087-1090` | 报告：仅事件枚举错配，handler/数据归属仍按窗；无越权 |
| SEC6-E | ①/④ | 信息 | instance 校验允许 `\|`/引号等可打印 ASCII；`child:` 仅是 managed 前缀，子 eval 仅 app 代码可达 | `host_a11y_table.c:150-165`；`host_napi.cpp` child 标记/分流；`SubWindow.ets:511-608,756-777` | 报告：无跨信任解析面；`w:<id>\|` 生产者仅 managed `sub-N` |
| SEC6-F | ③/⑤/⑥ | 信息 | 队列/池/降级核对：managed 64 + shell 32 溢出丢日志；槽池双侧 clamp=2；无 child sink、未挂 provider、hybrid/blazor 均完整降级不部分挂接 | `OpenHarmonyChildWeb.cs:63-65,469-478`；`SubWindow.ets:59,717-726`；`host_a11y_table.h:29`；`host_napi.cpp` AttachAccessibilityValueFor | 报告：上限全部 fail-closed；255 上限仅探针，产品 N=1 |

## 逐面判定

- ① **A 已修**：NAPI 两向（`attachAccessibilityNodeFor`/`statusFor`/`nodeCountFor`）长度/可打印校验，超长/非法直接 0/-1；事件方向 instance 由 ArkUI 回显已注册串，未知/空在表层 0/-1、managed 未知窗 false；slot 为单字符 `s<slot>` 且 `<2/4`，capacity 仅 `int` 解析并 clamp 1..2。
- ② **B 已修，D 注记**：a11y 节点/动作/事件严格按窗（主分区 legacy 逐字保留，`PublishSecondary` 只走 `*_for`；`HandleAccessibilityAction` 未知窗 false、modal 按窗）；child web 双向由 `HandlerMatches` 窗+槽过滤（套件红控去窗过滤 → `primary event isolated` assert=False）。
- ③ **C 报告**：溢出均丢弃+单次日志；迟到事件在槽释放后无 owner 匹配即忽略（槽号复用为窗内窄竞态）。
- ④ **E 注记**：畸形/无 `s` 标签/越界槽号在 shell 与 managed 双侧拒绝；load/data/cookie 走 ArkWeb API；eval 仅 app 代码（子 hybrid/blazor 注册即拒、页→managed JS 通道不接子宿主）。
- ⑤ **A 已修，F 注记**：分区 8/实例 8/槽 2/队列 64+32 全 fail-closed；窗口表随 id 不复用时的增长受产品 N=1 约束。
- ⑥ **无缺陷**：无 `registerChildWebSink` → 不注册/不广告、队列封顶丢弃（原单宿主行为）；provider 未挂 → 帧本地保留；hybrid/blazor 拒绝即销毁槽、eval 立即回错。

## 修复验证 / 提交 / 不确定

- `selftest-host-a11y-table.sh`：T1-T5 全绿，unit `checks=12 failures=0`，红控 8 FAIL（含新用例）；未跑 host 全量构建、未跑 C# 套件。
- 提交：ow `f5a892a`（origin/l2/a11y-provider）、`3c486cf`（origin/l2/arkweb-subwindow）；本文件 → runtime `feature/openharmony`（`commit-paths.sh`）。
- 不确定：SEC6-B 的 C# pin 未执行（本轮仅 1 次 C 构建；CI/preflight 下轮生效）；SEC6-C 的 close hook 需下波立项；a11y 动作真机 e2e 仍受平台无读屏服务限制（沿用 W2 卡）。
