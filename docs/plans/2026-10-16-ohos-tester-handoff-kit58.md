# 测试方交接：kit #58（BUNDLE-SWITCH + TOUCH-PASTE-DEFAULT + SECURE-STORAGE-ASSET + CLIPBOARD-ACL）+ kit #57 全量（2026-10-16）

> 本页 = kit #58 的判定点与证据入口。kit #58 = **kit #57 全量（官方 rc.2 重切 `.105`/`.29` + 三卡）** 之上：
> **BUNDLE-SWITCH**（主 app / 样例 / 脚本 / 套件 / 五包壳 abc 全线切到 `mauidemo.dotnet.springmin.com` = AGC 应用 = 发布 Profile）、
> **TOUCH-PASTE-DEFAULT**（触屏粘贴默认开 + opt-out）、**SECURE-STORAGE-ASSET**（Asset Store 后端 + FailClosed 默认 true）、
> **CLIPBOARD-ACL**（`READ_PASTEBOARD` 改 Acl 标记特征，默认/all 不含）。
> 发布：`device-test-kit` release **392356147**（kit 资产已刷新）；bundle = **重打包**（承载 #58 壳/宿主/targets：
> abc 637,300 + host 375,712 + CLIPBOARD-ACL targets）`8772ef23…`，sdk-ohos 锚重锚 `def202206b`；
> **新增 release-signed 主 hap（免 UDID）随轮包**。
>
> 先读：`2026-10-14-ohos-tester-handoff-kit57.md`（三卡）与 `2026-10-14-ohos-tester-handoff-kit56.md`（#56 功能面判定点全部有效）；本页只列 **#58 增量**。

## 0. 一键执行（tester-run v14 不变；版本/大小以包内自述与 release 为准）

```sh
sh tester-run.sh --install --start --capture 30 --probes probes --kit-dir device-test-kit
# #58 主判点 1：BUNDLE-SWITCH——装机件 bundle = mauidemo.dotnet.springmin.com（新应用身份），壳 abc 637,300
# #58 主判点 2：TOUCH-PASTE-DEFAULT——触屏长按 Entry → 浮层默认出现（opt-out 才关）
# #58 主判点 3：SECURE-STORAGE-ASSET——SecureStorage 默认 FailClosed=true（Asset Store → HUKS 双强链）
# #58 主判点 4：CLIPBOARD-ACL——默认件/all 均不含 READ_PASTEBOARD（ACL 面以申请包为准）
# #58 主判点 5：release-signed 主 hap（免 UDID，轮包 assets/release-signed/）本镜像安装/启动接受性
# 承 #57 主判点：三卡按文本沿用（见 cards/）；承 #56：TOUCH-PASTE / WEBAUTH-LOOPBACK / SECURE-STORAGE-FAILCLOSED / launcher / clipboard / media / 子窗
# 门禁回归：sh verify-kit.sh → 0 FAIL/0 WARN；套件 826/829 floor 809；导出 167/167
```

## 0b. 预签直装（#34 起加发资产；**已刷新至 #58**）+ release-signed 主 hap（新）

- `preSigned-haps.tar.gz`（7 hap 按 tester UDID `60CF7B27…` 预签，`hdc install -r` 直装）：**70,256,405 B / `3dc2f08e…`**（asset 646181985）、sidecar **88 B / `e3788ce4…`**（asset 646183845）、tree `39db32fc…`；逐件原/新 sha 与安装命令见包内 `preSigned-README.md`（dtk release 392356147「预签直装」note 行同值）。**5 个 MAUI hap 的 bundle 已切 `mauidemo.dotnet.springmin.com`**（与旧 `com.example.hellomauiapp` 为独立应用身份）。
- **release-signed 主 hap（免 UDID）**：随 tester 轮包 `tester-round-kit58.tar.gz` 的 `assets/release-signed/hello-maui-app-unsigned-release.hap`（**23,773,854 B / `667e319b…`**；华为 AGC 发布链签名，`verify-app` 内建通过）；与预签主件同 bundle，**互斥**（先 `bm uninstall -n mauidemo.dotnet.springmin.com` 再装）。**真机实测（发布方补跑，HAD-W32 / OH 7.0.0.111）**：`hdc install -r` 被镜像拒绝 `code:9568322 signature verification failed due to not trusted app source`——**平台级发布源信任边界**（非市场渠道的 release 签名件在本镜像不接受；该设备未注册发布源）。**降级**：预签 debug 通道照旧为主安装路径；发布链接受性随 AGC 上架/信任链配置再评（记录于证据归档 `device/rs-boundary.txt`）。

