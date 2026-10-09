# HARMONY-FLAVOR-FIX：第 6 workflow 红——freeWindowMode* 对 HarmonyOS 6.0.1 SDK 不可见（2026-10-09）

> 症状：`harmony-flavor` 自 2026-10-05 起红（旧 run `37299622898`；本轮 run `37902106120`）：编译
> HarmonyOS SDK 时报 5 个 ArkTS 错（`isInFreeWindowMode` 不存在；`freeWindowModeChange` 无 on/off
> 重载）。非 5 门禁之一；设备不需要；#49–#53 资产不动。

## 1) 根因

- 壳 `packs/…/templates/ets/pages/Index.ets` 的 `subscribeWindowShapeChange()`（MULTIWINDOW-S `c5df1de`）
  直接调用 `win.isInFreeWindowMode()` 与 `win.on/off('freeWindowModeChange')`。
- 该组成员在 SDK 声明中为 **@since 22**（本地 OH SDK 26.0.0.18 有）；harmony flavor 以 DevEco CLT
  6.0.1.251 / HarmonyOS 6.0.1(21) 编译，其 d.ts 没有这些成员 → 10505001（2 读 + on + off = 5 错）。
  默认 OH flavor 走 OH SDK 26，故一直绿——纯编译期 API 版本门差异。

## 2) 修法（最小，四包同步）

- 新增结构视图 `FreeWindowProbe`（3 可选成员），取用 `win as ESObject as FreeWindowProbe`（直接改型
  两 SDK 无成员可重叠；同文件 `(kit as ESObject)` KIT-IMPL 先例）。
- `readFree()` 以 `typeof === 'function'` 逐成员探测；`on/off` 仅在探测到成员时调用、失败只 warn；
  free 注册移入内层 try，`windowSizeChange` 观察器与 disposer 记账不受影响。
- OH-26 运行时行为不变（同调用、同日志）；无该 API 的运行时只丢 `free=?` 值与 free 变更行。
- `.22/.23/.24/.28` 四包同步；`--check-sources` 过（sources `40958b85…`）。

## 3) 验证

- 本地 OH SDK 26.0.0.18 默认 ui：CompileArkTS 过（11 s）→ abc **553,520 B / `0e98e5be…`**（基线
  `ab43ba2` 552,876 / `94f4e1f3…`，**+644 B**）；headless 不动（24,324 / `798b2477…`）。
- 缺失仿真：影子 SDK 剪 freeWindow d.ts（`TYPECHECK=1`）仍绿——OH-26 工具链不跑该强检查；未重下
  ~2 GB 真 SDK，以 workflow 为准。
- workflow：`fix/harmony-flavor` dispatch run `37945657194` **success**（CompileArkTS 8.6 s；harmony ui
  abc **641,504 / `eac28683…`**、0 ArkTS 错、MapOverlay record + 全 literals 过、gate=pass）。
- ow 分支 `fix/harmony-flavor` `ee6e754`（基 `ab43ba2`；普通推送、HTTP/1.1 直连旁路）。

## 4) 余项

- MERGE-BATCH-2：合入后一次重编 + `--install-packs`(.22/.23/.24)+.28、abc/EXPECT 重锚 **553,520**
  （headless 24,324 不变）；本分支不动四包 abc/abc-provenance（`selftest-build-arkts-shell` T16×3
  红 = packs source drift，随该次重编清零）。
- HarmonyOS 6.0.1 真机无 `free=?` 值属预期降级；本轮无真机（不需要）。
