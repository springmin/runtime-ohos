# MEDIAELEMENT-ARKWEB-PRESTUDY：绕 C1 无 MediaKit 的回退路线预研（2026-10-10，只读）

> 只读预研（SDK d.ts + 三仓代码走查），未构建/未上机；本 session 不处理上游 PR。
> C1 = 镜像无 MediaKit（`2026-10-05-ohos-platform-limitations.md`）：T20 桥 `OpenHarmonyMediaPlayer.cs` 已实现、`IsSupported=false`、`[media-probe] load status=Unavailable`。
> 证据源：`ohos-sdk 26.0.0.18_2` `ets/component/web.d.ts`（记 W）+ `ets/api/@ohos.web.webview.d.ts`（记 V）；壳 `Index.ets`/`SubWindow.ets`（preview.28）· `OpenHarmonyOverlays.cs`（默认 8/HOT 2，见 `2026-10-10-ohos-batch3-consolidate.md`）· `OpenHarmonyChildWeb.cs`（子窗 2 槽）· maui `OpenHarmonyWebViewHandler.cs`（槽/`frame`/eval/`dotnetHost` 桥先例）。

## 1. 能力矩阵（能答→证据；不能答→需探针）

| # | 问题 | 证据 | 判定 |
|---|---|---|---|
| Q1 | 本镜像 ArkWeb 能否播 HTML5 video/audio | 媒体控制面全套在：`mediaPlayGestureAccess`（W，since 9）· `pauseAllMedia/resumeAllMedia/stopAllMedia/getMediaPlaybackState/setAudioMuted`（V，10–12）· `onAudioStateChanged`（W，12） | 引擎面在；**出画/出声=探针**（核心未知：ArkWeb 媒体管线是否同样依赖缺失的媒体服务） |
| Q2 | 编解码（H.264/AAC/VP8/VP9/Opus/HLS/MSE） | takeover 语境有 `SourceType=URL\|MSE`、`format "mp4, webm, m3u8"`（V）；无编解码清单 | **探针**：`canPlayType`+`MediaSource.isTypeSupported` |
| Q3 | autoplay/手势 | `mediaPlayGestureAccess` 默认 **true**：音视频需手动触发，muted 不受控（W） | 可置 false；真机默认/置 false 效果=**探针** |
| Q4 | 音频焦点/会话 | `WebMediaOptions{resumeInterval≤60s, audioExclusive 默认 true, audioSessionType(API20)}`（W）+ `onAudioStateChanged`+`setAudioMuted` | API 在；中断/恢复/互斥真机语义=**探针**；无 AVSession 细粒度面 |
| Q5 | 全屏 | `onFullScreenEnter(handler, videoW/H)`/`onFullScreenExit`（W）· `closeAllMediaPresentations`（V） | API 在；落点（overlay 槽内 vs 窗口级）/2in1/旋转=**探针** |
| Q6 | DRM/EME | W/V 两文件无 Widevine/MediaKeys/EME 任何声明 | 视为不支持（业务需要再探） |
| Q7 | 后台播放 | 无后台音频 API；`resumeInterval` 仅跨应用恢复；壳有 Home/600 ms suspend 与 `webSuspended` 先例 | **探针**（Home/切后台的停/续窗口） |
| Q8 | 多实例/抢占 | `audioExclusive` 默认 true；主槽默认 8/HOT 2、owner-LRU 抢占；子窗 2 槽 | 播中被抢占/`visibility(None)` 的音频行为=**探针** |
| Q9 | 能耗/性能 | CEF 首实例 ≈240 ms（AOT-STARTUP）；E4 8 槽已修（`2026-10-08-ohos-overlay-capacity8.md`） | 播放 fps/CPU/RSS=**探针** |

## 2. 路线对比

**A) MediaElement → 壳内嵌 ArkWeb `<video>`（候选）**
- 实现面：maui 新 `OpenHarmonyMediaElement`（`IOpenHarmonyOverlaySlotOwner` 领槽；复用 `PlatformArrange`→`frame`、`load/show/hide/eval`、`dotnetHost`/`__OHORIGIN` 事件桥；URL 直载、rawfile/沙箱经 `onInterceptRequest` 同源服务）+ rawfile 媒体页（`<video>`+事件回传 ~100–200 行）；壳零改或仅加媒体页服务/按槽 `mediaPlayGestureAccess`。
- 语义映射：source→`src`；play/pause/stop→`play()/pause()/load()`；seek→`currentTime`；position/duration→`timeupdate/durationchange`；ended→`ended`；volume/mute→`volume/muted`+`setAudioMuted`；State→Opening/Playing/Paused/Stopped/Failed。
- risks：编解码/DRM（Q2/Q6）· 手势（Q3）· 焦点/后台（Q4/Q7）· z-order（overlay 恒在 MAUI 画布上方、控件不可叠；播中被 LRU 抢占=Q8）· 每控件 1 CEF 实例（能耗/内存）。

