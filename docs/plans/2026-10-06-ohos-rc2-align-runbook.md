# RC2-ALIGN-RUNBOOK：官方 rc.2 落地后的对齐与切包预案（2026-10-06 初稿；2026-10-08 刷新至 kit #53 现状，不执行）

> 触发前状态 = WAIT（2026-10-08 复核）：官方 rc.2 未上 nuget.org，pin 仍 dnceng daily `11.0.0-rc.2.26478.12`。
> 基线（#53 已切）：ow `master 7259a0f`；maui 切片 `caa463434b`（三 workflow pin）；套件 **737/740 floor 720**、导出 **164/164**、壳 abc **542,936（`f18f0855…`）** / headless 24,324、宿主 **367,520（`ad7ab986…`）**；kit #53 = tar **68,883,057 / `dba88961…`**（树 `9c67b5ec…`）、bundle **73,213,144 / `031ba342…`**（sdk 锚 `64f239eb28`）、预签 **68,755,353 / `d1732195…`**（assets 620760775/620762418）。
> 下一 kit = **#54**：rc.2 触发时按本 runbook 执行；post-L3 修复（A11Y-SELFCHECK + B6 子窗导航否决）已随 #53 发货、升级基线自带；#49–#53 资产不动。
> 上游态势（10-08 复核，10-07 复演）：runtime 34/40 merge-tree CLEAN（6 冲突唯 `src/libraries/Directory.Build.props`，union 解有效）· sdk 2/2 · aspnet 新增 `eng/Dependencies.props` delete/modify（解＝接受删除 + 4 行 RID 迁 `Directory.Packages.props`，复演 CLEAN）；**#135321 已合入**。详见 `2026-09-28-ohos-upstream-fork-sync-playbook.md` §5–§7。
> 依据：`2026-09-30-rc2-mainline-adoption.md` §8、`ohos-workload/docs/rc2-official-watch.md`、`2026-10-08-ohos-tester-handoff-kit53.md`（§6.3 表格式）、`2026-10-08-ohos-l3-post-consolidate.md`、`2026-10-08-ohos-device-round-53.md`。

## 1) 触发条件（RC2-WATCH，逐字判读；不变）

- 入口：`ohos-workload/scripts/rc2-official-watch.sh`（自测 `selftest-rc2-official-watch.sh`；CI `.github/workflows/rc2-watch.yml` 周一 03:17 UTC + dispatch）；状态页 `ohos-workload/docs/rc2-official-watch.md`。
- 判定：四包（Controls/Core/Graphics/AspNetCore.Components.WebView.Maui）任一 nuget flat-container 的 max 版本 ≥ `11.0.0-rc.2`，或 GitHub `dotnet/maui` releases ≥ `11.0.100-rc.2`（vcmp：`11.0.0-rc.2.26478.12`→yes；`11.0.0-rc.1.26451.6`→no）。
- 输出行（引用）：`   microsoft.maui.controls                   latest=… trigger=no|yes`；`   dotnet/maui latest release latest=… trigger=…`；命中打印 `RC2-WATCH TRIGGER: an official MAUI rc.2+ version is published.` 并 exit 10（0=继续等 / 1=源全失败 / 2=用法）。
- 当前 WAIT（2026-10-08 复核）：nuget 四包 `11.0.0-rc.1.26451.6`；GitHub `11.0.100-rc.1.26458.5`（watcher exit 0）。
- 进入 §2 的附加条件：记下官方四包 exact 版本；在无 dnceng feed 的干净 restore 中四包可解析（NU1102 消失）。

## 2) 升级序列（5 步，目标 kit #54）

1. **MAUI 包对齐（切片/测试工程）**：切片 `maui-ohos/src/Core/src/Platform/OpenHarmony/Microsoft.Maui.Platform.OpenHarmony.csproj` 4 处 `11.0.0-rc.2.26478.12` → 官方；ow 8 工程同步（7 test + `src/Microsoft.OpenHarmony.Maui.Graphics`；#53 时点仍全为 daily pin）；`test/hello-blazorwasm` 的 `BlazorFlightVersion`（`11.0.0-rc.2.26459.117`）与 blazor-recipe 复核；切片提交后三 workflow `MAUI_OHOS_REF` 从 `caa463434b` 换到新 maui tip，删 interaction/pixel 的 dnceng feed step。入口：`grep -rn "11.0.0-rc.2.26478.12" maui-ohos ohos-workload --include=*.csproj`；adoption §8.1–2。
2. **workload/packs 重锚**：`scripts/build-arkts-shell.sh`（`ARKTS_SHELL_VARIANT=ui|headless`）→ `--install-packs`（22/23/24 + .28 手动同步；provenance gate）→ T16 `--check-pack-abc` → `verify-kit.sh`/`selftest-verify-kit.sh` 重锚（当前 EXPECT `542936,24324`，ow `35aa1c3`）。当前基线 = kit #53 后 ui `542,936/f18f0855…`（provenance `1,166 B/167fa683`）；换 pin 重编再变则按实测重锚（四包一致）。历史件校验：#52=534192、#51=473048、#50=436808、#49=414532（旧值 FAIL 属预期）。**注：post-L3 修复（A11Y-SELFCHECK + B6）已随 #53 发货，本序列基线自带，无需再等。**
3. **Crossgen2/AOT/interp 包与锚核对**：JIT R2R = `crossgen2-packs-11.0.0-rc.2`（43,792,647 / `6bb8a375…`，folder feed，仅 JIT）；AOT = `-struct1`（28,905,116 / `09345f95…`，asset 607541145；`versions.env` `AOT_PACKS_TAG` + `fetch-nativeaot-packs.sh` 校验）；interp = `ohos-interpreter-pack-rc2b.tar.gz`（2,410,595 / `5974430509…`，asset 606999003）+ rc.2 kit hap（FIXRR：interp 置 `DOTNET_ReadyToRun=0`）。三件 #48–#53 保持；官方 rc.2 不动 runtime `.112` 线则包保持，只复跑设备 A/B（CG2-R2R / AOT-STARTUP / FIXRR 判定卡）。
4. **套件 floor**：当前 `test/maui-platform-verify` 自报 `[suite] checks=737 total=740 floor=720 assert=True`（= 731 + B6 5 + a11y 1；floor=total−20，`Program.cs:16`）；export 164/164、pixel PASS。M1/M2 窗口注册表等新检查已在 #50–#52 入册；kit #54 前如有新检查并入，按同一 total−20 重锚 `verifyCheckFloor` 再进 kit。
5. **kit #54 切包清单**：7 hap 表（5 MAUI AOT + Blazor 默认/`-nocsp`）→ bundle 重打 → 三处同步 → sdk 锚 → notes → 预签 → manifest → CI → tester 轮包；入口见 §3。

