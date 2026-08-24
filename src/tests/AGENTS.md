# Runtime Tests

## OVERVIEW
CoreCLR/runtime test tree (~17,417 files). Tests exercise the RUNTIME itself: JIT, GC, EE, interop, threading, tracing. Managed library tests live in `src/libraries/<Pkg>/tests/`, NOT here.

## CRITICAL: BUILD/RUN VIA src/tests SCRIPTS
- NEVER run `dotnet test` in this tree: it silently reports "0 test projects" or fails to find testhost.
- Build with `src/tests/build.sh` (Windows: `build.cmd`), run with `src/tests/run.sh <arch> <config>` (e.g. `src/tests/run.sh x64 checked`; `run.cmd` on Windows).
- `src/tests/build.sh -h` for the full flag list. Root-level build subset flags live in the root AGENTS.md COMMANDS section; don't repeat them here.

## STRUCTURE
Top-level areas. Most subdirs have their own README.md with area-specific authoring/run guidance: READ it before touching anything in that subdir.
- JIT/: CodeGenBringUpTests, IL_Conformance, SIMD, Methodical, jit64, ...
- GC/: incl. Scenarios/GCSimulator. GC stress tests usually require the Checked config.
- Interop/: PInvoke.
- Loader/, Exceptions/, baseservices/, Regressions/, FunctionalTests/
- async/, nativeaot/, readytorun/, tracing/, reflection/
- Common/: shared infra. Assert.cs, CoreCLRTestLibrary, CLRTest.*.targets (CrossGen, Execute, GC, Jit, MockHosting, CoreRootArtifacts).
- Root support: CMakeLists.txt (native tests), build.proj, MergedTestRunner.targets, Directory.Build.props/targets.

## WHERE TO LOOK
| Task | Path |
|------|------|
| JIT coverage | JIT/ (CodeGenBringUpTests, IL_Conformance, SIMD, Methodical) |
| GC / GC stress | GC/ (incl. Scenarios/GCSimulator) |
| P/Invoke interop | Interop/ |
| Assembly loading | Loader/ |
| Exceptions | Exceptions/ |
| Runtime basics / regressions | baseservices/, Regressions/, FunctionalTests/ |
| Async | async/ |
| NativeAOT | nativeaot/ |
| ReadyToRun | readytorun/ |
| EventPipe / tracing | tracing/ |
| Reflection | reflection/ |
| Shared test helpers | Common/ |
| Authoritative workflow docs | docs/workflow/testing/coreclr/testing.md (Core_Root setup, single-test builds, corerun), test-configuration.md, requiresprocessisolation.md, disasm-checks.md, gc-stress-run-readme.md |

## CONVENTIONS
- Tests with `<CLRTestPriority>1</CLRTestPriority>` require `-priority1` at build (bash) or `-Priority 1` (Windows). Without it the build silently reports "0 test projects".
- Build one project: `src/tests/build.sh -Test <path>`.
- Build a subtree recursively: `src/tests/build.sh -Tree <path>`.
- `-GenerateLayoutOnly`: produces Core_Root only. Required before running individual tests with corerun.
- Follow the per-subdir README authoring conventions: layout differs by area (flat files vs per-test subdirs). Don't invent a new layout.
- `.github/instructions/tests.instructions.md` applies automatically here, plus `conventions.instructions.md`.

## ANTI-PATTERNS
- NEVER `dotnet test` in this tree.
- Don't commit `.baseline` / golden output churn without intent.
- Don't add tests that require the .NET Framework host unless that is the point of the test.
- Pick the build config deliberately for GC/JIT tests (e.g. Checked for GC stress); don't default to Debug without checking the subdir README.
- Keep runtime tests here, library tests in src/libraries. Don't copy patterns across CoreCLR/Mono.

## COMMANDS
```bash
src/tests/build.sh -priority1          # priority-1 tests (required for <CLRTestPriority>1)
src/tests/build.sh -Test <path>        # single project
src/tests/build.sh -Tree <path>        # subtree recursively
src/tests/build.sh -GenerateLayoutOnly # Core_Root only; run individual tests with corerun
src/tests/run.sh x64 checked           # run tests (run.cmd on Windows)
```
Full flag reference: `src/tests/build.sh -h`. Repo-level build flags: see root AGENTS.md.
