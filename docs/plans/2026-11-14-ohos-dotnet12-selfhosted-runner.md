# .NET 12 OpenHarmony self-hosted runner 需求（提案）

> 2026-11-14。目标：把 .NET 11 期间靠手工执行的 clean-machine 与设备门禁迁到
> `[self-hosted, openharmony]` runner，供 .NET 12 的每个 RC/GA 使用。P3 已接受
> .NET 11 用“手工 clean-machine + hosted 离线 CI + 手工设备 round”收口，本文件是
> .NET 12 的迁移清单。

## 1. 结论

- hosted runner 继续跑纯离线合约（`ohos-install-tests`、`ohos-workload-selftest`）。
- self-hosted runner 只跑需要 OpenHarmony 主机/设备的部分：
  - `clean-machine-ga.sh`（安装、workload、826、JIT、AOT）
  - `device-round.sh --suite`（11/11）
  - `ohos-aot-host-provenance` 可以留在 hosted（只下载 nupkg 校验 SHA）
- 一台 runner 绑定一台设备；用设备锁串行化，禁止并跑两个 round。

## 2. Runner 主机

| 项 | 要求 |
|---|---|
| 系统 | OpenHarmony 2in1（HAD-W32/HAD-W24 同级），arm64 |
| 标签 | `self-hosted`, `openharmony`, `ohos-arm64` |
| 磁盘 | ≥ 80 GB 可用（clean root + SDK + AOT feed + 截图/归档） |
| 内存 | ≥ 16 GB（AOT publish 与 Ninja 峰值） |
| 网络 | 能访问 github.com、nuget.org；release 资产可下载 |
| 工具 | `hdc`（ohos-clt 或 harmonybrew）、`python3`、`zip`/`unzip`、`tar`、`jq`、`gh`、`git`、`curl` |

## 3. 设备与 hdc

- 设备通过 **loopback 无线调试** 接入：`hdc tconn 127.0.0.1:<port>`。
- 端口会变（35111 只是历史值）。runner 启动时扫描 `127.0.0.1` 开放端口，逐个
  `tconn`，以 `hdc list targets -v` 的 `Connected` 为准；旧 key 显示 `Offline`
  时不要使用。
- `~/.ohos-tools/hdcp4` 作为 patched hdc fallback（`OHOS_HDC_PATCHED`）；
  只有 stock hdc 返回 `[Empty]` 时才启用。
- 设备锁：`mkdir .device-lock` + `owner`，与本地 round 共用协议；
  `DEVICE_ROUND_LOCK_ATTEMPTS/INTERVAL/STALE` 可配。
- 每轮结束：
  - `hilog -G 512K` 还原缓冲
  - 释放设备锁
  - 保持屏幕 AWAKE（`PowerManager AWAKE`）
  - 关闭原生 Drawer overlay（slots/a11y 前）

## 4. Clean-machine 缓存与 I/O

- `NUGET_PACKAGES` 指向 runner 的持久缓存（不要每次冷下载）；`COLD_NUGET=1`
  只作为单独的夜间任务。
- 缓存 SDK tarball、workload bundle、AOT feed（`~/.cache/ohos-ci`）。
- **不要**在 clean SDK 上直接 `dotnet build` 826 harness：本机 I/O 会卡数小时。
  采用已验证的做法：
  1. host GA SDK 编译 826 harness（`-m:1 -nodeReuse:false`）
  2. clean SDK 运行 `verify.dll`
  3. JIT/AOT 在 clean SDK 上 publish
- AOT feed 必须含 `Microsoft.NET.ILLink.Tasks`（11.0.0 线已补
  `11.0.0-rc.3.26522.148`；11.0.1 线为 `11.0.0-rtm.26472.124`）。
- 内存门禁：`MemAvailable ≥ 2 GB`；重构建期间等待（publish-aot 已有 guard）。

## 5. 工作流改造

### 5.1 `ohos-clean-machine.yml`

- `runs-on: [self-hosted, openharmony, ohos-arm64]`
- `sdk_ref` 默认跟随 dispatch 分支：
  `ref: ${{ inputs.sdk_ref || github.ref_name }}`
- 输入：`skip_device`、`cold_nuget`、`sdk_tarball`、`workload_bundle`、
  `aot_assets`
- 失败时上传：`clean-*/logs/**`、AOT/JIT 日志、`summary.txt`

### 5.2 新增 `ohos-device-round.yml`

- `workflow_dispatch` + `schedule`（夜间）
- 输入：`kit`（默认 GA kit）、`mode`（aot/jit）、`suite`、`soak_min`
- 步骤：hdc 端口发现 → `device-round.sh --suite` → 上传
  `device-round-*.tar.gz` + `summary.txt` + `steps.tsv`
- 设备锁超时直接失败，不重试超过 30 分钟

### 5.3 保留 hosted

- `ohos-install-tests`（离线）
- `ohos-workload-selftest`（离线；已包含完整 device-round 合约）
- `ohos-aot-host-provenance`（下载 + SHA/targets 校验）

## 6. 凭据与签名

- `OHOS_RELEASE_TOKEN`：仅 release 上传 job 使用；runner 上最小权限。
- 设备签名：GA `selfsign-ohos-arm64`（静态）；`SELFSIGN_SHA256` 按线 pin。
- 不要把 keystore/p12 放进日志；`sign-for-device.sh` 已做 fail-closed 与
  UDID 校验。
- `binary-sign-tool` 只作为 selfsign 不可用时的 fallback。

## 7. 验收标准

在全新 runner 上，无人工步骤完成：

1. `clean-machine-ga.sh`：install/workload/pack + 826 `826/829` + JIT signed HAP
   + AOT `EXIT=0`、`IL2026/3050/3051 = 0`
2. `device-round.sh --suite`：11/11、failures=0、archive 生成
3. 失败时 artifact 含 hilog/截图/summary/steps
4. 单轮总时长 ≤ 45 分钟（含 5 分钟 soak）
5. 设备锁在异常退出后 20 分钟内可回收

## 8. 风险

- 无线调试端口变化：必须保留端口扫描，不要把 35111 写死。
- runner 的 OpenHarmony 版本/驱动漂移：固定镜像与 SDK，升级走单独 PR。
- 磁盘/IO 慢：clean SDK build 826 会卡；坚持 host 编译 + clean 运行。
- 设备被人工占用：设备锁 + 队列；夜间任务避开人工时段。
- hosted CI 与 self-hosted 结果不一致：离线合约留在 hosted，设备/安装只信
  self-hosted。

## 9. 迁移顺序

1. .NET 12 preview：新增 runner，先跑 `ohos-clean-machine.yml`（手动 dispatch）
2. 稳定后加夜间 `device-round`
3. 把 .NET 11 的手工证据目录（`device-round-*.tar.gz`、`dev-ga-evidence`）作为
   基线，后续自动结果与基线对比