## 1. kit #58 相对 #57 的增量（测试方视角）

| # | 变化 | 测试方看到什么 | 判定点 |
|---|---|---|---|
| 1.1 | **BUNDLE-SWITCH** | 5 MAUI hap / 样例 / 脚本默认 bundle = **`mauidemo.dotnet.springmin.com`**（AGC 应用 + 发布 Profile 同身份）；壳 abc `637,300（4070204a…）` / headless `24,340（944529ae…）`（`.22/.23/.24/.28/.29` 五包同源）；Blazor/razor/wasm 样例 bundle 保持 | 装机后 `bm dump -n mauidemo.dotnet.springmin.com` 可见；launcher 名称/图标/INTERNET 判据同 #55；`aa start -b mauidemo.dotnet.springmin.com -a EntryAbility` 起主件；旧 `com.example.hellomauiapp` 与新身份互不相干 |
| 1.2 | **TOUCH-PASTE-DEFAULT** | 触屏粘贴浮层**默认开**（壳 latch 默认 on）：长按 Entry → 浮层出现 → 点击 = 系统临时授予剪贴板读 → 文本落 Entry；**opt-out** = 沙箱标记 `filesDir/touch-paste.disabled` 或 `OHOS_TOUCH_PASTE=0`（pre-flip 的 opt-in 标记已废弃） | 默认件长按出浮层 + `pasted N chars`；opt-out 件 0 浮层；服务侧 `check permission failed` → 用户点击窗口内放行（沿 #56/#55 判据） |
| 1.3 | **SECURE-STORAGE-ASSET** | 新写入优先 **Asset Store**（`OH_Asset_*`，DEVICE_FIRST_UNLOCKED；数据文件 = 索引 `a1:`/`k1:`/明文，旧数据零迁移可读），HUKS `k1:` 二强链；**FailClosed 默认 true**：双强链都失败时 Set 抛错**不落盘**、索引读失败 Get 抛错；`SecureStorage.FailClosed=false` 才回退弱文件密钥（opt-out） | 探针件（`-p:SecureStorageProbe=true`）：`roundtrip failClosed=True hardwareBacked=True assetAvailable=True match/removed/gone=True afterSet=30B file=0 plainInFile=False`；0 条 asset 失败日志；弱存仅显式 opt-out |
| 1.4 | **CLIPBOARD-ACL** | `READ_PASTEBOARD` 改为 **Acl 标记特征**：**默认件与 `OpenHarmonyFeatures=all` 都不声明**（不会触发 9568289 拒装）；仅显式 `-p:OpenHarmonyFeatures=clipboard` 声明（装机需 ACL profile 放行；AGC 申请包见 `2026-10-15-ohos-acl-submit-pack.md`） | 默认件 reqPermissions 仍 1（INTERNET）；`all` 件 8 非 ACL、rc=0；ACL 获批后 `clipboard-acl-accept.sh` 一键验收（读路径获权即通） |
| 1.5 | **bundle 决策 = 重打包 + sdk 重锚（有包变化）** | 本刀壳/宿主/targets 变化（abc + host + CLIPBOARD-ACL targets）→ bundle 重打包 `8772ef23…`（46,368,700 B；`workload-1.0.0-preview.29` / `workload-latest` / SDK `.105 -ohos` release 三处同值；`SHA256SUMS` 212 B / `322bc0ab…`）；sdk-ohos `versions.env` 锚重锚 `def202206b`（`ohos-install-tests` CI 38852242270 success） | `dotnet workload list` = `1.0.0-preview.29/11.0.100-rc.2`；安装器/四锚校验通过（锚新值）；对消费面 = 新装/升级均得 #58 壳 |
| 1.6 | **门禁/指纹/7 hap/预签/发布签名** | 交互套件 **826/829 floor 809**、像素 PASS、宿主导出 **167/167**（+3 ASSET）、abc **637,300（`4070204a…`）**/headless **24,340**、宿主 **375,712（`1e156f42…`）**；7 hap = 5 MAUI 全 AOT + Blazor 默认/`-nocsp`；**预签刷新至 #58** + **release-signed 主 hap**；`SHA256SUMS` 18 项 | 包内 `sh verify-kit.sh` → **0 FAIL / 0 WARN**（默认期望 **637300,24340**，裸跑即绿；#57/#56/#55 包 637224、#54 包 623784 等旧值 FAIL 属预期）；`[suite] checks=826 total=829 floor=809 assert=True`；`runtime-mode.txt=aot` |

