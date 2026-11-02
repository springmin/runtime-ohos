# TouchBehavior NRE 根因与修复建议（2026-11-02）

> 结论：**不是 CommunityToolkit.Maui、Border 或 gesture 的问题**。NRE 发生在 MAUI 平台中性
> Controls 的 `PlatformBehavior<TView,TPlatformView>.OnLoaded`：`Loaded` 先于元素 handler 创建
> 触发，而该方法直接解引用 `view.Handler.PlatformView`（无空检查）。CommunityToolkit 的
> `TouchBehavior` 只是第一个踩到该顺序的消费者。

## 1. 复现与证据

- 构建：`test/maui-compat-app`，`-p:CompatCase=touch -p:OpenHarmonyRuntimeMode=jit`；
- 设备：HAD-W24（OpenHarmony 7.0.0.111 / API 26）；
- 启动后 hilog：

```text
[compat] EX NullReferenceException: Object reference not set to an instance of an object.
  stack=   at Microsoft.Maui.Controls.PlatformBehavior`2.OnLoaded(Object sender, EventArgs e)
[compat] TouchBehavior: PASS LIMIT toolkit NullReferenceException; compat behavior active
[compat] summary pass=1 fail=0
```

- AOT 下异常栈被裁剪为空（`site=? stack=`），所以此前只能看到“attach NRE”；
  JIT 栈把位置钉死到 `PlatformBehavior.OnLoaded`。
- 日志摘录：`/data/storage/el2/base/tmp/opencode/touchbehavior-jit-stack.txt`
  （原始 `touch-jit-2.hilog`，进程 27489，2026-11-02 14:52:14/17）。

## 2. 调用链

1. app 引用平台中性包 `Microsoft.Maui.Controls`（net11.0，**未定义 `PLATFORM`**）；
2. `VisualElement.IsLoaded` 在该配置下 = `Window != null`
   （`src/Controls/src/Core/VisualElement/VisualElement.cs:2429`）；
3. `VisualElement.Standard.cs:13` 在元素加入窗口时立即 `SendLoaded(false)`；
4. `PlatformBehavior` 订阅 `Loaded`，`OnLoaded` 在
   `src/Controls/src/Core/Interactivity/PlatformBehavior.cs:103-105` 执行：
   `if (sender is TView view && view.Handler.PlatformView is TPlatformView platformView)`；
5. 此时 Border/Button 的 handler 尚未创建 → `view.Handler` 为 null → NRE。

Android/iOS/Windows 使用带 `PLATFORM` 的 Controls 构建，`IsLoaded` 走平台视图判断，
不会在 handler 之前触发；OHOS 目前消费 net11.0 中性包，因此暴露该顺序。

## 3. 修复建议

### 3.1 上游 MAUI（推荐）

`PlatformBehavior` 对 `VisualElement` 同时监听 `HandlerChanged`，并在 `OnLoaded` 空检查；
新增路径用 `#if !PLATFORM` 限定在中性构建内，平台构建零新代码。草案（未提交）：

```diff
@@ protected sealed override void OnAttachedTo(TView bindable)
 		if (bindable is VisualElement ve)
 		{
 			ve.Loaded += OnLoaded;
 			ve.Unloaded += OnUnloaded;
+#if !PLATFORM
+			// Window != null can raise Loaded before the handler exists in the neutral build.
+			ve.HandlerChanged += OnHandlerChanged;
+			if (ve.Handler is not null)
+				FireAttachedTo(bindable);
+#endif
 		}
@@ protected sealed override void OnDetachingFrom(TView bindable)
 		if (bindable is VisualElement ve)
 		{
 			ve.Loaded -= OnLoaded;
 			ve.Unloaded -= OnUnloaded;
+#if !PLATFORM
+			ve.HandlerChanged -= OnHandlerChanged;
+#endif
 		}
@@ void FireAttachedTo(TView bindable)
 		if (bindable?.Handler?.PlatformView is TPlatformView platformView)
 		{
+#if !PLATFORM
+			if (ReferenceEquals(_platformView, platformView))
+				return;
+			if (_platformView is not null)
+				OnDetachedFrom(bindable, _platformView);
+#endif
 			_platformView = platformView;
 			OnAttachedTo(bindable, platformView);
 		}
@@ void OnLoaded(object? sender, EventArgs e)
 	{
-		if (sender is TView view && view.Handler.PlatformView is TPlatformView platformView)
+		if (sender is TView view)
 		{
-			OnAttachedTo(view, platformView);
-			_platformView = platformView;
+#if !PLATFORM
+			FireAttachedTo(view);
+#else
+			if (view.Handler?.PlatformView is TPlatformView platformView)
+			{
+				OnAttachedTo(view, platformView);
+				_platformView = platformView;
+			}
+#endif
 		}
```

