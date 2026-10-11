# BUMP-SHA-FIX：kit #54 tester-docs abc sha 修正 + A-M1 卫生（2026-10-10）

> 范围：修复 #54 预刷残留（bump 只刷 abc 尺寸，sha 仍 `f18f0855…`）；无构建、无设备；#49–#53 资产不动、远端零删除。
> bump 增强（ow `tooling/bump-sha`）：`bump-tester-docs.sh --abc-sha <sha8>` 在「被升块/README 索引行」把 ui abc 相邻 sha 刷为 `<sha8>…`（zh `（`sha…`）` + en ` / `sha…`` 两式、plain/grouped；历史行与 headless sha 不动）；缺相邻 sha 拒绝、非法 sha rc=2、dry-run 零写、二跑字节级幂等。
> selftest：T6 增 T6i–T6m（sha 两式/README/历史保留/缺 sha 拒/幂等/坏 sha）→ **101 checks 全过**（原 77）。
> 真仓刷新：`bump-tester-docs.sh --kit 54 --abc-sha 37c3afdc` → **19 文件 / 21 行**（README+18 docs）；复核 `589,?700` 相邻 sha **0 处旧值、全部 `37c3afdc…`**；历史 `f18f0855…` 引用原样（docs/plans 58→37 处，仅替换 21 行）；headless `798b2477…` 不动；尾随空白 0。
> P0 复核：`cut-kit.sh --kit 54 --phase P0 --dry-run` **PASS**（12:40–12:42）：pins ow `5e27363`/maui `fbd91e17bc`/runtime `a3a56461fb`、packs 指纹 `589700/37c3afdc`+`24324/798b2477`、suite 779 floor 759、exports 164、selftests 2/2、docs 门 PASS（P0 不校验 sha）。
> 提交：ow `tooling/bump-sha` `57bd2fc` → `master` merge **`624e6e43fa41`**（--no-ff；maui 未动、pin 不变；FF 推送 `5e27363..624e6e4`；CI **5/5**：interaction `38112610566`/pixel `38112610559`/host-export `38112610580`/ridgraph `38112610594`/markdownlint `38112610587`）；runtime 19 文件 **`e52d4ded09e1`** + 本页（pre-release 注记：kit #54 未切、rc.2 WAIT；FF 推送、未 force；fork 面无 push CI）。
> A-M1 卫生：`feat/mediaelement-arkweb` 删除（ow `b674f80`、maui `0adfe6c7fe`；ancestor 复核后 `branch -D`；远端不动）；五仓 `worktree prune -v` rc=0、附加 0（无 media worktree）；检出 ow `master@624e6e43`（含 `0177a32`）/ maui `feature/openharmony@fbd91e17bc`，均 clean。
> 证据保留：`media-q1/`、`mediaelement/` 为非 git 证据 scratch（Q1/A-M1 文档引用），未删；日志 `selftest-cutkit-sha.log`、`cutkit54-p0-bumpsha.log`（scratch、未入库）。
> 校验：markdownlint（本页 + 19 文件）**MD009=0**。
> 不确定项：① `--abc-sha` 为显式参数（`cut-kit --bump-docs` 未传、P0 不校验 sha）——下次切包需手动带上；② media 证据 scratch 未删（回收空间前需确认文档引用可断）。
