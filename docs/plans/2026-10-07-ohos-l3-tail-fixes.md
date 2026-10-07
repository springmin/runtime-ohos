# L3-TAIL-FIXES：a11y 分区清理 + 子窗 hybrid/Blazor 资产桥（2026-10-07）

> 口径：两线均从 ow `master` `696ebc0` / maui `feature/openharmony` `bb6b06990d` 切出；**未并 master、未强推、#49/#50/#51 资产不动**。
> 分支：ow `l3/a11y-cleanup` @ `19e8cb7`、`l3/web-assets` @ `fc186bf`；maui `l3/a11y-cleanup` @ `70b279548a`、`l3/web-assets` @ `4b9598d9f3`（均本地分支；推送时远端不可达，无强推）。

## ① a11y 分区清理（ow + maui，小）——SEC6-C 余留闭环

- 修复：`host_a11y_table.c` 新增 `ohos_host_accessibility_table_release`（表锁内摘链并释放节点串/数组），`host_napi.cpp` 新增导出
  `ohos_host_accessibility_release_for`（导出 163→**164**）：释放该窗命名分区（8 槽 cap 归还）+ 重置 per-instance NAPI 注册态
  （provider/customNode/content=null、status=0；记录保留以维持 `A11yInstanceProviderFor` 的指针稳定，重开同 id 建新 CUSTOM 节点）。触发 = 既有窗关闭 hook
  `OpenHarmonyAccessibility.ReleaseWindow`（maui）→ `ReleaseProviderState`（探测新导出，旧宿主仅 managed 释放）。
- 测试：`selftest-host-a11y-table.sh` v2 `15/15` 绿（+3 用例：release 掉分区/lookups、主分区与未知/重复 no-op、槽位复用+cap 仍守）；
  **双红控**（instance 键忽略 11 FAIL；release no-op 1 FAIL）；host build **164/164**（DT_NEEDED/UND 过）；
  套件 **688/690 floor 670 assert=True**（导出 pin 与 a11y 源 pin 扩到 release，check 数不变）。
- 边界：SDK 无 provider unregister API；旧 CUSTOM 节点随被销毁的 NodeContent 走；同 id 重注册若被 ArkUI 拒则降级无 provider（managed 帧本地保留）。

## ② 子窗 hybrid/Blazor 资产桥（ow + maui，中）——原显式拒绝改为可服务

- 实现（壳 4 packs `SubWindow.ets`）：接受 `hybrid`/`blazor` 注册（按子槽存 base/root/defaultFile/doc-id；替换 `disableChildWebSlot`）；
  `onInterceptRequest` 服务 `https://0.0.0.1/`（含 `_framework/hybridwebview.js`）与 Blazor 源（含 wasm 模式），移植主窗路径守卫/指纹回退/MIME/缓存头/404；
  `dotnetHost` 代理（含调用帧守卫）+ `window.external` shim + Blazor bootstrap（`__dispatchMessageCallback`/`Blazor.start`）按子槽安装；
  `__hwvSendMessage` 走 `notifyJsMessage`+`__OHORIGIN` 信封（managed 按 doc-id 派发，无需新通道）。
- hybrid invoke 跨窗：请求 id 加 child 旗标 bit30（ow `OpenHarmonyOverlays.ChildInvokeFlag/Encode/TryDecodeChildInvokeRequestId`），maui
  `ChildHandlerForSlot` 按子池槽路由（多窗同槽 fail-closed）；host_napi 新增 NAPI `registerChildHybridInvokeResultSink`，`ohos_host_hwv_invoke_result`
  按旗标分流到子页 sink；主窗编码/导出（163）字节不变。
- 测试（离线红/绿）：套件 **691/693 floor 673 assert=True**（+3：codec、child dispatch 真 invoke `echo:child`、未领槽 fail-closed；shell/host/slice 源 pin 更新为桥标记）；
  host **163/163**；shell abc **508,832（`9952229b…`）/24,324** 四包一致、provenance 过、`verify-kit` EXPECT 473,048→**508,832** 重锚；
  红控：maui 去掉 child 分支 → `child invoke dispatch`/`miss` assert=False（`l3-web-red.log`，已还原复绿）。
- 边界/余项：子窗 B6 导航否决未接（外部导航直载）；多子窗同槽 hybrid invoke fail-closed（产品级 N=1）；**真机抽验未跑**（无现成 child+hybrid 样例 hap，
  设备锁空闲但需新样例 + hap 构建）；与并行 `l3-multi-subwindow` 的壳改动需一次并存合并重建；子窗 a11y 动作 e2e 仍平台限。

## 提交 / 文档

- ow `l3/a11y-cleanup` `76f4eb5`+`19e8cb7`；ow `l3/web-assets` `fc186bf`；maui `l3/a11y-cleanup` `70b279548a`、`l3/web-assets` `4b9598d9f3`（普通提交，无强推）。
- 本页 → runtime `feature/openharmony`（`commit-paths.sh` 限定本文件；fetch/rebase 被拒，旁路未推）。并行 `l3-multi-subwindow` 的未提交 README/计划稿未触碰。
- 不确定：设备域仅离线；红控 run 为离线套件，未含真机。
