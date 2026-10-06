# L2CAP：平台级多子窗上限探针（2026-10-06）

> 承接 `2026-10-06-ohos-multiwindow-l2-options-analysis.md` §c：只关问题票、不入产品。
> 探针 = scratch `mw-l/l2cap/`（纯 ArkTS 应用 `com.example.l2cap`，独立 bundle；产品代码/资产零变更，
> #49/#50 未动）。设备 HAD-W32 / OpenHarmony-7.0.0.109 / API 26 / 2in1；锁 `mkdir .device-lock`
> （5 min 退避、≤90 min、轮末释放；轮内 MAUI 进程临时停靠、轮末拉起，签名 hap 不替换）。
> 件：签名 hap `ae989059…`；证据 tar `l2cap-evidence-20261006.tar.gz` / `e3e761d7…`（9.3 MB）。

## 方法

- 探针页自动 3 轮：`window.createSubWindowWithOptions`（decor=false、200×140、唯一名）→
  `setUIContent('pages/Child')` → `showWindow()` 逐次递增（上限 256）直至首次失败；失败后 CONFIRM×2 +
  1.5 s 退避 RECHECK（判瞬态/持久）；峰值持 8 s；`destroy` 全部；静置 5 s 后 RECOVER 单窗（可恢复性）。
  全程 hilog tag `L2CAP`（tick 心跳证明 UI 线程活性）。
- 宿主 `device-round.sh`：每 2 s 采 VmRSS/Threads/`hidumper -p --fd`；每峰值抓 WMS dump + 截图；
  轮前/轮后 fault diff；卸载后 WMS `l2cap_` 残留计数；hilog 缓冲提升 + 快照去重（防环回丢行）。

## 结果（run-20261006-225401，设备 22:54–22:58；另有两次全跑对齐）

| 轮 | 成功 N | 首个失败（=N+1） | CONFIRM×2/RECHECK | destroy | RECOVER |
|---|---|---|---|---|---|
| 1 | **255** | CREATE 256 `1300002` | 全失败（同码） | 255/255 | OK |
| 2 | **255** | 同上 | 全失败（同码） | 255/255 | OK |
| 3 | **255** | 同上 | 全失败（同码） | 255/255 | OK |

- 失败原文：`code=1300002 msg="This window state is abnormal.[window][createSubWindowWithOptions]msg: Create sub window failed."`
  （3 轮一致；1.5 s 退避与三次重试仍失败 ⇒ 非瞬态）；`ALL DONE r1=255 r2=255 r3=255`（截图同证）。
- WMS：峰值 dump `l2cap_*` 窗行 255（多峰复现；另一次全跑 run-…-224908 同值）；force-stop + 卸载后 0 行、`probe_pid` 空。
- 资源（255 窗峰值 → 空载）：fd `58 → 327`、threads `26 → 38`、VmRSS `104 → 364 MB`；destroy 后回落。
- 稳健：probe fault=0（`no records found.`）；MAUI fault 行 72/72 不变；64 上限预轮（run-…-224302）64/64 全成功。

## 判据与结论

- **平台级上限 = 255 个并发应用子窗**：第 256 个 `create` 稳定失败。255 子窗 + 1 主窗 = 256 窗/应用，
  疑为「256 窗/应用」硬限（未获源码常量，按观测口径记录）。⇒ **应用级 N=1 是壳契约而非平台限制**；
  多 managed 子窗平台可行，产品化按 §c 另行立项（本次不动壳单实例/801 契约）。
- **无泄漏/残留**：destroy 255/255 全 resolve；卸载后 WMS `l2cap_`=0、fault 不新增、进程回收。
- **失败可恢复**：上限拒绝后 destroy 全部 → 新窗 `RECOVER OK`；3 轮不衰减。
- 边界：2in1 debug 域、单机型（HAD-W32 7.0.0.109）结论；255 为探针观测上限（`1300002` 为通用窗状态
  错误，非专用超限码）；不外推手机/release。
