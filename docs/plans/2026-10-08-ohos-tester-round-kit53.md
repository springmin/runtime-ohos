# 测试方一轮交付包（tester-round-kit53.tar.gz）：kit #53 单件聚合（2026-10-08）

> 用途：把「一轮设备测试」的取件 → 校验 → 重签 → 一条命令 → 判定点索引 → 回传清单固化成单件资产。本页只记录包本身（来源/指纹/成员/发布/复核）；
> 判定内容一律指向被聚合原文（POST-L3 收口 / L3-CONSOLIDATE-FINAL / L3-M2/M3/M4 / L3-B6-MODES / L3-TAIL-FIXES / L-M 验收矩阵 / handoff-kit52 / handoff-kit51；§2 列名）。纪律：**只聚合、不重打包**——外部件逐件与 release sidecar 比对后按原字节复制。

## 1. 发布与指纹

- release：`springmin/sdk-ohos` tag **`device-test-kit`**（id 392356147）；新资产：`tester-round-kit53.tar.gz` asset **620790919**、
  **157,866,589 B** / `0ce200a279e852385da0518f881ef2e5e615603507d71d04dd3b7153bfb43eb9`；sidecar asset **620794313**、92 B / `c50b4a69…`。
- **by-id 复核**：按 asset id 回读（全量经 gh-proxy 通道；直连 release-assets 限速 ~20–40 KB/s）→ 大小/sha256 与发布 digest 一致、sidecar `cmp` 一致；零改动清单 = 新增这 2 项
  （392356147: 64→66，0 removed/changed；392077166/398739326/398936638 三 release 0 变化）。
- 包内顶层 `tester-round-kit53/`；`SHA256SUMS` 31 行（`sha256sum -c` 31/31，解包复跑 31/31）；`verify-kit.sh` → KIT OK（裸跑、
  `--expected-abc 542936`、`--tree-digest --expect-tree-digest 9c67b5ec…` 皆绿）；入口 `README-一轮上手.md`（#53 指纹、a11y selfcheck 修复
  （子窗 `nodes=10`）、B6 导航否决、N=2 多子窗/按窗 child web（承 #52）、降级/人工卡、参数 #53=542936 / #52=534192 / #51=473048、CI 链接）。

## 2. 成员（31 件 + `SHA256SUMS`；来源 → 包内路径）

- kit #53（**68,883,057 / `dba88961…`**、树 `9c67b5ec…`、sidecar `47ace1d0…`；内部 `SHA256SUMS` 18 项 / 1,600 B / `39489081…`）+
  #53 预签（**68,755,353 / `d1732195…`**，asset 620760775、sidecar `35b736b3…` asset 620762418；树 `422cc15f…`）→ `assets/`；
- 解释器 rc2b（`59744305…`+`519b459e…`+README `0141b224…`）、AOT v3 rc2（`3d24f716…`+`f51e2a04…`+README `05f9accb…`）、Crossgen2 rc.2
  `SHA256SUMS`（`d88a7551…`；nupkg 未内置）→ `assets/`；
- 15 份判定/证据文档（POST-L3 收口 `95833247…` / L3-CONSOLIDATE-FINAL `75e0cc2d…` / L3-M2 `3ff19406…` / L3-M3 `1e4221b9…` / L3-M4
  `9d7a4b7b…` / L3-B6-MODES `af556c93…` / L3-MULTI-SUBWINDOW 计划 `b7ca695e…` / L3-TAIL-FIXES `d1ed96a6…` / L-M 验收矩阵 `4f36b70f…` /
  platform-limitations `e706dad1…` / device-round-script `7bd0d721…` / retest-taskcard `037d2428…` / security-scan-6 `801ff7fb…` /
  handoff-kit52 `48590fe1…` / handoff-kit51 `93d442f8…`）→ `docs/`；
- `device-round.sh`（`4d59ed00…`）/`sign-for-device.sh`（`fa93f542…`）/`scripts/README.md`（`138e452f…`）→ `scripts/`。

## 3. 用法（3 步）

```sh
sha256sum -c tester-round-kit53.tar.gz.sha256 && tar xzf tester-round-kit53.tar.gz && cd tester-round-kit53 && sha256sum -c SHA256SUMS
mkdir -p kit && tar xzf assets/device-test-kit.tar.gz -C kit && (cd kit && sh verify-kit.sh --expected-abc 542936)
sh scripts/device-round.sh --kit assets/device-test-kit.tar.gz --suite --out ./round-report \
    --expect-tree-digest 9c67b5ec56b3698ac0e72f4905b9f4640a99fe0cc7888d281c35823e57888c79
```
- 步骤语义：① 外层 sidecar + 包内 31 件；② 裸跑 `sh verify-kit.sh` 亦绿（默认重锚 542936,24324），显式参数如上（#52 包 534192、#51 包 473048）；
  ③ 一条命令真机轮（预签 UDID 直装跳过重签；先 `--dry-run` 彩排）。预签直装：解 `assets/preSigned-haps.tar.gz` → 包内 8/8 → `hdc install -r`；非 tester UDID 报 `9568344` 回传代签。

## 4. 复核与不确定项

- 源件：kit/预签/解释器/AOT/Crossgen2 逐件 sha256 与 release sidecar 一致；#48–#52 聚合包保留未动；打包/发布后 31/31、解包复跑
  31/31、外层 sidecar OK、by-id 回读一致；dtk release body 追加 1 行（148→149，仅追加，前缀逐字节一致）。
- 本页提交：runtime-ohos `feature/openharmony`（docs-only；`commit-paths.sh` 限路径；Git Data API 旁路）；本页为初版记录，README 索引未改动。
- 不确定项：① Crossgen2 nupkg 未内置（43,792,647 / `6bb8a375…`，folder-feed 见引用文件）；② 预签仅 tester UDID 直装；③ 包内 docs 为 kit #53 波次快照（sha 绑定 `SHA256SUMS`）；
  ④ 40min soak / 容量 255 为交付方 2in1 debug 观测（测试方抽样/carry）；⑤ a11y selfcheck 修复与 B6 否决的真机证据引用两卡归档（A11Y-SELFCHECK / B6-MODES），测试方按包内判定点复核；⑥ 子窗 hybrid/Blazor 资产桥真机未验（明示降级项）。
