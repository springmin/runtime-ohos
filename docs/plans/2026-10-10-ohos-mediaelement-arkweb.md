# MEDIAELEMENT-ARKWEB A-M1：MediaElement → overlay 槽 ArkWeb `<video>`（2026-10-10）

> 设备 HAD-W32 / OH 7.0.0.109 / API26 / hdc 127.0.0.1:36823（锁协议，已释放）；#49–#53 资产未动。
> 载体 ow `feat/mediaelement-arkweb`（`b674f80`）+ maui 同名（`0adfe6c7fe`）；均从主线（ow `55044da`/maui `625177750f`）、普通推送、未并、禁强推。
> 套件 **776/779 floor 759 assert=True**（+8 A-M1 pin；红控 = 四包 gesture 翻 true → `gestureOptOut=False` 被抓）。证据 scratch `mediaelement/{device,evidence}/`。

## 1) 实现（壳 + maui）

- **壳**（四包 `Index.ets`+`media.html`+`Hap.targets`；abc ui **589,700/`37c3afdc…`**，headless **24,324** 不变）：
  - `media` web 命令 `{slot,id,kind,location}`：注册即 `loadUrl(https://media.local/?s=<slot>)`，槽/可见性/z-order/清理全复用既有 overlay 槽机制（`resetWebSlotState` 清媒体表、release 走 destroy/LRU）。
  - `onInterceptRequest` 服务 `/`（HAP rawfile `media.html`；Hap.targets 把 pack 模板 `resources/rawfile/**` staging 进每个 HAP）与 `/__src__`（kind1 rawfile→resourceManager、kind2 沙箱 file→@kit.CoreFileKit，带扩展名 MIME，≤64MB）；kind0 URL 由页面直接加载。
  - 事件：`dotnetHost.postMessage("__OHMEDIA|s<slot>|<kind>|<json>")` 走既有 `__OHORIGIN` 信封（`originEnvelope` 补媒体 docId 分支；`injectPageBridge` 注入 `__ohMediaSlot/__ohMediaId`）。手势：Web 组件 `.mediaPlayGestureAccess(false)`（绕 Q1 的无手势出声门，muted 行为不变）。
  - `media.html`：`<video>` + `window.__ohMedia`（load/play/pause/stop/seek/setVolume/setMuted/setAspect/snapshot/size/state）；事件 ready/opened/duration/size/position/playing/paused/stopped/seeked/ended/error/playfailed。
- **maui**：`OpenHarmonyMediaElementSurface`（每元素 1 槽；source 归一 URL/file/rawfile；`MediaOpened/Ended/Failed/PositionChanged/StateChanged/SizeChanged/DurationChanged`；无槽/页未就绪/无桥 → Unavailable/Failed，不抛）＋ `OpenHarmonyMediaElementHandler`（`IOpenHarmonyMediaElementView`；SliceHandlers 注册、source-gen JSON context、AOT 安全）。

## 2) 映射表

| MediaElement 面 | 实现 |
|---|---|
| Source：URL / 文件 / rawfile | 页 `src` / 壳 `/__src__`；`file:///x`→沙箱路径、绝对路径→file、其余→rawfile；`../`、`\`、非常规 URL 形状 fail-closed |
| Play / Pause / Stop / Seek | eval `window.__ohMedia.*`；页 ack `{ok,message}` → `Success`/`Failed`（不可达 → `Unavailable`） |
| Volume / Muted | eval setVolume(0..1)/setMuted(布尔) |
| Aspect | `object-fit` contain/cover |
| State / Position / Duration / Size | opened/position/duration/size/ended/error → Prepared/Playing/Paused/Stopped/Completed/Error + 镜像 |
| 槽生命周期 | Acquire/Release + LRU 复用；AUTODISCONNECT/弹层关闭 → hide+release |

## 3) 真机证据（锁内一轮，device hap `53360820…`/`32f512d4…`/`65608d61…`/`aaf661bd…` 多轮迭代）

- 短样 H.264/AAC 360x240 1.0s（rawfile）：`slot=2 supported=True` → `play=Success` → `opened dur=1000ms size=360x240` → `after-play ended=True state=Completed pos=1000ms seen=794ms`（states `Prepared/Playing/Playing/Paused/Completed/`）；长样 854x480 30s 活跃播至 `pos=9790ms`（`ended=False`）。
- 平台解码：`MediaCodecDecoderBridgeImpl::CreateVideoDecoder` + `[h.vdec]{Configure 360x240}→{Start} success→OnOutputFormatChanged NV12`（32 行）+ `[in]/[out]` buffer；音频 `audio_server OHAudio/Hpae` 会话（无手势，opt-out 生效）。
- 交互：`transport seek/resume/pause=Success`、`pauseState=Paused`、位置停住（226ms→226ms）、`resumeAgain=Success state=Playing`；`audio mute/volume/unmute=Success`；`stop slot=2 claimed=True` → modal 关闭 `close released=True mainWindowAlive=True`（槽释放）。
- 主窗零回归：pid 恒稳、fault 目录 0→0、主窗 title/framestats 正常；轮末恢复 fixture 件、hilog 还原、锁释放。
- 画面：解码/输出（NV12/EOS）与浏览器侧同片彩条截图（Q1）成立；本轮 **modal 页截图中 overlay 未出画**（media 区显示平台 view 黑框；同弹层下主窗 hybrid overlay 也不出现于截图）→ overlay 像素为余项，功能链（load/play/seek/事件/槽）不受影响。

## 4) 余项 / 边界

- HLS 不支持（需 MSE+hls.js；**B-M1 已补：内置 hls.js 1.7.3 走 MSE，见 `2026-10-10-ohos-media-subwin-hls.md`**）；DRM/EME 无声明（视为不支持）；MPEG-4 Part2 不支持（Q1 边界）。
- 子窗无媒体服务（child 池 → 无槽 → Failed 语义；**B-M1 已补：子窗媒体服务，见 `2026-10-10-ohos-media-subwin-hls.md`**）；file/rawfile 一次整流无 Range（>64MB 拒）；每元素 1 CEF+1 槽（默认池 8）。
- modal 下 overlay 像素（含 hybrid）未在截图出现——合成/捕获层问题，待独立复现；CommunityToolkit 适配器归属未定（本仓给 surface/handler + slice 接口）。
- abc 变化已实测并锚入 `verify-kit.sh EXPECT_ABC=589700,24324`；#54 预刷 tester docs（576,664）待 cut-kit bump 随动。
