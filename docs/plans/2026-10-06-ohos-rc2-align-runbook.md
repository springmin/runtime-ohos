# RC2-ALIGN-RUNBOOK：官方 rc.2 落地后的对齐与切包预案（2026-10-06 初稿；2026-10-12 刷新至 kit #54 rev2 现状，目标 #55；不执行）

> 触发前状态 = WAIT（2026-10-11/10-12 复核，watcher exit 0）：官方 rc.2 未上 nuget.org，pin 仍 dnceng daily `11.0.0-rc.2.26478.12`。
> 基线（#54 rev2 已切）：ow `master f66d67c`（#54 线 = P0 安装 pack 门禁 `25e6f54` → rev2 `77fc502` → WEBAUTH-DECOUPLE `f66d67c`；pin `60dda54`）；maui 切片 `36da77cba492`（三 workflow pin）；套件 **796/799 floor 779**、导出 **164/164**、壳 abc **623,784（`58c5829b…`）** / headless 24,324、宿主 **367,520（`ad7ab986…`）**；kit #54 rev2 = tar **70,345,291 / `583d6df4…`**（树 `251d0c43…`、sidecar `094165d7…`、`SHA256SUMS` 18 项 / 1,600 B / `0d42d76d…`）、bundle **73,465,150 / `09326398…`**（sdk 锚 `977be2e31b`）、预签 **70,180,932 / `8eb6dc80…`**（assets 630934768/630936005）、轮包 **160,770,425 / `bd8948db…`**（asset 630954114/630955835）、证据归档 asset 631055430。
> 下一 kit = **#55**：rc.2 触发时按本 runbook 执行；#54 已切、rev2 已修（rawfile/WebAuth 注入 + pack-sync + P0 门禁），升级基线自带；内容增量（#54 全量）= MEDIAELEMENT 波（A-M1 主窗 / B-M1 子窗媒体 + HLS / MEDIA-MICRO 弹窗·Range）· MODAL-OVERLAY 可见性修复 · SUBWINDOW-DEFAULT4 默认 4 · E4 8 槽 · 深链布局修复 · WebAuth · L8 · **子窗 ENTER→Completed 可观测已修（ow `34bcaa4`：样例 Completed 探针 + 套件 pin；maui/shell 零改动、abc 不变，不随 #55 必带）**；#49–#54 资产不动。
> 上游态势（10-08 复核，10-07 复演）：runtime 34/40 merge-tree CLEAN（6 冲突唯 `src/libraries/Directory.Build.props`，union 解有效）· sdk 2/2 · aspnet 新增 `eng/Dependencies.props` delete/modify（解＝接受删除 + 4 行 RID 迁 `Directory.Packages.props`，复演 CLEAN）；**#135321 已合入**。详见 `2026-09-28-ohos-upstream-fork-sync-playbook.md` §5–§7。
> 依据：`2026-09-30-rc2-mainline-adoption.md` §8、`ohos-workload/docs/rc2-official-watch.md`、`2026-10-11-ohos-tester-handoff-kit54.md`（§6.3 表格式）、`2026-10-11-ohos-kit54-hap-verify.md`（rev2 根因/修复）、`2026-10-11-ohos-device-round-54.md`。

## 1) 触发条件（RC2-WATCH，逐字判读；不变）

- 入口：`ohos-workload/scripts/rc2-official-watch.sh`（自测 `selftest-rc2-official-watch.sh`；CI `.github/workflows/rc2-watch.yml` 周一 03:17 UTC + dispatch）；状态页 `ohos-workload/docs/rc2-official-watch.md`。
- 判定：四包（Controls/Core/Graphics/AspNetCore.Components.WebView.Maui）任一 nuget flat-container 的 max 版本 ≥ `11.0.0-rc.2`，或 GitHub `dotnet/maui` releases ≥ `11.0.100-rc.2`（vcmp：`11.0.0-rc.2.26478.12`→yes；`11.0.0-rc.1.26451.6`→no）。
- 输出行（引用）：`   microsoft.maui.controls                   latest=… trigger=no|yes`；`   dotnet/maui latest release latest=… trigger=…`；命中打印 `RC2-WATCH TRIGGER: an official MAUI rc.2+ version is published.` 并 exit 10（0=继续等 / 1=源全失败 / 2=用法）。
- 当前 WAIT（2026-10-11/10-12 复核）：nuget 四包 `11.0.0-rc.1.26451.6`；GitHub `11.0.100-rc.1.26458.5`（watcher exit 0）。
- 进入 §2 的附加条件：记下官方四包 exact 版本；在无 dnceng feed 的干净 restore 中四包可解析（NU1102 消失）。

## 2) 升级序列（5 步，目标 kit #55）

