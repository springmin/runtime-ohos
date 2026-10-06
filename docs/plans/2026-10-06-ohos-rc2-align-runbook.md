# RC2-ALIGN-RUNBOOK：官方 rc.2 落地后的对齐与切包预案（2026-10-06，不执行）

> 触发前状态 = WAIT：官方 rc.2 未上 nuget.org，pin 仍 dnceng daily `11.0.0-rc.2.26478.12`。
> 基线：ow `master 7e7ea06`（polish-49 四包 abc 已装、verify-kit 默认 417416）；maui 切片 `b093e33825`；kit #49 资产不动。
> 依据：`2026-09-30-rc2-mainline-adoption.md` §8、`ohos-workload/docs/rc2-official-watch.md`、`2026-10-06-ohos-nextkit-{prep,polish-prep}.md`、`2026-10-05-ohos-kit48-stress-soak.md`。

## 1) 触发条件（RC2-WATCH，逐字判读）

- 入口：`ohos-workload/scripts/rc2-official-watch.sh`（自测 `selftest-rc2-official-watch.sh`；CI `.github/workflows/rc2-watch.yml` 周一 03:17 UTC + dispatch）；状态页 `ohos-workload/docs/rc2-official-watch.md`。
- 判定：四包（Controls/Core/Graphics/AspNetCore.Components.WebView.Maui）任一 nuget flat-container 的 max 版本 ≥ `11.0.0-rc.2`，或 GitHub `dotnet/maui` releases ≥ `11.0.100-rc.2`（vcmp：`11.0.0-rc.2.26478.12`→yes；`11.0.0-rc.1.26451.6`→no）。
- 输出行（引用）：`   microsoft.maui.controls                   latest=… trigger=no|yes`；`   dotnet/maui latest release latest=… trigger=…`；命中打印 `RC2-WATCH TRIGGER: an official MAUI rc.2+ version is published.` 并 exit 10（0=继续等 / 1=源全失败 / 2=用法）。
- 当前 WAIT：nuget 四包 `11.0.0-rc.1.26451.6`；GitHub `11.0.100-rc.1.26458.5`。
- 进入 §2 的附加条件：记下官方四包 exact 版本；在无 dnceng feed 的干净 restore 中四包可解析（NU1102 消失）。

## 2) 升级序列（5 步）

1. **MAUI 包对齐（切片/测试工程）**：切片 `maui-ohos/src/Core/src/Platform/OpenHarmony/Microsoft.Maui.Platform.OpenHarmony.csproj` 4 处 `11.0.0-rc.2.26478.12` → 官方；ow 8 工程同步（7 test + `src/Microsoft.OpenHarmony.Maui.Graphics`）；`test/hello-blazorwasm` 的 `BlazorFlightVersion`（`11.0.0-rc.2.26459.117`）与 blazor-recipe 复核；切片提交后三 workflow `MAUI_OHOS_REF` 换到新 maui tip，删 interaction/pixel 的 dnceng feed step。入口：`grep -rn "11.0.0-rc.2.26478.12" maui-ohos ohos-workload --include=*.csproj`；adoption §8.1–2。
2. **workload/packs 重锚**：`scripts/build-arkts-shell.sh`（`ARKTS_SHELL_VARIANT=ui|headless`）→ `--install-packs`（22/23/24 + .28 手动同步；provenance gate）→ T16 `--check-pack-abc` → `verify-kit.sh`/`selftest-verify-kit.sh` 重锚。期望基线 = nextkit 后 `417,416/cee64297…`（provenance `99f005df…`）；重编再变则重锚；#49 历史件用 `--expected-abc 414532`。
3. **Crossgen2/AOT/interp 包与锚核对**：JIT R2R = `crossgen2-packs-11.0.0-rc.2`（43,792,647 / `6bb8a375…`，folder feed，仅 JIT）；AOT = `-struct1`（28,905,116 / `09345f95…`，asset 607541145；`versions.env` `AOT_PACKS_TAG` + `fetch-nativeaot-packs.sh` 校验）；interp = `ohos-interpreter-pack-rc2b.tar.gz`（2,410,595 / `5974430509…`，asset 606999003）+ rc.2 kit hap（FIXRR：interp 置 `DOTNET_ReadyToRun=0`）。官方 rc.2 不动 runtime `.112` 线则包保持，只复跑设备 A/B（CG2-R2R / AOT-STARTUP / FIXRR 判定卡）。
4. **套件 floor**：`test/maui-platform-verify` 自报 `[suite] checks=607 total=609 floor=589 assert=True`（floor=total−20，`Program.cs:16`）；export 153/153、pixel PASS。新窗测试：M1 `selftest-host-registry` 61 checks（分支 `l/m1-window-registry`）与 M2 headless 双面用例并入后按同一 total−20 重锚 `verifyCheckFloor`，再进 kit。
5. **kit #50 切包清单**：7 hap 表（5 MAUI AOT + Blazor 默认/`-nocsp`）→ bundle 重打 → 三处同步 → sdk 锚 → notes → 预签 → manifest → CI → tester 轮包；入口见 §3。

