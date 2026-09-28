# MAUI W2A 状态：T4 Label FormattedText/Spans 富文本（2026-09-28）

> Backlog：`2026-09-28-ohos-maui-port-backlog.md` §2 T4。范围 = maui-ohos 切片 +
> OpenHarmony 在树 PublicAPI + ohos-workload 交互/像素套件断言。**未做真机验证**。
> 未改三 workflow pin（收口统一推进）。

## 1. 提交

| 仓库 | 提交 | 内容 |
|---|---|---|
| maui-ohos `feature/openharmony` | `043e6468` | T4：`FormattedText`/`Span` 解析为平台 runs + 视图 run 化排布/绘制 + `MapFormattedText` + PublicAPI |
| ohos-workload `master` | `938d710` | 交互套件 T4 断言（`l1`–`l4`，+4，420/400）+ README |
| ohos-workload `master` | `888a956` | 像素套件：格式化文本各 span 颜色断言（T4） |
| runtime-ohos | 本文 | 状态记录 |

## 2. 实现要点

- **映射**：`Label.FormattedText` → `OpenHarmonyFormattedText.Create`。span 的
  TextColor/FontSize/FontAttributes/CharacterSpacing/LineHeight/TextDecorations/
  BackgroundColor 覆盖 label 级样式（粗斜体与 label 合并），TextTransform 继承
  span→label 并在排布前展开；`Text`/`FormattedText` 互相清除，两个映射器都按
  “读当前属性对”收敛（两种事件顺序都正确），label 级样式变化时重建 runs。
- **排布/绘制**：`OpenHarmonyFormattedTextLayout` 按 run 边界测量（跨 span 的单词仍
  作为一个词换行，每 run 自己的字号/字距推进），支持 NoWrap/CharacterWrap/WordWrap
  与三种截断 + MaxLines 尾截断；逐 run 绘制颜色/字号/粗体/字距（逐字形模拟）/装饰线/
  背景块。斜体（无字体倾斜 API）、span 字体族（进程级单字体）、span 手势（无可命中
  字形范围）经状态通道一次性诚实降级。
- **PublicAPI**：新增 `OpenHarmonyLabelHandler.MapFormattedText`；run/布局模型保持
  internal。

## 3. 验证（离线）

- 切片构建（Release + trim/AOT 分析器 + `-warnaserror:IL2026,IL3050`）：
  **0 error / 0 IL**。
- 交互套件：**420/420，floor 400，assert=True**，本批 `l1`–`l4` 全 True。T3 尚未并入
  `feature/openharmony`，故验证在临时集成树（`t3-graphics` + `c56bf0fa` + T4，无冲突）
  上进行；套件提交 `938d710` 只含本批 4 行（不含 W2C 的 T10 行）。
- 像素套件：`PIXEL ASSERTIONS PASSED`（新增 `formatted span colours red=117
  blue=156`）。
- 宿主契约：未新增导出。

## 4. 未决/依赖

- 真机：字体族/字号缩放后的 run 度量、长段落富文本换行、span 手势（未实现）。
- 集成：`t3-graphics`（T3）尚未并入 `feature/openharmony`；三 workflow pin 与
  checks/floor 收口统一推进。
