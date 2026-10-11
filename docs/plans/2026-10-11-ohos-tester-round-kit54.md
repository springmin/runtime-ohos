# 测试方一轮交付包（tester-round-kit54.tar.gz）：kit #54 单件聚合（2026-10-11）

> 用途：把「一轮设备测试」的取件 → 校验 → 重签 → 一条命令 → 判定点索引 → 回传清单固化成单件资产。本页只记录包本身（来源/指纹/成员/发布/复核）；
> 判定内容一律指向被聚合原文（FINAL-BATCH / A-M1 / B-M1 / MEDIA-MICRO / MODAL-OVERLAY-FIX / SUBWINDOW-DEFAULT4 / E4-CAPACITY8 / DEEPLINK / WebAuth 显隐 / L8-POPUP / UITEST-INJECT / UNSUPPORTED-RECHECK / 承 #53 各卡；§2 列名）。纪律：**只聚合、不重打包**——外部件逐件与 release sidecar 比对后按原字节复制。

## 1. 发布与指纹

- release：`springmin/sdk-ohos` tag **`device-test-kit`**（id 392356147）；新资产：`tester-round-kit54.tar.gz` asset **630491536**、
  **158,684,546 B** / `8fc05b6d8992ea8ad5cb11e0c0015b0eef3a0f52b2cfafab39256d37965180f6`；sidecar asset **630493485**、92 B / `97aeb64b…`。
- **by-id 复核**：按 asset id 回读（全量经 gh-proxy 通道；直连 release-assets 限速 ~20–40 KB/s）→ 大小/sha256 与发布 digest 一致、sidecar `cmp` 一致；零改动清单 = 新增这 2 项（392356147: 68→70，0 removed/changed；392077166/398739326/398936638 三 release 0 变化）。
- 包内顶层 `tester-round-kit54/`；`SHA256SUMS` 40 行（`sha256sum -c` 40/40，解包复跑 40/40）；`verify-kit.sh` → KIT OK（裸跑、
  `--expected-abc 623784`、`--tree-digest --expect-tree-digest c0099033…` 皆绿）；入口 `README-一轮上手.md`（#54 指纹、MediaElement 主窗/子窗/HLS、
  模态 overlay 修复、子窗默认 4、容量 8、深链 0 s 修复、WebAuth 显隐、L8 弹窗、降级/人工卡、参数 #54=623784 / #53=542936 / #52=534192 / #51=473048、CI 链接）。

## 2. 成员（40 件 + `SHA256SUMS`；来源 → 包内路径）

- kit #54（**69,301,436 / `ecc41f05…`**、树 `c0099033…`、sidecar 89 B / `02da6dcd…`、asset 630438379；内部 `SHA256SUMS` 18 项 / 1,600 B / `727d8815…`）+
  #54 预签（**69,144,076 / `c4806485…`**，asset 630444444、sidecar 88 B / `cbce6b6e…` asset 630445633；树 `d15a2c16…`）→ `assets/`；
- 解释器 rc2b（`59744305…`+`519b459e…`+README `0141b224…`）、AOT v3 rc2（`3d24f716…`+`f51e2a04…`+README `05f9accb…`）、Crossgen2 rc.2
  `SHA256SUMS`（`d88a7551…`；nupkg 未内置）→ `assets/`；
- 24 份判定/证据文档（FINAL-BATCH `59eb483f…` / A-M1 `5ffce9fe…` / B-M1 `31fba15b…` / MEDIA-MICRO `bcc1bb24…` / MODAL-OVERLAY-FIX `28e7f99d…` /
  CAPTURE `043c7a39…` / SUBWINDOW-DEFAULT4 `e375210c…` / L7-M2 `8a5fe1dd…` / E4-CAPACITY8 `75fc73e0…` / DEEPLINK `9a90eab5…` / WebAuth `7a12c513…` /
  隐式 `bc49920f…` / L8-POPUP `da3b4069…` / UITEST-INJECT `e9e49b17…` / UNSUPPORTED-RECHECK `c4066419…` / platform-limitations `0c3cc8c8…` /
  POST-L3 收口 `95833247…` / L-M 验收矩阵 `50bacd43…` / L3-TAIL-FIXES `cd75b382…` / handoff-kit52 `48590fe1…` / handoff-kit51 `93d442f8…` /
  retest-taskcard `037d2428…` / device-round-script `7bd0d721…` / SEC-SCAN-7 `857c774b…`）→ `docs/`；
- `device-round.sh`（`4d59ed00…`）/`sign-for-device.sh`（`fa93f542…`）/`scripts/README.md`（`138e452f…`）→ `scripts/`。

## 3. 用法（3 步）

```sh
sha256sum -c tester-round-kit54.tar.gz.sha256 && tar xzf tester-round-kit54.tar.gz && cd tester-round-kit54 && sha256sum -c SHA256SUMS
mkdir -p kit && tar xzf assets/device-test-kit.tar.gz -C kit && (cd kit && sh verify-kit.sh --expected-abc 623784)
sh scripts/device-round.sh --kit assets/device-test-kit.tar.gz --suite --out ./round-report \
    --expect-tree-digest c009903378e09907c2b5590d0107d6083b719445ad5720c8b9ed15634fe6f3de
```
- 步骤语义：① 外层 sidecar + 包内 40 件；② 裸跑 `sh verify-kit.sh` 亦绿（默认重锚 623784,24324），显式参数如上（#53 包 542936、#52 包 534192、#51 包 473048）；
  ③ 一条命令真机轮（预签 UDID 直装跳过重签；先 `--dry-run` 彩排）。预签直装：解 `assets/preSigned-haps.tar.gz` → 包内 8/8 → `hdc install -r`；非 tester UDID 报 `9568344` 回传代签。

## 4. 复核与不确定项

- 源件：kit/预签/解释器/AOT/Crossgen2 逐件 sha256 与 release sidecar 一致；#48–#53 聚合包保留未动；打包/发布后 40/40、解包复跑
  40/40、外层 sidecar OK、by-id 回读一致；dtk release body 追加 1 行（207→208，仅追加，前缀逐字节一致）。
- 本页提交：runtime-ohos `feature/openharmony`（docs-only；`commit-paths.sh` 限路径；直推 OK `08b8b149c60…→0f2b77b08d8…`，未触发旁路）；README 索引未改动。
- 不确定项：① Crossgen2 nupkg 未内置（43,792,647 / `6bb8a375…`，folder-feed 见引用文件）；② 预签仅 tester UDID 直装；③ 包内 docs 为 kit #54 波次快照（sha 绑定 `SHA256SUMS`）；④ 子窗 HLS 未单独取景 / 弹窗无托管 MediaElement 映射（设计内）；
  ⑤ 人工卡（子窗 IME 实键盘）与 Back 平台边界按 UITEST-INJECT 口径；⑥ modal overlay 像素与容量 8 / 默认 4 的真机证据引用各卡（MODAL-OVERLAY-FIX / E4-CAPACITY8 / SUBWINDOW-DEFAULT4），测试方按包内判定点复核。
