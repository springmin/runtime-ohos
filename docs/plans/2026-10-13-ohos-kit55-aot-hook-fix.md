# KIT55-AOT-HOOK-FIX：AOT Exec 本地钩子滞后导致 labelId/iconId 流失（2026-10-13）

> 结论：kit #55 第一次 P1 构建（7 hap 全部产出）在最后的 tree-digest 步失败——包内 `verify-kit.sh` 2b 深度断言对 5 个 MAUI hap 报 `module.json 缺 app.labelId/app.iconId`。根因 = 本机 AOT 发布用的 Exec 变通钩子 `aot-local-hooks.targets`（`-p:CustomAfterMicrosoftCommonTargets`，经 cut-kit `OHOS_AOT_HOOKS` 注入）以旧版覆盖了包内 `_OpenHarmonyGenerateResourceIndex`：该副本停留在 kit #32 时代，**不含** LAUNCHER-IDENTITY（`8a48a91`）新增的「restool 解析版 module.json 写回 staged 件 + RestoolV2 断言」步骤，于是 AOT 线 5 个 MAUI hap 静默丢掉解析 id（桌面回退 bundle 名 + 空白图标）。JIT 线（PRE55 整备轮样例）不注入该钩子，故此前未暴露。**零发布副作用**：该构建未出 tar、未上传任何资产；#49–#54 资产未动。

## 1) 现象 / 定位

- P1 日志尾部：`WARN: could not compute the kit tree digest (verify-kit.sh rc=1)`；对 kit 目录跑 `verify-kit.sh` → `FAIL 5`（每件 MAUI hap `labelId=None iconId=None`），其余断言（abc 620,908、resources.index 2,102/RestoolV2、INTERNET、`myapp://callback`、AOT 形状）全过。
- 对照：包内 targets（四包 22/23/24/28；`fa21a1a` 树；sha `90e45a6c…`）的 `_OpenHarmonyGenerateResourceIndex` **有**解析写回（`_OpenHarmonyResourceIndexResolved` → `Copy` 到 staged `module.json`，缺失即 Error fail-closed）。
- 差异 = 钩子（`/data/storage/el2/base/tmp/opencode/aot-v3/aot-local-hooks.targets`）重定义了同名 target 且**整段旧**：只有 `LocalRun` restool + index 存在性断言，无 resolved 写回、无 RestoolV2 断言。`CustomAfterMicrosoftCommonTargets` 使其定义后于包内 target 生效（覆盖）。
- 背景：该钩子解决本机 rc.2 SDK 的 Exec 在非 Win 主机上写 Windows batch wrapper（`exit: bad number: %errorlevel%`）问题；三个 hap 打包步骤（restool / ohos_packing_tool / sign）走进程内 `LocalRun`。kit54/#54 各 AOT 轮一直用它，但到 LAUNCHER-IDENTITY 后副本滞后。

## 2) 修法

- 以包内当前 target 为基准重写钩子的 `_OpenHarmonyGenerateResourceIndex`（保留 `LocalRun` 替换 restool Exec；补 `_OpenHarmonyResourceIndexResolved` 属性、RestoolV2 头断言、resolved 缺失 fail-closed、`Copy` 写回 staged `module.json`、含 `RestoolV2`/resolved 文案的 Message）；`_OpenHarmonyPackHap`/`_OpenHarmonySignHap` 与包内等价（仅 Exec→LocalRun），不动。
- 备份 `aot-local-hooks.targets.kit55-bak`（旧件）；XML 解析校验；清 `test/hello-maui-app/{bin,obj}` 后重编（一次一构建；旧件未出 tar，无资产作废）。
- 复核判据 = 重编后 kit 目录 `verify-kit.sh` 0 FAIL/0 WARN（含 5 hap labelId/iconId >0）→ P2 严格门禁复验。

## 3) 教训 / 后续

- 本地钩子是「包内 targets 的镜像」，pack targets 每次演进都要同批同步；本次由 `verify-kit.sh` 2b（labelId 检查，LAUNCHER-IDENTITY 同批加入）兜住——门禁有效，但暴露点在最后而非打包中。
- 可选加固（后续轮）：在 kit 构建前对 `OHOS_AOT_HOOKS` 做「target 文本与包内 diff」防呆，或让 `_OpenHarmonyPackHap` 在缺 resolved 时 fail-closed（包内已有 Error，但被覆盖后不可见）——**本轮不做**，记入 #55 边界。
