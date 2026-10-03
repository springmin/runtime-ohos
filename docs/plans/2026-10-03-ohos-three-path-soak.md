# 三路径长跑浸泡（SOAK）：JIT / interp / AOT — 受并发代理干扰，未完成（2026-10-03）

> 设备 HAD-W32（OpenHarmony-7.0.0.111 / API 26 / 2in1），hdc `127.0.0.1:35111`；资产同 31 min 基线：
> JIT = kit#42 重签 `jit-kit42-signed.hap`（134,191,593 / `81e3c7fc…`）、interp = rc2b 重组件 `interp-kit42-signed.hap`（134,509,532 / `69bb864d…`）、
> AOT = `host2-aot-signed.hap`（21,849,484 / `e7cc9a5f…`）。单设备分时（同 bundle 不可并行），计划 JIT→interp→AOT 各 58 min；
> 每 60 s 查 pid、每 5 min 全量采样（RSS/线程/fd/canvas 增量/faultlog 崩溃 diff）、T+30/T+55 扰动（抽屉开合 + Back 前后台）。
> 证据 scratch `/data/storage/el2/base/tmp/opencode/soak/`（out/{jit,interp}/samples|perturb|meta、aux/canvas-stream.txt、interference/、fl-now*/、logs/）。

## 1. 执行结论：未完成 — 环境碰撞，非产品判定

- 三轮尝试均被**同设备并发代理**打断：外部持续对同一 bundle `com.example.hellomauiapp` 重装/`aa start`/输入注入（他家 scratch `acl-pack` 20:06、`aot-default` 20:33、`framepacing` 19:56 同期活动）。
- JIT 段（20:03–21:02，13 个采样点）：3 次失 pid 自愈重启（t=20/25/30 min）；**20:28–20:32 4 次 CppCrash（SIGABRT，thread `assertFaultTHR`，崩溃日志映射 `libclrjit.so` → 均为 JIT 件）**；
  崩溃窗后无新崩溃，但 20:54–21:02 有 6+ 次**外部重启**（无崩溃记录；`managed app started` 由外部触发，同刻 WMS/桌面 `AppIconCommonEvent`）。整段共 ~12 次实例启动。
- interp 段（21:02–21:14，**作废**）：我方 21:02:25 装入 rc2b interp（`installTime=1791032545`）→ 21:05:09 **外部重装**（`updateTime=1791032709`）为 JIT 件（运行进程 smaps 见 `libclrjit.so`）→ 此后样本均为外部件，不再有效。
- AOT 段：未执行（停止以避免继续污染设备与数据）。
- 干扰直接证据：外部 `aa start`（AATool pid 60862 @21:05:11）；`updateTime=21:05:09`；该外部 JIT 件 21:17:11 触发 **AppFreeze/APP_INPUT_BLOCK**（pid 46531，life 863 s，输入事件 8 s 未处理），21:21 pid 消失；桌面 hishell CppCrash 20:20/20:33；21:21 后无新崩溃文件。

## 2. 可用数据（仅 JIT 稳定窗口 20:34–20:52，单实例 pid 15274，18 min）

| 指标 | 值 |
|---|---|
| RSS 起/中/末（t=1800/2400/2700 s） | 310,196 → 329,180 → 331,192 kB（+21.0 MB/18 min，未见平台化） |
| 线程 | 79 → 67 |
| fd | **NA**（shell 无 root；`/proc/<pid>/fd` opendir 被拒，无可用替代） |
| canvas 增量 | 0（空闲不重绘）；全段总数 1,631；per-path 流 20:20 后断流，由 aux watcher 补记 |
| 崩溃 / 失 pid | 0 / 0（本窗口）；扰动 p1 20:34:35 BG→FG 成功，pid 不变，`uitest` 全 `No Error`，无锁屏 10106102 |
| interp 有效样本 | 仅 2 点：RSS 334,516 →（t=300 s）353,000 kB；t=300 时件已被外部替换，判废 |

- 与 31 min 短跑差异：短跑 JIT 342,104→243,576 kB（−98.5 MB 热身回落）、0 崩溃/0 重启、canvas 805；本次干净窗仅 18 min 且 +21 MB 缓升，窗口外另有 4 崩溃 + 1 冻结 + 外装/外启 → **不可比**。

## 3. 结论 / 交主会话

- **判据不满足，不作发布背书**：稳定性（0 崩溃/0 重启/0 冻结）与泄漏（RSS 平台化）在并发窗口内均无法判定。
- 31 min 短跑（三路径基线，0 崩溃/0 重启）仍是当前唯一干净长跑证据；本次增量证据 = 同一 JIT 件在**外部安装/启动/输入注入窗口**内出现 4 SIGABRT + 1 APP_INPUT_BLOCK，时间与外部动作重合，指向环境碰撞。
- 建议：在**独占设备窗口**重跑本 harness（`soak/bin/*.sh` 已留档；注意本机 mksh 禁用 `$(( $( ))` 写法、fd 须 root、流断自愈由 aux watcher 兜底），或与并发任务串行化。
- 不确定：外部注入内容/目标不明；外部安装件具体变体不明（仅知映射 libclrjit）；JIT 4 崩溃/1 冻结无法 100% 排除为真实抖动，但窗口重合度高；共享桌面与 hilog 512K→16M 期间的伪影判读以时序为准。
