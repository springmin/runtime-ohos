# 一条命令跑完一轮真机测试（tester-run.sh）

> 面向拿到 device-test-kit、手上有设备/`hdc` 的测试者：把「校验 kit → 安装 → 启动 → 抓 hilog → 跑 P1–P4 探针 → 打包回传」串成一条命令。
> `tester-run.sh` 是 `device-test-kit` release 上的**独立资产**（不在 kit 的 `SHA256SUMS` 内，kit 本身无需重下）；脚本默认 **dry-run**，不加动作参数不会碰设备。
> 当前脚本 = **v6r2**（内嵌 `script_version=6`，2026-09-24）：行为与输出字段对旧调用兼容；`--tree-digest` 复用已校验摘要（P16）明显更快，证据包新增 `meta/kit-hap-sha256.txt` 与 `summary.txt` 的 `main_hap_sha256`。
> 逐项清单与判读仍见 `docs/plans/2026-09-19-ohos-hap-acceptance-for-testers.md`（包内名 `验收说明.md`）；探针定义见 `docs/plans/2026-09-21-ohos-crash-probes.md`。

## 1. 它做什么

| 步骤 | 内容 | 触发参数 |
|---|---|---|
| 0 | 定位 kit（解压目录或 `.tar.gz`）：sidecar `sha256sum -c` → `sh verify-kit.sh`（含内容树摘要，P16 复用已校验摘要）→ 可选 `--expect-tree-digest` 绑定解压内容 | 无（总是执行，纯本地）|
| 1 | `hdc install -r` 主 hap；记录安装结果码并给出 `9568344` / `9568297` / `E00C001` 提示 | `--install` |
| 2 | `aa start -b <module.json 里的 bundleName> -a EntryAbility`，数秒后用 `pidof`（回退 `ps -ef`）判定进程存活 | `--start` |
| 3 | `hilog -r` → 开录 →（若同时加 `--start`）启动应用 → 录 N 秒 → 按关键字过滤 | `--capture [N]`（默认 30 秒）|
| 4 | 安装并运行 `probe1..probe4`，逐个抓 `PROBE1..PROBE4` 行（含各自的 hilog 原文）| `--probes <dir>` |
| 5 | 采集 hilog/探针日志、`module.json`、`param get` + UDID、kit 哈希、`summary.txt`，打包 `tester-report-<时间戳>.tar.gz` | 有设备动作时总是执行 |

`--device <id>` 会让每条 hdc 命令都带 `-t <id>`；`--out <dir>` 改报告目录（默认 `./tester-report`）；`--hap <hap>` 用指定 hap 代替 kit 默认包（可重复，主包取第一个）。

## 2. 下载与自检

```sh
base=https://github.com/springmin/sdk-ohos/releases/download
curl -L -O "$base/device-test-kit/tester-run.sh"
sh tester-run.sh --help
# 资产摘要以 release 资产页 / API 为准（本文不写死哈希）：
gh api repos/springmin/sdk-ohos/releases/tags/device-test-kit \
  --jq '.assets[] | select(.name=="tester-run.sh") | .digest'
sha256sum tester-run.sh
```

## 3. 一条命令（完整一轮）

```sh
base=https://github.com/springmin/sdk-ohos/releases/download
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz"
curl -L -O "$base/device-test-kit/device-test-kit.tar.gz.sha256"
sh tester-run.sh --kit-tar ./device-test-kit.tar.gz --install --start --capture 30
```

- 建议同时用发布说明「Integrity」的 tree sha256 绑定解压内容：加 `--expect-tree-digest <hex>`。
- **API 20 波段设备**用 api20 包（先解压 kit）：`sh tester-run.sh --kit-dir ./device-test-kit --install --hap ./device-test-kit/hello-maui-app-api20.hap`。
- **启动崩溃排查**（探针 hap 是未签名的，先按 `自签说明.md` 自签到位）：`sh tester-run.sh --kit-dir ./device-test-kit --probes ./probes`。

## 4. 常用组合

| 目的 | 命令 |
|---|---|
| 只看计划（安全，不碰设备）| `sh tester-run.sh --kit-tar ./device-test-kit.tar.gz` |
| 完整一轮 | `sh tester-run.sh --kit-dir ./device-test-kit --install --start --capture 30` |
| 只录 hilog 60 秒（自己操作应用）| `sh tester-run.sh --kit-dir ./device-test-kit --capture 60` |
| 只跑 4 个探针 | `sh tester-run.sh --kit-dir ./device-test-kit --probes ./probes` |
| 显式卸载（主应用 + 4 个探针）| `sh tester-run.sh --kit-dir ./device-test-kit --uninstall --probes ./probes` |
| 多设备环境指定目标 | 以上任一命令再加 `--device <hdc list targets 里的 id>` |

## 5. 它执行的命令（精确）

以下 `<D>` 表示 `hdc`，给了 `--device <id>` 时表示 `hdc -t <id>`：

