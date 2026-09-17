# OpenHarmony platform workload — W14 status (2026-09-17)

W14 removes the last documented no-ops in the Microsoft.Maui.Graphics backend: gradients and
shadows.

## Platform capabilities added
| Host API | Implementation |
|---|---|
| `ohos_host_draw_set_linear_gradient` | `OH_Drawing_ShaderEffectCreateLinearGradient` + `OH_Drawing_BrushSetShaderEffect` |
| `ohos_host_draw_set_radial_gradient` | `OH_Drawing_ShaderEffectCreateRadialGradient` + brush shader |
| `ohos_host_draw_set_shadow` | `OH_Drawing_ShadowLayerCreate` + `OH_Drawing_BrushSetShadowLayer` |
| `ohos_host_draw_clear_effects` | releases the current shader/shadow |

All fills and text now create their brush through a shared helper that applies the pending
shader/shadow, so effects cover rectangles, polylines/paths, ellipses and strings.

## Backend mapping
- `SetFillPaint`: `SolidPaint` -> fill colour (clears effects), `LinearGradientPaint` ->
  linear shader (gradient stops, or start/end colours as a two-stop fallback),
  `RadialGradientPaint` -> radial shader. `PatternPaint` stays unmapped (documented).
- `SetShadow` -> shadow layer with blur/offset and the alpha-adjusted colour.
- `FillColor` setter clears pending effects so solid fills are not tinted by gradients.

## Verified
- Host library built/signed with the new symbols (checked in the pack and in the installed
  SDK); both managed libraries build clean.
- Workload `1.0.0-preview.6` published (versioned + rolling + SDK release attachment),
  reinstalled into the device SDK; zero-environment UI hap build + `verify-app` success.
- Lifecycle bridge regression passes (registered=True, managed exit 0).

## Next (W15)
- First MAUI handlers (Label/Button/Layout) over the backend, plus touch input via the
  `OH_NativeXComponent` callbacks; then device validation of the rendered frame.
