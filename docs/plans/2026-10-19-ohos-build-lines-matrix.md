# 构建线矩阵（五仓）＋ main 对齐（2026-10-19）

## 1. 构建线矩阵（kit 线 vs 上游 main 线）

| 仓 | 上游 main | 我方 main（已对齐） | kit / 11.0 线 | 说明 |
|---|---|---|---|---|
| `runtime-ohos` | dotnet/runtime main = **12.0.0-alpha.1**（2026-09-09 翻 12，`dfcb726e234`） | `91b63bf8825` | **`fix/ohos-rc2` = 11.0.0 rc2** | `feature/openharmony` 跟 main＝**12-alpha**（上游 PR 准备线）；**kit 构建用 `fix/ohos-rc2`** |
| `sdk-ohos` | dotnet/sdk main = **12.0.1xx-alpha** | `c70b3856e7` | `feature/openharmony` = **11.0.1xx rtm**（同步自 `release/11.0.1xx`） | 11.0 发布支＝`release/11.0.1xx` |
| `aspnetcore-ohos` | dotnet/aspnetcore main = **12.0.0-alpha.1** | `c09e2b89bd` | `feature/openharmony` = **11.0 rtm**（同步自 `release/11.0`） | 11.0 发布支＝`release/11.0` |
| `maui-ohos` | dotnet/maui main = **10.0.0（ci.main）** | `3a7d72870b` | `feature/openharmony` = **11.0.0 rc.2**（同步自 `release/11.0.1xx-rc2`） | maui 的 11.0 是发布支线；其 main 仍是 10.0 |
| `ohos-workload` | （自家仓，无上游） | `master` `83ee7d0` | `master` | 不适用 |

**关键口径**：kit #58＝**11.0 rc.2 线** → sdk/aspnetcore/maui 用各自 `feature/openharmony`（11.0 线）；
**runtime 用 `fix/ohos-rc2`（11.0.0 rc2）**，**不要用 `feature/openharmony`（12-alpha）构建 kit**。
上游 PR 线仍以 runtime `feature/openharmony` 为准（跟 main）。

## 2. 2026-10-19 main 对齐记录

- **runtime / sdk / aspnetcore**：`origin/main` 纯落后（0 ahead）→ FF 推送至上游 main ✓
  （`91b63bf8825` / `c70b3856e7` / `c09e2b89bd`）；
- **maui**：`origin/main` 有 2 个 fork 独有 docs 提交（`7de682ea176` / `c1a11aae330`）→
  先备份到 **`backup/main-presync`**（已推 ✓），再 `--force-with-lease` 对齐到上游 `3a7d72870b` ✓；
- 本地 `main` 同步更新 ✓；四仓 **origin/main == upstream/main** ✓。

## 3. 后续

- **12.0 迁移＝产品决策**（未做；等 11.0 发版后评估，MAUI 需等其 12 线出现）；
- kit 构建/复现按上表选支；**下次 kit 构建需验证 sdk 的 RTM pin**。

## 4. 构建环境约束（2026-10-19 实测）

- **hmmac 禁止执行/映射"新创建"文件**：把 `/system/bin/sh` 拷到 `/storage` 或 `/data` 后执行均为
  `Permission denied`；而**同权限位、同属主**的既有 `~/.dotnet.rc2-105/dotnet` 正常执行 →
  不是 mode/owner 问题，而是**新建文件无执行权**。
- 推论：**不能引导新 SDK**（`build.sh` 装出的 `.dotnet/dotnet` 与 `libhostfxr.so` 均为 `EACCES`）；
  构建必须使用**既有 SDK root**（`~/.dotnet.rc2-105`、`~/.dotnet.rc2-112` 等）。
- `dotnet build` 在本环境曾于 `dotnet-aot` 工程上**病态自旋**（>1 天 CPU、0 字节输出、
  `timeout 7200` 未终止），已 `kill -9`；**不再尝试从源码整构建 dotnet/sdk**——
  kit 流程本就用官方 SDK＋仓内脚本。
- **MSBuild 多进程节点不可用**：`NodeLauncher.StartInternal` 抛 `PlatformNotSupportedException`
  （`MSB0001: Cannot acquire required number of nodes`）→ 必须 `-m:1` 单节点。
- 即使 `-m:1`，`dotnet msbuild -t:Restore` 在 aspnetcore 工程上仍会**病态自旋**（CPU 2h+、0 输出），
  已 `kill -9`；**设备上不做整仓构建/还原验证**。

## 5. 三仓同步验证（2026-10-19/20）

- **sdk**：改用仓内 OHOS 回归套件（CI `ohos-install-tests` 同款）——
  `test-installer-verification` 43 ✗、`test-sdk-arch-check` 21 ✗、
  `test-fetch-aot-packs-resolution` 17 ✗、`test-hostfeed-verification` 10 ✗、
  `test-codesign-filewrites` 5 ✗、`test-packsplit-equivalence` 6 CASE ✗（需 bash ✗）：
  **96 PASS ＋ 6 CASE OK，0 FAIL** ✓。
- **aspnetcore**：`dotnet msbuild src/Http/.../Microsoft.AspNetCore.Http.Abstractions.csproj -t:Restore -m:1`
  （既有 SDK ✗）→ **病态自旋**（CPU 2h+ ✗、0 输出 ✗）→ 已 kill ✗；**设备上不可行** ⚠️。
  同步内容为发布支的**版本/config** ✗（上游 CI 覆盖 ✓）。
- **maui**：`dotnet msbuild src/Core/src/Core.csproj -t:Restore -m:1` → **NETSDK1139** ✗
  （`ios` TFM 未被当前 SDK 识别 ✗——设备 SDK 无 iOS workload ✗）；**非同步问题** ✓；
  同步内容为上游发布支提交 ✓（上游 CI 覆盖 ✓），本地不做整构建 ✓。
- **结论** ✓：设备侧验证以 **sdk 仓内套件**为准 ✓；aspnetcore/maui 受环境限制 ⚠️，不做整构建/还原 ✗。
