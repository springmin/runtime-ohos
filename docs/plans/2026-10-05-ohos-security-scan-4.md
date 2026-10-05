# runtime-ohos 新面具安全复查 #4（SEC-SCAN-4，2026-10-05）

**范围：** scan-3（2026-09-28）之后新增/改动的 7 个面：①INTERP-DRAW2 面外剔除（maui `6652017ca5`）②MULTIWINDOW-S（maui `ed02203bfd` + ow `c5df1de`）③FPS48（ow `67a1de8`）④AOT-STARTUP 首用挂载 + 相同快照重放跳过（ow `22ca602`/`372c35e`/`92ea222`）⑤SMALL-FIXES 动态槽 N=8 残留（ow `88e5aec`/`189b87c` + `2026-10-05-ohos-mime-max-device.md` 设备轮）⑥CG2-R2R rc.2 crossgen2 nupkg（sdk release `crossgen2-packs-11.0.0-rc.2` + ow `b6c9793`）⑦FIX-A11YFLYOUT a11y 走查（maui `d5384d6cc3`）。
**约束：** WebView/ArkWeb 区（maui WebView handler、`packs/**/templates/Index.ets`、`arkts-host`）只审不改，patch 草图见 §报告未修；其余面最小修复已落地。**性质：** 读码 + 离线红/绿复现；本轮未上机，设备可见结论一律「设备未验证」。

## Verdict

**PASS WITH FINDINGS（1 中已修 + 6 低/信息报告；2 面无缺陷并补断言）。** a11y 走查发现密码 `Entry` 明文进影子树（中，已修 + 负控）；动态槽 churn 陈旧回调、建而不挂残留、crossgen2 消费链无强制摘要校验（低，WebView/供应链，报告 + 草图）；a11y 走查无节点上限、a11y client 跨应用遍历为低/信息；INTERP-DRAW2 剔除边界（错误坐标/负尺寸/NaN/特大 shadow/移位/图片/覆盖层）、AOT-STARTUP 重放跳过、MULTIWINDOW-S 门控逐项未发现可利用缺陷（剔除边界已补断言）。

| 指标 | 数值 |
|---|---|
| 复查面 | 7 |
| 候选 | 7（中 1 · 低 4 · 信息 2） |
| 已修 | 1（SEC4-A11Y1 = maui 切片 + 套件断言） |
| 报告未修 | 6（WebView 区 2 · 供应链 1 · 加固 3） |
| 无缺陷面 | 3（INTERP-DRAW2 / AOT-STARTUP / MULTIWINDOW-S） |
| 设备验证 | 无（离线；设备未验证） |

## 汇总表

| 编号 | 面 | 严重度 | 标题 | 可利用性 | 状态 |
|---|---|---|---|---|---|
| SEC4-A11Y1 | a11y walk | 中 | 密码 `Entry` 明文进 a11y 影子树 | 启用读屏/无障碍服务即可读；违反绘制已脱敏契约 | 已修（maui） |
| SEC4-SLOT1 | SMALL-FIXES | 低 | churn 陈旧 `onControllerAttached` 把重建槽标记已挂 | 销毁→重建窗口内旧回调先到 → 命令打到未挂控制器（17100001，降级） | 报告（Index.ets 草图） |
| SEC4-SLOT2 | SMALL-FIXES | 低 | 建而不挂动态槽无超时/回收（N=8 残留） | 资源（ArkWeb/控制器）留到 destroy 或进程止；产品 MAX=4 时潜伏 | 报告（维持 4） |
| SEC4-CG2 | CG2-R2R | 低 | crossgen2 nupkg folder feed 消费无强制摘要校验 | 本地 feed/nupkg 被换 → 发布期 crossgen2 执行 + R2R 产物被改 | 报告（sha/lock 建议） |
| SEC4-A11Y2 | a11y walk | 低 | 服务端走查/宿主表无节点上限 | 仅应用自控树可放大（自伤 DoS），非跨信任面 | 报告（加固） |
| SEC4-A11Y3 | a11y client | 信息 | 测试客户端遍历所有窗口而非仅目标 bundle | 测试件（不随 kit）；dump/hilog 含他应用文本 | 报告（测试件） |
| SEC4-FPS | FPS48 | 信息 | 帧率投票常驻（`{60,60,60}`），无 idle 撤销 | 常量入参无校验缺口；功耗项非安全 | 报告（后续项） |

