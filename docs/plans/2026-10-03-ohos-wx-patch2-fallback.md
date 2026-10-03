# WX-PATCH2：双映射预检 + 写屏障 Commit 降级（2026-10-03）

> 范围：runtime-ohos `feature/openharmony` `src/coreclr`（minipal/threads/utilcode 小面）。
> 关联：`2026-10-03-ohos-wx-runtime-review.md` 候选 ②；`2026-10-03-ohos-wx-probe-matrix.md`。

## 1. 补丁（4 文件，+57/-1）

| 文件 | 改动 |
|---|---|
| `minipal/Unix/doublemapping.cpp` | memfd 建好后预检 RW mmap + PROT_NONE mmap + `mprotect(RX)`；失败记 errno 并返回 false（fd 失败也记录）|
| `utilcode/executableallocator.cpp` | 回落 xwe=0 时输出明确日志 |
| `vm/eeconfig.h` | 新增 `SetWriteBarrierCopyEnabled` |
| `vm/threads.cpp` | 检查 `Commit(...,true)` 返回值；失败不 memcpy 到未提交页，关副本回落到只读写屏障 |

判定（③）：OHOS `EnableWriteXorExecute=0` 默认不变；`UseGCWriteBarrierCopy` 仅 VM 读取（`threads.h`/`writebarriermanager.cpp`/`arm/stubs.cpp`，JIT 无引用），JIT 可用 =0，故不加平台默认，运行时回退已覆盖两种域；`xwe.txt=1` 时预检也会在启动早期回退并记录。

## 2. 构建证据

- `artifacts/obj/coreclr/openharmony.arm64.Release` ninja 增量：306 CXX 重编 + 链接成功（lld 需 `LD_LIBRARY_PATH=<sdk>/native/llvm/lib`，宿主缺 libxml2.so.16 时静默失败）。
- `artifacts/bin/coreclr/openharmony.arm64.Release/libcoreclr.so` sha256 `6f74e851…24222c9`，含新字符串，`.dbg` 同步。

## 3. 设备验证（HAD-W32 / 7.0.0.111；memfd RX 各域恒 13）

- 前：受控 CLI（同内核，stock coreclr，`DOTNET_EnableWriteXorExecute=1`）SIGSEGV(139)；faultlog `./corerun` `SEGV_ACCERR`，libcoreclr +0x3bc848（双映射提交/映射受保护页），1s 退出 —— 与历史 HAP `memcpy+312`/`coreclr_initialize+996` 同类。
- 后：补丁 coreclr（build-id `6d086c71…`）装入 JIT HAP 后可加载并执行到托管代码（类构造器，app 层 FailFast）；fortify 开/关各轮均未见写屏障/双映射 `ACCERR`。
- 混杂：devcompat 宿主无 8MB 栈修复，fortify=1 时 stock/patched 均先崩在 `EnsureStackSize`（`coreclr_initialize+440`，`SEGV_MAPERR`）；CLI 域加载补丁 `.so` 被 BinSec 拒（Permission denied），补丁 CLI A/B 无法直测；预检正确性由 3=13 与代码路径判定。

## 4. 提交 / 不确定

- 提交 `07700380098`（`commit-paths.sh`，`feature/openharmony`，未强推）。
- 不确定：① HAP 域写屏障失败点未能与 8MB 栈宿主同时复现；② 新日志走 stderr 未进 hilog，设备归因靠 faultlog build-id/地址；③ VM 启动 C++ 无单测缝，未加；未跑 Linux/macOS CI。
