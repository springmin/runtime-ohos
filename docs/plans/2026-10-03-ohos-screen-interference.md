# 屏幕变量判定：灭屏/屏保/NAP 与 SOAK SIGABRT / AppFreeze 不相关；锁屏是 harness 干扰（SCREEN-HYP，2026-10-03）

> 设备 HAD-W32（7.0.0.111 / API 26 / 2in1，hdc 127.0.0.1:35111）；JIT 件 = kit#42 `jit-kit42-signed.hap`（`81e3c7fc…`）。
> A/B 对照：A 强制常亮 / B `power-shell suspend` 90 s→`wakeup`→交互；两组同轮结构（冷启→15 s 稳定→90 s 相→点击→force-stop）。
> 证据 scratch `/data/storage/el2/base/tmp/opencode/screen-hyp/`（`out/{A,B}/{rounds.csv,hilog-events.txt,fault-*}`、`round-N-start.txt`）。
> 对端 `2026-10-03-ohos-jit-abort.md` 已定性 4×SIGABRT = 外部件 MAUI handler race 冷启动未处理异常（非 JIT/非屏控）。

## 1. 两组对照（每轮记 `PowerManager Current State` + `RenderService powerStatus` + fault diff）

| 组 | 屏控实测 | 有效轮次 | 新增 CppCrash | 新增 Freeze/InputBlock | 失 pid |
|---|---|---|---|---|---|
| A 常亮 | `wakeup` + `timeout -o 6h`（每 30 s 重申）；16/16 轮 `pm=AWAKE render=POWER_STATUS_ON` | 16 | 0 | 0 | 0 |
| B 灭屏 | 90 s suspend 中 `pm=INACTIVE render=POWER_STATUS_OFF`，wake 后 app 存活 | 4/11 | 0 | 0 | 0（有效轮） |

- A 跑满 30 min（21:43:33–22:18:40，16 冷启+点击，updateTime 恒定，16 次 `aa start` 全为己方）。
- B 的 4 个有效循环（pid 47114/51466/55870/58389）全部跨 suspend 存活，0 崩溃/0 冻结 → 灭屏/恢复本身不触发 abort/freeze；
  第 3、6–11 轮 `aa start` 被锁屏 10106102 拦截（无样本）；B 在 22:40 被外部 SIGTERM（exit 143）终止（非崩溃）。

## 2. 时间线 / 机制证据

- 历史 4 崩点 20:28:26.267 / 20:29:07.307 / 20:29:24.978 / 20:32:18.119：crashlog 均 `Foreground:Yes`，`enters foreground` 后
  0.68–0.75 s、life 27/43/20/18 s（冷启动窗）；SOAK 采样全 `AWAKE`；JIT-ABORT 归因外部件 handler race → 与屏控无交集。
- **B 组走通完整 NAP 链路**：suspend 后 `Doze`（前台先拒 `ERR_IN_STATE_FOREGROUND`，转后台放行）→ `FreezeFreezeUnit, Freeze`
  （≈95 s）→ 唤醒 `ProcTransitThawSuccess, Thaw`，4/4 冻结后解冻、pid 不变；A 组全程被 `ERR_IN_STATE_FOREGROUND` 拒绝 doze。
- 灭屏即锁：suspend 时 `SUSPEND_MSG: Screen lock` + `UpdateIsLockedState mIsKeyguardLocked 0→1`（22:19:49 / 22:21:49 / 22:25:00
  / 22:27:00）；锁后 `aa start` 10106102（developer mode 不自动解锁）→ 后续冷启动压力无法施加，是 harness 失效而非崩溃。
- 21:17:05.697 AppFreeze（外部件 pid 46531）：`Foreground:Yes`、`powerState:AWAKE`、`IS_FROZEN=0`、`APP_INPUT_BLOCK`，主线程
  `HostCallJs ← ohos_host_request_focus`（输入路径挂起）→ 与屏控无关。

## 3. 判定

- **屏保/灭屏/NAP：与 4×SIGABRT、AppFreeze 不相关。** 崩点全部前台/常亮；非崩时刻无 suspend 记录；B 组显式 freeze→thaw 仍
  0 复现；前台被 NAP 显式豁免；真因是外部件 MAUI handler race 的冷启动未处理异常（JIT-ABORT）。
- **锁屏是长跑 harness 干扰因子**：灭屏→keyguard 锁定→`aa start` 10106102；长跑一旦失去前台就无法自愈重启。

## 4. 缓解 / 建议

- 长跑保留常亮（`wakeup` + `power-shell timeout -o 21600000`）并记录 `render powerStatus`；常亮只作操作保障，**不得**用作崩溃解释。
- 允许灭屏的矩阵先关锁屏/备凭据，否则须对 `10106102` 快速失败并有限重试；每轮记录错误码与 `updateTime`。
- 外部并发重装/启动/输入注入仍是 SOAK 第一干扰源（见 `2026-10-03-ohos-three-path-soak.md`）；屏幕项可排除。

## 5. 不确定 / 限制

- B 臂仅 4 个 app 存活循环即被锁屏中断（且进程被外部 SIGTERM），未完成 30 min 全压；不能外推为“灭屏永不触发”。
- 20:28–20:32 历史 hilog 已被 21:02 buffer reset 清除；屏态只能由 crashlog `Foreground:Yes` + SOAK AWAKE 采样 + 无 suspend 记录推断；设备当前锁屏密码态无法自动解锁，后续设备测试需人工解锁（B 臂 SIGTERM 来源未查明）。
