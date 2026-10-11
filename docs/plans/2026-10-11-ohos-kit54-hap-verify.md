# KIT54-HAP-VERIFY：kit #54 的 7 hap 壳 rawfile / WebAuth 注入核查（2026-10-11）

> 结论：**DEVICE-ROUND-54 发现 11 复核成立**——kit #54 的 5 个 MAUI(AOT) hap 缺壳 rawfile `resources/rawfile/media.html`/`hls.min.js`/`hls.LICENSE.txt`（A-M1/B-M1 壳契约件），7 hap 的 `module.json` 均无 WebAuth 回调 skill；根因 = P1 用的 `~/.dotnet.rc2-fix` 的 preview.28 SDK pack 停在 #53 代且缺 #54 目标，而 repo/pin worktree（与 `~/.dotnet` 的目标件）已是 #54 代。静态核查为主：无设备、未动 release 资产（#49–#54 资产未动）。

## 1. 逐 hap 检查表（`reg-kit54/device-test-kit/`，tar 69,301,436 / `ecc41f05…`）

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
