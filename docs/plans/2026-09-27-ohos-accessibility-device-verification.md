# 无障碍真机验证清单（P0b-A11Y，2026-09-27）

**范围**：影子无障碍树（托管 `OpenHarmonyAccessibility` → 宿主 ArkUI provider）在 kit #31 真机上的逐项验证（MAUI 主包承 #30、abc/宿主不变；#31 新增的 Blazor 组件不改变 MAUI 无障碍路径）；只做验证与采集，不改壳/托管源码。
**样品**：默认 `hello-maui-app.hap`（重签后安装）；演示页含 Entry/CheckBox/Switch/Slider/ProgressBar/CollectionView/ListView/HybridWebView/BlazorWebView（无 Image 入口 → I1 登记未测）。
**前置**：点左下角 `A11Y` 确认 `accessibilityStatus: 1 (attached - expected)`；读屏 =「设置 → 辅助功能 → 屏幕朗读」；每轮开始 `hdc shell hilog -r`（或直接 `--capture`）。
**采集**：`sh tester-run.sh --kit-dir <kit> --install --start --capture 30 --a11y-probe`（v13；v12 亦可，`--a11y-probe` 行为不变）→ `a11y/selfcheck.txt`、`a11y/selfcheck-layout.json`、`a11y/hilog-a11y.txt`，`summary.txt` 增 `a11y_*` 键（另含 `runtime_mode`）；旧脚本按文末「手动采集」。
**维度**：影子树语义（role/text/description/hint/bounds/enabled/focusable/range/checked）· 朗读串（角色+文本+状态）· 焦点顺序（几何方向/发布树序）· 动作触发（双击 = CLICK 回放为画布点按）· 几何命中（节点 bounds 中心）。
**判定**：全部「通过判据」满足 = PASS；本包无入口 =「未测（本包无入口）」不判失败；有入口但语义/动作/几何不符 = FAIL（附录屏 + `a11y/` + 对应 hilog 关键字）。

