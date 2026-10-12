# MAUI-KEYBOARD-CHECK：注入路径复核 + 物理键盘捕获就绪（2026-10-12）

> 设备 HAD-W32 / OH debug 域（hdc 127.0.0.1:36823）；锁独占（捕获脚本持 owner `maui-kbd-capture`）；应用 = 设备现状
> `com.example.hellomauiapp`（未重装、未改产品代码）；证据 scratch `mkbd/`。触发：用户报"PC 键盘输入已好" → 复核 MAUI 键盘输入。

## 1. 路径矩阵（可达 = 隐藏输入 `sub-1__input` 文本变化 → onChange → 托管 Entry.TextChanged）

| 路径 | 结果 | 关键证据 |
|---|---|---|
| `uitest uiInput inputText <x> <y> <t>` | **可达**（逐字符注入 key 事件） | `InjectKeyEventSequence keycode:2017`；+SPACE 后输入文本 `seed`→`seed鹌鹑蛋你好`（04/05 截图） |
| `uitest uiInput text <t>` | **可达**（同上，`No Error`） | `keycode:2019`；同链 |
| `uitest uiInput keyEvent <kc>` | **可达**（逐键；SHIFT=2047 切 Zh/En） | `isSingleShiftKeyUp`→`InputEnLowerService`；英文直提（09 截图） |
| `uinput -K -t <t>` / `-d <kc>` `-u <kc>` | **可达**（内核虚拟键盘，IME 硬件通路） | `-t xyz`+SPACE→`下一站`；`-d/-u 2017/2018`+SPACE→`安保`（05 截图） |
| 纯字母、无提交键（中文态） | 不落文本（仅组合+候选日志） | 上轮"只动 caret/无文本事件"= 未提交的组合态，非通路断 |
| ENTER（2054） | 提交组合文本（`…你好ab`） | 未观测 TextSubmitted→Completed（子窗 Entry 无 Completed；label 末事件=TextComposition）——边界 |
| 软键盘 | 未触发（2in1+物理键盘，IME `isSoftKeyboardShow:false`） | 聚焦后无键盘窗；注入仍走硬件通路 |

## 2. 结论与证据

- **注入可观测文本事件**：落点 = IME 提交（中文 SPACE 选词 / ENTER，或 Shift 切英文直提）→ 壳隐藏输入 onChange →
  `notifyTextInput`/`SUB_EVENT_TEXT` → 托管 Entry；上轮"文本实敲仍人工卡"修正为"注入需提交键或英文态"。
- 托管自绘 UI 证实：子窗 Entry 与 `child entry:` 标签 = `seed鹌鹑蛋你好ab下一站安保test`（04/05/09 截图）；
  焦点链 `text input focused` + `text focus forwarded`（10:54/11:10 两轮）。
- 边界：`dotnet-status.txt` 600 权限（hdc 不可读）；壳启动镜像只回放末 60 行（framestats 洪泛）→ 托管状态
  文件取不到，证据以自绘 UI + 隐藏输入文本 + hilog 为准。
- 物理键盘 = 同一 IME 硬件通路（`uinput` 即虚拟物理键盘），预期同结果；实键入捕获已武装（§3）。

## 3. 人工步骤（进行中）

- 应用在设备前台、子窗 Entry 已聚焦（`sub-1__input focused=true text='seed'`；重聚焦 = 点 (458,358)）；物理
  键盘直接键入（中文态按 SPACE 提交；或先按一次 SHIFT 切英文直提）。
- 捕获（11:11 武装，45 min → ~11:56 自动结束）：`mkbd/kbd-capture.sh`；日志 `kbd-capture.log` + `kbd-capture-hilog.log`
  + `hit-*.{json,jpeg}` + `shots/`；读结果 = INPUT-CHANGE 行 + `hit-*.jpeg` + hilog `OHOS_MAUI_SUB`/IME 行；结束自动还原 hilog 512K + 释放锁。
- 并发会话备注：取锁时 Flectar Mail（另一实测）在前台；本轮已置 MAUI 前台等待键入，如需先测 mail 由主会
  话切换。

## 3b. 实体键入结果（2026-10-12 11:23–11:25，用户实操）

- 子窗 Entry 聚焦（系统焦点窗 775 `ohos_dotnet_subwindo`）下实体键盘直敲 → `sub-1__input` 连续 INPUT-CHANGE：
  `seed` → `seedjjj78`（11:23:19/11:23:40）→ `seedjjj7800`（11:23:51）；证据 `hit-1123{18,29,39,50}.{json,jpeg}`。
- **结论：MAUI 键盘输入 = OK**（物理键盘 → IME 硬件通路 → 隐藏输入 onChange → 托管 Entry；与 §1 注入矩阵一致）。
- 11:25:28 后 inputs 清空（窗口状态变化）；捕获按计划 ~11:56 自动收尾并还原（hilog 512K + 释放锁）。
- 备注：`ENTER` 提交未观测 `TextSubmitted→Completed`（子窗无 Completed 处理器）——保留边界，下批可补。

## 4. 文档 / 提交

- 本文件 + `docs/plans/README.md` 索引行 → runtime `commit-paths.sh`（限路径；直推，被拒 fetch/rebase）。
- 设备保持"等待键入"状态（不卸载、不杀应用）；45 min 内无人键入则由捕获脚本自动还原。
