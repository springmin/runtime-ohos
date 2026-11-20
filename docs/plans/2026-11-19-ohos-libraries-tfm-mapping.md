# OpenHarmony library TFM mapping — status and exit criteria

Context: `dotnet/runtime#136186` proposed `LibrariesOpenHarmonySfxTfm` (map the
OpenHarmony shared framework + shims onto the **linux** TFM group). It was
reviewed by `jkotas` and closed:

> FreeBSD and other OSes do not have platform TFM either and work just fine.
> There should not be any special casing for open harmony like this.

The reviewer's position is that OpenHarmony should follow the standard
`$(NetCoreAppCurrent)-$(TargetOS)` path, and that any real incompatibility must
be fixed in the specific component, not papered over with a global mapping.

## What the fork carries today

| File | Line | Content |
|---|---|---|
| `src/libraries/Directory.Build.props` | 19 | `LibrariesOpenHarmonySfxTfm = $(NetCoreAppCurrent)-linux` when `TargetsOpenHarmony` |
| `src/libraries/Directory.Build.targets` | 94 | `LibrariesBinPlaceTfm` uses the mapped value |
| `src/libraries/sfx.proj` | 5-6 | `TargetFramework` mapped |
| `src/libraries/sfx-src.proj` | 5-6 | `TargetFramework` mapped |
| `src/libraries/sfx-finish.proj` | 7-8 | `TargetFramework` mapped |
| `src/libraries/shims/Directory.Build.props` | 8-11 | shims compile in the same group |
| `src/libraries/System.Console/src/System.Console.csproj` | - | unix `ConsolePal` + scoped CA1416 suppression |

## Why it is still here

The fork builds the SDK/workload artifacts that the GA gate (`ohos-clean-machine`)
consumes; the mapping is what puts the shared framework and shims into the layout
that `ohos-workload` packs. Removing it without an alternative breaks the layout.

## Exit criteria (when this mapping can be deleted)

1. The OpenHarmony build line works with the standard
   `$(NetCoreAppCurrent)-$(TargetOS)` selection — i.e. `TargetsOpenHarmony`
   no longer needs a TFM remap; **or**
2. A real `-openharmony` platform TFM exists end to end (NuGet.Frameworks
   platform registration + `dotnet/sdk` supported-platform list + runtime packs);
3. In that state the `System.Console.csproj` comment about removing the CA1416
   suppression once a platform TFM exists also resolves.

## How to remove it safely (per-component, FreeBSD model)

Do not delete the property first. Instead:

1. Build `libs` (and `sfx`) with the standard path and capture the layout diff:
   ```bash
   ./build.sh libs -c release -arch arm64 -os openharmony
   diff -r <old layout> <new layout>
   ```
2. For every missing/misplaced file, fix the component that owns it:
   - shims → `src/libraries/shims/Directory.Build.props`
   - console → `System.Console.csproj` pal selection
   - sfx → `sfx*.proj` TFM/binplace
3. Only when the layout matches with no OpenHarmony-specific properties, delete
   `LibrariesOpenHarmonySfxTfm` and the `LibrariesBinPlaceTfm` override.

## Upstream state

- `#136194` (native fixes incl. System.Native / OpenSSL shim) — **merged**
  (`c54062f2a75b82a5b6baebb0caf41481679cdc1c`).
- `#136186` (this mapping) — **closed by design**, do not resubmit as-is.
- `#136206` (CI build leg for OpenHarmony arm64) — still open.
