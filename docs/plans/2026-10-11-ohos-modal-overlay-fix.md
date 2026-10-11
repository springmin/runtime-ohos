# MODAL-OVERLAY-FIX：模态 overlay 不出画修复（2026-10-11）

> 设备 HAD-W32 / OH 7.0.0.109 / API26 / hdc 127.0.0.1:36823（互斥锁；轮末 fixture 还原 + 锁释放 + 0 fault/0 JS crash）；#49–#53 资产未动。
> 上游 = `2026-10-11-ohos-modal-overlay-capture.md`（判定=真实渲染；候选 ①重发 ②sticky suspend ③ArkUI 叠层）。
> 主线：ow `04d1606` · maui `54631780a3`；载体 ow `fix/modal-overlay` + maui `fix/modal-overlay`（只推分支，合并/文档重刷留协调步）。

## 1) 隔离结论 = ②×①：抽屉 suspend 粘滞、模态不解除；③ 排除

- CAPTURE 的 25 MB hilog 复算 + 本轮红件（主线切片）：启动即 `web cmd: suspend` ×2（`FlyoutPageHandler.MapIsPresented(true)`），全程 **0 `resume`**；模态 push 只发 `slot`+`data`（M1）/`slot`+`media`（M2）。壳 `webSuspended=true` 时 `applyWebFrame/load/data/media` 一律 `webVisible=false`，模态页自己的 re-show 全被吞 → 屏上=managed 占位（WebView 白 / MediaElement 黑）。
- 启动即 suspend 的成因：该机 2in1 横屏 + Default 版式 → MAUI `UpdateFlyoutLayoutBehavior`（OnAppearing）把 `IsPresented` 钉 true（FIX-DISMISS 已改 Popover 但状态仍为开），抽屉启动呈现。
- ③ 排除：槽已 ensure、页面已加载（DOM/eval 活；`me opened dur=30030ms size=853x480`、`me after-play … pos=9795ms`），仅可见性被抑制；① 单独不够（suspend 期间重发 frame/show 同样落 false），必须 `resume`。

## 2) 修法（maui 切片；AOT 安全，无新公开 API，子窗路径不动）

- 新增 `OpenHarmonyOverlaySuspension`（唯一 suspend/resume 出口的状态机）：抽屉（主窗）呈现 ⇒ `hide`+`suspend`（hide 先清，免 pop 后旧可见向量被 resume 复活）；模态在顶 ⇒ `resume`；模态 pop ⇒ 重新 `hide`+`suspend`；**无抽屉的模态转换 ⇒ 零命令**（历史行为）；非主窗抽屉保留旧直发；`DisconnectHandler` 释放占用（弱引用表）。
- 改点：`OpenHarmonyMauiAppHost.OnModalStackChanged(Window)`（ModalPushed/Popped → 状态机）；`OpenHarmonyFlyoutPageHandler.MapIsPresented/OnIsPresentedChanged/DisconnectHandler`。

## 3) 离线红绿 + 套件（ow `fix/modal-overlay`，总量 791→792）

- 新 pin（drawer→arm / modal push→lift / pop→re-arm / 无抽屉静默）：红控（主线切片）`liftOnPush=False rearmOnPop=False` → UnhandledException rc=134；修复切片 4/4 True。
- 套件 **789/792 floor 772** 绿（原 788/791）；FIX-WVP/Back/FIX-DISMISS/子窗等既有 pin 全绿。

## 4) 真机（同 ow 树/同 abc 602,744/同 staged rawfile，唯一变量 = maui 切片）

| 场景 | RED `67ab9dac…` | FIX `fbd72ef3…` |
|---|---|---|
| 启动（2in1 抽屉呈现） | `suspend,suspend,hybrid,hybrid` | `hide,suspend,hybrid,hybrid` |
| M1 模态 WebView | `slot,data`；白带空白 | `resume`→`slot,data`；带内 DOM 文案（"…A REUSE WRITE"） |
| M2 模态 MediaElement | `slot,media`；媒体区纯黑（dye 0.00%） | `resume`→`slot,media`；**#123456 8.17%** + 视频帧（NTSC 6:23） |
| M2 关模态 | 0 解除 | `hide,suspend`→`hide(slot)`；回主窗与 boot 逐像素同（无残留 overlay） |
| N 抽屉 scrim 点关 | — | `resume`；Hybrid A/B 出画（2.94%） |

- 两路截图（`snapshot_display` / `uitest screenCap`）逐场景一致：dye 8.17 vs 8.19、hybridA 2.94 vs 2.83（boot/抽屉开 = 0.02/0.03，FIX-WVP 非回归保留）。
- 换回 fixture hap（主线切片）即回 `suspend×2` 无 `hide`，复核变量唯一。
- 轮内注记：scratch repack 必须 `zip -D`（无目录项）——带目录项的 repack 被设备验签拒（9568393 `verify code signature failed`），SDK 自身 hap 亦无目录项。
- abc 实测：本分支/本轮 hap 用 master `04d1606` 的 **602,744**；并行 MEDIA-MICRO 已并 master `1d7ec00`（abc **623,732**），属另一波、未混入本修与套件口径。

## 5) 载体/提交

- ow `fix/modal-overlay`（pin + 总量）、maui `fix/modal-overlay`（状态机 + 两改点）；只推分支，不并 master。
- 本文件 → runtime `feature/openharmony`（`commit-paths.sh` 限路径；直推，不 force）；README 索引行留协调步统一刷。
