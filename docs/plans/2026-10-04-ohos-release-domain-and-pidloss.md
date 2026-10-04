# RELEASE 域自签实测 + AOT soak 静默 pid 丢失归因（DEV-RELEASE 重试，2026-10-04）

> 设备 MateBook Pro HAD-W24（OpenHarmony-7.0.0.111 SP3ENTC293E104R2P1log / API 26 / 2in1），hdc `127.0.0.1:35111`；独占锁 `.device-lock`（21:44 接管 18:55 陈锁 → 完成后释放）。SDK `26.0.0.18_2/toolchains/lib`。
> 方法：`hap-sign-tool` 重签 —— release profile = `UnsgnedReleasedProfileTemplate.json` + `OpenHarmonyProfileRelease.pem` + `OpenHarmony.p12`（alias `openharmony application profile release`）；debug 对照 = 模板 + 本机 UDID；app 证书/密钥 `OpenHarmonyApplication.pem`/`OpenHarmony.p12`（alias `openharmony application release`），`signCode 1`。
> 证据 scratch：`release-domain/{bin/sign-variants.sh,out/device-install.log,out2/matrix2.log,out2/*.jpeg,out2/e3-cppcrash-full.txt,out2/r2-jit-cppcrash-full.txt}`、`soak2/out/jit`、`kit44-local/soak`。

## 1. 签名 / 安装矩阵（22:05 冷机重跑，19:16 首轮同结论）

| 件（provision / runtime） | 安装 | 启动 |
|---|---|---|
| e-ourbundle-release（release / AOT） | OK | **OK**：`jitfort: skipped runtime-mode=aot`、`web sink: true`、host `canvas presented` ×22（60 fps 口径）、pid 28225 RSS 198,380 kB（截图被 HiShell 窗口遮挡，非应用 UI 证据） |
| e3-jit-release（release / JIT，= soak2 JIT payload 逐字节同） | OK | **崩**（§2） |
| d0-debug-control（debug / AOT） | OK（先 uninstall；见下） | **OK**：`jitfort: skipped runtime-mode=aot`、`canvas presented`、pid 48102 RSS 249,884 kB（22:14 冷机） |
| d0-debug-control 覆盖 release 件安装 | **9568286 install provision type not same** | — |
| e-ohos-test-release（release / AOT，bundle `com.OpenHarmony.app.test`） | OK | 未启 |
| e0-presigned-expired（原 `SgnedReleaseProfileTemplate.p7b`） | **9568329 verify signature failed**（profile validity 过期） | — |

- 三件 `verify-app` 全过；**SDK 自签 release 件在本 OpenHarmony 设备可装可跑**（华为商用 HarmonyOS 验签链仍须发布证书，自签不可替代）。

## 2. JITFORT 域差异（核心）

- **release × JIT**：装 OK、`aa start` OK，`managed app ... started` 后 ~44 ms 进程死（22:08 冷机重跑同型）；faultlog `04703579937933323244`（19:21:28）/ `04954836155665300046`（22:08:19，pid 35047）：`SIGSEGV(SEGV_ACCERR)` @ `0x5cccfc0000` / `0x5e248d0000`（ASLR 异址），栈均 `memcpy ← libcoreclr.so(coreclr_initialize+996)`；两例 maps 同构：故障址落 `---p` 的 **PROT_NONE ≈1 GB 保留区** → JIT 代码内存提交被拒后的写缺口。Foreground，进程寿命 4 s。
- **debug × JIT（同 payload）**：`jitfort rc=0 errno=0 state=off`（`prctl(PR_SET_JITFORT=0x6a6974)` 解锁成功；22:11 冷机重跑 pid 43151 + `canvas presented`，45 min soak2 正常）。两件 283 个非签名文件逐字节同，仅签名块异 → 差异归因 provision 域。
- **AOT 两域**：`skipped runtime-mode=aot`；release AOT 出帧（上表）。
- 判定：**release provision 下 JIT 路线在 `coreclr_initialize` 崩**（exec-mem/JITFORT 策略路径），AOT 不受影响；debug 域解锁有效。发布域 JIT = 华为发布证书 + ACL/JIT 豁免后复验，不能由自签 release 外推。
- 残余：崩点早于托管状态回读（release 崩点 `managed app` +44 ms vs debug 回读 +132 ms），hilog 无 `jitfort`/`openharmony-host` 原始行非负证据；prctl 返回码需 `dotnet-status.txt`（应用沙箱，未取到）。

## 3. AOT soak 无声 pid 丢失归因（2026-10-04 10:33–11:14，kit44-local E）

- 时间线：pid 17035 存活至 sample20 10:54:30（FOREGROUND / AWAKE / RSS 266,336 kB / 线程 91）；末条应用日志 10:54:00–02 `web slot create: 2/3`；10:59:30 sample25 `PID_LOST`（无 fault）→ 脚本自 `aa start` 重启 pid 29050，后 15 min 正常；`updateTime` 首=末（无重装）。
- 排除：`hidumper -e --list` 全量列表在 10-03 20:32 → 10-04 19:21 之间**无任何条目**（含 10:54–11:00；无 CppCrash / JsError / AppFreeze / ThreadBlock），`fault-new` = 0 → **非 Hiview 可见崩溃**。
- 盲区：hilog 持久化最早文件 = 10-04 11:51:05（043），10:54–11:00 的 hilog / kmsg / APP_NAP（resource_schedule_service）/ WMS 时间线未存留（设备 21:36 重启清缓冲）；`/data/log` 其余目录 shell 不可读。
- 旁证：run1（09:52–10:33）原 pid 32207 于 ~09:58 因**并发会话外部重装**而换 pid（updateTime 1791078753886→1791078879216）——同 bundle 外部操作先例；但 run2 丢失窗口内无 agent 会话消息、无后台 shell 完成记录。
- 判定：**静默终止（无 fault 的 kill/exit）**，非崩溃；残余候选（降序）= 外部 `aa force-stop`/kill（共享设备）> 系统资源回收（内存压力/APP_NAP）> 应用自退。唯一归因需独占复跑 + `hilog -w start` + WMS/内存压力采样。

## 4. 提交 / 不确定

- 提交：本文 + `docs/plans/README.md` 索引（`commit-paths.sh`，未强推）。
- 不确定：自签 release ≠ 华为发布域（ACL/JIT 未获批）；release×JIT 崩溃的 prctl 返回码未直接观测；pid 丢失因缺持久日志无法唯一归因；release×JIT 仅单 payload、单设备复现。
