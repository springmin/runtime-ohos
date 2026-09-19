# 五仓库代码规范审计（2026-09-19）
聚焦：稳定性 · 性能 · 边界。范围：`maui-ohos`（OpenHarmony 切片）、`ohos-workload`（宿主/NAPI/脚本/套件）、
`runtime-ohos`（文档）、`sdk-ohos`、`aspnetcore-ohos`（fork 增量部分）。

## 1. 探针结果（通过项）
| 检查 | 结果 |
|---|---|
| 宿主 C 分配后判空 | **5/5** ✓ |
| `strstr`/字符串解引用判空 | 已判空（`nodeText`/`description` 双条件）✓ |
| 托管 P/Invoke 异常保护 | 全仓 35 处 `catch`，逐调用点包裹（DllNotFound/EntryPointNotFound → 降级）✓ |
| 脚本健壮性 | 11 个脚本 **10 个 `set -e`**（`env.sh` 为 source 用，例外合理）✓ |
| 现有边界守卫 | `Math.Max(1, Span)`、`Math.Max(1, Interval)`、`Math.Clamp(ms, 1, 3000)`、差分循环用 `Math.Min` ✓ |
| NAPI 参数校验 | `argc` 检查 + `nullptr` 守卫 ✓ |

## 2. 本轮修复（含验证）
| 级别 | 问题 | 修复 | 验证 |
|---|---|---|---|
| **高（性能）** | 每帧**无条件**把整棵影子树发布给宿主：3 次 P/Invoke × N 节点 + 每节点 UTF-8 封送（60fps 下可达万级调用/秒）| `Publish` 先做帧间差分；**无变化则跳过全部原生通信**（新增 `WouldPublish` 可观测属性、`FramesSkipped` 计数）| 断言：`wouldPublish=False`（未变化帧）；回归 **128 项** ✓ |
| **中（边界）** | 无障碍屏幕矩形由 `float` 直接转 `int32`：极端坐标/NaN 会溢出或未定义 | 宿主新增 `A11yCoord()`：NaN→0，钳制到 ±32767，两处填充点统一使用 | 宿主构建+自签名 ✓ |

## 3. 建议项（未实施，按优先级）
1. **（规范，中）** `ohos-workload` 缺少 C# 分析器策略（无 `Directory.Build.props`：`TreatWarningsAsErrors`/`Nullable`/`AnalysisLevel`）。
   建议作为独立批次引入，先以 `Nullable=enable` + 警告清单基线化，避免一次性淹没。
2. **（性能，低）** `OpenHarmonyAccessibility.Refresh` 每帧重建节点 `List` 并读取 `SemanticProperties`；
   可复用缓冲 + 仅在布局/文本变化时重建（收益中等，风险低）。
3. **（性能，低）** 视图树遍历为递归实现（`ChildrenOf`/`DrawDiagnosticsFor`）；超深树有栈风险，可改迭代。
4. **（稳定性，低）** 宿主无障碍回调为 O(节点数) 线性查找；超大 UI 建议建索引（当前规模足够）。
5. **（规范，低）** 脚本输出日志目前散落；可统一为 `log()` 前缀（可读性）。

## 4. 结论
- 稳定性：无未判空分配、无未保护 P/Invoke、脚本普遍 `set -e`；本轮未发现崩溃级缺陷。
- 性能：**消除每帧全树发布**（最大热点）；其余为低收益项。
- 边界：矩形填充已钳制；索引访问均有界（差分循环用 `Math.Min`，`Math.Max(1,…)` 防零除）。
- 复现：`test/maui-platform-verify`（128 项，含无障碍快照/点击回流/未变化帧跳过断言）。
