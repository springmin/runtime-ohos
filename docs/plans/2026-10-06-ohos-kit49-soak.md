# SOAK49：kit #49 AOT 40 min 浸泡 + 子窗 churn ×20 + 主窗 hide/show→子窗 suspend/resume ×10 —— 0 崩 / 0 残留（2026-10-06）

> 设备 HAD-W32（OpenHarmony 7.0.0.111 / API 26 / 2in1，UDID `1BCE13C8…`，hdc `127.0.0.1:35111`），独占
> 02:31–03:25（`.device-lock` owner=soak49）。件：kit #49 tar **67,888,851 / `477974bb…`**、树 `8d03cb4c…`、
> sidecar ok。方法 = `device-round.sh --mode aot --soak-min 40`（6/6 步 ok；装载后 pid 7271）+ 自研
> `bin/{churn,suspend-resume}.sh`（常驻 hilog 流 + 每循环 VmRSS/Threads + WMS 残留判据）；本轮聚焦 AOT +
> 子窗新路径（JIT/interp 承 SOAK48）。证据 `reg-kit49/soak49/soak49-evidence.tar.gz`（**25,983,542 B / `c9ee6efd…`**）。

## 1) 子窗 churn ×20（`app://subwindow/demo` create→move→resize→close）

| 判据 | 结果 |
|---|---|
| create / move / resize / close | 20/20 / 20/20 / 20/20 / 20/20（另校准 1 对 id=366，共 **21/21**） |
| WMS `ohos_dotnet_subwindow` 残留 | 每次 close 后 **0**（触发前也恒 0） |
| pid / 线程 | pid 16043 恒定；threads 74–76（首 75 末 75，无单调增长） |
| RSS / 崩 | 205,820→213,028 kB（**+7.0 MB**，小步热身/缓存；0 CppCrash/AppFreeze/JSCRASH） |

## 2) 主窗 hide/show → 子窗 suspend/resume ×10（标题栏最小化按钮 (2464,318)）

- **10/10 created+suspended+resumed+closed**：`main window hidden: subwindow suspended` /
  `main window shown: subwindow resumed` 各 10；WMS 残留 0/10；pid 7271 恒定；threads 74–75；
  RSS +1.5 MB；0 崩。
- 方法校正：v1 用 `uitest uiInput keyEvent Home`——窗口确被挂后台（`aa start` 后出现 resumed）但壳收不到
  `WINDOW_HIDDEN`（9 轮 suspended=0）；改点标题栏最小化后 WINDOW_HIDDEN 同秒到达。v1 留档
  `out/suspend-homekey-failed/`（属输入路径差异，非产品缺陷/最小复现见该目录）。

## 3) 40 min AOT soak（`device-round.sh --soak-min 40`，60 s 采样；含 §2 的 10 轮负载）

- 41 采样（t=0..40）：pid 7271 首=末；**pid_lost=0 / fault_new=0**；`updateTime` `1791225789545` 首=末
  （无重装/重启）；power 恒 AWAKE。
- RSS 236,016→227,756 kB（**−8.3 MB**；min 209,688 / max 237,584 = 热身→GC 锯齿，无单调增长）；
  threads 67–76（首 71 末 67）；0 CppCrash / 0 AppFreeze / 0 JSCRASH。
- 已知非新告警：最小化期间 `set window title failed` E（round49 手测同现，窗口正常化即止）；
  `AceSubWindow: Fail to get subwindow in dialogSubwindowMap_` WARN 每 close 1 条（round49 已登记）。

## 4) 结论 / 异常 / 边界

- **背书：可以** —— 40 min + churn 21/21 + suspend 10/10：0 崩 / 0 失 pid / 0 重启 / 0 窗口残留；
  线程稳定、RSS 无累积增长。异常仅方法项（Home 键不触发 WINDOW_HIDDEN，已改最小化点击）与环境项
  （清理昨日 kit #47 `device-round/run{1,2}` 遗留 `hdc hilog` 流 2 条，经 /proc/fd 确认非本轮）。
- 边界：单设备 2in1 debug 域；churn 在 round49 实例（pid 16043）、soak/suspend 在新装实例（pid 7271）；
  子窗仍为壳侧 ArkUI 自绘（单 surface）；未测 split 拖拽与 0×0 收窗保帧。

## 5) 证据 / 提交

- 证据：`reg-kit49/soak49/soak49-evidence.tar.gz`（25,983,542 B / `c9ee6efd…`；含 device-round 归档
  26,172,444 B / `586ec0ec…`、churn/suspend CSV + 过滤 hilog、SUMMARY.md、脚本 `bin/`）。
- 提交：本文件 + `docs/plans/README.md` 索引（runtime-ohos `feature/openharmony`；`commit-paths.sh`
  限定路径、普通推送、未强推）。
