# CommunityToolkit.Maui 兼容矩阵（第三方库首轮，2026-10-29）

> 口径：`maui-ohos` `feature/openharmony` @ `868d3c8727b`（MAUI 11 rc.2）+
> `CommunityToolkit.Maui` **15.0.1**（NuGet 最新；net10.0 资产，依赖 `Microsoft.Maui.Controls`
> 10.0.90）+ `ohos-workload` `test/maui-compat-app`。设备 = HAD-W24 / OpenHarmony 7.0.0.111。
> AOT 发布、真机运行；每个控件单独一版页面（`-p:CompatCase=...`）隔离崩溃。

## 1. 构建面（先于运行）

| 项 | 结果 |
|---|---|
| 还原 / 编译（`net11.0-openharmony26.0`） | **PASS**（0 error；已提交的 net10.0 资产可在 MAUI 11 rc.2 下编译） |
| NativeAOT 发布 | **PASS**（hap 21,785,379 B；`libmaui-compat-app.so` 17,779,440 B） |
| 裁剪告警 | **IL2026 ×1–2**（`Expander..ctor` 标注 `RequiresUnreferencedCode`；调用链进入 `Binding.Binding(string,...)`）；IL3050 / IL3051 = 0 |
| 结论 | 工具包可作为**普通 NuGet 依赖**接入；AOT 不阻断构建，但 Expander 的绑定路径有裁剪风险 |

## 2. 运行矩阵

| 控件 | Slice handler | 真机稳定性 | 可见性 | 判定 |
|---|---|---|---|---|
| `Expander` | `OpenHarmonyContentViewHandler` | 稳定（8 s+，无新 fault） | 未截图（本轮未取） | **PASS\*** |
| `AvatarView` | `OpenHarmonyBorderHandler` | 稳定（8 s+，无新 fault） | **不可见**（仅行标题，圆形头像未出画） | **LIMIT** |
| `DrawingView` | **无**（`$no-slice-handler`） | 未进入树 | — | **FAIL（需 handler）** |
| `TouchBehavior` | 行为，无 handler | 附加 PASS；命令路径可执行 | 未单独出画（all 版 summary 3 PASS） | **PASS\*** |
| `Popup` | `null` | **CppCrash**（SIGSEGV，UI 线程，启动后 ≈3 s） | — | **FAIL（需集成）** |

\* `PASS*` = 构建/连接/存活通过；视觉与交互还需逐项截图闭环。

**可用度：3/5 可用（含 LIMIT），2/5 需要移植工作。**

## 3. 关键证据

### 3.1 Popup 触发原生崩溃

`hidumper -e --print 02860493995795444667`：

```text
Reason:Signal:SIGSEGV(SEGV_MAPERR)@000000000000000000  probably caused by NULL pointer dereference
Fault thread info:
Tid:40517, Name:t.springmin.com
#00 pc 0000000000828e44 .../libmaui-compat-app.so
```

- 进程存活 ≈3 s；崩溃前**没有** `Popup slice-handler` 状态行，说明崩溃发生在
  `ShowPopupAsync` 的导航/页面呈现路径，而不是 handler 查找。
- `Popup` 在 net10.0 中性资产里由 `PopupPage`（ContentPage）承载，但 slice 的页面/导航栈
  没有为它准备平台承载；`ShowPopupAsync` 进入后空指针。
- **规避**：`PopupExtensions.ShowPopupAsync(Page, View, ...)` 的 **View 重载**尚未验证；下一轮优先试，
  若可用则把 `Popup` 控件判为 LIMIT（改用 View API）。

### 3.2 DrawingView 无 slice handler

`FindSliceHandlerType(typeof(DrawingView))` = `null`。`DrawingView` 不属于
`IGraphicsView`/`TemplatedView` 的已注册路径，slice 的 connector 只按**精确类型 → 接口 → 基类**
查找，`CommunityToolkit.Maui` 自带的 `DrawingViewHandler` 不在 slice 表里，也不被 connector 使用。

- 影响：控件加入树会在 connect 阶段失败（探针在加入前拦截，页面保持存活）。
- 建议：实现 `OpenHarmonyDrawingViewHandler`（线稿模型可直接落到
  `OpenHarmonyView` 的 canvas，或桥到 `GraphicsView` 的 `IDrawable`）。

### 3.3 AvatarView：handler 有、画面无

截图（`compat-avatar.jpeg`）只有 “AvatarView” 行标题，圆形头像未出画；进程稳定。
handler 解析到 `OpenHarmonyBorderHandler`，说明 `AvatarView` 被当作 `Border` 连接。
缺口在**控件模板/测量**（`AvatarView` 的 `Text` + `CornerRadius` 组合未产生可绘制内容），
不在 handler 注册。

### 3.4 两个环境级发现（会影响所有第三方库）

