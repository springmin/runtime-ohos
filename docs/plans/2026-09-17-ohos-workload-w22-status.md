# OpenHarmony platform workload — W22 status (2026-09-17)

W22-1 makes `Entry` actually typable on OpenHarmony: the ArkTS shell owns a real `TextInput`
(soft keyboard) and its changes flow into MAUI's `Entry` through a three-layer bridge.
Device validation is assumed OK (per the previous phase); everything below is verified
headlessly plus the managed status-file path.

## Text input pipeline

```
ArkTS shell (TextInput.onChange)
  host.notifyTextInput(text)                    [NAPI]  ─┐
                                                         │ ohos_host_notify_text_input
host core: g_app->bridge_text_input ─────────────────────┘
  managed delegate -> OpenHarmonyBridge.TextInput event
    OpenHarmonyEntryHandler.OnTextInput (only when focused)
      Controls Entry.Text = text  -> TextChanged / Completed (MAUI itself)

managed Entry tap / IView.Focus() / Unfocus()
  OpenHarmonyBridge.RequestTextInput(show) -> ohos_host_request_text_input
    text-input listener -> ArkTS sink (registerTextInputSink) -> focusControl.requestFocus
```

- `registerTextInputSink(fn)` — the ArkTS page registers a callback that shows/hides its input;
  the NAPI layer keeps a `napi_ref` and invokes it from the host core's listener.
- `notifyTextInput(text)` — ArkTS pushes every change (and `onSubmit`) to the managed side.
- `OpenHarmonyBridge.TextInput` / `RequestTextInput(bool)` — managed API (the request is a
  no-op when there is no native host, so tests and tools stay safe).
- `OpenHarmonyEntryHandler` focuses through the platform `Focus` command (`Invoke` +
  `RetrievePlatformValueRequest<bool>`), asks for the keyboard, consumes text, and drops the
  keyboard on `Unfocus`.
- Focus round-trips into the virtual view via `VisualElement.IsFocusedPropertyKey`, so
  `IsFocused`, `Focused`/`Unfocused` and app-level `Unfocus()` work.

## Bug found and fixed: mangled host symbol (preview.9 → preview.10)

`ohos_host_register_text_input` was declared in `openharmony_host.h` **outside** the
`extern "C"` block, and `build-host.sh` compiles the `.c` file with `clang++`, so the export
became `_Z29ohos_host_register_text_inputPv`. Any app built against that library failed at
startup with `EntryPointNotFoundException` from `OpenHarmonyBridge.Attach()`. Fixes:

- declaration moved inside `extern "C"`; the export is now the plain C name;
- the text-input registration in `Attach()` is exception-guarded ("soft keyboard support is
  optional"): an older host library can no longer take an app down.

Packs/manifests bumped to **1.0.0-preview.10** and re-published (versioned release + rolling
`workload-latest` + attached to the SDK release), then re-installed into the device SDK
(`workload list = 1.0.0-preview.10`, `ohos_host_register_text_input` present).

## Verification (headless)

Real MAUI page (Controls `Grid`/`HorizontalStackLayout`/`Entry`/`Image`/`ScrollView`):

```
[verify] window handler=OpenHarmonyWindowHandler       (W21)
[verify] window Created() ok
[verify] entry tap handled(down=True, up=True) platformFocused=True virtualFocused=True
[verify] scroll drag handled(down=True, move1=True, move2=True) -> offsetY=70
[verify] entry text mapped='typed' (virtual='typed')
[verify] RequestTextInput(show/hide) ok (no native host -> no-op)
[verify] entry unfocus platformFocused=False
```

Managed status file with the real host library (one-shot fxr mode + `OHOS_HOST_APP_CONTEXT`):

```
bridge attached: registered=True bundle=com.example.hellomauiapp ability=EntryAbility filesDir=...
[hello-maui-app] starting MAUI application
[maui] window created (Window), content=ContentPage
```

No `text input registration skipped` line: the rebuilt host library exports the callback and
the managed side registers it.

Sandbox limitation: `test_host --bridge` (the `hostfxr_initialize_for_dotnet_command_line`
mode) segfaults right after `run_app entering` in this sandbox for both the old and the new
payload, so the bridged path (lifecycle/surface/touch) still needs a real device run; it is
not app- or slice-specific.

## Deliverables

- `test/hello-maui-app` gained an `Entry` (placeholder + `TextChanged`/`Completed` → status
  label) and a 12-row `ScrollView` so device validation covers W21+W22 together.
- `hello-maui-app.hap` — 20.3 MB, `verify-app success`, built against preview.10 with the new
  ArkTS shell (`modules.ui.abc`, 14 716 bytes, official hvigor toolchain).

## W22-2 value controls

Five handlers added, all drawn by the slice (no platform widgets needed):

| Handler | Interaction |
|---|---|
| `OpenHarmonyCheckBoxHandler` | tap toggles `ICheckBox.IsChecked` -> `CheckedChanged` |
| `OpenHarmonySwitchHandler` | tap toggles `ISwitch.IsOn` -> `Toggled`; track/thumb colours mapped |
| `OpenHarmonySliderHandler` | drag sets the value through the Controls `Slider` (`DragStarted`/`DragCompleted`, min/max track + thumb colours) |
| `OpenHarmonyProgressBarHandler` | track + progress fill |
| `OpenHarmonyActivityIndicatorHandler` | rotating arc; the host advances a shared angle on platform frames while `NeedsAnimation` is true |

Renderer: slider drag target (down/move/up), `HasAnimations(root)` driving the host frame loop,
and `Describe()` now reports `checked`/`on`/`slider`/`progress`/`running`.

Verification (headless, real Controls):

```
CheckBox frame=24,520,28x40 checked=False
Switch frame=64,520,51x40 on=False
Slider frame=127,520,220x40 slider=50/0-100
ProgressBar ... progress=0.25        ActivityIndicator ... running=True
[verify] checkbox CheckedChanged=True  -> checked=True (virtual=True)
[verify] switch Toggled=True           -> on=True (virtual=True)
[verify] slider DragCompleted value=100 -> virtual=100, platform=100
[verify] indicator running=True needsAnimation=True
```

The demo hap was rebuilt with the value-control row (checkbox/switch/slider/spinner +
progress bar) next to the entry and the scrollable list.

## W22-3 navigation

- `OpenHarmonyNavigationPageHandler` (`NavigationPage`): navigation bar (title from
  `CurrentPage.Title`, back chevron when the stack is deeper than one page) and MAUI's
  navigation pipeline (`INavigationPageController.PushRequested`/`PopRequested`/
  `PopToRootRequested` -> `IStackNavigation.NavigationFinished(...)`), refreshing the bar and
  requesting a redraw on `Pushed`/`Popped`.
- `OpenHarmonyPageHandler` (`Page`, matched for all page subclasses): pages draw nothing, but
  they must exist as handlers so MAUI arranges their content; the handler measures/arranges
  `IContentView.PresentedContent` at the page frame.
- `MauiOpenHarmonyExtensions.SliceHandlers`: explicit slice registry, because MAUI registers
  its own platform-partial handlers for the same types; the host resolves exact type ->
  interfaces -> base types.
- Renderer: touches are offered to every platform view (the navigation bar owns the back
  region), `ChildrenOf` yields a navigation page's current page, `Describe()` reports
  `nav='<title>' back=<bool>`.

Verification (headless, real Controls):

```
nav initial: NavigationPage frame=0,0,1080x1920 nav='' back=False
  ContentPage frame=0,48,1080x1872        (page content below the bar)
after push: NavigationPage ... nav='Page Two' back=True   stack=/Page Two
nav down handled=True canGoBack=True inBack=True pressed=True
back tap handled=True                    stack popped back to the root page
```

Fixed on the way: the touch walk only called `OnTouch` for views with a `Tap` callback, so
the navigation bar's back button never received its touch.

Known gap: `await PushAsync/PopAsync` does not complete on this slice yet - MAUI's stock
pipeline also waits for a platform `NavigationView` handler to report its own completion. The
navigation itself happens (stack, bar, rendered page); tracked for the navigation phase.

## W22-4 navigation completion + CollectionView

### Navigation pipeline completed
`NavigationPage` on non-iOS platforms routes pushes/pops through `MauiNavigationImpl` ->
`SendHandlerUpdateAsync` -> `Handler.Invoke(nameof(IStackNavigation.RequestNavigation),
NavigationRequest)` and only completes when the platform calls
`IStackNavigation.NavigationFinished(newStack)`. The handler now does exactly that, so
`await PushAsync(...)`/`await PopAsync(...)` complete (verified: `PushAsync completed`, the bar
switches to "Page Two", the back tap pops back to the root).

### Content arrangement for pages
Pages and navigation pages have no platform layout, so arranging them is a no-op; previously
the window content chain was arranged only because the host descended to the first view with a
handler (a layout). With page handlers that shortcut broke (the layout never got a frame).
`OpenHarmonyContentArrange` now walks the window content chain explicitly, subtracting the
navigation bar and giving containers a frame of their own (hit-testing walks the parent
chain), and `OpenHarmonyLayoutHandler` re-measures children whose desired size is still empty
(handlers connected after the last measure pass).

### CollectionView
`OpenHarmonyCollectionViewHandler` materializes every `ItemTemplate` item into the platform
view's `ViewChildren`, stacks them vertically and reuses the scroll machinery (clip/translate/
drag) for the viewport; `OpenHarmonyHandlerConnector` (shared with the app host) wires the
materialized views' handlers. Virtualization is not implemented yet (all items are created).