## 3) 第 5 步命令/脚本入口（引用，不复制）

- 7 hap：`ohos-workload/scripts/make-device-test-kit.sh`（默认 `--runtime-mode aot`；`--with-blazor`）；表格式仿 `2026-10-05-ohos-tester-handoff-kit49.md` §6.3。
- bundle/三处：`prepare-packs.sh`（四包）→ `pack-workload-bundle.sh` → `release-checksums.sh`；`publish-workload-release.sh --bundle-sha256 <sha> --skip-kit --also-sdk-release <sdk-tag>`（三处 = `workload-1.0.0-preview.28` / `workload-latest` / SDK release）。
- sdk 锚：`eng/ohos-install/refresh-release-anchors.sh`（SDK/runtime/selfsign）+ `versions.env` `WORKLOAD_BUNDLE_SHA256` 手动重锚；普通推送，不强推。
- notes/manifest：`release-notes.sh` + 各 release body `## Integrity (kit #50)`；刷新 `2026-09-22-ohos-release-manifest.md` 与 tester 文档（README 索引另行合并补）。
- 预签：`sign-for-device.sh` 按 tester UDID 重签 7 hap → `verify-app` → `preSigned-haps.tar.gz`（7 hap + README + `SHA256SUMS` 8/8）上 `device-test-kit`。
- CI/tester：ow 5/5（interaction / pixel / host-export / ridgraph / markdownlint）+ sdk `ohos-install-tests`；本地 `device-round.sh` / `tester-run.sh`（v14）与 soak；kit #50 交接文以 #49 §6 为模板。

## 4) 回滚（锚点回退点）

| 对象 | 当前值（切包前） | 回退动作 |
|---|---|---|
| bundle | `7d06e781…`（sdk 锚 `7abaf8132f`） | sdk-ohos `git revert` 新锚提交 → 回 `7d06e781`（更远 `3b62cee2`/`767c03ee71`）；release 旧资产保留 |
| abc | `cee64297…`（417,416，nextkit 后） | 校验 #49 件用 `verify-kit.sh --expected-abc 414532`（`e016db13…`） |
| MAUI pin | 官方 rc.2 + 新 maui tip + 无 dnceng feed | 恢复 `11.0.0-rc.2.26478.12` + `MAUI_OHOS_REF=b093e33825…` + feed step 同批 revert（adoption §8.5） |
| AOT/interp/CG2 | `09345f95` / `5974430509` / `6bb8a375` | 未动不回退；误换则从 release 旧 asset 重指并复核 shim/ABI |
| 平台线 | SDK `.112` / workload preview.28 | 保持；设备 rc.1 回滚线 `~/.dotnet`（preview.24）不动 |

## 5) 风险

- 官方 rc.2 与 dnceng daily `.26478.12` 可能不同提交/包号 → 切片 CA/IL/API 需重跑；Blazor flight（`26459.117`）与 AspNetCore WebView 版本可能另需对齐。
- packs 兼容：换源后四包恢复（NU1102 消失）、RID 图/Ref/Runtime pack 与 AOT/CG2/interp 的 `.112` runtime 组合须重验；AOT 依赖 `-struct1` shim，不得混用旧包。
- 必重跑门禁：切片 0 error/0 IL、interaction 607/609 floor 589、pixel PASS、host-export 153/153、ridgraph 20/20、markdownlint、sdk `ohos-install-tests`；kit 后 `device-round.sh` + soak（子窗 Home suspend、建窗 E=0、close WARN 1）。
- 预签 UDID 若变更/缺失则预签件落空，需重签；README 索引与部分 tester 文档按惯例稍后合并补。