`FireAttachedTo` 在非 PLATFORM 下幂等，并在 handler 替换时先 detach 旧 platform view；
平台构建保持原有 Loaded-only 行为。

### 3.2 本地 workaround（已采用）

`test/maui-compat-app/CompatTouchBehavior.cs`：纯 MAUI gesture recognizer
（Tap + Pointer pressed/released + dispatcher timer），不依赖 handler/platform view；
tap / 按压 / 长按均 PASS，并已进入 P0 门禁的 compat pin。

### 3.3 长期方案

为 OHOS 构建带 `PLATFORM` 的 `Microsoft.Maui.Controls`（补 `PlatformView` 别名与
`IsLoaded` 平台判断），可一次性修正所有 `PlatformBehavior` 消费者；成本高于 3.1，
适合 RTM 后与上游一起评估。

## 4. 验证计划（待上游修复后）

1. 单测：构造一个 `VisualElement`，先触发 `Loaded`（Handler=null），再设置 Handler；
   断言 `PlatformBehavior.OnAttachedTo(view, platformView)` 在 HandlerChanged 时调用一次，
   且全程无 NRE；
2. 设备：去掉 `CompatTouchBehavior`，用 toolkit 原 `TouchBehavior` 跑 touch-only 页；
   期望 summary PASS、无 `[compat] EX NullReferenceException`；
3. AOT：同一用例 AOT 发布 + 稳定 8 s。

## 5. 对其他 OS 的影响与验证

补丁的隔离面：

- 平台 TFM（android / ios / maccatalyst / windows / tizen）定义 `PLATFORM`；新增的
  `HandlerChanged` 订阅、幂等/替换 detach 全在 `#if !PLATFORM` 内，**不编译**，行为与现状一致。
- 唯一无条件改动 = `view.Handler?.PlatformView`。平台构建在 Loaded 时 Handler 非空，
  等价于原逻辑；若为 null，旧代码抛 NRE，新代码安全跳过（防御性）。
- 非 PLATFORM（netstandard2.0/2.1、net11.0）才走 HandlerChanged 回退；OHOS 消费的
  net11.0 中性 Controls 是修复目标。

验证：

- 预处理边界：`PlatformBehavior.cs` 顶部 `#elif NETSTANDARD || !PLATFORM`；Controls 平台
  构建由 SDK 定义 `PLATFORM`（源码中大量现有 `#if PLATFORM` 依赖它）。
- **文件级 stub 编译（本机）**：把 patched 文件 + 最小 MAUI 桩放进 `net11.0` 项目：
  - no-PLATFORM：**0 error**（过程中抓到并修正了 `FireAttachedTo(ve)` 的
    `VisualElement`→`TView` 类型错误，以及 `OnLoaded` 绕过幂等 guard 的双 attach 路径）；
  - `PLATFORM;ANDROID`：**0 error**，且 `Element.HandlerChanged` 未被使用
    （`#if !PLATFORM` 的新订阅被排除）。
  - 该 stub 只验证该文件的语法/预处理路径，不替代 MAUI 全量构建。
- 完整 net11.0 Controls 构建本机**未完成**：Arcade restore 未生成 `project.assets.json`
  （网络/feed 阻塞），不是编译错误；不作为通过证据。
- 上游 PR 需附：net11.0 单测（Loaded 时 Handler=null → HandlerChanged 只 attach 一次）+
  Android/iOS/Windows 现有 `PlatformBehaviorTests` 全绿（平台代码未变）。

风险：

- 非 PLATFORM 第三方若依赖“Loaded 前不 attach”，会看到更早 attach；对 OHOS 是修复，
  对 netstandard 测试可能改变时序，应由单测锁定。
- 平台构建零新代码路径，回归风险低。

## 6. 状态

- 根因：**已定位**（本文）；
- 上游 issue/PR：**未提交**（本会话不处理上游；草案已备）；
- 补丁范围：已收敛 `#if !PLATFORM`；stub 编译 no-PLATFORM 与 `PLATFORM;ANDROID`
  均 **0 error**，平台分支不编译新订阅；
- 完整 Controls 构建：本机未完成（Arcade restore 阻塞），未作为证据；
- 本地替代：`CompatTouchBehavior` 已交付并通过 5/5 矩阵；
- 关联：`2026-10-29-ohos-maui-thirdparty-compat.md` §9/§10。
