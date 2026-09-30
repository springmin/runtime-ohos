# rc.2 五仓并入主线（RC2-MERGE 执行记录，2026-09-30）

> 用户批准的 RC2-MERGE：把五仓的 rc.2 影子并入主线 —— runtime / sdk / aspnetcore / maui-ohos → `feature/openharmony`，ohos-workload → `master`。禁强推；FF 或 merge commit；线性优先。
> 计划依据：[`2026-09-28-rc2-conflict-sharding-plan.md`](2026-09-28-rc2-conflict-sharding-plan.md)（runtime/sdk/aspnetcore）、[`2026-09-29-ohos-maui-rc2-alignment-plan.md`](2026-09-29-ohos-maui-rc2-alignment-plan.md) 与 [`2026-09-29-ohos-maui-rc2-shadow-results.md`](2026-09-29-ohos-maui-rc2-shadow-results.md)（MAUI/workload）。
> 执行 scratch：`/data/storage/el2/base/tmp/opencode/rc2-merge/`（worktree、preflight/门禁日志）。

## 1. 合并表

| 仓 | 影子（sha） | 并入方式 | 合并前 tip | 合并后 tip | 冲突 |
|---|---|---|---|---|---|
| runtime-ohos | `fix/ohos-rc2` `417ab220532` | merge commit | `1a88ad4f2b8` | `9b31ed2d08a` | 0（自 merge-base 两侧文件集不相交：feature 41 docs vs rc.2 301 文件） |
| aspnetcore-ohos | `fix/ohos-rc2` `e10d030184` | fast-forward | `07ed2fe38d` | `e10d030184` | 0 |
| sdk-ohos | `fix/rc2-pins` `e114268339` | 已在主线（祖先） | `06884ccb13` | `469eae2734` | 0（另加 rc.2 默认化同步提交） |
| maui-ohos | `fix/ohos-maui-rc2` `41ec990196` | merge commit（整树采纳） | `63d6fe7019` | `ebffdd787c` | 0（结果树 == 影子树；后补 CA 作用域，见 §2） |
| ohos-workload | `fix/ohos-rc2` `b531cc98` | cherry-pick（线性） | `64ed3b5` | `53058734ae` | 0 |

- 全部推送 origin 对应分支（无强推）；影子分支保留。
- `9b31ed2d08a` 的首父 = 原 `feature/openharmony` tip；`a00c30631a` 双亲 = `63d6fe7019` + `41ec990196`；maui 结果树 `HEAD^{tree} == 41ec990196^{tree}`（逐字节核验）。
- CoreLib 平台修复（`417ab220532`，`OperatingSystem.cs` 接受 `LINUX` 别名）随 runtime merge 入主线（对应本仓 §6 "C3/N 组一并对齐" 的收口）。

## 2. 冲突与解决

- **runtime**：merge 前 `git diff` 两侧文件集交集为空 → 干净 merge；`--diff-filter=U=0`、`git diff --check` 干净。
- **aspnetcore**：feature tip 是影子首父 → FF（4 个版本/Darc 文件取 rc.2）。
- **sdk**：`fix/rc2-pins` 0 缺失提交（已含于 feature，含 host pack 摘要锚与设备 selfsign 锚）；本波只加"rc.2 默认化"同步提交 —— rc.2 成为主线后 workflow 的 `*rc2*` 分支名启发式不再匹配 `feature/openharmony`，默认 dispatch/本地构建会落回 `DEFAULT_BUILDID=20260901.109`，与 `versions.env`（`RT_VERSION`/`SDK_VERSION` = `.112`）不一致；改为默认 `.112`（legacy rc.1 以显式 buildid 保留）。
- **maui**：影子为「rc2 全树 + 138 文件 delta」，与切片载体主线不能常规 3-way（1,672 项 modify/delete 噪声）→ **整树采纳式 merge**（双亲记录 + 结果树取影子）；影子内的 3 个真冲突已按 shadow-results 文档在影子解决（`Directory.Build.props` 手解 1 块；`Core.csproj`/`WorkloadManifest.in.json` 自动合净）。
- **ohos-workload**：cherry-pick 干净（master 侧 docs 与 pin 提交文件不相交）→ 线性；pin 刷新随后。
- **CI 发现并修复的两处跨仓集成缺口**（影子的本地门禁未覆盖）：
  1. rc.2 树的 `src/Core/src/.editorconfig` 把性能 CA 规则提升为 error，覆盖 slice 源码 → 后并入首轮的 interaction slice gate（`maui-ohos/.../Microsoft.Maui.Platform.OpenHarmony.csproj`）与 pixel suite（编译同一批 .cs）报 50+ CA error。修复 = maui `ebffdd787c`：切片目录级 `.editorconfig` 把该组 CA 规则降为 suggestion（IL2026/IL3050 提升与三套件门禁不变）。
  2. `Microsoft.Maui.* 11.0.0-rc.2.26478.12` 为 dnceng daily、未上 nuget.org → interaction/pixel restore `NU1102`。修复 = workload `004b7f8`：两个 workflow 在 restore 前加 dnceng `dotnet11` feed（官方 rc.2 包发布后移除）。

## 3. 门禁（按仓可行面）