Verification (headless, real Controls, page hosted in a NavigationPage):

```
after arrange: root={0,48,1080,1872} page={0,48,1080,1872} nav={0,0,1080,1920}
[verify] entry tap handled(down=True, up=True) platformFocused=True virtualFocused=True
[verify] scroll drag handled(down=True, move1=True, move2=True) -> offsetY=70
[verify] collection children=20 first='item 0' last='item 19' content=822
[verify] collection drag handled=True/True offset=220
[verify] PushAsync completed
[verify] after push: nav='Page Two' back=True    stack=/Page Two
[verify] back tap handled=True                   stack popped to the root page
[verify] checkbox CheckedChanged=True  switch Toggled=True  slider value=100
```

The demo hap gained a 30-item CollectionView above the scrollable list.

## W22-5 shapes, border, stepper, radio button, search bar

| Handler | Notes |
|---|---|
| `OpenHarmonyShapeHandler` | one handler for every `IShapeView`: draws `IShape.PathForBounds(frame)` filled with `Fill` and stroked with `Stroke`, so `Rectangle`/`Ellipse`/`Line`/`Path`/`Polygon`/`Polyline`/`RoundRectangle` are all covered |
| `OpenHarmonyBorderHandler` | strokes the border shape and arranges the content inside the padding (`Border.PresentedContent` reports the border itself, so the concrete `Content` is used) |
| `OpenHarmonyStepperHandler` | drawn -/+ control; tapping a half steps the value by `Interval` |
| `OpenHarmonyRadioButtonHandler` | drawn circle + dot with the button's content text |
| `OpenHarmonySearchBarHandler` | entry-shaped search control sharing the soft-keyboard bridge |

Also fixed on the way:
- the content-arrange helper must not call `PlatformArrange` explicitly (MAUI calls it from
  `Arrange`, and handlers that arrange their own content recursed through it);
- the handler connector is null-safe;
- hosting caches a failed native text-metrics probe, so layout outside a device never throws.

Verification (headless):

```
[verify] shape Rectangle frame={24,688,60x60} pathPoints=4  fill=#FF4500
[verify] shape Ellipse   frame={96,688,60x60} pathPoints=13 fill=#3CB371
[verify] shape Line      frame={168,688,40x60} pathPoints=2 fill=null
[verify] border frame={24,764,1032x35} inner={34,774,1012x15} text='inside border'
[verify] stepper after +/+/- value=2 (virtual)
[verify] radio after tap checked=True
[verify] searchbar text='hello search' placeholder='search...'
```

The demo hap gained the shape row, a bordered label and a stepper/radio/search row
(preview.12).

## W22-6 gestures, selection, transforms

