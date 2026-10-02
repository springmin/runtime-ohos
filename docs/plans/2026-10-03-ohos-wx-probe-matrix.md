# WX-PROBE：exec 内存墙全路线矩阵（2026-10-03）

> 设备 HAD-W32 / 7.0.0.111(SP3ENTC293E104R2P1log) / HongMeng Kernel 1.13.0 / API 26。工具：独立 `wxprobe`（hishell 域）+ 重打包 kit interp HAP 的 `libopenharmonyhost.so`（app 域，probe 在 CoreCLR 启动前运行）。证据（scratch，未提交）：`/data/storage/el2/base/tmp/opencode/wx-probe/`（源码 `wxprobe.c`；日志 `log/{hishell-matrix,app-inprocess-unlock,app-enabled-matrix,stock-a-run,stock-b-enabled,jit-enabled}.out`）。

## 1. 关键结论

- **app 域匿名 exec 是可自解的开关**：默认（JITFORT fortify）`anon RWX/RW→RX/RW→RWX` 全 `EINVAL(22)`；进程内 `prctl(0x6a6974, 0, 0)` 后 `/proc/self/xpm_region` 由 `0-0` 变 **4 GB 区间**，三条匿名路线立即 `OK|exec`，且后续 app 进程启动即 `1=OK 2=OK`。
- **A/B 因果（stock interp HAP，无 prctl 代码）**：`jitfort(0,1)` → 下一 app `probe 1=22 2=22` + CoreLib `0x800701E7` 失败；`jitfort(0,0)` → `1=OK 2=OK` + CoreLib 装载成功（`Failed to load`=0）。
- **文件/共享内存路所有域恒拒**（13/1）：memfd 双映射（W^X 合规形态）不可行；`MFD_EXEC`/`MFD_NOEXEC_SEAL`/`MAP_XPM` 内核直接 `EINVAL`。**`DOTNET_EnableWriteXorExecute=0` 仍是唯一运行形态**。

## 2. 路线矩阵（errno；`OK+exec` = 写入 stub 并真实执行返回 42）

| 路线 | app 默认(fortify) | app prctl(0,0) 后 | hishell_hap | hdc sh(uid2000) |
|---|---|---|---|---|
| anon RWX / RW→RX / RW→RWX | 22（进程内 prctl 后 OK+exec） | OK+exec | OK+exec | 无法执行探针¹ |
| memfd create + seal-add | OK | OK | OK | ¹ |
| memfd RW→RX / 双映射 RX / seal→RX / seal+双映射 | 13 / 13 / 1 / 13 | 同 | 同 | ¹ |
| MFD_EXEC / MFD_NOEXEC_SEAL / MAP_XPM(0x40) mmap | 22 | 22 | 22 | ¹ |
| 签名 .so RX（shared/private、RW→RX）；/system lib RX | 13 | 13 | 13 | ¹ |
| tmpfile RX / posix-shm / sysv-shm / ashmem RX | 1 / 13 / 13 / 13 | 同 | 13 / 13 / 13 / 13 | ¹ |
| pkey_alloc / pkey_mprotect | 38 | 38 | 38 | ¹ |
| dlopen 签名 .so | OK | OK | OK | ¹ |
| dlopen text +W / data +X / 自身 text +W | 22 / 1 / 22 | 同 | 同 | ¹ |
| fork / 子进程 anon exec | OK / 22 | OK / OK | OK / OK | ¹ |
| 子进程 exec `/system/bin/sh` | OK(exit 7) | OK | OK | 仅 system_file 可执行² |
| `prctl(0x6a6974,0) / (0,1) / (0,0) / (0,1)` 直传 | 0 / 0 / 0 / 22 | 同 | 同 | ¹ |
| `/proc/self/xpm_region` | `0-0`→4 GB | 4 GB | `0-0` | `0-0` |
| kit probe / runtime | `1=22 2=22`；CoreLib 失败 | `1=OK 2=OK`；CoreLib 通过 | —（anon OK 但无 runtime） | — |

¹ 该域不可执行任意 ELF：`/data/local/tmp` 标签 `u:object_r:data_local_tmp` 无 exec 许可；签名/未签名探针、`cp /system/bin/sh` 均 `EACCES`(rc 126)，仅 symlink→`/system/bin/sh`（system_file 标签）可执行 → 无法在 sh 域运行自带 probe。
² SELinux 按目标 inode 标签放行，与 JITFORT/W^X 无关。系统签名/预装域不可得（无材料，记录）。

## 3. 平台要求（表述）

- 本镜像 app 域可执行内存默认拒绝（XPM/JITFORT fortify；`persist.security.jitfort.disabled` 属性缺失，param err 1002）。**解除条件 = `prctl(0x6a6974, 0, 0)`（JITFORT off），arg3=1 为 fortify/拒绝**；宿主在 CoreCLR 启动前调用即可工作，无需平台改动。
- 平台"仅系统 JS 引擎可 JIT"在此镜像**非调用者隔离**：任何加载了自签名原生代码的 app 都能翻转该状态（并影响后续 app 进程），建议平台明示契约或提供 JIT 权限，否则依赖隐藏 prctl。
- W^X 合规路径（memfd/文件 RX）全域不可用；唯一进入 JIT 的形态是 anon RWX + `EnableWriteXorExecute=0`。

## 4. 与前轮结论差分

- 2026-08-31「XPM 不生效（anon RWX OK）」复测属 hishell 类域；app HAP 域一直生效（kit #24 探针 `1=22`）——两结论并存，差异 = 域 + JITFORT 状态。
- INTERP-FRAME 7 项（`1=22 2=22 3=13 4=1 5=13 6=13 7=22`）全部复现；新增 12 条未试路线（MFD_EXEC、seal 组合、pkey、MAP_XPM、dlopen 对照、fork 继承）确认无第二条路。
- kit22/30/31 的 JIT 主判失败属"默认 fortify"态；解除后 JIT/interp 均过 CoreLib（`jit-enabled.out`：JIT HAP `run_app entering`、`Failed to load`=0；55 s 窗口 canvas=0）。

## 5. 提交 / 不确定

- 提交：本文件（`commit-paths.sh`，`feature/openharmony`，未强推）。证据在 scratch，未入库。
- 不确定：① 仅 debug_hap 实测，release/生产签名域未测；② 状态是否跨重启（未 reboot）；③ prctl 是否平台认可（内核开源树不见实现，应在商业 XPM LSM）；④ JIT 首帧未确认（canvas=0，需长窗复测）；⑤ 系统/预装域不可得。
