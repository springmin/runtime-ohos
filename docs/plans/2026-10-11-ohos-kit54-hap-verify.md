# KIT54-HAP-VERIFY：kit #54 的 7 hap 壳 rawfile / WebAuth 注入核查（2026-10-11）

> 结论：**DEVICE-ROUND-54 发现 11 复核成立**——kit #54 的 5 个 MAUI(AOT) hap 缺壳 rawfile `resources/rawfile/media.html`/`hls.min.js`/`hls.LICENSE.txt`（A-M1/B-M1 壳契约件），7 hap 的 `module.json` 均无 WebAuth 回调 skill；根因 = P1 用的 `~/.dotnet.rc2-fix` 的 preview.28 SDK pack 停在 #53 代且缺 #54 目标，而 repo/pin worktree（与 `~/.dotnet` 的目标件）已是 #54 代。静态核查为主：无设备、未动 release 资产（#49–#54 资产未动）。

## 1. 逐 hap 检查表（`reg-kit54/device-test-kit/`，tar 69,301,436 / `ecc41f05…`）
> **rev2 已执行（2026-10-11）**：本文的修复方案已落地并成套替换 #54 资产（pack-sync + P0 install-pack 门禁 + 重编 7 hap）；rev2 值：kit tar **70,345,291 B / `583d6df43961d371e666dcc078a63a41530d9dc4c74d7c6d7375e0b3c7171f09`**、树 `251d0c43ab5b5146845febc4afee53187e56513ee4a375f4cd7327c2b7462c09`、sidecar 89 B / `094165d72ec079920862bf9ada268da55634a87aba3833f7c3eb1f9a65522543`（见 handoff54）。本文保留核查时点（rev1）的原始记录。

| hap | sha(8) | media.html | hls.min.js / LICENSE | module.json skill |
|---|---|---|---|---|
| hello-maui-app.hap | `66dc5662` | 缺 | 缺 / 缺 | 仅 home（无回调） |
| …-unsigned | `0dbc266f` | 缺 | 缺 / 缺 | 仅 home |
| …-permissions | `3c73926a` | 缺 | 缺 / 缺 | 仅 home |
| …-api20 | `c2bdf8ef` | 缺 | 缺 / 缺 | 仅 home |
| …-api20-permissions | `0b66d12c` | 缺 | 缺 / 缺 | 仅 home |
| hello-blazorwasm-host-unsigned | `de223516` | N/A（hvigor 宿主，不走 pack staging） | N/A | N/A |
| …-nocsp | `b4b50a65` | N/A | N/A | N/A |

- 期望（好 pack）：每个 MAUI hap 应带 `media.html` 16,768 / `465f8190…`、`hls.min.js` 619,692 / `a12e7ee1…`、`hls.LICENSE.txt` 1,338 / `ca8773cf…`；WebAuthProbe 构建应追加 `{"entities":["entity.system.browsable"],"actions":["ohos.want.action.viewData"],"uris":[{"scheme":"myapp","host":"callback"}]}`（发布 hap 本不带回调属预期）。
- 中间产物旁证：P1 worktree `obj/.../openharmony-hap/resources/rawfile/` 仅 `app.json`+`dotnet.zip`；module.json 仅 home skill。

## 2. 对照（哪套 workload/pack 好、哪套坏）

- **坏（P1 实际使用）`~/.dotnet.rc2-fix`**：preview.28 SDK pack 为 10-07 代——`targets/OpenHarmony.Hap.targets` 77,401 B 无 `_OpenHarmonyHapShellRawfile` staging、无 `OpenHarmonyWebAuthenticatorCallbackUrls`；`tools/Microsoft.OpenHarmony.Tasks.dll`（`0c186779…`）无该参数（strings 0 vs 3）；`modules.ui.abc` 542,936 / `f18f0855…`（#53 abc）；无 `templates/resources/rawfile/`。
- **好 1：repo/pin worktree `ohos-workload/packs`（= 34b53ea bundle 源）**：targets `6e1f1abf…`（webauth/rawfile 两处新增）、tasks `93db9653…`、ui.abc 623,784 / `58c5829b…`、rawfile 3 件齐全、provenance 为 FINAL。
- **好 2：`~/.dotnet`**：targets/tasks/rawfile 与 repo 逐字节同；仅 ui.abc 602,744 / `d32981e6…`（pre-FINAL，非全量镜像）。
- **正控**：`mediamicro/device/kit/jit/*`（默认 `dotnet`=`~/.dotnet` 构建）自含 media.html 16,768/`465f8190…`+hls 两件；`wt-wa/webauth-kit4`（JIT）module.json 自动含 `myapp://callback`。
- **手补旁证**：`reg-kit54/soak54/bin/repack-probe54.sh` 注释明载 stale pack "does not stage … (this is also why the kit hap lacks them)"+"pack targets predate the injection"；探针 hap `1cf7fd4f…` 手补后全链过。

