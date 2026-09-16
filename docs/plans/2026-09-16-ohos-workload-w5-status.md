# OpenHarmony platform workload — W5 status (2026-09-16)

W5 makes the platform workload installable and closes the MAUI auto-detection loop.

## Installable workload
- `scripts/pack-local-workload.sh` packs the six workload packs into nupkgs (local feed,
  no network needed).
- Installation (verified on the device SDK root):

  ```sh
  ./scripts/pack-local-workload.sh
  cp -r manifests/11.0.100-rc.1/microsoft.net.sdk.openharmony ~/.dotnet/sdk-manifests/11.0.100-rc.1/
  dotnet workload install openharmony --skip-manifest-update --source .feed
  dotnet workload list          # -> openharmony 1.0.0-preview.1/11.0.100-rc.1
  ```

  After that, `dotnet build` and `dotnet publish -r openharmony-arm64` work for
  `net11.0-openharmony20.0` / `…26.0` **without** `DOTNETSDK_WORKLOAD_MANIFEST_ROOTS` /
  `…_PACK_ROOTS` (verified: library build succeeded, publish produced 198 files).
  Uninstall: `dotnet workload uninstall openharmony` plus removing the manifest directory.
- Note: a *symlinked* dotnet root does not work for installation — the muxer resolves the
  SDK through the real path, so the workload must live in the root that owns the SDK.
- The nupkg packer skips NuGet metadata files (a package may only contain one `.nuspec`;
  extracted runtime packs carry the original one).

## MAUI auto-detection
MAUI's OpenHarmony detection had two problems for Linux/HarmonyOS hosts:
1. `DotNetWorkloadInstallLocation` was only set when the **macOS** workload manifest was
   present, so OpenHarmony could never be detected off Windows/macOS.
2. Even after that, the block needed to be band-agnostic.

It now locates the platform manifest through `sdk-manifests/*` wildcards (DOTNET_ROOT, then
ProgramFiles) and derives the packs directory from it. Verified in an isolated evaluation of
the block:
- installed root -> `DotNetOpenHarmonyWorkloadInstalledVersion=1.0.0-preview.1`,
  `DotNetOpenHarmonyWorkloadIsInstalled=true`, `IncludeOpenHarmonyTargetFrameworks=true`;
- empty root / root without the manifest -> all empty, no MSBuild errors.
Together with the platform pack's `Sdk/AutoImport.props` (the file MAUI probes), the MAUI
`maui-openharmony` chain now lights up automatically once the platform workload is installed.

## Next
- Make the platform workload part of the fork's SDK layout (so it ships with the SDK), or
  publish the manifest/packs as a proper NuGet feed entry.
- Start the MAUI platform slice (Microsoft.Maui.Controls for openharmony) on top of the
  lifecycle bridge and the UI page path from W4.
