# PRE55-INTEGRATION：最终 master 端到端整合（安装位重同步 + 合并树样例 + 真机轮 + #55 锚）（2026-10-13）

> 目标：把 LAUNCHER-IDENTITY（`8a48a91`）+ PASTEBOARD-FIX（merge `15237a5`）并入后的 ow `master fa21a1a` 做成一次完整核对——两安装位 pack 重同步（此前为两分支轮残留混合态）、hello-maui 样例默认/`all` 合并树构建 + 离线断言、真机整合轮（互斥锁独占）。#49–#54 资产未动、无上游 PR；一次一构建。载体 = scratch `/data/storage/el2/base/tmp/opencode/pre55-integration/`（fp/cmp/sync/gate/round 脚本与日志）。

## ① 安装位重同步（install == repo，fail-closed）

- repo 侧确认（最终 master 完整构建件）：四包 targets = 并集（`READ_PASTEBOARD` 撤出 + `<Acl>` 跳过 + `RestoolV2`/解析 id 替换）；tasks dll `dfa3a085`（== `src/.../bin/Release` 新鲜构建；selftest-tasks S3 在 `fa21a1a` 绿）；abc `c473b7be/620,908`（四包 provenance 源哈希逐一核对）；host `8826adde`（PASTEBOARD 重建、含 NDK 读符号；164/164 导出）。
- 同步前（两分支轮混合态）：`~/.dotnet` = LAUNCHER targets `03c2bc44` + 旧 tasks `93db9653`；`~/.dotnet.rc2-fix` = PASTEBOARD targets `35353bab`（tasks 已新）。
- 同步（repo→两安装，写入前后逐文件 sha256 校验）：targets `03c2bc44`/`35353bab` → **`90e45a6c`**（两安装）；tasks `93db9653` → **`dfa3a085`**（`~/.dotnet`）。
- 指纹（7 family 全量：SDK preview.28 + 6 Ref/Runtime/BCL，573–579 件/根）：同步前 payload diff **2 / 1**，同步后 **0 / 0**（两安装互差 0）；余 18/20 条已知元数据（`*.nupkg`、生成 nuspec、容器件）。
- 门禁：canonical cut-kit P0 `p0_install_pack`（自 ow `fa21a1a` 脚本抽出、语义未改）对两安装各绿（7 SDK + 20 RRB 关键件）；红控（分别篡改 tasks、abc 复制）**rc=1 fail-closed**。日志 `gate-p0-dotnet/rc2fix.log`、`gate-p0-redcontrol.log`。

## ② 合并树样例构建（hello-maui-app，JIT/非 AOT）

- 默认特征：`-p:OpenHarmonyUIPage=pages/Index`；`all` 特征：+ `-p:OpenHarmonyFeatures=all -p:ClipboardProbe=true`。各一件 hap（`make-mode-kit.sh`，两次顺序构建；首次漏 `OpenHarmonyUIPage` 出 headless 壳，复核后重编 ui 壳，旧件留 scratch `*-headless-mistake/`）。
- 产物（自签名）：default `8ac15de2…` / all `4b0effc7…`；设备重签（sign-for-device，UDID `1BCE13C8…`，verify-app 绿）：`37c7a09e…` / `6a628964…`。
- 离线断言（verify-kit 2b 等效 `assert-hap.py`）双绿：RestoolV2 index（2,102 B）· app/ability 解析 id 全 >0（labelId 16777218 / iconId 16777231，minAPI 60000020）· `resources.index`+`resources/**` 全 STORED、0 目录条目 · 权限 = 默认 1（INTERNET + reason/usedScene）/ `all` = 8 非 ACL · abc `620908`/13.0.1.0。

## ③ 真机整合轮（HAD-W32 7.0.0.111 / API 26；互斥锁独占，`round.sh` rc=0）

- 卸载+装默认 rc=0 → bm `labelId=16777217 iconId=16777231`、1 权限；叠装 `all` **rc=0** → 8 权限（INTERNET/PRINT granted；无 READ_CONTACTS/READ_PASTEBOARD）。
- launcher/桌面：开始菜单（dock hoskey）`layout-startmenu.json` + `startmenu.jpeg` 均含 `hello-maui-app`（自带蓝色图标，非默认拼图）。
- 主窗 `canvas presented 2090×1324`（n≈300、avg 16–17 ms）；clipboard：write OK（服务 `SetPasteData`）/ read 恒 null + 服务 `GetPasteDataInner# check permission failed`（ACL，与 PASTEBOARD 结论一致）；fault diff=0。
- 末态：合并树修好件（`all`）在场、app 停止、hilog 512K 还原、锁释放（`round/round.log`、`hilog.txt`、`bm-*.json`）。

## ④ #55 锚 / runbook / 收尾

- `2026-10-06-ohos-rc2-align-runbook.md` 刷新：基线 `fa21a1a`、abc 620,908/`c473b7be`、矩阵 1/6/8、套件 801/804 floor 784、宿主 `8826adde`、api20 镜像级边界（9568297）、clipboard 真读=ACL profile/用户粘贴（产品决策）、loopback/Asset 待定项（指向 MAIL-LESSONS，不重写）。
- ow 主树回 `master`（clean，无收尾提交）；删已并本地分支 `fix/pasteboard`、`fix/launcher-identity`（保留 `feat/l8-popup-probe`、`fix/media-residuals`、`fix/webauth-decouple`、`tooling/*`；`bundle-retest` worktree 未动）。

## 不确定项

- `bm dump` applicationInfo.labelId=16777217 vs packed module.json 16777218（系统资源表再解析差 1；两者 >0，launcher 渲染正常）。
- 两安装 4 个旧 `*.nupkg` 等元数据差异属已知边界（workload 安装不回读它们）。
- app-drawer 的智能坞按钮会随运行应用重排，本轮 launcher 取证改用开始菜单（hoskey）面板；`all` hap 的 ClipboardProbe 为样例探针 opt-in，不产生产品权限。
