# INTERP-FRAME：解释器路径「存活不出首帧」的断点（2026-10-03）

> 输入：KIT41-LOCAL-VERIFY §5（rc.2 interp pack 装/启 OK、存活、0 cppcrash，canvas=0）。结论：断点在托管运行时启动前——`coreclr_initialize` 装载 `System.Private.CoreLib.dll` 失败（0x800701E7），宿主 app 线程退出；ArkUI 壳存活 →「进程在、窗口在、画不出」。证据 `/data/storage/el2/base/tmp/opencode/interp-frame/`；设备 HAD-W32 / 7.0.0.111 / `127.0.0.1:35111`。

## 1. 启动序（host stderr → `<filesDir>/dotnet-status.txt` → 壳轮询 hilog `[maui] status:`）

fresh 装 kit 线 interp HAP（`44ea0d46…`；内件 BuildID `bc5ff740…`/`ba83106b…` 与 rc2 pack 一致）：`probe 1=22 2=22 3=13 4=1` → `start_app aot=0` → `launching app thread` → `run_app entering`
→ `Failed to load System.Private.CoreLib.dll (error code 0x800701E7)` / `Attempt to access invalid address.` → `Failed to create CoreCLR, HRESULT: 0x800701E7` → `run_app exited: -2147450743`；pid `#FOREGROUND` 存活、`canvas presented`=0。`managed started`/MAUI init/surface/canvas 均未到达。

## 2. 判定：HAP 域无可用可执行内存，纯解释绕不开

interp=3 已跳过屏障拷贝，CoreLib 装载是本进程**第一个**取可执行页处：CoreLib 有可写 `.data` → `PEImageLayout::LoadConverted` → `FlatImageLayout::LoadImageByCopyingParts`（`vm/peimagelayout.cpp:933-952,992`）把 `.text` 以 `PAGE_EXECUTE_READWRITE` 提交 → PAL `VirtualProtect` mprotect EINVAL
→ `ERROR_INVALID_ADDRESS`(487)=0x800701E7（`pal/src/map/virtual.cpp:1261-1263`；`appdomain.cpp:1121`）。scratch 探针宿主实测：`1=22` anon RWX、`2=22` anon RW→RX、`7=22` anon RW→RWX 全 EINVAL；`3=13` memfd RX、`5=13` bundle 内 CoreLib.dll RX、`6=13` 同文件 MAP_FIXED 全 EACCES；`4=1` 临时文件 RX EPERM。
文件映射路 EACCES 失败后回退拷贝路，拷贝路 RWX 又 EINVAL；解释器 precode 的 exec stub 堆是同墙第二段（未到达）。

## 3. AOT 对照（同镜像、同宿主）

AOT 件 `a4ece296…`：`aot dlopen now=ok`（不经 `coreclr_initialize`）→ 状态到 `window created` → 25 s 窗口 `canvas presented` **529**、pid FOREGROUND。差异只在 CoreCLR 需要动态可执行页。

## 4. 精确缺口 + 最小复现

缺口 = HAP 域拒绝全部 exec 内存策略（探针 7 项）；CoreCLR（JIT 或 interp）在 `LoadBaseSystemClasses` 必取 RWX/RX 执行页，interp=3 只把首崩从 `InitThreadManager` 移到 CoreLib 装载。平台至少需放开其一（anon RX / memfd W^X / 带签名 PE 的 RX 映射）。
复现：装 kit 线 interp HAP、启动、读壳轮询状态（§1 六行）；AOT 件同法得 `canvas presented`。

## 5. 记录更正（INTERP-FIX §4）

「15 s 411 行 `canvas presented`」是状态文件伪影：411 行同刻（23:35:23.367）由壳轮询输出上一轮（AOT）残留行；随后 3 次 interp 启动均为 0，与 KIT41 §5 final 快照一致。

## 6. 提交 / 不确定

- runtime-ohos `feature/openharmony`：本报告 + kit41 §5、interp-fix §4 更正（`commit-paths.sh`，未强推）。
- 不确定：`interp.txt=1|2` 差分未跑（需壳写沙箱）；payload PE 标为可执行（mode/label）能否解锁文件映射路未验证；探针宿主仅 scratch，未提交，发布宿主契约（`8d67def3`）未变。
