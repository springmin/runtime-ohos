# UPSTREAM-TESTS-RUNNER：上游 MAUI 单元测试复跑脚本（工具项③）（2026-10-15）

> 结论：`ohos-workload/scripts/run-upstream-tests.sh` 把 UPSTREAM-TESTS（2026-10-13）的实跑配方封装为一条命令：`--suite core|essentials|controls|all`、`--timebox <秒>`（总预算；到点杀当前命令 → TIMEOUT → 余下 SKIP → 退出 1）、`--no-build`、`--log-dir`；逐相位 tee 日志，每套件一条可解析汇总行，退出码 0/1。本机抽验 Essentials **513/0/0**（build 51 s / run 2 s，exit 0）。不改 maui 源码，全部旁路为参数/环境变量。
> 载体：ow `8c8b5c6`（master；commit-paths；禁强推）＋ 本文。

## 1. 用法与旁路
- `sh scripts/run-upstream-tests.sh [--suite ...] [--timebox <secs>] [--no-build] [--log-dir <dir>]`；env：`MAUI_REPO`（默认兄弟 `../maui-ohos`）、`DOTNET`（默认 `~/.dotnet.rc2-fix/dotnet`，可指任意 11.0.100-rc.2 SDK）、`UPSTREAM_TESTS_LOG_BASE` / `UPSTREAM_TESTS_NUGET_CONFIG` / `UPSTREAM_TESTS_XUNIT_RUNNER`。
- 记录旁路（详见 `2026-10-13-ohos-upstream-tests.md` §2）：`lib-dotnet-env`（MSBuild server/node reuse 关、短 TMPDIR、无 Roslyn server）＋ `DOTNET_NUGET_SIGNATURE_VERIFICATION=false`（PKCS 卡死）＋ 备源 NuGet 配置（nuget.org + dnceng dotnet11；`RestoreDisableParallel=true`、`NuGetAudit=false`；冷并发 HTTP 死锁）＋ `DOTNET_PROCESSOR_COUNT=1`（csc OpenSSL/活锁）＋ 平台 TFM 全关 ＋ xunit console（`dotnet exec`，CWD=输出目录，Core 的 LocalizationTests 依赖）＋ Controls 额外 `-p:RunAnalyzers=false` / `-parallel none`（上游 BannedSymbols 快照 + CSS 开关竞态）。

## 2. 判定与抽验
- 判定：PASS 需退出 0 且 xunit 汇总行 `Errors=0 && Failed=0`；否则 FAIL(exit=…)；超时=TIMEOUT。汇总行示例：`suite=essentials result=PASS total=513 errors=0 failed=0 skipped=0 build=51s run=2s`。
- 抽验（本机 2026-10-15；dotnet 11.0.100-rc.2.26451.112 / maui `1c5ff3cbeb`）：`--suite essentials --timebox 1800` → **513/0/0 PASS**，日志/xml/html 落 `upstream-tests-<ts>/`；`selftest-run-upstream-tests.sh` **47/0**（离线 stub：用法、三套件、失败/编译失败/超时、`--no-build`、两红控、缺前置；preflight 步骤 1 接线）。
- Core/Controls 本轮未复跑（`--suite all --timebox <secs>` 可整跑）；基线见 `2026-10-13-ohos-upstream-tests.md`（Core 1077/0/3、Controls 6441/0/30）。

## 3. 边界
- 上游测试树无 openharmony 平台分支；脚本只跑平台无关 net11.0 单元测试（设备/UI 套件不适用）。
- 需本机有 maui checkout 且 xunit console 已在 `~/.nuget`（首次恢复后即有）；离线可 `--no-build` 复用既有产物。
