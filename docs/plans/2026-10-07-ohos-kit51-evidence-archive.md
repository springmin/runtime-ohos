# KIT51-EVIDENCE-ARCHIVE：kit #51 关键证据归档（2026-10-07）

> release `springmin/sdk-ohos@device-test-kit`（id 392356147）；本波仅新增 2 个 asset（zero-change：
> before 58 → after 60，0 改动 / 0 删除）。背景：scratch 为冻结快照，此为耐久副本；新名不覆盖 #49/#50 件。

## 1) kit51-evidence-20261007.tar.gz — 56,638,182 B / `95e1b9f0…`（asset 617308713；边车 617309039）

- `soak51-evidence.tar.gz` **56,622,678 / `8d0c9620…`**（152 条目：device-round51 输出 + presign/soak 样本/日志）
- `RELEASE-VALUES.txt`（FINAL）+ `kit51-gates-summary.md`（consolidated）+ 原始门禁件（gate-values51.env / gates-1.status / gates-2b.status）
- `docs/`（8 份关键文档快照）：handoff-kit51 `93d442f8…`、l2-consolidate、l2-a11y-provider、l2-arkweb-subwindow、
  multiwindow-l2-options-analysis、l2-subwindow-capacity-probe、security-scan-6、device-round-51（sha 见包内 `SHA256SUMS`）
- `SHA256SUMS`（14 条，路径相对包根；解包 `sha256sum -c` 14/14 OK）

## 2) 复核 / 用法

- by-id 回读：2/2 asset 按数字 id 下载后 `cmp` 逐字节一致；asset digest、边车、本地 sha 三处一致。
- 下载：`gh release download device-test-kit -R springmin/sdk-ohos -p 'kit51-evidence-*'`
- 校验：`sha256sum -c kit51-evidence-20261007.tar.gz.sha256`；解包后以包内 `SHA256SUMS` 再校验 14 个成员；
  内层证据再解 `soak51-evidence.tar.gz`（含 `SUMMARY.md`/samples/帧图/device-round51 原文）。
- 关联：tester 轮包 `tester-round-kit51.tar.gz`（asset 617151248）；设备原文见 `2026-10-07-ohos-device-round-51.md`。

## 3) 边界

- 外层是对已压缩件的再打包（双重压缩）；外层 sha 以边车与 release digest 为准。
- 未改动既有 58 个 asset，dtk release body 未改（仅资产 +2）；文档快照取自 runtime `docs/plans/` 当前版。
