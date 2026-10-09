# L8 探针：ArkWeb `onWindowNew` → 跨窗 `setWebController`（真机，2026-10-09）

> 口径：纯壳侧探针（托管包未启动、零托管/宿主/导出改动）；HAD-W32 / OH 7.0.0.109 / API26 / 2in1（UDID `1BCE13C8…`）；`.device-lock` 互斥 6 轮、轮末卸载/512K 还原/释放；一次一构建。件 = ow `feat/l8-popup-probe` `19b02da`（四包 preview.22/23/24/28 换探针页，**不并 master**）；探针 abc 38,156 B 仅 scratch（#49–#53 资产未动）。证据 scratch `/data/storage/el2/base/tmp/opencode/l8-probe/`（`l8-probe-round{1..6}.sh`、`device*/`、`repack-5/`、`logs/`）。

## 判据（真机逐条）

| # | 判据 | 结果 | 证据（scratch 相对路径） |
|---|---|---|---|
| ① | 弹窗内容在第二窗渲染（非主窗内嵌） | **PASS** | WMS 独立窗 `l8_probe_popup`（winid 3120/3122–3132）；`device6/{s1,s2,s3}.jpeg`（`L8 POPUP GOT PING-s1`、`L8 POPUP WRITE`、`name=l8pop_s3 ?mode=s3`）；`uitest dumpLayout -w <win>` rootWebArea=1 |
| ② | opener→popup `postMessage` / `name` | **PASS** | 三形态 PING→`L8POP MSG`→`PONG`→主窗 `MSG-FROM-POPUP`（双向）；`window.name=l8pop_s*`；同名重开=内核复用已绑定子窗并原地导航（无新窗、同 winid），**`onActivateContent` 未触发**（子窗前台） |
| ③ | popup `window.close()` 关窗、主窗不受扰 | **PASS** | 3×`onWindowExit`→模块桥回调→`destroyWindow`→`child destroyed`+`subwindow event 7`；关窗后主窗 HB 连续、0 fault |
| ④ | 不接管阻塞对照 | **PASS** | `none`：HB 停于 STEP none、`CONTROL-OPEN-RETURNED` 无（renderer 阻塞）；`null`：`setWebController(null)` 无阻塞、`window.open` 返回 null；异步绑定=返回 null 且不投递内容（无阻塞半态） |
| ⑤ | controller 跨页/跨模块传递可行形态 | 结论 | **可行**：主窗在 `onWindowNew` 内同步 new+bind，同一对象经页模块静态导入（`import { L8Bridge } from './SubWindow'`）交子窗页；**不可行**：窗口 `LocalStorage`（named-route 页读回空→弹窗空白+阻塞，round1）与 attach 后回传（`window.open` 返回 null，round2） |

## A1 结论（探针级）

- **跨窗绑定成立，A1 可行**；产品化必须按序：`onWindowNew` **零 await** 同步 `new WebviewController()` → `handler.setWebController(controller)` → 再异步建子窗/载弹窗页；controller 走壳内共享模块（Index↔SubWindow），**勿用 loadContentByName LocalStorage**。
- 拟真快照 = round6 对齐轮 `device6/{s1,s2,s3}.jpeg` + `*-wms.txt`；失败链 = round1 `device/`（LocalStorage 空/空白窗）、round2 `device2/`（`OPEN-RETURN null`+`createSubWindow ... created again`）。
- 未定项：`onActivateContent` 触发条件与同名重开语义（前台不触发）需产品化按需处理；`isAlert`/tab-vs-popup 未映射；弹窗 IME/焦点回主窗与容量占用（`SUB_WINDOW_MAX`）留给 A1 产品真机轮。

## 给 L7-M2 的接口建议

- 弹窗会话并入 L7 同一注册表/容量（`SUB_WINDOW_MAX`，勿立第二上限）；键建议 `web:N` 命名空间 + `kind=popup`，**不接入** managed 身份握手/child web sink。
- 壳直管弹窗页（SubWindow popup 模式或新页）职责最小集：消费共享模块 controller、`multiWindowAccess(false)`、`onWindowExit`→关窗+回调、`onActivateContent`→尽力置前（不依赖）；容量满/失败一律 `setWebController(null)` + 日志，**禁留不绑**（阻塞）。
- 导航/安全按 B6 口径（不注入 dotnetHost、URL/协议白名单）；`window.close` 后的 WMS 残留/同名重开在 A1 产品轮复验（探针轮 3/3 关窗干净）。

> 提交：本文件 + `README.md` 索引 → runtime `feature/openharmony`（`commit-paths.sh` 限路径；直推、被拒 fetch/rebase + 旁路钉 `140.82.112.3`，不 force）。原文级证据存 scratch 不入库。
