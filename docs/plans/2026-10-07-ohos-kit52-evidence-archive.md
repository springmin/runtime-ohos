# KIT52-EVIDENCE-ARCHIVE：kit #52 关键证据归档（2026-10-07）

> release `springmin/sdk-ohos@device-test-kit`（id 392356147）；本波仅新增 2 个 asset（zero-change：
> before 62 → after 64，0 改动 / 0 删除）。背景：scratch 为冻结快照，此为耐久副本；新名不覆盖 #49/#50/#51 件。

## 1) kit52-evidence-20261007.tar.gz — 61,615,799 B / `9d6f53c4…`（asset 619088581；边车 619089866）

- `soak52-evidence.tar.gz` **61,631,773 / `a26f4a41…`**（153 条目：device-round52 输出 + presign/soak 样本/日志）
- `RELEASE-VALUES.txt`（FINAL）+ `kit52-gates-summary.md`（consolidated）+ 原始门禁件（gate-values52.env / gates-1.status / gates-2b.status）
- `docs/`（8 份关键文档快照）：handoff-kit52 `48590fe1…`、l3-multi-subwindow-plan、l3-m2、l3-m3、l3-m4、
  l3-consolidate-final、l3-tail-fixes、device-round-52（sha 见包内 `SHA256SUMS`）
- `SHA256SUMS`（14 条，路径相对包根；解包 `sha256sum -c` 14/14 OK）

## 2) 复核 / 用法

- by-id 回读：2/2 asset 按数字 id 下载后 `cmp` 逐字节一致；asset digest、边车、本地 sha 三处一致。
- 下载：`gh release download device-test-kit -R springmin/sdk-ohos -p 'kit52-evidence-*'`
- 校验：`sha256sum -c kit52-evidence-20261007.tar.gz.sha256`；解包后以包内 `SHA256SUMS` 再校验 14 个成员；
  内层证据再解 `soak52-evidence.tar.gz`（含 `SUMMARY.md`/samples/帧图/device-round52 原文）。
- 关联：tester 轮包 `tester-round-kit52.tar.gz`（asset 618885974/618888765）；设备原文见 `2026-10-07-ohos-device-round-52.md`。

## 3) 边界

- 外层是对已压缩件的再打包（双重压缩）；外层 sha 以边车与 release digest 为准。
- 未改动既有 62 个 asset，dtk release body 未改（仅资产 +2）；文档快照取自 runtime `docs/plans/` 当前版。
