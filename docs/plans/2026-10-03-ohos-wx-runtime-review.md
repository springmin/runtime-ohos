# W^X 降级方法清点与可行补丁评估（WX-RUNTIME，2026-10-03）

> 范围：runtime-ohos `feature/openharmony`（6cd95aa5519）源码只读盘点 + 前几轮设备证据
> （KIT41/INTERP-FIX/INTERP-FRAME/syscall-audit/runtime-strategy）。设备：HAD-W24/W32
> 7.0.0.111（API 26）。结论先行：HAP 域无任何可用 exec 通道，JIT/解释器均止步 CoreLib
> 装载；现有降级手段均属配置/宿主层，runtime 源码未动 W^X 路径。

## 1. 既有手段（已改/已验/已试后退）

| 手段 | 位置 / 提交 | 状态 |
|---|---|---|
| OHOS 默认关 W^X | `clrconfigvalues.h:637-643` `678ac21836c`（+`4c77bcca`/`fbaba79e`/`051492b4`/`94e28f7f` 注释） | CLI 域 JIT 全绿；HAP 域无效（anon RWX EINVAL）|
| 宿主 setenv `DOTNET_EnableWriteXorExecute=0` + `xwe.txt` A/B | ohos-workload kit #24 起，`OhosHostApplyExecMemoryPolicy` | 生效；不改变 HAP 域结论 |
| 解释器 pack rc.2（`FEATURE_INTERPRETER=1`、`DOTNET_InterpMode=3`、宿主 `interp.txt`） | 本仓 `-clrinterpreter`；pack `34709a94…` | 构建全通；HAP 域 CoreLib 装载 RWX→EINVAL（0x800701E7）|
| `DOTNET_UseGCWriteBarrierCopy=0`（仅 interp=3） | ohos-workload `c9916cd` | 修 `+996` 写屏障 memcpy 崩；非解锁 |
| 8 MB app 线程栈 | ohos-workload `c9916cd` | 修 `+440` `EnsureStackSize`（1 MB musl 栈）|
| exec-memory 探针 1–7 | host scratch（interp-frame `run3.out`） | 1/2/7 anon=22 EINVAL；3/5/6 file/memfd/bundle=13 EACCES；4 tmpfile=1 EPERM |
| seccomp 拦截器、PAL SIGSYS→ENOSYS、LD_PRELOAD/GOT | strategy §4；`70ba6f54f25` 已由 `78096ffb3a4` revert | 均不采用（只诊断/不解锁）|
| 未改：PAL/分配器/装载器 | `git diff upstream/main...HEAD -- src/coreclr` 无 `virtual.cpp`/`doublemapping.cpp`/`executableallocator.cpp`/`peimagelayout.cpp` | 无源码级 W^X 降级补丁可清点 |

## 2. 上游对照与我们的失败点

- **三条路径**：xwe=0 → 匿名 RWX（`ExecutableAllocator::Commit`→PAL `mprotect RWX`）；xwe=1 → memfd 双映射（`minipal/Unix/doublemapping.cpp`，本树无 `g_doubleMappedMemory` 符号）；Apple arm64 恒 W^X=`MAP_JIT`+`pthread_jit_write_protect`（`virtual.cpp:1282-1302`），OHOS 均未接。
- **回退缺陷**：仅 `CreateDoubleMemoryMapper()` 失败才回退 xwe=0（`executableallocator.cpp:286-292`）；memfd 可建但 RX 提交失败时不回退。`threads.cpp:1200-1211` 的 `Commit(...,true)` 返回值未检查 → 页留 PROT_NONE → `memcpy` ACCERR（= 我们的 `+996`）。
- **顺序不是问题**：CoreLib 拷贝路已“先 RW 写入、后 `mprotect` RX”（`peimagelayout.cpp:1011-1055`）；失败在 RX 提升本身（HAP EINVAL）。`FlushInstructionCache`=`__builtin___clear_cache`（`context.cpp:2210`），与保护无关。
- **平台旁路**：OHOS 内核 fork 定义 `MAP_JIT 0x80000000`（FORT→PROT_EXEC）；ArkTS 走 JITFort+ACL。第三方需 AGC ACL：`ALLOW_WRITABLE_CODE_MEMORY`（RWX 匿名，平板/2in1、受邀）或 `ALLOW_EXECUTABLE_FORT_MEMORY`/`ALLOW_USE_JITFORT_INTERFACE`（JS 引擎向）。

## 3. 候选补丁（按优先级）

| # | 补丁 | 可行性 / 改动面 | 验证 |
|---|---|---|---|
| ① | OHOS exec 分配器：PAL 在 `TARGET_OPENHARMONY` 下给可执行预留带 `MAP_JIT`（define 兜底 + knob），或接 JITFort | **先探针后定**：HAP 域 `mmap(RWX\|MAP_JIT)`、`mmap(PROT_NONE\|MAP_JIT)+mprotect(RX)` 通过才有意义；通过则 ~30 行（PAL+allocator）；不通过 = 纯 ACL | host token 8/9；`xwe=0` JIT hello + maps |
| ② | 回退链与检查：`Initialize` 预检双映射（memfd RW + `mprotect RX`）失败即 xwe=0（告警）；`Commit` 失败检查 / OHOS 默认 `UseGCWriteBarrierCopy=0` | **小（~30 行）**，上游友好；不解 HAP 域，只让 xwe=1 优雅降级 | xwe=1 A/B 不再 memcpy ACCERR；Linux/macOS CI 不变 |
| ③ | 无 exec 解释器：a) PE 装载器在 `InterpMode=3`（隐含 R2R=0）时 exec 段降 RW；b) `FEATURE_PORTABLE_ENTRYPOINTS`（现仅 WASM）开到 OHOS arm64 | **大**：a ~30 行但单不够；b 涉 precode/UMEntryThunk/反向 P-Invoke、20+ `PORTABILITY_ASSERT`，非 WASM 未验 | bounded spike：maps 无匿名 `r-x` + hello；失败归档 |

## 4. 建议

1. 出货继续 **NativeAOT**（真机出画、零动态 exec）。
2. 立即加 host 探针 token 8/9（MAP_JIT/FORT）判 ①；并行启动 AGC ACL 预研。
3. ② 独立小 PR（对 CLI 域 xwe=1 与未来平台都有价值）。
4. ③ 仅当平台永久堵死且必须 JIT/interp 时做，且先 spike。
5. **若平台全堵则要求 ACL/系统签名**：申请 `ALLOW_WRITABLE_CODE_MEMORY`（2in1/平板、受邀、AGC profile ACL）或 `os_integration` 系统签名/预置 + JIT 豁免；否则仅 AOT 形态可上架。

## 5. 不确定项

- `MAP_JIT` 是否 ACL/能力门控（HAP 域未实测）；JITFort ABI/文档未核。
- `interp.txt=1|2` 差分未跑；portable entrypoints 非 WASM 可行性未证。
- 7.0.0.105（tester 机）与 7.0.0.111 策略差异仍在。

## 6. 提交

- 本文 + scratch `/data/storage/el2/base/tmp/opencode/wx-runtime/NOTES.md`（精确路径提交，未强推）。
