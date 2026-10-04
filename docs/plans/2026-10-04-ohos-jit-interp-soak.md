# SOAK-JI：JIT/interp 45 min 浸泡、抢占原文复取、a11y nodeCount 核查（2026-10-04/05）

> **2026-10-05 更新**：§4 抢占原文与 §5 a11y `nodeCount=1` 两条残余已由 FIX-PREEMPT-RAW +
> FIX-A11YFLYOUT 闭环（见 `2026-10-05-ohos-a11yflyout-preempt-export.md`；nodeCount=70，三行
> 原文经 `[maui-capacity]` 直写 hilog 取到）。

> 设备 HAD-W32（OpenHarmony-7.0.0.111 / API 26 / 2in1），hdc `127.0.0.1:35111`；独占窗（`.device-lock` mkdir+owner，
> 收尾 rmdir）2026-10-05 02:50–06:06；P=`com.example.hellomauiapp`。件：JIT=`jit45/signed.hap`（runtime-mode=jit、
> 宿主 `7b1694d9`、libcoreclr `5791c298`、libclrjit `3dd94d15`）；interp=`interp45/signed.hap`（rc2b+INTERP-RENDER
> 优化件：libcoreclr `1024af70`、libclrinterpreter `6a424da7`）。方法同 SOAK2（装→`hilog -r`→45 min 采样窗；
> 5 min pid/VmRSS/线程/PSS/native heap/fault 差集/frame；15 min 抽屉+前后台扰动）；证据 scratch `soak-ji/`。
## 1) JIT 45 min（#45 主线件，03:05:14–03:50:16）
| pid/失pid/重启 | RSS 首→末（增量） | 峰/谷（t） | 线程 | 新崩/冻结 | FPH 窗 |
|---|---|---|---|---|---|
| 14414 / 0 / 0 | 320,500→342,056 kB（+21.6 MB） | 342,056(2700)/320,500(0) | 72→69 | 0/0 | 300 帧/60.1 fps |
- 扰动 3/3：BG→FG、pid 不变、0 次 `10106102`；`fault-new` 空、updateTime 首=末、power 全 AWAKE。
- 引擎（末 smaps）：libclrjit 2244 kB + libcoreclr 4816 kB；曲线 320→330→342 MB 锯齿带，无单调增长。
## 2) interp 45 min（rc2b+优化件，03:57:05–04:42:08）
| pid/失pid/重启 | RSS 首→末（增量） | 峰/谷（t） | 线程 | 新崩/冻结 | FPH 窗 |
|---|---|---|---|---|---|
| 41197 / 0 / 0 | 328,216→225,936 kB（**−102.3 MB**） | 354,876(1800)/223,416(2400) | 71→71 | 0/0 | 171 帧/34.3 fps |
- 扰动 3/3 同上；`fault-new` 空；t=1800 后一次大回收（354.9→264.2→223.4 MB，native heap 42.6→27.3 MB）后稳定
  224–226 MB；引擎：libclrinterpreter 228 kB + libcoreclr 5016 kB，`libclrjit` 0 行（解释器确在跑）。
- frame 口径同 SOAK2：FPH 5 s 行只经壳启动轮询镜像（22 行）进 hilog，仅作活跃度、非节奏测量。
## 3) 与 AOT soak2 对照（`2026-10-03-ohos-three-path-soak-2.md` §2）
| 路径 | RSS 首→末 | 峰/谷 | 线程 | 崩/冻 |
|---|---|---|---|---|
| AOT（soak2） | 247,568→253,604（+5.9 MB） | 295,500/242,840 | 70→68 | 0/0 |
| JIT（本波） | 320,500→342,056（+21.6 MB） | 342,056/320,500 | 72→69 | 0/0 |
| interp（本波） | 328,216→225,936（−102.3 MB） | 354,876/223,416 | 71→71 | 0/0 |
三路径 0 CppCrash / 0 AppFreeze / 0 失 pid / 0 重启；JIT/interp 为热身+GC 锯齿（interp 尾段大回收），非泄漏 →
发版浸泡背书沿用 SOAK2（AOT+JIT+interp）。
## 4) 抢占原文复取（preempted/restored/replay）
- 低噪声窗（停 razor/opendotnet/cdgss/wasm）重放「加 C/D/E→E 抢 A 槽→Activate A 恢复」4 轮：宿主直证
  `web slot create 2/3` + `hybrid assets slot=0`（E 抢占 A）+ `slot=1`（Activate A 恢复、B 被抢）成立。
- 原文仍未取到：该三行只写 `dotnet-status.txt`（壳 12×3 s 轮询/9 s 镜像的 60/120 行窗），CEF stderr 同灌该文件
  （镜像窗全为 CEF/`web capacity` 噪声）；`cat` 与 `hdc file recv` 均 permission denied。残余：需壳加定向导出。
## 5) a11y nodeCount（=1 vs 5/24）
- 门控前/后 + 主线 `--a11y-probe` 同法读数（owner 钉 `com.example.hellomauiapp`）：`phase-interp`（门控前）=1、
  `phase-interp-opt`（门控后）=1、`interp45`（主线）=1；AMS `accessible=0`、`client num: 0`（无 client）。
- 根因（host-side，IL 对照）：a11y 走查自 `IWindow.Content`（样例 = FlyoutPage），`PushChildren` 只认
  `ILayout`/NavigationPage/TabbedPage/Shell/IContentView，**无 FlyoutPage（IFlyoutView）分支** ⇒ 只发布根 → 1；
  kit35/门控前/门控后三件 `PushChildren` IL 分支集逐字相同 ⇒ 与 INTERP-RENDER 门控无关。
- 历史 24 = 跨应用误配：kit35-local `--a11y-probe` 的 A11Y 按钮 owner=`com.cdgss.app`（kit36/kit34 owner 均
  `hellomauiapp`，读数 1/0；wasm 5 属 wasm 页）。残余：真读屏机复核（clientless 沙箱仅读已发布计数）；产品项：
  如需 FlyoutPage 子树上屏，需补 a11y 走查分支。
## 6) 提交 / 不确定
- 提交：本文件 + `docs/plans/README.md` 索引（runtime-ohos `feature/openharmony`；`commit-paths.sh` 限定路径、普通推送，未强推）。
- 不确定：FPH/frame 仅启动镜像窗；单设备 2in1 debug 域；preempt 原文受壳镜像窗设计限制；a11y 真读屏机另场。
