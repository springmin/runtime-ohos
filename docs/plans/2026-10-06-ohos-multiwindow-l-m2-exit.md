# MULTIWINDOW-L M2-EXIT：22 checks 落地、ow 带窗桥、AOT 解阻（2026-10-06）

> 口径：M2 退出三项收口（验收矩阵 §2）；ow 分支 `l/m2-exit`（基于 `l/m1-window-registry`、pin maui M2 `1a15f56b30`）已推送；未并 master、未切 kit、未动 #49 资产、未用设备。证据 scratch `mw-l/m2exit-*`（不落库）。

## ① 22 checks 落地（`test/maui-platform-verify`）

- 新增 22 行：scratch 双窗 20 断言（单面降级 → pending → 绑定 → 独立帧/尺寸/触摸 → 关窗存活 → 同 id 重建）+ 桥 id/空 id 丢弃 + 晚期订阅 replay；每窗各一台 `CanvasFactory` 录制画布。
- 运行：`[suite] checks=629 total=631 floor=611 assert=True`、0 Unhandled（607+22）；pixel 套件 `PIXEL ASSERTIONS PASSED`（43 PASS 基线不动）。
- pin：interaction/pixel/host-export 三 workflow 指 `1a15f56b308c4e45889fe425ed384ed7697ee11a`（仅本 L 分支；master 仍 `b093e33825`）。红控：换回 pre-M2 切片（`b093e33825` archive）编译即红（`RouteSurface/RouteTouch/RouteFrame/FindSecondaryWindow/…` CS1061/CS0246，`m2exit-redcontrol-build3-1.log`）。
- 提交：ow `650ce12`（test）+ `896f4e3`（ci）。

## ② ow 带窗桥 + per-window canvas

- 新纯 C 模块 `host_window_bridge.c`：注册回调 + `ohos_host_set_window_native_window` / `ohos_host_notify_window_touch` / `_frame`（带 M1 注册表 id；主窗同带 `main`，legacy untagged 路径未动）；`host_napi.cpp` 三处回调接入（surface/touch/frame）。
- hosting：`OpenHarmonyBridge.WindowSurfaceChanged/WindowTouch/WindowFrame`（surface 带 per-id replay、空 id 丢弃）；新 DllImport `ohos_host_register_window_bridge` → `host-exports.txt` / `check-host-exports.py SOURCES`（154/154）；新 selftest `selftest-host-window-bridge.sh`（12 checks，接入 preflight）。
- 数据集接口：以 id 调切片 `RouteSurface/RouteTouch/RouteFrame`（测试内订阅 tagged 事件转发）；per-window canvas 走各窗 renderer 的 `CanvasFactory`。
- 主机三门禁：`build-host.sh`（DT_NEEDED 白名单 / UND 黑名单 / 154 导出）全过。
- 提交：ow `c056f52`。

## ③ AOT publish 解阻（workload preview.28）

- 根因两步：① `~/.dotnet` 的 .24 manifest 把 ref pack 钉在 `1.0.0-preview.24`（无 `IOpenHarmonyOverlaySlotOwner`）；② `.feed` 的 .28 ref nupkg 是旧构建（hosting DLL 无该接口）。绕法 = `pack-local-workload.sh` 从工作树 `packs/` 重打 .28 feed + `dotnet workload install --skip-manifest-update`（manifest 已同步 .28，旧 manifest 备份 scratch），并按本机 rc.2 纪律 `DOTNET_PROCESSOR_COUNT=1`（csc livelock）+ scratch hooks（Exec/hap 本地替换，`m2exit-aot/aot-local-hooks.targets`）。
- 结果（`m2exit-aot/publish-aot.log`；ow 树 `df2a246`+工作树、maui `1a15f56b30`）：EXIT=0、0 error、IL2026/IL3050/IL3051=0；`runtime-mode.txt=aot` 且 probe 行 `runtime mode 'aot' written to libs/arm64-v8a/runtime-mode.txt`；hap 31,137,191 B、publish `libhello-maui-app.so` 19,405,584 B / `c471ee11…`。余下 warning 全为基线类（CS0618/NETSDK1188/CA2255/CS8604 + 第三方 IL3053/IL3000/IL2104）。

## pin 切换步骤（L 收口时）

1. L 栈（`l/m1-window-registry` → `l/m2-exit`）并入 ow master 后，取合并提交 SHA。
2. 改三 workflow 的 `MAUI_OHOS_REF` 默认值与 env、注释里的 `629/631 floor 611`、`154/154`；`1a15f56b30` 只作本 L 分支历史 pin。
3. 合并树重跑 interaction + pixel + host-export + preflight 复核后推送 master。

## 余项 / 不确定

- 真机轮未跑（M3 壳带 id 桥后才有意义）；hap 内 host 仍是 .28 pack 基线（301,984 B），M3 切包时需用 `l/m2-exit` 重编 .so。
- ② 的 managed 生产消费方（切片订阅 tagged 事件转发）按约定留 M3；本步交付桥事件 + 适配测试路径。
- workload 全局状态已切 .28（`~/.dotnet`，旧 manifest 备份 `m2exit-aot/sdk-manifests-11.0.100-rc.2-preview24-backup.tgz`）；红控为编译红。
