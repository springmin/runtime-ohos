# 测试方一轮交付包（tester-round-kit48.tar.gz）：kit #48 单件聚合（2026-10-05）

> 用途：把「一轮设备测试」的取件 → 校验 → 签名/重签 → 一条命令执行 → 判定点索引 → 回传清单
> 固化成单件资产 `tester-round-kit48.tar.gz`，减少测试方在多资产间的对照成本。本页只记录包本身
> （来源、指纹、成员、发布与复核）；判定内容与数字一律指向被聚合的原文
> （`2026-10-05-ohos-tester-handoff-kit48.md` / `2026-09-28-ohos-retest-taskcard.md` /
> `2026-10-05-ohos-platform-limitations.md` / `2026-10-05-ohos-device-round-script.md`）。
> 纪律：**只聚合、不重打包**——外部件（kit/预签/解释器/AOT）逐件与 release sidecar 比对后按原字节
> 复制；未改动 `device-test-kit` release 的既有资产内容（仅新增资产 + notes 一行）。

## 1. 发布与指纹

- release：`springmin/sdk-ohos` tag **`device-test-kit`**（database id 392356147）。
- 新资产（2026-10-05，notes 加一行）：
  - `tester-round-kit48.tar.gz`：asset **612145810**，**155,577,555 B**，
    sha256 `aa030d1fdf95572ac63d8a1bdb5f66fdd633113f1a06a6eebc79804d7a9c873e`；
  - `tester-round-kit48.tar.gz.sha256`：asset **612145811**，92 B。
- **by-id 复核**：按 asset id 回读下载 → tar 大小/`sha256` 与本地一致、sidecar `cmp` 一致。
- 包内顶层目录 `tester-round-kit48/`；成员 **20 件**（`SHA256SUMS` 20 行；`sha256sum -c` 20/20 OK，
  解包复跑 20/20 OK）；入口 `README-一轮上手.md` = **59 行**（≤60：下载→校验→签名/重签→device-round
  一条命令→判定点索引→回传清单）。

## 2. 成员（来源 → 包内路径 / sha256 前缀）

| 来源 | 包内路径 | sha256（前缀） |
|---|---|---|
| sdk-ohos `device-test-kit.tar.gz`（kit #48） | `assets/device-test-kit.tar.gz` | `5c22704f…`（release 值） |
| … sidecar | `assets/device-test-kit.tar.gz.sha256` | `1c51cdbc…` |
| sdk-ohos `preSigned-haps.tar.gz`（#48 预签） | `assets/preSigned-haps.tar.gz` | `2f2f4c40…` |
| … sidecar | `assets/preSigned-haps.tar.gz.sha256` | `50a1f38e…` |
| sdk-ohos `ohos-interpreter-pack-rc2b.tar.gz` | `assets/ohos-interpreter-pack-rc2b.tar.gz` | `5974430509…` |
| … sidecar + README | `assets/ohos-interpreter-pack-rc2b.tar.gz.sha256` / `…-README.md` | `519b459e…` / `0141b224…` |
| sdk-ohos `aot-haps-v3-rc2.tar.gz` | `assets/aot-haps-v3-rc2.tar.gz` | `3d24f716…` |
| … sidecar + README | `assets/aot-haps-v3-rc2.tar.gz.sha256` / `…-README.md` | `f51e2a04…` / `05f9accb…` |
| sdk-ohos `crossgen2-packs-11.0.0-rc.2` 的 `SHA256SUMS` | `assets/crossgen2-packs-11.0.0-rc.2.SHA256SUMS` | `d88a7551…` |
| 本页新增（Crossgen2 引用，nupkg 不入包） | `assets/crossgen2-packs-REFERENCE.md` | `65954306…` |
| runtime-ohos handoff #48 | `docs/2026-10-05-ohos-tester-handoff-kit48.md` | `afc43531…` |
| runtime-ohos 复测任务单（#48） | `docs/2026-09-28-ohos-retest-taskcard.md` | `5c806352…` |
| runtime-ohos 平台限制清单 | `docs/2026-10-05-ohos-platform-limitations.md` | `6d0426f6…` |
| runtime-ohos device-round 说明 | `docs/2026-10-05-ohos-device-round-script.md` | `7bd0d721…` |
| ohos-workload `scripts/device-round.sh`（`c42cfa43`） | `scripts/device-round.sh` | `4d59ed00…` |
| ohos-workload `scripts/sign-for-device.sh` | `scripts/sign-for-device.sh` | `fa93f542…` |
| 本页新增（用法） | `scripts/README.md` | `df244f76…` |
| 本页新增（入口） | `README-一轮上手.md` | `c4586b0e…` |

## 3. 用法（一行）

```sh
tar xzf tester-round-kit48.tar.gz && cd tester-round-kit48
sha256sum -c SHA256SUMS
sh scripts/device-round.sh --kit assets/device-test-kit.tar.gz --suite --out ./round-report \
    --expect-tree-digest 6b2b493c261ba089b0b14fd39319e832a25e989e75e9ebbbd02c31216c628160
```

- 预签直装（tester UDID `60CF7B27…`）：解 `assets/preSigned-haps.tar.gz` → 包内 `sha256sum -c SHA256SUMS`
  （8/8）→ `hdc install -r`；非该 UDID 报 `9568344`，回传 UDID 代签。
- Crossgen2 nupkg **未内置**（R2R 可选，43,792,647 / `6bb8a375…`），指纹、下载与 folder-feed 用法见
  `assets/crossgen2-packs-REFERENCE.md`；解释器轮由宿主置 `DOTNET_ReadyToRun=0`（FIXRR），不消费 R2R。

## 4. 复核记录与不确定项

- 源件复核：四个大件 sha256 与 release sidecar 逐件一致（kit `5c22704f…`、预签 `2f2f4c40…`、
  rc2b `5974430509…`、aot `3d24f716…`）；kit/预签 sidecar 本身与 release 下载件 `cmp` 一致。
- 打包后：`sha256sum -c SHA256SUMS` 20/20、解包目录复跑 20/20、外层 sidecar `sha256sum -c` OK；
  发布后按 asset id 回读：tar 155,577,555 B / sha 一致，sidecar 与本地一致。
- 不确定项：① Crossgen2 包未内置（引用文件）；② 预签件只在 tester UDID 上直装；③ 包内文档与脚本
  为提交 `75d49eefce1` 时点快照，编号/数字以 release 与原文为准；④ `device-round.sh` 默认锁目录
  `/data/storage/el2/base/tmp/opencode/.device-lock`，非交付机需 `DEVICE_ROUND_LOCK` 覆盖（已写入
  `scripts/README.md` 与入口 README）。
