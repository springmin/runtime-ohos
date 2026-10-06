# L2-CONSOLIDATE：MULTIWINDOW-L2（a+b + SEC-SCAN-6 A/B/C）并入主线 / 门禁 / pin / CI（2026-10-07）

> 口径：两线**并存整合**——ow `master` ← `l2/a11y-provider` @ `f5a892a` + `l2/arkweb-subwindow` @ `3c486cf`
> （merge `c562a32d`、`094ad51b`）；maui `feature/openharmony` ← 同两线 @ `ba7581022c`、`2e441c35c9`
> （merge `9faacf3ca3`、`086d358dc3`）；均 merge commit、普通推送、未强推。**不切 kit（KIT51 待切）、#49/#50 未动**。

## 1) 合并（四 pack `SubWindow.ets` 一次并存整合）

- ow `afa6d7a` → `c562a32`（a11y +7 checks、导出 163）→ `094ad51`（arkweb +18）；冲突 = 4×`SubWindow.ets` + `Program.cs`，解析 = a11y 挂接 + child web 池并存、主窗零变化；并集修复 `l2ExportCount 157→163`、顶层重名 2 处。
- maui `74e0bde5b9` → `9faacf3ca3` → `086d358dc3`（自动合并；`ResolveWindowId` 两线改写逐字相同）。

## 2) packs / abc / provenance

- 重编：ui **473,048 / `298622c0…`**（439,144 与 470,720 并存后）、headless **24,324** 不变；`--install-packs`
  + preview.28 手动同步，四包逐字节一致；`--check-sources`/`--check-pack-abc` 绿。
- `verify-kit` EXPECT_ABC `436,808 → 473,048`；selftest 129/0、arkts 188/0；ow `6ce7610`+`3fe0d88`。

## 3) 门禁

- 套件 `[suite] checks=688 total=690 floor=670 assert=True`（declared==printed、0 Unhandled、perf `within=True`；超集 = 663+7+18+2）。**红控**：反转 SEC6-B 主窗拒绝 + SEC6-C 两 hook → `primary tag rejected`/`close drops a11y frame`/`close drops child pool` 3 条 assert=False（exit 134），还原复绿。
- host 三门禁：DT_NEEDED/UND 过、**导出 163/163**；`check-host-exports.py --cross-check` 163/163；
  registry 6/0、bridge 12/0、a11y-table 13/0。
- preflight：gates + interaction + pixel 全 PASS、markdownlint 0 issue（补 `.a11y-build/**` 忽略 `696ebc0`）。

## 4) SEC6-C（低，已修）

- `OpenHarmonyChildWeb.ReleaseWindow`（清 Capacity/Pending）+ `OpenHarmonyAccessibility.ReleaseWindow`
  （清 frame/first-publish 标记）挂 `OpenHarmonyWindowHost.Reset()`；ow `1ed43d1` / maui `bb6b0699`；+2 checks（红控在案）。
- 余留 = ow 原生 a11y 分区常驻（有界；SEC-6 报告边界）。

## 5) pin / CI

- 三 workflow pin `23d98a9615 → bb6b06990d`（注释：套件 688/690 floor 670、导出 163/163、abc 473,048）；ow `8ba02a8`（pin）+ `696ebc0`（lint）。
- CI 5/5 @ `696ebc0`：interaction `37548888210`/pixel `37548888313`/host-export `37548888169`/ridgraph `37548888051`/markdownlint `37548888104`。

## 6) 状态

- **L2（a+b）合并完成；KIT51 待切**；#49/#50 资产未动、未强推；SEC-6 A/B/C 全闭；余项 = 子窗 hybrid/blazor 资产桥 + B6 导航否决（下波）、a11y 读屏 e2e 平台限制（B1）。
