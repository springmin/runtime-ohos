# runtime-ohos 新面具安全复查 #7：B6 子窗 navask 网关 + a11y publish 变更（SEC-SCAN-7，2026-10-08）

**范围：** ow `master` @ `7259a0f`（`96267f2` B6 子窗导航否决 + `11972de` A11Y-SELFCHECK；壳 abc 542,936/`f18f0855…` 四包一致）· maui `feature/openharmony` @ `caa463434b`（`b64c477f8e` B6 + `4910d470db` a11y；修复落新分支 `sec7-fixes` @ `9aaa3b40f4`，未并主线、未强推）。**口径：** 离线读码 + 1 次交互套件构建兼跑（737/740 floor 720，含 `b6c` 5 条与 `m4 a11y selfcheck pending repaint`）；未上机、未跑 C 套件、未动 #53 发布件（abc/hap/tar 不改）。

## Verdict

**PASS WITH FINDINGS（0 高 / 0 中 / 1 低（已在新分支修复）/ 5 信息）。** ① 子窗 URL 网关与主窗同构、deny/ask/ok 不可伪造；② 窗/槽隔离成立（主窗标签上游拒绝、批准键命名空间化、答案按窗路由）；③ 全部 pending/队列/批准表有界、槽销毁清标记、`started` 一次性；④ a11y 直调探针 + `OnFrame` 重绘清除路径有界、无部分发布；⑤ 无 host/旧对端均 fail-closed 或 pre-B6；⑥ 主 `__OHNAV` 行为逐字保留，唯一不一致=SEC7-A（已修）。

| 指标 | 数值 |
|---|---|
| 复查面 | 6（① URL 信任 · ② 窗/槽隔离 · ③ DoSS/资源 · ④ a11y publish · ⑤ 降级 · ⑥ #53 一致性） |
| 候选 | 6（低 1 · 信息 5） |
| 已修 | 1（SEC7-A，maui `sec7-fixes` `9aaa3b40f4`；普通推送新分支） |
| 构建/设备 | 1×套件构建兼跑（`checks=737 total=740 floor=720 assert=True`、rc=0）；无设备 |

## 发现表

| 编号 | 面 | 严重度 | 标题 | 证据（扫描 tip） | 判定 |
|---|---|---|---|---|---|
| SEC7-A | ④/⑤ | 低 | close-hook 的 native release 仍被退役款 `NativeLibrary.TryLoad` 预探针把门：loader 误报 "no export" 时 SEC6-C 宿主半段（分区释放/attach 记录复位）静默跳过 | maui `OpenHarmonyAccessibility.cs:263-286,295`（@ `caa463434b`）；对照已修 `WindowProviderExportAvailable`（kit#53 根因 `export=False status=1`） | **已修（新分支）** `sec7-fixes` `9aaa3b40f4`：直呼 `ohos_host_accessibility_release_for`，`EntryPointNotFound`/`DllNotFound` 缓存 -1 保持旧宿主 managed-only 降级，成功缓存 1；影响本就 bounded（分区上限 8、managed 半段仍清帧/标记、`begin_for` 复用复位） |
| SEC7-B | ②/① | 信息 | `HandleChildNavigationRequest` 只验 `IsValidWindowTag`、不验 `IsApplicable` | `OpenHarmonyWebViewHandler.cs:895-901`；`OpenHarmonyChildWeb.cs:386-407` | 报告：`w:main\|` 已被 `TryParseState`（SEC6-B）上游拒绝，直呼才可达；建议级防护，不改 |
| SEC7-C | ③ | 信息 | 子窗 ask 无主道 `hostCall` 的“投递失败即删 pending”：`notifyWebHostState` 为 void，投递失败条目驻留至 5 s TTL/8 表淘汰 | `SubWindow.ets` `askManagedAboutChildNavigation`/`notifyWebHostState`；对照 `Index.ets:4260-4288` | 报告：仍 fail-closed、有界；改壳需重编并改 abc 指纹，不值得 |
| SEC7-D | ④ | 信息 | `OnFrame` 强制重绘的上界=帧 tick（非严格一次）：清除路径=发布成功；旧/缺失导出经缓存 -1 后 pending 不再成立 | `OpenHarmonyWindowHost.cs:381`；`OpenHarmonyAccessibility.cs:959-1092` | 报告：仅“status=1 且每次发布抛一般异常”的理论情形按 tick 重试（无内存无界，只有重绘）；改动有回归 selfcheck 修复的风险，不改 |
| SEC7-E | ①/⑥ | 信息 | `approveChildNavigation` 先置一次性标记再 `loadUrl`；reload 抛异常后同 URL 在 5 s 内可消费该标记 | `SubWindow.ets` `approveChildNavigation`；对照 `Index.ets` `approveNavigation` | 报告：语义=同一已批准 URL 的一次使用；与主窗 #53 同形，无越权 |
| SEC7-F | ③/⑥ | 信息 | 导航 ask 风暴无速率上限（每次 ask 同步进 managed `Navigating` 与状态行） | `SubWindow.ets` `onLoadIntercept`/`askManagedAboutChildNavigation` | 报告：pending/队列/批准/状态文件全有界（8/32/64/256 KiB）；与主 B6 #53 同形，建议后续波次统一限速 |