| # | 检查点 | 操作 | 期望（语义/朗读/焦点/动作/几何） | 证据 | 通过判据 |
|---|---|---|---|---|---|
| B1 | A11Y 自检基线 | 启动后点左下角 `A11Y` | `accessibilityStatus: 1 (attached - expected)`；`accessibilityNodeCount` 为正整数（约 3xx 级） | 截图 + `a11y/selfcheck.txt` + `dotnet-status.txt` 的 `[maui] accessibility provider status=1` | status=1 且节点数 > 0；非 1 原样回传（0 未附着 / 2 frame node 被拒 / 3 CUSTOM 未创建 / 4 provider 拒绝） |
| E1 | Entry（textInput） | 读屏聚焦 `type here (soft keyboard)` → 双击 → 打字 | role=textInput、可聚焦、朗读占位/文本；双击 = CLICK 进入编辑；bounds=画布输入框矩形 | 录屏 + `selfcheck-layout.json` 的 textInput 节点 | 可聚焦且朗读；双击后软键盘弹出、文字上屏 |
| L1 | Label / 标题 | 读屏聚焦 `MAUI on OpenHarmony`、`tap this label` | role=text；朗读=Label 文本；标题类=header；Label 的 CLICK 无副作用 | 录屏 | 朗读串=文本内容；无状态变化/无崩溃 |
| B2 | Button | 读屏聚焦 `Count: N`、`Run animations` → 双击 | role=button；双击一次=一次画布点按（计数恰好 +1）；朗读按钮文本 | 录屏 + 计数变化 | 不多触发/不落点偏移；点击后朗读刷新 |
| C1 | CheckBox | 读屏聚焦 CheckBox（初始勾选）→ 双击 | role=checkBox、checked 0/1 随读屏状态播报；双击切换 | 录屏 + 勾选态变化 | 状态切换且朗读更新 |
| S1 | Switch | 读屏聚焦 Switch（初始关）→ 双击 | role=switch、checked 0/1；双击切换 | 录屏 | 同 C1 |
| I1 | Image | M8/功能探针页（kit #30/#31 无入口） | role=image、text 空、`SemanticProperties.Description` 作为朗读 | 探针页录屏 | 有入口才判：朗读描述、不误读为文本；无入口=未测 |
| N1 | List（CollectionView） | 读屏聚焦 `scrollable row i`；滑动/翻页手势 | 行=text 可聚焦朗读；容器=`scroll` 并发布 scroll 动作；滚动步进≈0.8 视口 | 录屏 + 滚动前后 dump | 行文本可朗读；手势可滚动且焦点见 F2 |
| W1 | WebView（hybrid/Blazor） | 打开 hybrid 页/Blazor 页 → 读屏遍历 | 宿主 WebView=影子树 `group` 节点 + 状态 Label 可朗读；**网页 DOM 文本不发布**（自绘画布边界） | 录屏 + dump | 宿主节点/状态文本可见、不崩；DOM 文本未发布登记为已知边界（不判失败） |
| M1 | 模态/弹层焦点陷阱（ArkUI） | 读屏开 → 点 `A11Y` 打开自检弹窗 → 焦点遍历 → 点 `OK` 关闭 | 焦点进入弹层、背景控件不可达；可朗读标题/正文/`OK`；关闭后焦点回应用 | 录屏 | 焦点不逃逸到背景；关闭后可继续操作 |
| M2 | 自绘弹层（已知缺口） | `DisplayAlert`/ActionSheet（kit #30/#31 无入口） | 自绘层不进影子树 → 读屏读不到弹层内容（现状缺口，非回归） | 无入口；有探针页时录屏 | 登记为缺口，不判失败；后续包补入口后按 M1 标准复判 |
| F2 | 滚动中焦点保持 | 长列表读屏聚焦中间一行 → 滑动滚动 → 观察焦点 | 滚动后焦点仍在语义相邻行；不丢焦点、不跳回首行、不落到无关控件；朗读行与屏上一致 | 录屏 + 滚动前后 dump | 焦点保持 + 行文本对应；丢失/漂移 = FAIL |
| T1 | 读屏关闭态 | 关读屏 → 常规触摸（按钮/输入/滚动） | 行为与无读屏一致；provider 仍 `status=1`；无残留焦点框 | 录屏 + 自检截图 | 操作全部正常、不崩；状态行不变 |
| T2 | 读屏开启态 | 开读屏 → 遍历 E1–S1 控件 → 双击激活 → 关读屏 | 可聚焦、朗读角色+文本+状态；双击激活；关闭后恢复 T1 行为 | 两段录屏（开/关） | 两态切换无崩溃/卡死；覆盖 E1–S1 |

**动作面（发布契约）**：只发布并执行 Click（button/text/checkBox/switch/textInput）、ScrollForward/Backward（scroll/slider）、Copy/Paste/Cut/SelectText（textInput）；SET_TEXT/LONG_CLICK 未发布（监听器无值载荷、切片无长按路径）→ 读屏不出现这两类动作属预期。

## 手动采集（无 `--a11y-probe` 时）

```sh
hdc shell hilog -r; hdc hilog > hilog-all.txt &        # 采集窗口内完成操作后停止
hdc shell uitest dumpLayout -p /data/local/tmp/a11y.json && hdc file recv /data/local/tmp/a11y.json .
# dump 中 text=A11Y 节点的 bounds 中心即按钮坐标（左下角 44x24）：
hdc shell uitest uiInput click <x> <y>                 # 打开自检弹窗后再 dump 一次读弹窗 text
```

| 关键字（`grep -E`） | 含义 |
|---|---|
| `accessibility provider status=` | provider 附着：0 未附着（启动初值属预期）/ 1 已附着（理想）/ 2 frame node 被拒 / 3 CUSTOM 未创建 / 4 provider 拒绝 |
| `accessibilityStatus\|accessibilityNodeCount` | 自检弹窗读数（第二次 dumpLayout 的 text） |
| `\[openharmony-host\] accessibility` | 宿主附着/公告告警（`provider attached` / `announce …` / NodeContent 重建） |
| `screen reader announce fell back` | Announce 走旧宿主回退路径（文本仍记录） |

**已知边界（登记、不判失败）**：Image/自绘模态/Announce 在 kit #30/#31 无 UI 入口；网页 DOM 内文本不发布；读屏对 progress `0..1`（不缩放到 0..100）、slider 用自身 min/max/value。
