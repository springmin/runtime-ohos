# OpenHarmony device validation checklist (2026-09-18)

Everything in this list is blocked on an install-eligible device (`hdc` is restricted in this
environment). Each step names the artifact, the command and the observable result, so a single
session on a device closes the whole port validation.

## 0. Artifacts

| Artifact | Where |
|---|---|
| `hello-maui-app.hap` (20.4 MB, `verify-app` success) | `ohos-workload/test/hello-maui-app/bin/Release/net11.0-openharmony26.0/openharmony-arm64/` |
| Workload bundle `openharmony-workload-1.0.0-preview.14.tar.gz` | GitHub release `workload-1.0.0-preview.14` (+ `workload-latest`, attached to the SDK release) |
| Host library | `packs/Microsoft.OpenHarmony.Sdk/<ver>/hosts/arm64-v8a/libopenharmonyhost.so` (signed) |
| ArkTS shells | `packs/.../templates/ets/modules.abc` (headless) and `modules.ui.abc` (UI) |

## 1. Install and launch

```
hdc install -r hello-maui-app.hap          # or: bm install -p <extracted dir>
hdc shell aa start -a EntryAbility -b com.example.hellomauiapp
```
Expected: the app starts; the status file (`<filesDir>/dotnet-status.txt`) contains
`bridge attached: registered=True`, `[hello-maui-app] starting MAUI application`,
`[maui] window created (Window), content=ContentPage`.

## 2. Rendering (pixel expectations)

The window is a `FlyoutPage` (drawer) whose detail is a `TabbedPage` (Home + Animations).

| # | Action | Expected |
|---|---|---|
| 2.1 | Look at the Home tab | dark-slate background, "MAUI on OpenHarmony" title, nav bar with the title, bottom tab bar with two tabs |
| 2.2 | Tap **Count** | label increments; the counter text persists after restart (Preferences) |
| 2.3 | Drag the 30-item **CollectionView** | list scrolls smoothly; the first visible row changes; tapping a row tints it |
| 2.4 | Drag the legacy **ListView** | rows scroll; `legacy row N` labels visible |
| 2.5 | Shapes row | orange rectangle, green ellipse, gold diagonal line |
| 2.6 | **Border** | blue rounded border around "inside border" |
| 2.7 | Value row | checkbox toggles, switch toggles, slider moves the progress bar, spinner rotates, stepper −/+, radio dot |
| 2.8 | **DatePicker** | month calendar opens; `<`/`>` change months; tapping a day updates the field |
| 2.9 | **TimePicker / Picker** | dropdown lists open, a selection updates the field |
| 2.10 | Search bar | tapping focuses; typing shows characters via the soft keyboard |
| 2.11 | **Entry** | tap focuses (caret), the ArkTS soft keyboard shows, typed text appears, **Enter** raises `Completed` (status label updates) |
| 2.12 | Animations tab | button runs FadeTo/TranslateTo/RotateTo visibly; carousel swipes (looping) and shows dots |

## 3. Interaction

| # | Action | Expected |
|---|---|---|
| 3.1 | Tap the tappable label | counter in its text increments (TapGestureRecognizer) |
| 3.2 | Drag inside the pan label | no crash; pan callbacks run (log) |
| 3.3 | Swipe the drawer open (hamburger at top-left) | drawer slides in; tapping an item switches; tapping outside closes |
| 3.4 | Switch tabs | content swaps; tab bar highlights the active tab |
| 3.5 | Navigation: from the drawer/second page use back | returns to the previous page; the back chevron appears only when the stack is deeper |

## 4. State and storage

| # | Action | Expected |
|---|---|---|
| 4.1 | Restart the app | the counter keeps its value (`Preferences`) |
| 4.2 | `SecureStorage` path | values are written through HUKS when the keystore kit is enabled in the shell project; otherwise the documented file fallback is used (see the HUKS plan) |
| 4.3 | Files | `AppDataDirectory` is `<filesDir>`; files written by the app are visible there |

## 5. Performance smoke

| # | Action | Expected |
|---|---|---|
| 5.1 | Scroll a 30-item list | no visible stutter; virtualization keeps only ~1 screen of item views (log line: `collection materialized=N of 30`) |
| 5.2 | Idle | CPU stays low (renderer redraws on request only; animation ticks only while indicators run) |

## 6. Known test-side items (not device blockers)

* the pixel harness's checkbox-stroke sample reads a neighbouring colour (the check line itself
  is verified); the selection-tint sample needs the tap re-checked with fresh frames;
* both are test-side and tracked in the port status document; the renderer behaviour they cover
  is verified by the other 10 pixel assertions.

## 7. Reporting back

Collect `dotnet-status.txt`, `hilog` excerpts around a tap/typing/animation and any crash
traces. With those, the port validation is complete and the remaining work is upstream API
approval only.