## 3. 根因 / 影响面

- 根因：`cut-kit.sh` P1 默认 `DOTNET=$HOME/.dotnet.rc2-fix/dotnet`（L705-708；env54 未覆盖）；rc2-fix pack 自 #53 代后无 pack-sync（对照 #53 `pack-sync53.sh` 双安装同步）；#54 的 webauth（`b49ea76`）、A-M1 rawfile（`b674f80`）、B-M1 hls（`983d103`）、MICRO（`a118ed8`）、FINAL abc（`34b53ea`）只进了 repo/`~/.dotnet`。hap abc 正确（623,784）仅因 `make-device-test-kit.sh` 显式 pin `OpenHarmonyArktsModulesAbc`；rawfile/manifest 仍出自安装 pack。P0 "packs abc PASS" 只查 repo pack，不查构建用安装 → 门禁盲区。
- 影响面：5 MAUI hap 上 A-M1 主窗 MediaElement、B-M1 子窗媒体+HLS、MEDIA-MICRO 弹窗/m3u8 将降级 Failed（壳 `getRawFileContentSync` 无 media.html）；rc2-fix 构建的 WebAuth hap 不路由（探针手补）。Blazor hap、宿主 `.so`（`ad7ab986`）、abc 不受影响。#49–#53 特性当时不存在（#53 交接 10-08；两特性 10-09/10-11），其 hap 无此件非缺陷；staleness 窗口仅覆盖 #54。
- 不确定项：rc2-fix 的 Ref/Runtime/BCL pack 同为 10-07 代（与 `.dotnet` 一致、与 pin 件不同源）；kit 构建未受影响（Ref 仅编译期、AOT 载荷源自源编译），全量刷新时以 pin 件为准复核。

## 4. 修复方案（不执行发布）

1. 刷新 rc2-fix packs：同步 pin 件 preview.28 SDK pack（targets/templates/tools/hosts；可仿 `reg-kit53/pack-sync53.sh`）→ `build-arkts-shell.sh --check-pack-abc` + `selftest-hap-targets.sh`；顺带补 `~/.dotnet` ui.abc 602,744→623,784。
2. 小构建验证：rc2-fix + JIT `make-mode-kit --mode jit` + `-p:WebAuthProbe=true`，断言 rawfile 3 件 + `myapp://callback` skill；AOT 全 kit 走 P1。
3. 重建 7 hap：P1 → P2 严格 verify → 新增 7-hap 抽查（media/hls 存在性 + module.json 字节断言）；hap/tar/sidecar/树/SUMS/预签/轮包 sha 全变，abc 与宿主不变。
4. 门禁：P0 增加 "构建用安装（rc2-fix）pack == repo pack（targets/tasks/ui.abc/rawfile）" 断言，防复发。
5. 记 `make-mode-kit --mode aot` 缺 `-p:InvariantGlobalization=true`（kit/publish-aot 有；漏传会 ICU FailFast——本 session 已复现）；建议 aot 分支默认补上。

## 5. re-cut 选项与风险

- **A. 同 #54 clobber rev2**（P4 `clobber kit 54`）：替换 dtk 630438379/630439196、latest 630439416/630440201、预签 630444444/630445633、轮包 630491536/630493485 + 四条 release body Integrity 重写。风险：测试方可能已取 #54（哈希漂移；预签/轮包成套换），改动面大但省 runbook 改动。
- **B. 切 #55**：不动 #54 资产，在 release/known-issues 标注缺口；全量 P0–P6 新号。风险：文档/预签/轮包成本 + 测试方换包；审计链最干净。
- 建议：未出测试结论且测试方尚未开跑 → A（rev2）；已开工/要留审计链 → B。两案均先做 §4.1–4.4 与静态 7-hap 抽查；本轮不动 release。

