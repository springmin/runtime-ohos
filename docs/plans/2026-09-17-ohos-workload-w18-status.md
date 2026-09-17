# OpenHarmony platform workload — W18 status (2026-09-17)

W18 lands the first real MAUI handlers and the compositor in the platform slice, verified
with actual MAUI controls.

## Slice additions (`maui-ohos`, `src/Core/src/Platform/OpenHarmony`)
| Type | Role |
|---|---|
| `OpenHarmonyView` | platform view: arranged frame, text/font/colour/background/corner radius, pressed state, tree-walking tap routing |
| `OpenHarmonyViewHandler<TVirtualView>` | base handler; keeps `PlatformView.VirtualView` current (required for frames/hit-testing) |
| `OpenHarmonyLabelHandler` (`ILabel`) | `Text`/`TextColor`/`Font` mapping; `GetDesiredSize` from platform text metrics (estimate fallback) |
| `OpenHarmonyButtonHandler` (`IButton`) | text/colour/background/corner radius mapping; tap -> `IButton.Clicked()` |
| `OpenHarmonyLayoutHandler` (`ILayout`, `ILayoutHandler`) | add/insert/update/remove/clear; routes `GetDesiredSize`/`PlatformArrange` into MAUI's `CrossPlatformMeasure`/`CrossPlatformArrange` |
| `OpenHarmonyWindowRenderer` | measure/arrange the tree, draw through the MauiGraphics canvas, deepest-first hit testing, `Describe()` tree dump |
| `UseOpenHarmony()` | registers services + the three handlers |

MAUI API notes that cost a few iterations: `IButton` only exposes `Clicked()/Pressed()/Released()`
(text/colour live on `IText`/`ITextStyle`, corners on `IButtonStroke`); `ILayout` is an
`IList<IView>` (no `Children` property) and `ILayoutHandler` needs `Insert`/`Update` as well as
`Add`/`Remove`/`Clear`; `Microsoft.Maui.Dispatching` is not a package (the dispatcher
interfaces live in `Microsoft.Maui.Core`, which has plain `net11.0` assets - that is what makes
the slice verifiable without a platform TFM).

## Verification (real MAUI controls)
```
VerticalStackLayout frame=0,0,1080x1920
  Label  frame=24,24,1032x54  text='MAUI on OpenHarmony'
  Button frame=24,94,1032x51  text='Tap me'
  Label  frame=24,161,1032x32 text='Ready'
tap at 540,119 handled(down=True, up=True) clicks=1
```
Handling, measure/arrange, drawing and touch all pass through our platform code.

## Next (W19)
- `WindowHandler`/`ContentPage` wiring (window content -> renderer, lifecycle -> window events)
  and a MAUI app host driven by `OpenHarmonyBridge` (surface/touch/frame).
- Device validation on an install-eligible device (the `hello-maui.hap` app or a MAUI one).
