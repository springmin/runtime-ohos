# 测试方一轮交付包（tester-round-kit51.tar.gz）：kit #51 单件聚合（2026-10-07）

> 用途：把「一轮设备测试」的取件 → 校验 → 重签 → 一条命令 → 判定点索引 → 回传清单固化成单件资产，减少多资产对照成本。
> 本页只记录包本身（来源/指纹/成员/发布/复核），判定内容与数字一律指向被聚合的原文（handoff-kit51 / L2-CONSOLIDATE /
> handoff-kit50 / L2-a11y / L2-ArkWeb / L2CAP / SEC-SCAN-6；§2 列名）。纪律：**只聚合、不重打包**——外部件逐件与 release sidecar 比对后按原字节复制；既有资产未改（仅新增 2 项 + body 一行）。

## 1. 发布与指纹

- release：`springmin/sdk-ohos` tag **`device-test-kit`**（database id 392356147）；新资产（2026-10-07）：
  - `tester-round-kit51.tar.gz`：asset **617151248**，**157,211,898 B**，sha256 `ff882ac3015e696922526108b12214cfe7ac31a858478df2f3c2f36a966fb610`；
  - `tester-round-kit51.tar.gz.sha256`：asset **617152631**，92 B（文件 sha `fa007b6b…`）。
- **by-id 复核**：按 asset id 回读下载 → tar 大小/sha256 与本地一致、sidecar `cmp` 一致；零改动清单 = 新增这 2 项（56 件既有资产 0 变化）。
- 包内顶层 `tester-round-kit51/`；`SHA256SUMS` 27 行（`sha256sum -c` 27/27 OK，解包复跑 27/27）；kit 深度自检 `verify-kit.sh` → KIT OK（裸跑与 `--expected-abc 473048` 皆绿；脚本 76,707 B / `33bc35c8…`）；入口 `README-一轮上手.md`（#51 全指纹、`app://subwindow/openweb` child web 链/`demo`、W0/W2 a11y 自检、容量探针 255、IME 人工卡、参数提示 #51=473048 / #50=436808 / #49=414532、CI 链接）。

## 2. 成员（27 件 + `SHA256SUMS`；来源 → 包内路径）

- kit #51（**68,550,333 / `e5f6541c…`**、树 `a06d3897…`、sidecar `5c471871…`）+ #51 预签（**68,447,288 / `e9fb1e90…`**，asset 617093322、sidecar `96948b04…`，asset 617094016）→ `assets/`（含 sidecar）；
- 解释器 rc2b（`59744305…` + `519b459e…` + README `0141b224…`）、AOT v3 rc2（`3d24f716…` + `f51e2a04…` + README `05f9accb…`）、Crossgen2 rc.2 `SHA256SUMS`（`d88a7551…`；nupkg 未内置）→ `assets/`；
- 11 份判定/证据文档（handoff-kit51 `93d442f8…` / L2-CONSOLIDATE `7aa886bd…` / handoff-kit50 `936ce2a8…` / retest-taskcard `037d2428…` / platform-limitations `5a79b9e0…` / device-round-script `7bd0d721…` / multiwindow-l-m4 `acc0d69e…` / l2-a11y-provider `5cedb117…` / l2-arkweb-subwindow `d71a14dc…` / l2-subwindow-capacity-probe `792188d9…` / security-scan-6 `801ff7fb…`）→ `docs/`；
- `device-round.sh`（`4d59ed00…`）/ `sign-for-device.sh`（`fa93f542…`）+ `scripts/README.md`（`b32b6835…`）→ `scripts/`。

## 3. 用法（3 步）

```sh
# 1) 下载校验（外层 sidecar + 包内 SHA256SUMS）
sha256sum -c tester-round-kit51.tar.gz.sha256 && tar xzf tester-round-kit51.tar.gz && cd tester-round-kit51 && sha256sum -c SHA256SUMS
# 2) kit 深度自检：裸跑即绿（默认已重锚 473048,24324）；显式锁定用 --expected-abc 473048（#50 包 436808、#49 包 414532）
mkdir -p kit && tar xzf assets/device-test-kit.tar.gz -C kit && (cd kit && sh verify-kit.sh --expected-abc 473048)
# 3) 一条命令真机轮（预签 UDID 可直装跳过重签；先 --dry-run 彩排）
sh scripts/device-round.sh --kit assets/device-test-kit.tar.gz --suite --out ./round-report \
    --expect-tree-digest a06d3897507981c104b0a62618bf8c244518c1735ba9b31780695d3f0bce8843
```

- 预签直装：解 `assets/preSigned-haps.tar.gz` → 包内 `sha256sum -c SHA256SUMS`（8/8）→ `hdc install -r`；非 tester UDID 报 `9568344` 回传代签；Crossgen2 nupkg 未内置（43,792,647 / `6bb8a375…`），folder-feed 见引用文件。

## 4. 复核与不确定项

- 源件：kit/预签/解释器/AOT/Crossgen2 逐件 sha256 与 release sidecar 一致；#48/#49/#50 聚合包保留未动；打包/发布后 27/27、解包复跑 27/27、外层 sidecar OK、by-id 回读一致（56 件既有资产 0 变化）；dtk release body 追加 1 行（162→163，仅追加）。
- 交付顺序如实记录：先按仓库 kit51 文档提交（`7f722f20264`）前的快照打包上传，随后以最终快照重建并删除/重发本轮自有 2 项（新 asset id），body 行同位置更新为最终指纹——相对原始 body 仍 +1 行。
- 不确定项：① Crossgen2 nupkg 未内置；② 预签仅 tester UDID 直装；③ 包内 docs 为 kit #51 交接轮快照（sha 已绑定 `SHA256SUMS`，仓库后续提交可能前移）；④ L2CAP 255 为交付方 2in1 debug 观测（非测试方复跑项）；⑤ 降级声明（a11y 动作平台限、hybrid/blazor 拒绝、IME 人工卡、池满/队列边界、SEC-6 余留）为明示项，不判失败。
