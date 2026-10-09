# BATCH-CONSOLIDATE：E4 · L3/L4 · WebAuth · SEC-SCAN-5c E/F · N-SUBWINDOW 批合并（2026-10-09）

> 口径：ow `master` ← cut-kit-2 → E4 → L3/L4 → WebAuth → L5 → L7（逐支 `--no-ff`，合并 `15f3dc8`）＋默认 8（`adf2efb`）＋唯一一次 abc 重编（`bd25907`）＋8 槽 drill pin（`a3f9e10`）＋pin（`ab43ba2`）；maui `feature/openharmony` ← L5 → WebAuth → L7（合并 `4fa0170900`）；普通推送、未强推；不切 kit（#54 待 rc.2）；#49–#53 资产零改动。

## 1) 合并 SHA

- ow：cut-kit-2 `3773c64`→`ee8971a` · E4 `30a8651`→`970e68b` · L3/L4 `e6e4f41`→`2b69bc5` · WebAuth `b49ea76`→`cd73bc7` · L5 `95e4a68`→`d4af2ab` · L7 `343fc21`→`15f3dc8`。
- maui：L5 `6f278ee99b`→`165d7fb273` · WebAuth `2803e15b6c`→`8185fb4f7f` · L7 `8b6d4073cb`→`4fa0170900`。

## 2) 冲突与解法

- WebAuth（基 `ca94b55` 较旧）：4 包 `modules.ui.abc`（二进制）＋4 包 `abc-provenance.json` 取 ours 占位、重编后重生成；`Program.cs` 计数行取 theirs 注释＋E4/C5 段，值 `752＝744+8`。
- L7：4 abc/4 provenance 取 ours 占位；`build-arkts-shell.sh` 6 块三契约并存（E4 slot-capacity ＋ C5 loadData ＋ SEC7-F ask-rate ＋ N-SUBWINDOW）；`selftest-build-arkts-shell.sh` 两组红控件串接；`verify-kit.sh`/`selftest-verify-kit.sh` 取 ours 占位后重锚；`Program.cs` 终值 **759**。
- 四包 `Index.ets`/`SubWindow.ets` 文本自动合并（E4 派生表＋C5/SEC7-F＋Want 对象字面量＋SUB_WINDOW 开关）；四包逐字节一致、`--check-sources` 过。

## 3) 默认 8 翻转 + abc/EXPECT（一次重编）

- 翻转：`src/Microsoft.OpenHarmony.Hosting/OpenHarmonyOverlays.cs` `DefaultMaxOverlays` 4→8；四包 `WEB_SLOT_DEFAULT_MAX` 4→8（`OHOS_OVERLAY_MAX`/`ohos-overlay-max.txt` 仍可下调；`build-arkts-shell.sh` gate 字面与套件 pin 随动）。
- 重编一次：ui **552,876 / `94f4e1f3…`**（原 550,304）、headless **24,324 / `798b2477…`**（不变）；`--install-packs`（.22/.23/.24）＋ .28 同步；`EXPECT_ABC=552876,24324`；`selftest-verify-kit` **129/0**。
- 套件 pin 随动：multi-ovl 池 drill 取 0–7＋溢出（`s8` 越界、`s7` 有效边界）。

## 4) 门禁（合并树）

- 套件 **756/759 floor 739**（declared==printed−3 平台跳过、0 Unhandled、perf within）；pixel `PIXEL ASSERTIONS PASSED`（host fallback，csc 宿主抖动）。
- preflight **OK 5/5**：repo gates（ridgraph 20 / packs 25 / hap-targets 85 / tasks 9 / hygiene 25 / host 84+26+47 / cut-kit 52）；sh -n 54；lint 0；导出 **164/164**；`selftest-build-arkts-shell` **207/0**。
- CI 5/5 @ `ab43ba2`：interaction `37902106137` / pixel `37902106134` / host-export `37902106191` / ridgraph `37902106143` / markdownlint `37902106196`（全 success）。
- 第 6 workflow `harmony-flavor` 本轮因触达 paths 过滤而运行、红：自 2026-10-05 即红（`freeWindowModeChange`/`isInFreeWindowMode` 对 HarmonyOS 6.0.1 SDK 声明不可用；旧运行 `37299622898` 同错）——MULTIWINDOW-S 起的既存问题，非本轮回归，亦不在 5 门禁口径内；修它需再动壳源码＝第二次重编，本轮不做。

## 5) pin / 状态

- 三 workflow `MAUI_OHOS_REF`（默认+env）→ `4fa017090076b510bdea97a6cd77df57446d1577`，注释同步（756/759 floor 739、164/164、552,876）；pin 提交 ow `ab43ba2`。
- **#54 待切**（等 rc.2：`bump-tester-docs.sh --kit 54` 波次后 `cut-kit.sh --kit 54`）；本轮不切、#49–#53 资产不动。
- 不确定项：pixel 走 host fallback（宿主 csc 抖动，非合并内容，CI Linux 无此现象）；preflight 明细 `cut-kit:0` 为计数显示（新脚本 PASS 无方括号，实测 52/52）；本轮无真机轮（E4 8 槽 soak 证据沿用）；L7 默认维持 2（M1 未决/M2/M3 未开，不据此抬默认）。
