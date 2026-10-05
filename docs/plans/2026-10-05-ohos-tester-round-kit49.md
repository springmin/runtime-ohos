# 测试方一轮交付包（tester-round-kit49.tar.gz）：kit #49 单件聚合（2026-10-05）

> 用途：把「一轮设备测试」的取件 → 校验 → 重签 → 一条命令 → 判定点索引 → 回传清单固化成单件资产，减少测试方
> 在多资产间的对照成本。本页只记录包本身（来源/指纹/成员/发布/复核），判定内容与数字一律指向被聚合的原文
> （`2026-10-05-ohos-tester-handoff-kit49.md` / `2026-09-28-ohos-retest-taskcard.md` /
> `2026-10-05-ohos-platform-limitations.md` / `2026-10-05-ohos-device-round-script.md`）。纪律：**只聚合、不重打包**——外部件逐件与 release sidecar 比对后按原字节复制；既有资产未改（仅新增两项 + body 一行）。

## 1. 发布与指纹

- release：`springmin/sdk-ohos` tag **`device-test-kit`**（database id 392356147）；新资产（2026-10-05）：
  - `tester-round-kit49.tar.gz`：asset **613320136**，**155,893,607 B**，sha256 `6b9712efa8093c2e73fe80661edb468dae6466e2248c2a95d9aa30b549409379`；
  - `tester-round-kit49.tar.gz.sha256`：asset **613322973**，92 B（文件 sha `c62c09d2…`）。
- **by-id 复核**：按 asset id 回读下载 → tar 大小/`sha256` 与本地一致、sidecar `cmp` 一致；零改动 = 新增这 2 项。
- 包内顶层 `tester-round-kit49/`；`SHA256SUMS` 20 行（`sha256sum -c` 20/20 OK，解包复跑 20/20）；入口
  `README-一轮上手.md` 74 行（tar/tree/bundle/锚/预签指纹、`app://subwindow/demo`、`--expected-abc 414532`、CI 链接）。

## 2. 成员（20 件 + `SHA256SUMS`；来源 → 包内路径）

- kit #49（**67,888,851 / `477974bb…`**、树 `8d03cb4c…`、sidecar `3803b3db…`）+ #49 预签（**67,807,185 /
  `56aaf08f…`**，asset 612929512、sidecar `4ba00cf8…`）→ `assets/`（含 sidecar）；
- 解释器 rc2b（`5974430509…` + `519b459e…` + README `0141b224…`）、AOT v3 rc2（`3d24f716…` + `f51e2a04…` +
  README `05f9accb…`）、Crossgen2 rc.2 `SHA256SUMS`（`d88a7551…`；nupkg 未内置）→ `assets/`；
- 4 份判定文档（handoff-kit49 / retest-taskcard / platform-limitations / device-round-script）→ `docs/`；
- `device-round.sh`（`4d59ed00…`）/ `sign-for-device.sh`（`fa93f542…`）+ `scripts/README.md` → `scripts/`。

## 3. 用法（3 步）

```sh
# 1) 下载校验（外层 sidecar + 包内 SHA256SUMS）
sha256sum -c tester-round-kit49.tar.gz.sha256 && tar xzf tester-round-kit49.tar.gz && cd tester-round-kit49 && sha256sum -c SHA256SUMS
# 2) kit 深度自检：须显式 --expected-abc 414532（包内默认仍 #48 的 375268，裸跑 5 条历史 WARN 不阻断）
mkdir -p kit && tar xzf assets/device-test-kit.tar.gz -C kit && (cd kit && sh verify-kit.sh --expected-abc 414532)
# 3) 一条命令真机轮（预签 UDID 可直装跳过重签；先 --dry-run 彩排）
sh scripts/device-round.sh --kit assets/device-test-kit.tar.gz --suite --out ./round-report \
    --expect-tree-digest 8d03cb4c928ec9bac7b29d83c0192791da6d5837698d39d588a13512c5cb6b2c
```

- 预签直装：解 `assets/preSigned-haps.tar.gz` → 包内 `sha256sum -c SHA256SUMS`（8/8）→ `hdc install -r`；非 tester
  UDID 报 `9568344` 回传代签；Crossgen2 nupkg 未内置（43,792,647 / `6bb8a375…`），folder-feed 见引用文件。

## 4. 复核与不确定项

- 源件：四件 sha256 与 release sidecar 逐件一致、sidecar `cmp` 一致；#48 包新名保留未动；打包/发布后 20/20、
  解包复跑 20/20、外层 sidecar OK、by-id 回读一致（46 件既有资产 0 变化）。不确定项：① Crossgen2 nupkg 未内置；
  ② 预签仅 tester UDID 直装；③ 包内为当前提交时点快照；④ `verify-kit.sh` 默认 abc 未重锚（下一 kit 生效）。
