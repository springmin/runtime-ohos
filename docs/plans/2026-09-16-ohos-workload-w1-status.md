# OpenHarmony platform workload — W1 status (2026-09-16)

## What was built
`~/springsources/ohos-workload/` (git repo, commit `8b73612`) — a local, DevEco-less
platform workload following the dotnet/android model:

```
manifests/{11.0.100,11.0.100-rc.1}/microsoft.net.sdk.openharmony/
    WorkloadManifest.json        workload `openharmony`; packs:
                                   Microsoft.OpenHarmony.Sdk (kind sdk)
                                   Microsoft.OpenHarmony.Ref.20.0 (kind framework)
                                   Microsoft.OpenHarmony.Runtime.20.0.openharmony-arm64 (kind framework)
    WorkloadManifest.targets     unconditionally imports Sdk.targets of the platform pack
    WorkloadDependencies.json    declares the OpenHarmony SDK as the external toolchain
packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.1/
    Sdk/Sdk.targets              gated on TargetPlatformIdentifier == openharmony:
                                   TargetPlatformSupported=true, TargetPlatformDisplayName,
                                   SupportedOSPlatformVersion (default 20.0),
                                   SdkSupportedTargetPlatformIdentifier openharmony,
                                   SdkSupportedTargetPlatformVersion 20.0 / 26.0,
                                   FrameworkReference Microsoft.OpenHarmony,
                                   KnownFrameworkReference (version-only TFM net11.0,
                                   TargetingPackName Microsoft.OpenHarmony.Ref.<TargetPlatformVersion>,
                                   RuntimePackNamePatterns Microsoft.OpenHarmony.Runtime.<ver>.**RID**,
                                   RuntimePackRuntimeIdentifiers openharmony-arm64),
                                   host-model defaults (UseAppHost=false, SelfContained=true, ...)
    targets/*.props              placeholders (SupportedPlatforms / BundledVersions / DefaultProperties)
packs/Microsoft.OpenHarmony.Ref.20.0/1.0.0-preview.1/
    ref/net11.0/Microsoft.OpenHarmony.dll     thin surface (assembly-level
                                              SupportedOSPlatform("openharmony20.0") + IsOpenHarmony)
    data/FrameworkList.xml
packs/Microsoft.OpenHarmony.Runtime.20.0.openharmony-arm64/1.0.0-preview.1/
    laid out from the released Microsoft.NETCore.App.Runtime.openharmony-arm64 package
test/hello-lib/                  net11.0-openharmony20.0 classlib
scripts/env.sh                   exports DOTNETSDK_WORKLOAD_MANIFEST_ROOTS / _PACK_ROOTS
```

## Verified
- **First successful platform-TFM build** (device SDK untouched, env-root mounting only):
  `dotnet build` → `hello-lib -> bin/Debug/net11.0-openharmony20.0/hello-lib.dll` (Build succeeded).
- Both band forms (`11.0.100` for release SDKs, `11.0.100-rc.1` for the preview SDK) are present;
  the band directory name must match the SDK feature band.

## Wiring facts discovered (each was an SDK error first)
| SDK error | Requirement | Where implemented |
|---|---|---|
| NETSDK1139 | platform must set `TargetPlatformSupported=true`; the manifest targets import the platform pack, whose `Sdk.targets` is imported deferred (so it can gate on `TargetPlatformIdentifier`) | pack `Sdk/Sdk.targets` |
| NETSDK1147 | the pack ids in `WorkloadManifest.json` must resolve under `<pack root>/packs/<id>/<version>`; `DOTNETSDK_WORKLOAD_PACK_ROOTS` points at a *dotnet-root-like* dir (it contains `packs/`) | layout + env |
| NETSDK1140 | the platform pack must declare `SdkSupportedTargetPlatformVersion` items | pack `Sdk/Sdk.targets` |
| MSB4018 (NRE in `ResolveTargetingPackAssets`) | targeting pack requires `data/FrameworkList.xml`; every `<File>` needs `AssemblyName`, `PublicKeyToken` (non-null; empty for unsigned), `AssemblyVersion`, `FileVersion` | ref pack |
| — | `KnownFrameworkReference` with a version-only `TargetFramework` and platform-gated definition resolves the ref/runtime packs for the platform TFM | pack `Sdk/Sdk.targets` |

## In progress / next
- `dotnet publish -r openharmony-arm64` validation: the released runtime pack is being
  fetched (resumable + sha256 `b9fff88a…`, background `w1-finish.sh`), then laid out and
  the publish output inspected.
- **W2**: NAPI host (hostfxr/CoreCLR), ArkTS shell template, and the MSBuild
  `publish → .hap` target (reusing the validated `ohos_packing_tool` + `hap-sign-tool` chain
  and the `maui-ohos-p0` probe project as the template).
- MAUI: switch `maui-openharmony` to `extends: [ "maui-blazor", "openharmony" ]` once this
  workload is stable.
