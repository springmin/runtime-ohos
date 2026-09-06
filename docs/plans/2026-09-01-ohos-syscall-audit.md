# OHOS TARGET_LINUX / Syscall Audit Report

**Date:** 2026-09-01 · **Device:** HarmonyOS, HongMeng Kernel 1.13.0 (aarch64) · **Runtime:** .NET 11.0.0-rc.1.26451.1-ohos (running on device)

**Purpose:** Answer jkotas's review question — how many `TARGET_LINUX` guards are correct for OpenHarmony? Audit-driven, not blanket inheritance.

---

## A. Hardcoded syscall numbers (`__NR_*`) — 15 files

| # | File | Syscall | Number | On-device (HongMeng 1.13.0) | Verdict |
|---|---|---|---|---|---|
| 1 | `System.Native/pal_process.c:303` | `close_range` | 436 (fallback hardcode) | **SIGSYS (all args)** | 🔴 **FIX NEEDED** |
| 2 | `System.Native/pal_io.c:1423` | `copy_file_range` | 285 (aarch64 fallback) | allowed (EINVAL → reaches kernel) | ✅ OK |
| 3 | `System.Native/pal_io.c:429/449` | `memfd_create` | header | ✅ works | ✅ OK |
| 4 | `minipal/memorybarrierprocesswide.c` + `pal/src/thread/process.cpp:69` | `membarrier` | header | allowed (ret=25) | ✅ OK |
| 5 | `gc/unix/numasupport.cpp:60/89` | `get_mempolicy`/`mbind` | header | SIGSYS / ENOSYS | ✅ already fixed (`TARGET_OPENHARMONY`) |
| 6 | `coreclr/minipal/Unix/doublemapping.cpp` | `memfd_create` | header | ✅ works | ✅ OK |
| 7 | `eventpipe/ds-ipc.c` | `memfd_create` | header | ✅ works | ✅ OK |
| 8 | `minipal/cpufeatures.c` | `riscv_hwprobe` | — | N/A (riscv only) | N/A |
| 9 | `pal/src/thread/context.cpp:2204` | `riscv_flush_icache` | 259 | N/A (riscv only) | N/A |
| 10-12 | `libunwind` hppa/ia64 | `rt_sigreturn`/`sigreturn`/`getunwind` | — | N/A (hppa/ia64) | N/A |

**Syscall numbers match the Linux generic table on the tested kernel** (verified empirically) — but this is not a contract (openharmony-linux / harmony-ohos / liteos kernels may differ).

## B. Linux-specific paths (`/proc`, `/sys`, `/etc`) — 10 distinct paths

| Path | On-device | Used for |
|---|---|---|
| `/proc/self/mountinfo`, `/proc/self/cgroup`, `/proc/self/statm` | ✅ | cgroup/limits detection |
| `/proc/mounts`, `/proc/self/stat` | ✅ | mount/stat |
| `/proc/meminfo` | ✅ | memory info |
| `/proc/self/maps` (assumed), `/proc/self/exe` | ✅ | — |
| `/sys/fs/cgroup` | ✅ | cgroup v1 (freezer/pids, sandbox paths) |
| `/sys/devices/system/node` | — | NUMA (already skipped on OHOS) |
| `/system/usr/icu/` | — | ICU (OHOS has its own ICU) |
| **`/etc/os-release`** | ❌ **MISSING** | distro detection — runtime falls back (RID comes from the graph, unaffected) |

**Verdict: low risk** — all runtime-critical proc/sys paths verified present.

## C. `TARGET_LINUX` guard surface — 48 files total, 23 C/C++/H source files

| Area | Files with TARGET_LINUX |
|---|---|
| `src/native/libs` | 7 |
| `src/coreclr/pal` | 1 (plus build files) |
| `src/coreclr/gc` | 3 |
| `src/coreclr/vm` | 2 |
| `src/native/minipal`, `corehost`, `eventpipe` | 1 each |
| build/config (cmake/props, not counted above) | rest of 48 |

Classification by content (sampled): most guards are **plain POSIX/musl behavior** (libc-level, valid on OHOS since its libc is musl-based — factual inheritance), **not** Linux-syscall or Linux-path specific. Deep per-guard review continues for the remaining files (will publish as follow-up).

## D. Seccomp whitelist audit — **7 syscalls trapped (SIGSYS)** on-device

