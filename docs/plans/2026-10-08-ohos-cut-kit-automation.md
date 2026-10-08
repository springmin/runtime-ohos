# CUT-KIT-AUTOMATION：kit 切包流程脚本化 + 包内 tester docs 预检（2026-10-08）

> 状态：**已实现 + 干跑/自测；未真实发布**。本次未执行任何构建/上传/clobber，#49–#53 release 资产未动。
> 载体：ohos-workload 分支 `tooling/cut-kit`（`5baf2be`，从 master `7259a0f`；未并 master、未强推、普通推送）。
> 入口：`ohos-workload/scripts/cut-kit.sh`；自测 `scripts/selftest-cut-kit.sh`（已接入 `preflight.sh` step 1）。

## 1) 阶段与安全门

| 阶段 | 内容 | 干跑 | 执行 |
| --- | --- | --- | --- |
| P0 预检 | pin（worktree/三 workflow `MAUI_OHOS_REF`）+ 四包 abc + verify-kit `EXPECT_ABC` + 套件/宿主导出计数 + 工作树净 + selftest + docs 预检 | 真跑（只读） | 写 `state.env` |
| P1 构建 | 三 worktree 落 pin + hosting/Graphics Release prep + `make-device-test-kit --runtime-mode aot --with-blazor`（7 hap，不 `--publish`） | 打印命令 | `--execute`；docs 门 fail-closed；一次一构建（`--force-build` 覆盖） |
| P2 严格校验 | 包内 `verify-kit.sh --expected-abc <EXPECT> --tree-digest`：rc=0 且 0 FAIL/0 WARN + sidecar + tree 锚入 state | 打印命令 | `--execute` |
| P3 bundle/锚 | prepare-packs → pack-local-workload → pack-workload-bundle → release-checksums；sdk-ohos `WORKLOAD_BUNDLE_SHA256` 改锚 + 3 个 installer 测试 + commit/push | 打印命令 | `--execute`（`--no-push` 演练） |
| P4 发布（F4） | 打印将 clobber 的资产清单 → 键入 `clobber kit <N>` 确认 → `--upload-hook` 上传 → by-id 摘要复核 + 各 release 零改动清单 → 4 个 release body 补 `## Integrity (kit #N)` | 打印计划 | `--execute --i-know` |
| P5 VALUES/预签 | `RELEASE-VALUES`/`release-values.env` + presign/manifest 钩子（`--presign-hook`/`--manifest-hook`） | 打印 | `--execute --i-know` |
| P6 CI 复核 | ow 5 workflow + sdk anchor run（API 只读） | 打印查询 | `--execute --i-know` |

- 断点续跑：默认 P0→P6，`<scratch>/state.env` 记录各阶段 rc/时间戳 + kit/bundle sha、tree digest、sdk anchor；rc=0 已完成阶段自动跳过（`--force` 重跑）。
- 安全默认：`--dry-run` 为默认，仅 `--execute` 写；P4–P6 另需 `--i-know`；`--yes` 跳过键入确认仅供演练。
- 单阶段：`--phase P0,P1` 或 `--phase P4`；未知阶段/用法错误 rc=2，安全门拒绝 rc=3，缺前置件 rc=4。

## 2) docs 预检（#52/#53 痛点闭环）

- 契约：18 份 tester docs（#50/#51/#52 波次同表）必须含目标 kit 的块头 `kit #N，当前）` / `kit #N — current)`，且每份含当前壳 abc（`542936`/`542,936`）；`docs/plans/README.md` 必须含 `kit #N 日期口径`。8 份入包文档（对应 `make-device-test-kit.sh` 的 copy_doc 映射）一并做存在性校验。
- 失败 fail-closed：P0 rc=3；P1 先复检再构建，拒绝时给 `--bump-docs` 提示（`--bump-docs` 调 `scripts/bump-tester-docs.sh --kit N`，该 helper 尚未入库）。
- 误报治理：只认“块头”标记（`，当前）`/`— current)` 收尾），历史行如 `**kit #45（当前）**` 不误伤。

## 3) 用法示例

```sh
sh scripts/cut-kit.sh --kit 54                                   # 全阶段干跑（P0 真检，P1..P6 打印计划）
sh scripts/cut-kit.sh --kit 54 --phase P0 --execute              # 预检 + 落 state.env
sh scripts/cut-kit.sh --kit 54 --phase P0,P1,P2 --execute        # 续跑：构建 + 严格校验
sh scripts/cut-kit.sh --kit 54 --phase P4 --dry-run              # F4 clobber 计划
sh scripts/cut-kit.sh --kit 54 --phase P4 --execute --i-know --upload-hook <scratch-curl.sh>
```

## 4) 干跑/自测证据（2026-10-08，本机）

- 真仓 P0（kit #53）：PASS — pins ow `7259a0f848` / maui `caa463434b` / runtime `8a2bbd2b73`（3/3 workflow 同 pin）、四包 abc `542936/f18f0855`+`24324/798b2477`、`EXPECT_ABC=542936,24324`、套件 `740/720`、导出 `164`、docs 18/18。
- 真仓 `--kit 54 --phase P0,P1 --dry-run`：docs 陈旧 → rc=3 + bump 提示；P1 拒绝（`refusing to build`，未打印构建命令）。
- 真仓全阶段 `--dry-run`：P1–P6 命令/计划全部打印（P4 列 10 项 clobber 资产 + notes×4），scratch 零写入。
- `sh scripts/selftest-cut-kit.sh`：**38/38 通过**（P0 pass/fail、pack 漂移、docs 陈旧两种、断点续跑、F4 拒绝门零写盘/零 curl）；`sh -n` 全绿。

## 5) 已知缺口/不确定项

- `bump-tester-docs.sh` 未实现：docs 波次仍由切包代理编辑 18 份文档 + 索引，工具只做门 + 提示。
- P4 默认走 repo `publish-workload-release.sh`；本机需 #49–#53 的 pinned-IP curl 驱动，以 `--upload-hook` 接入（计划文件 3 列 `rid|name|file`）。
- P5 预签/manifest 为钩子（每轮 scratch 脚本不同），未内联签名密钥/UDID；P6 需 `--token-file`/GH_TOKEN。
- `--release-ids` 默认 = #49–#53 四个 release；换线需覆盖；P4 `--also-sdk-release` tag 与 merged sums 按轮提供。
- P0 默认 selftest 组合较慢（真仓 P0 含默认 selftest ≈2.6 min，主要来自 `selftest-verify-kit`）；P1–P5 的 execute 路径未实跑（本任务只验证 dry-run/自测）。
