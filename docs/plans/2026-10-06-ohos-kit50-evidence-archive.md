# KIT50-EVIDENCE-ARCHIVE：kit #50 关键证据归档（2026-10-06）

> release `springmin/sdk-ohos@device-test-kit`（id 392356147）；本波仅新增 2 个 asset（zero-change：
> before 54 → after 56，0 改动 / 0 删除）。背景：scratch 为冻结快照，此为耐久副本；新名不覆盖 #49 件。

## 1) kit50-evidence-20261006.tar.gz — 52,940,085 B / `4baf0b29…`（asset 616009069；边车 616010097）

- `soak50-evidence.tar.gz` **52,937,361 / `4e674660…`**（超集：干净轮 + 首轮 pidloss 窗口 + 样本 + device-round 输出，154 条目）
- `RELEASE-VALUES.txt`（FINAL）+ `kit50-gates-summary.md`（consolidated）+ 原始门禁件（gate-values50.env / gates-1.status / gates-2b.status）
- `docs/`（9 份关键文档快照）：handoff-kit50 `936ce2a8…`、l-consolidate、l-m4、l-m4-prestudy、l2-options-analysis、
  security-scan-5a/5b/5c、device-round-50（从 runtime `docs/plans/` 当前版取；sha 见包内 `SHA256SUMS`）
- `SHA256SUMS`（15 条，路径相对包根；解包 `sha256sum -c` 15/15 OK）

## 2) 复核 / 用法

- by-id 回读：2/2 asset 按数字 id 下载后 `cmp` 逐字节一致；asset digest、边车、本地 sha 三处一致。
- 下载：`gh release download device-test-kit -R springmin/sdk-ohos -p 'kit50-evidence-*'`
- 校验：`sha256sum -c kit50-evidence-20261006.tar.gz.sha256`；解包后以包内 `SHA256SUMS` 再校验 15 个成员；
  内层证据再解 `soak50-evidence.tar.gz`（含 `SUMMARY.md`/samples/帧图/首轮 pidloss 归因）。
- 关联：tester 轮包 `tester-round-kit50.tar.gz`（asset 615575350）；设备原文见 `2026-10-06-ohos-device-round-50.md`。

## 3) 边界

- 外层是对已压缩件的再打包（双重压缩）；外层 sha 以边车与 release digest 为准。
- 未改动既有 54 个 asset，dtk release body 未改（仅资产 +2）。
