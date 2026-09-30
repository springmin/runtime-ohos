# W9D: MediaElement/媒体面实施（E9/T20）与 T19 深链真机判定（2026-09-30）

> 切片 `springmin/maui-ohos` 分支 **w9d-t20** `64e2dc4d92`（基于 `ebffdd787c`，与 W9A/W9C 同基；集成态
> `w9d-test = 5b51e1d448 + 640de39638 + 3fda5bdbe6`）；壳/host/harness `ohos-workload` **`66d1c40`**。
> 套件 **535/515**（+4 T20；基线 531/511，floor 511→515）· host 导出 **149/149** · 本机 AOT 真机复测
> （HAD-W32 / 7.0.0.111 / hdc `127.0.0.1:35111`）。证据 scratch `/data/storage/el2/base/tmp/opencode/w9d/`。

## 1. T20 媒体面（最小可用桥）

- **切片** `OpenHarmonyMediaPlayer.cs`（+ PublicAPI/切片 notes）：ops 0 load（url / rawfile `getRawFd` /
  沙箱 `fs.open`）/1 play/2 pause/3 stop/4 seek/5 release/6 status；`state|time|duration|error` 事件；
  `IsSupported` 降级语义；请求串行化。参照契约 = 社区工具包 MediaElement 的播放传输层（MAUI 无媒体
  抽象；控制/处理器留给工具包侧）。
- **壳**（四包字节一致，abc 重建 + provenance）：`registerMediaSink`（懒加载 `@kit.MediaKit`、单 AVPlayer、
  fd 生命周期、状态推送 + hilog）；设备自检行与托管状态镜像（files 0600 → 壳读 tail 打 hilog）。
- **host**：`ohos_host_media_request/_register_result/_register_event` + NAPI `registerMediaSink/
  notifyMediaResult/notifyMediaEvent`；`host-exports.txt`（149/149，`--cross-check` 绿）。
- **harness +4**：`t20 media pins / degrade / events / status`；README 更新。
- **真机**（AOT 路径、本机重签安装）：
  - 壳侧成立：`[maui] media sink registered`；自检 `media self-test status code=0 payload='idle\t0\t0'`。
  - **设备能力判定（E9 关键）**：`media self-test media-kit=missing media-core-capability=true` —— 本机桌面
    镜像 `canIUse('SystemCapability.Multimedia.Media.Core')` 为真，但运行时解析 `@kit.MediaKit` 后
    **无 media 命名空间/createAVPlayer** → 该镜像**无法播放**；sink 已按其降级为 -1（`IsSupported=false`）。
  - 托管桥面（load/play 状态/hilog 证据）在**本机 AOT 包上不可达**：见 §3 的 `delivered=0`；JIT 真机与
    工具包接入后按 `app://media/probe` 热激活触发（`MediaProbe`，本地正弦 WAV，缓存目录，无需码流）。

## 2. T19 深链真机判定（本机）

- 壳日志（新增，证据 `dev-final1.log`/`dev-final2.log`）：`activation cold seq=1 uri=app://media/probe…
  delivered=0`；热 `activation hot seq=2 uri=app://probe/unknown?x=1 delivered=0`。
- 判定：**want `-U`/`--ps` 冷/热投递到 ability 均成立**（冷 = `onCreate` 捕获→`bootstrap` 先于 startApp
  移交；热 = 存活实例 `onNewWant`；seq 单调、去重语义由托管侧持有）。**未知路由**在 ability/壳层无异常，
  托管侧路由决策（app:// 只接受、`..` 拒绝、https 白名单）由既有 p2c/SEC3 套件钉住。
- **`delivered=0`（host 未见托管激活监听器）**：本机 AOT 运行下托管侧未注册激活回调（同轮状态镜像
  `meaningful=0`、无托管桥调用）。这是**平台 AOT 启动/桥注册的既有缺口**（另线 `139f745d45 app host
  桥上下文刷新（AOT 启动时序）` 可能已修）——与 tester JIT 机差异：tester 走 JIT 主包（本机因
  payload-in-libs 码签拒装 9568393 不可装），激活/媒体真判定仍应在 tester 机复核。

## 3. 纪律与边界

- 切片 `OpenHarmonyMediaPlayer.cs` 0 error/0 IL（独立编译车 + IL2026/IL3050 warnaserror 绿）；套件
  535/515；`host-exports` 149/149；**未改 slice pin**（三 workflow 维持 `ebffdd787c`；集成态以 coordinator
  合并为准）。
- 遗留：本机镜像 Media Kit 缺失（E9 外部判定点回写：真机播放需 Kit 完整镜像/HMS 设备）；AOT 托管桥
  `delivered=0` 平台 follow-up；`window.Title` 心跳在 slice 生命周期未接（OnStart 未映射，记录）；壳内
  自检/状态镜像是诊断件（每次启动 1 行 hilog，不做播放）。
- 临时实验：`hilog -G 16M` 已恢复 512K；调试用 `mediaKitShape`/playback 自检已回退为 status-only。
