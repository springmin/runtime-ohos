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
