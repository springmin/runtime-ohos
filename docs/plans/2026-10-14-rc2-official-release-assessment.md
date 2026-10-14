# rc.2 官方发布对位评估（2026-10-14）

> 触发：上游 rc.2 正式发布 → 检查能否推进到官方 rc.2 并重发布 OHOS 版。
> **结论：可以推进 ✓**；三仓源码基本已对位官方 rc.2，剩余 = **MAUI 官方换 pin ＋ 重切发布（换官方戳）**；
> 唯一非技术闸门 = kit/tester 窗口与资源。

## 1. 官方发布核验（✓）

| 源 | 证据 |
|---|---|
| dotnet/core | **".NET 11.0 RC 2"** 发布 `2026-10-13T22:34:41Z`；VMR tag `v11.0.0-rc.2.26504.105` |
| runtime / sdk / aspnetcore | tags `v11.0(.100).0-rc.2.26504.105`（分支均已冻结于 tag 目标）；NuGet `microsoft.netcore.app.ref` / `microsoft.aspnetcore.app.ref` = `11.0.0-rc.2.26504.105` ✓ |
| MAUI（nuget.org） | `11.0.0-rc.2.26505.5`（四包）→ **RC2-WATCH 触发（exit=10 ✗）**；GitHub release 页仍滞后（rc.1 ✗，不影响判据 ✗） |
| 版本戳解码 | 形如 `YY` + `M*50+D`：`26451`=2026-09-01 / `26504`=2026-10-04 / `26505`=2026-10-05（与 buildid `20260901.112`/`20261004.105` 一一对应 ✗） |

## 2. 源码对位（我方并入基线 vs 官方）

| 仓 | 我方基线 | 官方（分支头 = tag 目标） | 判定 |
|---|---|---|---|
| runtime | `d4a4e25c89f^2` = `474ed963`（2026-09-28 并入 ✗） | `474ed963` | **逐位一致** ✓✓（compare `identical / 0` ✗） |
| aspnetcore | `e10d030184^2` = `5b8345f01c`（2026-09-28 并入；= 分支头 ✗） | `4a708708`（tag 目标 ✗） | **一致且领先 1**：分支头比 tag 目标多 1 个 darc 依赖合并（#69474 ✗）→ 我方为超集 ✓ |
| sdk | 末次上游并入 = main `3b1d59fe`（2026-09-26 ✗） | rc2 分支 `b370d9f8`（2026-09-25 ✗） | **分叉**（merge-base 09-02 ✗；rc2 独有 158 / main 基线独有 372 ✗）→ **需 merge rehearsal 定量** ⚠️ |
| maui | 切片仍锁 dnceng daily `11.0.0-rc.2.26478.12`（`eng/Versions.props` + 切片 csproj ✗） | 官方 `11.0.0-rc.2.26505.5` | **待换 pin（§8 清单 ✗）** ⚠️ |

## 3. "推进并发布" = 重切发布（此前已列暂缓项 ✗）

- 现发布资产版本戳 = `…-rc.2.26451.112`（Sept 1 flight 戳 ✗；发布于 09-27~29 ✗，早于/邻近 RC2-MERGE 收口 ✗）；
  官方 = `…-rc.2.26504.105`（Oct 4 戳 ✗）。
- 重切批次：
  1. **换戳**：`DEFAULT_BUILDID=20261004.105`、`RT_VERSION`/`SDK_VERSION=…-rc.2.26504.105`（sdk
     `eng/ohos-install/versions.env` 单一来源 ✗）；
  2. **MAUI 官方换 pin（§8 ✗）**：maui-ohos → `26505.5`（1–2 文件 ✗）＋切片门禁；workload 三 workflow pin ＋
     删 dnceng feed（interaction/pixel ✗；blazor-recipe 复核 ✗）；门禁 5/5 ＋ 本地复跑 ✓；
  3. **重建链**：runtime redist → SDK → crossgen2/AOT packs（同 tag、资产替换 ✗）→ workload bundle（pack 版本随动 ✗）；
  4. **锚重测 ＋ 发布**：四锚协议——SDK/runtime/bundle 三锚将变（selfsign 复核 ✗）；发布 `-openharmony` 新线
     （`v11.0.0-rc.2.26504.105-openharmony` 等 ✗）＋ `-ohos` 镜像 ＋ kit 交接更新（`.112→.105` ✗）；
  5. **验证**：CI 冷/热 ＋ 设备 smoke（install/publish/run ✗）。
- **不必做**：runtime/aspnet 无需再并入 ✓；上游 PR 线（#132953 等 ✗）与本发布无关、不阻塞 ✓。

## 4. 闸门与风险 ⚠️

