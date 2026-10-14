# NA — native libs + build glue — OpenHarmony port review

Scope (working tree, branch `feature/openharmony`, baseline `main` @ `719009acffb`):

```
src/native/libs/System.Native/{pal_process.c,pal_signal.c,pal_interfaceaddresses.c}
src/native/libs/System.Security.Cryptography.Native/{CMakeLists.txt,extra_libs.cmake,opensslshim.c,pal_err.c,pal_hmac.c}
src/native/libs/System.Net.Security.Native/extra_libs.cmake
src/native/libs/{build-native.proj,build-native.sh,CMakeLists.txt}
eng/native/{tryrun.cmake,gen-buildsys.sh}
```

Method: located the OHOS hunks with `git log --no-merges --author=springmin -p -- <file>` and
`git diff main -- <file>`, then read the surrounding logic. Two claims were verified by experiment
on this OpenHarmony device (clang/musl, `HongMeng Kernel 1.13.0`):

1. **`-C` initial-cache semantics** (for `tryrun.cmake`): a `-C` script runs during CMake argument
   parsing, *before* `project()`; `CMAKE_SYSTEM_NAME` is not a cache entry and is set from the
   toolchain file/`-D` only later. Measured with cmake 4.4.3: `-- PRELOAD: CMAKE_SYSTEM_NAME=[]` even
   on a re-configure of the same build dir; it is visible only if `-DCMAKE_SYSTEM_NAME=...` appears
   *before* `-C` on the command line (that ordering is what the Android branch relies on:
   `-DANDROID_BUILD=1 -C tryrun.cmake`).
2. **close_range on OpenHarmony**: a forked child calling `syscall(SYS_close_range, ...)` — including
   the "side-effect-free" `UINT_MAX,UINT_MAX,CLOSE_RANGE_CLOEXEC` probe idiom — is **killed by SIGSYS**
   (signal 31) on this device. Also verified `SYS_getdents64` exists in the OHOS sysroot (so the
   `/proc/self/fd` walk does compile in for OHOS), and a standalone replica of the dirent parse loop
   resolves real fds correctly (`./fdwalk` → fds 0,1,2,3,4, `d_reclen=24`, `.`/`..` skipped).

---

## Findings

### ❌ 1. The OpenHarmony `tryrun.cmake` gate can never be true — the pins are dead code and the comment states an impossible mechanism
`eng/native/tryrun.cmake:24-31`

The comment says "CMAKE_SYSTEM_NAME is passed on the CMake command line (`-DCMAKE_SYSTEM_NAME=OHOS` for
cross builds), which the initial-cache script can read", but (a) `eng/native/gen-buildsys.sh:80-82`
deliberately does **not** pass `-DCMAKE_SYSTEM_NAME=OHOS` ("do not override it" — the NDK toolchain file
sets it), and (b) a value set by the toolchain file is never visible inside a `-C` script, in any CMake
version, because `-C` is processed before `project()` (measured: `CMAKE_SYSTEM_NAME=[]` inside the `-C`
script, with the toolchain file setting `OHOS`; also empty on a re-configure because `CMAKE_SYSTEM_NAME`
is not a cache variable). Consequence: `HAVE_BROKEN_FIFO_KEVENT_EXITCODE`/`HAVE_BROKEN_FIFO_SELECT_EXITCODE`
are never pinned by this hunk. The port's own scripts mask this by passing the two values explicitly
(`scripts/ohos-runtime-clrinterpreter-build.sh:139`, `scripts/ohos-runtime-interp-fullbuild.sh:194`); the
upstream-visible `./build.sh -os openharmony --cross` path does not.

Fix: mirror the Android precedent in `eng/native/build-commons.sh` — put a marker before the cache file
(`-DOHOS_NDK_HOME=... -C tryrun.cmake ...`) and gate on that, or gate on the env var
(`if(DEFINED ENV{OHOS_NDK_HOME})`), or delete the block (the linux-family branch below already supplies the
other answers). Confidence: high.

> Note (evidence, not a port defect): even if the gate fired, the two FIFO probes cannot be steered by a
> cached `_EXITCODE` because their sources currently fail to **compile** (upstream typo `exit(numFD==0)`
> for `numFDs`, `src/coreclr/pal/src/configure.cmake:256`), so `check_cxx_source_runs` short-circuits to
> FALSE. Do not "fix" the pin values; fix or drop the gate.

