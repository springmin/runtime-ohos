# OpenHarmony platform workload — W12 status (2026-09-17)

W12 adds the Microsoft.Maui.Graphics canvas backend on top of the platform drawing bridge.

## Backend
`ohos-workload/src/Microsoft.OpenHarmony.Maui.Graphics/` implements
`Microsoft.Maui.Graphics.ICanvas` over `Microsoft.OpenHarmony.Hosting.OpenHarmonyCanvas`:

| ICanvas area | Implementation |
|---|---|
| rectangles / rounded rectangles / ellipses / arcs / lines | mapped to the native polyline primitive (`ohos_host_draw_polyline`); arcs and rounded corners are sampled |
| paths (`PathF`) | flattened with `PathF.GetFlattenedPath(0.25f)` and drawn as one polyline (`DrawPath`/`FillPath`) |
| text | `DrawString` (both overloads incl. the `TextFlow` one) via `OH_Drawing_TextBlob`; `GetStringSize` returns an approximation until platform metrics are wired |
| transforms | `SaveState`/`RestoreState`/`Translate`/`Scale`/`Rotate`/`ConcatenateTransform` tracked in managed `Matrix3x2` and applied to points |
| clipping, shadows, gradients (`SetFillPaint`), images | documented no-ops (the bridge does not expose them yet) |
| colors/alpha/line caps/joins | tracked; ARGB conversion honours `Alpha` |

The project builds against `Microsoft.Maui.Graphics 11.0.0-rc.1.26451.6` (the same version as
this runtime) and ships in the platform runtime packs, so published apps carry it.

## Verified
- Backend builds clean (`dotnet build`), `hello-app` references it and draws an `ICanvas`
  frame on the surface (fill rectangle, ellipse, string) in addition to the native demo.
- Workload `1.0.0-preview.4` published (versioned + rolling `workload-latest` + SDK release
  attachment), reinstalled into the device SDK; UI hap (with the graphics stack in the
  payload) builds and `verify-app` succeeds with no `DOTNETSDK_WORKLOAD_*` variables.
- Device regression of the lifecycle bridge still passes (`registered=True`, exit 0).

## Next (W13)
- Platform text metrics (`OH_Drawing_TextBlob` bounds) and clipping/`OH_Drawing_CanvasClipRect`,
  plus `DrawImage` (bitmap/pixelmap) to complete the ICanvas surface.
- First MAUI handlers (Label/Button/Layout) over the backend; input via
  `OH_NativeXComponent` touch callbacks.
- ONNX: move `Microsoft.OpenHarmony.Maui.Graphics` into the MAUI fork's Graphics slice when
  the platform build there is wired (same sources, `OPENHARMONY` guarded).
