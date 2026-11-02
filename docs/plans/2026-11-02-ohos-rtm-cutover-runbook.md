# RTM / kit #59 切换 Runbook（2026-11-02）

> 状态：**预演（dry-run）通过，执行等待 RTM 产物**。本 runbook 把 #59 切换从“临时操作”
> 变成可检查的步骤；`scripts/rtm-cutover.sh` 只读校验，不构建、不写、不推送。
>
> 当前口径（2026-11-02）：SDK `11.0.100-rc.2.26504.105` · workload `1.0.0-preview.29` ·
> MAUI `11.0.0-rc.2.26505.5` · kit #58。五仓 tips 见
> `ohos-workload test/p0-gate/rtm-pins.json`。

## 1. 前置条件（全部满足才进入执行）

| 条件 | 检查 |
|---|---|
| 官方 RTM 产物已发布 | SDK release + workload packs + MAUI 包；`scripts/rc2-official-watch.sh` 退出 10（或 release notes 确认） |
| 五仓可切换 | `runtime-ohos` / `sdk-ohos` / `aspnetcore-ohos` / `maui-ohos` 的 RTM 提交或 tag 可达 |
| 构建空闲 | 无并行 build；`MemAvailable` ≥ 2 GB |
| 设备空闲 | `.device-lock` 不存在；无残留 `mauidemo.dotnet.springmin.com` 进程 |
| 回滚资产在位 | kit #58 tar / hap / 校验和已归档（tar 70,449,999 / `d7e3311b…`） |
| 当前 dry-run 绿 | `sh scripts/rtm-cutover.sh` 版本 pin 全 PASS |

## 2. 执行步骤

### Step 1：记录与冻结

```sh
cd ohos-workload
sh scripts/rtm-cutover.sh                      # 只读，记录五仓 tips
git -C ../runtime-ohos status --porcelain      # 记录 dirty（应只有已知文档）
git -C ../maui-ohos status --porcelain
```

退出标准：五仓 tips 与版本 pin 已记录；kit #58 回滚包可访问；设备锁空闲。

### Step 2：更新五仓与版本 pin

按以下顺序切换（每个仓都先记录旧 tip）：

1. `runtime-ohos`：RTM 运行时提交/tag；确认 `fix/ohos-rc2` 或新 RTM 分支已包含平台补丁。
2. `sdk-ohos`：RTM SDK 的 `feature/openharmony` 提交；记录 `sdk-ohos` 锚。
3. `aspnetcore-ohos`：RTM 提交。
4. `maui-ohos`：RTM upstream + OpenHarmony 切片；确认 4 个侵入文件仍可合并。
5. `ohos-workload`：更新以下文件。

| 对象 | 当前值 | 更新位置 |
|---|---|---|
| workload manifests | `1.0.0-preview.29` | `manifests/<band>/microsoft.net.sdk.openharmony/WorkloadManifest.json` |
| workload packs | `1.0.0-preview.29` | `packs/Microsoft.OpenHarmony.Sdk/<version>/` 等 |
| MAUI 包 | `11.0.0-rc.2.26505.5` | 所有 `test/*/*.csproj`、manifest |
| RTM pin 记录 | 见 JSON | `test/p0-gate/rtm-pins.json` |
| 上游差异基线 | `d32b7992870` | `test/p0-gate/upstream-delta.json` + delta 文档 |
| CI 切片 pin | `868d3c8727b…` | `host-export-contract.yml` / `interaction-regression.yml` / `pixel-regression.yml` 的 `maui_ohos_ref` |
| RID graph pin | `469eae2734a2…` | `ridgraph-sync.yml`（SDK RID 变化时） |

退出标准：`sh scripts/rtm-cutover.sh` 版本 pin 全 PASS（五仓分支差异只报 WARN）。

### Step 3：重建 packs 与壳

