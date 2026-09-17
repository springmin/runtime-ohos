# OpenHarmony platform workload — W21 status (2026-09-17)

W21 completes the window handler and widens the control set, still verified headlessly with
real MAUI controls (device validation assumed OK per the previous phase).

## Window
`OpenHarmonyWindowHandler` gives `IWindow` a platform handler, so MAUI's window lifecycle
(`Created`/`Activated`/`Resumed`/`Stopped`/`Destroying`) runs. The app host now connects
handlers for `IElement`s as well as `IView`s (a window is not a view), and the best-effort
guards from W20 are no longer hit.

## New handlers
| Handler | Notes |
|---|---|
| `OpenHarmonyEntryHandler` | text/placeholder/colour/font mapping; taps focus through the platform `Focus` command (`Invoke` + `RetrievePlatformValueRequest`), caret drawn when focused; real text input needs the ArkTS soft keyboard (next phase) |
| `OpenHarmonyImageHandler` | resolves `FileImageSource` to bytes and draws them via the canvas (aspect fit); stream/URI sources need the platform image service |
| `OpenHarmonyScrollViewHandler` | measures/arranges its content; `HeightRequest` is the viewport; `IScrollView` offsets are mapped both ways |
| `Grid`, `HorizontalStackLayout`, `AbsoluteLayout`, `FlexLayout`, `StackLayout` | already covered by `OpenHarmonyLayoutHandler` (all `ILayout`) |

Renderer additions: clip + translate for scroll views, drag scrolling (deepest scroll view
under the touch, offset clamped to the content, propagated back to `IScrollView`), and
`Describe()` now reports image bytes, scroll offsets/content size and entry focus.

## Verification (real MAUI page, headless)
```
[verify] window handler=OpenHarmonyWindowHandler
[verify] window Created() ok
  VerticalStackLayout frame=24,24,1032x... 
    Grid > HorizontalStackLayout > Label + Button   (arranged)
    Entry (placeholder)      -> tap focuses (platformFocused=True)
    Image                    -> image=70B (FileImageSource resolved)
    ScrollView (400 viewport of 509 content)
[verify] scroll drag handled(down=True, move1=True, move2=True) -> offsetY=70 (virtual view)
```

## Next (W22)
- Soft keyboard / text editing (ArkTS input method + `IEntry` events), then `Image` for
  stream/URI sources, `CheckBox`/`Switch`/`Slider`, and `Shell`/navigation.
- Device validation of the MAUI hap (install-eligible device) once available.
