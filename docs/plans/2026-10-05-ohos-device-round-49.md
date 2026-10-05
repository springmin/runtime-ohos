# DEVICE-ROUND-49：kit #49 真机背书轮（AOT，HAD-W32，2026-10-05/06）

> 结论：**自动轮 rc=0（6/6 步 ok）**。kit #49 发布件（tar **67,888,851 B / `477974bb…`**、树
> **`8d03cb4c…`**、sidecar ok）在 HAD-W32 2in1（HAD-W24 **7.0.0.111**(SP3ENTC293E104R2P1log) / API 26 /
> UDID `1BCE13C8…`）跑完 `device-round.sh --mode aot`；手动复验 `app://subwindow/demo`
> create/move/resize/close 与主窗 suspend/resume 全通；预签件（**67,807,185 B / `56aaf08f…`**）本地
> sha 与 7/7 verify-app 一致，**未在本机安装**（tester UDID `60CF7B27…` 件）。

## 1. 资产 / 设备 / 纪律

- kit tar sha `477974bb3d45…`、size 67,888,851 == 期望；`verify-kit.sh --tree-digest` tree
  `8d03cb4c…`；本地重签主 hap `hello-maui-app-local.hap` sha `438d235cf080…`（mode=aot）。
- preSigned-haps.tar.gz `56aaf08f700e…`；7 份 `verify-app` 日志全 `verify-app success`（另
  `verify-publish.log` FAILS:0）；未安装（本机 UDID 与 tester UDID 不同）。
- 设备：HUAWEI MateBook Pro（HAD-W32）；hdc 无线 `127.0.0.1:35111`；常亮 `power-shell wakeup` +
  `timeout -o 1800000`；设备互斥锁由本会话 `mkdir .device-lock` 持有，脚本以 `--no-lock` 运行；
  运行期未遇锁屏 `10106102`。脚本：`ohos-workload/scripts/device-round.sh` v1 + tester-run v14。

## 2. 自动轮（steps.tsv 6/6 ok；soak 10 min）

- verify ok → 重签 → install/start rc=0，**pid 16043，runtime_mode=aot(hap)** → first_frame ok
  （`canvas presented (3120x1885)` + `frames/first.jpeg`）→ tester-run v14 dry-run probe ok。
- AOT 路由原文（core hilog）：`jitfort: skipped runtime-mode=aot`、`OHOS_DOTNET probe: 1=OK 2=OK
  3=13 4=1`、`OHOS_HOST start_app aot=1 …/entry/libs/arm64/libhello-maui-app.so`、
  `web overlays mounted on first use`。
- soak：11 采样，pid 16043 恒存；RSS 167,748–182,216 kB、threads 69–75、power=AWAKE；
  `fault_new=0`、`updateTime` 不变（未重启）。归档 `device-round49-20261006-021323.tar.gz`
  （24,485,508 B / `c24c660b…`）。
- 已知告警（#1.8 已登记）：in-kit verify-kit 对 5 壳报 abc 414532 vs 历史期望 375268 的 WARN。

## 3. 手动补验（截图/日志见 `device-round49-manual-20261006-0228.tar.gz` 5,149,043 B / `551d5d8a…`）

- `app://subwindow/demo`（02:17:15–24）：create **id=362 (120,160 720×480)** → page ready
  `name=ohos_dotnet_subwindow drag=on` → move **420,360** → resize **900×600** → closed；
  截图 mw-seq1/2/3/4，主页面状态行与壳 hilog 逐项对上。
- 主窗协同（02:22，另一次 id=365）：`app://subwindow/open` 后点标题栏最小化按钮 → `[maui] main
  window hidden: subwindow suspended`；`aa start` 恢复 → `main window shown: subwindow resumed`；
  `app://subwindow/close` → `subwindow closed`；截图 mw2-open/suspended/resumed/closed；主窗
  `canvas presented` avg=16ms max=21ms（60fps），无新 fault。
- 观察（非失败）：close 时 1 条 `AceSubWindow: Fail to get subwindow in dialogSubwindowMap_`
  WARN；建窗时 3 条 `ParseSubWindowOptions: Failed to convert …` E（可选参数转换，创建仍成功）。

## 4. 边界 / 不确定

- 子窗内容仍为壳侧 ArkUI 自绘（单 surface/renderer，非第二 MAUI 视觉树，L 余量）；soak 仅 10 min。
- 本任务未复跑 a11y 密码脱敏真机（#49 主判点 2 维持「设备未验证」口径）。
- 手动期 hilog 缓冲在 512K/16M 间切换并轮转过一次；suspend/resume 标记用 16M 复跑二次取证。
- 遗留进程：两个昨日 kit #47 脚本开发 run1/run2 的 `hdc hilog` 仍在写
  `/data/storage/el2/base/tmp/opencode/device-round/run{1,2}/…/hilog-full.txt`（非本轮，未处置）。

## 5. 产物

- 本文（runtime-ohos `docs/plans/`）；证据在 scratch（`reg-kit49/device-round49*`，未入库）。
