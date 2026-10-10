# OpenHarmony W2B 保留分支裁决 — maui `w2b-int` / `w2b-t3t5`（A 组尾项，2026-10-10）

> 口径：maui `feature/openharmony` @ `14cc245902`（ow `01b426e`）；复核命令 `git -C maui-ohos cherry feature/openharmony <branch>`；仅动本地分支，远端与 #49–#53 资产零触碰。

## 复核结果

- `w2b-int` f333e24da9：未覆盖补丁 **1**（`^+ 48c01d69f1`）；另外 2 笔为纯合并（f333e24da9、076034dbfd），两个合并均无独有内容（首父差与对应 T3/T5 补丁逐行比对 0 差异）。
- `w2b-t3t5` 48c01d69f1：未覆盖补丁 **1**（`^+ 48c01d69f1`）。
- 唯一未覆盖提交 = T5 布局语义（z-order / clip / input transparency / anchors；2 文件 +319/−26）。主线同题提交 `c1c05f3db1`（origin 已含）与其 +/- 内容 0 行差异，仅父上下文不同导致 patch-id 不等价，故 `git cherry` 的 `+` 为伪差。

## 处置

- **均保留**（按非 0 法则）；未删除分支、未动远端。
- 价值判断：无独有内容，属备删候选；待确认后于下次卫生复核执行 `branch -D w2b-int w2b-t3t5`。
- 复核日志（scratch，未入库）：`/data/storage/el2/base/tmp/opencode/{cherry-w2b-int.txt,cherry-w2b-t3t5.txt,ab.diff}`。
