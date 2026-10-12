# PASTEBOARD-FIX：剪贴板读改 host NDK + ACL 权限拆出矩阵/'all'（2026-10-12）

> 结论：**四包矩阵不再声明 READ_PASTEBOARD（clipboard 特征撤销），并新增 `<Acl>` 概念让 `all` 跳过 ACL 特征**（`contacts`/READ_CONTACTS 同 system_basic）——真机 `all`（8 权限）install rc=0。读路径移到 host pasteboard NDK；**服务侧仍按 ACL 拦 NDK 读**（`cmd 200: GetPasteDataInner# check permission failed`），mail 的「NDK 零权限可读」未复现（其读在用户 Ctrl+V 窗口内）；写路径零权限可用。
> 载体：ow `fix/pasteboard` `fa9916b` → merge **`15237a5`**（并 `8a48a91` LAUNCHER-IDENTITY（并发会话）入 `master`，两处冲突按并集解）；maui/pin 零改动（`44dcef8d15` 不变）。

## 1. 改动（ow `fa9916b`，45 文件）
- **矩阵**：四包 targets 去 `clipboard→READ_PASTEBOARD`（四包字节一致）；`all`=8 个非 ACL 权限；`clipboard` 不再是已知 id。
- **ACL 子集**：tasks CS（`<Acl>true</Acl>`）+ 单测 + 四包 `tools/*.Tasks.dll`；`all` 跳过并点名 ACL 特征；显式 `-p:OpenHarmonyFeatures=contacts` 仍声明 READ_CONTACTS + 安装风险告警。
- **host 读**：新纯 C `host_clipboard.{h,c}`（注入式 NDK 表、null/空语义、上限整条丢弃）；`host_optional.c` dlopen `libpasteboard.so`/`libudmf.so`；`openharmony_host.c` op0/1 本地应答、op2 走壳；`host-deps.conf` 禁直引；host .so 重建（164/164 导出、DT_NEEDED 白名单成立）。
- **壳**：`Index.ets` 删权限请求/缓存/读 helper，sink 只留 op2；`build-arkts-shell.sh` 源合同禁 READ_PASTEBOARD 字面量。
- **测试**：`selftest-host-clipboard.sh`（35 单测 + 变异红控，入 preflight）；tasks 单测 +2b ACL；T5（八权限/跳过点名/显式告警/clipboard unknown/默认 network 与 none 保留）；套件 clipboard pins（nd/matrix/shell=True，801/804 floor 784）；样例 `-p:ClipboardProbe=true`（`app://clipboard/*`）。
- **abc**：ui `623784/58c5829b`→`620908/c473b7be`（headless 24324 不变），四包 provenance/`verify-kit` EXPECT 随动。

## 2. 离线（绿）
`selftest-host-clipboard` 10 检查/35 单测；`selftest-hap-targets` **96/0**（合并树；本提交树 91/0）；`selftest-tasks` 9/0（178 单测）；`selftest-verify-kit` **135/0**（合并树）/129/0（本提交树）；`selftest-build-arkts-shell` 209/0；packs/host-* 同绿；套件 801/804。

## 3. 真机（HAD-W24，OH 7.0.0.111，锁独占）
- **`all` 装机**：rc=0（8 权限）；**红控**：ACL 子集前 `all` 因 `9568289 ... PermissionName: ohos.permission.READ_CONTACTS` 拒装。
- **读/写**：`app://clipboard/write`→服务 `SetPasteData rawDataSize=378`（写可用）；read/roundtrip → 服务 `GetPasteDataInner# check permission failed` → 托管 null（null/空语义保持）。
- 主窗零回归（`canvas presented 2091×1324`、framestats ≈57–60 fps）、fault diff=0、fixture `l7m2-s2` 回装、锁释放；#49–#54 资产未动。

## 4. 后续 / 不确定
- clipboard 真读需 ACL profile（`READ_PASTEBOARD`+system_basic 签名）或用户粘贴触发——产品决策；NDK 读封装已就位（获权即通）。
- launcher/`getStringSync` 桌面验收归 LAUNCHER-IDENTITY 会话（`8a48a91` 已入 master）。