- **kit/tester 窗口**：§8 item 4「随下一版 kit 窗口出包」；bundle 移动需避开轮次（kit 卡/锚随动 ✗）。
- **sdk 分叉**：先跑 merge rehearsal（merge-tree + 内容面定量 ✗）再定合并范围；158 提交中含 cherry-pick/品牌重复 ✗。
- **版本串涟漪**：文档/观测脚本/交接卡中 `.112` 与 `26451` 字样批量更新 ✗。
- **资源**：CI（冷 ~45m 级 ✗）＋ 设备验证时间 ✗。
- rc.1 回滚线（`~/.dotnet` / preview.24 ✗）与影子分支保持不动 ✓。

## 5. 建议批次（待批准 ⏳）

| 批 | 内容 | 前置 |
|---|---|---|
| **批 1** | MAUI 官方换 pin（§8 全清单 ✗） | 与 maui-ohos/kit 协调提交排期（其线活跃 ✗） |
| **批 2** | sdk rc2 merge rehearsal（只读 ✓，定量内容差 ✗） | 无 |
| **批 3** | RC2-OFFICIAL 重切发布波（§3 全部 ✗） | 批 1/2 ＋ kit 窗口对齐 |

> 证据：本页核对均来自 GitHub compare/tags/releases API、NuGet flat-container、RC2-WATCH 脚本输出
> （`ohos-workload/scripts/rc2-official-watch.sh` exit=10 ✗）；取证轮次与原始输出见会话记录。

## 6. CI 覆盖面审（2026-10-14，应"4 仓推进"前置检查）

**现状（核实 ✓）**：

| 面 | 载体 | 范围 | MAUI |
|---|---|---|---|
| 三仓构建/发布 | sdk-ohos `ohos-full-build.yml` | 输入 `runtime_ref`/`aspnetcore_ref`/`sdk_ref`；上传 runtime-ohos / aspnetcore-ohos / sdk-ohos 三个 `-ohos` release ✗ | **不在**（设计边界 ✗） |
| 发布镜像 | sdk-ohos `ohos-release-mirror.yml` | 矩阵 = 同三仓（sdk 任务兼搬 `workload-*` 资产 ✗）→ `-openharmony` 线 ✗ | **不在** |
| MAUI 切片 | maui-ohos releases `ohos-slice-1.0.0/1.0.1` | **源码 drop**（branch＋tag＋tarball ✗；README 规程 ✗；**无 CI workflow** ⚠️） | 即本体 ✓ |
| workload | ohos-workload 脚本（`prepare-packs` / `publish-workload-release` ✗） | 本地/kit 驱动；`Microsoft.OpenHarmony.Maui.Graphics` 现 pin dnceng daily `26478.12` ⚠️ | 消费方 ✓ |

**判定**：

1. **sdk full-build 无需纳入 MAUI** ✓——其构建闭包 = .NET 三件套 ✗（stage1 runtime / stage3 aspnetcore ✗）；MAUI 不在闭包内 ✗，塞入会把流水线与 MAUI 节奏/包源耦合 ✗。rc2 波对它**只改 pin** ✓（`versions.env`：`DEFAULT_BUILDID=20261004.105`、`RT_VERSION`/`SDK_VERSION=…-rc.2.26504.105` ✗）。
2. **四仓发布的真实缺口 = MAUI 切片的新一轮发布** ⚠️：port session（maui-ohos `feature/openharmony` ✗）**已把切片切到官方 `26505.5`** ✓（切片 csproj 76–79 行与 docs 均已是官方版本 ✗）；session 收口后需切 `ohos-slice-1.0.2` ✗——目前**无 CI、靠 README 规程人工** ⚠️。
3. workload 侧：`Microsoft.OpenHarmony.Maui.Graphics` 的 daily pin 与 §8 的 dnceng feed step 需在 rc2 批次一并换官方 ✓。

**建议**：① 给 maui-ohos 加一个 **dispatch-only 最小切片 workflow**（构建切片 → tarball+sha256 → 建 release ✗；量小 ✓；README 规程保留为兜底 ✗）——随 session 收口后落地 ✓；② 或不加 CI、沿用人工（零改动 ✗）。**推荐 ①** ✓。

**执行顺序（4 仓推进 ✗）**：等 session 完成 → 切 `ohos-slice-1.0.2` ＋ `MAUI_OHOS_REF` 换新 ＋ 删 dnceng feed（§8 ✗）＋ MauiGraphics 换 `26505.5` → 门禁 5/5 → 三仓换戳重切（§3 ✗）→ bundle/锚/发布 ✓。

## 7. RC2-OFFICIAL 执行记录（三仓先行，2026-10-14）

> 用户决定：**MAUI 单独处理**（不加 CI、不进本批 ✗）；**三仓先行**：「sdk 并源码，开干」✓。