### ⚠️ 2. The one-time close_range probe runs in the *parent*, so a SIGSYS-trapping sandbox now kills the app instead of failing one spawn
`src/native/libs/System.Native/pal_process.c:405-417` (probe), `:935-943` (call site)

Before this port, the only `close_range` calls happened inside the `fork()` child
(`RestrictHandleInheritance`); the new `ProbeCloseRange()` call site is in `ForkAndExecProcessInternal`
*before* `fork()` (line 936), i.e. in the application process. On any seccomp/sandbox profile that turns
`close_range` into `SECCOMP_RET_TRAP` (verified fatal on this OpenHarmony device; Android app filters are
also kill-on-trap profiles), the probe terminates the whole process on the first `Process.Start`, whereas the
old code only lost the child. OHOS is guarded, but the probe is compiled for **all** Linux/Android targets.

Fix: do not issue the (possibly fatal) syscall from the parent — probe in the fork child and cache the result
there, or drop the probe and keep per-call failure handling, or gate the probe to platforms known not to trap
it. Confidence: high for the mechanism, medium for impact on non-OHOS targets.

### ⚠️ 3. The `/proc/self/fd` walk is shipped as a Linux-wide behavior change, not as an OpenHarmony fix
`src/native/libs/System.Native/pal_process.c:261-348`, `:355-362`

The commit is framed as the OHOS H8 performance fix, but the guard is `defined(__linux__) &&
defined(SYS_getdents64)`, so every glibc/musl/Android Linux build switches its `SetCloexecForAllFdsFallback`
from the RLIMIT scan to a `/proc` walk. The port's own rules say "only touch OpenHarmony / keep Android
untouched" (review-lessons §2) and "unrelated parts in a separate PR" (§3); this hunk cannot be reviewed as an
OHOS change (it also reparents the pre-existing fallback and renames `SetCloexecForFd`).

Fix: either scope the walk to `defined(TARGET_OPENHARMONY)` (keeping the old fallback elsewhere), or split it
out and propose it upstream as a general Linux/Android improvement with the measured numbers. Confidence: high.

### ⚠️ 4. `fd > (1 << 20)` silently skips descriptors while reporting the listing as complete — CLOEXEC is then not enforced for them
`src/native/libs/System.Native/pal_process.c:329-338`

A name that parses to a value above 2^20 is treated as "malformed" and skipped, yet the function still returns
`complete = true`, so `SetCloexecForAllFdsFallback` does not fall back to the bounded range scan. With
`fs.nr_open` raised above its default 2^20, an open fd above that value silently leaks into the execed child
(the path is security-relevant: CLOEXEC propagation). The reachable cases are bounded by `INT_MAX` because
`fcntl` takes an `int`.

Fix: bound on `INT_MAX` instead of `1 << 20` (and/or treat an out-of-range name as `complete = false` so the
rlimit scan runs). Confidence: high on the logic, low on reachability (needs a raised `nr_open`).

### ⚠️ 5. The sibling-OpenSSL path is not guaranteed to be absolute, so the fail-closed policy can still resolve through the CWD (or abort on a bare-name load)
`src/native/libs/System.Security.Cryptography.Native/opensslshim.c:84-113`, `:127-132`

`GetSiblingLibraryPath` concatenates `dirname(info.dli_fname)` + `/` + soname and the comment claims the
library is opened "by absolute path"; nothing checks that `dli_fname` starts with `/`. For an app binary
invoked relatively (`./app`, e.g. a NativeAOT app, whose own image is what `dladdr(&GetSiblingLibraryPath)`
reports) the constructed path is CWD-relative, i.e. the CWD decides which "libssl.so.3" becomes the TLS
provider — the exact scenario the policy is meant to prevent. When `dli_fname` has no slash at all (loaded by
bare soname / via `PATH`) the code hard-fails instead, so "put libssl.so.3 next to this library" is not
sufficient. The port's policy doc still lists the on-device `SslStream`/HTTPS self-check as TODO.

