# Mono

Mono runtime: managed runtime for iOS/Android (mobile), WebAssembly (browser), and WASI workloads. 2,955 files. Native core in C, browser glue in JS + C.

## STRUCTURE

- `mono/` — the runtime proper, all C
  - `mini/` — JIT + interpreter
  - `metadata/` — type system, class layout, images
  - `sgen/` — generational GC
  - `component/` — debugger-engine.c, hot_reload.c, eventpipe
  - `profiler/`, `utils/`, `eglib/`, `minipal/`, `arch/`
- `browser/` — WASM browser runtime (JS + C), BrowserDebugProxy/
- `wasm/` — WASM build/test integration, Wasm.Build.Tests
- `wasi/` — WASI runtime + build
- `llvm/` — LLVM backend for Mono AOT
- `msbuild/` — mobile (iOS/Android) build targets
- `System.Private.CoreLib/` — Mono's core library copy
- `sample/`, `tests/`, `tools/`

## WHERE TO LOOK

| Task | Path |
|------|------|
| JIT / interpreter | `mono/mini/` |
| Type system, layout, images | `mono/metadata/` |
| GC | `mono/sgen/` |
| Debugger, hot reload | `mono/component/` |
| WASM browser runtime | `browser/runtime/`, `browser/BrowserDebugProxy/` |
| WASM build + tests | `wasm/` |
| WASI | `wasi/` |
| LLVM AOT backend | `llvm/` |
| Mobile build | `msbuild/` |
| Mono core library | `System.Private.CoreLib/` |
| Runtime tests | `tests/` |

## CONVENTIONS

- C style deviates from CoreCLR: tabs, 8-col indent, K&R braces (braces on their own line only at function start). See `mono/.editorconfig`. Root 4-space/Allman does not apply.
- Handle-based object access: use MONO_HANDLE_NEW / MONO_HANDLE_CAST, not raw handle derefs.
- Mono metadata structs are layout-critical. `metadata/class-internals.h`: do not add fields after vtable.
- Build uses Mono-specific subsets, not CoreCLR's. `./build.sh -subset mono+libs+host+packs -c release` or `./build.sh mono -c release`.
- Build is CMake-driven with a wrapper Makefile (`Makefile` targets: runtime, run-tests-coreclr, run-tests-coreclr-all, run-sample).
- MonoAOT cross: `-s mono.aotcross`; LLVM backend: `mono LLVM`.
- Deeper docs: `docs/workflow/building/mono/README.md`, `src/mono/README.md`.

## ANTI-PATTERNS

- Don't hand-edit WasiPoll*.cs (wit-bindgen output, generated at build time).
- Never rename `System.Private.CoreLib/src/System/Threading/Thread.Mono.cs` or add fields after the existing ones.
- Don't assume CoreCLR native conventions carry over. Mono differs on style, handles, and build.
- Use DOTNET_ env prefix, never COMPlus_.

## BUILD / TEST

- `./build.sh mono -c release` — Mono runtime only
- `./build.sh -subset mono+libs+host+packs -c release` — full Mono product
- `make -C src/mono <target>` — subtree targets (see Makefile)
- Mobile/browser tests run via Microsoft.DotNet.XHarness; see `docs/workflow/testing/mono/testing.md`
- CoreCLR-style tests under `src/tests/` can also run against Mono
