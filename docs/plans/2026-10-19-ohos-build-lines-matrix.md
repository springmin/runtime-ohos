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