## 已修（非 WebView 区）

- **SEC4-A11Y1（中）。** `OpenHarmonyAccessibility.BuildNode` 对 `IText.Text` 直取发布，而绘制走 `OpenHarmonyView.DisplayText`（`IsPassword` → `•••`）——密码字段的明文随每帧影子树交给 ArkUI 无障碍 provider（`AccessibilityBegin/Node/Commit`），启用读屏或本仓 a11y client 可原样读出。修复：文本计算后按 `view is IEntry { IsPassword: true }` 或平台 `OpenHarmonyView.IsPassword` 判定，走同一 `MaskPassword`（`OpenHarmonyView.cs:284` 放开为 `internal`；`OpenHarmonyAccessibility.cs:664-676`），密码节点只发布等长圆点。**负控**：还原切片修复重编，新断言 `[verify] a11y-password plainHidden=False masked=False assert=False` 抛异常（exit 134）；恢复后 `plainHidden=True masked=True assert=True`。
- **断言（套件只增，+2）。** ①`a11y-password`（如上，含明文不得出现 + `textInput` 圆点等长）；②`draw cull edge`：零尺寸框、shadow 外延触及 surface 的框、屏外 `Image` 三者都不得被剔除（`DrawKindText==2 && DrawKindImage`）。该条把本报告对 INTERP-DRAW2 的边界判定钉死（扫描未改产品剔除逻辑，故只做绿跑，不做产品侧变异红控）。套件计数根（`Program.cs:15`）与两断言已随并发 MULTIWINDOW-M 波次提交（ow `be70a73`，该波套件 607/609 floor 589）；本报告口径 = SEC-SCAN-4 贡献 +2。

## 逐面结论（无缺陷面含边界矩阵）

| 面 | 判定 | 证据 |
|---|---|---|
| INTERP-DRAW2 剔除 | **无缺陷** | `CanSkipOwnDrawing`：`opacity<=0` 只跳自身绘制（子仍走查）；`shifted/movesPixels`（平移/缩放/旋转/滚动）整树禁用；`Width/Height<=0`、NaN/Inf 均不跳（相交判定为假→绘制）；shadow 外延 = `Radius + max(|dx|,|dy|)+2` 覆盖实际绘制（`DrawShadow` 用同一 offset/radius）；`Image`/`ImageBytes`、popup/toolbar/flyout/carousel/TitleView 白名单不跳；`_drawSurface` 每帧设置。新断言补零尺寸/外延/图片三例 |
| AOT-STARTUP 重放跳过 | **无缺陷** | `set_app_context` 的 `strcmp` 与替换同在 `g_context_mutex`；相同快照仅省 `OhosHostReplaySurfaceNotification`（managed 已由 startApp 持有）；不同快照仍 retire+重放；无锁外读退休指针（`OhosHostRetireContextSnapshot` 只挂链、join 释放）；首用门 `ensureWebSlot` 先置 `webOverlaysMounted` 再建槽，重入幂等 |
| MULTIWINDOW-S | **无缺陷** | `CanArrangeSurface` = 非 Destroyed 且 >0（Changed/0x0 拒绝）；0x0/Destroyed 保留末帧；壳 `windowSizeChange`/`freeWindowModeChange` 经 `trackDisposer` 在 `aboutToDisappear` 精确 off，`windowShapeRegistered` 防重复；`reportWindowAvoidArea` 读失败降级为空 |