> #54 已切 / rev2 已修；rc.2 到货按本 runbook 切 **#55**（全量 = #54 rev2 基线 + 官方 rc.2 对齐 + #55 必带流程件）。

1. **MAUI 包对齐（切片/测试工程）**：切片 `maui-ohos/src/Core/src/Platform/OpenHarmony/Microsoft.Maui.Platform.OpenHarmony.csproj` 4 处 `11.0.0-rc.2.26478.12` → 官方；ow 8 工程同步（7 test + `src/Microsoft.OpenHarmony.Maui.Graphics`；#54 时点仍全为 daily pin）；`test/hello-blazorwasm` 的 `BlazorFlightVersion`（`11.0.0-rc.2.26459.117`）与 blazor-recipe 复核；切片提交后三 workflow `MAUI_OHOS_REF` 从 `36da77cba492` 换到新 maui tip，删 interaction/pixel 的 dnceng feed step。入口：`grep -rn "11.0.0-rc.2.26478.12" maui-ohos ohos-workload --include=*.csproj`；adoption §8.1–2。
2. **workload/packs 重锚**：`scripts/build-arkts-shell.sh`（`ARKTS_SHELL_VARIANT=ui|headless`）→ `--install-packs`（22/23/24 + .28 手动同步；provenance gate）→ T16 `--check-pack-abc` → `verify-kit.sh`/`selftest-verify-kit.sh` 重锚（当前 EXPECT `623784,24324`，ow `34b53ea`）。当前基线 = kit #54 rev2 后 ui `623,784/58c5829b…`（provenance `1,166 B/52ea17d5`）；换 pin 重编再变则按实测重锚（四包一致）。历史件校验：#53=542936（`f18f0855…`）、#52=534192、#51=473048、#50=436808、#49=414532（旧值 FAIL 属预期）。**rev2 根因 = 构建用安装 pack（rc2-fix）停在 #53 代 → 切 #55 前先 pack-sync 两安装（构建用安装 == repo/pin pack；targets/tasks/abc/壳 rawfile），cut-kit P0 已加 fail-closed 门禁。** **注：#54 全量（post-L3 + MEDIAELEMENT 波 + 子窗/overlay 硬化尾；rev2 = rawfile/WebAuth 注入修复）已随 #54 rev2 发货，本序列基线自带。**
3. **Crossgen2/AOT/interp 包与锚核对**：JIT R2R = `crossgen2-packs-11.0.0-rc.2`（43,792,647 / `6bb8a375…`，folder feed，仅 JIT）；AOT = `-struct1`（28,905,116 / `09345f95…`，asset 607541145；`versions.env` `AOT_PACKS_TAG` + `fetch-nativeaot-packs.sh` 校验）；interp = `ohos-interpreter-pack-rc2b.tar.gz`（2,410,595 / `5974430509…`，asset 606999003）+ rc.2 kit hap（FIXRR：interp 置 `DOTNET_ReadyToRun=0`）。三件 #48–#54 保持（#54 rev2 未动）；官方 rc.2 不动 runtime `.112` 线则包保持，只复跑设备 A/B（CG2-R2R / AOT-STARTUP / FIXRR 判定卡）。
4. **套件 floor**：当前 `test/maui-platform-verify` 自报 `[suite] checks=796 total=799 floor=779 assert=True`（= 793/796 floor 776 + MODAL-OVERLAY 1 + SUBWINDOW-DEFAULT4 2；floor=total−20，`Program.cs:16`）；export 164/164、pixel PASS。M1/M2 窗口注册表等新检查已在 #50–#52 入册；kit #55 前如有新检查并入，按同一 total−20 重锚 `verifyCheckFloor` 再进 kit。
5. **kit #55 切包清单**：7 hap 表（5 MAUI AOT + Blazor 默认/`-nocsp`）→ bundle 重打 → 三处同步 → sdk 锚 → notes → 预签 → manifest → CI → tester 轮包；入口见 §3。**#55 必带流程件**：cut-kit P0「安装 pack == repo pack」门禁（ow `25e6f54`，fail-closed）· kit `check_webauth()`（hap `module.json` 缺 `(myapp,callback)` 即拒装；ow `f66d67c` 起回调路由无条件随件）· bump `--abc-sha`（显式传 sha8；cut-kit `--bump-docs` 不传、P0 不校验）· csc 防呆（preflight 内嵌 csc watchdog）。

## 3) 第 5 步命令/脚本入口（引用，不复制）

