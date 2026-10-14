# TOOL-HARDEN-B：宿主状态文件 mode 行 + 设备脚本 hdc 回退（2026-10-15）

> 目标：③ 宿主在启动/模式判定后把 `interp=`/`runtime-mode=`/r2r 开关写进既有状态文件 `dotnet-status.txt`（round57 §9 的"下轮建议"；本镜像无 libhilog_ndk，宿主 hilog/stderr 不可见，壳镜像的状态文件是唯一可读通道）；④ 设备脚本 hdc 解析回退——优先 `HDC` env → 常规 `hdc`，`list targets` 为空时回退补丁版并明确日志，避免把沙箱工具门再判成"设备掉线"（kit #57 窗口实为普通 hdc 不可见，设备一直在 36823）。
> 载体：ow（host + scripts + 自测）→ commit-paths → `origin/master`；runtime 本文件 + README 行 → `feature/openharmony`；零 kit 重切（下一刀随重锚）、#49–#57 资产只读、不处理上游 PR。

## ③ 宿主状态文件（`host_status.{h,c}` + `openharmony_host.c`）

- 新纯 C 模块 `host_status.{h,c}`：既有 `OhosHostAppendStatusLine` 的扁平化/600 字符 cap/失败静默语义迁入并单测；新增 `OhosHostStatusFormatModeLine`。模式判定后按 `(dir,line)` 去重追加一行：
  `OHOS_HOST mode caller=start_app interp=3 source=manifest runtime-mode=interp source=manifest xwe=0 source=default r2r=off wbcopy=off`
- `interp=`/`runtime-mode=`/`xwe=` token 形态与 hilog 行一致（`tester-run.sh` exec-mem 读者直接命中壳镜像行）；`r2r=off wbcopy=off` 仅 interp=3；load 行（`start_app aot=`/`aot dlopen`/`entry invoking|rc`）与 jitfort/globalization/probe 行如旧。
- host .so 重建：**371,616 B / `33ba896f3676984…`**（was 367,520/`8826adde…`）；导出 164/164、UND 252、DT_NEEDED 白名单零变化；packs `.22/.23/.24/.28/.29` 同步（`.25–.27` 旧线未动）。
- 重锚链：`host-exports.txt`/`host-deps.conf` 不变；host 系与 verify-kit/hap-targets/cut-kit 自测绿；发布件宿主仍 `8826adde`，kit #58 重切时随 EXPECT/四包指纹重锚（新锚即本件 sha）。

## ④ hdc 回退（`tester-run.sh` / `device-round.sh` / `devloop.sh`）

- 解析顺序：`HDC` env → `hdc` PATH → 回退 `OHOS_HDC_PATCHED`（默认 `$HOME/.ohos-tools/hdcp4`）；仅当主 hdc 缺失或 `list targets` 为空时切换并记录（tester-run/devloop stdout、device-round stderr+RUNLOG）；`OHOS_HDC_NO_FALLBACK=1` 关闭；双方皆空的消息点名补丁候选。
- 持久化：scratch `hdcpatched/hdcp4`（sha `1e0ff920…`、3,975,488 B；源 = ohos-clt 库存件 `4fcd78bf…` 经 3 处等长字节替换）→ `~/.ohos-tools/hdcp4` + `.provenance.txt`；二进制不入仓，packaging doc “Device scripts” 节给复制/来源/哈希与 socket 说明。
- 真机（hdcp4）：无 `HDC` env 的 `tester-run.sh --dry-run` 自动回退并记录 `hdc 回退：hdc 看不到设备，改用补丁 hdc /storage/Users/currentUser/.ohos-tools/hdcp4`（rc=0）。

## 自测（全绿）

- 新 `selftest-host-status.sh`：11 checks（T3 单测 **33/33**：文件缺失静默/创建+追加/扁平化/cap/模式行格式/失败形状；T4 构建接线钉；T5 红控关扁平化必失败）。
- 设备脚本：`selftest-devloop` **119**（+S12 回退 ×4）、`selftest-tester-run` **697/697 PASS**（+S22 回退 ×4；在我提交的隔离 worktree 复跑排除并发编辑伪影）、`selftest-device-round` **48**（+T2b 回退）；host registry 6 / window-bridge 12 / a11y-table 14 / clipboard 10、`selftest-verify-kit` 135、`selftest-hap-targets` 96（1 skipped）、`selftest-cut-kit` **217**、`selftest-repo-hygiene` 25 复核绿。

## 设备证据（hdcp4，锁独占→释放；新宿主重签件）

- **AOT**：`OHOS_HOST mode caller=start_app interp=0 source=default runtime-mode=aot source=manifest xwe=0 source=default r2r=default wbcopy=default`；**interp**：`interp=3 source=manifest runtime-mode=interp source=manifest … r2r=off wbcopy=off`（`start_app aot=0`）；**JIT**：`interp=0 source=default runtime-mode=jit source=manifest … r2r=default wbcopy=default`。
- 各件 install rc=0、`canvas presented (2090x1324)`、pid 尾活（零回归）；PRE55 还原 rc=0、锁释放；证据 `/data/storage/el2/base/tmp/opencode/tool-harden-b/out2/`（install/start/stream/summary；流式捕获跨 force-stop/start 以命中壳早期轮询），归档 `tool-harden-b-device-evidence.tar.gz`（5,860,061 B / `c7585ecf…`）。

## 提交 / 不确定项

- 提交：ow `4d4b46e`（host+scripts+docs 一条）+ `8dfa90a`（`maui-platform-verify` 的 CG2-R2R pin 重锚到 `pure_interp` 判定；中间 `e364570` = 他会话 cut-kit P3 payload，三条均已推 `origin/master`）；CI @ `8dfa90a`：interaction/host-export/pixel/ridgraph/markdownlint **5/5 success**；runtime 本文件 + README 行（commit-paths）。
- 不确定项：发布件宿主未随（kit #57 仍 8826adde，需下一刀 kit/预签重出）；`hdcp4` 为环境特定二进制（socket 路径与沙箱绑定，不入仓）；host 重签字节不可复现，重锚以本件 sha 为准；壳镜像的早期轮询是时序竞争，证据按“流式捕获跨 force-stop/start”口径。
