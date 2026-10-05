# MW4 收口：MULTIWINDOW-M + SEC-SCAN-4 合并树门禁 / pin / CI（MAUI-CONSOLIDATE-MW4，2026-10-05）

> 本波 = MULTIWINDOW-M（maui `b093e33825`、ow `be70a73`+`16df9a3`；报告 `2026-10-05-ohos-multiwindow-m.md`）+ SEC-SCAN-4（maui `5f3efd55e5`；报告 `2026-10-05-ohos-security-scan-4.md`）。三仓：runtime-ohos `feature/openharmony`、ohos-workload `master`、maui-ohos `feature/openharmony`。

## 1. origin 核对

- GitHub API：maui `b093e3382550670936c1c399e3db6c1114cbc302` 在 origin，父 `5f3efd55e59fad4ce7125b3bbb0a1033c61aeb30`（SEC-SCAN-4 密码脱敏）；`git ls-remote`：ow `origin/master` = `16df9a3`（父 `be70a73`，MULTIWINDOW-M 壳+宿主+套件）。

## 2. 合并树门禁（本地复核；共享设备高负载 load≈23）

- 切片：`Microsoft.Maui.Platform.OpenHarmony.csproj -c Release -p:IsAotCompatible=true -p:EnableTrimAnalyzer=true -p:EnableAotAnalyzer=true -warnaserror:IL2026,IL3050` → Build succeeded，**0 error / 0 IL warning**。
- 套件：`[suite] checks=607 total=609 floor=589 assert=True`；printed `[verify]`=607==declared；0 Unhandled；perf/a11y `within=True`。
- 像素：headless-render Release → `PIXEL ASSERTIONS PASSED`（42 PASS，RUN_EXIT=0）。
- 导出：`check-host-exports.py --cross-check --maui-dir …/maui-ohos/src/Core/src/Platform/OpenHarmony` → `OK: all 153 expected exports …`。
- 四包+provenance：preview.22/23/24/28 ui abc **414,532 B / `e016db13…`**、headless 24,324 / `798b2477…`；四包 provenance 逐字节一致（脚本覆盖 .22/.23/.24，.28 手核）；`--check-sources` / `--check-pack-abc` 绿（源哈希 `6e82e4d0…`）。

## 3. pin / 提交 / CI

- 三 workflow pin `ed02203bfd` → **`b093e33825`**（host-export / interaction / pixel；注释 607/609 floor 589、host-export 153/153）。
- 提交：ow **`e0803be`**（`commit-paths.sh`；禁强推；`ls-remote origin/master` 复核 = `e0803be`）。
- CI 5/5 @ `e0803be`：interaction 37321721695、pixel 37321721683、host-export 37321721786、ridgraph 37321722030、markdownlint 37321721810。

## 4. 不确定

- 本地门禁在共享设备上跑（load≈23）；CI 5/5 为最终判据。
- SEC-SCAN-4 的 6 条报告未修项（WebView 区 2 / 供应链 1 / 加固 3）按报告处置；MULTIWINDOW-M 的 L 余量（per-window surface/renderer、OpenWindow 映射）见 M 报告末节。