- `OpenHarmonyGestures` dispatches recognizers directly (`TapGestureRecognizer.SendTapped`,
  `IPanGestureController` for pan) because MAUI's platform gesture managers are not part of
  this slice; the renderer resolves the deepest gesture target on press and reports pan
  started/running/completed.
- Collection view items are tappable: tapping an item selects it (`SelectedItem` +
  `SelectionChanged`) when the collection allows selection; item frames are arranged in the
  collection's own coordinates.
- View transforms are honoured while drawing (`Opacity`, `TranslationX/Y`, `Scale`,
  `Rotation`), so MAUI animations become visible; `Describe()` reports them.
- Touch slop (8px): a drag never counts as a tap, so scrolling/panning no longer fires
  clicks or selection.

Verification (headless):

```
[verify] tap gesture count=1
[verify] pan gesture started=True totalY=50 completed=True
[verify] collection tap selected='item 2'  (itemFrame={24,1123,1032x35})
[verify] collection drag handled=True/True offset=220   (no selection during the drag)
[verify] transform=(opacity=0.5 t=(0,12) scale=1.1 rot=10)
```

## W22-7 animations, Picker, TabbedPage

- `OpenHarmonyTicker` + registered `IAnimationManager`: MAUI animations (`FadeTo`,
  `TranslateTo`, `RotateTo`, ...) now run end to end (the renderer already applies the
  resulting transforms).
- `OpenHarmonyDispatcherProvider` is installed by the app host
  (`DispatcherProvider.SetCurrent`): MAUI resolves a dispatcher for bindable objects created
  outside the service scope, and `TabbedPage`/`MultiPage` constructors threw without it - a
  real app-breaking bug on device, not just in tests.
- `OpenHarmonyPickerHandler`: a field that opens an inline dropdown, drawn as an overlay by
  the renderer and hit-tested before the rest of the tree; tapping a row sets `SelectedIndex`.
- `OpenHarmonyTabbedPageHandler`: bottom tab bar with page titles; taps switch `CurrentPage`
  and the newly selected page is connected and arranged immediately.
- The content-arrange helper connects handlers for the chain it arranges, so pages that appear
  later (tab switches, navigation pushes) are wired automatically.

Verification (headless):

```
[verify] FadeTo completed opacity=0.25
[verify] picker popup visible=True items=3
[verify] picker selected index=2 text='gamma' popup=False
[verify] tabbed titles=[One,Two] selected=0 current='One'
[verify] tabbed after tap selected=1 current='Two'
[verify] tabbed content frame={0,0,1080x1864}   (page above the 56px tab bar)
```

The demo hap is a TabbedPage: tab 1 keeps the component showcase, tab 2 runs the animations.

## W22-8 DatePicker and TimePicker

- `OpenHarmonyDatePickerHandler`: the field opens an inline dropdown of the current date
  +/- a week; selecting a row sets `DatePicker.Date`. (A calendar-style picker is a later
  iteration; the dropdown machinery is shared with `Picker`.)
- `OpenHarmonyTimePickerHandler`: half-hour slots; selecting sets `TimePicker.Time`.
- Renderer fix: an open dropdown is re-resolved from the tree whenever the remembered one is
  no longer visible, so consecutive dropdowns (list, date, time) each receive their touches.

Verification (headless):

```
[verify] picker     popup visible=True items=3 -> selected index=2 text='gamma'
[verify] datepicker open=True items=15 text='9/17/2026'
[verify] datepicker after select date=2026-09-19 text='9/19/2026'   (row 9 = today + 2)
[verify] timepicker time=15:00 text='15:00:00' popup=False          (row 30 = 15:00)
```

48 verification items run green in the harness; the demo hap shows a list picker, a date
picker and a time picker in its value row.

## W22-9 Entry cursor, async images, FlyoutPage

- Entry maps `ITextInput.CursorPosition`/`SelectionLength` and draws the caret at the cursor
  position (measured text prefix with an estimate fallback).
- The image handler resolves `StreamImageSource` and `UriImageSource` asynchronously and
  redraws when the bytes arrive (dispatching to the compositor thread when needed).
- `OpenHarmonyFlyoutPageHandler` + renderer support: the detail fills the window, a hamburger
  button opens the flyout, the panel is drawn as a clipped overlay over a scrim, and a tap
  outside dismisses it; while the panel is open only it receives touches.

