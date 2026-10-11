# MODAL-OVERLAY-CAPTURE：模态下 overlay 像素“未出画”独立复现（2026-10-11）

> 设备 HAD-W32 / OH 7.0.0.109 / API26 / hdc 127.0.0.1:36823（锁协议；本 session 14:52 取锁，15:34 被同机 UI-TEST-INJECT 会话接管，见 §4）；#49–#53 资产未动。
> 件 = A-M1 dev hap `f2371724…`（同一 hap 含 `app://web/windowopen`（模态 WebView）与 `app://media/element/long`（模态 MediaElement）双路）。

## 1) 复现矩阵（同刻两路：`snapshot_display` vs `uitest screenCap`）

| 场景 | 内容 | snapshot_display | uitest screenCap | 两路像素 |
|---|---|---|---|---|
| N 主窗 hybrid（非模态） | hybrid 页文案/按钮 | 有 | 有 | 一致 |
| S windowopenseq（非模态） | hybrid HUD 文案更新 | 有 | 有 | 一致 |
| M1 模态 WebView（windowopen doc） | DOM 文案（hilog 读到 `L8 MAIN`/HUD） | **无（整片 255）** | 无 | 一致 |
| M2 模态 MediaElement（long 播至 9.8 s） | 视频帧 | **无（整片 0,0,0）** | 无 | 一致 |

- 14 对同刻 diff ≤ ~450 px（噪声级；m1b 单对 8.9k 时钟/压缩噪声）；`-t 0`=默认，`-m` rc=255 不支持，`-t 1/2` 抓到时模态已收（场景变化，不构成第二路径）。

## 2) 判定：**② 真实渲染问题（overlay 未上屏）**，非截图/捕获层缺失

- hap 内 `media.html` 背景实测 `#123456`，而 M2 实像素为纯 `0,0,0`；M1 为纯 `255,255,255`：恰为宿主平台占位色（`MediaElement.Background=Black` / `WebView.Background=White`，两者 `GetDesiredSize` 取 `min(400,…)`≈实测 398 px）→ 屏上是**管理侧占位 view**，overlay 页像素（含背景）未合成。
- ArkWeb 遥测：模态页 webId 无 `OnVisibleAreaChange/OnFirstScreenPaint`（popup 窗口与非模态 overlay 均有）→ 模态 overlay 未呈可见/未上屏；Blink 内部 FCP 不构成窗口像素。
- 功能链正常（DOM/JS/视频解码/槽/事件均活），但视觉缺画是真实缺陷（非“仅截图”）。

## 3) 规避 / 最小修方向（修需一轮插桩+构建验证，本 session 未开修分支）

- 截图途径无规避（两路等价且忠实）。
- 方向①（宿主最小改动）：`ModalPushed/Popped` 后对所有在用 overlay 重发 frame/show（对齐抽屉 resume 路径；改点 `OpenHarmonyMauiAppHost.OnModalStackChanged`）。
- 方向②：查 sticky `webSuspended`——每轮启动 `web cmd: suspend` ×2 而全程无 `resume`；若悬挂，模态槽的 `frame/load/data` re-show 全被抑制（核 Flyout `MapIsPresented`/`OnIsPresentedChanged` 的 resume 配对）。
- 方向③：若属 ArkUI 叠层（XComponent(SURFACE) 压过 Web），模态转换后重挂/重排 overlay 层。

## 4) 边界 / 未决

- 未做 red-overlay 重打包验证与 fixture 还原：15:34 锁被同机 UI-TEST-INJECT（sibling）接管，其 uiInput 与本轮收尾 swipe 相交，为免打断未再触设备；16M hilog 未还原 512K（待其轮常规收尾）。
- 捕获层假设不成立：两路一致且非视频文本同样缺失，“仅截图少层”解释不通；未决 = 可见性协议 vs ArkUI/RS 合成两候选未隔离（需 shell 插桩）；并发会话潜在污染仅限收尾段（M1/M2 关键证据标题/状态逐帧吻合）。