## 2. 本轮判定点（按包内入口逐个勾）

| 判定点 | 前置/怎么测 | 期望 | 证据/回传 |
|---|---|---|---|
| **① bundle 切换复核（#58 主判点 1）** | 装机默认件（预签件 `hdc install -r`）→ `bm dump -n mauidemo.dotnet.springmin.com` → `aa start` | 新应用身份可见（labelId/iconId > 0、1×INTERNET）；主窗 `canvas presented`；壳 abc 637,300（包内核对） | `bm` dump + 截图 + hilog |
| **② TOUCH-PASTE 默认开（#58 主判点 2）** | 默认件：长按 Entry → 浮层 → 点击落字；另装 opt-out 件对照 | 默认出浮层 + `pasted N chars`；opt-out 0 浮层 | hilog 原文 + 截图 |
| **③ SECURE-STORAGE-ASSET（#58 主判点 3）** | 有源码者：`-p:SecureStorageProbe=true` 探针件 → `app://securestorage/*` 探针 | `roundtrip failClosed=True … assetAvailable=True match/removed/gone=True`；0 失败日志 | 探针 JSON + hilog |
| **④ CLIPBOARD-ACL（#58 主判点 4）** | 默认/`all` 件装机（不声明 ACL）；ACL 获批后跑 `clipboard-acl-accept.sh` | 默认/all rc=0（无 9568289）；ACL 后读回 marker | `bm dump` + `report.md`（ACL 后） |
| **⑤ release-signed 主 hap（#58 主判点 5）** | 轮包 `assets/release-signed/hello-maui-app-unsigned-release.hap` → `hdc install -r`（免 UDID） | **已完成（发布方补跑）**：镜像拒绝 `9568322 not trusted app source` = 发布源信任边界（如实记录、非回归）；预签通道照旧 | 安装输出（证据归档 `device/rs-install.log` + `rs-boundary.txt`） |
| **承 #57：三卡（按文本沿用）** | 有源码者按包内 `cards/README.md` 复跑（CG2-R2R / AOT-STARTUP / FIXRR） | 沿 #57 结论：#57 卡值（JIT IL 135,688,505 vs R2R 147,389,459；attach→surface 14/14 ms；interp 613/580/588 ms + `DOTNET_ReadyToRun=0`） | `[startup]` hilog + 冷启表 |
| **承 #56 判定点** | 同 `2026-10-14-ohos-tester-handoff-kit56.md` §2（TOUCH-PASTE 控件 / WEBAUTH-LOOPBACK / SECURE-STORAGE-FAILCLOSED → #58 起默认 ON / launcher / clipboard / media / 子窗） | 不变（SECURE-STORAGE 语义升级见 1.3） | 同上各卡 |
| **门禁回归 / 指纹基座** | 有源码测试者跑 `sh verify-kit.sh` 与 `test/maui-platform-verify` | verify-kit **0 FAIL/0 WARN**（默认 637300,24340）；`[suite] checks=826 total=829 floor=809 assert=True`；导出 **167/167**；像素 PASS | 终端输出 |

> **本刀执行时的设备状态（如实）**：发布侧全部完成（P0–P6、预签、release-signed、manifest、CI 5/5 + harmony + sdk install-tests、轮包/证据归档）；
> **发布件设备冒烟已在刀内补跑**（设备在切包窗口后段回线，HAD-W32 / OH 7.0.0.111；`hdcp4` 本机 targets 空 → 按 TOOL-HARDEN-B 回退取 harmonybrew `hdc`，锁协议 + PRE55 还原照走）：
> **结果 = 预签通道全绿**（发布 digest 对口 asset 646176805；kit 未签件按本机 UDID `1BCE13C8…` 重签 → 安装 rc=0；`bm dump` labelId 16777217 / iconId 16777231 / 1×INTERNET；主窗 `canvas presented`；fault diff 0）＋
> **release-signed 件 = `9568322 not trusted app source` 边界**（见 §0b；降级记录，非回归）。证据 = `kit58-evidence-20261016.tar.gz` 的 `device/`（smoke 全 log + rs-boundary）。

## 3. 环境与边界要记（增量）