Fix: require `info.dli_fname[0] == '/'` (or resolve the real path via `readlink("/proc/self/exe")` /
`/proc/self/maps`) and fail closed otherwise; then verify end-to-end with a real SslStream request, not only
a manual `dlopen` harness. Confidence: medium-high.

### ⚠️ 6. Dated lab-plan references and over-long rationale comments in upstream-visible files
`src/native/libs/build-native.sh:64-76` (`docs/plans/2026-09-23-ohos-tls-policy.md`,
`docs/plans/2026-10-03-ohos-aotpack-structural.md`), `src/native/libs/System.Security.Cryptography.Native/CMakeLists.txt:115`
(`docs/plans/2026-10-03-ohos-aotpack-structural.md`)

Review-lessons §2 forbids dated/lab/historical narrative in comments and calls out "unnecessarily verbose";
these are the only remaining `docs/plans/...` references in native/build code (checked repo-wide) and they will
dangle if the internal plan docs are not part of the upstream PR. `build-native.sh` spends 13 comment lines on
the OpenSSL/static-archive policy in a shell script that reviewers read as build plumbing.

Fix: drop the `docs/plans/<date>-*.md` references and compress each rationale to 1–3 lines (keep the "why"
only where it is not obvious from the code). Confidence: high.

### 💡 7. `-linkstaticopenssl` is silently ignored on non-OHOS targets
`src/native/libs/build-native.sh:5,79`, `src/native/libs/build-native.proj:50`

The switch is documented "OpenHarmony only" and the OHOS guard is checked only when building the
`-D` values; passing it for another `-os` produces a normal portable build with no message, which is a
footgun for CI/SDK scripts (`-DCMAKE_STATIC_LIB_LINK` / `FEATURE_DISTRO_AGNOSTIC_SSL_STATIC` are also pushed
for every non-Apple/Android target, where they are no-ops because the CMake default is identical).

Fix: `echo "error: -linkstaticopenssl is only supported for -os openharmony"; exit 1` for other targets (and
consider only passing `-DFEATURE_DISTRO_AGNOSTIC_SSL_STATIC` when it differs from the default). Confidence: high.

### 💡 8. OHOS gets the glibc answer for a musl-sensitive try_run cache value
`eng/native/tryrun.cmake:104-108` (else branch; `HAVE_SHM_OPEN_THAT_WORKS_WELL_ENOUGH_WITH_MMAP`)

`ALPINE_LINUX` is detected from rootfs paths, so an OHOS cross build falls into the plain-linux default
(`_EXITCODE 0` → variable TRUE, i.e. "shm_open+mmap works"), while the musl/Alpine answer is the other one.
`SystemNative_ShmOpen/ShmUnlink` (`pal_io.c:471,489`) gate named shared memory on this value, so a wrong
answer is user-visible (ENOTSUP vs. a failure later in `mmap`).

Fix: run the probe on an OHOS device once and pin the observed answer in the (fixed) OHOS block of
`tryrun.cmake`. Confidence: low-medium.

### 💡 9. Missing `d_reclen` bounds check in the dirent loop
`src/native/libs/System.Native/pal_process.c:310-340`

The loop trusts `d_reclen` to stay inside `bytes` (only `d_reclen == 0` is rejected), and reads `d_name` as a
NUL-terminated string from the 4 KiB stack buffer. The kernel guarantees complete entries, so this is
unreachable today, but the parser already defends against malformed *names*; a malformed *record* would read
past the buffer.

Fix: `if (entry->d_reclen > bytes - offset) { complete = false; break; }` before using the entry. Confidence: high (nit).

### 💡 10. `s_closeRangeAvailable` is a plain `volatile int` shared across threads and the fork child
`src/native/libs/System.Native/pal_process.c:400`

`ProbeCloseRange` can be entered concurrently from multiple threads doing `Process.Start` (races are benign —
both may issue the probe — but it is a C11 data race), and the child then reads a value written in the parent.
Existing code styles this with minipal atomics.

Fix: use a minipal atomic (or add a one-line comment stating the benign-race intent). Confidence: medium.

### 💡 11. Redundant `<pthread.h>` include with a rationale that does not hold for that file
`src/native/libs/System.Native/pal_signal.c:19`

