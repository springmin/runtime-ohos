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

## 5. 并行评估补充（2026-09-28 重测，含对 PR 线的影响）

**结论：可以并行**（影子分支 + ref 派发 CI），且**与上游 PR 线文件级零重叠**；主要成本是 CI 冷启动与操作注意力。

### 5.1 重测数据（feature `e19147890d2` vs `upstream/release/11.0-rc2`）

真实 merge dry-run（scratch worktree，已 abort/清理）得出 **67 个冲突文件**（§1 的 52 为更早 tip 的测量，已被本次取代）：

| 分类 | 数量 | 分类 | 数量 |
|---|---|---|---|
| `src/libraries` | 32 | `src/tests` | 3 |
| `eng/pipelines` | 19 | `src/tasks` / `src/native`(`minipal/thread.c`) / `src/installer` / `eng/common` | 各 1 |
| `src/coreclr` | 5 | `.config/dotnet-tools.json` / `eng/Version.Details.{xml,props}` / `global.json` | 各 1 |

- 后 4 个版本类文件与 aspnetcore 侧冲突清单**完全同款** → 机械处理（取 rc2 版本 + 重应用 fork pin）
- 方法：`git worktree add --detach <scratch> feature/openharmony` → `git merge --no-commit --no-ff upstream/release/11.0-rc2` → `git diff --name-only --diff-filter=U`（67）→ `git merge --abort`

### 5.2 与 `pr/*` 的关系（对 PR 的影响）

**20 支 `pr/ohos-*` 的文件集与 67 个冲突文件的交集 = 0**（逐支计算：`merge-base upstream/main <branch>` → `git diff --name-only base..branch` → 交集）。原因：`pr/*` 锚定 upstream/main，其 delta 落在 `eng/build.sh`、`eng/native/*`、`coreclr/pal`、`native/corehost`、libraries TFM 等；rc2 冲突面集中在 release 线的 pipelines/版本文件与 libraries 回移——两套文件不相交。

推论：

| PR/资产 | 迁移的直接影响 | 迁移后要做的事 |
|---|---|---|
| `#132827`（open，hold） | 无（3 文件，零重叠） | 无 |
| `#132953`（open） | 无（11 文件，零重叠） | 无；按既定 playbook：合并后同步 `eng/common` 再落 N 组 |
| N1–N16 + C2/C3（17 支） | 无 | **无需重演**（09-28 演练 39/39 CLEAN 继续有效）；开 PR 前照常 rebase 到 post-infra main |
| item 5 新上游 PR（AOT 日志） | 无（corehost 文件不在冲突清单） | 无 |
| fork 线自身 / workload bundle | 迁移本体（§2 的 pin 组 + 重打 bundle） | 见 §5.3 |
| **唯一共享资源：CI** | `runtime_ref` 每次变化 ⇒ rt 级必冷启动 ~58 min（缓存键设计使然） | 批量解完冲突再派轮；避免与 PR 落地验证同时派发 |

### 5.3 并行推进方式（已在本仓验证可行）

```sh
# workflow 内容取 --ref 的版本；构建源码取 *_ref；不动 release/锚点
gh workflow run ohos-full-build.yml --repo springmin/sdk-ohos --ref feature/openharmony \
  -f runtime_ref=<迁移分支> -f aspnetcore_ref=<迁移分支> -f sdk_ref=feature/openharmony \
  -f rid=openharmony-arm64 -f upload_release=false
```

顺序沿用 §4 建议：aspnetcore（半天）→ runtime 67 冲突（1–3 天，可按目录分片：libraries 32 最大）→ pin 组重发 → workload bundle 重打 → 设备 smoke → 替换 `feature/openharmony`。

**窗口注意**：kit #31（含 Blazor/ArkWeb 组件）正在基于 rc.1 线打包，建议 kit 先出，rc2 迁移排其后；否则 kit 需随迁移重打 bundle。

### 5.4 风险（不变）

67 冲突的语义解决（libraries 最重）+ 版本 pin 组 + 三仓制品短暂不一致；迁移期间 `feature/openharmony` 保持不动，直到一轮 ref 派发全绿 + 设备 smoke 通过。
