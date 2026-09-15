# OpenHarmony platform identity — how `IsOSPlatform("openharmony")` should work

**Date:** 2026-09-15
**Status:** decision record for the port (S1b + runtime follow-ups)
**Related:** `2026-09-07-ohos-pr-plan-bsd-haiku-model.md` (S1b, N15),
`2026-09-01-ohos-syscall-audit.md`, PR dotnet/runtime#132827 (review thread
`discussion_r4011019803`), the CA1418 probe in
`final-evidence/` (device-verified 2026-09-15).

## Question

`OperatingSystem.IsOSPlatform("openharmony")` is the API the runtime reviewer
asked for (instead of RID-string checks). `openharmony` was not a "known
platform" for the platform-compatibility analyzers, so using it in src code
fails warnings-as-errors (CA1418). How should this be implemented — modeled on
how macOS is handled?

## macOS: platform identity is five layers

| Layer | macOS | Where |
|---|---|---|
| 1. Compile-time define | `TARGET_OSX` from `TargetsOSX` (`TargetOS == 'osx'`) | `eng/RuntimeIdentifier.props:60` -> `System.Private.CoreLib.Shared.projitems:43` |
| 2. CoreLib platform name | `OSPlatformName = "OSX"` | `OperatingSystem.cs` const chain |
| 3. Name alias | `IsOSPlatform(string)` additionally accepts `MACOS` under `#if TARGET_OSX` | `OperatingSystem.cs` (OSPlatformName is `OSX`, analyzer/attributes use `macos`) |
| 4. Guard API | `IsMacOS()` + `IsMacOSVersionAtLeast(...)`, registered in the ref surface | `System.Runtime/ref/System.Runtime.cs:4976-4977` |
| 5. Analyzer / compat layer | TFM `net11.0-macos` -> `TargetPlatformIdentifier=macos`; SDK `Microsoft.NET.SupportedPlatforms.props` lists macOS; runtime `eng/versioning.targets:118-124` adds `SupportedPlatform` items for niche platforms (OpenBSD/illumos/Solaris/Haiku) | CA1418's known-platform set = guard methods in the TFM ref assemblies **union** the project's MSBuild `SupportedPlatform` items |

Key mechanism (docs + device-verified): CA1418 accepts an unknown name when the
project declares it:

```xml
<ItemGroup>
  <SupportedPlatform Include="openharmony" />
</ItemGroup>
```

## OHOS today: layers 1-2 done, 4-5 open

| Layer | State | Notes |
|---|---|---|
| 1 | done | `TARGET_OPENHARMONY` (`Shared.projitems:57` <- `eng/RuntimeIdentifier.props:57`) |
| 2 | done (2026-09-15) | `OSPlatformName = "OPENHARMONY"` (PR #132827); comparison is case-insensitive |
| 3 | not needed | single canonical name; `ohos` was deliberately retired by the rename |
| 4 | open (optional) | public `IsOpenHarmony()` does not exist (only the internal helper from #132827) |
| 5 | open | no OHOS TFM (N15 maps libraries to linux/unix) -> analyzer does not know `openharmony` -> CA1418 in src projects; test projects are exempt (`CodeAnalysis.test.globalconfig` sets CA1418 = none) |

## Decision

**方案 A — use `IsOSPlatform("openharmony")` plus a `SupportedPlatform` item.**
Applied to S1b (`OpenHarmonyEnvironmentDefaults`); the item goes into the CLI
projects that compile it (the SDK has no OHOS TFM, so the analyzer layer is
handled by the item rather than by a TFM).

**方案 B — macOS-parity follow-up (after the platform is accepted upstream).**
Add a public `OperatingSystem.IsOpenHarmony()` (implementation under
`#if TARGET_OPENHARMONY`, ref registration in
`System.Runtime/ref/System.Runtime.cs`, api-proposal/API review, tests) and add
`openharmony` to the SDK's `Microsoft.NET.SupportedPlatforms.props`. Also add
the `SupportedPlatform` entry to runtime's `eng/versioning.targets` when a
runtime src project first needs `IsOSPlatform("openharmony")`.

**Not doing:** an `ohos` alias (rename is settled), `OSPlatform.OpenHarmony`
(Android/iOS precedent: guard method only; `OSPlatform.OSX` is legacy), and a
`net11.0-openharmony` TFM (a full platform TFM is out of scope for this port).

**方案 C (fallback):** `RuntimeInformation.IsOSPlatform(OSPlatform.Create("OPENHARMONY"))`
does not trigger CA1418; use only where adding the item is impossible.

## Device-verified evidence (2026-09-15)

- `OperatingSystem.IsOSPlatform("openharmony")` with `TreatWarningsAsErrors=true`
  -> `error CA1418` (src context).
- The same call with `<SupportedPlatform Include="openharmony" />`
  -> `Build succeeded`.
- `RuntimeInformation.IsOSPlatform(OSPlatform.Create("OPENHARMONY"))`
  -> no CA1418 (方案 C viable).
- `Path.GetTempPath()` honours `TMPDIR`; with `TMPDIR` unset it returns the
  read-only `/tmp` (write -> IOException) while the user home is writable —
  input for the S1b TMPDIR decision (see the plan's S1b row).

## Implementation checklist (S1b prep)

1. `OpenHarmonyEnvironmentDefaults.Apply()`: use
   `OperatingSystem.IsOSPlatform("openharmony")` (drop the RID-string check).
2. Add `<SupportedPlatform Include="openharmony" />` to the CLI projects that
   compile the file (`src/Cli/dotnet`, `src/Cli/dotnet-aot`; shared
   `src/Cli/Directory.Build.props` if it exists).
3. Resolve the `TMPDIR` default (hardcoded sandbox path must not go upstream —
   decide between fork-local wrapper export vs a derived writable path).
4. Neutralize fork-context wording in the class summary ("the wrapper script
   previously exported these").
5. Tests: make the platform decision injectable and add a unit test for the
   `SetDefault` semantics.

## Upstream path (方案 B) — sequencing

- runtime PR: public `IsOpenHarmony()` (+ version API only if OHOS reports a
  usable OS version) with ref + api-proposal;
- sdk PR: `openharmony` in `Microsoft.NET.SupportedPlatforms.props`;
- runtime `eng/versioning.targets`: `SupportedPlatform` entry when first needed;
- revisit only after the platform lands upstream (blocked on the tracking
  discussion in #132866).
