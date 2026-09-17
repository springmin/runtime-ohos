# OpenHarmony platform workload — W19 status (2026-09-17)

W19 wires a **real MAUI application** to the platform contract.

## Application host (`maui-ohos` slice)
`OpenHarmonyMauiAppHost`:
- creates the window through `IApplication.CreateWindow(null)` (the same explicit interface
  implementation platform hosts use) and connects the slice's handlers to the visual tree;
- prefers this slice's **interface-registered** handlers (`ILabel`/`IButton`/`ILayout`) over
  MAUI's platform-partial concrete registrations (whose `CreatePlatformView` throws here);
- arranges the first descendant that has a handler (pages/content views have no platform
  handler in this slice) and drives `Render()` from the XComponent surface/frame events;
- forwards lifecycle to window events (`Activated`/`Resumed`/`Stopped`/`Destroying`).

`OpenHarmonyWindowRenderer` now also descends into `IContentView.PresentedContent`, so
`ContentPage` trees are traversed for drawing, hit testing and `Describe()`.

## Verification (real MAUI app, headless)
`MauiApp.CreateBuilder().UseOpenHarmony().UseMauiApp<TestApp>()` with
`Window(ContentPage(VerticalStackLayout(Label, Button, Label)))`:
```
ContentPage
  VerticalStackLayout frame=0,0,1080x1920
    Label  frame=24,24,1032x54   text='MAUI app on OpenHarmony'
    Button frame=24,94,1032x51   text='Tap me'
    Label  frame=24,161,1032x32  text='Ready'
[verify] Button.Clicked fired
[verify] tap 540,119 handled(down=True, up=True)
```
So MAUI's own application/window/page/layout/control types are handled, laid out and tapped
through this platform slice; only the native surface is absent in the sandbox (the render
call is a no-op without an XComponent).

## Next (W20)
- Package a MAUI host app as a hap (the slice + `OpenHarmonyUIPage` shell) so a MAUI app can
  be installed and validated on device.
- Grow the handler set (Entry/Image/ScrollView/Grid) and Windows-style navigation.