| Syscall | Runtime usage | On-device | Handling | 7.1 policy* |
|---|---|---|---|---|
| `get_mempolicy` (237) | GC NUMA probe | SIGSYS | ✅ fixed (numasupport.cpp) | relaxed |
| `close_range` (436) | fork/exec cloexec sweep (`pal_process.c`) | SIGSYS | 🔴 **crash if reached** (masked by posix_spawn today) | relaxed |
| `inotify_init1` (294) | **FileSystemWatcher backend** (`pal_io.c:1602`) | SIGSYS | 🔴 **crash when used** | **not in bun's list — needs request or fallback** |
| `rseq` (293) | TLS acceleration | SIGSYS | ✅ graceful (apps run) | **stays blocked** |
| `clone3` (435) | thread creation | SIGSYS | ✅ musl falls back to `clone` | relaxed |
| `openat2` (437) | not used by runtime | SIGSYS | ✅ harmless | — |
| `signalfd4` (289) | not used by runtime | SIGSYS | ✅ harmless | — |

\* HarmonyOS 7.1 relaxation agreed with the HarmonyOS team during the **Bun port** covers `clone3`, `get_mempolicy`, `close_range` (everything except `rseq`). **`inotify_init1` is a .NET-specific gap** — Bun doesn't use inotify, so it wasn't in the 7.1 list.

**Other syscalls verified allowed** (not SIGSYS): statx, pidfd_open, timerfd_create, eventfd2, getdents64, readlinkat, renameat2, epoll_create1, pipe2, dup3, gettid, set_robust_list, madvise, clock_gettime, nanosleep, wait4, rt_sigaction, ioctl, fcntl, socket, connect, accept4, recvmsg, sendmsg, mmap, munmap, openat, read, write, close, dup, rt_sigprocmask, memfd_create, copy_file_range, membarrier, futex, prctl, tgkill, epoll_pwait, ptrace, mprotect, mremap.

## Required fixes (runtime)

1. **`close_range`** (`pal_process.c`): add `TARGET_OPENHARMONY` guard → skip syscall, use `SetCloexecForAllFdsFallback()`. Revisit after 7.1.
2. **`inotify_init1`** (`pal_io.c`): `TARGET_OPENHARMONY` guard → return `ENOTSUP` (managed `FileSystemWatcher` reports unsupported; polling fallback can be added later). Also request `inotify_init1` addition to the HarmonyOS whitelist.
3. **`rseq`**: keep the graceful-degradation path permanently (7.1 keeps it blocked).
4. No other changes required from this audit; remaining C-category guard review is informational.

## Conclusion

- Syscall numbers match Linux today (empirical, not contractual).
- 7 syscalls trapped by seccomp; 2 are real crash risks (`close_range`, `inotify_init1`) → both get `TARGET_OPENHARMONY` guards.
- `/proc`/`/sys` surface verified usable; `/etc/os-release` absent (handled).
- Approach: audit-driven, targeted `TARGET_OPENHARMONY` handling (same pattern as the NUMA fix), not blanket `TARGET_LINUX` inheritance.

---

## Addendum (2026-09-06): syscall table verified = Linux asm-generic; verify tool fixed

Follow-up device verification (exchanges/ci-test/ohos-syscall-verify.c, dotnet
section added):

1. **OHOS aarch64 syscall table == Linux asm-generic** (301 syscalls, verified
   against NDK sysroot `aarch64-linux-ohos/bits/syscall.h` and on-device SIGSYS
   numbers). The earlier "numbers may differ" caveat is resolved for the
   tested kernel: no offsets exist. Full table:
   `exchanges/ci-test/syscall-table-ohos-aarch64.txt` +
   `ohos-syscall-table-verification.md`.
2. **verify.c Bun-section had 3 wrong numbers** (x86-64 values on aarch64):
   `statx 332→291`, `setgroups 158→159` (158 is getgroups on aarch64!),
   `membarrier 176→283`. Corrected so the Bun section tests the intended
   syscalls.
3. **New [dotnet] section** (separate from Bun) verifies .NET runtime syscalls
   with the runtime's actual arguments:
   - SIGSYS (runtime guards justified): close_range(3,UINT_MAX,CLOEXEC) = 436,
     get_mempolicy probe = 236.
   - OK: futex _PRIVATE variants, memfd_create CLOEXEC|ALLOW_SEALING, mbind,
     membarrier QUERY, sched_getaffinity, mprotect RW→RX (JIT W^X allowed),
     clock_gettime, madvise MADV_FREE, tgkill, pipe2(O_CLOEXEC), dup3,
     epoll_pwait, signalfd4, rt_sigprocmask.
   - 17/17 dotnet items pass; runtime hardcoded __NR_ values (copy_file_range
     285, close_range 436, numasupport/minipal via sys/syscall.h) all compile
     to correct aarch64 numbers - no runtime change needed.