## 逐面判定

- ① **PASS**：子窗 allow-list 与主 `Index.ets isAppNavigation` 同构（先拒 `//`、`/\`、`\\`、`\/`，前导 C0 跳过；`/` `#` `?` 快路径；about/data/blob/javascript/file + 本槽 hybrid/Blazor origin）；managed 侧绝对 http(s) 带 host、控制字符、短/长/空、slot<2 全拒（`//host`、`https:foo` 由套件 pin）。状态机：id=壳生成 UUID 存本页 pending，批准需 (id,slot,url) 精确三元组且未过期；页面 JS 只能 `postMessage`（`__OHORIGIN` 包裹，不作 navask/`__OHNAV` 分派），伪造 event 不可达。
- ② **PASS**：`TryParseState` 拒空/`main`；navask 需 child 窗+槽；`RaiseNavigating` 按 `_overlayWindowId`+`_overlaySlot` 过滤；批准键 `child|<win>|<slot>|<url>` 命名空间不与主键冲突；答案经 `CommandForWindow(windowId,"nav",Tag(slot,id+url))` 只回该窗 sink；套件隔离 pin。无 handler 槽=主道同款 fan-out 语义（提交命令、槽无页面时不可达），接受。
- ③ **PASS**：pending 8/TTL 5 s/URL 8 KiB、槽 defer 32、managed 队列 64/窗、批准表 64 共享 cap+prune、状态文件 256 KiB；`started` 一次性消耗（重放再抛，pin）；槽销毁清 `subNavProgrammatic/Approved/Pending`（旧批准不落到新占用者）。
- ④ **PASS**：`provider_status_for` 直调、`EntryPointNotFound` 缓存降级；`WindowPublishPending`=帧+attached+未发布，`OnFrame` tick 级强制重绘、发布成功即清；provider 未 attached → 本地帧+单日志，无部分发布；退役预探针后 attach 失败路径=本地降级（见 SEC7-D 上界）。
- ⑤ **PASS**：无 host channel → ask 取消、pending 过期（fail-closed）；旧 managed + 新壳 → navask 入通用路径、不批不放；旧壳 + 新 managed → 无网关=pre-B6 行为；a11y 未挂 provider 全本地降级，无部分挂接。
- ⑥ **PASS（注 SEC7-A）**：主 `__OHNAV`/主批准键/主 `started` 行为逐字保留（`ApproveNavigation=>ApproveNavigationEntry` 等价重构）；四包 abc/ets 字节一致（`f18f0855…`/`ea10a7f0…`）；套件 737/740；唯一不一致=release 预探针（#53 前资产；新分支修，不回改发布件）。

## 修复验证 / 提交 / 不确定

- 验证：1×`dotnet build -m:1`（maui slice+harness，pin 预建 Hosting/Graphics DLL；0 error）+ 1×套件并跑 `checks=737 total=740 floor=720 assert=True`、rc=0、`b6c` route/cancel/fail-closed/isolation/source 全 True、`m4 a11y selfcheck pending repaint` True。
- 提交：maui `sec7-fixes` @ `9aaa3b40f4`（基 `caa463434b`，普通推送 `origin/sec7-fixes`；不并 master/feature、未强推）；本文件 + README 索引 → runtime `feature/openharmony`（`commit-paths.sh` 限路径；直推，被拒则 fetch/rebase 或旁路钉/Git Data API）。
- 不确定：SEC7-A 的 loader 误报底层根因未追（沿用 kit#53 口径）；native 释放仅离线编译+套件背书、未上机；同族 `NativeLibrary` 预探针（announce/action-listener/chrome/screenshot 提示位）未逐一改（建议后续波次统一评估）；ask 限速未做（与 #53 同形）。