## 3) 第 5 步命令/脚本入口（引用，不复制）

- 7 hap：`ohos-workload/scripts/make-device-test-kit.sh`（默认 `--runtime-mode aot`；`--with-blazor`）；表格式仿 `2026-10-08-ohos-tester-handoff-kit53.md` §6.3。
- bundle/三处：`prepare-packs.sh`（四包）→ `pack-workload-bundle.sh` → `release-checksums.sh`；`publish-workload-release.sh --bundle-sha256 <sha> --skip-kit --also-sdk-release <sdk-tag>`（三处 = `workload-1.0.0-preview.28` / `workload-latest` / SDK release）。
- sdk 锚：`eng/ohos-install/refresh-release-anchors.sh`（SDK/runtime/selfsign）+ `versions.env` `WORKLOAD_BUNDLE_SHA256` 手动重锚（当前 `031ba342`，锚 `64f239eb28`）；普通推送，不强推。
- notes/manifest：`release-notes.sh` + 各 release body `## Integrity (kit #54)`；刷新 `2026-09-22-ohos-release-manifest.md` 与 tester 文档（README 索引另行合并补）。
- 预签：`sign-for-device.sh` 按 tester UDID 重签 7 hap → `verify-app` → `preSigned-haps.tar.gz`（7 hap + README + `SHA256SUMS` 8/8）上 `device-test-kit`；替换 #53 件（assets 620760775/620762418）。
- CI/tester：ow 5/5（interaction / pixel / host-export / ridgraph / markdownlint）+ sdk `ohos-install-tests`；本地 `device-round.sh` / `tester-run.sh`（v14）与 soak；kit #54 交接文以 #53 §6 为模板。

## 4) 回滚（锚点回退点；当前 = #53 已切）

| 对象 | 当前值（#53） | 回退动作 |
|---|---|---|
| bundle | `031ba342…`（73,213,144；sdk 锚 `64f239eb28`） | sdk-ohos `git revert` 新锚提交 → 回 `031ba342`；更远 `5a00331f`（#52，锚 `9609da7a47`）→ `f4b4fe8d`（#51，锚 `a00e810c92`）→ `6a83c0f3`（#50，锚 `a3417a5489`）→ `7d06e781`（#49，锚 `7abaf8132f`）；release 旧资产保留 |
| abc | `542,936`（`f18f0855…`；headless 24,324） | 历史件校验：`--expected-abc 534192`（#52）/`473048`（#51）/`436808`（#50）/`414532`（#49，`e016db13…`） |
| MAUI pin | 官方 rc.2 + 新 maui tip + 无 dnceng feed | 恢复 `11.0.0-rc.2.26478.12` + `MAUI_OHOS_REF=caa463434b…` + feed step 同批 revert（adoption §8.5） |
| AOT/interp/CG2 | `09345f95` / `5974430509` / `6bb8a375`（#53 保持） | 未动不回退；误换则从 release 旧 asset 重指并复核 shim/ABI |
| 平台线 | SDK `.112` / workload preview.28 | 保持；设备 rc.1 回滚线 `~/.dotnet`（preview.24）不动 |

## 5) 风险

- 官方 rc.2 与 dnceng daily `.26478.12` 可能不同提交/包号 → 切片 CA/IL/API 需重跑；Blazor flight（`26459.117`）与 AspNetCore WebView 版本可能另需对齐。
- packs 兼容：换源后四包恢复（NU1102 消失）、RID 图/Ref/Runtime pack 与 AOT/CG2/interp 的 `.112` runtime 组合须重验；AOT 依赖 `-struct1` shim，不得混用旧包。
- 必重跑门禁：切片 0 error/0 IL、interaction **737/740 floor 720**、pixel PASS、host-export **164/164**、ridgraph 20/20、markdownlint、sdk `ohos-install-tests`；kit #54 后 `device-round.sh` + soak（子窗 Home suspend、建窗 E=0、close WARN 1）。
- 预签 UDID 若变更/缺失则预签件落空，需重签；README 索引与部分 tester 文档按惯例稍后合并补。
