# SOAK48：kit #48 三路径 40 min 浸泡 + 槽 churn ×20 + 窗口循环 ×10 —— 0 崩 / 资源回收完整（2026-10-05）

> 设备 HAD-W32（OpenHarmony-7.0.0.x / API 26 / 2in1），hdc `127.0.0.1:35111`；独占窗 20:20–21:19（`.device-lock` owner=soak48）。件（自签，均带 kit #48
> 壳 abc **375,268（`9cd2b4c3…`）** + 宿主 **297,888（`319db8e5…`）**）：AOT = kit #48 `hello-maui-app-unsigned`（22,334,901 B）；JIT R2R = reg-kit48/ow +
> maui 切片（`ed02203bfd`）`RuntimeMode=jit` + Crossgen2 feed + `PublishReadyToRun=true`（145,481,909 B；dll `RTR\0`@2088）；interp R2R = 同切片 + rc2b pack
> （2,410,595 / `5974430509…`）+ R2R（FIXRR；145,965,743 B）。方法：装→`hilog -r`（16M）→40 min 采样窗；5 min pid/RSS/线程/PSS/native/fault/frame；15 min 抽屉+前后台扰动；
> 每段查 `updateTime` 首=末（外部重装）；指纹见证据 `assets/fingerprints.txt`。

## 1) 三路径（各 40 min；0 CppCrash / 0 AppFreeze / 0 失 pid / 0 重启）

| 路径 | 采样窗 | pid / 失 / 重启 | RSS 首→末（Δ） | 峰 / 谷 kB | 线程 | 新崩 | frame | start_ms |
|---|---|---|---|---|---|---|---|---|
| AOT（清洁重跑） | 20:38:44–21:18:45 | 6053 / 0 / 0 | 236,456→272,556 kB（**+36.1 MB**） | 272,556 / 187,324 | 70→68 | 0 | 8,239 | 6,535 |
| JIT R2R | 18:57:19–19:37:20 | 57755 / 0 / 0 | 330,916→358,420 kB（**+27.5 MB**） | 359,904 / 330,916 | 72→71 | 0 | 6,496 | 6,564 |
| interp R2R | 19:38:26–20:18:26 | 24964 / 0 / 0 | 344,336→411,756 kB（**+67.4 MB**） | 411,756 / 344,336 | 73→71 | 0 | 6,713 | 6,566 |

- 末点增量 = 冷启→热热身 + GC 锯齿（JIT 带 357–360 MB；AOT t=1500 回收 220→187 MB 后回平台；interp 30 MB 级锯齿），**无单调增长**；扰动 9/9 通过
  （BG→FG、pid 不变、0 次 `10106102`）；引擎：AOT 3 libs（无 coreclr）/ JIT `libclrjit`+`libcoreclr` / interp `libclrinterpreter`+`libcoreclr`。
- **首轮 AOT（18:10–18:51）被未持锁外部用户干扰**（8 次 managed app 启动、4 次 `updateTime` 变更、pid 连换）→ 作废并保留 `out/aot-polluted/`；
  20:38 起清洁重跑（updateTime 首=末 `1791203894126`），本结论只用清洁段。
## 2) 槽 churn（AOT，快速 create/destroy ×20）

- **20/20 通过**：`web slot create: 2`=**21** / `web slot destroy: 2`=**21**（含校准 1 对，1:1）；rejected / defer overflow / defer rejected /
  command rejected 全 0；`hybrid assets`=23；`hybrid overlay restored/replay`=5/5（重挂重放，非异常）。
- **残留检查**：末次 destroy（20:32:59）后截图 = `hybrid C: removed (slot destroy)`、Blazor 未挂、无第 3 控件矩形；`window size`=0。
- **fd/RSS 对照**：RSS 226,056→254,232 kB（+27.5 MB / +12%）、PSS +19.1 MB、native heap +2.1 MB、线程 75→73、崩 0；**fd=NA**
  （hdc uid2000 读 `/proc/<pid>/fd` 被拒）→ 以 RSS/PSS/native/线程替代。

## 3) 窗口循环（AOT，最大化/还原/自由窗 ×10）

- 手势 = 标题栏控制按钮（`rect_right-218, rect_top+29`，cal 验证 2090×1394 ↔ **3120×1955**）；**10/10 通过**，无 fault。
- 尺寸跟随：`[maui] window size change: 3120x1955 / 2090x1394 free=true` 46 行；`canvas presented (3120x1885)` / `(2090x1324)`（内容重排正确）；
  自由窗拖拽 +150,+100 往返 10/10；3 组前后截图；RSS 226,368→249,448（+23.1 MB）、native +0.9 MB、线程 76→71、崩 0。

## 4) 结论 / 异常

- **发布背书：可以** —— 清洁 120 min + churn ×20 + 窗口 ×10：**0 崩 / 0 冻结 / 0 失 pid / 0 重启**；槽计数 1:1、0 残留、0 rejection；
  窗口尺寸与内容重排正确；设备 MemAvailable 稳定 8.6–9.9 GB。**0 泄漏证据**：三条 RSS 曲线均热身+GC 锯齿（末点落带内）；churn/window 的
  +23~27 MB 为每次测试重启新进程后的热身，非累积。最小复现：无产品异常；唯一异常为环境项（外部未持锁用户 vs 首轮 AOT），已清洁重跑修正并留证据。

## 5) 证据 / 提交

- 证据：scratch `soak48/soak48-evidence.tar.gz`，3,480,805 B / sha256 `02d02b298516198ca21820fbe5d75c8bf168d522aab1bdf5c6c00c4121f137ac`（含 out/logs/bin/指纹；
  首轮污染段在 `out/aot-polluted/`）；脚本 `bin/{lock-run,soak-path,churn,windows,summarize,pack-evidence}.sh`。
- 提交：本文件 + `docs/plans/README.md` 索引（runtime-ohos `feature/openharmony`；`commit-paths.sh` 限定路径、普通推送、未强推）。

## 6) 不确定 / 边界

- fd 对照不可得（uid2000）⇒ 以 RSS/PSS/native/线程替代；frame 仅宿主 5 s 聚合（无 FPH，静态帧 0 属门控预期）。单设备 2in1 debug 域；churn/window 仅
  AOT 路径（JIT/interp 只做 40 min 浸泡）；窗口只测 free-window 控制按钮路径，未测 split 拖拽与 0×0 收窗保帧；JIT release 域仍受 ACL 限制（承 #48 交接）。
