# 测试方一轮交付包（tester-round-kit50.tar.gz）：kit #50 单件聚合（2026-10-06）

> 用途：把「一轮设备测试」的取件 → 校验 → 重签 → 一条命令 → 判定点索引 → 回传清单固化成单件资产，减少多资产对照成本。
> 本页只记录包本身（来源/指纹/成员/发布/复核），判定内容与数字一律指向被聚合的原文（handoff-kit50 / retest-taskcard / platform-limitations / device-round-script / multiwindow-l-m4；§2 列名）。纪律：**只聚合、不重打包**——外部件逐件与 release sidecar 比对后按原字节复制；既有资产未改（仅新增两项 + body 一行）。

## 1. 发布与指纹

- release：`springmin/sdk-ohos` tag **`device-test-kit`**（database id 392356147）；新资产（2026-10-06）：
  - `tester-round-kit50.tar.gz`：asset **615575350**，**156,614,426 B**，sha256 `950c1e040e2666bc3001125330afb2c0d754d43b5e6676c0570f1bb26a193de6`；
  - `tester-round-kit50.tar.gz.sha256`：asset **615577418**，92 B（文件 sha `9465d30a…`）。
- **by-id 复核**：按 asset id 回读下载 → tar 大小/sha256 与本地一致、sidecar `cmp` 一致；零改动清单 = 新增这 2 项（52 件既有资产 0 变化）。
- 包内顶层 `tester-round-kit50/`；`SHA256SUMS` 21 行（`sha256sum -c` 21/21 OK，解包复跑 21/21）；kit 深度自检 `verify-kit.sh` → KIT OK 0 FAIL/0 WARN
  （裸跑与 `--expected-abc 436808` 皆绿）；入口 `README-一轮上手.md`（89 行；#50 全指纹、`app://subwindow/open`/`demo`、IME 人工卡、verify-kit 参数提示、CI 链接）。

## 2. 成员（21 件 + `SHA256SUMS`；来源 → 包内路径）

- kit #50（**68,264,136 / `d70dc786…`**、树 `b4b5055c…`、sidecar `2ffb3b6a…`）+ #50 预签（**68,157,557 /
  `028d29f4…`**，asset 615517779、sidecar `02397318…`，asset 615518466）→ `assets/`（含 sidecar）；
- 解释器 rc2b（`59744305…` + `519b459e…` + README `0141b224…`）、AOT v3 rc2（`3d24f716…` + `f51e2a04…` +
  README `05f9accb…`）、Crossgen2 rc.2 `SHA256SUMS`（`d88a7551…`；nupkg 未内置）→ `assets/`；
- 5 份判定/证据文档（handoff-kit50 `936ce2a8…` / retest-taskcard `037d2428…` / platform-limitations `38a8cb85…` / device-round-script `7bd0d721…` / multiwindow-l-m4 `acc0d69e…`）→ `docs/`；
- `device-round.sh`（`4d59ed00…`）/ `sign-for-device.sh`（`fa93f542…`）+ `scripts/README.md` → `scripts/`。

## 3. 用法（3 步）

```sh
# 1) 下载校验（外层 sidecar + 包内 SHA256SUMS）
sha256sum -c tester-round-kit50.tar.gz.sha256 && tar xzf tester-round-kit50.tar.gz && cd tester-round-kit50 && sha256sum -c SHA256SUMS
# 2) kit 深度自检：裸跑即绿（默认已重锚 436808,24324）；显式锁定用 --expected-abc 436808（#49 包仍 414532）
mkdir -p kit && tar xzf assets/device-test-kit.tar.gz -C kit && (cd kit && sh verify-kit.sh --expected-abc 436808)
# 3) 一条命令真机轮（预签 UDID 可直装跳过重签；先 --dry-run 彩排）
sh scripts/device-round.sh --kit assets/device-test-kit.tar.gz --suite --out ./round-report \
    --expect-tree-digest b4b5055c34978514a5c1ca45a065ca11d078ffcf3bc687648c6efbace0b10b11
```

- 预签直装：解 `assets/preSigned-haps.tar.gz` → 包内 `sha256sum -c SHA256SUMS`（8/8）→ `hdc install -r`；非 tester
  UDID 报 `9568344` 回传代签；Crossgen2 nupkg 未内置（43,792,647 / `6bb8a375…`），folder-feed 见引用文件。

## 4. 复核与不确定项

- 源件：kit/预签/解释器/AOT/Crossgen2 逐件 sha256 与 release sidecar 一致、sidecar `cmp` 一致；#48/#49 聚合包新名保留未动；
  打包/发布后 21/21、解包复跑 21/21、外层 sidecar OK、by-id 回读一致（52 件既有资产 0 变化）；dtk release body 追加 1 行（116→117，仅追加）。
- 不确定项：① Crossgen2 nupkg 未内置；② 预签仅 tester UDID 直装；③ 包内 docs 为 kit #50 交接轮快照（sha 已绑定 `SHA256SUMS`，仓库后续提交可能前移）；
  ④ 裸跑已绿（默认重锚 436808），任务口径的显式 `--expected-abc 436808` 同验；⑤ 平台级多子窗上限/子窗 IME 实敲属 #50 降级/人工卡，非本包缺陷。