1. **预编译 ArkTS 壳按 bundle 名索引模块**：把 `OpenHarmonyBundleName` 改成
   `compatmaui...` 后安装成功，但启动时报
   `ReferenceError: Cannot find module 'ets/entryability/EntryAbility'`；
   abc 里的模块键是 `mauidemo.dotnet.springmin.com/entry/...`。
   → 新 bundle 必须重编壳 abc（或复用产品 bundle）。
2. **不要在 UI 线程之外续接 MAUI 界面操作**：`Loaded` 里的 `async` 续接在无
   `SynchronizationContext` 时落到 `.NET TP Worker`，0.55 s 后 SIGSEGV；
   改用 `Dispatcher.DispatchDelayed` 后进程稳定。这条对所有自绘/MAUI 应用都适用。

## 4. 结论与工作量

| 项 | 结论 | 估算 |
|---|---|---|
| Expander / TouchBehavior | 可直接用（视觉待截图闭环） | 0.5 人日 |
| AvatarView | handler 通、模板不出画 | 1–2 人日 |
| DrawingView | 需新 handler | 1–3 人日 |
| Popup | 需 PopupPage/导航承载集成；先试 View 重载 | 3–5 人日 |
| 壳 bundle 绑定 | 新 bundle 需重编 abc（打包链能力） | 1–2 人日 |

**净结论**：CommunityToolkit.Maui 15.0.1 在 MAUI 11 rc.2 + 本 slice 上**可编译、可 AOT、
基础控件可跑**；平台相关控件（Popup / DrawingView）需要 slice 侧适配。第三方库生态不是
“零成本”，但缺口是**可枚举、可估算**的，不是整库不可用。

## 5. 证据与复现

- 样例：`ohos-workload/test/maui-compat-app`（`7cef629`）
  - `-p:CompatCase=none|expander|avatar|drawing|touch|popup` 单控件隔离
  - `COMPAT_CASE=... sh test/maui-compat-app/publish-aot.sh`
- 文档：`ohos-workload` 提交 `7cef629`；本轮 AOT 日志
  `/data/storage/el2/base/tmp/opencode/compat-aot/publish-aot.log`
- 截图：`compat-avatar.jpeg`（AvatarView 不可见）；`compat.jpeg`（首版页面）
- fault：`02860493995795444667`（Popup CppCrash）
- 设备：HAD-W24 / 7.0.0.111；测试后已卸载 `mauidemo...` 并释放 `.device-lock`。

## 6. 下一轮（T2 收尾）

1. 用 `ShowPopupAsync(Page, View, ...)` 的 View 重载复测 Popup；若可用，记录规避写法。
2. 给 `DrawingView` 落最小 handler（先画线 + 清空），设备截图。
3. 修 `AvatarView` 模板/测量（或记录为上游模板问题）。
4. 为 Expander / TouchBehavior 各留一张真机截图 + 一次点击。
5. 结论回填 P0 计划 T2；通过后进入 T3 Reference App。

## 7. 补齐进展（2026-10-29 晚）

代码面已完成，**设备复验被启动异常阻断**：

| 项 | 状态 |
|---|---|
| Slice 扩展点 | `OpenHarmonyHandlerConnector.RegisterHandler(viewType, handlerType)`（maui `e1a44c33b6a`）——第三方库 handler 的受支持入口，带 `DynamicallyAccessedMembers` 注解 |
| DrawingView handler | `CompatDrawingViewHandler`（`OpenHarmonyViewHandler<DrawingView>` + `OpenHarmonyCanvas` 画线），经上述 API 注册；JIT 编译与 AOT 发布 **PASS**（ohos-workload `fc9e200`） |
| Popup | 改用 `ShowPopupAsync(Page, View, ...)` 的 View 重载（`Border` 内容），不再走 `Popup` 控件路径；AOT **PASS** |
| AvatarView | 增加 `MinimumWidth/HeightRequest` 与 `Start` 对齐（待出画验证） |
| 设备复验 | **BLOCKED**：重装后 `aa start` 返回 success，但无 appspawn/进程/fault，dock 图标不可见；设备 load ≈22、内存 27 GB/32 GB。此前同一 hap（未含上述改动）可正常启动，故判为设备态问题，需重启/空闲后重试 |

**不把“AOT 通过”当成“运行通过”**：矩阵 §2 的运行时结论仍是首轮实测值；补齐项待设备恢复后重跑并更新。

复验步骤（设备恢复后）：

```bash
# 1) 取锁；安装；从 dock 图标启动（aa start 在该设备上不可靠）
hdc -t 127.0.0.1:36823 install -r test/maui-compat-app/bin/Release/*/openharmony-arm64/maui-compat-app.hap
hdc -t 127.0.0.1:36823 shell "uitest dumpLayout -p /data/local/tmp/l.json"   # 找 dock 图标 bounds 后 click
# 2) 检查：进程存活 8s+、无新 CppCrash、页面含 5 行结果
hdc -t 127.0.0.1:36823 shell "hidumper -e --list mauidemo.dotnet.springmin.com"
# 3) 截图 + 点 “Show Popup”（View 重载）与 “Fire TouchBehavior command”
```