| 仓 | 门禁 | 结果 |
|---|---|---|
| maui（pin = `ebffdd787c`） | 切片 0 error / 0 IL；交互 ≥513/floor 493；像素；导出 145 | **CI 全绿**（run 36656123464 / 36656123473 / 36656123543）：slice gate `0 Error(s)` + `71 Warning(s)` + `no IL warnings`；交互 `[suite] checks=513 total=513 floor=493 assert=True`；`PIXEL ASSERTIONS PASSED`；`OK: all 145 expected exports`。本地同树复跑亦绿（513/493、PIXEL、145/145） |
| ohos-workload | preflight/selftests（RID 图 / pack / 任务 / hygiene，含 pin 一致性） | `selftest-ridgraph` **20/20**（byte-level，sibling sdk）、`selftest-packs` 25、`selftest-hap-targets` 49、`selftest-repo-hygiene` 25、`sh -n` 39/39、markdownlint 转绿；CI ridgraph-sync ✓。**`selftest-tasks` S3 红（预先存在）**：新 SDK 构建的 task 程序集与提交的 pack 副本字节不同；`64ed3b5→5305873` 对该路径 0 diff，与本次并入无关，脚本提示需重跑 `prepare-packs.sh`（建议随 kit 窗口） |
| runtime / aspnetcore | rc.2 全链（构建 / 发布 / 设备） | 引用已执行证据：冷 run **36455830206**（43m18s 全绿）、热 **36461099649**（11m1s）、发布 **36504623184**（双仓 `v11.0.0-rc.2.26451.112-ohos`）、平台修复 run **36552629066**（57m33s 全绿，构建 SHA = `417ab220532`） |
| sdk | rc.2 默认化 + 锚一致性 | `bash -n`/YAML 校验 + `versions.env` 解析（`DEFAULT_BUILDID=20260901.112`）；锚（SDK/runtime/selfsign/bundle）与 rc.2 发布实测一致（§9 ④/⑤ 已记）；全链构建证据同上 |

## 4. pin / 环境刷新

- ohos-workload：`interaction` / `pixel` / `host-export` 的 `MAUI_OHOS_REF` → `ebffdd787c`；`ridgraph-sync` 的 `SDK_OHOS_REF` → `469eae2734`；`docs/rc2-line-notes.md` 平台修复引用 → runtime merge `9b31ed2d08a`（并记主线并入轮）。
- sdk：`DEFAULT_BUILDID` → `20260901.112`；`BUILD-GUIDE` 两个示例与 workflow 注释同步；legacy rc.1 以显式 buildid/版本覆盖保留。
- 未改：`versions.env` 发布锚（`SDK_TARBALL_SHA256`/`RUNTIME_TARBALL_SHA256`/`SELFSIGN_SHA256`/`WORKLOAD_BUNDLE_SHA256`）、AOT rc.2 pin（`aot-packs-11.0.0-rc.2`）、`REFERENCE_RUNTIME_PACK_*`（rc.1 基线）。

## 5. 本机部署（rc.2 负载，workload preview.28）

采用"`~/.dotnet.rc2-fix` + feed"方式（安装到默认根会覆盖 rc.1 回滚线且 OHOS 不可覆盖已签名文件）：

- `dotnet --info`：SDK `11.0.100-rc.2.26451.112`、host `11.0.0-rc.2.26451.112`、`RID=openharmony-arm64`、`OS Platform: Linux`（平台修复生效）。
- `dotnet workload list`：`openharmony 1.0.0-preview.28/11.0.100-rc.2`；AOT packs 为 rc.2 线（`fetch-nativeaot-packs.sh`）。
- 发布版安装 `~/.dotnet.rc2-112` 同为 rc.2/.28；默认根 `~/.dotnet` 保留 rc.1 回退线（有意，未动）。
- 本轮本地门禁即用该根执行（§3）。

## 6. CI 记录（ohos-workload，push 触发）

| 轮 | commit | runs | 结果 |
|---|---|---|---|
| 1 | `d23b915` | 36655197580 interaction / 36655197455 pixel | 红：`NU1102`（daily 包缺 feed） |
| 2 | `004b7f8` | 36655494161 / 36655494086 | 红：CA error（rc.2 `.editorconfig` 作用域） |
| 3 | `5305873` | 36656123464 / 36656123473 / 36656123543（+ ridgraph 36656123466 / markdownlint 36656123486） | **5/5 全绿** |

## 7. 遗留与不确定项

1. maui `11.0.0-rc.2.26478.12` 为 dnceng daily；官方 rc.2 上 nuget.org 后替换 pin 并移除 dnceng feed step（kit #34 前）。
2. `selftest-tasks` S3（预先存在）：task 程序集需按新 SDK 重锚（重跑 `prepare-packs.sh`），建议随 kit 窗口；本次并入对该路径 0 diff。
3. `documentation/ohos-install/NATIVE-AOT.md` 仍描述 rc.1 AOT 镜像（`versions.env` 已 pin `aot-packs-11.0.0-rc.2`）——既有文档漂移，另单。
4. sdk legacy rc.1 构建路径（显式 buildid）未实测；默认路径（rc.2）由已发布全链证据覆盖。
5. runtime/sdk/aspnetcore 本波未在设备旁本地重跑构建（内存纪律），以已执行的 CI/发布/设备证据为准。
