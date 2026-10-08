# CUT-KIT-AUTOMATION：kit 切包流程脚本化 + 包内 tester docs 预检（2026-10-08）

> 状态：**已实现 + 自测 52/52 + P0–P3 实弹冒烟；未真实发布**（P4+ 未动，无上传/clobber，#49–#53 release 资产未动）。
> 载体：ohos-workload `tooling/cut-kit`（`5baf2be`）已并入 master `86fb3d4`；本轮补全在 `tooling/cut-kit-2`（`9253e76` + `3773c64`，从 master `ca94b55`；未并 master、未强推、普通推送）。
> 入口：`ohos-workload/scripts/cut-kit.sh`；docs 机械升级 `scripts/bump-tester-docs.sh`；自测 `scripts/selftest-cut-kit.sh`（52/52，已接入 `preflight.sh` step 1）。

## 1) 阶段与安全门

| 阶段 | 内容 | 干跑 | 执行 |
| --- | --- | --- | --- |
| P0 预检 | pin（worktree/三 workflow `MAUI_OHOS_REF`）+ 四包 abc + verify-kit `EXPECT_ABC` + 套件/宿主导出计数 + 工作树净 + selftest + docs 预检 | 真跑（只读） | 写 `state.env` |
| P1 构建 | 三 worktree 落 pin（git-ignored `dist/ets` + `.arkts-build` 从主检出物化）+ hosting/Graphics Release prep + `make-device-test-kit --runtime-mode aot --with-blazor`（7 hap，不 `--publish`） | 打印命令 | `--execute`；docs 门 fail-closed；一次一构建（`--force-build` 覆盖） |
| P2 严格校验 | 包内 `verify-kit.sh --expected-abc <EXPECT> --tree-digest`：rc=0 且 0 FAIL/0 WARN + sidecar + tree 锚入 state | 打印命令 | `--execute` |
| P3 bundle/锚 | prepare-packs → pack-local-workload → pack-workload-bundle → release-checksums；sdk-ohos `WORKLOAD_BUNDLE_SHA256` 改锚 + 3 个 installer 测试 + commit/push | 打印命令 | `--execute`（`--no-push` 演练） |
| P4 发布（F4） | 打印将 clobber 的资产清单 → 键入 `clobber kit <N>` 确认 → `--upload-hook` 上传 → by-id 摘要复核 + 各 release 零改动清单 → 4 个 release body 补 `## Integrity (kit #N)` | 打印计划 | `--execute --i-know` |
| P5 VALUES/预签 | `RELEASE-VALUES`/`release-values.env` + presign/manifest 钩子（`--presign-hook`/`--manifest-hook`） | 打印 | `--execute --i-know` |
| P6 CI 复核 | ow 5 workflow + sdk anchor run（API 只读） | 打印查询 | `--execute --i-know` |

- 断点续跑：默认 P0→P6，`<scratch>/state.env` 记录各阶段 rc/时间戳 + kit/bundle sha、tree digest、sdk anchor；rc=0 已完成阶段自动跳过（`--force` 重跑）。
- 安全默认：`--dry-run` 为默认，仅 `--execute` 写；P4–P6 另需 `--i-know`；`--yes` 跳过键入确认仅供演练。
- 单阶段：`--phase P0,P1` 或 `--phase P4`；未知阶段/用法错误 rc=2，安全门拒绝 rc=3，缺前置件 rc=4。

## 2) docs 预检 + 机械升级（#52/#53 痛点闭环）

- 契约：18 份 tester docs（#50/#51/#52 波次同表）必须含目标 kit 的块头 `kit #N，当前）` / `kit #N — current)`，且每份含当前壳 abc（`542936`/`542,936`）；`docs/plans/README.md` 必须含 `kit #N 日期口径`。8 份入包文档（对应 `make-device-test-kit.sh` 的 copy_doc 映射）一并做存在性校验。
- 失败 fail-closed：P0 rc=3；P1 先复检再构建，拒绝时给 `--bump-docs` 提示。
- `scripts/bump-tester-docs.sh`（本轮入库，`--bump-docs` 实际调用）：
  `sh scripts/bump-tester-docs.sh --kit <N> [--abc <A[,B]>] [--docs-dir <dir>] [--dry-run]`
  - 按 P0 块头规则把 18 份 docs 的 `kit #N-1，当前）`/`#N-1 — current)` 与 README 顶层 `kit #N 日期口径` 机械升到 #N；abc 取 `--abc`（缺省 = `verify-kit.sh` 的 `EXPECT_ABC`），逐档检查存在（plain/千分组任一）。
  - 幂等（二次运行报 `already at kit #N`、零写）；写默认开启、`--dry-run` 只打印计划；缺档/块头歧义/降级/缺 abc 任一即拒绝且**零文件写入**（事务化；apply 失败从备份回滚）。
  - 只保证门契约（块头 + abc + 索引口径）；块内正文仍由切包轮撰写。
- 误报治理：只认“块头”标记（`，当前）`/`— current)` 收尾），历史行如 `**kit #45（当前）**` 不误伤。

## 3) 用法示例

```sh
sh scripts/bump-tester-docs.sh --kit 54 --dry-run                 # docs 升级计划（零写）
sh scripts/cut-kit.sh --kit 54                                   # 全阶段干跑（P0 真检，P1..P6 打印计划）
sh scripts/cut-kit.sh --kit 54 --phase P0 --execute              # 预检 + 落 state.env
sh scripts/cut-kit.sh --kit 54 --phase P0 --execute --bump-docs  # 先机械升级 docs 再过 docs 门
sh scripts/cut-kit.sh --kit 54 --phase P0,P1,P2 --execute        # 续跑：构建 + 严格校验
sh scripts/cut-kit.sh --kit 54 --phase P1,P2,P3 --execute --force --force-build   # 重构建（换 hook/输入后）
sh scripts/cut-kit.sh --kit 54 --phase P3 --execute --sdk-repo <dir> --no-push    # bundle；锚演练不推
sh scripts/cut-kit.sh --kit 54 --phase P4 --dry-run              # F4 clobber 计划
sh scripts/cut-kit.sh --kit 54 --phase P4 --execute --i-know --upload-hook <scratch-curl.sh>
```