```sh
# 0 本地校验
( cd <kit.tar.gz 所在目录> && sha256sum -c <kit>.tar.gz.sha256 )
tar xzf <kit>.tar.gz -C <临时目录>
( cd <kit> && sh verify-kit.sh --tree-digest [--expect-tree-digest <hex>] )

# 1/4 每个 hap（主包、--hap、以及 probe1..probe4）
<D> install -r <hap>

# 2 启动与存活
<D> shell aa start -a EntryAbility -b <bundle>
<D> shell pidof <bundle>            # 为空时回退 <D> shell ps -ef | grep <bundle>

# 3 hilog（录制 N 秒后停止；先 -r 清缓冲）
<D> shell hilog -r
<D> hilog > <out>/hilog/hilog-full.txt &
grep -E 'hellomaui|maui|dotnet|openharmonyhost|AppKilledReporter|JsError|appspawn|PROBE' \
  hilog-full.txt > hilog-filtered.txt

# 5 设备信息与 UDID
<D> shell param get const.product.model / const.product.brand / … / const.build.characteristics
<D> shell bm get -u

# 仅 --uninstall（显式）
<D> uninstall <bundle>              # 加了 --probes 时也卸载 4 个 probe 包
```

`v6r2` 另在设备窗口内自动采集（无需手工 grep）：`hilog -t kmsg` → `kmsg/`、`xpm_mode`/`require_signatures`、`SoInfoSegment` 命中数，以及 app-lib 证据 ——
`hilog/hilog-applib.txt`（`SetAppLibPath|appLibPathKey|NativeLibPath|lib path`）、`hilog/hilog-dlopen.txt`（`dlopen|cannot find library|openharmonyhost`）、
`device/app-libs-arm64.txt`（`ls -l /data/storage/el1/bundle/libs/arm64/`）。判读要点：`appLibPathKey: <bundle>/<module>` 出现 = 模块级 app-lib key 已注册（`libIsolation` 生效）；
`[openharmony-host] … bound via alias '…'` 出现 = 宿主加载并绑定到该别名；首帧成功信号 = `registerXComponent=function`、首帧出现、无 `Load native module failed`。
`--extra-probes <dir>` 可把 importprobe/importb/importd 等载荷按与 P1–P4 相同的「装 → 启 → 录」流程一并采集。

## 6. 回传什么

脚本最后会打印归档绝对路径：

```sh
# 形如 ./tester-report-<YYYYmmdd-HHMMSS>.tar.gz，旁边有同名 .sha256
sha256sum -c ./tester-report-<时间戳>.tar.gz.sha256
```

把 `tester-report-<时间戳>.tar.gz`（连同 `.sha256`）通过**收到 device-test-kit 的同一渠道**（邮件/IM/工单）发回给交付方；GitHub 用户可在 `springmin/sdk-ohos` 开 issue 附归档。
归档内固定包含：`summary.txt`（机器可读，`KEY=value`：`script_version`、kit/tree 摘要、`main_hap_sha256`、bundle、安装/启动/存活结果、每条 hilog 行数、app-lib/dlopen 证据行数、`probe1..probe4` 结果、`failures`）、`hilog/`（含 `hilog-applib.txt`、`hilog-dlopen.txt`）、`probes/`、`kmsg/`、`device/param-get.txt`、`device/udid.txt`、`device/app-libs-arm64.txt`、`meta/module.json`、`meta/SHA256SUMS`、`meta/kit-hap-sha256.txt`。v6r2 的字段/文件对旧版归档是超集，解析方按 `KEY=value` 读即可。
若安装报 `9568344`，归档里的 UDID 可直接用于重签；`summary.txt` 的 `main_install_result=code:9568344` 即为凭据。

## 7. 安全说明

- **默认 dry-run**：不加 `--install` / `--uninstall` / `--start` / `--capture` / `--probes`，只做本地 kit 校验并打印计划，不创建报告目录、不打包。
- **无设备拒绝执行**：`hdc list targets` 为空（或 `--device` 指定的 id 不在列表）时——带动作参数立即退出 3；不带动作参数则只做本地校验、打印计划后退出 3。
- **卸载只认 `--uninstall`**，且只卸载主应用（给 `--probes` 时加 4 个探针包），绝不隐式卸载。
- `--kit-tar` 缺 sidecar 时**拒绝解压**（fail closed）；校验失败先重新下载，不要带病安装。
- 探针 hap 未签名，需要先自签（`自签说明.md`）；脚本不做签名、不生成密钥、不上传任何东西。
- `--extra-probes <dir>`（可重复，或逗号分隔多个目录；重复目录只处理一次）：把目录内全部 `*.hap`（importprobe a–c、importb/importd 载荷等）按 P1–P4 相同的「装 → 启 → 录」流程采集，命中行并入 `probes/probe-all-lines.txt`。

## 8. 退出码

| 码 | 含义 |
|---|---|
| 0 | 成功（有设备时的完整一轮，或 dry-run 计划打印完成）|
| 1 | 有步骤失败：归档仍会生成，详情见 `summary.txt` 的 `failures` 与各步骤键 |
| 2 | 用法错误（缺参数值、路径不存在、找不到 kit 等）|
| 3 | 无设备 / 拒绝执行（含无设备时的 dry-run）|

## 9. 相关文档

- 快速上手（一页版）：`docs/plans/2026-09-20-ohos-tester-quickstart.md`（包内名 `快速开始.md`）
- 真机操作手册：`docs/plans/2026-09-21-ohos-device-run-playbook.md`（包内名 `真机操作手册.md`）
- 完整验收清单：`docs/plans/2026-09-19-ohos-hap-acceptance-for-testers.md`（包内名 `验收说明.md`）
- 启动崩溃探针 P1–P4：`docs/plans/2026-09-21-ohos-crash-probes.md`
- 回传模板：`docs/plans/2026-09-21-ohos-device-report-template.md`
