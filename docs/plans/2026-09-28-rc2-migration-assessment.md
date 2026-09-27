# rc2 迁移评估（runtime / aspnetcore）

**日期：** 2026-09-28
**目的：** 评估把 runtime/aspnetcore 从 rc.1 线迁到 rc.2 线（SDK 已是 rc.2）的成本、改动面与风险。

## 1. 上游 rc2 分支现状

| 仓 | rc2 分支 | 版本标签 | 与 fork 的 merge dry-run 冲突 |
|---|---|---|---|
| runtime-ohos | `release/11.0-rc2`（tip 2026-09-22） | rc, iteration **2** | **52 个文件**（libraries 22 / eng-pipelines 18 / coreclr 4 / tests、tasks、native 各 1 / 版本与 RID 图文件） |
| aspnetcore-ohos | `release/11.0-rc2` | rc, iteration **2** | **仅 4 个文件**：`.config/dotnet-tools.json`、`eng/Version.Details.xml`、`eng/Version.Details.props`、`global.json` |
| sdk-ohos | 无需处理（主线即 rc.2 线） | rc, iteration 2 | — |

- 冲突性质（runtime）：release 线回移修复 vs 主线演进（Number.*、Bcl.Cryptography、ILCompiler.ReadyToRun、eng-pipelines 等），需逐文件语义解决
- rc2 修复不在 main 11 段尾：rc2 分支点 `86f11fbddc7`（08-16），修复以独立 SHA 回移

## 2. 迁移改动面（sdk-ohos 的 pin 组）

| 变量 | 用途 | 迁移要求 |
|---|---|---|
| `RT_VERSION` | runtime+aspnetcore 产品版本 | `11.0.0-rc.1.26451.109` → rc.2 版本串 |
| 脚本默认 `LABEL`/`PRE`（rc/1） | 版本渲染 | `PRE` 1 → 2 |
| `SDK_VERSION` | SDK redist | 已是 `11.0.100-rc.2.*`（buildid 可能更新） |
| `BOOTSTRAP_SDK_VERSION` / `BOOTSTRAP_RUNTIME_VERSION` | 引导 SDK | 换 rc.2 对应 build |
| `RIDGRAPH_SDK_VERSION` | RID 图引导 | 核对 rc.2 可用性 |
| `STOCK_CROSSGEN2_VERSION` / `CI_STOCK_CROSSGEN2_VERSION` | R2R 工具 | 换 rc.2 版 + 新增 sha 表项 |
| `REFERENCE_RUNTIME_PACK_VERSION` / `_ASSET` / `_SHA256` | R2R-PGO 参考包 | 需 fork 侧重发（runtime-ohos release） |
| `HOST_PACK_DNCENG_*` / `HOST_PACK_BRANCH_VERSION` / `HOST_PACK_GITHUB_VERSIONS` | 主机包 | 需 rc.2 主机包（dnceng + fork release） |
| `AOT_PACKS_TAG` / `aot_pack_sha256()` | NativeAOT 离线包 | 需 rc.2 重打包 + 新 sha |
| `SDK/RUNTIME_TARBALL_SHA256`、`SELFSIGN_SHA256`、`WORKLOAD_BUNDLE_SHA256` | 发布锚点 | 全部重取 |
| ohos-workload `Microsoft.OpenHarmony.*` | 平台包 | manifest 引用的 `Microsoft.NETCore.App.Runtime.openharmony-arm64` 需指向 rc.2 runtime pack → **bundle 重打** |

## 3. 工作量与风险

- aspnetcore：低（4 个版本/Darc 文件冲突，半天内）
- runtime：52 个冲突文件，语义解冲突 + CI 验证（1–3 天）
- pin 组与发布链：重发 runtime packs（R2R-PGO 参考包、host pack、AOT pack）、重刷锚点、workload bundle 重打（1–2 天 + 多轮 CI）
- 风险：切换期间三仓制品短暂不一致；workload 用户需换新 bundle

## 4. 建议

1. **只需要个别 rc2 修复** → cherry-pick，避免整线迁移
2. **目标是"三仓统一 rc.2 产品线"** → 按 aspnetcore → runtime → pin 组 → workload 顺序，独立立项
3. 迁移前先做 **CI 阶段缓存**（每轮 ~50 分钟 → ~15 分钟），否则多轮验证成本高
4. 上文冲突清单（2026-09-28 dry-run）可直接作为解冲突工作清单