## 6. 复核命令 / 证据

- `unzip -l <hap> | grep -E 'rawfile/(media|hls)'` · `diff ~/.dotnet.rc2-fix/packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.28 <pin>/packs/…` · `strings …Tasks.dll | grep -c WebAuthenticatorCallbackUrls`（0=坏 / 3=好）；证据：`reg-kit54/device-test-kit*`、`reg-kit54/soak54/bin/repack-probe54.sh`、`reg-kit54/ow/.../openharmony-hap/`、`mediamicro/device/kit/jit/*`、`wt-wa/webauth-kit4/*`、本机两安装 pack。

## 7. rev2 抽验（真机 KIT54-REV2-SPOTCHECK，2026-10-11 22:52–22:53）

> 输入 = 本地 `reg-kit54-rev2/device-test-kit.tar.gz`（70,345,291 / `583d6df4…`，sha256 复核一致）；设备 HAD-W32 / OpenHarmony-7.0.0.109 / hdc `127.0.0.1:36823`（UDID `1BCE13C8…`，非预签 UDID）；本 session 不改上游 PR。

- **装机/启动**：取 kit `hello-maui-app-unsigned.hap` 经 `scripts/sign-for-device.sh <udid>` 设备重签（**23,749,705 B / `5b3b33ba…`**）→ `hdc install -r` success；`bm dump` 设备侧确认 `myapp://callback` skill；冷启（AOT）pid=10457、主窗首帧出画（`evidence/first-frame.jpeg`）。
- **WebAuth 判据（注入实际生效）**：`aa start -b … -a EntryAbility -U 'app://webauth/start'` → `pending +1`；再 `-U 'myapp://callback?code=REV2&state=s1'` → **+8 s `[maui] status: [webauth-probe] webauth: ok code=REV2 state=s1 token=`**（窗口标题通道同证）；激活链 `activation seq=3 uri='myapp://callback?code=REV2&state=s1'`。探针 = rev2 件内建（`libhello-maui-app.so` 含 `[webauth-probe]`/`app://webauth/*` 字面量 + 清单 skill）。
- **MediaElement 判据：N/A（无探针）**——rev2 cut 仅开 `DEVICE_TEST_KIT_WEBAUTH_PROBE=1`（无 `-p:MediaElementProbe=true`），`app://media/element/*` 路由未编译（App.cs `#if MEDIAELEMENT_PROBE`），真机无触发入口；hap 侧证据（重签件/kit 签件/unsigned 三处逐字节同）：`media.html` 16,768 / `465f8190…`、`hls.min.js` 619,692 / `a12e7ee1…`、`hls.LICENSE.txt` 1,338 / `ca8773cf…`、`runtime-mode.txt=aot`。
- **0 fault**：`hidumper -e --list` 前后 diff = 0 新 fault（列表内 10-11 20:04 CppCrash 三条为前轮既存）。纪律：锁独占、常亮 6 h、hilog 16M→512K 还原；结束恢复设备原状（l7m2-s2 `f78695d5…` 重装成功，updateTime 22:53:08）+ 释放锁；证据 `…/opencode/spotcheck54-rev2/evidence/`。
- 不确定项：无阻断项；WebAuth 用显式投递（隐式 chooser 链 2026-10-10 已有 JIT 探针证据）；MediaElement「播至 ended」待含 `-p:MediaElementProbe=true` 的轮次补（本件无入口，非缺陷）。