```sh
sh scripts/prepare-packs.sh                    # 铺开本地 workload packs
sh scripts/pack-local-workload.sh              # 需要本地 feed 时
sh scripts/build-arkts-shell.sh                # 默认 --jitless；冷构建一次通过
sh scripts/build-login-shell.sh --fresh        # 第二 ability 壳（可选）
```

退出标准：

- stock abc 637,300 B / `4070204a…`（内容不变则无需改 kit 期望）；
- 若 RTM 导致 abc 变化，同步 `EXPECT_ABC`、`verify-kit`、文档与 kit 记录。

### Step 4：P0 门禁

```sh
sh scripts/p0-gate.sh --quick
sh scripts/p0-gate.sh --full
```

- `--quick`：perf fixture 21 checks、上游漂移（先更新基线/容差）、compat/reference pin；
- `--full`：compat IL2026 ≤ 预算、reference IL2026 = 0、IL3050/IL3051 = 0、hap 产出；
- 若 RTM 合法改变预算，更新 `test/p0-gate/il-budget.json` 并在门禁文档记录。

退出标准：quick/full 均 rc=0（SKIP 必须带原因）。

### Step 5：设备轮

按 `2026-10-30-ohos-maui-reference-app.md` 的 runbook：

1. 安装新 kit / hap；
2. 冷启（进程→首帧）与 Run→首帧；
3. 冷启 `-U`：`orders` / `form` / `settings` / `subwindow` / `form/save` 全部 `ps=1`；
4. 第二 ability `LoginAbility`（独立 `:login` 进程）；
5. 1k 列表 fps / PSS；Form 保存；子窗；
6. 产出 metrics JSON，strict 比较：

```sh
sh scripts/perf-gate.sh /path/to/rtm-metrics.json
sh scripts/p0-gate.sh --quick --metrics /path/to/rtm-metrics.json
```

退出标准：设备冒烟全 PASS；perf-gate 无回归。

### Step 6：切 kit #59

```sh
sh scripts/cut-kit.sh --kit 59 --dry-run      # 先看 P0–P6 计划
sh scripts/cut-kit.sh --kit 59                # 正式切包（人工确认）
sh scripts/verify-kit.sh                      # 包内自检
sh scripts/release-checksums.sh               # 校验和
sh scripts/release-notes.sh                   # release notes
```

退出标准：verify-kit FAIL=0；tar/tree/sidecar 指纹记录；release 资产上传完成；文档状态切到 #59。

### Step 7：解冻与归档

- 解除构建/设备冻结；
- 归档：五仓 tips、kit 指纹、p0-gate quick/full 日志、设备截图与 metrics；
- 更新 `docs/plans/README.md`、state-of-port、交接文档。

## 3. 回滚

| 场景 | 动作 |
|---|---|
| RTM 构建/门禁失败 | 回退五仓 pin 到本 runbook 记录的旧 tips；恢复 `rtm-pins.json` / `upstream-delta.json` |
| 设备冒烟失败 | 重装 kit #58；保留 RTM 构建产物与日志，单独立项 |
| kit #59 已发布但发现回归 | 保留 #59 资产，发布 #59.1 或回退下载页；不删历史资产 |

回滚后必须重跑：`rtm-cutover.sh` + `p0-gate.sh --quick` + 设备冒烟（至少冷启/深链）。

## 4. Dry-run 证据（2026-11-02）

`scripts/rtm-cutover.sh` rc=0：

- workload pack / 两个 manifest = `1.0.0-preview.29`；
- MAUI = `11.0.0-rc.2.26505.5`；SDK = `11.0.100-rc.2.26504.105`；
- 五仓 tips：runtime `59dcb688c679`、sdk `18f86ce80f89`（本地 `feat/aotpack-rebuild`，WARN）、
  aspnet `44ec71aa7c06`、maui `efe5b823c8e0`、workload `14562d3bf2bc`；
- CI slice refs：`868d3c8727b…`（3 个 workflow）、`469eae2734a2…`（ridgraph）；
- 结论：**版本 pin 一致；执行等待 RTM 产物**。