**B) offscreen ArkWeb + 音频走后端**：不可行——无后端可走（MediaKit 缺、无独立音频通道）；离屏引擎仍付 CEF 成本且可见性/抢占语义更差。若只需音频：折叠进 A 的页内隐藏 `<audio>`，不单立路线。

**C) 其他**：① `enableNativeMediaPlayer`+`NativeMediaPlayerBridge` takeover——SDK 原生链接面有 `multimedia/player_framework/avplayer.h`+`libavplayer.so`，但设备媒体服务是否存在未知（与 Q1 同因），且全量回调+自渲染 ≥N 人日；② 系统播放器 want——离开应用、无 MediaElement 语义、镜像播放器未知；③ 换有 MediaKit 镜像/设备=外部依赖。均不推荐（Q1 红时可单点试 C①）。

**D) 维持 C1**：零成本；设备有 MediaKit/HMS 时以 T20 桥为准；本镜像 E9 维持未验。

## 3. 成本/依赖（粗估）
| 项 | 文件级 | 人日 | 容量影响 |
|---|---|---|---|
| 探针（前置门） | scratch 壳页+脚本 | 0.5–1 | 0 |
| A-M1（播/暂/停/seek/音量/事件） | maui 2–3 新改（~500–800 行）+ rawfile 页 | 3–5 | 1 槽/控件（默认 8）；子窗占 1/2 |
| A-M2（全屏/焦点/控件/几何） | maui 1–2 文件 | 2–4 | 同 M1 |
| C①（原生 takeover） | maui+host+壳 | ≥10 | 同 M1（或自渲） |
- 依赖/决策：CommunityToolkit.MediaElement 的 OHOS handler 不在本仓（适配器归属：app 侧最小适配器 vs toolkit 分叉）；壳是否新增媒体页服务；`mediaPlayGestureAccess` 全局 vs 按槽。
- 测试：离线 pin（传输/状态/事件解析 + 壳源码检查）+ 真机探针（§5）；不重复运行既有 737/740 套件语义。

## 4. 推荐
**值得做，但探针先行**：Q1 是单点生死门。绿 → A-M1 是唯一可行的应用内回退且复用 ~80% 既有桥；红 → 关闭为文档化负结论（D），可选 C① 复探。B 不可行、C①–③ 不先行。

## 5. 探针设计（真机；可先 scratch 离线）
1. 器物：1 个 overlay 槽 + 探针页（rawfile 或 `https://0.0.0.1/` 同源服务）；`eval` 下发、`dotnetHost.postMessage`/`__hwv*` 读回、hilog 标记。
2. Q1/Q2：`canPlayType` 矩阵 + `MediaSource.isTypeSupported`；实播 rawfile mp4（静音）与带音轨 mp4，记录 `loadedmetadata/duration/playing/timeupdate/ended/error`。
3. Q3：程序化 `play()`（无手势）× 默认 / `mediaPlayGestureAccess(false)` 两态。
4. Q4/Q7/Q8：双 overlay 同播（`audioExclusive`）；Home 600 ms/回前台续播；播中 `hide`（None）/被 LRU 抢占/子窗。
5. Q5：全屏 enter/exit 落点与手柄；Q9：播 60 s 的 fps/CPU/RSS/线程。
6. 判定卡：Q1 绿=出画出声；Q3 拒绝可用属性绕开；Q7 至少停/续可预期；否则转 D。

## 6. 未知/风险（对外可引用）
- 核心未知：Q1（媒体管线 vs 媒体服务依赖）· Q2 编解码 · Q7 后台；语义偏差：Q3/Q5/Q6/Q8。
- 维护成本：每媒体控件 1 CEF 实例 + 1 槽（与 Web/Hybrid/Blazor 争 8 槽池）；toolkit 适配器归属未定。
- 范围：2in1 debug 域推演（E1），手机/release 不外推；预研不含实现与上游 PR。