`minipal/thread.h` (included on the line above) already includes `<pthread.h>` on every non-Windows target, so
this include cannot be what fixed the OHOS build; the commit message ("pthread APIs ... relying on a transitive
include that the OHOS NDK sysroot does not provide") is only accurate for `pal_err.c`/`pal_hmac.c`.

Fix: keep the include if self-contained headers are the goal, but drop the OHOS-NDK explanation for this file
(or drop the include). Confidence: high (nit).

---

## Verified-OK

- `close_range` is never issued on OHOS: the macro definition (`pal_process.c:45`), the probe
  (`:395-418`, call site `:935`), and both call sites (`:428`, `:445`) are all guarded by
  `!defined(TARGET_OPENHARMONY)`, and no other file in `src/` calls `close_range`/`closefrom`. The trap is
  real (verified: `syscall(SYS_close_range, ...)` → SIGSYS/signal 31 in a fork child on this device), and the
  probe idiom would have been fatal had it been left unguarded.
- The `/proc/self/fd` parse loop and hand-rolled dirent layout are empirically correct on aarch64/OHOS:
  a standalone replica lists fds 0–4, advances by `d_reclen` (24), skips `.`/`..`, terminates, and needs no
  malloc (only `open`/`syscall`/`fcntl`/`close`), so the fork-child constraint in review-lessons §5 holds.
- `int fd` digit accumulation cannot overflow (`fd <= 1<<20` before each `fd*10`, so ≤ ~10.5e6).
- `SetCloexecForFdValue`/`SetCloexecForFd` are compiled exactly where they are called
  (`HAVE_FDWALK || (linux && SYS_getdents64)` / `HAVE_FDWALK`), so no `-Wunused-function`; the
  `CLOSE_RANGE_CLOEXEC` definition is guarded so no `-Wunused-macros` (the R2 fix).
- `pal_interfaceaddresses.c:556-562` inlines `ethtool_cmd_speed()` exactly as the kernel UAPI defines it
  (`(speed_hi << 16) | speed`), the Android branch is left untouched, and the surrounding
  `HAVE_ETHTOOL_H` / error handling is unchanged.
- `opensslshim.c` `_GNU_SOURCE` guard is inert in the normal build (the libs build passes `-D_GNU_SOURCE`
  for `CLR_CMAKE_TARGET_LINUX`, which OHOS maps to) and only serves standalone compilation; bounds checks in
  `GetSiblingLibraryPath` are correct; `PATH_MAX` comes from `<limits.h>`, included for the new branch.
- Crypto `CMakeLists.txt` split (`objlib` vs `objlib_static`, `NATIVECRYPTO_STATIC_OBJECTS`) is consistent:
  the three combinations (portable / static-only / OHOS `-linkstaticopenssl`) each produce exactly one shim
  configuration, and the AOT/static-apphost consumer
  (`src/native/corehost/apphost/static/CMakeLists.txt:166`) keeps the shim in the archive.
- `System.Net.Security.Native/extra_libs.cmake:27-31` is genuinely needed: the static apphost evaluates the
  macro (`apphost/static/CMakeLists.txt:195`) even though `System.Net.Security.Native-Static` is skipped for
  OHOS (`:161-163`), and the managed side degrades gracefully when the library is missing
  (`NegotiateAuthenticationPal.Unix.cs:771-783`).
- `extra_libs.cmake:39-44` `-Wl,--exclude-libs,ALL` is OHOS-only and cannot leak into other links:
  `CMAKE_STATIC_LIB_LINK` is only ever set by `build-native.sh`, so the coreclr/apphost configure never
  takes that branch.
- `pal_err.c:6`/`pal_hmac.c:9` are correct: both files use `pthread_mutex_*`/`pthread_once` and their own
  headers do not provide the declarations.

## Out-of-group observation (for whoever owns `eng/native`)

`eng/native/configurecompiler.cmake:943-949` (port commit, `-march=x86-64-v2` at `:947`) adds it (and
`/arch:SSE4.2` on Windows) for **every** AMD64 host build. That raises the minimum CPU for the produced
x64 artifacts on all platforms, not just OHOS; if it is only meant to satisfy the OHOS toolchain it should
be scoped, otherwise it needs an explicit rationale.
