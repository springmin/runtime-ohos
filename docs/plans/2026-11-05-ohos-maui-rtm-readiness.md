# MAUI RTM 就绪与 rebase 计划（2026-11-05）

> 状态：**等待 RTM 产物**。MAUI 没有 rc3；`dotnet/maui` 的 `main` / `release/11.0.1xx`
> 已是 RTM 取向（`MicrosoftNETSdkPackageVersion=11.0.100-rtm.26514.118`），但 NuGet
> 仍只有 rc2。kit #59 等 MAUI RTM + .NET RTM，rc3 `.31` 只做平台预演。

## 1. 当前事实

| 项 | 状态 |
|---|---|
| MAUI NuGet | 最新 `11.0.0-rc.2.26505.5`；无 rc3/stable |
| MAUI 源码 | `main` / `release/11.0.1xx` RTM 取向；`PlatformBehavior.OnLoaded` 仍无空检查 |
| .NET rc3 | SDK `11.0.100-rc.3.26522.148`；runtime/aspnet `11.0.0-rc.3.26522.148` |
| OpenHarmony workload | `.31` / manifest `11.0.100-rc.3`；rtc AOT/crossgen2/selfsign 已发布 |
| kit | #58 rc2 冻结；kit #59 等 RTM |
| 全局默认 | rc3（profile 已切）；`runtime-ohos` 仓库仍有 rc2 `global.json` pin |

## 2. RTM 观察

脚本：`ohos-workload/scripts/watch-maui-rtm.sh`

```sh
sh scripts/watch-maui-rtm.sh   # 0=WAIT, 10=READY, 1=所有源失败
```

当前输出：**WAIT**。必须同时满足：

- NuGet `Microsoft.Maui.Controls` stable `11.0.0`；
- .NET runtime `11.0.0` stable、SDK `11.0.100` stable；
- `springmin/runtime-ohos` / `springmin/sdk-ohos` RTM release；
- OpenHarmony workload `preview.32+`（或 stable）；
- AOT/crossgen2/selfsign RTM 资产（kit 前置，见 §5）。

## 3. MAUI rebase 计划（RTM 产物出现后执行）

1. **取上游 RTM**：`maui-ohos` fetch `dotnet/maui release/11.0.1xx`，新建
   `release/ohos-rtm`（不要动 `feature/openharmony`/kit #58）。
2. **迁移切片**：把 `src/Core/src/Platform/OpenHarmony/**` 与 4 个侵入文件
   （`Directory.Build.props`、`Core.csproj`、`MultiTargeting.targets`、workload manifest）
   合并到 RTM；确认 `OpenHarmonyHandlerConnector`、TouchBehavior 补丁状态。
3. **版本对齐**：
   - `maui-ohos/eng/Versions.props`：`MicrosoftNETSdkPackageVersion` /
     `MicrosoftNETCoreAppRefPackageVersion` / Extensions / ASP.NET → RTM；
     `PreReleaseVersionIteration` 置空（stable）；
   - `maui-ohos/global.json` → RTM SDK；
   - slice 的 `Microsoft.Maui.*` 引用、所有 `test/*/*.csproj`、`hello-*` 引用 → stable；
   - `ohos-workload` 的 `manifests`/`packs` 使用 RTM workload（`.32+`）。
4. **门禁更新**：
   - `test/p0-gate/upstream-delta.json` 基线改为 RTM 上游 commit，重新测量；
   - `.github/workflows/*` 的 `maui_ohos_ref` → RTM slice；SDK setup 显式 pin；
   - `p0-gate` IL 预算、`reference-thresholds.json`、`smoke.sh` 指标重测；
   - `rtm-pins.json` 更新为 RTM（MAUI stable / SDK stable / workload `.32+`）。
5. **验收**：见 §4。

## 4. RTM 兼容矩阵（执行时逐项填结果）

| 用例 | rc2 基线 | RTM 目标 | 门禁 |
|---|---|---|---|
| CommunityToolkit 15.0.1 | 5/5 | 5/5 | `p0-gate --quick` + 设备矩阵 |
| TouchBehavior | `CompatTouchBehavior` | 上游修复后去 shim；否则保留 | `smoke.sh`/T2 |
| Popup | View 重载 | 不回归 | T2 |
| AvatarView / DrawingView | Avatar 基础/Drawing handler | 不回归 | T2 |
| Reference App | 4/4 | 4/4 | T3 + `smoke.sh` |
| 第二 ability | `:login` | `:login` | `smoke.sh --login-hap` |
| 冷启/深链 | 1,012 ms / 全 ps=1 | 不回归 | `smoke.sh` |
| AOT | IL2026 2/0；3050/3051/2070=0 | 重测预算 | `p0-gate --full` |
| Blazor/razor/wasm | 通过 | 不回归 | 样例 publish/run |
| kit | #58 | #59 | `verify-kit.sh` + 设备 |

## 5. Kit #59 RTM 步骤

1. 等 §2 的 RTM set 齐全；不要用 rc3 `.31` 做 #59。
2. 使用 RTM workload（`.32+`）+ RTM AOT/crossgen2/selfsign；更新
   `sdk-ohos/eng/ohos-install/versions.env` 的 `AOT_PACKS_TAG`/`SELFSIGN_SHA256`/
   `WORKLOAD_BUNDLE_VERSION`。
3. 在干净 worktree 构建（`--ow-repo` 指向 RTM workload分支，不要用带未提交改动的 main）。
4. 本地 kit → `verify-kit.sh` → 设备 smoke → `cut-kit --kit 59` bundle/release。
5. 保留 kit #58 回滚；失败回退 runtime/SDK/MAUI pin 与 #58。

## 6. 上游 PlatformBehavior

- `main` / `release/11.0.1xx` 仍存在：
  `if (sender is TView view && view.Handler.PlatformView is ...)`。
- 上游已有同根因修复，**不再开重复 PR**：
  - issue **#39747**（open，`s/verified`）；
  - PR **#39838**（open，base `main`，含 Core.UnitTests + Android 设备测试）。
- 本地备份分支（未推送，仅回退用）：

```text
branch: fix/platformbehavior-handler-null
commit: e42dfc72fb9
patch:  /data/storage/el2/base/tmp/opencode/0001-fix-defer-PlatformBehavior-attach-until-the-handler-.patch
```

- #39838 当前 CI 有 Build Insights / `maui-pr-uitests` 失败（2026-11-05），尚未归因；
  合并前不改本地 shim。
- 合并后：移除 `CompatTouchBehavior`，重跑 T2/T3/smoke，并更新本文档。

## 7. 决策门

- **RTM set 未齐**：只维护观察/rebase 文档，不改 MAUI 包/kit。
- **RTM set 齐 + 上游修复可用**：按 §3/§4 执行；TouchBehavior 可去 shim。
- **RTM set 齐但上游修复不可用**：保留 `CompatTouchBehavior`，kit 仍可发。
- **任何一步失败**：回退到 rc2/kit #58，不发布 #59。