## 8. 干净探针轮：环境修复后的 AOT 媒体探针直证（2026-10-12 06:25–07:01）
> 输入 = **单次干净构建（无手补）**：ow `f66d67c`（= `77fc502` + WEBAUTH-DECOUPLE `f66d67c`；仅 csproj/make-device-test-kit/selftest 三文件，媒体路径与壳逐字节不变）· maui `36da77cba4` · `DOTNET=~/.dotnet.rc2-fix`（pack 同步后；targets `6e1f1abf`/abc `58c5829b`）· `make-mode-kit --mode aot -p:MediaElementProbe=true -p:OpenHarmonyFeatures=network -p:InvariantGlobalization=true --property CustomAfterMicrosoftCommonTargets=<aot-local-hooks>`（06:25–06:27，BUILD_RC=0）；unsigned hap **23,440,683 / `8fb197f2…`**；仅 staging 探针媒体样本（`MediaElementProbe.cs` 明载 round-script staging，非环境修复）后签本机 UDID → 探针 **23,868,773 / `c7ae4f22…`**。设备 HAD-W32 / OH 7.0.0.109 / hdc `127.0.0.1:36823`；锁独占（owner=mediaprobe-clean）、常亮 6 h、hilog 16M→512K 还原、末态 fixture `l7m2-s2.hap` 回装（post updateTime 07:01）+ 锁释放；#49–#54 资产未动。
- **静态断言 PASS（环境修复 = 自动入包，无手补；unsigned 与签后件两处复验）**：hap 自带 `resources/rawfile/media.html` 16,768/`465f8190…`、`hls.min.js` 619,692/`a12e7ee1…`、`hls.LICENSE.txt` 1,338/`ca8773cf…`、`libs/arm64-v8a/runtime-mode.txt=aot`、`ets/modules.abc` **623,784/`58c5829b…`**（未 pin，由同步后的 rc2-fix pack 解析）、`libhello-maui-app.so`（AOT）；module.json 路由 `myapp://callback`（WEBAUTH-DECOUPLE 后无条件）+ `INTERNET`。
- **① rawfile H.264/AAC 播至 ended**：冷启 `runtime-mode=aot`、`canvas presented`×24 + 首帧截图；`me opened dur=1000ms size=360x240` → `after-play ended=True state=Completed pos=1000ms dur=1000ms seen=1000ms states=Prepared/Playing/Playing/Paused/Completed/` → `transport seek=Success resume=Success pause=Success posBeforePause=165ms=posAfterPause pauseState=Paused resumeAgain=Success` → `audio mute/volume/unmute=Success` → `stop=Success slot=2 claimed=True` → `close released=True mainWindowAlive=True`（冷启遍首 ack `Unavailable`＝已知 page-bridge 竞态、仍播至 ended；pass2 暖遍 `play status=Success` 全链同，pos 对 188ms）；暂停帧（pass2）/分段帧截图像素 colorful **32.9%**（主窗面板基线 12.6%）。
- **③ HLS**：`hlslocal`（分段）两遍复现 `play=Success` + `opened 1000ms/360x240` + `after-play ended=True Completed 999/999 seen=724–734ms` + `close released`。`hlsrange`（单文件 BYTERANGE）：`manifest-parsed` + 2×206（`bytes=0-789 -> 0-789/39739`、`bytes=790-39738 -> 790-39738/39739`）+ 首 ack `play=Success`，随后 `fragLoadError`（non-fatal）→ `opened=0 / ended=False state=Unknown`、`pauseState=Error`（本轮 **5 次完整等待全复现**、另 1 次 13 s 截断）。
- **hlsrange「ended=True」更正（raw 复核）**：DEVICE-ROUND-54 §3③ 与 `2026-10-11-ohos-media-micro-boundaries.md` §2 所记均系标题通道 dedup 命中**前一阶段**陈旧行——`warm-hlsrange-maui.txt` 唯一 `ended=True` 在 hlslocal 段（20:34:41），hlsrange 段（20:34:53 起）无 opened/after-play；`mediamicro/evidence/hilog.txt` 16:07:45 为 hlsrange 自身 `ended=False`。结论：rawfile BYTERANGE 本地 HLS 在本设备**从未实测到达 ended**（206/manifest/serve 均正常）→ 记**既有边界**（非本轮回归）。
- **零回归**：4 遍安装/运行 ×`fault-new=0`（`hidumper -e` 前后 diff）＋ pid 全程恒稳 ＋ `wms_sub=0` ＋ 主窗首帧出画；本轮流树进程已回收（设备上 4 条 `hdc … hilog` 流均归 soak54 会话）。
- 证据：`…/opencode/mediaprobe-clean/`（`build.log`、`assert-static-{unsigned,probe}.txt`、`summary{,-4}.txt`、`live-hilog.txt`、`pass2/3-*-lines.txt`、`evidence/SUMMARY.md`、截图与 fault diff）；提交 = 本 §8 + README 索引行。
