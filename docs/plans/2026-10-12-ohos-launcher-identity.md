# LAUNCHER-IDENTITY：kit 打包 identity 三连（V2 index + 解析 id + STORED 保持）与 INTERNET 默认（2026-10-12/13）

> 结论：ow 打包链补齐 MAIL-LESSONS E 的缺二（V2 index、labelId/iconId）+ A（INTERNET 默认）。ow 分支
> `fix/launcher-identity`（`8a48a91`，10 文件 +536/−117）→ ff master。真机 HAD-W32 7.0.0.111/API 26：
> 卸载+重装后 `bm dump` `labelId=16777217/iconId=16777231`（原 0/0）、app center 显示 **`hello-maui-app` +
> 自带 64×64 图标**（同一截图坏件对照 `hellomauirazor` 仍显示 bundle 名 + 平台默认拼图图标）、主窗
> `canvas presented (2091x1324)` 全样例 UI、0 fault；INTERNET 已声明且 `atm dump` grantStatus=0(granted)。
> api20 band 真机装不上（9568297；kit54 旧件 re-sign 同败 → 镜像级收紧，非本改）。#49–#54 资产未动、无上游 PR。
> 提交：ow `fix/launcher-identity` → master（HTTP/1.1 直推）；本文 + README 索引 → runtime（commit-paths 限路径）。

## ① V2 resources.index（minAPIVersion 抬高）
- `OpenHarmonyMinApiVersion` 设备带默认 `50002014` → `60000020`（本机 restool 26.0.0.18_2 阈值复现：60000019 仍 `Restool 6`（V1）、60000020 起 `RestoolV2`；api20 band 本已 V2）；targets 编译后断言 `RestoolV2`，低于阈值 fail-closed 并指向 min 覆盖值。四包 22/23/24/28 同步（quartet 字节一致契约保持）。
- 证据：kit 5 hap `resources.index 2102 B / RestoolV2`（原 26.0 件 1894 B V1、api20 件 2102 B V2）。

## ② 解析 id 注入（DevEco PackageHap 等价）
- restool 以 staged module.json 编译时同出 **id 解析版 module.json**（app labelId/iconId、module.descriptionId、ability labelId/iconId/descriptionId/startWindow*Id）；targets 打包前用它替换 staged 件，缺失 fail-closed。
- Blazor host（hvigor 链，pack-host.sh）：保留 hvigor `ids`/`definedIds` 表、去 `compression`、坐标抬到 V2 下限后重跑 restool，并断言 `RestoolV2`。
- 证据：kit 5 hap `app labelId=16777218/iconId=16777231`；T11 fixture 断言全部 id 字段 >0 且与 index 同源。

## ③ STORED / 无目录条目（保持）
- 原 `ohos_packing_tool` 链已满足；**T11 新断言** `resources.index`+`resources/**` 全部 STORED、0 目录条目（坏件缓存字节级根因）。

## ④ INTERNET 默认（A）
- `OpenHarmonyFeatures` 空值默认 = `network`（`$string:permission_reason_internet` + usedScene）；`-p:OpenHarmonyFeatures=none` 显式退出；`make-device-test-kit` 新增 `check_internet()` 门禁（4 MAUI hap；Blazor 件走 hvigor 链除外）。
- 证据：真机 `bm dump` reqPermissions=[INTERNET] reason+usedScene；`atm dump -t -b` INTERNET grantStatus=0/grantFlag=4（system_grant 装机即授）。

## ⑤ selftest / 验证
- selftest-hap-targets **90/0**（T5 默认 network + none 哨兵 + raw-extra；新 **T11** 走真 restool/打包 fixture）、selftest-verify-kit **135/0**（新 S17：legacy V1 index / 缺 id 均 FAIL）、selftest-tasks 9/0、make-device-test-kit 52/0；verify-kit 2b 新增 `RestoolV2` 头 + 解析 id 断言（S17 红控覆盖）。
- kit 构建（worktree、`DOTNET=~/.dotnet.rc2-fix`、一次、AOT 4+1 hap）→ `verify-kit` KIT OK **0 FAIL/0 WARN**；真机轮 00:35–00:43 互斥锁内（卸载+重装、bm/atm/app-center 布局 dump+截图/hilog/主窗；锁已释放，末态=修好的 26.0 hap 在场、app 停止）。

## ⑥ 边界 / 供 #55
- api20 band 在该镜像装不上（9568297 "older sdk version"；旧件同败 = 镜像级；对照改用 host 侧 V2+id 证据）；#55 需要 api20 真机对照时先抬 target/compileSdk 或降设备。
- INTERNET 默认：**abc 不变**；权限矩阵 +1（默认件 1 项，权限件 6 项）→ #55 tester 文档权限表随动。
- 并发 PASTEBOARD-FIX（ow `fix/pasteboard` `faab198`，未并 master）同改 targets/selftest/verify-kit/docs：与本分支合并需人工对账（本分支不含其 READBOARD/clipboard 变更）；两分支同源于 `6addaba`，先并者 ff、后并者需 merge 解冲突。
