# OpenHarmony platform workload — W11 status (2026-09-17)

W11 brings up the renderer path over the XComponent surface.

## Drawing bridge (native_drawing, Skia-backed)
The host library exposes an immediate-mode canvas implemented with the platform's
`native_drawing` API (the Skia-backed OHOS 2D library):

| Host API | Purpose |
|---|---|
| `ohos_host_draw_begin(w, h)` | creates/reuses an `OH_Drawing_Bitmap` + `OH_Drawing_Canvas` sized to the surface |
| `ohos_host_draw_clear(argb)` | clears the canvas |
| `ohos_host_draw_rect(x, y, w, h, argb, filled)` | fill/stroke rectangle (brush/pen) |
| `ohos_host_draw_text(x, y, utf8, size, argb)` | text via `OH_Drawing_TextBlobCreateFromString` |
| `ohos_host_draw_present()` | blits the bitmap into the `OHNativeWindow*` buffer (row-copy respecting `stride`) and flushes |

Managed surface: `Microsoft.OpenHarmony.Hosting.OpenHarmonyCanvas`
(`Begin/Clear/FillRect/StrokeRect/DrawText/Present`, plus `DrawDemoFrame`).
`hello-app` draws the demo frame (background, bars, translucent box, two labels) when the
surface is created, and logs both `FillSurface` and `DrawDemoFrame` results into its status
file.

This is the rendering entry point a `Microsoft.Maui.Graphics` backend maps onto:
`ICanvas.FillRectangle/StrokeRectangle/DrawString` -> the calls above; paths and curves are
the next addition (`OH_Drawing_Path`), then the Skia GPU path
(`OH_Drawing_GpuContext` + backend render target) once a device validates the CPU path.

## Releases
- Workload `1.0.0-preview.3` (manifest/packs/scripts and pack content aligned), published as
  `workload-1.0.0-preview.3`, refreshed rolling `workload-latest`, attached to the SDK
  release `v11.0.100-rc.1.26451.109-openharmony`.
- Reinstalled into the device SDK; UI hap build + `verify-app` succeed with no
  `DOTNETSDK_WORKLOAD_*` environment variables; the installed host library carries the
  drawing symbols.

## Next (W12)
- `OH_Drawing_Path` (paths/curves) and image drawing, then a thin
  `Microsoft.Maui.Graphics` `ICanvas` implementation over `OpenHarmonyCanvas`.
- First MAUI handlers (Label/Button/Layout) on top; input events through
  `OH_NativeXComponent` touch callbacks.
- Device validation of the surface handshake + demo frame (needs an install-eligible device).
