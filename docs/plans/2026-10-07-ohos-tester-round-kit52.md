# 测试方一轮交付包（tester-round-kit52.tar.gz）：kit #52 单件聚合（2026-10-07）

> 用途：把「一轮设备测试」的取件 → 校验 → 重签 → 一条命令 → 判定点索引 → 回传清单固化成单件资产，减少多资产对照成本。
> 本页只记录包本身（来源/指纹/成员/发布/复核），判定内容与数字一律指向被聚合的原文（handoff-kit52 / L3 各文 / 承 #51 卡片）。
> 纪律：**只聚合、不重打包**——外部件逐件与 release sidecar 比对后按原字节复制；既有资产未改（仅新增 2 项 + body 一行）。

## 1. 发布与指纹

- release：`springmin/sdk-ohos` tag **`device-test-kit`**；新资产（2026-10-07）：
  - `tester-round-kit52.tar.gz`：asset **618885974**，**157,785,932 B**，sha256 `b16c9b25…`（完整值以 release 边车为准）；
  - `tester-round-kit52.tar.gz.sha256`：asset **618888765**，92 B（文件 sha `b16c9b25…`）。
- **by-id 复核**：按 asset id 回读下载 → tar 大小/sha256 与本地一致、sidecar `cmp` 一致；零改动清单 = 新增这 2 项（既有资产 0 变化）。
- 包内顶层 `tester-round-kit52/`；`SHA256SUMS` 28 行（sha 自检 28/28）；kit 深度自检 `verify-kit.sh` → KIT OK（裸跑与 `--expected-abc 534192` 皆绿）；入口 `README-一轮上手.md`（#52 全指纹与判定点、参数提示 #52=534192 / #51=473048 / #50=436808 / #49=414532；以包内为准）。

## 2. 成员（28 件 + `SHA256SUMS`；来源 → 包内路径，明细以包内 `SHA256SUMS` 与 release body 为准）

- kit #52（**68,853,027 / `9e60fdc0…`**、树 `c1fa6421…`、sidecar `d10ae2e7…`）+ #52 预签（**68,732,127 / `5abf7629…`**，asset 618854752、sidecar `2d8390bf…`，asset 618855844）→ `assets/`（含 sidecar）；
- 解释器 rc2b（2,410,595 / `59744305…`，asset 606999003）、AOT v3 rc2（18,185,012 / `3d24f716…`，dtk 599996905）、Crossgen2 rc.2 `SHA256SUMS`（43,792,647 / `6bb8a375…`；nupkg 未内置）→ `assets/`；
- 判定/证据文档（L3 各文 + 承 #51 卡片；随包快照，以包内 sha 为准）→ `docs/`；
- `device-round.sh` / `sign-for-device.sh` + `scripts/README.md`（承 #51；sha 以包内 `SHA256SUMS` 为准）→ `scripts/`。

## 3. 用法（3 步）

```sh
# 1) 下载校验（外层 sidecar + 包内 SHA256SUMS）
sha256sum -c tester-round-kit52.tar.gz.sha256 && tar xzf tester-round-kit52.tar.gz && cd tester-round-kit52 && sha256sum -c SHA256SUMS
# 2) kit 深度自检：裸跑即绿（默认已重锚 534192,24324）；显式锁定用 --expected-abc 534192（#51 包 473048、#50 包 436808、#49 包 414532）
mkdir -p kit && tar xzf assets/device-test-kit.tar.gz -C kit && (cd kit && sh verify-kit.sh --expected-abc 534192)
# 3) 一条命令真机轮（预签 UDID 可直装跳过重签；先 --dry-run 彩排）
sh scripts/device-round.sh --kit assets/device-test-kit.tar.gz --suite --out ./round-report \
    --expect-tree-digest c1fa642149d5798e14c6c984d53a372ccde4dbf4c913f3a015df24378caf3003
```

- 预签直装：解 `assets/preSigned-haps.tar.gz` → 包内 `sha256sum -c SHA256SUMS`（8/8）→ `hdc install -r`；非 tester UDID 报 `9568344` 回传代签；Crossgen2 nupkg 未内置（43,792,647 / `6bb8a375…`），folder-feed 见引用文件。

## 4. 复核与不确定项

- 源件：kit/预签/解释器/AOT/Crossgen2 逐件 sha256 与 release sidecar 一致；#51 聚合包保留未动；打包/发布后 28/28、外层 sidecar OK、by-id 回读一致。
- 不确定项：① 本页 tar sha256 为前缀（完整值以 release 边车与包内 `SHA256SUMS` 为准）；② Crossgen2 nupkg 未内置；③ 预签仅 tester UDID 直装；④ 包内 docs 为 L3/承 #51 快照（sha 已绑定 `SHA256SUMS`，仓库后续提交可能前移）；kit #52 交测的 runtime 侧 #52 块见 `2026-10-07-ohos-tester-handoff-kit52.md`；⑤ 降级/人工卡（a11y 动作平台限、hybrid/blazor 真机未抽验、IME 人工卡、池满/队列边界、SEC-6 余留、N=2 壳契约）为明示项，不判失败。
