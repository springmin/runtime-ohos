# OpenHarmony platform workload — W9 status (2026-09-16)

W9 delivers the rendering surface handshake: the ArkUI `XComponent` surface reaches the
managed application.

## Surface path
```
ArkUI page (pages/Index.ets)
  XComponent({ id: 'ohos_dotnet_surface', type: SURFACE, libraryname: 'openharmonyhost' })
    .onLoad(() => host.registerXComponent())
        |
        v
libopenharmonyhost.so (host_napi.cpp)
  OH_NATIVE_XCOMPONENT_OBJ unwrap -> OH_NativeXComponent_RegisterCallback
  OnSurfaceCreated/Changed/Destroyed -> OH_NativeXComponent_GetXComponentSize
                                     -> ohos_host_set_native_window(window, w, h, state)
        |
        v
Microsoft.OpenHarmony.Hosting
  OpenHarmonyBridge.SurfaceChanged / .Surface  ->  OpenHarmonySurfaceInfo
      { IntPtr Window /* OHNativeWindow* */, Width, Height, State }
```
- The page stacks the `XComponent` (the render target for Skia/MAUI) with the existing
  `ContentSlot` (native ArkUI nodes attached by managed code through `NodeContent`).
- The bridge registration now carries three callbacks (lifecycle, node, surface); the
  surface callbacks are replayed to late subscribers like the lifecycle events.
- `hello-app` logs surface events into its status file, so an installed run shows the
  handshake (`surface Created <w>x<h> window=0x...`).

## Verified
- The ArkTS shell with the XComponent compiles with the official toolchain
  (`scripts/build-arkts-shell.sh` -> `dist/ets/modules.abc`, 11,956 bytes).
- UI hap: `modules.abc` + `main_pages.json = ["pages/Index"]` + the self-signed host
  library; `verify-app` succeeds.
- Device regression: the host library with the new three-callback registration still runs
  the lifecycle bridge (`registered=True`, Create..Destroy, exit 0).

Not yet validated (needs an installable device): the actual surface callback delivery and
the native-window rendering. The next step plugs a renderer into
`OpenHarmonyBridge.SurfaceChanged` (Skia over the OHNativeWindow*, or EGL/Vulkan surface
creation from it) and drives a first frame.

## Next (W10)
- Renderer bring-up on the surface (Skia/EGL) with a visible test pattern.
- MAUI platform slice on top of the lifecycle bridge + surface.
