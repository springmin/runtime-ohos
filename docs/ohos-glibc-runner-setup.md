# glibc 自托管 runner 准备手册（csc SIGSEGV 调查）

面向：负责准备 glibc 构建机的同学/机器。
目标：为 `springmin/runtime-ohos#2`（OpenHarmony 上 csc 编译 1.27 MB 源文件时 SIGSEGV）提供一台**可 dump、可对照**的 glibc 环境，并把复现矩阵、证据收集和验收标准固定下来。

相关材料：

- issue：https://github.com/springmin/runtime-ohos/issues/2
- 现有 GitHub-hosted 复现：`.github/workflows/csc-repro.yml`（run `46002170870`：9/9 `rc=0`，无 dump）
- 冻结 kit：`sdk-ohos/docs/ohos-maui-ga-freeze.md`
- 容器 CI 笔记：`sdk-ohos/docs/ohos-ci-container-builds.md`
- 本手册对应的 runner workflow：`.github/workflows/csc-glibc-runner.yml`

---

## 0. 能证明什么、不能证明什么

| 环境 | 能回答的问题 |
|---|---|
| **glibc x64 自托管** | 同一份 csc/SDK/source 在 glibc 上是否崩溃；内核/ulimit/ptrace 可控；可 dump |
| **glibc x64 + Alpine(musl) 容器** | 崩溃是否与 musl libc/运行时有关（更接近 OHOS 的 libc） |
| **glibc arm64 + linux-musl-arm64 runtime** | 最接近 OHOS 的非 OHOS 复现（同架构 + musl） |
| **OHOS 设备本身** | 最终确认；但当前 `createdump`/ptrace 不可用，拿不到 dump |

**不能**在 glibc x64 上直接运行 OpenHarmony arm64 runtime。glibc runner 的价值是对照、musl 容器、以及 arm64 上的同架构 musl 构建。

---

## 1. 机器规格

| 用途 | 推荐 |
|---|---|
| x64 glibc（首选） | 8 vCPU / 16–32 GB RAM / 100–150 GB NVMe；Ubuntu 24.04 x64 |
| arm64 glibc（同架构 musl） | 8–16 vCPU / 32 GB RAM / 150 GB；Ubuntu 24.04 arm64（Graviton/Ampere/Hetzner CAX） |
| 最低 | 4 vCPU / 8 GB / 80 GB（构建慢，dump 可能不够） |

磁盘预算：仓库 3–5 GB + NuGet 5–10 GB + 构建产物 10–20 GB + 每次 dump 1–3 GB。

---

## 2. 操作系统与 dump 配置（关键）

```sh
sudo apt update
sudo apt install -y git curl jq unzip build-essential libicu-dev zlib1g-dev \
  libssl-dev libkrb5-dev gdb lldb docker.io procps

# ptrace + core
sudo sysctl -w kernel.yama.ptrace_scope=0
sudo sysctl -w fs.suid_dumpable=1
sudo sysctl -w kernel.core_pattern=/var/crash/core.%e.%p.%t
sudo mkdir -p /var/crash && sudo chmod 1777 /var/crash

# 资源限制
ulimit -c unlimited
ulimit -n 65535

# Ubuntu 的 apport 会接管 core，关掉
sudo systemctl disable --now apport
```

持久化：

```sh
# /etc/sysctl.d/99-ohos-dumps.conf
kernel.yama.ptrace_scope = 0
fs.suid_dumpable = 1
kernel.core_pattern = /var/crash/core.%e.%p.%t

# /etc/security/limits.d/99-ohos-dumps.conf
*  soft  core  unlimited
*  hard  core  unlimited
*  soft  nofile  65535
*  hard  nofile  65535
```

.NET 自身 dump（推荐，和 core_pattern 互补）：

```sh
export DOTNET_DbgEnableMiniDump=1
export DOTNET_DbgMiniDumpType=4          # full
export DOTNET_DbgMiniDumpName=/var/crash/csc-%p.dmp
export COMPlus_DbgEnableMiniDump=1
export COMPlus_DbgMiniDumpType=4
```

Docker 跑 musl 容器时必须加 `--cap-add SYS_PTRACE`，否则 createdump 无法 attach。

---

## 3. GitHub runner 注册

```sh
mkdir -p /opt/actions-runner && cd /opt/actions-runner
curl -fL -o runner.tar.gz \
  https://github.com/actions/runner/releases/download/v2.338.2/actions-runner-linux-x64-2.338.2.tar.gz
tar xzf runner.tar.gz

TOKEN=$(gh api -X POST repos/springmin/runtime-ohos/actions/runners/registration-token --jq .token)
./config.sh \
  --url https://github.com/springmin/runtime-ohos \
  --token "$TOKEN" \
  --name glibc-x64-01 \
  --labels self-hosted,linux,x64,glibc,ohos-dump \
  --work _work --unattended --replace

./run.sh
```

arm64 机器：换 `actions-runner-linux-arm64-2.338.2.tar.gz`，标签
`self-hosted,linux,arm64,glibc,ohos-dump`。

标签必须与 `.github/workflows/csc-glibc-runner.yml` 的 `runs-on` 一致：

```yaml
runs-on: [self-hosted, linux, x64, glibc, ohos-dump]
```

建议用 `--ephemeral`（每个 job 重新注册）或一次性 VM；公开仓库的 runner 会执行 PR 代码。

---

## 4. 工具链