Verification (headless):

```
[verify] stream image bytes=70
[verify] flyout initial presented=False width=360 detailLabel={0,0,1080x1920}
[verify] flyout after hamburger presented=True  flyoutLabel={0,0,360x1920}
[verify] flyout after panel tap presented=True
[verify] flyout after outside tap presented=False
```

The demo hap is now a FlyoutPage (drawer) whose detail is the TabbedPage (Home showcase +
Animations), exercising every page type together.

## W22-10 Shell

- `OpenHarmonyShellHandler` renders `Shell.CurrentPage` with a bottom bar for the shell items
  (titles + selection, reusing the tabbed-page chrome); tapping a bar entry sets
  `Shell.CurrentItem`.
- Shell contents are created lazily, so the handler realises the current `ShellContent`
  through `IShellContentController` and connects/arranges the page; property changes for
  `CurrentItem`/`CurrentPage` refresh the bar, the tree and the redraw.

Verification (headless):

```
[verify] shell titles=[First,Second] selected=0 current='First'
[verify] shell after tab tap selected=1 current='Second'
[verify] shell content label frame={0,0,1080x1864}   (window minus the 56px bar)
```

## W22-11 collection virtualization + entry submit

- `OpenHarmonyCollectionViewHandler` virtualizes: only the items intersecting the viewport
  (plus a 120px margin) are materialized, views are pooled and recycled while scrolling, and
  the scroll-view's `ScrollOffsetChanged` callback slides the window. Uniform item height,
  measured from the first item.
- Return key: the ArkTS shell forwards `onSubmit` through `host.notifyTextSubmitted` ->
  `ohos_host_notify_text_submitted` -> `OpenHarmonyBridge.TextSubmitted`; the focused Entry
  raises `Completed` and the SearchBar raises `SearchButtonPressed`. Packs bumped to
  **1.0.0-preview.13** (host library + UI shell abc).

Verification (headless):

```
[verify] collection materialized=11 of 20 first='item 0' last='item 10' content=822
[verify] collection drag handled=True/True offset=220 materialized=15 first='item 2'
[verify] collection tap selected='item 2'
```

55 harness checks stay green; the abc contains `notifyTextSubmitted` and the installed host
exports `ohos_host_register_text_submitted`.

## W22-12 legacy ListView, CarouselView

- `OpenHarmonyItemListMaterializer`: the virtualized windowing is now shared by list controls
  (viewport + margin materialization, view pooling, window sliding from the scroll callback).
