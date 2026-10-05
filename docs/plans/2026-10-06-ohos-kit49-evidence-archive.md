# KIT49-EVIDENCE-ARCHIVE：kit #49 关键证据 + a11y 外部验证包归档（2026-10-06）

> release `springmin/sdk-ohos@device-test-kit`（id 392356147）；本波仅新增 4 个 asset（zero-change：
> before 48 → after 52，0 改动 / 0 删除）。背景：scratch 已被清理过一次，此为耐久副本。

## 1) kit49-evidence-20261006.tar.gz — 64,593,254 B / `4de90cc0…`（asset 613748063；边车 613748596）

- `device-round49-20261006-021323.tar.gz` 24,485,508 / `c24c660b…`（device round 主档，69 成员）
- `device-round49-manual-20261006-0228.tar.gz` 5,149,043 / `551d5d8a…`（manual 归档）
- `soak49-evidence.tar.gz` 25,983,542 / `c9ee6efd…`
- `RELEASE-VALUES.txt`（FINAL）+ `kit49-gates-summary.md` + 原始门禁件（gate-values49.env /
  gates-1.status / gates-2b.status / selftests.status）
- `ur1005/`（13 件：mergetree / rebase 的 tsv/log/refs + rt-rebase.sh、sdk-asp-rebase.sh）
- `keep-evidence-20261005.tar.gz` 9,997,642 / `1fb7adc8…`（4,810 文件）
- `SHA256SUMS`（24 条，路径相对包根）

## 2) a11y-client-pack-20261006.tar.gz — 47,913 B / `c624d2dd…`（asset 613747651；边车 613747940）

- 来源：dtk 既有 asset（无）→ `reg-kit49/`（无）→ 残余 `ohos-workload/dist/a11y-client/`（2026-10-05
  09:16 构建）；sha 与 `docs/plans/2026-10-05-ohos-a11y-client.md` 记录一致，未重建。
- 件：`a11y-client-signed.hap` 83,279 / `f3fbfad6…`（debug 签名、绑 kit #49 tester UDID）、
  `a11y-client-unsigned.hap` 57,702 / `487dd0b9…`（异地重签用）、`ENABLE-AND-COLLECT.md`（启用 /
  采集步骤摘录）、`RETURN-TEMPLATE.md`、`MANIFEST.md`、`SHA256SUMS`。
- kit #49 影像第三方扩展启用全闭（AMS client=0、无 `accessibility` CLI、设置无已安装服务）；外部验证
  需 stock/user 构建。判据：dump nodes>0、NODE role/label/rect 与屏幕一致、ACTION 后 `Count:` +1、
  密码仅等长点号（SEC-SCAN-4）。

## 3) 复核 / 用法

- by-id 回读：4/4 asset 按数字 id 下载后 `cmp` 逐字节一致；asset digest、边车、本地 sha 三处一致。
- 下载：`gh release download device-test-kit -R springmin/sdk-ohos -p 'kit49-evidence-*' -p 'a11y-client-pack-*'`
- 校验：`sha256sum -c <file>.sha256`；证据包解包后以包内 `SHA256SUMS` 再校验 24 个成员。

## 4) 边界 / 备注

- 证据包是对既有压缩件的再打包（双重压缩）；外层 sha 以边车与 release digest 为准。
- 未改动 `docs/plans/README.md`（并发代理在改）；本文件待索引。
- a11y 签名 hap 仅适用 kit #49 tester UDID（`1BCE13C8…`）；其他设备用未签件自行签名。
