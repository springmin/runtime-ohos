# .NET Libraries

## OVERVIEW
The .NET class libraries: ~218 packages of managed code (~156 System.*, ~57 Microsoft.*), shared Common/ source, and System.Private.CoreLib, the runtime core library.

## STRUCTURE
- Each package (e.g. `src/libraries/System.Text.Json/`) holds its own `src/` (implementation), `ref/` (contract), `tests/`, plus optional `Common/`, `gen/`, `docs/`, `*.slnx`.
- `src/libraries/Common/` holds shared source (`src/` + `tests/`): `Interop/`, `System/`, `Microsoft/`, `Internal/`, `Polyfills/`, `SourceGenerators/`. Shared code is pulled into projects via `$(CommonPath)`/`$(CommonTestPath)` Compile Include globs, NOT project references.
- `src/libraries/System.Private.CoreLib/` is the runtime's core library. CoreCLR and Mono each keep their own copy of this library; changes here must consider parity across runtimes.

## WHERE TO LOOK
| Task | Path |
|------|------|
| Implementation of package X | `src/libraries/<Pkg>/src/` |
| Contract/reference assembly | `src/libraries/<Pkg>/ref/` |
| Unit tests for package X | `src/libraries/<Pkg>/tests/` |
| Shared cross-package source | `src/libraries/Common/src/` (tests: `Common/tests/`) |
| Shared interop declarations | `src/libraries/Common/src/Interop/` |
| Shared source generators | `src/libraries/Common/src/SourceGenerators/` |
| Runtime core library | `src/libraries/System.Private.CoreLib/` |

## CONVENTIONS
- Package layout: `src/` = implementation, `ref/` = reference assembly, `tests/` = unit tests. Solutions are generated per area by `GenerateLibrariesSln.ps1`; there is no checked-in root solution.
- `ref/` assemblies: no `using` directives, fully-qualified types, empty bodies or `throw null`, genapi formatting, members in alphabetical order. Regenerate with genapi; never hand-edit.
- Tests use xUnit with `Microsoft.DotNet.XUnitExtensions` traits: `[OuterLoop]`, `[PlatformSpecific(TestPlatforms.*)]`, `[ActiveIssue(...)]`, `[SkipOnPlatform]`.
- Test folders commonly split by kind: `UnitTests/`, `FunctionalTests/`, `EnterpriseTests/`, `ManualTests/`, `NlsTests/`, `PalTests/`, `SourceGenerationTests/` (with Roslyn version variants). Filter runs with `TestScope`, `WithCategories`, `WithoutCategories` MSBuild props.
- Prefer adding tests to existing test files; prefer `[Theory]` over duplicative `[Fact]`s.
- Area conventions: read the matching `.github/instructions/` file before changing code: `extensions-*.instructions.md` (DI/Configuration/Logging/Hosting/Options/Caching), `system-net-*.instructions.md` (http/quic/sockets/security/interop), `system-security-cryptography.instructions.md`, `compression.instructions.md`.

## ANTI-PATTERNS
- Don't suppress warnings/errors to pass builds; fix the root cause.
- Don't scatter per-file analyzer suppressions; severities are centralized in `eng/CodeAnalysis.src.globalconfig` / `eng/CodeAnalysis.test.globalconfig`.
- Don't add new public API without an approved proposal (`api-proposal` skill); keep it internal until approved.
- New public APIs need XML docs (see `.github/prompts/docs.prompt.md`).
- Don't copy code across CoreCLR/Mono/NativeAOT; move it to a shared partition with `#if !MONO` where needed.
- Don't hand-edit generated files (e.g. genapi output under `ref/`).

## BUILD/TEST
```bash
./build.sh -subset libs -configuration Release        # build all libraries
./build.sh -subset clr+libs -configuration Release     # clr + libs
cd src/libraries/<Pkg>/tests && dotnet build /t:Test   # test one package
# single method: /p:XunitMethodName=Ns.Class.Method
# single class:  /p:XUnitOptions="-class Ns.Class"
# outer loop:    /p:TestScope=outerloop
```