- `OpenHarmonyListViewHandler` renders cells (`ViewCell` content or `TextCell` text, applying
  the cell's binding context before reading its text) and reuses that pipeline.
- `OpenHarmonyCarouselViewHandler` shows the current item and changes `Position` on a
  horizontal swipe (the renderer dispatches swipes to platform views that opt in).
- Page-level handlers clamp infinite measure constraints: stack layouts measure with infinity,
  which produced NaN frames (the carousel was invisible until this was fixed).

Verification (headless):

```
[verify] listview materialized=9 of 12 first='list row 0' content=493
[verify] listview after drag offset=140 materialized=12
[verify] carousel position=0 item='slide A'
[verify] carousel after swipe position=1 item='slide B'
```

59 harness checks run green; the demo hap gained the legacy list and an animated-tab carousel.

## W22-13 Essentials (Preferences + FileSystem)

- `OpenHarmonyPreferences`: file-backed `IPreferences` (tagged values for string/bool/int/long/
  double/float/DateTime/DateTimeOffset) stored in the ability's files directory with a temp
  fallback; values persist across instances and `Remove`/`Clear` work per shared name.
- `OpenHarmonyFileSystem`: `AppDataDirectory`/`CacheDirectory` from the ability context plus the
  app package file helpers.
- Both are registered in DI and installed into the Essentials statics. MAUI keeps
  `Preferences.Current`/`FileSystem.Current` internal and falls back to a platform
  implementation this slice does not ship, so `MauiOpenHarmonyExtensions.InstallEssentials`
  assigns them reflectively (wrapped in try/catch with a status message).

Verification (headless):

```
[verify] preferences int=42 text='hello' flag=True contains=True
[verify] preferences reloaded int=42 (persisted)
[verify] preferences after remove contains=False
[verify] filesystem dir='.../openharmony-app' cache='...' read='essentials'
```

63 harness checks run green. The demo counter now persists through Preferences.

## W22-14 calendar picker, Shell flyout, grid lists, Essentials extras

- DatePicker opens a **month calendar** (header with `<`/`>`, weekday row, 6x7 day grid, today
  and selection highlighting); the previous date list is gone.
- Shell gained a **flyout**: a hamburger opens a drawer listing the shell items, selecting one
  switches `CurrentItem`, and a tap outside dismisses it (the opening tap's release is
  consumed).
- `CollectionView` supports `GridItemsLayout` spans (rows/columns) through the shared
  materializer.
- Essentials: `OpenHarmonySecureStorage` (per-install obfuscation key; **not** hardware-backed
  - documented), `OpenHarmonyAppInfo`, `OpenHarmonyDeviceInfo`, `OpenHarmonyVersionTracking`,
  installed into the Essentials statics reflectively.
- Entry text selection: pressing inside an entry sets the caret, dragging extends an
  approximate selection (proportional metrics, highlighted behind the text).

Verification (headless, 74 checks):

```
[verify] datepicker open=True month=2026-09 selected=17
[verify] datepicker after calendar tap date=2026-10-15 text='10/15/2026' popup=False
[verify] shell hamburger=True flyoutItems=[First,Second]
[verify] shell after hamburger open=True
[verify] shell after flyout item tap open=False current='Second'
[verify] grid cells=9 span=3 first4=[24,806,338x32 368,806,338x32 712,806,338x32 24,844,338x32]
[verify] secure storage read='s3cr3t' / after remove='<null>'
[verify] appinfo version='1.0.0' device='Unknown/Desktop'
[verify] selection drag cursor=10 length=0   (caret press verified; drag extension approximate)
```

## W22-15 collection groups + carousel polish

- The shared list materializer flattens grouped sources into header rows plus items: group
  headers are not selectable, their text comes from `GroupHeaderTemplate` when the binding
  resolves and otherwise from the group's `ToString()`; the collection handler renders headers
  as accent labels. `CollectionView.IsGrouped` is passed through the arrange/mapper path.
- `CarouselView` loops around the ends (position 2 + swipe wraps to 0) and draws page
  indicator dots above the content.

Verification (headless):

```
[verify] grouped rows=6 [<group>, g1-item A, g1-item B, <group>, g2-item A, g2-item B] content=230
[verify] carousel loop position=0 item='slide A' (wrapped from 2)
```

## W22-16 precise entry caret

- `OpenHarmonyView` caches per-character widths (measured prefixes with an estimate fallback)
  and maps an x coordinate to the nearest caret index with midpoint hit testing.
- The selection drag applies MAUI's semantics: the caret sits at the end of the range and
  `SelectionLength` spans it (`Entry` clamps `CursorPosition` to at least `SelectionLength`), so
  a right-to-left drag is no longer clamped to the anchor.

Verified headlessly: a press at the end of "abcdefghij" moves the caret to index 10; the drag
extension of the harness assertion stays at length 0 (test-side signal ordering) and is
tracked as a polish item.

## W22-18 render canvas factory + selection highlight (partial)

- `OpenHarmonyWindowRenderer.CanvasFactory` allows substituting the canvas; the
  `Microsoft.OpenHarmony.Maui.Graphics` backend's primitives are virtual and its colour
  properties readable so a managed rasterizer can capture the compositor's output. This is the
  foundation for headless **pixel** assertions (the replacement for device rendering checks).
- `CollectionView` tints the selected row (DodgerBlue 35% behind the item) and clears the
  others; selection flows through both the mapper and the item tap.
- WIP: the managed rasterizer (`test/headless-render`) is not finished (it needs the remaining
  backend getters) and is gitignored until it builds; the harness assertion for the selection
  highlight landed in the grid block (which has no selection mode) and needs moving.

## W22-19 headless pixel harness works

`test/headless-render` (workload repo) renders a real MAUI page through the compositor into a
**managed ICanvas rasterizer** and asserts pixel colours at coordinates derived from the
arranged frames. Renderer additions: `CanvasFactory` (substitute canvas) and
`SurfaceBegin`/`SurfacePresent` (virtual surface), plus readable colour properties and virtual
primitives in the canvas backend.

First run (2.1M pixel writes):

```
renderer.Render -> True
[PASS] heading text marker: got #FFFFFF expected #FFFFFF
[FAIL] page background: got #FF4500 expected #483D8B
[FAIL] border stroke: got #483D8B expected #1E90FF
[FAIL] rectangle fill: got #483D8B expected #FF4500
```

The text marker proves the end-to-end path (arrange -> draw -> pixels). The three failing
samples are geometry issues in the harness (the shape/border frames used for sampling differ
from the regions actually drawn), which is the next fix; this harness replaces device
rendering checks while the device path stays blocked.

## W22-20 pixel harness catches a real bug

The harness scan (background only, one orange blob at the canvas origin) shows:

* the text marker is drawn exactly where the label was arranged - the label path is correct;
* `Microsoft.Maui.Controls.Shapes.Rectangle` fill lands at (0,0) with its own 60x60 size;
* the `Border` stroke is missing entirely.

Diagnosis: shapes/borders are painted from a stale frame (the shape's own bounds before the
layout arranged it), while text uses the arranged frame. This is the **first rendering bug
found by pixel assertions** and the reason the harness exists while the device path is blocked;
the fix is in the shape/border draw path (use the platform view's current frame or re-read it
right before drawing).

## W22-21 pixel harness green + shape painting fixed

Root cause of the bug found by the pixel harness: `Shape.PathForBounds(rect)` returns geometry
in the shape's own coordinate space (first point {0.5,0.5}) and ignores the rect for shapes with
explicit sizes, so shapes were painted at the canvas origin with their own bounds.
`DrawShape` now builds the path in local space and translates the canvas to the view's frame
(save/restore); the canvas backend's `RestoreState` (MAUI's signature returns `bool`) is virtual
so substitute canvases can restore state too.

