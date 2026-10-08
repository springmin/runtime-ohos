# E4 >4 覆盖层 attach 定因（审计 #7 / 限制表 E4，2026-10-08）

> 设备 HAD-W32 / OpenHarmony-7.0.0.109 / API26 / 2in1（UDID `1BCE13C8…AEA0`）；全程本地 `.device-lock`
> 互斥（mkdir+owner，结束释放）。装置 = probe8（9×HybridWebView、托管 `OHOS_OVERLAY_MAX=8`）+ 壳
> `WEB_SLOT_MAX=8`；修正壳只在 scratch 工作树构建（产品码/切片零改；#49–#53 资产未动）。原始件 = scratch
> `/data/storage/el2/base/tmp/opencode/e4-probe/`（`e4-run.sh`；`device/r0,r1,r1b,r2-{hilog,txt,json,jpeg}`；
> `probe8-fix8b-signed.hap`；`artifacts/Index-fix8b.ets` + `modules-fix8b-371012.abc`；`build-fix8*.log`）。

## 结论：E4 = 我们可修（有界壳 bug），平台不设 >4 上限

- **修正壳下真机 8 槽全部 attach/服务/渲染、两轮冷启稳定**：a11y `rootWebArea=8` ×2、0 退出、pid 稳定；
  平台侧 ArkWeb 同时 8 实例（`nweb_stats … max_instance_count=8`；`JsConstructor=9`（含遗留
  `webController`）、`OnAttachToFrameNode=8`）。
- 2026-10-05 “槽 4–7 建而不挂/未服务”机制：临时补丁**只改了常量**，**两组逐槽表仍硬编码长度 4**——
  ①`webVisible/webZOrder/webFrameX|Y|W|H/webSlotCreated|Attached/webControllers/hybridBase|Root|
  DefaultFile|Registered|DocId|ServeLogs/blazorBootstrapped/dotNetHostRegistered`（16 个）
  ②`navProgrammatic/navApproved`；且 `webControllers[slot] === null` 对越界回读 `undefined` 不成立
  → 槽≥4 不建控制器 → 命令永久 `web slot defer`（probe8 abc 反汇编实证：无 8 元素 u1 字面量；
  `ensureWebSlot` 编译为 `stricteq null`）。
- 2026-10-05 “应用重启一次”= **计数伪影**：三轮 dump 唯一 start（11:15:34.314 pid 12497）；hilog1+2
  同窗重叠被累计；hilog3（至 11:20）同 pid 存活。本轮 R0 亦单 start、pid 59270 稳定 90 s。

## 实验矩阵（HAD-W32；cold start；90 s 采样；同一 probe8 托管件只换壳 abc）

| 轮 | 壳体 | 观测 |
|---|---|---|
| R0 | 既有 probe8（不完整补丁） | `slot create 2..7` 后仅 0–3 attach/serve；`rootWebArea=4`；JsCtor/attach/max_instance = 5/4/4；RSS 263,516 KB |
| R1 | 修正①组（8 槽数组+哨兵） | slot 2–7 全部 attach+replay+serve（8 nweb）；**+1.1 s `TypeError: Cannot read property url of undefined`**（`retireNavigationMarker`→②组越界；Index.ts:4052）→ RuntimeError 退出（`kill_id 2003`） |
| R1b/R2 | 修正①+②组 ×2 冷启 | 6 动态槽同 tick 创建，~130 ms 内全部 attach+replay+serve（hilog：`hybrid assets … slot=2..7`、`web serve (slot 7)`）；`rootWebArea=8`×2；JsCtor/attach/max_instance = 9/8/8；0 error；RSS 259,780/260,120 KB、线程 70/71 |

- **4→5 与 6→8**：修正壳无陡崖（4→8 连续成功，无新增 defer 残留）；断裂只在不完整补丁下、恰在首个
  “缺控制器”槽（=4）。最小对照：R1b/R2 两轮同构；R0 与 2026-10-05 轮跨日/镜像（7.0.0.109 vs .111）同构。

## 最小修复（本轮不实施，开单）

1. 两组 18 个逐槽表按 `WEB_SLOT_MAX` 派生（或构造器统一预填）＋哨兵改假值/越界防护（`=== null`→`!x`）；
2. 提升默认前：复用本装置复验 5–8 并发，并评估新增 4 个 render 进程的整机内存/长稳（本轮只取 app RSS）。
   风险：低（纯壳数组；默认 4 时行为不变）；中（8 并发资源/长稳未 soak）。共享面：`SUB_WINDOW_MAX` 无关。

## 恢复 / 纪律

- 设备恢复：重装原 `a11ysc/fix-hap.hap` 成功；hilog 缓冲回 512 K；本地锁释放；`/data/local/tmp` 清理。
- 未改 runtime/maui 切片与 #49–#53 资产；本文提交 runtime-ohos（commit-paths.sh，网络旁路）。
