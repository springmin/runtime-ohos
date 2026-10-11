# MEDIA-SUBWIN+HLS（B-M1）：子窗媒体服务 + HLS（hls.js/MSE）（2026-10-11）

> 设备 HAD-W32 / OH 7.0.0.109 / API26 / hdc 127.0.0.1:36823（锁协议，已释放）；#49–#53 资产未动。
> 载体 ow `feat/media-subwin-hls`（`983d103`；合流 `04d1606`）+ maui 同名（`04106f8906`）；均从主线（ow `624e6e4`/maui `fbd91e17bc`；maui 轻合并 `feature/openharmony` `54631780a3`、ow 轻合并 `master` `04d1606`）、普通推送、禁强推。
> 套件 **788/791 floor 771 assert=True**（+12 B-M1 pin；红控 = slice 的子窗降级串/`IsApplicable(_windowId)` 必须消失、四包 `identical`、gesture 必须是 opt-out 形式）。
> 证据 scratch `subwinhls/{device,evidence,evidence3,evidence4}/`；填平 A-M1 两项边界：子窗无媒体服务 → Failed、HLS 须 MSE+hls.js。

## 1) ① 子窗媒体服务（复用 child web/会话表，最小可行）

- 壳 `SubWindow.ets`（四包）：子槽接 `media` 命令（`SubMediaAssetsConfig {kind,location,id,slot}`，走既有 child 命令通道）→ 该子槽加载 `https://media.local/?s=<slot>` 并同源服务：
  `media.html`、`hls.min.js`、`/__src__`（kind1 rawfile / kind2 沙箱 file，≤64MB，带扩展名 MIME，与主窗同规）；`__ohMediaId/__ohMediaSlot` 注入 + 子 `originEnvelope` 增媒体 docId 分支
  → `host.notifyJsMessage` → slice `OnJsMessage` 按 docId 解析 surface（无需新 sink）；子 Web 组件 `.mediaPlayGestureAccess(false)`；`resetChildWebSlotState` 清媒体表（槽销毁即回收）。
- slice：`OpenHarmonyMediaElementSurface` 删去子窗降级（`IsApplicable(_windowId)` 拒 → 走 `AcquireForWindow`）；`EnsureSlot` 先 `RefreshWindow`（按元素窗口认领子池），窗口迁移置 `_detached` 由 Arrange/AttachOverlay 重认领；
  `OpenHarmonyWebViewHandler.ReleaseWindowOverlays` 增 `OpenHarmonyMediaElementSurface.ReleaseWindowOverlays(windowId)`（关窗 → 释放子槽 + `slot destroy`）。
- 边界：L8-POPUP 弹窗（无托管树/面）不在本波；子池容量 2 与 hybrid/blazor 共享，满 → `Failed`（不抛）；每元素 1 子槽。

## 2) ② HLS（内置 hls.js，同源 rawfile）

- `hls.min.js`（**hls.js 1.7.3**，npm tarball vendored，Apache-2.0 → 同目录 `hls.LICENSE.txt`）入四包 `templates/resources/rawfile/`（Hap.targets 通配 staging）；主窗/子窗在媒体 origin 增 `/hls.min.js` 服务。
- `media.html`：源路径 `.m3u8` → 懒加载同源 `hls.min.js` → `Hls.isSupported()` → MSE（`enableWorker:false`）`attachMedia/loadSource`；`play()` 在 `MANIFEST_PARSED` 前暂存、解析后触发；
  致命错误限 2 次 recover（network/media）→ `error` 事件；hls.js/MSE 不可用 → 回退原生 `video.src`（`fallback-native` 诊断事件）；`__ohMedia.hlsState()` 供诊断；slice 把 `hls` 诊断行写状态文件。
- 边界：HLS 走 kind0 URL（rawfile/file 的 m3u8 需 playlist 改写/Range，本波不做）；`.m3u8` 检测只看 URL 路径。

## 3) 真机证据（锁内一轮，one build；hap `74d311cf…`/`92d97306…`）

- ① 主窗回归（A-M1 用例，rawfile H.264/AAC 1s）：`slot=2 supported=True` → `opened dur=1000ms size=360x240` → `after-play ended=True state=Completed pos=1000ms seen=787ms` → `close released=True mainWindowAlive=True`。
- ② HLS（本地构造 CMAF 样本：`long-test.mp4` → MP4Box.js 切段 init+fMP4×8 → bun loopback `http://127.0.0.1:8791/hls/master.m3u8`）：壳 `media serve /hls.min.js` →
  服务端逐段 `GET /hls/master.m3u8`、`video.m3u8`、`init-all.mp4`、`v-0..7.m4s` → `opened dur=30032ms size=853x480` → `after-play ended=True state=Completed pos=30030ms seen=30030ms` → `close released=True`（整链播完；样本为 MP4Box.js 构造的 video-only CMAF）。
- ③ 子窗（`app://subwindow/openmedia`，子窗 hap 多轮迭代）：`cm slot=0 supported=True win=sub-1` → 壳 `child media serve (slot 0): /`、`/__src__` → `opened dur=1000ms size=360x240` →
  `after-play ended=True state=Completed pos=1000ms seen=789ms states=Prepared/Playing/Playing/Paused/Completed/` → `stop=Success claimed=True` → `child web cmd: slot destroy 0` → `close released=True mainAlive=True win=sub-1 slot=0`；平台 `OhosVideoDecoder` h264 360x240 Init/Decode + `OHAudioRenderer`(session)。
- 主窗零回归：pid 恒稳、fault 目录 0→0、主窗 title/framestats 正常；轮末恢复 fixture 件、hilog 还原、锁释放。

## 4) 余项 / 边界

- 子窗 HLS 未单独取景（与主窗同一 `media.html` 代码路径；子窗用例为 rawfile H.264/AAC）；弹窗无媒体；rawfile/file 的 m3u8 无 Range/改写（>64MB 拒与 A-M1 同）。
- modal/子窗 overlay 像素截图问题沿用 A-M1 余项（功能链不受影响）；探针的子窗标题通道在播放后不再送达（after-play/stop 走主窗标题，见 `MediaElementProbe.cs` 注释）。
- 载体与 pin：ow 主线 `04d1606`（三 maui gate pin `54631780a3`）、maui `feature/openharmony` `54631780a3`；CI：interaction/pixel/host-export/ridgraph/markdownlint 5/5 绿 + harmony-flavor dispatch 绿（run 38116936529）。
