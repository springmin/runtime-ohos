# 评审经验检查清单（源自 #132953 / #132827 / #135321 / #134670 评审，2026-10-14 汇编）

> 用途：对「当前移植代码」做提交前自审时的标准判据。每条都出自维护者原话或我方已确认的处置。

## 1. 命名

- 平台名一律写 **OpenHarmony**；不许 "HarmonyOS (OpenHarmony)"、不许 "HarmonyOS"（jkotas：
  "HarmonyOS is not the same as OpenHarmony"；jkoritzinsky：`ohos`→`openharmony`）。注释同样只谈
  OpenHarmony。
- 标识符：native 用 `TARGET_OPENHARMONY`（am11：比 TARGET_OHOS 可读）；MSBuild 用
  `TargetsOpenHarmony`（对齐 `TargetsAndroid`/`TargetsLinux`）；C# 用 `IsOpenHarmony()`。
- 唯一允许 `ohos` 的位置：**工具链契约名**（NDK/lowercased CMAKE_SYSTEM_NAME），且要一句短注释说明
  是 toolchain contract（不要长篇）。
- RID：`openharmony`/`openharmony-<arch>`，独立、**不 import linux-musl**；顶层 `#import: ["any"]`
  （jkotas：像其他顶级 OS）；**runtime.json 已冻结**，只改 `PortableRuntimeIdentifierGraph.json`
  （am11）。

## 2. 注释与变更范围

- 注释只写「做什么/为什么」，**禁止日期、lab 记录、历史叙事**（"drop the dated lab note"）；
  "unnecessarily verbose" 会被点名——一行能说清就一行。
- 不留多余空行/孤立注释；评审措辞要回填（"tighten the comments"/"neutralize the comment"）。
- **只动 OpenHarmony**：不顺手改 Android/其他平台（"keep Android untouched"）；不删除无关内容
  （"Why are you deleting this?"——先恢复再对齐上游）。
- 能不引入专用机制就不引入：优先跟随既有平台先例（freebsd/haiku 不带的东西就别带，如
  `__PortableTargetOS` 案）。

## 3. 设计与拆分

- **不新增 Mono 依赖**（Mono 将弃）；OHOS subsets 假定 CoreCLR-only。
- Linux 关系口径（已定）：RID/包层**不假装 Linux** ✓；C/C++ 编译层保留 linux+musl 映射（已被接受，
  注释简短说明是本地可复审决定）；`IsLinux()==true` 而 `IsOSPlatform("linux")==false`（已向 jkotas
  说明 + 留 Android-式一致的 follow-up）。
- 拆分：与争议设计无关的部分独立 PR（#134670 先例）；宁可小、单一目的。

## 4. 失败/降级逻辑（corehost 先例）

- 「optional」语义要显式：降级路径只影响可选组件；要有失败注入测试（HostActivation.Tests）；
  跨平台一致（unix+windows 同改，或明确只改一方的原因）。

## 5. C 面红线

- 平台分支用 `TARGET_*` 定义；`#endif` 配注释；4 空格；不用 auto；生产代码不用 printf。
- **fork-child 内不得 malloc**（先例：/proc/self/fd 用 getdents64 + 栈缓冲）。
- 平台专用 helper/宏必须有 `#if` 包裹，防 `-Wunused-function`/`-Wunused-macros` 在 -Werror 下爆
  （CLOSE_RANGE_CLOEXEC 先例）。
- 回退路径要**有界且快**：fd 类操作优先 /proc/self/fd 枚举；close_range 在 OHOS 被 seccomp 拦截
  （SIGSYS）——调用点必须 `!defined(TARGET_OPENHARMONY)` guard + 替代路径。
- 资源生命周期：fd/句柄成对；错误路径不泄漏。

## 6. C# 面

- 热路径零分配优先（详见 `analyzing-dotnet-performance` 技能检查单）；OS 判定/命名类 API 属常调面。
- 注释注明与 Linux 的差异理由。

## 7. 流程

- 推送前用「独立判断在前、PR 叙事在后」的自审（code-review 技能精神）；不报 CI 能抓的琐碎问题。
- 上游可见动作逐次报批；bot findings 除非用户点头否则不推码（防清审批）。
