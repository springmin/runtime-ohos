# Build & Dev Tools

**Generated:** 2026-08-13
**Commit:** `811225a4827`
**Branch:** `main`

## OVERVIEW

Repo build/dev tooling: IL linker, IL assembler, stress log analyzer, Hot Reload delta generator. 2,187 files, mostly C#. Built as part of the toolchain via root subsets, not standalone.

## STRUCTURE

- `illink/`: IL linker (the big one, ~2k files). Trims unused code from managed assemblies; shared test cases also run against ILC, the ILLink analyzer, and ILTrim. Own Directory.Build.props/targets + README.
- `ilasm/`: IL assembler (ilasm -> PE/IL output). Own build files + README.
- `StressLogAnalyzer/`: CLR stress log analyzer (native+managed, parses StressLog output).
- `hotreload-delta-gen/`: Hot Reload delta generator (metadata/IL deltas for Edit and Continue).

Each subdir has its own Directory.Build.props/targets and, where relevant, a README.md. Read the subdir README before touching it.

## WHERE TO LOOK

| Task | Path |
|------|------|
| Linker behavior change | `illink/src/` (core logic under `illink/src/linker/`) |
| Linker tests | `illink/test/` (library-style, `dotnet test`) |
| Trimming shared test cases | `illink/test/TrimmingTests/` (also consumed by ILC/analyzer/ILTrim) |
| IL assembler work | `ilasm/` |
| Stress log analysis | `StressLogAnalyzer/` |
| Hot Reload deltas | `hotreload-delta-gen/` |
| Area conventions | `.github/instructions/illink.instructions.md` (applies to `src/tools/illink/test/**`, `src/coreclr/tools/ILTrim.Tests/**`, `src/coreclr/tools/aot/ILCompiler.Trimming.Tests/**`) |

## CONVENTIONS

- Read `.github/instructions/illink.instructions.md` before touching any trimming code or tests.
- Shared trimming test cases must pass in ALL applicable tools: ILLink, ILC, ILLink analyzer, and ILTrim.
- Unsupported ILTrim cases follow the existing expected-failure conventions in `illink.instructions.md`; do not invent new markers.
- A trimming change is validated by running the shared test cases through each tool that supports them, then confirming the expected-failure set for ILTrim is unchanged (or updated per convention).
- Warnings-as-errors is ON by default (root build flags apply; see root AGENTS.md `COMMANDS` for `-subset` usage and `TreatWarningsAsErrors=false` escape hatch).

## ANTI-PATTERNS

- Do not build these standalone in ad-hoc ways; they are built through root subsets (e.g. `tools.illink`). Use root `./build.sh -subset help` for the canonical subset names.
- Do not edit `eng/common/` (externally synced) from this tree.
- Do not hand-edit generated files (see root AGENTS.md ANTI-PATTERNS); change the generator or source definition instead.
- Do not duplicate trim test markers or expected-failure conventions across tools; keep them in the shared test cases.
- Do not add new public API without an approved proposal; keep `internal` until approved.

## BUILD / TEST

```bash
# Build the linker toolchain via root subset
./build.sh -subset tools.illink        # root-level; see root AGENTS.md for full flag set

# Linker tests: library-style (NOT src/tests/; use dotnet test)
cd src/tools/illink/test && dotnet build /t:Test

# Single test method/class:
cd src/tools/illink/test && dotnet build /t:Test /p:XunitMethodName=Ns.Class.Method
cd src/tools/illink/test && dotnet build /t:Test /p:XUnitOptions="-class Ns.Class"
```

Root `./build.sh` flags, subset list, and baseline-build requirements live in the root AGENTS.md; do not duplicate them here.
