# PROJECT KNOWLEDGE BASE — dotnet/runtime

**Generated:** 2026-08-13
**Commit:** `811225a4827`
**Branch:** `main`

## OVERVIEW

The .NET runtime repository: CoreCLR and Mono runtime implementations, the shared .NET class libraries (~218 packages), and the native shared host. C# / C++ / C / MSBuild monorepo (~58k files) built with the Arcade toolchain. **This is NOT a Rust project** — there is no Cargo.toml, no `.rs` source; do not look for cargo/clippy/rustfmt tooling here.

## STRUCTURE

```
runtime/
├── src/                  # all source (57k files)
│   ├── coreclr/          #   CoreCLR runtime: jit/, gc/, vm/, pal/, nativeaot/, System.Private.CoreLib/
│   ├── libraries/        #   ~218 library packages, each with src/ ref/ tests/
│   ├── mono/             #   Mono runtime: mobile/iOS/Android, WASM, WASI; its own System.Private.CoreLib
│   ├── native/           #   shared native code: corehost/, eventpipe/, minipal/, external/, libs/
│   ├── tests/            #   CoreCLR/runtime test tree (GC, JIT, Interop, Loader, ...)
│   ├── tools/            #   illink/, ilasm/, StressLogAnalyzer/, hotreload-delta-gen/
│   ├── installer/        #   shared host / CoreSetup (managed/, pkg/)
│   ├── tasks/            #   repo-local MSBuild tasks (WasmAppBuilder, AotCompilerTask, ...)
│   └── samples/          #   LibraryImportGeneratorSample
├── eng/                  # Arcade build engineering (548 files); eng/common is EXTERNALLY SYNCED
├── docs/                 # workflow/, design/ (incl. coreclr botr/), coding-guidelines/, project/
└── .github/              # CI + agent knowledge layer (instructions/, skills/, agents/)
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| CoreCLR runtime (JIT/GC/VM) | `src/coreclr/` (+ docs `docs/design/coreclr/botr/`) |
| Class library X | `src/libraries/<Pkg>/` — implementation in `<Pkg>/src/`, contract in `<Pkg>/ref/`, tests in `<Pkg>/tests/` |
| Mono (mobile/WASM/WASI) | `src/mono/` — runtime C in `mono/`, browser in `browser/`, wasm/wasi in `wasm/`,`wasi/` |
| Shared native host | `src/native/corehost/` |
| CoreCLR runtime tests | `src/tests/` (NOT `dotnet test` — see COMMANDS) |
| Library tests | `src/libraries/<Pkg>/tests/` (these DO use `dotnet test`) |
| Trim/link tooling | `src/tools/illink/` |
| Area owners for PRs | `docs/area-owners.md` |
| Per-area conventions | `.github/instructions/*.instructions.md` (auto-applied by `applyTo` globs) |
| Build/test commands | `.github/skills/build-and-test/SKILL.md` + `docs/workflow/` |
| CI pipelines | `eng/pipelines/` (Azure DevOps, primary); `.github/workflows/` (GitHub Actions, secondary) |

## EXISTING AGENT KNOWLEDGE LAYER (DO NOT DUPLICATE)

This repo already has a mature per-area convention system. Read before writing code:

- **`.github/instructions/`** — 23 area files (`conventions.instructions.md` applies to `src/**`; plus `csharp`, `native`, `tests`, `jit`, `core-runtime`, `system-net-*`, `extensions-*`, `illink`, `compression`, `cdac`). Specific file wins over general.
- **`.github/skills/`** — 17 skills incl. `build-and-test` (MANDATORY before any build/test command), `code-review`, `api-proposal`, `breaking-change-doc`, `performance-benchmark`, `vectorization`.
- **`.github/copilot-instructions.md`** — global PR/build conventions (must read).
- **`.github/agents/`** — 3 agent specs (`agentic-workflows`, `extensions-reviewer`, `system-net-review`).
- **`.github/prompts/docs.prompt.md`** — XML doc comment guidelines.

## CONVENTIONS (project-specific deviations)

- Warnings-as-errors is **ON by default** (`TreatWarningsAsErrors=false` to disable). `LangVersion=preview`, `AnalysisLevel=preview`.
- Analyzer severities centralized in `eng/CodeAnalysis.src.globalconfig` / `eng/CodeAnalysis.test.globalconfig` — do not scatter per-file suppressions.
- Style: `.editorconfig` at root (4-space indent, Allman braces in C++, mandatory MIT license header). `.clang-format` has `DisableFormat: true`; JIT C++ formatting enforced via `src/coreclr/scripts/jitformat.py` in CI, not clang-format config.
- Env vars: use `DOTNET_` prefix, **never** `COMPlus_`.
- Error strings live in `.resx` (referenced via `SR` class), not inline.
- `.editorconfig` naming: `s_` prefix + camelCase for private/internal static fields, `_camelCase` for private fields, PascalCase constants.
- **NativeAOT parity**: runtime changes under CoreCLR should consider whether NativeAOT needs the same fix. Mono native code conventions differ from CoreCLR — do not assume shared rules.

## ANTI-PATTERNS (THIS PROJECT)

- **NEVER edit `eng/common/`** — contents are synced from dotnet/arcade and overwritten by automation (see `eng/common/AGENTS.md`).
- **NEVER hand-edit generated files** — e.g. `src/coreclr/inc/*_generated.h`, `readytoruninstructionset.h`, `corinfoinstructionset.h`, `crsttypes_generated.h`, `WasiPoll*.cs` (wit-bindgen output), `XmlValueConverter.cs` (generator output). Change the generator or source definition instead.
- **NEVER run `dotnet test` on `src/tests/`** — silently reports "0 test projects". Use `src/tests/build.sh` + `src/tests/run.sh`.
- **NEVER use COMPlus_ env vars** — `DOTNET_` only.
- **Do not add config switches to `src/coreclr/inc/clrconfigvalues.h` sections marked "DO NOT ADD ANY MORE CONFIG SWITCHES"**; max 7 args for STRESS_LOG (no STRESS_LOG8+).
- **Do not modify layout-critical structs** — e.g. `host_interface.h` fields (layout is contract), `sbuffer.h` "NEVER BE FREED OR MODIFIED", `Thread.Mono.cs` "DO NOT RENAME! DO NOT ADD FIELDS AFTER!".
- **Do not bundle unrelated changes / drive-by refactors** — one concern per PR; large refactors get their own PR.
- **Do not add new public API without an approved proposal** (see `api-proposal` skill); keep `internal` until approved.
- **Do not copy code across CoreCLR/Mono/NativeAOT** — move to shared partition with `#if !MONO` where needed.
- Do not suppress warnings/errors (`as any`-style `#pragma warning disable` / `NoWarn`) to pass builds — fix root cause.

## COMMANDS

```bash
# Build (root) — subsets via -s, config via -c; see ./build.sh -h and -subset help
./build.sh                          # full repo, Debug, host platform (Windows: build.cmd)
./build.sh clr -c release           # CoreCLR only
./build.sh -subset clr+libs -configuration Release
./build.sh clr.runtime -arch arm64 -c release -cross   # cross-compile (needs ROOTFS_DIR)
./build.sh -subset help             # list all subsets

# Test
./build.sh clr+libs+libs.tests -rc checked -lc release -test   # build + run tests
src/tests/build.sh -h               # CoreCLR test tree build (NOT dotnet test)
src/tests/run.sh x64 checked        # run CoreCLR tests
# Library tests: cd src/libraries/<Pkg>/tests && dotnet build /t:Test
#   single method: /p:XunitMethodName=Ns.Class.Method
#   single class:  /p:XUnitOptions="-class Ns.Class"
#   outer loop:    /p:TestScope=outerloop

# Format / lint
python3 src/coreclr/scripts/jitformat.py -r . -o linux -a x64   # JIT C++ format (CI-enforced)
markdownlint "**/*.md"               # enforced in CI (MD009 only)
# Warnings-as-errors default ON; disable: TreatWarningsAsErrors=false
```

Authoritative docs: `docs/workflow/README.md` (build/test/CI), `.github/skills/build-and-test/SKILL.md` (MANDATORY read before any build/test).

## NOTES / GOTCHAS

- Baseline build is REQUIRED before incremental builds/tests — missing it causes "missing testhost"/"shared framework" errors. Under CCA always build baseline first; under CLI check `baseline sentinel` first.
- CI is Azure DevOps (`eng/pipelines/`); GitHub Actions is secondary (bot automation + jit-format/markdownlint checks).
- Library solutions are generated by `src/libraries/GenerateLibrariesSln.ps1`; no single root `.sln`.
- Build outputs go to `artifacts/`; the local SDK bootstraps into `.dotnet/` via `dotnet.sh` (never system dotnet).
- Shared managed source lives in `src/libraries/Common/` (pulled via `$(CommonPath)`/`$(CommonTestPath)` Compile Include, not project refs).
- `src/libraries/System.Private.CoreLib` is the runtime's core library; each runtime (coreclr/mono) also has its own copy.
- Mono uses different build subsets and host configurations than CoreCLR — see `docs/workflow/building/mono/README.md` and `src/mono/README.md`.
- Test tree subdirs each have their own README.md with area-specific authoring/run guidance — read before touching.
