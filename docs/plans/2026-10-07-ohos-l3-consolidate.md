# L3-CONSOLIDATE：三线（a11y 清理 + 资产桥 + M1 多子窗）并入主线 / 门禁 / pin / CI（2026-10-07）

> 口径：三线**一次并存整合**——ow `master` ← `l3/a11y-cleanup` @ `19e8cb7` + `l3/web-assets` @ `fc186bf` +
> `l3/multi-subwindow` @ `ec0a6e4`（merge `f2ff017`/`eac789f`/`5488b41`）；maui `feature/openharmony` ←
> `70b279548a`/`4b9598d9f3`/`fd7451adbf`（merge `3c3ba9f108`/`31794d884d`/`d1d485bb67`）；均 merge commit、
> 普通推送、未强推。**不切 kit（#52 待切）、#49/#50/#51 资产不动**。

## 1) 合并（SubWindow.ets/packs 一次共存重建）

- ow `696ebc0` → `f2ff017`（a11y，导出 163→**164**）→ `eac789f`（web-assets：子窗 hybrid/Blazor 资产桥 +3 checks；
  `Program.cs` 导出 pin 冲突解析 = 桥标记 + `l2ExportCount==164`）→ `5488b41`（multi：N=2 会话表 +11 checks；
  4×`SubWindow.ets`/`Index.ets` 自动并存，packs abc/provenance 冲突取一后重装）。
- maui `bb6b06990d` → `3c3ba9f108`/`31794d884d`/`d1d485bb67`（三支文件互不重叠，全部自动合并）。
- 合并树重编：ui abc **512,304 / `eae87765…`**（508,832 与 476,516 并存产物）、headless **24,324（`798b2477…`）** 不变；
  `--install-packs`（.22/.23/.24）+ **.28 手动同步**，四包 abc/provenance/源逐字节一致（`--check-sources`/`--check-pack-abc` 绿）；ow `cf2c9d2`。
- `verify-kit` EXPECT_ABC `476,516/508,832 → 512,304`（`selftest-verify-kit` ABC_SIZE 同步；实测重锚）；ow `3a16d3c`。

## 2) 门禁

- 套件 `[suite] checks=701 total=704 floor=684 assert=True`（declared==printed、0 Unhandled、perf 全 within；超集 = 690 + web 3 + M1 11）。
- 红控（合并树）：去 `ohos_host_accessibility_release_for` → `m4 a11y provider source pins assert=False`；`SUB_WINDOW_MAX 2→1`
  → `m1 shell source assert=False`（各 exit 134）；还原复绿 `701/704`。
- host 三件：DT_NEEDED/UND 过、**导出 164/164**；`check-host-exports.py --cross-check` 164/164；registry 84 / bridge 26 /
  a11y-table 47 selftest 全绿。
- preflight：gates + interaction + pixel 全 PASS、markdownlint 0 issue（首轮 csc SIGSEGV 139，重跑绿）。

## 3) 真机 N=2 抽验（HAD-W32；锁协议，已释放）

- 合并树 JIT hap（宿主 87,040 + host .so 347,040 + abc 512,304；本机 workload 包同步）。**windows=2**：WMS 双
  subwindow（sub-1 id 2620 / sub-2 id 2622，720×480 级联）+ 宿主 `registered ... windows=2` + 双 a11y provider
  status=1 + 两窗 `first frame=True`。
- **输入分窗**：sub-2 点击 → `child taps: 1`；sub-1 点击 ×2 → `child taps: 2`（互不串）。
- **定向关**：`close` → `event Closed: surface=sub-2`、WMS 仅留 sub-1；**重开** → 新会话 id 2623 +
  `open(managed) children=2 result=OpenedWindow`。
- **主窗零回归**：主窗会话 2619 常驻、`framestats main` 全程 59.6–60.0 fps、pid 不变；噪音 = 焦点切换
  `subwindow blur failed` E×3（平台组件时序，闭环不受影响）。

## 4) pin / CI

- 三 workflow pin `bb6b06990d… → d1d485bb67…`（注释：套件 701/704 floor 684、导出 164/164、abc 512,304）；ow `a551013`。
- CI 5/5 @ ow `a551013`：interaction `37582309965` / pixel `37582310008` / host-export `37582309986` /
  ridgraph `37582309980` / markdownlint `37582309960`（全 success）。
- 推送：ow `696ebc0..a551013`（a11y/web 支仅本地，随 master 落远端）、maui `bb6b06990d..d1d485bb67`；均普通推送、未强推。

## 5) 状态

- **L3 三线合并完成**（a11y 清理 + 资产桥 + M1 多子窗一次共存）；**#52 待切**（L3 载体；切包时重建 packs/abc/
  provenance 并按 `verify-kit` 锚定）；#49/#50/#51 资产未动。
- 余项 = 子窗 B6 导航否决、多子窗同槽 hybrid invoke fail-closed（产品级 N=1）、L3-M2–M4（每窗握手/IME/a11y/
  overlay/child web 按窗）未开工、子窗 a11y 动作 e2e 平台限。