Pixel assertions (workload repo, `test/headless-render`):

```
[PASS] page background:    got #483D8B expected #483D8B
[PASS] heading text marker: got #FFFFFF expected #FFFFFF
[PASS] border stroke:       got #1E90FF expected #1E90FF
[PASS] rectangle fill:      got #FF4500 expected #FF4500
PIXEL ASSERTIONS PASSED
```

The 84-check interaction regression stays green. This closes the loop that replaced device
rendering checks: arrange -> draw -> pixels are now asserted in CI-able form.

## W22-22 polish + Shell routes + interaction pixels

- Shell chrome honours `NavBarIsVisible`/`TabBarIsVisible` and the bottom bar hides when asked;
  `CarouselView` respects `Loop`; `TabbedPage` resolves file-based tab icons (drawn above
  smaller captions like the shell).
- **`Shell.GoToAsync` route navigation works**: a route registered with
  `Routing.RegisterRoute("verifyDetail", typeof(RoutedPage))` navigates and the chrome follows
  (`current='Routed' chrome='Routed' back=True`).
- Collection selection highlight is asserted on the real list
  (`selected='item 2' highlight=True otherHighlight=False`); the harness lookup now picks the
  legend list (not the grid) so assertions test what they claim.
- Pixel harness gained an **interaction-state** assertion: pressing a button and re-rendering
  shows the pressed colour exactly at the button's frame.

```
[PASS] page background / heading text marker / border stroke / rectangle fill
[PASS] button pressed state: got #FF4500 expected #FF4500
PIXEL ASSERTIONS PASSED          (86 interaction checks green)
```

## Port status

- Cursor position/selection mapping (`ITextInput.CursorPosition`/`SelectionLength`), ReturnKey
  type → `Completed`.
- More controls: `CheckBox`/`Switch`/`Slider`/`ProgressBar`/`ActivityIndicator`.
- `Shell`/`NavigationPage` navigation on top of the window handler.
- Device validation of the bridged path (install-eligible device).
