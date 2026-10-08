# L3-B6-MODES：⑤ N=2 JIT/interp 覆盖 + 子窗 B6 导航否决（2026-10-08）

> 口径：ow `l3/b6-nav-veto` @ `d25c0eb`（自 `0685d7b`）· maui `l3/b6-nav-veto` @ `b64c477f8e`（自 `277967cc56`）；
> **不并 master/feature、未强推**（两分支普通推送新分支）；#49–#52 资产不动。结论域 = 2in1 debug（E1）；设备 HAD-W32 @ `127.0.0.1:35111`。

## 1) 子窗 B6 导航否决（ow + maui）

- 壳 `SubWindow.ets`（四包字节一致；新 abc 542,936 / `f18f0855…`）：child ArkWeb 增加 `onLoadIntercept` 网关——
  app 来源、本槽 hybrid/blazor origin 与一次性放行标记直接放行；外部主帧导航取消并经子窗事件通道问 managed
  （`w:<surface>|s<slot>|navask|<id>`，URL 在事件 URL 槽）；managed `nav` 命令按 (slot,id,url) 精确回放一次；
  pending 有界（8/TTL 5s/URL 8KiB），槽销毁丢弃该槽 pending；程序化 `load` 标记与主窗同形。
- maui `OpenHarmonyWebViewHandler`：`HandleChildNavigationRequest` 与主 `__OHNAV` 同校验（绝对 http(s) 带 host、
  H-C2 拒网络路径/方案样式、控制字符/长度、未知窗口 fail-closed）、对 (window,slot) 的 handler 同步抛 `Navigating`
  （应用可否决）、批准键 `child|<win>|<slot>|<url>` 共享主表 cap/prune；child `started` 一次性消费批准（不二次抛）。
  主窗键/编码/行为不变（主 B6 既有 pin 全绿）。
- 离线：套件 **736/739 floor 719 assert=True**（+5 b6c：route+one-shot / cancel / fail-closed / window isolation / 源 pin）；
  红控 = 去掉 child 分派 → 3 行 assert=False、套件 Unhandled 退出 134（`suite-red.log`），还原复绿。
- 设备抽验（JIT hap，子窗 data: 页探针链接）：deny 链接 ask → 无 `nav` 命令/无批准（应用取消，载荷保留）；
  ok 链接 ask → managed `Navigating` → `child web cmd: nav s0\n<id>\n<url>` → 壳 `nav approved` → 重载 DNS 失败
  `child web error` → hide（完整 ask→approve→reload 子窗闭环）；`//host` 探针因桌面控制台抢占 z-order 未取得干净点击。

## 2) 真机 N=2 × JIT（06:46–07:28，独占锁）

- 件：B6 分支 JIT hap（abc 542,936/`f18f0855`、host 367,520/`ad7ab986`、libcoreclr 5791c298；hap
  134,726,055 B / `bb041159…`）安装 rc=0，冷启 pid=37362。
- 双窗 identity 双端 confirmed（sub-1 gen=1 id=2817 / sub-2 gen=2 id=2818）；a11y `status=1` ×2（selfcheck
  nodes=0 ×2 = 首发布时机，承 #52 降级）；两窗各自 data 文档（`CHILD-WEB-1/2`）、各自 capacity/slot create/attach、
  managed eval+tap 回读（`child web tap text='CHILD WEB TAP 1'`）；定向关→1 窗、重开→2 窗、pid 恒定、0 fault。
- 帧率：镜像窗 main/sub-1 均 **60.0 fps**（n=300/301、avg 16.7ms、long=0）。短稳 **25 采样**：RSS min 262,976 /
  max 344,252 / avg 279,711 kB（首 3 采样 338–344MB GC 锯齿 → 262–270MB 稳态）、线程 68–69、subs=2 全程、
  crash=0 全程、pid 首=末。

## 3) 真机 N=2 × interp（rc2b pack 叠加件）

- 件：release `ohos-interpreter-pack-rc2b.tar.gz` 2,410,595 B / `5974430509…`（libcoreclr e150558a… +
  libclrinterpreter 3e4b4d10…）叠加 JIT hap（runtime-mode.txt=interp）重签：71,976,357 B / `d84ba7f3…`，安装 rc=0。
- 冷启 pid=6453，首帧 `canvas presented (2090x1324)` + `[sub-1]/[sub-2] (720x480)`；双窗 identity ×4、a11y status=1 ×2、
  WMS=2、定向关/重开、pid 恒定、0 crash。抽验 **10 采样**（可缩短）：RSS 284,292–303,920 kB、线程 65–67、subs=2、
  crash=0。限制：宿主 `runtime-mode=interp`/`interp=3` 行落 `dotnet-status.txt` 状态镜像窗之外（未入 hilog）；
  件内 `runtime-mode.txt=interp` + `libclrinterpreter.so` 与运行首帧为运行侧证据。

## 4) 分支 / 文档 / 提交 / 不确定

- ow `l3/b6-nav-veto` `d25c0eb`（壳+abc+套件+样例探针+README）；maui `l3/b6-nav-veto` `b64c477f8e`；本文件 → runtime-ohos
  `feature/openharmony`（`commit-paths.sh` 限定路径）。均未并主线、未强推。
- **并入（2026-10-08，POST-L3-CONSOLIDATE）**：本卡并入主线（ow `96267f2`、maui `caa463434b`）；合并树套件 **737/740 floor 720**
  （`b6c` 5 条在案）、ui abc **542,936/`f18f0855…`** 四包一致、导出 164/164；见 `-l3-post-consolidate.md`。
- 不确定：子窗 fps/status 镜像窗限制（sub-2 与 managed 行）；`//host` 设备点击被桌面控制台抢占；selfcheck nodes=0
  为已知首发布时机；单设备 2in1 debug 域结论不外推。
