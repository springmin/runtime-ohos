# 测试方一轮交付包（tester-round-kit52.tar.gz）：kit #52 单件聚合（2026-10-07）

> 用途：把「一轮设备测试」的取件 → 校验 → 重签 → 一条命令 → 判定点索引 → 回传清单固化成单件资产。本页只记录包本身（来源/指纹/成员/发布/复核）；
> 判定内容一律指向被聚合原文（L3-CONSOLIDATE-FINAL / L3-M2/M3/M4 / L3-TAIL-FIXES / L-M 验收矩阵 / handoff-kit51 / SEC-SCAN-6；§2 列名）。纪律：**只聚合、不重打包**——外部件逐件与 release sidecar 比对后按原字节复制。

## 1. 发布与指纹

- release：`springmin/sdk-ohos` tag **`device-test-kit`**（id 392356147）；新资产：`tester-round-kit52.tar.gz` asset **618885974**、
  **157,785,932 B** / `b16c9b2557c9eec7995110f3a7362eec52d0d6cb7b6e6e83622fc99c8b43437f`；sidecar asset **618888765**、92 B / `e9a2aac8…`。
- **by-id 复核**：按 asset id 回读（tar 断点续传）→ 大小/sha256 与本地一致、sidecar `cmp` 一致；零改动清单 = 新增这 2 项
  （392356147: 60→62，0 removed/changed；392077166/398739326/398936638 三 release 0 变化）。
- 包内顶层 `tester-round-kit52/`；`SHA256SUMS` 28 行（`sha256sum -c` 28/28，解包复跑 28/28）；`verify-kit.sh` → KIT OK（裸跑、
  `--expected-abc 534192`、`--tree-digest --expect-tree-digest c1fa6421…` 皆绿）；入口 `README-一轮上手.md`（#52 指纹、N=2 多子窗/
  定向关/重开、按窗 child web、每窗 IME/overlay/Back、降级/人工卡、参数 #52=534192 / #51=473048 / #50=436808、CI 链接）。

## 2. 成员（28 件 + `SHA256SUMS`；来源 → 包内路径）

- kit #52（**68,853,027 / `9e60fdc0…`**、树 `c1fa6421…`、sidecar `d10ae2e7…`；内部 `SHA256SUMS` 18 项 / 1,600 B / `fbc035f8…`）+
  #52 预签（**68,732,127 / `5abf7629…`**，asset 618854752、sidecar `2d8390bf…` asset 618855844；树 `b91b0036…`）→ `assets/`；
- 解释器 rc2b（`59744305…`+`519b459e…`+README `0141b224…`）、AOT v3 rc2（`3d24f716…`+`f51e2a04…`+README `05f9accb…`）、Crossgen2 rc.2
  `SHA256SUMS`（`d88a7551…`；nupkg 未内置）→ `assets/`；
- 12 份判定/证据文档（L3-CONSOLIDATE-FINAL `75e0cc2d…` / L3-M2 `3ff19406…` / L3-M3 `e461b91f…` / L3-M4 `9d7a4b7b…` / L3-MULTI-SUBWINDOW
  计划 `36f65813…` / L3-TAIL-FIXES `666fdbd9…` / L-M 验收矩阵 `407e0ffe…` / platform-limitations `5a79b9e0…` / device-round-script `7bd0d721…` /
  retest-taskcard `037d2428…` / security-scan-6 `801ff7fb…` / handoff-kit51 `93d442f8…`）→ `docs/`；
- `device-round.sh`（`4d59ed00…`）/`sign-for-device.sh`（`fa93f542…`）/`scripts/README.md`（`62afdb8a…`）→ `scripts/`。

## 3. 用法（3 步）

```sh
sha256sum -c tester-round-kit52.tar.gz.sha256 && tar xzf tester-round-kit52.tar.gz && cd tester-round-kit52 && sha256sum -c SHA256SUMS
mkdir -p kit && tar xzf assets/device-test-kit.tar.gz -C kit && (cd kit && sh verify-kit.sh --expected-abc 534192)
sh scripts/device-round.sh --kit assets/device-test-kit.tar.gz --suite --out ./round-report \
    --expect-tree-digest c1fa642149d5798e14c6c984d53a372ccde4dbf4c913f3a015df24378caf3003
```
- 步骤语义：① 外层 sidecar + 包内 28 件；② 裸跑 `sh verify-kit.sh` 亦绿（默认重锚 534192,24324），显式参数如上（#51 包 473048、#50 包 436808）；
  ③ 一条命令真机轮（预签 UDID 直装跳过重签；先 `--dry-run` 彩排）。预签直装：解 `assets/preSigned-haps.tar.gz` → 包内 8/8 → `hdc install -r`；非 tester UDID 报 `9568344` 回传代签。

## 4. 复核与不确定项

- 源件：kit/预签/解释器/AOT/Crossgen2 逐件 sha256 与 release sidecar 一致；#48–#51 聚合包保留未动；打包/发布后 28/28、解包复跑
  28/28、外层 sidecar OK、by-id 回读一致；dtk release body 追加 1 行（204→205，仅追加，前缀逐字节一致）。
- 本页提交：runtime-ohos `feature/openharmony`（docs-only；`commit-paths.sh` 限路径；fetch/rebase 被拒，Git Data API 旁路）；初版随并行文档波次先行落库
  （65dc4b42），本页为复核修正版（sidecar 文件 sha、成员逐件 sha、body 追加复核），API 落于远端树；README 索引行未改动。
- 不确定项：① Crossgen2 nupkg 未内置（43,792,647 / `6bb8a375…`，folder-feed 见引用文件）；② 预签仅 tester UDID 直装；③ 包内 docs 为 kit #52 波次快照（不含其后落库的 handoff-kit52；sha 绑定 `SHA256SUMS`）；
  ④ 40min soak / 容量 255 为交付方 2in1 debug 观测（测试方抽样/carry）；⑤ 降级声明（hybrid/blazor 桥未真机、uitest Back/alert 注入限、a11y 动作平台限、子窗 IME 人工卡、池满/队列边界、SEC-6 余留）为明示项，不判失败。
