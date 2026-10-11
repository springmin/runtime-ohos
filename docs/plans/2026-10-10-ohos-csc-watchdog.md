# csc 活锁防呆接入 preflight（CSC-WATCHDOG-INTEGRATION，2026-10-10）

> 范围：ow `tooling/csc-watchdog`（包装器 + preflight 接入 + selftest，已轻并 master）；runtime 本档。maui 未动、pin 不变、#49–#53 资产不动、本 session 无构建（让行 bun ninja）。

## 1) 包装器 `ohos-workload/scripts/run-with-csc-watchdog.sh <cmd…>`

- 复用 runtime `scripts/ohos-csc-watchdog.sh`（解析序：`$CSC_WATCHDOG_SCRIPT` → `$RUNTIME_REPO` → 兄弟 `../runtime-ohos` → 本仓 scripts/）。
- 监视 csc/VBCSCompiler：/proc io + `/out:` 工件 + 服务器请求集无增长；spin 默认 480s、idle 300s（5–8min 档，`CSC_WATCHDOG_SPIN_TIMEOUT`/`IDLE_TIMEOUT`/`POLL` 可配）。
- 触发：kill 卡死链 → attempt1 日志+证据保留 → 整条命令以 `DOTNET_PROCESSOR_COUNT=1`（+`UseSharedCompilation=false`）重跑一次（attempt2 独立日志）。
- 二次仍卡 → 非零 fail-closed、不再重试；`CSC_WATCHDOG=0` 关闭；无 watchdog 可解析/无 bash 时告警直跑（CI Linux 无感）。

## 2) 接入点

- 步骤 4（interaction build）与步骤 5（pixel `dotnet run` + host fallback build）经包装器；证据入 `<preflight log>/csc-watchdog/run-*/`。
- 步骤 1 selftest 链增 `selftest-csc-watchdog.sh`；cut-kit P2 评估为纯 verify（无托管编译）→ 不接。

## 3) 自测/CI

- `selftest-csc-watchdog.sh` 34/34 PASS：stub 首杀重跑 / 二杀 fail-closed / 关闭开关 / 无杀不重跑 / 无 watchdog 直跑 + 真实 watchdog 假 `csc` 自旋两场景；`sh -n` 全绿。
- ow：分支 `dd5734b` → master merge `55044da` 已推；CI 5/5 success（markdownlint/ridgraph-sync/host-export-contract/pixel-regression/interaction-regression）。
- 本次未跑整套 preflight（构建让行 bun ninja）；接入冒烟 = selftest 走 `sh` 入口 + 目标步命令逐字核对。

## 4) 不确定项

- 非 csc 的 MSBuild 死锁不触发（沿用原时长）；二次仍卡总耗时 ≈ spin 480s ×2 + kill 收尾。
- 无 runtime-ohos 兄弟检出时直跑（仅告警）；若需 CI 侧强保障需把 watchdog 宿主化进 ow（未做）。
