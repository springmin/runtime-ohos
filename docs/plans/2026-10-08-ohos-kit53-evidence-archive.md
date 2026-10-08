# KIT53-EVIDENCE-ARCHIVE：kit #53 关键证据归档（2026-10-08）

> release `springmin/sdk-ohos@device-test-kit`（id 392356147）；本波仅新增 2 个 asset（zero-change：
> before 66 → after 68，0 改动 / 0 删除）。背景：scratch 为冻结快照，此为耐久副本；新名不覆盖 #49–#52 件。

## 1) kit53-evidence-20261008.tar.gz — 62,954,206 B / `bf2025a2…`（asset 620982987；边车 620984550 / 97 B / `679a6e43…`）

- `soak53-evidence.tar.gz` **62,960,168 / `107155e6…`**（202 条目：device-round53 输出 + 干净轮归档
  `soak-round-clean-20261008-135031.tar.gz` 48,804,221 / `2da4371c…` + a11y selfcheck 轮/B6 deny·ok/ N=2+IME 复跑/
  churn/Home/fps/抽装/预签样本/soak 负载与日志/SUMMARY.md）
- `RELEASE-VALUES.txt`（FINAL）+ `kit53-gates-summary.md`（consolidated）+ 原始门禁件（gate-values53.env / gates-1.status / gates-2b.status）
- `docs/`（7 份关键文档快照）：handoff-kit53 `9da8aeb8…`、l3-post-consolidate `95833247…`、l3-b6-modes `af556c93…`、
  l3-m3 `1e4221b9…`、l3-tail-fixes `d1ed96a6…`、l3-consolidate-final `75e0cc2d…`、device-round-53 `1433715c…`（sha 见包内 `SHA256SUMS`）
- `SHA256SUMS`（13 条，路径相对包根；解包 `sha256sum -c` 13/13 OK）

## 2) 复核 / 用法

- by-id 回读：2/2 asset 按数字 id 下载后 `cmp` 逐字节一致；asset digest、边车、本地 sha 三处一致。
- 下载：`gh release download device-test-kit -R springmin/sdk-ohos -p 'kit53-evidence-*'`
- 校验：`sha256sum -c kit53-evidence-20261008.tar.gz.sha256`；解包后以包内 `SHA256SUMS` 再校验 13 个成员；
  内层证据再解 `soak53-evidence.tar.gz`（含 `SUMMARY.md`/samples/帧图/device-round53 原文）。
- 关联：tester 轮包 `tester-round-kit53.tar.gz`（asset 620790919/620794313）；设备原文见 `2026-10-08-ohos-device-round-53.md`。

## 3) 边界

- 外层是对已压缩件的再打包（双重压缩）；外层 sha 以边车与 release digest 为准。
- 未改动既有 66 个 asset，dtk release body 未改（仅资产 +2）；文档快照取自 runtime `docs/plans/` 当前版。
