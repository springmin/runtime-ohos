# KIT55-EVIDENCE-ARCHIVE：kit #55 关键证据归档（2026-10-13）

> release `springmin/sdk-ohos@device-test-kit`（id 392356147）；本波新增 2 个 asset（zero-change：before → after 仅 +2；其余三个 release 0 改动；#49–#54 件全程未动）。背景：scratch 为冻结快照，此为耐久副本；新名不覆盖既有件。
> 口径 = kit #55：kit tar **70,312,042 / `504ea1ae…`**、树 `7a226f94…`、sidecar 89 B / `005cfecb…`；bundle **73,468,932 / `8aa53b67…`**（sdk 锚 `cd5bee91dc`）；预签 **70,151,840 / `fcfb6085…`**；轮包 **160,728,131 / `db585877…`**。

## 1) kit55-evidence-20261013.tar.gz — 11,519,557 B / `d97d7458…`（asset 637234489；边车 637235274 / 97 B / `953ca971…`）

- `RELEASE-VALUES.txt` + `release-values.env`（P5 实测）+ `state.env`（cut-kit 全阶段 rc）+ `presign55-values.env`/`round55-values.env`/`ci55-values.env`（资产 id/CI 记录）+ `SHA256SUMS`（99 条，开箱 `sha256sum -c`）。
- `logs/`：P0–P6 全程（`p0.log`、`p1-console{,2}.log`、`p1-prep/p1-build/p2-verify/p3-bundle`、`sdk-test-*` 安装器 3 件、`p4-verify.log`（by-id / zero-change）、`p6-ow-runs.json`）+ 步 0 预演（`step0-p4p6-dry.log`）+ bumps + `upload55.log`。
- `aot-hook/`：本 kit 构建期发现并修复的 AOT Exec 本地钩子（`aot-local-hooks.targets` 修后 + `.kit55-bak` 修前）+ 专文 `docs/2026-10-13-ohos-kit55-aot-hook-fix.md`。
- `docs/`：#55 波 10 份（handoff55 / PRE55-INTEGRATION / launcher-identity / pasteboard-fix / media-residuals / WEBAUTH-DECOUPLE / subwin-completed / pack-full-sync / cut-kit-harden / pin-bump）快照。
- `presign55/`：`sign-tester.tsv`（7 件原/新 sha、device-ids、verify）、`preSigned-README.md`、签署/装配日志与 tree digest。
- `round55/`：轮包 stage/upload/patch 日志。
- `device/` + `device-smoke/`：PRE55 真机轮关键原始件（bm 三件、fault 前后、WMS、安装日志、开始菜单 dump/截图）+ 本轮 #55 发版抽验（`smoke.log`、release digest 对口、`bm-dump.json`（labelId 16777217/iconId 16777231、INTERNET）、`layout-startmenu.json` + `startmenu.jpeg`、`hilog.txt`（`canvas presented`）、`fault-*`（diff=0）、重签/安装日志）。

## 2) 复核 / 用法

- by-id 回读：2/2 asset 按数字 id 下载后 `cmp` 逐字节一致（本地 sha 与 release digest 双向一致）。
- 下载：`gh release download device-test-kit -R springmin/sdk-ohos -p 'kit55-evidence-*'`
- 校验：`sha256sum -c kit55-evidence-20261013.tar.gz.sha256`；解包后以包内 `SHA256SUMS` 再校验 99 个成员。
- 关联：tester 轮包 `tester-round-kit55.tar.gz`（asset 637208200/637213855，`db585877…`）；交接/判定 = `2026-10-13-ohos-tester-handoff-kit55.md`。

## 3) 边界

- 外层是对已压缩件的再打包（双重压缩）；外层 sha 以边车与 release digest 为准。
- 未改动既有资产（P4 zero-change 清单：dtk 全部历史件 id 不变；versioned/latest/sdkrc2 仅 bundle + sums 更新为 #55 字节）。