## 报告未修（patch 草图）

- **SEC4-SLOT1（WebView 区）。** `Index.ets` builder 用 `this.slotController(slot)`，`onControllerAttached` 无条件 `webSlotAttached[slot]=true`；`destroyWebSlot` 后旧组件回调落在这条路径上 → 新建槽 `webSlotReady` 假阳（命令打到未挂控制器 17100001 降级）。草图：builder 顶部 `const controller = this.slotController(slot);`，回调首行 `if (!this.webSlotCreated[slot] || this.webControllers[slot] !== controller) { return; }`，再 register/flush；`ensureWebSlot` 置 `webSlotAttached[slot]=false` 双保险。
- **SEC4-SLOT2（WebView 区/平台）。** 建议：`ensureWebSlot` 记录 ensure 时刻，在状态轮询里对 `created && !attached` 超时报 `web slot attach timeout: N` 并让托管池回收；**不提升 MAX**（N=8 实测 >4 不挂，产品维持 4/2）。
- **SEC4-CG2。** 文档已记 sha `6bb8a375…` 且 release 带 `SHA256SUMS`；建议消费脚本化：入 feed 前 `sha256sum -c`，或用 `packages.lock.json` + `--locked-mode`（NuGet content hash 校验）。默认源无该 RID 包（NU1100 fail-closed），`openharmony` RID 图无 `#import` → 无 linux 交叉喂养；`Microsoft.*` 前缀在 nuget.org 保留，无抢注面。
- **SEC4-A11Y2。** 加固建议：`Visit` 加节点上限（如 16384）并在宿主 `ohos_host_accessibility_begin` 同步夹取，超限一次告警；客户端已有 600/40 深帽。非跨信任面，未改以免截断大页面树。
- **SEC4-A11Y3。** `A11yExtAbility.dumpOnce` 对 `getWindows()` 每个窗口都 `walk` 入 `nodes`（`isTarget` 只控制点击/摘要）→ dump 文件与 hilog 含非目标应用文本。建议：非目标窗只记 bundle/windowId，不入 `nodes`。
- **SEC4-FPS。** 常量 `{60,60,60}` 在 API 合法域（0–120），无校验缺口；idle 撤销按 FPS48 §3 后续项处理（省电，非安全）。

## 验证与命令（离线；scratch `/data/storage/el2/base/tmp/opencode/sec4-*`）

```sh
cd ohos-workload/test/maui-platform-verify
dotnet build -v:q --no-restore -m:1 -nodeReuse:false          # 0 error（编译器吞掉切片 + 套件）
dotnet bin/Debug/net11.0/verify.dll | grep -E 'a11y-password|draw cull edge|\[suite\]'
#   绿：a11y-password plainHidden=True masked=True assert=True；draw cull edge ... assert=True
#   红控：还原 maui OpenHarmonyAccessibility 掩码后重编 → plainHidden=False assert=False（exit 134）
# 并发 MULTIWINDOW-M 波次（ow be70a73，同一 Program.cs）的套件口径：checks=607 total=609
#   floor=589（已含本报告 +2 断言；本机高负载下全量 csc 复跑超时，改隔离复跑）：
#   scratch /data/.../tmp/opencode/sec4-mini 只编切片 + 两断言 → [mini] a11y-password
#   plainHidden=True masked=True；draw cull edge zeroAndShadowText=2 image=True kinds=[3,0,0,1]；rc=0
```

**未覆盖/不确定：** 本轮未上机——修复与断言为离线复现（含红/绿负控）；读屏服务实际可达性取决于用户启用（修复直接消除暴露面，不依赖可达性判定）；SEC4-SLOT1/2 需真机 churn 复演（WebView 区未改）；N=8 >4 挂载失败为设备/平台事实（MAX 维持 4）；CG2-R2R 的 release sha 未在本机重算（文档值与 `SHA256SUMS`/API digest 双向核对，见 CG2-R2R 文）。
