# DEVICE-ROUND：设备轮自动化脚本（device-round.sh，kit #47 本机短跑验证，2026-10-05）

> 承接本轮散落 scratch（`a11y45/`、`fix-a11yflyout/`、`soak-ji/`、`interp-draw2/` 里的
> `round*.sh`/`lockwait.sh`/`soak-path.sh`）。把「资产核验→重签→装/启/首帧→Blazor A/B→动态槽→a11y→
> 深链→tester-run v14 probe→短 soak→归档」固化成一条命令；复用 kit 内 `verify-kit.sh`/`tester-run.sh`（v14）
> 与 `scripts/sign-for-device.sh`，不重写。脚本 = ohos-workload `scripts/device-round.sh`（+ selftest）。

## 1. 用法与覆盖步骤

```sh
sh scripts/device-round.sh --kit <device-test-kit.tar.gz|目录> [--mode aot|jit] [--suite] \
  [--out <dir>] [--soak-min N] [--blazor|--slots|--a11y|--deeplink] [--uninstall] [--dry-run]
```

- 核心（默认）：设备锁 → 资产核验（sidecar/SUMS/tree/KIT OK）→ 重签 → `tester-run` 装/启/录制 →
  `canvas presented` + 首帧截图/layout → tester-run v14 dry-run probe → 短 soak（默认 5 min）→
  证据 `tar.gz`（log/截图/json/summary/steps）。
- `--suite` = Blazor A/B（重签 default+nocsp、BLZ 标记、/counter 点击）+ 动态槽（绿块定位 3/5 控件、
  destroy/create、`[maui-capacity]` 原文）+ a11y 探针 + 深链冷/热激活（`aa start -U app://…`）。
- JIT：`--mode jit` 需 `--hap`（DeviceCompat 预检：libs 无扩展名/恰 4096 B 条目告警 + 重出包提示）。
- 健壮性：每步失败不中断并写 `steps.tsv`/`summary.txt`；`hilog -G 16M` 临时、退出还原；
  `10106102` 锁屏提示；锁超时退出 1、无设备退出 3（两者仍归档）。锁协议 = `mkdir .device-lock` +
  owner 文件（重试/陈旧回收/退出释放，默认 `/data/storage/el2/base/tmp/opencode/.device-lock`）。

## 2. 本机验证（kit #47，HAD-W32 / OpenHarmony-7.0.0.109；UDID `1BCE13C8…`）

- dry-run 两次（解包目录 + tar）：tree `0f266636…` == 发布值、sidecar OK、未碰设备（stub 日志空）。
- run1 `--suite --capture 20 --uninstall`：核验/锁/装启（pid 34367）/首帧/Blazor A/B 全过
  （BLZ_BOOT+BLZ_RENDERED，default/nocsp 点击 `Current count: 1`）；动态槽暴露 2 个脚本缺陷
  （未绑定变量中止、旧前台化逻辑被遮挡）→ 已修。
- run2 `--slots --a11y --deeplink --soak-min 1 --capture 15 --uninstall` **rc=0 全步骤 ok**：
  槽 `web slot create=2 / destroy=1`（3 控件 + remove/re-add；工件样例无 D/E，`[maui-capacity]` 记 0）；
  a11y `nodeCount=67`（槽后 3 覆盖层态）；深链 hot `delivered=1`（pid 65026→65280）；v14 dry-run；soak
  1 min pid_lost=0 fault_new=0；归档 `run2-20261005-093037.tar.gz`（18,373,743 B / `f23f0b9d…`）。

## 3. selftest / 文档 / 提交

- `scripts/selftest-device-round.sh`（stub hdc/tester-run/sign-for-device，含合成绿块截图）：
  **44 checks 全绿**（usage/dry-run/全轮 suite/锁忙超时/陈旧锁回收/JIT 缺件/归档内容）；
  文档 = `scripts/README.md` 两行 + 本文件；提交上述脚本与本文件（`commit-paths.sh` 限定路径、普通推送）。
