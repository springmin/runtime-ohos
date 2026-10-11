# FINAL-BATCH：MODAL-OVERLAY + SUBWINDOW-DEFAULT4 共存合并收口（2026-10-11）

> 口径：ow `master` ← `fix/modal-overlay`（`fc848f0`）→ `feat/subwindow-default4`（`5c6289a`），均 `--no-ff`；maui `feature/openharmony` ← `01fd6034` → `144b5b6a09`；普通推送（HTTP/1.1 旁路）、未强推；不切 kit（#54 tester-docs 终刷；rc.2 仍 WAIT）；#49–#53 资产不动；无设备、无上游 PR。

## 1) 合并 SHA

- ow：merge `357d7a9` + `69e2916` → pin `60dda54` → 重编 `34b53ea`（推送 `1d7ec00..34b53ea`）。
- maui：merge `ab8cfe8e11` + `36da77cba492d2e694064b2080f5c53a18f4c19f`（已推，`54631780a3..`）。

## 2) 冲突与解法

- ow：`Program.cs` 计数注释行两轮冲突 → 并集（+5 MEDIA-MICRO / +1 MODAL-OVERLAY / +2 SUBWINDOW-DEFAULT4 = **total 799 floor 779**）；四包 abc/provenance 二进制冲突取主线版本、随后重编覆盖；`verify-kit.sh`/`selftest-verify-kit.sh` 取主线后重锚 623,784；`Index.ets`（media+default4 双改点）、`App.cs`、`build-arkts-shell.sh` 自动并，union 复核。
- maui：零冲突（`OpenHarmonyMauiAppHost.cs` 两改点不同文件区域，自动并）。

## 3) abc / packs（唯一一次重编）

- ui **623,784/`58c5829b…`**（= 623,732 + 52 B SUBWINDOW-DEFAULT4 壳增量；MODAL-OVERLAY 为切片侧、无壳增量）、headless **24,324/`798b2477…`**；四包 22/23/24/28 与 `abc-provenance.json` 逐字节一致；EXPECT/`selftest-verify-kit` 重锚（`--install-packs` 后 provenance gate clean）。

## 4) 门禁（合并树）

- 套件 **796/799 floor 779**（declared==printed、0 Unhandled、frame+a11y within；本地与 CI 同线）；pixel `PIXEL ASSERTIONS PASSED`；host **164/164** + `--cross-check` **164/164**（对合并 maui 切片）；preflight **OK 5/5**。
- `cut-kit.sh --kit 54 --phase P0 --dry-run` **PASS**（pins `36da77cba4`/packs 623,784/suite 779/导出 164/selftests 2/2/docs #54）。

## 5) #54 终刷 / pin / CI

- tester-docs 终刷：19 文件 623,732 → **623,784/`58c5829b…`**（commit `5ce9df274ef`；pre-release 注记；kit 未切）。
- 三 workflow `MAUI_OHOS_REF` → `36da77cba492`（pin `60dda54`）；CI **6/6** @ `34b53ea`：interaction `38128268123` · pixel `38128268094` · host-export `38128268048` · ridgraph `38128267992` · markdownlint `38128268124` + harmony `38128268008`（push 路径命中 `build-arkts-shell.sh`，自动触发）。

## 6) 不确定项

- 直推 SSL 曾 `unexpected eof`；`-c http.version=HTTP/1.1` 即通（runtime-ohos 与 ow 均此法），未动用 Git Data API 旁路。
- harmony-flavor 因 `build-arkts-shell.sh` 在推送 diff 内而自动触发；后续不含该路径的 shell 改动需手动 dispatch。
- 发布件（tar/bundle/预签）仍为 #53 数字，kit 未切（rc.2 WAIT）。