- 7 hap：`ohos-workload/scripts/make-device-test-kit.sh`（默认 `--runtime-mode aot`；`--with-blazor`）；表格式仿 `2026-10-11-ohos-tester-handoff-kit54.md` §6.3；组装期 `check_webauth()` fail-closed。
- bundle/三处：`prepare-packs.sh`（四包）→ `pack-workload-bundle.sh` → `release-checksums.sh`；`publish-workload-release.sh --bundle-sha256 <sha> --skip-kit --also-sdk-release <sdk-tag>`（三处 = `workload-1.0.0-preview.28` / `workload-latest` / SDK release）。
- sdk 锚：`eng/ohos-install/refresh-release-anchors.sh`（SDK/runtime/selfsign）+ `versions.env` `WORKLOAD_BUNDLE_SHA256` 手动重锚（当前 `09326398`，锚 `977be2e31b`）；普通推送，不强推。
- notes/manifest：`release-notes.sh` + 各 release body `## Integrity (kit #55)`；刷新 `2026-09-22-ohos-release-manifest.md` 与 tester 文档（README 索引另行合并补）；bump 用 `bump-tester-docs.sh --kit 55 --abc-sha <sha8>`（显式 sha，见 §2.5）。
- cut-kit：`scripts/cut-kit.sh` P0–P6（P0 含安装 pack 门禁；文档 fail-closed；P3 `--seed-bundle` 保持累积）+ `scripts/selftest-cut-kit.sh`；csc 防呆 = preflight 内 `run-with-csc-watchdog.sh`（spin 480 s / idle 300 s）。
- 预签：`sign-for-device.sh` 按 tester UDID 重签 7 hap → `verify-app` → `preSigned-haps.tar.gz`（7 hap + README + `SHA256SUMS` 8/8）上 `device-test-kit`；替换 #54 rev2 件（assets 630934768/630936005）。
- CI/tester：ow 6/6（interaction / pixel / host-export / ridgraph / markdownlint + harmony）+ sdk `ohos-install-tests`；本地 `device-round.sh` / `tester-run.sh`（v14）与 soak；kit #55 交接文以 `2026-10-11-ohos-tester-handoff-kit54.md` §6 为模板。

## 4) 回滚（锚点回退点；当前 = #54 rev2 已切）

| 对象 | 当前值（#54 rev2） | 回退动作 |
|---|---|---|
| bundle | `09326398…`（73,465,150；sdk 锚 `977be2e31b`） | sdk-ohos `git revert` 新锚提交 → 回 `09326398`；更远 `031ba342`（#53，锚 `64f239eb28`）→ `5a00331f`（#52，锚 `9609da7a47`）→ `f4b4fe8d`（#51，锚 `a00e810c92`）→ `6a83c0f3`（#50，锚 `a3417a5489`）→ `7d06e781`（#49，锚 `7abaf8132f`）；release 旧资产保留 |
| abc | `623,784`（`58c5829b…`；headless 24,324） | 历史件校验：`--expected-abc 542936`（#53，`f18f0855…`）/`534192`（#52）/`473048`（#51）/`436808`（#50）/`414532`（#49，`e016db13…`） |
| MAUI pin | 官方 rc.2 + 新 maui tip + 无 dnceng feed | 恢复 `11.0.0-rc.2.26478.12` + `MAUI_OHOS_REF=36da77cba492…` + feed step 同批 revert（adoption §8.5） |
| AOT/interp/CG2 | `09345f95` / `5974430509` / `6bb8a375`（#54 保持） | 未动不回退；误换则从 release 旧 asset 重指并复核 shim/ABI |
| 平台线 | SDK `.112` / workload preview.28 | 保持；设备 rc.1 回滚线 `~/.dotnet`（preview.24）不动 |

## 5) 风险

- 官方 rc.2 与 dnceng daily `.26478.12` 可能不同提交/包号 → 切片 CA/IL/API 需重跑；Blazor flight（`26459.117`）与 AspNetCore WebView 版本可能另需对齐。
- packs 兼容：换源后四包恢复（NU1102 消失）、RID 图/Ref/Runtime pack 与 AOT/CG2/interp 的 `.112` runtime 组合须重验；AOT 依赖 `-struct1` shim，不得混用旧包。**切 #55 前先 pack-sync（构建用安装 == repo/pin pack）**；rev2 根因 = rc2-fix 停在 #53 代（P0 门禁已补，仍以实测为准）。
- 必重跑门禁：切片 0 error/0 IL、interaction **796/799 floor 779**、pixel PASS、host-export **164/164**、ridgraph 20/20、markdownlint、sdk `ohos-install-tests`；kit #55 后 `device-round.sh` + soak（子窗 Home suspend、建窗 E=0、close WARN 1）。
- kit 组装/文档锚 fail-closed：`check_webauth()` 缺 `(myapp,callback)` 拒装（`f66d67c` 起回调路由无条件随件）；bump 须显式 `--abc-sha`（#54 预刷曾漏 sha → BUMP-SHA-FIX）；`verify-kit` 期望随包重锚（旧值 FAIL 属预期）。
- 预签 UDID 若变更/缺失则预签件落空，需重签；README 索引与部分 tester 文档按惯例稍后合并补。
