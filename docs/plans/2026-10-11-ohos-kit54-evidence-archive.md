# KIT54-EVIDENCE-ARCHIVE：kit #54 关键证据归档（rev2，2026-10-11）

> release `springmin/sdk-ohos@device-test-kit`（id 392356147）；本波仅新增 2 个 asset（zero-change：
> before 70 → after 72，0 改动 / 0 删除；其余三个 release 0/0/0）。背景：scratch 为冻结快照，此为耐久副本；新名不覆盖 #49–#53 件。
> 口径 = rev2（kit tar 70,345,291 / `583d6df4…`、树 `251d0c43…`；预签 70,180,932 / `8eb6dc80…`；轮包 160,770,425 / `bd8948db…`；旧 rev1 件作废）。

## 1) kit54-evidence-20261011.tar.gz — 77,782,693 B / `d20b5cde…`（asset 631055430；边车 631056825 / 97 B / `1953aaa3…`）

- `soak54-evidence.tar.gz` **77,760,631 / `92d76031…`**（263 条目：device-round54 输出 + presign/soak 样本与日志 +
  overlay/subwindow-default4/media/HLS/WebAuth/churn/fps/a11y 各轮 + `SUMMARY.md`/`device.txt`/samples/帧图）
- `RELEASE-VALUES.txt`（rev2 实测）+ `gate-values54.env`（门禁摘要：796/799 floor 779、pixel PASS、preflight 5/5、导出 164）
- `docs/`（9 份关键文档快照）：handoff54、kit54-hap-verify（含 §7 rev2 抽验）、mediaelement-arkweb、media-subwin-hls、
  media-q1-probe、modal-overlay-fix、subwindow-default4、final-batch、device-round-54（sha 见包内 `SHA256SUMS`）
- `SHA256SUMS`（12 条，路径相对包根；解包 `sha256sum -c` 12/12 OK；内层 soak tar 与 RELEASE-VALUES 交叉钉）

## 2) 复核 / 用法

- by-id 回读：2/2 asset 按数字 id 下载后 `cmp` 逐字节一致；asset digest、边车、本地 sha 三处一致。
- 预签核验（2026-10-11 release API/body）：`preSigned-haps.tar.gz` 现值 **70,180,932 / `8eb6dc80…`**（asset 630934768；
  sidecar 88 B / `6ecab34b…`，asset 630936005）——与 rev2 RELEASE-VALUES 及 release body「预签直装」行一致（无偏差）。
- 下载：`gh release download device-test-kit -R springmin/sdk-ohos -p 'kit54-evidence-*'`
- 校验：`sha256sum -c kit54-evidence-20261011.tar.gz.sha256`；解包后以包内 `SHA256SUMS` 再校验 12 个成员；
  内层证据再解 `soak54-evidence.tar.gz`（含 `SUMMARY.md`/samples/帧图/device-round54 原文）。
- 关联：tester 轮包 `tester-round-kit54.tar.gz`（asset 630954114/630955835，rev2 `bd8948db…`）；设备原文见 `2026-10-11-ohos-device-round-54.md`。

## 3) 边界

- 外层是对已压缩件的再打包（双重压缩）；外层 sha 以边车与 release digest 为准。
- 未改动既有 70 个 asset，dtk release body 未改（仅资产 +2）；文档快照取自 runtime `docs/plans/` 当前版（rev2 后）。
