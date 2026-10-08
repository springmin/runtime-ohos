# SEC-5c E/F 加固（maui 侧）：pinch 有限性 · 子窗 a11y 帧边界（2026-10-08）

**范围：** maui `maint/sec5c-ef` @ `6f278ee99b`（基 `619c40a483`，3 文件 +183/−8）· ow `maint/sec5c-ef` @ `95e4a68`（套件 pin，基 `3ecec5c`，+120/−1）。**口径：** 离线读码 + 2×套件构建兼跑（绿 + 门禁禁用红控）+ 1× slice trim/AOT 门禁；未上机；不并 master/feature、禁强推；ow 默认 CI pin 未动（待合并波次）。

## E pinch 有限性（SEC5C-E 报告 → 已修）

- 新 `OpenHarmonyPinch.TryNormalize(phase,scale,x,y,out normalizedScale)`：started/running 的非有限中心拒绝；running 的非有限/≤0 scale 拒绝、有限极值钳制 `[1e-3, 1e3]`；completed 恒放行（Dispatch 不读其 scale，丢弃会卡死 `IsPinching`）。
- 双门禁：`HandlePinch` 先判后走树（非有限不再触发全树 hit-test），`Dispatch` 终门再判（直呼同样安全）；越界拒绝/钳制不回传改变路由结果。
- 正常手势语义不变：真实手势远离边界；套件既有 `Running:1.5` 逐字保留。

## F 子窗 a11y 帧边界（SEC5C-F 报告 → 已修）

- **数量上限** `MaxWindowFrames=8`（对齐 native `OHOS_A11Y_MAX_NAMED_PARTITIONS`）：满表丢新窗帧（`WindowFramesDropped` + 单次状态行），`ReleaseWindow` 释放槽可复用；帧/差分基线/provider 先发布标记三者随窗一致回收。
- **尺寸上限** `MaxWindowFrameNodes=4096`（仅子窗；主窗传 `int.MaxValue` 零变化）：超长走查截断为合规前缀（父 id 全可解析）并计 `WindowFrameWalksTruncated`。
- **空帧**：子窗空帧 publish 直接返回（不落基线、不探 provider、不计计数）；`Refresh(null/空 id)` 为 fail-safe no-op（保留旧帧、不抛）。

## 红绿 / 门禁

- 绿：`[suite] checks=744 total=747 floor=727 assert=True`、rc=0、perf 两行 within；新增 6 条（pinch 非有限丢弃 / 极值钳制；帧数量上限 / 释放复用 / 节点截断 / 空帧 no-op）全 True。
- 红控：同套件 + 门禁禁用切片（保留 API 面）→ 恰 6 条 `assert=False`、rc=134；其余全绿（证明判定面独立）。
- AOT：slice `IsAotCompatible+EnableTrimAnalyzer+EnableAotAnalyzer`、`-warnaserror:IL2026,IL3050` → Build succeeded、0 IL warning。
- 主窗零回归：主 `s_frame`/主 walk（`int.MaxValue`）/主 Publish 序列逐字保留；全套件既有主窗 a11y/pinch/焦点检查无红。

## 提交 / 不确定

- 提交：maui `maint/sec5c-ef` `6f278ee99b`、ow `maint/sec5c-ef` `95e4a68`（普通推送新分支；未并 master、未强推）；本文 → runtime `feature/openharmony`（`commit-paths.sh` 限路径）。
- 不确定：未上机（设备未验证；pinch 注入面/a11y 真机 e2e 沿用既有降级口径）；alert 节点叠加在 `MaxWindowFrameNodes` 之上（走查上限不含 alert，主/子同形）；8/4096 为防御性取值，正常 UI 远未触及。
