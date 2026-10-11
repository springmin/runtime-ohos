# SUBWINDOW-DEFAULT4：managed 子窗默认 2→4（2026-10-11）

> 载体：ow `feat/subwindow-default4` `5c6289a`（自 `04d1606`）+ maui `feat/subwindow-default4`
> `144b5b6a09`（自 `54631780a3`），均已推 origin。只推分支、不并 master、不刷 tester docs（供最终
> 协调步一次重刷）；#49–#53 资产未动。

## 1. 改动（常量/开关）
- 壳四包（22/23/24/28）`SUB_WINDOW_DEFAULT_MAX: 2→4`；`applySubWindowLimit` 两向（`!==`）+ 非正数
  守卫（`requested<=0` 保持默认）；env/rawfile 开关仍可下调 2 / 上调 8。gate marker=4+守卫+两向。
- maui `DefaultMaxManagedSubWindows 4` + 新 `MinManagedSubWindows 2`（`Clamp [2,8]`）；样例默认 4 + `Min 2`。

## 2. 离线门禁
- 套件 pins 默认=4 + 行为（第 3/4 窗服务、第 5 窗 `NotSupported`）→ **790/793 floor 773**；红控（默认=2
  重编译）：`third/fourth served`、`capacity declines fifth`、`cleanup`、`slice source`、`n-subwindow
  switch` 6 断言 False（RC=134），还原复绿。arkts selftest **207/0**；`--check-sources`/`--check-pack-abc`
  绿；`selftest-verify-kit` **129/0**（EXPECT 重锚 602796）；gate 红控（默认改回 2）rc=1 点名 marker。
- abc 实测（同机归因：改前源逐字节重现 `d32981e6`）：ui **602796 / `e0e20130`**（+52B）、headless
  24324 / `798b2477` 不变；四包同值（28 由 24 复制）。**供最终协调步一次重刷。**

## 3. 真机（HAD-W32；锁协议；证据 `sw-default4/device/ev/`）
- 默认路径（无 rawfile/env）：open #1–4 → WMS `subs=1/2/3/4`；`subwindow created` 4 行 +
  `identity confirmed` 4（`sub-1..4`）；**0 容量覆盖日志**。主窗零回归：`framestats main n=300
  fps=60.0 avg=16.7ms max=19.0ms long=0 longruns=0`（sub-1 58.8）；宿主 `canvas presented` 主/四子窗出线。
- 槽释放/复用：close → `subs=3` + `remaining=3`；重开 → `subs=4` 复用 `sub-4`；fault diff=0（40 min soak
  引用 M2 双窗结局，不重跑）。

## 4. 不确定项
- `uitest` 强制点击相位 0 重绘（初始/空闲相位已出线）；最终协调步一次重编重刷 tester-docs/kit。
- 2in1 debug 域（E1）与既有降级卡片照旧；本文件 + `README.md` 索引 → runtime `commit-paths`（不 force）。