1. **sdk 源码并入** ✓：官方 `release/11.0.1xx-rc2`（tag 目标 `b370d9f850` ✗）并入 `feature/openharmony` →
   合并提交 **`ed2706c021`**（双亲 `cd5bee91dc` ＋ `b370d9f850` ✗）；**83 个冲突全部无 fork 自有提交**
   （逐文件核过 ✗）→ 一律**取官方侧** ✓；fork 路径（`eng/ohos-install`、`.github/workflows` ✗）**零变化** ✓；
   净变化 549 文件 / +15893−16862 ✗。runtime/aspnetcore 无需源码并入（已逐位对齐/超集 ✓）。
2. **换官方戳** ✓：提交 **`7d5636e485`**（`RT_VERSION=11.0.0-rc.2.26504.105`、`SDK_VERSION=11.0.100-rc.2.26504.105`、
   `DEFAULT_BUILDID=20261004.105` ✗；legacy rc.1 覆盖保留 ✓）→ 已推 origin `feature/openharmony` ✓。
3. **派发 full-build** ✓：run **`38502009121`**（`buildid=20261004.105` 显式（绕缓存 ✗）、三仓 ref 均 `feature/openharmony` ✗、
   `upload_release=true` ✗）——构建完成后自动上传三仓 `v…-ohos` 线 ✓。
4. **构建后待办** ⏳：三仓 `-ohos` 资产核验 → selfsign 重挂（如缺 ✗）→ 镜像至 `-openharmony` → 锚重测
   （`SDK_TARBALL_SHA256` / `RUNTIME_TARBALL_SHA256` 将变 ✗；selfsign 复核 ✓）→ 设备 smoke → 交接/记录更新 ✓。
5. **首跑失败与修复** ⚠️：run `38502009121`（29m36s ✗）在 runtime 阶段报 `NETSDK1112`（linux-musl-arm64 pack
   缺 ✗）——根因 = **musl alias 的 bootstrap 鸡生蛋** ✗：`seed_musl_runtime_pack_alias_from_release` 要取
   `v$RT_VERSION-ohos` 的 runtime pack 作别名基底，但 `.105` 尚未发布 → fail-closed 拒下 → 函数**早退** ✗、
   所有版本的别名播种被整段跳过 ✗。修复提交 **`6b43c08e92`** ✗：新增 `ALIAS_SOURCE_RUNTIME_VERSION`
   （versions.env ✗，= 最近已发布 `11.0.0-rc.2.26451.112` ✗）＋ 同版本不可得时**回落到它**（经 release
   `SHA256SUMS` 验证 ✓；alias 按目标版本重写 ✗——任意已发布 OHOS pack 均为合法基底 ✓）。
   → 重派 run `38505697606`（45m30s ✗）：**alias 修复生效** ✓（runtime 阶段全过：R2R 180/180 ✓、`.105`
   runtime tar 叠层 ✓；aspnet 过 ✓）——但 **sdk 阶段编译失败** ✗（10 个合并残留错误 ✗）。
6. **合并残留编译错修复** ⚠️：run `38505697606` 在 sdk 编译报 10 错 ✗，全部为"冲突取官方侧 ＋ main 线更新"
   混搭的残留 ✗：①同名 const 被自动合并成两份（`MSBuildLogger` ✗）；②测试方法双侧重复（CS0111 ✗，
   2 文件 3 方法 ✗）；③`RegistryTests` 调 `GetStreamAsync` 而官方 src 已改名 `GetUnvalidatedStreamAsync` ✗；
   ④`MicrosoftTestingPlatformTestCommand`（官方版早于 main 的 `CLI_AOT` 护栏 ✗）把 `MSBuildSession`（MSBuild
   API ✗）带进 AOT 编译集 ✗——**恢复 main 护栏版** ✓。修复提交 **`d709fe3270`** ✗（3 方法去重、2 调用改名、
   1 文件还原 ✓）→ **重派 run `38513763455`** ⏳（观察中 ✗）。
7. **编译残留修复（第二轮）** ⚠️：run `38513763455`（54m07s ✗）——**首轮三处修复生效** ✓（CS0102/CS1061/CS0246
   全消失 ✗），剩两类 ✗：①**MSTEST0074**（合并后的 MSTest 分析器 + `TreatWarningsAsErrors` 把"测试内改环境
   变量需 `[ResourceLock]`"判为错误 ✗）命中取官方版的 `TestCommandParserTests` / `SdkForwardingAppTests`
   （main 版才有标注 ✗）＋双方均漏标的 `NoCacheOptionParserTests` ✗；②首轮去重把
   `DoNotPassDisposables...` 的原始字符串截断（CS1519 ✗）。修复提交 **`4731e1fa7f`** ✗（前两者恢复 main 版 ✗、
   第三者补 `[ResourceLock(WellKnownResources.EnvironmentVariables)]` ✗、截断文件整体恢复 ✗）→ 推送时吸收
   kit 新提交（merge → `bc7a8997c6` ✗）→ **重派 run `38518894431`** ⏳（观察中 ✗）。