```sh
# 与 OHOS SDK 对齐的 .NET 11.0.100（x64）
curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
sudo bash /tmp/dotnet-install.sh --version 11.0.100 --install-dir /usr/share/dotnet
sudo ln -sf /usr/share/dotnet/dotnet /usr/local/bin/dotnet

# dump 分析
dotnet tool install -g dotnet-dump
dotnet tool install -g dotnet-symbol
export PATH="$PATH:$HOME/.dotnet/tools"

# 记录 csc 指纹，与 OHOS SDK 对比
sha256sum /usr/share/dotnet/sdk/11.0.100/Roslyn/bincore/csc.dll
```

Docker 用于 musl 对照（`mcr.microsoft.com/dotnet/sdk:11.0-alpine`）。

---

## 5. 网络放行

出站 HTTPS：

- `github.com`, `api.github.com`, `objects.githubusercontent.com`, `codeload.github.com`
- `builds.dotnet.microsoft.com`（SDK 安装）
- `api.nuget.org`, `globalcdn.nuget.org`
- `pkgs.dev.azure.com`（dnceng，Arcade/依赖）
- `mcr.microsoft.com`（容器镜像）
- 如需要：`ghfast.top`（大 release 资产镜像；glibc 机器网络好时可不用）

---

## 6. 工作流

仓库内新增 `.github/workflows/csc-glibc-runner.yml`：

- `glibc` job：在自托管 runner 上，用宿主 SDK 构建 + dump 矩阵。
- `musl` job：同一 runner 上用 Docker 跑 `dotnet/sdk:11.0-alpine`，`--cap-add SYS_PTRACE`，做 musl 对照。

派发（runner 注册好、标签匹配后）：

```sh
gh workflow run csc-glibc-runner.yml -R springmin/runtime-ohos --ref feature/openharmony \
  -f iterations=10 -f musl=true
```

如果标签不同，改 workflow 的 `runs-on`，或在派发前用 `gh workflow` 的输入（当前 workflow 固定为上述标签，保持简单）。

---

## 7. 复现矩阵

同一份 `ohos-workload/test/maui-platform-verify`（`Program.cs` 1.27 MB）：

| 变体 | 目的 |
|---|---|
| baseline | 默认 JIT/GC/编译器行为 |
| `DOTNET_TieredCompilation=0` | 排除分层编译 |
| `DOTNET_GCHeapHardLimit=1G` / `2G` | 排除 GC 堆上限 |
| `DOTNET_ReadyToRun=0` | 排除 R2R |
| musl 容器（Alpine） | 排除 glibc 因素 |
| arm64 + linux-musl-arm64（可选） | 同架构 musl，最接近 OHOS |

每次 `dotnet build -t:Rebuild --no-restore -m:1 -p:UseSharedCompilation=false -p:RunAnalyzers=false -p:TreatWarningsAsErrors=false`，建议 ≥10 次/变体。

---

## 8. 证据收集

崩溃时：

```sh
# 1) dump 列表
ls -lh /var/crash/csc-*.dmp /var/crash/core.* 2>/dev/null

# 2) dotnet-dump 分析
dotnet-dump analyze /var/crash/csc-<pid>.dmp <<'EOF'
eeversion
threads
clrstack -all
dumpheap -stat
pe -nested
modules
EOF

# 3) 环境
dotnet --info > dotnet-info.txt
uname -a >> dotnet-info.txt
sha256sum /usr/share/dotnet/sdk/11.0.100/Roslyn/bincore/csc.dll >> dotnet-info.txt
dmesg -T | tail -50 > dmesg.txt
```

同时上传：`build-*.log`、`summary.txt`、`dumps/`、`dotnet-info.txt`、`dmesg.txt`。
workflow 已把 `dumps/`、日志和 summary 作为 artifact 上传。

---

## 9. 验收清单

- [ ] runner 在 `gh api repos/springmin/runtime-ohos/actions/runners` 里 `online`
- [ ] `runs-on` 标签匹配（`self-hosted,linux,x64,glibc,ohos-dump`）
- [ ] `kernel.yama.ptrace_scope=0`、`ulimit -c unlimited`、`apport` 已停
- [ ] `dotnet --version` = 11.0.100（或与 OHOS SDK 同 commit 的版本）
- [ ] `sha256sum csc.dll` 已记录
- [ ] 手工跑一次 `csc-glibc-runner.yml`：`glibc` job 绿/或按预期崩溃并产出 dump
- [ ] `musl=true` 时：Alpine job 能完成 restore/build，dump 目录可写
- [ ] artifact 里有 `summary.txt` + `build-*.log` + （如有）`*.dmp`
- [ ] 结果回填到 `runtime-ohos#2`

---

## 10. 安全

- 公开仓库的 self-hosted runner 会执行任意 PR 代码：专用 VM、无 secrets、出站白名单、定期重建。
- 不要把 GitHub PAT、签名材料、设备 UDID 放在这台机器上。
- 需要长期保留时，优先 `--ephemeral` + 自动重注册，而不是长期在线。

---

## 11. 快速命令汇总

```sh
# 注册（x64）
TOKEN=$(gh api -X POST repos/springmin/runtime-ohos/actions/runners/registration-token --jq .token)
./config.sh --url https://github.com/springmin/runtime-ohos --token "$TOKEN" \
  --name glibc-x64-01 --labels self-hosted,linux,x64,glibc,ohos-dump \
  --work _work --unattended --replace
./run.sh

# 派发
gh workflow run csc-glibc-runner.yml -R springmin/runtime-ohos --ref feature/openharmony \
  -f iterations=10 -f musl=true
```
