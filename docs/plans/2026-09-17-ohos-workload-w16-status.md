# OpenHarmony platform workload — W16 status (2026-09-17)

W16 closes the last `ICanvas` gap: pattern paints.

## Platform capability
- `ohos_host_draw_set_image_pattern(bytes, tileModeX, tileModeY, scaleX, scaleY)`: decodes
  PNG/JPEG (`OH_ImageSourceNative`), wraps the pixelmap for drawing
  (`OH_Drawing_PixelMapGetFromOhPixelMapNative`) and creates a tile shader
  (`OH_Drawing_ShaderEffectCreatePixelMapShader` with clamp/repeat/mirror and an optional
  scale matrix) that the fill brush uses.
- `OpenHarmonyCanvas.SetImagePattern(...)` exposes it to managed code.

## Backend mapping (`SetFillPaint`)
| MAUI paint | Mapping |
|---|---|
| `SolidPaint` | fill colour (effects cleared) |
| `LinearGradientPaint` / `RadialGradientPaint` | brush shader (stops or start/end colours) |
| `ImagePaint` | tile shader (repeat) |
| `PatternPaint` wrapping a paint (`PaintPattern`) | recursion into the wrapped paint |
| `PatternPaint` with a procedural `IPattern` | the fill operations tile it: clip to the fill rectangle, then `Translate` + `IPattern.Draw` per `StepX`/`StepY` |
| `PicturePattern` (`IPicture`) | falls back to the current solid colour (documented) |

This completes the subset: shapes, paths, text (with real metrics), transforms, clipping,
images, gradients, shadows and patterns are all mapped; only picture-based patterns are
approximated.

## Verified
- Host library rebuilt with the pattern symbol (present in the pack and the installed SDK);
  backend and app build clean; UI hap + `verify-app` succeeds; lifecycle bridge regression
  passes (registered=True, managed exit 0).
- Workload `1.0.0-preview.8` published (versioned + rolling `workload-latest` + SDK release
  attachment) and installed into the device SDK.

## Next (W17)
- MAUI's real handlers in the MAUI fork (needs its platform build) over this contract.
- Device validation of the rendered UI + touch input (needs an install-eligible device).