- 构建位 = `~/.dotnet.rc2-105`（rc.1 回滚线 `~/.dotnet` 与 `.112` 线 `~/.dotnet.rc2-fix` 保持不动）；`.29` bundle 的 `.28` 保留历史。
- **P0 安装 pack == repo `.29` 门禁**（保 #58）：本轮修正 = 构建位安装包补齐 **`hosts/arm64-v8a/libopenharmonyhost.so`（375,712）** 与 **`targets/OpenHarmony.Hap.targets`（CLIPBOARD-ACL）** 两件（此前停在 #57 代；缺件会让 hap 静默带旧宿主/旧特征表——已同步并复验 7 sdk + 20 ref/runtime/bcl 文件 + 红控 rc=1）。
- bundle 重打包（canonical P3）承载：五包 abc（637,300/24,340）、宿主 375,712、CLIPBOARD-ACL targets、tasks 同代；BCL packs 沿发布 seed（rc.2 `.105` / rc.1 aspnet `.105`）。对外消费面 = `workload-latest` / versioned / SDK release 三处已同步。
- release-signed 主 hap 的免 UDID 属性 = UDID-free Release Profile（无 `debug-info.device-ids`）；与预签 debug 件**互斥**（同 bundle）。
- 降级/人工卡：同 #57/#56（`2026-10-14-ohos-tester-handoff-kit57.md` §3）；api20 镜像级边界（9568297）等继续有效。

## 4. 证据与指针

- release「## Integrity (kit #58)」（四 release：dtk 392356147 / workload-latest 392077166 / workload-1.0.0-preview.29 412533677 / SDK `.105 -ohos` 412433510）；
- kit 数字：tar **70,449,999 B / `d7e3311b61014ffb18bf27525d385750c91d1a81975d18bfd5d5505b8966e995`**、树 `25f3159a9ea08254583d83a0e4a6d9feea5ac7ddd1f9e162da67f91aeb7adcb0`、sidecar `0da48a97aba6305ee5707223aac1fab1216a906cf0cd192c6fd16d493805cc28`（89 B）；pins ow `83ee7d0d97e8a453574abf2acedd6d868d525924` / maui `44da5f74f5b2609011f1eec7b754cbbeebaae765` / runtime `9d76707596c660f7e8d0564913c792aba5192bce`；
- bundle：**46,368,700 B / `8772ef23e08ba3feec3149de37104d23948f3a466dd36e246bfc65b22413aa2f`**（重打包；sdk-ohos 锚 `def202206bd99d8578d9aabde4e1e9a240183e8a`）；`SHA256SUMS` 212 B / `322bc0ab8075294f16a5ec4a8a0a05a9e752f1acbe8a8f07af119523089981b6`（sdkrc2 合并 14 行 / `7a6083a8…`）；
- 预签：`preSigned-haps.tar.gz`（**70,256,405 / `3dc2f08e…`**，asset 646181985；sidecar 88 B / `e3788ce4…`，asset 646183845）＋ **release-signed 主 hap**（23,773,854 / `667e319b…`）；
- 证据归档 `kit58-evidence-20261016.tar.gz`（**108,772 B / `a2a4c08f93ca3e944cc06c485207bc3ef682b621dd14e7ed8ba72d044100f9dc`**，asset 646216133；sidecar 97 B / `1b588713a130…`，asset 646216578；95 成员：本刀全部 log/state/values、bundle 决策对照、presign/release-sign、**设备冒烟全套（smoke log / rs-boundary / hilog 行 / bm dump / fault diff）**）；
- 轮包 `tester-round-kit58.tar.gz`（**214,609,739 B / `3786f30c23606a4871b1a1d50b9043f5485ee483bd1006ee9b7592559277046c`**，asset 646211333；sidecar 92 B / `c26924542534…`，asset 646214775；76 成员 = kit + 预签 + release-signed + 解释器 rc2b + AOT v3 rc2 + Crossgen2 引用（`.112` 档 + `.105` 官方 nupkg）+ 三卡说明 `cards/`（按文本沿用）+ 文档 + device-round；包内 `README-一轮上手.md` 已含 release-signed 实测边界）；
- CI：ow @ `83ee7d0` 6/6（interaction 38849077281 / pixel 38849077214 / host-export 38849077221 / ridgraph 38849077356 / markdownlint 38849077228 + harmony 38849077251）；sdk `ohos-install-tests` 38852242270 @ `def202206b`。
