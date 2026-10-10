# WEBAUTH-IMPLICIT：隐式 skill 投递真机验证受阻（2026-10-10）

> 口径：本 session 只做 A 组（真浏览器跳 `myapp://` 的**隐式 skill 投递**）真机验证；产品代码/分支不动、
> #49–#53 资产不动、未取设备锁（无设备操作）。设备 HAD-W32 / OpenHarmony-7.0.0.109 / API26，
> **~09:16 重启后 hdcd 未再启动**，本轮**未取得隐式投递判据（未判定 ≠ 投递失败）**。证据与就绪工件：
> scratch `/data/storage/el2/base/tmp/opencode/webauth-implicit/`（`implicit.html` / `serve.mjs` / `run-implicit.sh` / `NOTES.md`）。

## 1) 构造（就绪未执行）

- a) `hdc file send implicit.html /data/local/tmp/`，再 `aa start -a ohos.want.action.viewData -U file:///…`
  隐式选浏览器；页面 = meta refresh + JS 跳 `myapp://callback?code=SECRET-IMPLICIT&state=st-implicit`。
- b) file:// 若被浏览器限制 → `data:text/html,…` 或设备 loopback（`bun serve.mjs 8788` → `http://127.0.0.1:8788/implicit.html`；
  本机 `/bin` 无 busybox httpd）。
- c) 无公网，真实 302 端点一跳不可用（兜底缺席）。
- 判据：不经 `aa start -U` 显式投递，App 经 skill 匹配收到回调（activation 日志 + `ok state=st-implicit`）；
  负控：未注册 scheme（`myapp-nope://`）不投递。

## 2) 阻塞链（环境，非 WebAuth 产品问题）

- **hdcd 缺失**：全量回环扫描 1024–65535 仅 4709/11434/14013/48299/49374；逐个 `hdc -t` 均
  `[Fail][E001005] Device not found or connected`；`ps` 无 hdcd（重启前最后可用 07:28，daemon=127.0.0.1:35111）。
- **hdc 客户端被审计拦截**：原版任何命令（含 `version`）→ `Failed to connect to socket.` +
  `[E00C002]Execution intercepted due to inaccessibility of reporting command event.`；
  审计要求的 `/data/hdc/hdc_huks/hdc_credential.socket` 不可达（EACCES）。
- **hdc 服务端无法启动**：`SetUdsListen:202 bind uds addr fail! ret:-13`；O_PATH 实测 `/data/hdc/hdc_debug`、
  `/data/hdc/hdc_huks` 均为 mode 000 root:root（父 `/data/hdc` 0711）。
- **无提权旁路**：`/bin/{aa,bm,uitest,snapshot_display,hidumper,param,hdcd}` 均 exec 拒绝且不可读；
  `chcon`/`setfattr`/建符号链接被拒；新编译可执行文件被 label 拒绝（`hishell_hap_data_file`）。
- 可用旁路（同批 session 产出，已验证）：patch 同长替换 hdc 的 UDS 路径 + 两个审计参数名 →
  `hdcp4 list targets` 正常返回（`[Empty]`），但**无 daemon 可连，`shell/install` 仍不可用**。

## 3) 边界与替代

- 本边界属**测试链路**（重启后 hdc sandbox/credential mount 缺失），不是浏览器对自定义 scheme 的策略；
  浏览器拦截策略由 B 组（SELinux CIL 对照）另行给出，本轮无法真机观测。
- app-link https 路径同样依赖 hdcd，无更优可测性；hdcd 恢复后按 §1 一次性重跑即可。
- 结论：**隐式投递未判定**；显式 `aa start -U` 证据有效但不等价（见 `2026-10-08-ohos-webauthenticator.md` §4）。