## 4) 自测 + P0–P3 实弹冒烟（2026-10-08，本机）

- 自测：`sh scripts/selftest-cut-kit.sh` **52/52**（原 38 + T6：dry-run 零写 / 98→99 zh+en 块头与 README / 幂等字节不变 / 缺档拒绝 + 零部分写入）；`sh -n` 全绿。
- 真仓 docs 链（kit #54）：`bump-tester-docs.sh --kit 54 --dry-run` 列 18+1 项、19 文件零变化；P0 无 `--bump-docs` 实测 **rc=3**（19 条 issue + 3 条 hint，156 s，state 保留断点）；`--bump-docs` 实测 19 文件升 `#54`（只动块头/索引 + abc 检查，未切包）后 docs 门 PASS（演练后已 revert，见冒烟报告 checksums）。
- 冒烟（scratch `smoke-cut-kit/`，pins ow `ca94b55bc9` / maui `b914379269` / runtime `d2b720d406`；**未发布、未 P4/P5/P6**）：

| 阶段 | 结果 | 耗时 | 指纹/证据 |
| --- | --- | --- | --- |
| P0 | rc=0：pins / 四包 abc `542936`+`24324` / suite `740 floor 720` / 导出 `164` / worktrees / selftests 2/2 / docs #54 | ≈160 s | `state.env` `P0_rc=0` |
| P1 | rc=0：3 worktree 落 pin + ignored `dist/ets`+`.arkts-build` 物化 + 5 MAUI AOT + 2 Blazor = 7 hap + tar | 388 s（复跑 309 s） | kit **68,908,566 B / `e8dd6cc8…`** |
| P2 | rc=0：`verify-kit.sh --expected-abc 542936,24324 --tree-digest` **严格 0 FAIL / 0 WARN** + 侧车 + tree 锚 | ≈5 s | tree `7321477534f4a49a…`；侧车 `2f87c93e…` |
| P3 bundle | rc=0：prepare-packs → pack-local-workload → pack-workload-bundle → release-checksums（未上传） | ≈28 s | bundle **41,231,594 B / `34b1ce95…`**、`SHA256SUMS` `45c33b50…` |
| P3 sdk 锚 | **跳过并记录**：`--sdk-repo <missing>` rc=4 前置拒绝（零写入、无 push）；命令计划见 `--phase P3 --dry-run`（worktree add → replace `WORKLOAD_BUNDLE_SHA256` → 3 installer tests → commit+push） | — | state `P3_rc=4` |

- 冒烟发现并修复（入库）：① 新 worktree 无 git-ignored `dist/ets` + `.arkts-build` → `p1_prep` 从主检出物化（P1 复跑 7 hap 全绿）；② `--force-build` 后旧 `<kit>.tar.gz.sha256` 挡住 P2 侧车检查 → `p1_build` 重建后删除侧车、P2 重生成（strict PASS）。
- 冒烟环境坑（未改仓内文件）：首次 P2 5×WARN（`dotnet.zip 11 != 9`）= 本机 `aot-v3/aot-local-hooks.targets` 误带 R91 OpenSSL 试验段（`libcrypto.so.3`/`libssl.so.3` 进 publish → libs/dotnet.zip）；换标准 Exec-only hook + 清 `test/hello-maui-app` bin/obj 后 P2 0/0。
- bundle 体积口径：干净 worktree 的 `.feed` 只含本轮 manifest 包（BCL rc.2 39.9 MB）→ bundle 41.2 MB；主检出 `.feed` 累积的历史包会顺带进旧流程 bundle（#53 73.2 MB），非脚本行为差异、换线时以 `--seed-bundle`/清理 `.feed` 统一。

## 5) 已知缺口/不确定项

- P0–P3 execute 已实跑；P4/P5/P6 的写路径仍未实跑（发布/预签/CI 按纪律未动）。P4 默认走 repo `publish-workload-release.sh`；本机需 #49–#53 的 pinned-IP curl 驱动，以 `--upload-hook` 接入（计划文件 3 列 `rid|name|file`）。
- P5 预签/manifest 为钩子（每轮 scratch 脚本不同），未内联签名密钥/UDID；P6 需 `--token-file`/GH_TOKEN。
- `--release-ids` 默认 = #49–#53 四个 release；换线需覆盖；P4 `--also-sdk-release` tag 与 merged sums 按轮提供。
- sdk 锚的 execute 写入路径未验证：本轮以缺前置 rc=4 按纪律跳过（不刷锚）；真切 #54 先用 `--sdk-repo <dir> --no-push` 演练，再放行 push。
- docs 波次正文（块内叙述/数字）仍人工撰写；helper 只保证块头/abc/索引口径。
- P2 严格门以 `verify-kit.sh` 期望为锚：构建内容真实变化（如运行时文件集）需先更新期望，否则按 drift 拒绝（本轮 11→9 是环境 hook 污染，非内容变更）。
- P1 复跑后下游阶段 rc 不做失效：`--phase P1 --force` 之后需带上 P2/P3（或用 `--force` 全选）重验，避免 state 里旧的 rc=0 被当成已验。
- P0 默认 selftest 组合较慢（真仓 P0 含默认 selftest ≈2.6 min，主要来自 `selftest-verify-kit`）。
