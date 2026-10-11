# MERGE-BATCH-4：MEDIAELEMENT-ARKWEB A-M1 并入主线 + #54 预刷刷新（2026-10-10）

> 口径：ow `master` ← `feat/mediaelement-arkweb`（`b674f80`）、maui `feature/openharmony` ← 同名（`0adfe6c7fe`），均 `--no-ff`；普通推送、未强推；不切 kit（#54 仅预刷 tester-docs abc 尺寸，rc.2 仍 WAIT）；#49–#53 资产不动；无设备、无上游 PR。

## 1) 合并 SHA

- ow：merge **`0177a32`**（树 `f0370bf5…` 与 `b674f80` 逐字节一致）+ pin **`5e27363`**（`5e273639ab2a`）。
- maui：merge **`fbd91e17bc`**（`fbd91e17bc2a3031766f275d21134561f6a804d2`）。

## 2) 冲突与解法

- 预期计数行/abc/provenance 冲突 **未出现**：两支均为「主线 tip + 单提交」（merge-base = `55044da`/`625177750f`），零文本冲突；如遇并发推进，计数行仅需并集（本次无需）。
- 分支已携带最终 abc/provenance 与 EXPECT（589700,24324），合并树同哈希；`Program.cs` 计数在合并树复跑复核。

## 3) abc / packs（唯一一次重编）

- 重编一次（ui+headless，标准脚本）：ui **589,700/`37c3afdc…`**、headless **24,324/`798b2477…`**；四包 22/23/24/28 与合并树逐字节一致（**零漂移 → EXPECT 不再重锚**）。
- `--install-packs` 0 变更（git status clean）；`selftest-build-arkts-shell` **207/0**、`selftest-verify-kit` **129/0**。

## 4) 门禁（合并树）

- 套件 **776/779 floor 759**（`[suite] checks=776 total=779 floor=759 assert=True`；declared==printed=776、0 Unhandled、frame+a11y within）；A-M1 pins 在案（`amedia shell/page`、`w6/w7 media`、`t20`）；红控引用分支轮：四包 gesture 翻 true → `gestureOptOut=False` 被抓。
- pixel `PIXEL ASSERTIONS PASSED`（宿主 fallback）；导出 **164/164**；preflight **OK 5/5**（ridgraph 20 / packs 25 / hap-targets 84 / tasks 9 / hygiene 25 / host 84+26+47 / csc-watchdog 34；sh -n 56/56；lint 0；interaction+pixel）。
- `cut-kit.sh --kit 54 --phase P0 --dry-run` **PASS**（pins/packs 589700/suite 779/导出 164 entries/selftests 2/2/docs #54）。

## 5) #54 预刷 / pin / CI

- tester-docs abc 预刷：`bump-tester-docs.sh --kit 54` 19 文件 576,664 → **589,700**（18 docs + README；commit `e7737832005`，pre-release 注记；kit 未切）。
- 三 workflow `MAUI_OHOS_REF` → `fbd91e17bc`（pin 提交 `5e27363`）；ow `master` 单推（merge+pin）。
- CI 6/6 @ `5e273639ab`：interaction `38110872949` · pixel `38110872944` · host-export `38110872943` · ridgraph `38110872961` · markdownlint `38110872960` + harmony `38110880469`（手动 dispatch；push 路径过滤不含 `map/**`）。

## 6) 不确定项

- bump 只刷 abc 尺寸，`（`f18f0855…`）` 等旧 sha 后缀未随刷（#53 遗留形；cut-kit 门不校验 sha，属工具既有边界）。
- A-M1 自身边界（HLS/DRM/MPEG-4P2、modal 下 overlay 像素、子窗无媒体服务）见 `2026-10-10-ohos-mediaelement-arkweb.md`。
