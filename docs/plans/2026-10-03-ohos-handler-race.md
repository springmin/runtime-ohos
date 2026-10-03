# FIX-SLICERACE：MAUI 切片 handler 并发设置竞争（2026-10-03）

> 范围：maui-ohos `OpenHarmonyHandlerConnector.cs` + `OpenHarmonyMauiAppHost.cs`（handler 设置/启动序），
> ohos-workload 套件 `test/maui-platform-verify/Program.cs`；pin 未动。设备 HAD-W32 / hdc
> 127.0.0.1:35111，JIT 件（kit#41 JIT 载荷以修复切片重编 + WX-HOST-PRCTL 宿主 `08abe185`）；
> 证据 scratch `/data/storage/el2/base/tmp/opencode/fix-slicerace/`。
## 1. 根因
- 运行时跑在宿主 launch 线程，ArkTS shell 在自身线程反向回调 surface/frame/lifecycle；`Run` 的
  `ConnectTree`（app 线程）与 `SurfaceChanged/Frame → Arrange → ConnectTree`（shell 线程）并发。
  `Element.SetHandler` 的 check-then-set 非重入 → “Handler is already being set elsewhere”，并伴随
  `PlatformView cannot be null here` 与「non-concurrent collection … concurrent update」；JIT 慢启动
  放大窗口，AOT 快故不显。
- pre-fix 设备 `wx-prctl/logs/host2-jit-inv/hilog.txt`：7 次启动 5 pid 命中 handler 竞争、5 pid
  PlatformView-null、1 pid 集合腐坏（互有重叠）。headless 还原（4 线程 × 300 轮）：152 失败
  （89 handler / 53 PlatformView / 4 collection）。
## 2. 修复
- 连接器：可重入 `s_connectSync` 串行化 `Connect/ConnectTree` 的 check-then-set（核心下移
  `ConnectCore/ConnectTreeCore`）；并发第二次调用见已连接即幂等返回。
- 宿主：`_sync` 串行化全部触树入口（Run/TryAdoptWindow/Arrange/Render/触摸/字号/lifecycle/回调）；
  `_ready` 门闩让 surface/frame 在 Run 连接完成前不触树（消除半连接树的 PlatformView-null/集合腐坏）。
- 纯串行化/幂等，无语义改变；套件 +3 断言（connect storm / host storm / 源码 pin）。
## 3. 设备证据（修复后 JIT）
- 8 轮（4×inv → 2×plain → 重装后 2×inv，每轮 force-stop/重启）：8/8 PASS；每轮
  `race=0 pvnull=0 conc=0 unhandled=0 jitfort=1`，首帧 `canvas presented` 767–814 次，pid 36 s 存活，
  截图 `logs/device/*-frame.jpeg`（3120×2080）；对照：同 config 轮修复前全实例命中 crash。
## 4. 套件 / 门禁 / 提交
- 交互套件 `checks=578 total=580 floor=560 assert=True`（基线 575/577，只增）；pre-fix stash 回归
  `slicerace connect storm … errors=165 … assert=False`（同一句错误）。
- 切片 compile vehicle（IsAotCompatible + trim/AOT analyzer，warnaserror IL2026,IL3050）：0 error / 0 IL。
- 提交：maui-ohos `549967f2f0`、ohos-workload `f6cbbe8`、本篇 runtime-ohos；`commit-paths.sh`，
  未推送/未强推。
## 5. 不确定
- 锁让 shell 回调在启动期阻塞（帧丢弃）属预期；shell 端同步等待 app 桥调用的边界未测。
- 未覆盖长时后台唤醒、release 签名域与 AOT 重跑（同一托管路径；本波只做 JIT 轮）。
