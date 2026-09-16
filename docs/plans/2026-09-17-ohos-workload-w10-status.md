# OpenHarmony platform workload — W9 completion + W10 status (2026-09-17)

## W9 gaps filled
| Gap | Resolution |
|---|---|
| Prebuilt UI shell not shipped | The SDK pack now carries `templates/ets/modules.ui.abc` (official ArkTS toolchain, ability + `XComponent` page). `-p:OpenHarmonyUIPage=pages/Index` selects it automatically; `OpenHarmonyArktsModulesAbc` still overrides. |
| Windows signing path | `templates/scripts/sign-hap.ps1` mirrors the POSIX script; the packaging target picks it on Windows (`$([MSBuild]::IsOSPlatform('Windows'))`). |
| Platform constant for the MAUI slice | The platform pack defines `OPENHARMONY` / `__OPENHARMONY__` for OpenHarmony projects; the MAUI fork defines `OPENHARMONY` in its platform block. |
| MAUI slice start | `maui-ohos/docs/openharmony-platform-slice.md` records the bridge surface (lifecycle, `NodeContent`, `SurfaceChanged`, `FillSurface`) and the planned slice layout/handlers. |

## W10: renderer bring-up
- The host draws a **first frame** (RGBA gradient) into the `XComponent` surface when it is
  created/changed — the `XComponent -> OHNativeWindow* -> buffer -> flush` path.
- New managed-driven frame API: `ohos_host_fill_surface(argb)` /
  `OpenHarmonyBridge.FillSurface(uint argb)`; `hello-app` fills the surface on
  `SurfaceChanged(Created)`, proving managed -> native -> surface control. A real renderer
  (Skia over the `OHNativeWindow*`) replaces this call.
- `hello-app` logs both the surface handshake and the fill result into its status file.

## Missed optionals audit (from the session backlog)
| Item | Status |
|---|---|
| F3 (sdk `OpenHarmonyEnvironmentDefaults` nitpicks) | already compliant: the TMPDIR comment documents the deliberate absence; no hardcoded path remains in the defaults |
| F4 (aspnetcore RID ordering) | **fixed**: `openharmony-x64;openharmony-arm64` appended after the last OS block in `Directory.Build.props`, and the `Dependencies.props` entries moved after the `haiku` ones |
| `sign-ohos-pre.py` dead `has_codesign()` | **removed** (sign_elf always re-signs with `--force`) |
| Windows signing | **added** (see above) |
| BCL completeness (`OSPlatform.OpenHarmony`, public `OperatingSystem.IsOpenHarmony()`, `SupportedOSPlatform("openharmony")`) | the runtime fork has an *internal* `OperatingSystem.IsOpenHarmony()` (#132827); the **public** API needs an upstream API proposal, so user code gets the helper from the workload (`OpenHarmonyRuntime.IsOpenHarmony` in `Microsoft.OpenHarmony.dll`), and `SupportedOSPlatform("openharmony<api>")` is analyzer-clean because the workload declares the platform (`SdkSupportedTargetPlatformIdentifier`) |
| Post-merge cleanups (TLS line-667 deletion, shims TFM special case, illink PR) | still gated on upstream merges (#132953 / #132866) — unchanged |
| Runtime-build TODOs (shims TFM alignment, `CoreCLR.sfxproj` empty nupkg, PGO mibc on clean builds) | need the runtime build environment/CI — unchanged, tracked in `2026-09-02-cxx-runtime-handoff.md` |

## Releases
- `workload-1.0.0-preview.2` (bundle `openharmony-workload-1.0.0-preview.2.tar.gz`),
  rolling `workload-latest`, and the same asset attached to the SDK release
  `v11.0.100-rc.1.26451.109-openharmony`.
- Installed into the device SDK and verified end-to-end with **no**
  `DOTNETSDK_WORKLOAD_*` environment variables: UI hap build + `verify-app success`,
  `fill_surface` present in the installed host library.

## Next (W11)
- Skia over the `OHNativeWindow*` (CPU path first) as the `Microsoft.Maui.Graphics`
  backend for `OPENHARMONY`; then the first MAUI handlers (Label/Button/Layout).
- Install-eligible device: confirm the surface handshake and the first frame visually.
