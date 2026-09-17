# OpenHarmony platform workload — W13 status (2026-09-17)

W13 completes the `ICanvas` semantics that were previously approximations or no-ops.

## New platform capabilities
| Host API | Implementation |
|---|---|
| `ohos_host_measure_text` | `OH_Drawing_FontMeasureText` + `OH_Drawing_FontGetMetrics` (width/height in px) |
| `ohos_host_draw_save` / `ohos_host_draw_restore` | `OH_Drawing_CanvasSave/Restore` (pairs with the managed transform stack) |
| `ohos_host_draw_clip_rect` | `OH_Drawing_CanvasClipRect` with `INTERSECT`/`DIFFERENCE` |
| `ohos_host_draw_clip_polyline` | `OH_Drawing_CanvasClipPath` over a flattened polygon |
| `ohos_host_draw_image_bytes` | `OH_ImageSourceNative_CreateFromData` -> `CreatePixelmap` -> `OH_Drawing_CanvasDrawPixelMapRect`, with release of the native objects |

## Backend changes (`Microsoft.OpenHarmony.Maui.Graphics`)
- `GetStringSize` now returns real platform metrics (falls back to the estimate only when
  the native measurement is unavailable).
- `ClipRectangle` / `SubtractFromClip` / `ClipPath` are native clips; `SaveState` /
  `RestoreState` / `ResetState` keep the native canvas stack in sync.
- `DrawImage(IImage, ...)` encodes the image to PNG bytes and draws them through the
  decoder path above (failures are swallowed so a bad image cannot take the frame down).

The remaining documented gap in the backend is gradients/patterns (`SetFillPaint`) and
shadows (`SetShadow`), which need brush shaders in the bridge.

## Verified
- Host library built and signed (selfsign); the four new symbol groups are exported and
  present in the installed pack.
- Both managed libraries build clean; workload `1.0.0-preview.5` published (versioned +
  rolling `workload-latest` + SDK release attachment) and installed into the device SDK.
- Zero-environment UI hap build + `verify-app` success; lifecycle bridge regression passes
  (`registered=True`, managed exit 0).

## Next (W14)
- Gradients/patterns + shadows in the bridge (brush shader), then the first MAUI handlers
  (Label/Button/Layout) over the backend and touch input via `OH_NativeXComponent`.
- Device validation of the rendering path (install-eligible device).
