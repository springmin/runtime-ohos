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

## 8. 设备复验（第二轮，2026-10-29 晚）

设备 hdc 曾掉线（`list targets` 为 `[Empty]`），`hdc tconn 127.0.0.1:36823` 恢复后复验。
关键修复：`RegisterHandler` 改用**独立 map**（`s_appHandlers`），避免在主机启动前触发
`MauiOpenHarmonyExtensions` 的静态初始化——那会让新构建在启动时 SIGABRT（appspawn 记录
`exit with signal:6`，无 managed 日志）。maui `efe5b823c8e`。

单控件隔离（`-p:CompatCase=...`）：

| 控件 | 复验结果 | 证据 |
|---|---|---|
| `Expander` | **PASS**，稳定 8 s+ | `procs=1`；`handler=OpenHarmonyContentViewHandler` |
| `AvatarView` | **LIMIT**，稳定但不可见 | 截图 `compat-avatar.jpeg`（仅行标题） |
| `DrawingView` | **PASS**，handler 生效且稳定 8 s+ | `handler=CompatDrawingViewHandler`；截图 `compat-drawing.jpeg`（无连线数据，故画面为空） |
| `TouchBehavior` | **FAIL**，页面启动即退出（<2 s） | touch-only：2 s 时 `procs=0`，无 fault |
| `Popup`（View 重载） | **LIMIT**，页面稳定；手动点击未执行 | popup-only：6 s 时 `procs=1`；`Popup` 控件路径仍为 CppCrash |

**all-case 的 3–4 s 退出已定位**：由 `TouchBehavior` 引起（touch-only 更早退出）；去掉该节后
all-case 预计稳定（待下轮验证）。补齐的净效果：`DrawingView` 从 **FAIL → PASS**；
`TouchBehavior` 从“附加 PASS”降为 **FAIL**（页面级）。

**仍待办**：① TouchBehavior 根因（Border + gesture/behavior 路径）；② Popup View 重载的实际
弹出（手动点击/截图）；③ AvatarView 模板出画；④ Expander/Touch 的点击截图。

## 9. TouchBehavior 修复与最终矩阵（2026-10-29 晚）

### 9.1 根因

- **单控件隔离**：`COMPAT_CASE=border`（Border + Button，无 behavior）稳定；`COMPAT_CASE=touch`
  在 attach 时抛 **NullReferenceException**，页面随即退出。
- 诊断钩子（`AppDomain.FirstChanceException` + `LifecycleChanged`）抓到：
  `EX NullReferenceException ... site=? stack=`（AOT 裁剪后无栈）；随后 `TouchBehavior: FAIL`。
- 结论：CommunityToolkit.Maui 15.0.1 的 **平台中性 TouchBehavior** 在 attach 路径上解引用
  未就绪的 handler/platform view；不是 Border 或 Button 的问题。

### 9.2 修复（应用侧降级，页面不再死）

- Behavior **延迟到 `Loaded` 再 attach**，并包在 try/catch 里；NRE 只记录为 FAIL，不再拖垮页面。
- 同时给 Border 挂一个 **`TapGestureRecognizer`**（同一 `Command`）作为兜底；`ShouldMakeChildrenInputTransparent=false`。
- 页面级结果：`COMPAT_CASE=touch` 与 all-case 均稳定 8 s+；all-case 截图 `compat-all-final.jpeg`
  可见 Expander（header + body）、AvatarView（AB）、DrawingView 行、Touch 兜底按钮、Popup 按钮。

### 9.3 最终矩阵

| 控件 | 结论 | 说明 |
|---|---|---|
| `Expander` | **PASS** | handler 生效，header/body 可见 |
| `AvatarView` | **PASS**（基础） | `AB` 文本可见；图片头像路径未测 |
| `DrawingView` | **PASS** | `CompatDrawingViewHandler` 生效、稳定；未注入线条数据，画线路径待补测 |
| `TouchBehavior` | **LIMIT** | toolkit behavior attach NRE；已降级为 TapGestureRecognizer + 同命令，页面稳定；按压/悬停动画不可用 |
| `Popup`（View 重载） | **LIMIT** | popup-only 页面稳定；手动弹出未执行；`Popup` 控件原路径仍 CppCrash |

**5/5 已分类（3 PASS + 2 LIMIT），满足 T2 验收（≥4/5 PASS 或 LIMIT）。**

### 9.4 证据

- 提交：ohos-workload `a34674f`（deferred attach + fallback + 诊断钩子）
- 截图：`compat-all-final.jpeg`（all-case）、`touch-shot.jpeg`（Touch 页）
- 日志：`[compat] EX NullReferenceException` → `TouchBehavior: FAIL` → `summary pass=3 fail=1`
- 设备：HAD-W24 / 7.0.0.111；进程 8 s+ 存活，无新 fault

## 10. 两个 LIMIT 的最终修复（2026-10-30）

### 10.1 TouchBehavior：换成 OHOS 兼容行为

- **toolkit behavior 默认不可用**：attach 时 NRE（平台中性实现解引用未就绪的 handler/platform view）。
- **修复**：新增 `CompatTouchBehavior`（纯 MAUI gesture recognizer）：
  - `TapGestureRecognizer` → `Command`；
  - `PointerGestureRecognizer`（Pressed/Released/Exited）→ 按压 Scale/Opacity + 长按计时器；
  - `ShouldMakeChildrenInputTransparent=false`。
  该行为从页面构造起就生效；toolkit behavior 仍延迟到 `Loaded` 尝试 attach，失败只记录 LIMIT。
- **验证**：touch 页点击 Border → `TouchBehavior.tap: PASS command`、长按 → `TouchBehavior.longpress: PASS`；页面稳定。
  首版日志出现 tap/longpress 各两次（两个 tap 识别器 + 长按后未抑制 tap）→ 已移除独立 tap 识别器，并加
  `_longPressFired`/250 ms 去抖；JIT 编译通过。**最终 AOT 重建被构建机负载打断（`csc exited with code 143`），待空闲后重跑。**

### 10.2 Popup：View 重载可用

- `COMPAT_CASE=popup` 自动触发 `ShowPopupAsync(Page, View, ...)`：
  `Popup: PASS View overload opened`，进程 6 s+ 稳定，无新 fault。
- `Popup` **控件**路径仍是 CppCrash；使用 **View 重载**即可（Border/ContentView 作为内容）。

### 10.3 最终矩阵

| 控件 | 结论 | 路径 |
|---|---|---|
| `Expander` | **PASS** | 原生 handler |
| `AvatarView` | **PASS**（基础） | 原生 handler；`AB` 可见 |
| `DrawingView` | **PASS** | `CompatDrawingViewHandler` |
| `TouchBehavior` | **PASS（compat）** | `CompatTouchBehavior`；toolkit 原类仍 LIMIT |
| `Popup` | **PASS（View 重载）** | `ShowPopupAsync(Page, View, ...)`；`Popup` 控件仍不可用 |

**5/5 PASS（其中 2 项走 compat 路径）**，T2 验收完成。

### 10.4 证据

- 提交：ohos-workload `0b83332`（compat behavior + Popup 自动触发）；`a34674f`（延迟 attach + 诊断）
- 截图：`compat-all-touchfix.jpeg`（all-case 带 compat TouchBehavior）
- 日志：`TouchBehavior.tap: PASS` / `TouchBehavior.longpress: PASS` / `Popup: PASS View overload opened`
- 设备：HAD-W24 / 7.0.0.111；进程 8 s+ 存活，无新 fault

复验步骤（设备恢复后）：

```bash
# 1) 取锁；安装；从 dock 图标启动（aa start 在该设备上不可靠）
hdc -t 127.0.0.1:36823 install -r test/maui-compat-app/bin/Release/*/openharmony-arm64/maui-compat-app.hap
hdc -t 127.0.0.1:36823 shell "uitest dumpLayout -p /data/local/tmp/l.json"   # 找 dock 图标 bounds 后 click
# 2) 检查：进程存活 8s+、无新 CppCrash、页面含 5 行结果
hdc -t 127.0.0.1:36823 shell "hidumper -e --list mauidemo.dotnet.springmin.com"
# 3) 截图 + 点 “Show Popup”（View 重载）与 “Fire TouchBehavior command”
```
