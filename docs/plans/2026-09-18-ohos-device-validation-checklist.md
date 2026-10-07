# OpenHarmony device validation checklist (2026-09-18)

> **2026-10-07 update (kit #51 — current):** kit #51 = kit #50 (full MULTIWINDOW-L M1–M4 + SEC-SCAN-5a/5b/5c + polish-49, carrying #49 MULTIWINDOW-M + SEC-SCAN-4 and #48–#45) plus MULTIWINDOW-L2 ((a) child-window a11y provider and (b) child ArkWeb second host), SEC-SCAN-6 A/B/C, and the L2CAP platform capacity probe: (a) the host node table is partitioned per provider instance (`host_a11y_table.c/h`; the legacy main partition is byte-preserved, `*_for(instance)` named partitions cap at 8, instance = <=63 printable ASCII), the `RegisterCallbackWithInstance` chain registers the child provider and routes actions via `set_window_action_listener`, the shell's `SubWindow.ets` mounts NodeContent/ContentSlot and double-reports `attachAccessibilityNodeFor`; exports 157 -> **163**; device HAD-W32 (OH 7.0.0.111) **W0 coexistence PASS** (`subwindow a11y provider status=1 instance=sub-1`, main status=1/72 nodes unchanged) and **W2 self-check PASS** (`subwindow a11y selfcheck status=1 nodes=10 instance=sub-1`, main 72 nodes, no regression); the per-window **action e2e stays platform-limited** (no screen reader / third-party a11y service in the image, `AccessibleManagerService accessible: 0`; covered offline by 7 checks + a 4-assert red control); (b) the host child web sinks (`child:` prefixed per-window routing with the main path byte-identical; `registerChildWebSink`/`registerChildWebEvalSink` NAPI probing), the new `OpenHarmonyChildWeb.cs` (per-window `sub-N` slot pool Max=2, 64-entry pre-ready queue, `w:<win>|capacity|<n>` readiness), and the 5-file slice routing; the first device round exposed the **capacity wire mismatch** (state carried `capacity` while managed parsed only `capacity|<n>` -> the event was dropped and the queue never flushed), fixed by emitting `w:<win>|capacity|<n>` plus accepting the URL form, with a `capacity wire` suite pin; the device closed loop (JIT) reaches `child web host registered` -> `child web capacity: sub-1 2` -> `child web cmd: data s0` -> `slot create/attached` -> `CHILD WEB OK` -> `navigated: Success` -> `eval title` -> click read-back `CHILD WEB TAP` with main-window zero regression (dual-window 60.0/60.0 fps, close slot destroy + WMS residue 0, 0 new faults); **SEC-SCAN-6 A/B/C closed** (A partitions allocate only through `begin_for`; B the primary window id is rejected on the child channel; C the close hook clears the child Capacity/Pending and the a11y frame/first-publish markers, +2 checks, 3x assert=False red control); the **L2CAP probe** puts the platform cap at **255 concurrent app subwindows** (the 256th `1300002`, stable over 3 rounds; destroy 255/255, no residue, recoverable) so **the app-level N=1 child window is a shell contract, not a platform limit**; **documented downgrades (not failures):** child a11y action e2e platform limit (external rerun), child ArkWeb hybrid/blazor asset bridge (explicit rejection; next wave = shell-side `onInterceptRequest` serving + per-window registration replay), child IME manual card (uitest cannot inject into the child XComponent), child B6 navigation veto unwired, child pool full (>2 controls) not mounted + pre-ready queue overflow drops one log line, ArkWeb `loadData` bare-`#` platform note, SEC-6 native a11y partition resident (bounded); pre-signed assets refreshed to #51 (68,447,288 / `e9fb1e90…`, asset 617093322; sidecar 88 B / `96948b04…`, asset 617094016); shell abc **473,048 / `298622c0…`**, headless 24,324, host **347,040 / `36acfc1d…`**, exports 163/163, suite **688/690 floor 670**; release tar **68,550,333 / `e5f6541c…`**, tree `a06d3897…`, sidecar `5c471871…`, `SHA256SUMS` 18 entries / 1,600 B / `5f8c1512…`; bundle **73,147,751 / `f4b4fe8d…`** (sdk anchor `a00e810c92`); CI 5/5 @ `696ebc0` (interaction 37548888210 / pixel 37548888313 / host-export 37548888169 / ridgraph 37548888051 / markdownlint 37548888104) + sdk run 37553127808; numbers follow the release notes `## Integrity (kit #51)`; acceptance: `docs/plans/2026-10-07-ohos-l2-consolidate.md` + `docs/plans/2026-10-06-ohos-tester-handoff-kit50.md` (cards carried).
>
> **2026-10-06 update (kit #50 — previous):** kit #50 = kit #49 (MULTIWINDOW-M + SEC-SCAN-4, carrying #48 CG2-R2R + AOT-STARTUP + FPS48 + MULTIWINDOW-S + FIXRR and #47/#46/#45) plus the full MULTIWINDOW-L stack (M1–M4 + SEC-SCAN-5a/5b/5c) and polish-49: M1 host per-window XComponent surface registry (window-id claim/release/route; registry 84/84, bridge 26/26); M2 slice per-window `OpenHarmonyWindowSurface`/`Renderer` + `OpenHarmonyWindowHost` with `RouteSurface/RouteTouch/RouteFrame` by window-id (headless dual-window 22 checks); M3 subwindow XComponent with the managed surface id (second MAUI visual tree; device `sub-1` 720x480 `first frame=True`, touch per window, close reclaims, reopen same id, churn x20 no residue); M4 per-window focus/IME/lifecycle/a11y partition/pinch (shell ACTIVE/INACTIVE -> per-window `IWindow.Activated/Deactivated/Stopped/Resumed`; per-window a11y shadow frames with the main provider unchanged; per-window pinch via `ohos_host_notify_window_pinch` to that window's renderer, exports 156 -> **157**); SEC-5a/5b/5c (unregisterXComponent failure closed + surface events routed per component; window-id validation failure closed + registerXComponent identity; the primary-to-child text thunk stays primary-window only, the cross-window text leak fixed); polish-49 (`ParseSubWindowOptions` optional booleans -> device E=0; the close WARN stays platform-internal; the Home key suspends via the focus-loss chain: INACTIVE -> 600 ms grace, `clearSubWindow` cancels the timer); device HAD-W32/W24 (2in1): dual-window steady **60.0/60.0 fps**, 40 min soak (RSS net -34 MB, pid constant), churn x20 (WMS residue 0), both JIT and AOT rounds; **documented downgrades (not failures):** child a11y provider (main provider unchanged, child shadow frames kept locally), child ArkWeb second host (slot pool stays on the primary window, no child web mount, no regression), platform-level multiple-subwindow cap not probed (app-level N=1 fails closed), **child IME actual typing manual card** (uitest `uiInput` has no child XComponent/multi-point injection surface; steps in `2026-10-06-ohos-multiwindow-l-m4.md`), SEC-5c B–F report-level items (B child prompt keyboard global / C state-machine ordering assumption / D Back/key consumer unwired / E pinch non-finite geometry / F child a11y frames retained); pre-signed assets refreshed to #50 (68,157,557 / `028d29f4…`, asset 615517779; sidecar 88 B / `02397318…`, asset 615518466); shell abc **436,808 / `289a5e5d…`**, headless 24,324, host **330,656 / `fdeb94eb…`**, exports 157/157, suite **661/663 floor 643**; release tar **68,264,136 / `d70dc786…`**, tree `b4b5055c…`, sidecar `2ffb3b6a…`, `SHA256SUMS` 18 entries / 1,600 B / `98fd0dd2…`; bundle **73,119,180 / `6a83c0f3…`** (sdk anchor `a3417a5489`); CI 5/5 @ `afa6d7a` (interaction 37460790068 / pixel 37460790072 / host-export 37460790087 / ridgraph 37460790138 / markdownlint 37460790028) + sdk run 37465689708; numbers follow the release notes `## Integrity (kit #50)`; handoff: `docs/plans/2026-10-06-ohos-tester-handoff-kit50.md`.
>
> **2026-10-05 update (kit #49 — previous):** kit #49 = kit #48 (CG2-R2R + AOT-STARTUP + FPS48 + MULTIWINDOW-S +
> FIXRR, carrying #47 FIX-A11YFLYOUT + FIX-PREEMPT-RAW and #46/#45) plus the in-app subwindow work (MULTIWINDOW-M:
> the shell `Window.createSubWindowWithOptions` subwindow controller with commands 0 create/1 move/2 resize/3 show/
> 4 hide (honest Failed 801, no public hide API)/5 close and events 0 created … 10 resumed; `pages/SubWindow.ets`
> is a shell-drawn named route `ohos_dotnet_subwindow` with a `WindowProperties.name` move guard; main-window
> HIDDEN/SHOWN forwards suspended/resumed and suppresses commands while suspended; the host adds
> `registerSubWindowSink`/`notifySubWindowEvent` NAPI and `ohos_host_sub_window_command` (op 99 probe)/
> `ohos_host_sub_window_event_listener` exports 151 -> **153**; the slice `OpenHarmonySubWindow` carries the
> command/event state machine, AOT-safe, off-device degradation; device `app://subwindow/demo` create id=344
> (120,160 720x480) -> move 420,360 -> resize 900x600 -> close, touch #57, drag #51 -> 269,259, main window
> 60 fps, no new fault; honest boundary: single surface/renderer, the subwindow content is shell-drawn ArkUI,
> per-window renderer/surface is L) and the a11y password masking (SEC-SCAN-4: `OpenHarmonyAccessibility`
> publishes equal-length dots for `IEntry{IsPassword}`/platform `IsPassword`, two new suite pins, offline
> red/green negative control, not device-verified; six more findings stay report-level). Pre-signed assets are
> refreshed to #49 (67,807,185 / `56aaf08f…`, asset 612929512; sidecar 88 B / `4ba00cf8…`, asset 612930421).
> Shell abc 414,532 / `e016db13…`, headless 24,324, host 301,984 / `cf4cc706…`, exports 153/153, suite 607/609
> floor 589. Release: tar 67,888,851 / `477974bb…`, tree `8d03cb4c…`, sidecar `3803b3db…`, bundle 73,085,186 /
> `7d06e781…` (sdk anchor `7abaf8132f`). Numbers follow the release notes `## Integrity (kit #49)`; handoff:
> `docs/plans/2026-10-05-ohos-tester-handoff-kit49.md`.
>
> **2026-10-05 update (kit #48 — previous):** kit #48 = kit #47 (FIX-A11YFLYOUT + FIX-PREEMPT-RAW) plus the
> JIT R2R startup work (CG2-R2R: the rc.2 Crossgen2 pack `crossgen2-packs-11.0.0-rc.2`, 43,792,647 / `6bb8a375…`,
> is consumed as a folder feed; `-p:PublishReadyToRun=true` takes the JIT cold start from 1031 to 710 ms (-31%,
> n=3; in-proc present 575 -> 307) while the interpreter stays R2R-free via `DOTNET_ReadyToRun=0` under
> `interp=3` (FIXRR, matching the runtime's implicit `fReadyToRun=false` for `InterpMode>=2`; JIT/mixed 1/2
> unchanged)), the AOT first-frame saving (AOT-STARTUP: the hidden ArkWeb overlays mount on first use and the
> host skips the same app-context surface replay, moving the ~240 ms CEF init out of the first-frame path: AOT
> AMS->first frame 796 -> 534 ms (-33%), attach->surface 239 -> 13 ms; JIT/interp not regressed), the frame-rate
> vote (FPS48: the host declares the expected 60 Hz range when registering the XComponent onFrame, so the RS
> 60/30 arbitration disappears and the interfering steady state goes 46.2 -> 60.0 fps), and the multi-window S
> shape (MULTIWINDOW-S: shell `supportWindowModes` fullscreen/split/floating + `windowSizeChange`/
> `freeWindowModeChange`; slice `CanArrangeSurface` re-arranges on Created/Changed >0 and keeps the last frame
> on Destroyed/0x0; 2in1 2090x1394 -> 3120x1955; suite +2). It carries everything from #47 (FIX-A11YFLYOUT
> nodeCount 1 -> 70, FIX-PREEMPT-RAW `[maui-capacity]`, INTERP-DRAW2 60.1 fps, FIX-A11YBUTTON, AUTODISCONNECT,
> INTERP-RENDER, dynamic slots MAX/HOT 4/2, AOT by default, FRAMEPACING). Pre-signed assets are refreshed to
> #48 (67,651,331 / `2f2f4c40…`, asset 612061141; sidecar 88 B / `50a1f38e…`, asset 612062470). Shell abc
> 375,268 / `9cd2b4c3…`, headless 24,324, host 297,888 / `319db8e5…`, exports 151/151, suite 599/601 floor
> 581. Release: tar 67,735,148 / `5c22704f…`, tree `6b2b493c…`, sidecar `1c51cdbc…`, bundle 73,053,084 /
> `3b62cee2…` (sdk anchor `767c03ee71`). Numbers follow the release notes `## Integrity (kit #48)`; handoff:
> `docs/plans/2026-10-05-ohos-tester-handoff-kit48.md`.
>
> **2026-10-05 update (kit #47 — previous):** kit #47 = kit #46 (INTERP-DRAW2 + FIX-A11YBUTTON) plus the
> FlyoutPage accessibility fix (FIX-A11YFLYOUT: `PushChildren` now publishes `FlyoutPage.Detail` always and
> `FlyoutPage.Flyout` only when presented — the rc.1 FlyoutPage is not an `IContentView`, so the old
> presented-content branch never matched and only the root was published; `--a11y-probe` nodeCount goes
> 1 -> 70 on device) and the preemption raw-text export (FIX-PREEMPT-RAW: the shell scans the new segment of
> `dotnet-status.txt` on each poll and writes every `overlay preempted/restored/replay` line to hilog with a
> `[maui-capacity]` prefix; the device replay captured five raw lines: `preempted: slot 0`,
> `preempted: slot 1`, `restored: slot 1`, `replay: slot 1`). It carries #46 (INTERP-DRAW2: off-surface culling
> lifts interp draw 14.4 -> 9.4 ms/frame and 33.9 -> 60.1 fps with no JIT regression; FIX-A11YBUTTON: the
> self-check button is pinned to the bottom-left above the overlays, reachable in both states) and #45
> (AUTODISCONNECT, INTERP-RENDER, dynamic slots, AOT by default, FRAMEPACING) with #42 and all earlier fixes.
> Pre-signed assets are refreshed to #47 (67,639,132 / `f58c4906…`, asset 610975429). Shell abc 370,240 /
> `4b439e83…`, headless 24,324, host 297,888 / `7b1694d9…`, exports 151/151, suite 593/595 floor 575. Release:
> tar 67,706,719 / `3d6bb58b…`, tree `0f266636…`, sidecar `4adb0b60…`, bundle 73,059,625 / `27c54c62…`
> (sdk anchor `266b196106`). Numbers follow the release notes `## Integrity (kit #47)`; handoff:
> `docs/plans/2026-10-05-ohos-tester-handoff-kit47.md`.
>
> **2026-10-04 update (kit #45 — previous):** kit #45 = kit #44 (dynamic overlay slots + AOT by default + FRAMEPACING)
> plus AUTODISCONNECT and INTERP-RENDER: a removed web control releases its overlay slot (a dynamic slot is
> destroyed in the shell, `web slot destroy`; the hot pair keeps its component) and a re-added control re-claims
> a slot and replays its load/registration (`web slot create`) while the handler stays connected; on device the
> kit sample (no explicit DisconnectHandler) logs `web slot destroy: 2` at 12:40:50 and `web slot create: 2` at
> 12:41:00 with interaction restored (c1-c5). The render layout gate skips the per-frame full Measure/Arrange when
> no real invalidation signal fired: interpreter 20.7 -> 30 fps (22.0 -> 30.1), meas 13.0 -> 0.0 ms/frame, main
> thread CPU 79.6-81.8% -> 65.5-70.5% (-13pt); JIT/AOT stay at 60 fps and draw/pres are unchanged. The suite is
> 587/589 floor 569 (AUTODISCONNECT +3 pins). The pre-signed assets are refreshed to #45
> (67,624,950 / `e1ce8ab6…`, asset 609411819). Shell abc 368,812 / `1076a700…`, headless 24,324,
> host 297,888 / `7b1694d9…`, exports 151/151. Release: tar 67,695,181 / `ca48a93c…`, tree `ae0f7fce…`,
> sidecar `9741aced…`, bundle 73,058,366 / `a8334c4c…` (sdk anchor `c7ac81ccdf`). Numbers follow the release
> notes `## Integrity (kit #45)`; handoff:
> `docs/plans/2026-10-04-ohos-tester-handoff-kit45.md`.
>
> **2026-10-04 update (kit #44 — previous):** kit #44 = kit #43 (AOT by default + FRAMEPACING) plus the dynamic
> overlay slots (SLOTS-DYNAMIC; ohos-workload `88e5aec` + MAUI slice `3feb347414`): the pool honours configurable
> MAX/HOT limits (default 4/2), creates slots on demand (`slot ensure`) and destroys released dynamic slots
> immediately (`slot destroy`; the hot pair [0,1] stays resident), downgrades/preempts by owner-LRU on capacity
> events, replays deferred shell commands per slot (queue <=32) and uses ForEach slots + `SetShellCapacity` —
> three concurrent web controls stay interactive on device (slot recycle/rebuild, Blazor hot swap). The kit ships
> AOT by default (five NativeAOT MAUI haps, `runtime-mode.txt=aot`, no JIT runtime libraries; JIT remains
> available via `--runtime-mode jit` and needs the AGC ACL/waiver outside the debug domain) and carries
> FRAMEPACING (host present telemetry; 17.7 fps was the shell status-poll artifact, real 60.00 fps). The pre-signed
> assets are refreshed to #44 (7 haps, 67,627,789 / `75a40110…`, asset 608782132). Shell abc 368,812 /
> `1076a700…`, headless 24,324, host 297,888 / `7b1694d9…`, exports 151/151, suite 584/586 floor 566. Release: tar
> 67,680,863 / `b777d8d8…`, tree `db2604d5…`, sidecar `85d62a6e…`, bundle 73,052,763 / `3b3008a4…` (sdk anchor
> `2abf4fcaa3`). Numbers follow the release notes `## Integrity (kit #44)`; handoff:
> `docs/plans/2026-10-04-ohos-tester-handoff-kit44.md`.
>
> **2026-10-03 update (kit #42 — older):** kit #42 = #41 + the JIT unlock, the rc2b interpreter first
frame, FIX-SLICERACE (8/8) and L6/LEGACY/SAMPLE-FIX/WX-PATCH2/P2c/mirror work. JIT unlock (WX-HOST-PRCTL):
the host enables `prctl(0x6a6974)` JITFORT by default and falls back to invariant globalization when the
image has no system ICU — JIT now reaches its first frame on device (`canvas presented` 4–8; probe
`1=OK 2=OK`; escapes `DOTNET_OHOS_NO_JITFORT=1` / `DOTNET_OHOS_ICU`). The interpreter pack is refreshed to
rc2b (`ohos-interpreter-pack-rc2b.tar.gz`, 2,410,595 / `5974430509…`, asset 606999003, includes WX-PATCH2)
and also reaches its first frame (`canvas presented 2090x1324`; the INTERP-NULL was an rc.1 managed CoreLib
x rc.2 native QCall ABI mismatch in a stale test hap, not a pack defect). FIX-SLICERACE serializes the
handler wiring race (reentrant connect + ready latch) — 8/8 JIT device rounds pass. Plus L6 (screenshot
JPEG / title heartbeat; shell abc 356,468 / `dd04dad1…`), the LEGACY toolbar close-out, SAMPLE-FIX
(`blzProbe` = `dotnet-ref ok`, the Blazor `#app` restored, `dotnet.zip` 258), WX-PATCH2 and the P2c
`skills[].uris` declaration. Host fully rebuilt: 297,888 / `08abe185…`, exports 151/151, UND 240. The
pre-signed assets are NOT refreshed (still the #41 items pointing at #41 content). Shell abc 356,468,
headless 24,324, suite 578/580 floor 560. Release: tar 376,256,128 B / `ea4e3b58…`, tree `13f3a086…`,
sidecar `878d05a1…`; numbers follow the release notes `## Integrity (kit #42)`; handoff:
`docs/plans/2026-10-03-ohos-tester-handoff-kit42.md`.
>
> **2026-10-03 update (kit #41 — previous):** kit #41 = #40 + MULTI-OVERLAY-FULL + DEVCOMPAT-DEFAULT +
INTERP-FIX. MULTI-OVERLAY-FULL (maui 07423dfe93 + ow 0e0129e): a two-slot ArkWeb overlay pool with
owner-aware LRU preemption/restore (`IOpenHarmonyOverlaySlotOwner`), per-slot hybrid serve/message/invoke
channels (slot-tagged invoke ids), activation-order z-order; two Hybrids on one page each round-trip
invoke/message, a third control preempts by LRU and activate replays the load. DEVCOMPAT-DEFAULT (ow
12be59c): the per-file code-sign rewrite is on by default (no-extension -> `.so`, exactly 4096 B -> +4 B),
so enforcing 7.0.0.111+ installs out of the box (15 `.so` / 257 zip entries). INTERP-FIX (ow c9916cd): the
host uses an 8 MB app thread stack and disables the GC write-barrier copy under `interp=3`; the rc.2
interpreter pack is a new asset `ohos-interpreter-pack-rc2.tar.gz` (2,409,070 B / `34709a94…`, asset
605924427). The pre-signed assets are refreshed to #41 (tester UDID; 376,684,381 / `2075650a…`, asset
606183753). FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount/FIX-JSCALL are kept. Shell abc 356,140
(`2a90f0d7…`), headless 24,324, host `8d67def3`, exports 150/150, suite 563/floor 543. Release: tar
376,036,502 B / `bed460ae…`, tree `7ce1946e…`, sidecar `2a95e764…`; numbers follow the release notes
`## Integrity (kit #41)`; handoff: `docs/plans/2026-10-03-ohos-tester-handoff-kit41.md`.
>
> **2026-10-02 update (kit #40 — previous):** kit #40 = #39 + FIX-JSCALL (the BlazorWebView IPC outbound
half is now AOT-rooted: `IpcSender.BeginInvokeJS` serializes `JSCallResultType`/`JSCallType` and
`IpcSender.Navigate` serializes `NavigationOptions` through the WebView package's reflection resolver,
where NativeAOT had no code for the `EnumConverter<T>`/`JsonTypeInfo<T>` closed instances — the attach
interop died in `IpcCommon.Serialize` and the FIX-BWVMount stub interop swallowed later clicks; the slice
re-carries the three types in its source-gen context, touches the type infos in the handler static ctor
and removes the stub probe; maui 15d81f31b1 + suite pin 2028cc2/9073c65). Device: the razor counter
round-trips **0 -> 1 -> 2** (screenshots r0/r1/r2; `missing native code`=0). Shell abc 342,160
(`ffda66da…`), headless 24,324, host `384e552a`, exports 150/150, suite 555/floor 535. Release: tar
375,836,470 B / `31ab8732…`, tree `e950de54…`, sidecar `9b051247…`; numbers follow the release notes
`## Integrity (kit #40)`; handoff: `docs/plans/2026-10-02-ohos-tester-handoff-kit40.md`.
>
> **2026-10-02 update (kit #39 — previous):** kit #39 = #38 + FIX-BACKSIZE (the system Back key now
closes the drawer via the shell `onBackPress(): boolean` -> host `host.backPressed` /
`ohos_host_register_back_pressed` (exports 149->150); a second Back falls back to the system
`#BACKGROUND`; `BlazorWebView` overrides `GetDesiredSize` — it returned 0 before, so its frame
degraded and was ignored; maui be09a48817 + shell/host 9e6519e) and FIX-BWVMount (`.razor` components
now mount under NativeAOT — the handler static ctor keeps the WebView package's reflection-built
`JsonElement[]` converter in the AOT image; maui 52b082a071). FIX-HOME/FIX-ITOUCH/FIX-DISMISS/FIX-WVP
are kept. Shell abc 342,160 (`ffda66da…`), headless 24,324, host `384e552a`, exports 150/150, suite
554/floor 534. Release: tar 375,765,521 B / `e95eed49…`, tree `932e7955…`, sidecar `e5fc82de…`;
numbers follow the release notes `## Integrity (kit #39)`; handoff:
`docs/plans/2026-10-02-ohos-tester-handoff-kit39.md`.
>
> **2026-10-01 update (kit #38 — previous):** kit #38 = #37 + FIX-DISMISS (the flyout drawer outside-click
dismiss: the `Default` layout threw `InvalidOperationException` under the device's non-Phone idiom /
landscape snapshot — the exception was swallowed at the touch-callback boundary — so `Default` now maps to
`Popover`; maui 86b439ffc8) and FIX-WVP (the Hybrid overlay: element px rendered as ArkUI vp → ×1.9
off-window, hybrid origin `0.0.0.1` registration arbitration, `Web` moved above the ContentSlot for
z-order, and suspend/resume/hide under a drawer or tab switch; maui 47d79add01 + shell acbe750).
FIX-HOME/FIX-ITOUCH are kept. Shell abc 341,560 (`4f02cb1d…`), headless 24,324 (unchanged), host
`4e9f3c3e`, export 149/149, suite 550/floor 530. The FIX-BACK wave is not in this kit (Back-closes-drawer
and BlazorWebView sizing are in flight for the next version). Numbers follow the release notes
`## Integrity (kit #38)`; handoff: `docs/plans/2026-10-01-ohos-tester-handoff-kit38.md`.
>
> **2026-10-01 update (kit #37 — previous):** kit #37 = #36 + FIX-HOME (the slice descends a
NavigationPage's `PlatformArrange` into its `CurrentPage` — the Home tab now draws its full page on the
AOT device, screenshot-proved; the suite gains 4 pins, 544/floor 524) and FIX-ITOUCH (the host reports
touch points in element coordinates — the same surface space as the mouse — so uitest-injected taps hit
content: "fading out…" -> "animations done" on device; host `4e9f3c3e`). The shell abc is unchanged
(339,964 / 24,324), host export 149/149. Release: tar 375,652,577 B / `3a7259d6…`, tree `ab517b57…`,
sidecar `7db60a77…`; numbers follow the release notes `## Integrity (kit #37)`; handoff:
`docs/plans/2026-10-01-ohos-tester-handoff-kit37.md`.
>
> **2026-10-01 update (kit #36 — previous):** kit #36 = #35 + the payload-in-place direct start (the shell
`findLibsPayloadDir` accepts the module layout `<bundleCodeDir>/<module>/libs/<abi>` — on device
hello-maui-wasm starts from `/data/storage/el1/bundle/entry/libs/arm64` with `dotnet.zip not unpacked`
(pid 49565) and `BLZ_BOOT`/`BLZ_RENDERED` both land), the host pre-registration buffer (web commands
arriving before the shell registers `registerWebSink` are buffered — 16 commands / 64 KiB — and flushed
on registration; suite pins `moduleRoot`/`webPending`), the pixel suite with no `Known(...)` left
(selection tint asserted byte-exactly), the a11y render-frame attachment fix (`nodeCount 0` was the
unpublished shadow tree; `status=1`, nodeCount 5/24 stable) and the rc.2 AOT pack `-r2` fix (OpenSSL shim;
the rc.1 pin can be dropped). New shell abc 339,964 / 24,324, host export 149/149, suite 540/floor 520.
Numbers follow the release notes `## Integrity (kit #36)`; handoff:
`docs/plans/2026-10-01-ohos-tester-handoff-kit36.md`.
>
> **2026-09-30 update (kit #35 — previous):** kit #35 = #34 + the W9/W10 waves (W9A B2: Blazor WASM in the
MAUI WebView, now passing on device with `BLZ_BOOT`/`BLZ_RENDERED`; W9B T14/T21; W9C T8; W9D the T20
media transport layer + the T19 deep-link determination; W10 the AOT-entry fix — host own-libs
`lib<stem>.so` resolution + `dotnet-status.txt` observability, the shell AOT payload probe / `fs` alias /
static-asset fingerprint, and the rc.2 AOT pack OpenSSL-shim regression with a local rc.1 pack pin); new
shell abc 339,164 / headless 23,516, host export 149/149, suite 540/floor 520. Numbers follow the release
notes `## Integrity (kit #35)` and the in-kit checks; handoff:
`docs/plans/2026-09-30-ohos-tester-handoff-kit35.md`.

Everything in this list is blocked on an install-eligible device (`hdc` is restricted in this
environment). Each step names the artifact, the command and the observable result, so a single
session on a device closes the whole port validation.

Updated 2026-09-21: §6 adds the S/T-series capabilities (Blazor/hybrid bridge page,
keep-screen-on, static asset fingerprint fallback + cache headers, file share, flashlight,
accessibility node count and the performance budget), and §0 names the preview.24 artifacts
they need. The older sections stay valid on the same hap.

Updated 2026-09-21 (kit #5): §0 records the kit identity check to run before installing
(sha256 + tree digest; the five haps need no `module.json` edits — legal bundle name and a
device-aligned profile), and §8 adds the P1–P4 startup-crash probe ladder and the fill-in
report template to what to return.

Updated 2026-09-22 (kit #7): the kit identity values live in the release notes, not here — §0
reads the tarball sha256 and the extracted-tree digest from the `device-test-kit` release notes
(`## Integrity`) or the `.sha256` sidecar, so a re-signed or repacked kit can never contradict
this document. Kit #35 numbers (release notes `## Integrity (kit #35)`) are: tar **375,629,423 B** / `419d42e2…`, tree `d3b1b317…`, `SHA256SUMS` 17 entries / 1,517 B / `2dd447a7…`; the kit #34 snapshot: tar **375,181,367 B** / `55834aeb…`, tree `d08de3ec…`; the kit #33 snapshot (measured: tar **218,138,546 B** / `38e4d57a…`, tree `064cb001…`, sidecar `8297363e…`; release notes `## Integrity (kit #33)`; kit #32 numbers follow for comparison,
PATCHed 2026-09-28): tar **207,023,588 B** / `f4325d2f…`, tree **`52e77ee8…`**, sidecar
**`7d0cba77…`**, `SHA256SUMS` 16 entries / 1,410 B / `f49b9a0e…` (the kit #31 handoff
`docs/plans/2026-09-29-ohos-tester-handoff-kit31.md` carries the full table; tester-run v13
137,113 B / `2caa06bd…`, asset 594519342; #30 was tar 196,992,264 / `a781c25b…`, #29
196,990,205 / `e895cc0a…`); the #28 comparison values were
tar **196,220,486 B** / `091dcc56…`, tree **`0a7a3215…`**, sidecar `d7efd251…` (see
`docs/plans/2026-09-26-ohos-tester-handoff-kit28.md`).

Updated 2026-09-24 (kit #21, historical snapshot — superseded by the kit #22/#23 notes below): the current kit is #21 — all five haps carry `libIsolation` plus the
complete security/performance/startup fix set since #17 (frame allocation 241,688 → 4,504 B/frame;
P17 extraction skip, H7 rawfile fd read, headless abc `13.0.1.0`) and `tester-run.sh` v6r2 now
collects app-lib/dlopen evidence, kmsg and the XPM/fs-verity probes automatically. The comparison
payloads (dynpkg/normalized/importb/importd/importprobe a–c) and P1–P4 remain on the same release.
Numbers stay in the release notes `## Integrity` (kit #32 measured: tar **207,114,608 B** / `8f690949…`, tree **`645879bc…`**, sidecar **`344760e7…`** (bundle 30,566,929 / `286a923e…`, tester-run v14 140,197 / `a174fcd0…`, razor asset 38,968,818 / `5e549506…`); kit #31 measured: tar **207,023,588 B** / `f4325d2f…`, tree **`52e77ee8…`**, sidecar **`7d0cba77…`**; kit #30 comparison: tar **196,992,264 B** / `a781c25b…`; kit #28 comparison: tar `196,220,486 B` / `091dcc56…`, tree `0a7a3215…`); the kit's `签名说明.txt` PA1 sentence is
historical wording (source fixed, next kit packaging).

Updated 2026-09-24 (kit #22): the current kit is #22 — a stock-runnable back-port of the on-device
milestone fixes: the host ships a 5-soname `DT_NEEDED` whitelist and resolves every optional system
API through dlopen/dlsym, every hap carries `resources.index` (restool legacy on the device band,
RestoolV2 on API 20), the bootstrap copies the payload ZIP by offset/length and mkdirs the payload
directory before inflating, and the generated shell project mirrors DevEco (`modelVersion 6.0.2`,
00302013 diagnostics). The 2026-09-24 device milestone (kit #18 + five local fixes, first full run)
is recorded in `2026-09-24-ohos-device-milestone.md`; **stock kit (from #22 on; #23 tool refresh, #24
payload-in-libs) has not been on a device yet**, so the checks below remain open — use the milestone §6
decision points (A host load / B bootstrap / C milestone regression) as the first pass/fail gates.

Updated 2026-09-24 (kit #24, historical snapshot — superseded by the #25–#30 notes below): **payload-in-libs + explicit W^X=0 + exec-memory probe**: the
hap `libs/arm64-v8a/` now carries the whole payload plus `.dotnet-payload.json` (the runtime starts
in place from the signed bundle directory; `dotnet.zip` stays as the fallback; the signed hap grows
from ~32.7 MB to ~75.3 MB). The host pins `DOTNET_EnableWriteXorExecute=0` on both launch paths and
adds the `xwe.txt` A/B switch plus the one-shot `OHOS_DOTNET probe: 1=… 2=… 3=… 4=…` line (token 1
anonymous RWX, 2 anonymous RW->RX, 3 memfd RX, 4 file RX; `OK` or errno). The bundled
`tester-run.sh` is now **v8** (`script_version=8`) and collects `hilog/hilog-execmem.txt`
(`execmem_capture`/`execmem_lines` in `summary.txt`) on top of `hilog/hilog-bootstrap.txt`,
`device/payload-files.txt`/`payload-marker.txt` and `meta/kit-selfcheck.txt`
(`kit_index_ok`, `payload=yes|no`). With payload-in-libs, `payload_present=no` is normal (that key
only reflects the fallback filesDir extraction). Judgement: `kit_index_ok=no` means the kit
predates #22 — re-download the current kit; `bootstrap_errors`/`rawfile_errors`>0 are reportable
signatures (see `hilog-bootstrap.txt`) and do not fail the round by themselves. JIT verdict table
and NativeAOT handoff: `2026-09-24-ohos-tester-handoff-kit24.md`; the kit #25 judgement points
(permission dialog copy / Share panel / Scan return / AOT startup): `2026-09-25-ohos-tester-handoff-kit25.md`;
the kit #26 incremental points (first run of the rebuilt payload / native-bridge ABI / PLAT-GAP consumer
path; still valid): `2026-09-26-ohos-tester-handoff-kit26.md`; the kit #27 incremental points (no-HMS
degradation must not throw for Push/Account/Map, first run of the rebuilt payload; history):
`2026-09-27-ohos-tester-handoff-kit27.md`; the kit #28 incremental points (Map overlay / Live View probe /
AOT start bridge / interpreter experiment): `2026-09-26-ohos-tester-handoff-kit28.md`; the kit #29 incremental
points (CoreSpeechKit TTS / HUKS-first SecureStorage / tester-run v11 matrix + a11y / text editing / animations /
lists / images / deep links): `2026-09-28-ohos-tester-handoff-kit29.md`; the kit #30 incremental
points (runtime-mode packaging switch / tester-run v12 / MAPFIX harmony re-cut): `2026-09-28-ohos-tester-handoff-kit30.md`; the kit #31 Blazor component points (6th unsigned hap `hello-blazorwasm-host-unsigned.hap`, bundle `com.example.opendotnet`, tester-run v13 `--blazor-probe` asserting `BLZ_BOOT`/`BLZ_RENDERED`, manual first screen //counter/screenshot): `2026-09-29-ohos-tester-handoff-kit31.md`.

Updated 2026-10-07 (kit #51 — current): **MULTIWINDOW-L2 (a11y child provider + child ArkWeb second host) + SEC-SCAN-6 A/B/C + L2CAP probe** (carrying #50 MULTIWINDOW-L M1–M4 + SEC-SCAN-5a/5b/5c + polish-49 and #49/#48–#45): per-instance a11y node-table partition with the WithInstance provider (W0/W2 device PASS; exports 163/163); child ArkWeb sink + `OpenHarmonyChildWeb` pool with the capacity-wire fix (device closed loop, main 60/60 fps); SEC-6 C close hook; platform cap 255 subwindows (app N=1 is a shell contract). Documented downgrades: a11y action e2e platform limit, child ArkWeb hybrid/blazor asset bridge, IME manual card, B6 veto, pool/queue bounds. Pre-signed assets refreshed to #51 (68,447,288 / `e9fb1e90…`, asset 617093322). Suite 688/690 floor 670, exports 163/163, shell abc 473,048 / `298622c0…`, headless 24,324, host 347,040 / `36acfc1d…`. Release: tar 68,550,333 / `e5f6541c…`, tree `a06d3897…`, sidecar `5c471871…`, bundle 73,147,751 / `f4b4fe8d…` (sdk anchor `a00e810c92`). Numbers follow the release notes `## Integrity (kit #51)`; acceptance: `docs/plans/2026-10-07-ohos-l2-consolidate.md`.
>
Updated 2026-10-06 (kit #50 — previous): **MULTIWINDOW-L (M1–M4) + polish-49** (carrying #49 MULTIWINDOW-M + SEC-SCAN-4 and #48 CG2-R2R + AOT-STARTUP + FPS48 + MULTIWINDOW-S + FIXRR): host per-window surface registry (84/84) + window bridge (26/26); per-window surface/renderer/input state routed by window id; the child window hosts an XComponent and carries the managed surface id (second MAUI visual tree, 720x480, `first frame=True`); per-window focus/IME/lifecycle/a11y partition/pinch (exports 157/157); SEC-SCAN-5a/5b/5c hardening; polish-49 (create E=0, close WARN platform-internal, Home focus-loss-chain suspend). Pre-signed assets refreshed to #50 (68,157,557 / `028d29f4…`, asset 615517779). Suite 661/663 floor 643, exports 157/157, shell abc 436,808 / `289a5e5d…`, headless 24,324, host 330,656 / `fdeb94eb…`. Release: tar 68,264,136 / `d70dc786…`, tree `b4b5055c…`, sidecar `2ffb3b6a…`, bundle 73,119,180 / `6a83c0f3…` (sdk anchor `a3417a5489`). Numbers follow the release notes `## Integrity (kit #50)`; handoff: `docs/plans/2026-10-06-ohos-tester-handoff-kit50.md`.
>
Updated 2026-10-05 (kit #49 — previous): **MULTIWINDOW-M + SEC-SCAN-4 (a11y password masking)** (carrying #48 CG2-R2R + AOT-STARTUP + FPS48 + MULTIWINDOW-S + FIXRR and #47):
> The shell's subwindow controller (`Window.createSubWindowWithOptions`) implements commands 0 create/1 move/2 resize/
> 3 show/4 hide (honest Failed 801: no public hide API)/5 close with events 0 created … 10 resumed, plus main-window
> HIDDEN/SHOWN -> suspended/resumed and command suppression while suspended; `pages/SubWindow.ets` is a shell-drawn
> named route (`ohos_dotnet_subwindow`, `WindowProperties.name` move guard). The host adds the
> `registerSubWindowSink`/`notifySubWindowEvent` NAPI pair and the `ohos_host_sub_window_command` (op 99 probe) /
> `ohos_host_sub_window_event_listener` exports (151 -> **153**); the slice `OpenHarmonySubWindow` carries the
> command/event state machine (AOT-safe, off-device degradation). Device (HAD-W32, 2in1): `app://subwindow/demo`
> create **id=344 (120,160 720x480)** -> page ready -> move **420,360** -> resize **900x600** -> close; touch #57 and
> drag #51 -> 269,259; main window HIDDEN/SHOWN -> suspended/resumed at 60 fps, no new fault. SEC-SCAN-4 masks the
> a11y shadow tree: `OpenHarmonyAccessibility` publishes equal-length dots for `IEntry{IsPassword}`/platform
> `IsPassword` (two new pins, offline red/green negative control, not device-verified). It carries everything from
> #48 (+ #47/#46/#45). Pre-signed assets are refreshed to #49 (67,807,185 / `56aaf08f…`, asset 612929512; sidecar
> 88 B / `4ba00cf8…`, asset 612930421). Suite **607/609 floor 589**, exports **153/153**, shell abc
> **414,532 / `e016db13…`**, headless 24,324, host 301,984 / `cf4cc706…`. Release: tar 67,888,851 / `477974bb…`,
> tree `8d03cb4c…`, sidecar `3803b3db…`, bundle 73,085,186 / `7d06e781…` (sdk anchor `7abaf8132f`); numbers
> follow the release notes `## Integrity (kit #49)`; handoff: `docs/plans/2026-10-05-ohos-tester-handoff-kit49.md`.
>
Updated 2026-10-05 (kit #48 — previous): **CG2-R2R + AOT-STARTUP + FPS48 + MULTIWINDOW-S + FIXRR** (carrying #47 FIX-A11YFLYOUT + FIX-PREEMPT-RAW):
> JIT R2R (Crossgen2 rc.2 folder feed + `PublishReadyToRun=true`) takes the JIT cold start 1031 -> 710 ms (-31%,
> n=3); the interpreter stays R2R-free (`DOTNET_ReadyToRun=0` under `interp=3`, FIXRR). AOT first frame 796 -> 534 ms
> (-33%) after the hidden ArkWeb overlays mount on first use and the host skips the same app-context surface replay.
> The XComponent registers an expected 60 Hz range so the interfering steady state goes 46.2 -> 60.0 fps. The shell
> declares `supportWindowModes` and the slice `CanArrangeSurface` follows window resize (2in1 2090x1394 ->
> 3120x1955). It also carries #47 (FIX-A11YFLYOUT nodeCount 1 -> 70, FIX-PREEMPT-RAW `[maui-capacity]`) and #46/#45.
> The pre-signed assets are refreshed to #48 (67,651,331 / `2f2f4c40…`, asset 612061141). Suite **599/601 floor
> 581**, exports **151/151**, shell abc **375,268 / `9cd2b4c3…`**, headless 24,324, host 297,888 / `319db8e5…`.
> Release: tar 67,735,148 / `5c22704f…`, tree `6b2b493c…`, sidecar `1c51cdbc…`, bundle 73,053,084 / `3b62cee2…`
> (sdk anchor `767c03ee71`); numbers follow the release notes `## Integrity (kit #48)`; handoff:
> `docs/plans/2026-10-05-ohos-tester-handoff-kit48.md`.
>
> Updated 2026-10-05 (kit #47 — previous): **FIX-A11YFLYOUT + FIX-PREEMPT-RAW** (carrying #46 INTERP-DRAW2 + FIX-A11YBUTTON):
> the a11y walk now publishes `FlyoutPage.Detail` always and `FlyoutPage.Flyout` only when presented (rc.1
> FlyoutPage is not an `IContentView`), so `--a11y-probe` reports nodeCount 1 -> 70 on the kit sample; the shell
> also exports the raw `overlay preempted/restored/replay` lines from `dotnet-status.txt` to hilog with a
> `[maui-capacity]` prefix (device replay: `preempted: slot 0`, `preempted: slot 1`, `restored: slot 1`,
> `replay: slot 1`). #46 adds off-surface culling (interp draw 14.4 -> 9.4 ms/frame, 33.9 -> 60.1 fps, no JIT
> regression) and the bottom-left A11Y button above the overlays. The kit also carries #45 (AUTODISCONNECT,
> INTERP-RENDER, dynamic slots MAX/HOT 4/2, AOT by default, FRAMEPACING).
> The pre-signed assets are refreshed to #47 (67,639,132 / `f58c4906…`, asset 610975429). Suite **593/595 floor
> 575**, exports **151/151**, shell abc **370,240 / `4b439e83…`**, headless 24,324, host 297,888 / `7b1694d9…`.
> Release: tar 67,706,719 / `3d6bb58b…`, tree `0f266636…`, sidecar `4adb0b60…`, bundle 73,059,625 / `27c54c62…`
> (sdk anchor `266b196106`); numbers follow the release notes `## Integrity (kit #47)`; handoff:
> `docs/plans/2026-10-05-ohos-tester-handoff-kit47.md`.
>
> Updated 2026-10-04 (kit #45 — previous): **AUTODISCONNECT + INTERP-RENDER**: a removed web control releases its
> overlay slot (dynamic slot destroyed in the shell; hot pair keeps its component) and a re-added control re-claims
> a slot and replays its load/registration while the handler stays connected (kit sample: `web slot destroy: 2` at
> 12:40:50 -> `web slot create: 2` at 12:41:00 -> interaction restored); the render layout gate skips the per-frame
> full Measure/Arrange unless a real invalidation signal fired, lifting the interpreter from 20.7 to 30 fps
> (meas 13.0 -> 0.0 ms/frame, CPU -13pt) while JIT/AOT stay at 60 fps. The kit carries #44 (dynamic slots MAX/HOT
> 4/2, three concurrent web controls, AOT by default, FRAMEPACING). The pre-signed assets are refreshed to #45
> (67,624,950 / `e1ce8ab6…`, asset 609411819). Suite **587/589 floor 569**, exports **151/151**,
> shell abc 368,812 / `1076a700…`, headless 24,324, host 297,888 / `7b1694d9…`; tar **67,695,181** / `ca48a93c…`,
> tree `ae0f7fce…`, dtk **392356147** / latest **392077166**; numbers follow the release notes `## Integrity (kit #45)`; handoff:
> `docs/plans/2026-10-04-ohos-tester-handoff-kit45.md`.
>
> Updated 2026-10-04 (kit #44 — previous): **dynamic overlay slots + AOT by default**: the overlay pool honours MAX/HOT (default 4/2), creates slots on demand and destroys released dynamic slots immediately, replays deferred commands per slot and keeps the hot pair — three concurrent web controls stay interactive on device (slot recycle/rebuild, Blazor hot swap); the kit ships five NativeAOT MAUI haps by default (`runtime-mode.txt=aot`, no JIT runtime libraries) and carries FRAMEPACING (host present telemetry; 17.7 fps was the shell status-poll artifact, real 60.00 fps). The pre-signed assets are refreshed to #44 (7 haps, 67,627,789 / `75a40110…`, asset 608782132). Suite **584/586 floor 566**, exports **151/151**, shell abc 368,812 / `1076a700…`, headless 24,324, host 297,888 / `7b1694d9…`; tar **67,680,863** / `b777d8d8…`, tree `db2604d5…`, dtk **392356147** / latest **392077166**; numbers follow the release notes `## Integrity (kit #44)`; handoff:
> `docs/plans/2026-10-04-ohos-tester-handoff-kit44.md`.
>
> Updated 2026-10-03 (kit #42 — older): **JIT unlock + rc2b interpreter + FIX-SLICERACE**: the host enables `prctl(0x6a6974)` JITFORT by default and falls back to invariant globalization when the image lacks system ICU, so JIT now reaches its first frame on device (probe `1=OK 2=OK`, `canvas presented`, UI screenshots). The interpreter pack is refreshed to `ohos-interpreter-pack-rc2b.tar.gz` (2,410,595 / `5974430509…`, asset 606999003) and also reaches its first frame. FIX-SLICERACE serializes the handler wiring race (8/8 JIT rounds pass). Plus L6 (screenshot JPEG/title heartbeat; abc 356,468 / `dd04dad1…`), the LEGACY toolbar close-out, SAMPLE-FIX (`blzProbe`, demo `#app`), WX-PATCH2 and the P2c `skills[].uris` declaration. The pre-signed assets are NOT refreshed (still #41 items). Suite **578/580 floor 560**, exports **151/151**, shell abc 356,468 / headless 24,324, host `08abe185`; tar **376,256,128** / `ea4e3b58…`, tree `13f3a086…`, dtk **392356147** / latest **392077166**; numbers follow the release notes `## Integrity (kit #42)`; handoff:
> `docs/plans/2026-10-03-ohos-tester-handoff-kit42.md`.
>
> Updated 2026-10-03 (kit #41 — previous): **MULTI-OVERLAY-FULL + DEVCOMPAT-DEFAULT + INTERP-FIX**: a two-slot ArkWeb overlay pool with owner-aware LRU preemption/restore and per-slot hybrid invoke/message channels (two Hybrids on one page each round-trip; a third control preempts by LRU; activate replays the load); the per-file code-sign rewrite is on by default (enforcing 7.0.0.111+ installs out of the box; 15 `.so` / 257 zip entries); and the host uses an 8 MB app thread stack plus a disabled GC write-barrier copy under `interp=3` (the rc.2 interpreter pack is `ohos-interpreter-pack-rc2.tar.gz`, 2,409,070 B / `34709a94…`). The pre-signed assets are refreshed to #41 (tester UDID). Suite **563/floor 543**, exports **150/150**, shell abc 356,140 (`2a90f0d7…`) / headless 24,324, host `8d67def3`; tar **376,036,502** / `bed460ae…`, tree `7ce1946e…`, dtk **392356147** / latest **392077166**; numbers follow the release notes `## Integrity (kit #41)`; handoff:
> `docs/plans/2026-10-03-ohos-tester-handoff-kit41.md`.
>
> Updated 2026-10-02 (kit #40 — previous): **FIX-JSCALL**: the BlazorWebView IPC outbound half is now AOT-rooted (the `JSCall` enums and `NavigationOptions` are carried in the slice's source-gen context, so the WebView package's reflection resolver finds their converters) — the razor counter round-trips **0 -> 1 -> 2** on device (screenshots r0/r1/r2; `missing native code`=0). FIX-HOME/ITOUCH/DISMISS/WVP/BACKSIZE/BWVMount are kept. Suite **555/floor 535**, exports **150/150**, shell abc 342,160 (`ffda66da…`) / headless 24,324, host `384e552a`; tar **375,836,470** / `31ab8732…`, tree `e950de54…`, dtk **392356147** / latest **392077166**; numbers follow the release notes `## Integrity (kit #40)`; handoff:
> `docs/plans/2026-10-02-ohos-tester-handoff-kit40.md`.
>
> Updated 2026-10-02 (kit #39 — previous): **FIX-BACKSIZE + FIX-BWVMount**: the system Back key now closes the drawer (the shell `onBackPress()` routes to host `host.backPressed` / `ohos_host_register_back_pressed`, exports 150; a second Back falls back to the system) and `BlazorWebView` reports a real desired size; the `.razor` components now mount and render under NativeAOT (the WebView package's reflection-built `JsonElement[]` converter is kept in the AOT image). FIX-HOME/FIX-ITOUCH/FIX-DISMISS/FIX-WVP are kept. Suite **554/floor 534**, exports **150/150**, shell abc 342,160 (`ffda66da…`) / headless 24,324, host `384e552a`; tar **375,765,521** / `e95eed49…`, tree `932e7955…`, dtk **392356147** / latest **392077166**; numbers follow the release notes `## Integrity (kit #39)`; handoff:
> `docs/plans/2026-10-02-ohos-tester-handoff-kit39.md`.
>
> Updated 2026-10-01 (kit #38 — previous): **FIX-DISMISS + FIX-WVP**: the flyout drawer now dismisses on an outside click (re-open/re-close both work; no residue) and the Hybrid overlay really renders (element px converted to vp, hybrid origin `0.0.0.1` registration, `Web` above the ContentSlot, suspend/resume/hide under a drawer or tab switch; the page bridge round-trips `window.external.sendMessage`). FIX-HOME/FIX-ITOUCH are kept; the FIX-BACK wave (Back-closes-drawer, BlazorWebView sizing) is not in this kit. Suite **550/floor 530**, host export **149/149**, shell abc 341,560 (`4f02cb1d…`) / headless 24,324, host `4e9f3c3e`; tar **375,641,619** / `ced5583f…`, tree `307004e1…`, dtk **392356147** / latest **392077166**; numbers follow the release notes `## Integrity (kit #38)`; handoff:
> `docs/plans/2026-10-01-ohos-tester-handoff-kit38.md`.
>
> Updated 2026-10-01 (kit #37 — previous): **FIX-HOME + FIX-ITOUCH**: the Home tab (FlyoutPage -> TabbedPage -> NavigationPage) now draws its full page on the AOT device (screenshot-proved) and uitest-injected taps hit MAUI content (the host reports touch points in element coordinates, the same surface space as the mouse; "fading out…" -> "animations done"). Suite **544/floor 524**, host export **149/149**, shell abc 339,964 / headless 24,324 (unchanged), host `4e9f3c3e`; tar **375,652,577** / `3a7259d6…`, tree `ab517b57…`, dtk **392356147** / latest **392077166**; numbers follow the release notes `## Integrity (kit #37)`; handoff:
> `docs/plans/2026-10-01-ohos-tester-handoff-kit37.md`.
>
> Updated 2026-10-01 (kit #36 — previous): **payload in place + host pre-registration buffer + pixel Known-clear + a11y render-frame fix + rc.2 AOT pack `-r2`**: hello-maui-wasm starts from the module libs layout (`/data/storage/el1/bundle/entry/libs/arm64`, `dotnet.zip not unpacked`) and `BLZ_BOOT`/`BLZ_RENDERED` both land; the host buffers pre-registration web commands (16 / 64 KiB, flushed on registration); no `Known(...)` remains in the pixel suite; the a11y node count now pins the render-frame attachment (`status=1`, nodeCount 5/24 stable); the rc.2 AOT pack `-r2` asset (`601289590`) fixes the OpenSSL shim and drops the rc.1 pin. Suite **540/floor 520**, host export **149/149**, shell abc 339,964 / headless 24,324; tar **375,627,841** / `9eb9cecf…`, tree `9764827c…`, dtk **392356147** / latest **392077166**; numbers follow the release notes `## Integrity (kit #36)`; handoff:
> `docs/plans/2026-10-01-ohos-tester-handoff-kit36.md`.
>
> Updated 2026-09-30 (kit #35 — previous): **the W9/W10 waves**: B2 (Blazor WASM in the MAUI WebView) now passes on device (`BLZ_BOOT`/`BLZ_RENDERED`); T14/T21 and T8 (uneven-height TableView); the T20 media transport layer + the T19 deep-link determination; the W10 AOT-entry fix (host own-libs `lib<stem>.so` resolution + `dotnet-status.txt` observability, the shell AOT payload probe / `fs` alias / static-asset fingerprint; the rc.2 AOT pack OpenSSL-shim regression pins the rc.1 pack locally); suite **540/floor 520**, host export **149/149**, shell abc 339,164 / headless 23,516; numbers follow the release notes `## Integrity (kit #35)`; handoff:
> `docs/plans/2026-09-30-ohos-tester-handoff-kit35.md`.
>
> Updated 2026-09-30 (kit #34 — previous): **rc.2 baseline + MAUI waves W6/W7/W8**: the stack moves to SDK `11.0.100-rc.2.26451.112` / workload `1.0.0-preview.28` / MAUI `11.0.0-rc.2.26478.12` (a dnceng daily until it reaches nuget.org) with the CoreLib `LINUX` alias (`OS Platform: Linux`); the waves add T14 rich shell flyout, T12 CarouselView group slides, N1 multi-pointer coordinates, FIX-SHELL (Shell CurrentPage draws), T15 rich TitleView, T16 structured menus, N4 Window.TitleBar in the a11y shadow tree, T18 Essentials IMap, N5 overlay touch-passthrough suppression and N6 app-managed window decorations (suite **513/floor 493**, host export **145/145**); the AOT fallback asset is `aot-haps-v3.tar.gz` (17,537,186 / `004ba03c…`); numbers follow the release notes `## Integrity (kit #34)`; handoff:
> `docs/plans/2026-09-30-ohos-tester-handoff-kit34.md`. The kit #33 Blazor A/B and TabbedPage/W5 points keep working.
>
> Updated 2026-09-28 (kit #32 — history; kit #33 previous): **WebView six-item wiring + B1 razor asset + SEC round**: MAUI WebView/Hybrid/Blazor handlers (history/CanGoBack, cookies, frame, events, failure clear; device card `2026-09-28-ohos-webview-blazor-device-card.md`), B1 `hello-maui-razor` (bundle `com.example.hellomauirazor`), tester-run **v14** (Blazor probe pid+nonce), Blazor hap without INTERNET; the kit #31 Blazor component (a 6th,
unsigned hap `hello-blazorwasm-host-unsigned.hap` (26,794,931 B / `36010a9c…`, 219 entries, bundle
`com.example.opendotnet`, own shell abc 16,352 B @13.0.1.0; embedded site 210 files = `_framework` 208
with 204 `.wasm` + `blazor.webassembly.js`; declares `ohos.permission.INTERNET` - development-only
host, rawfile-served, no runtime network need; a re-signed copy keeps it only if the signing project
does). `tester-run.sh` is **v13** (137,113 B / `2caa06bd…`, asset 594519342) adding `--blazor-probe`
(install the re-signed hap, start `com.example.opendotnet`/`EntryAbility`, assert `marker: BLZ_BOOT` +
`marker: BLZ_RENDERED`, dump `blazor-hilog.txt` on failure); manual first screen "Hello from Blazor
WebAssembly" + `/counter` +1 + one screenshot. `verify-kit.sh` is **63,301 B / `67622771…`** (selftest
72 -> 92) and adds the section-2c Blazor assertions (when the component is present). **Stock kit (from
#22 on, #31 included) has not been on a device yet.**

Updated 2026-09-28 (kit #30 — history): **MS-MODE — runtime-mode packaging switch / tester-run v12 /
MAPFIX harmony re-cut**: `-p:OpenHarmonyRuntimeMode=jit|aot|interp` (default `jit`) selects the launch
shape and writes `libs/<abi>/runtime-mode.txt` next to the signed payload (the `aot` shape requires the
NativeAOT application library `lib<stem>.so` or the build fails, naming the aot-haps publish flags;
`interp` may carry `-p:OpenHarmonyInterpreterPack=<dir>` to stage `libcoreclr.so` +
`libclrinterpreter.so` over the publish natives). The host reads the marker at the same launch point as
`xwe.txt`/`interp.txt` with **file (`interp.txt`) > manifest (marker) > default (jit)** precedence and logs
`runtime-mode=<v> source=file|manifest|default`; an `aot` marker with a missing/unloadable library logs the
explicit `falling back to the JIT route` line; a stale or invalid marker warns once and keeps jit.
`tester-run.sh` is **v12** (`runtime_mode` summary key `jit|aot|interp(hap)|invalid(...)|<absent>`;
`interp_mode`/`aot_route` fall back to `3(manifest)`/`1(manifest)`; the matrix Run C runs the stock hap
when the main hap is marked interp, `run_c_via=manifest`; 126,658 B / `87763a3e…`, asset id 593961018).
MAPFIX re-cut the harmony haps so `MapOverlay` really compiles (abc **291,628 B** / `a637a513…`, tar
`9b0506fa…`; the old `d3a7b718…`/`f7a4faa2…` assets lacked the module record); lit-up needs the AGC map
AppKey plus a re-sign whose certificate fingerprint matches AGC. Artifacts: host rebuilt with the marker
parser; abc **281,052 B** / headless **20,916 B**, host export contract **143/143**, suite
**387/floor 367 -> 391/floor 371**; the kit `verify-kit.sh` abc expectation is unchanged
(`281052`/`20916`; the #28 value `264136` FAILs by design). The kit's five haps are the default jit shape
(`libs/<abi>/runtime-mode.txt=jit`); **stock kit (from #22 on, #31 included) has not been on a device yet**,
so the checks below remain open.

Updated 2026-09-28 (kit #29 — history): **R3 — CoreSpeechKit TTS / HUKS-first SecureStorage / tester-run v11 /
self-drawn depth**: the shell probes `@kit.CoreSpeechKit` behind `canIUse('SystemCapability.AI.TextToSpeech')`
plus a variable import and registers a five-op TTS sink (create/speak/stop/locales/isBusy); the managed
`OpenHarmonyTextToSpeech` gains `SpeakAsync` (returns when the utterance completes) / `GetLocalesAsync` /
`Stop` / `IsSupported` — with no Kit the sink is not registered, `IsSupported=false` and every call degrades
without throwing; real speech needs an HMS device plus a harmony shell (the kit itself has no AGC
entitlement/permission gate; AGC checklist row 13 = TTS, gate = device speech capability/offline voice data).
`SecureStorage` now prefers HUKS (host `host_keystore.c` AES-256-GCM via `libhuks_ndk.z.so`, device-bound key,
**no permission**, alias `maui.ohos.securestorage.v1.<path-hash>`, `k1:<nonce||ct||tag>`) and falls back to the
per-install file key with the honest `IsHardwareBacked=false`; `RemoveAll` deletes the key. `tester-run.sh` is
**v11** (`--mode-matrix` four-run JIT/XWE/interpreter/AOT matrix plus `--a11y-probe`; 119,452 B / `2355e493…`).
The self-drawn depth batch lands text editing (caret blink/selection handles/IME composition), animations
(page transitions/control states/shared elements/reduced motion), lists (incremental loading/ScrollTo/group
collapse/scroll physics), images (low-res first -> display-size replace; up to ~43x smaller decoded bitmap)
and deep links (cold `onCreate` want via `notifyActivation` before `startApp`, warm `onNewWant` with
sequence de-duplication). Artifacts: abc **281,052 B** / headless **20,916 B**, host export contract
**143/143**, suite **387/floor 367**; the kit `verify-kit.sh` re-anchors the abc expectation to
`281052`/`20916` (the #28 value `264136` now FAILs by design). The kit's five haps are JIT payloads
(hostfxr fallback, `aot=0`); **stock kit (from #22 on; the #29/#30 waves carry this forward unchanged) has not been on a
device yet**, so the checks below remain open.

Updated 2026-09-26 (kit #28 — history): **R2 — Map overlay / Live View probe / AOT start bridge /
interpreter**: the shell gains the `MapComponent` overlay as a harmony-flavor-only module
(`templates/ets/map/MapOverlay.ets`, literal `@kit.MapKit`, dynamic `'./map/MapOverlay'` import) driven
through `ohos_host_map_command`, with managed `OpenHarmonyMap` overlay APIs (`IsOverlayAvailable`,
show/hide/close, region, marker) and `Ready`/`MarkerClick`/`CameraIdle` events — on the default
OpenHarmony flavor `IsOverlayAvailable=false` and every overlay call degrades without throwing (the real
map needs `ARKTS_SDK_FLAVOR=harmony` plus an AGC map AppKey); the Live View probe (`canIUse` +
`@kit.LiveViewKit`, TIMER scene create/update/stop) registers no sink without the kit/entitlement
(`IsSupported=false`, Start/Update/Stop `Unavailable`, never throws); the host `start_app` route now
probes `lib<stem>.so` / `openharmony_app_main` and logs `aot=1` (falling back to hostfxr with `aot=0`),
so the AOT haps in `aot-haps.tar.gz` can launch from the shell; the interpreter stays a separate
experimental asset (`ohos-interpreter-pack.tar.gz`; `<files>/interp.txt` selects `DOTNET_InterpMode`,
logged as `interp=3 source=file`). Artifacts: abc **264,136 B** / headless 18,532 B, host export contract
**134/134**, suite **334/floor 314**; the kit `verify-kit.sh` re-anchors the abc expectation to `264136`
(the #27 value `245412` now FAILs by design). The kit's five haps are JIT payloads (hostfxr fallback,
`aot=0`); **stock kit (from #22 on; the #28 wave carries this forward unchanged) has not been on a
device yet**, so the checks below remain open.

Updated 2026-09-27 (kit #27 — history): **KIT-EXT2 — Push / Account / Map**: the shell probes the three
HMS kits (`@kit.PushKit` `getToken()`/`deleteToken()`, `@kit.AccountKit`
`createAuthorizationWithHuaweiIDRequest()` + `getQuickLoginAnonymousPhone`, `@kit.MapKit` capability bits)
and only registers a sink when the variable `import()` succeeds — with no Kit/AGC/HMS everything returns
`Unavailable`/null/false and **never throws**. The host gains 12 kit sinks (`ohos_host_push_*`,
`ohos_host_account_*`, `ohos_host_map_*`; error-code mapping `1000900010`/`1000900012`,
`1001502014`/`1001500001`; export contract 118/118 -> **130/130**) plus the FIX-R1-NAPI-6D boundary
hardening, and the reverse entries (host -> managed callbacks) now marshal off the runtime
(`[UnmanagedCallersOnly]` + `delegate* unmanaged[Cdecl]` thunks; FIX-R1-MARSHAL-OFF). Artifacts:
signed hap ~75.56 MB (zip 278 entries; `libs` 269 = 14 `.so` + 254 payload + `.dotnet-payload.json`),
abc **245,412 B** / headless 18,532 B, in-hap host **265,120 B** / pack 261,024 B, in-hap hosting DLL
**55,296 B**, index 1588/1780 B, `dotnet.zip` 254 entries / 0 `.so`; the kit `verify-kit.sh` re-anchors
the abc expectation to `245412` (the #25/#26 value `234620` now FAILs by design). The kit's five haps
are JIT payloads (hostfxr fallback); **stock kit (from #22 on, #28 included) has not been on a device
yet**, so the checks below remain open.

Updated 2026-09-26 (kit #26; history): **P2-INTEROP + TASK-MIG + PLAT-GAP**: the managed hosting bridge is
fully source-generated `LibraryImport` (125 declarations = 44 hosting + 81 MAUI slice; zero `DllImport`;
the 118/118 host export contract is unchanged), hap packaging tasks are now compiled into the pack
(`tools/Microsoft.OpenHarmony.Tasks.dll`, six task assemblies; `OpenHarmony.Hap.targets` split +
`PlatformItems.targets`), and the ASP.NET Core KFR is pinned to the published `11.0.0-rc.1.26425.128`
band with `RuntimeIdentifier=openharmony-arm64` defaulted and `EnableAppHostPackDownload=false` — consumers
no longer need the per-project workaround. Artifacts: signed hap ~75.47 MB, abc 234,620 / headless 18,532,
in-hap host 240,544 B, in-hap hosting DLL 55,808 B. The kit #27/#28 waves carry these forward unchanged.

Updated 2026-09-25 (kit #25): **permission chain + Share/Scan feature probes + AOT startup
path**: the permissions hap declares every permission with a `reason` (`$string:permission_reason_*`) and a
`usedScene` (`EntryAbility`, `when=inuse`), and the pack targets gate the feature -> permission matrix at
the request point, so the runtime permission dialog must show the localized reason text. Share/Scan are
probed (`canIUse` + variable import) and degrade cleanly on the OpenHarmony SDK (`shareDispatch=False` /
`scanSupported=False`, sinks not registered); only the HarmonyOS SDK variant (`ARKTS_SDK_FLAVOR=harmony`,
HMS device) opens the share panel / returns a scan result. The host gains an AOT startup path
(`lib<stem>.so` -> `openharmony_app_main`, hostfxr fallback for the JIT payload). Rebuilt artifacts:
UI abc `234620` / headless `18532` (version `13.0.1.0`), hap `libs` 269 = 14 `.so` + 254 payload +
`.dotnet-payload.json`, hap zip 278 entries, `resources.index` 1588/1780 B, `dotnet.zip` 254 entries /
0 `.so`; the kit `verify-kit.sh` asserts these. Judgement points on that kit: permission dialog copy,
Share panel, Scan return, AOT startup — see `2026-09-25-ohos-tester-handoff-kit25.md` §2.

## 0. Artifacts

| Artifact | Where |
|---|---|
| `hello-maui-app.hap` (~21 MB, 26.0 band, `verify-app` success; siblings `-permissions`, `-api20`, `-api20-permissions`, `-unsigned`) | `ohos-workload/test/hello-maui-app/bin/Release/<tfm>/openharmony-arm64/` or the delivery kit |
| Delivery kit `device-test-kit.tar.gz` — current delivery kit (**kit #35**: the W9/W10 waves — B2 device BLZ pass, T20 media transport layer, T14/T21/T8, the AOT-entry fix; suite 540/floor 520, export 149, shell abc 339,164/23,516; bundle **77,754,383** / `acd26821…`, dtk **392356147** / latest **392077166**; numbers follow the release notes `## Integrity (kit #35)`; the kit #34 snapshot: rc.2 baseline + MAUI waves W6/W7/W8 (T14/T12/N1/FIX-SHELL/T15/T16/N4/T18/N5/N6; suite 513/floor 493, export 145) + the AOT-v3 fallback asset; the kit #32 snapshot: WebView wiring + B1 razor asset + SEC round; the kit #31 Blazor WASM/ArkWeb component — 6th unsigned hap `hello-blazorwasm-host-unsigned.hap` (26,794,931 B / `36010a9c…`, bundle `com.example.opendotnet`, declares `ohos.permission.INTERNET`; tester-run v13 `--blazor-probe`; 6 haps total) + **kit #30**: MS-MODE — runtime-mode packaging switch (`-p:OpenHarmonyRuntimeMode=jit|aot|interp`, default `jit` -> hap `libs/<abi>/runtime-mode.txt`; host **file > manifest > default** precedence, `runtime-mode=<v> source=file|manifest|default` log, explicit `falling back to the JIT route` when an aot marker's library is missing/unloadable; `interp` may carry `-p:OpenHarmonyInterpreterPack`) + tester-run v12 (`runtime_mode` key; matrix Run C `run_c_via=manifest` for an interp-marked main hap) + the MAPFIX harmony re-cut (MapOverlay really compiles: abc 291,628 B / `a637a513…`, tar `9b0506fa…`); R3 carried: CoreSpeechKit TTS (probe + five-op sink + `SpeakAsync`/`GetLocalesAsync`/`Stop`/`IsSupported`; no Kit -> `IsSupported=false`, calls do not throw; real speech needs an HMS device + harmony shell, no AGC entitlement/permission gate) / HUKS-first SecureStorage (device-bound AES-256-GCM key via `libhuks_ndk.z.so`, no permission, file-key fallback marked not hardware-backed; `RemoveAll` clears the key) / devloop.sh (one-command incremental deploy replacing Hot Reload) / self-drawn depth (text editing carets/selection/IME preedit, page transitions/control states/shared elements/reduced motion, incremental list loading/ScrollTo/group collapse/scroll physics, low-res-first image decode, cold/warm deep links), on top of the #28 R2 Map overlay / Live View / `start_app` AOT bridge / interpreter, the #27 KIT-EXT2 Push/Account/Map probes + 12 host kit sinks + FIX-R1-NAPI-6D / FIX-R1-MARSHAL-OFF, the #26 P2-INTEROP `LibraryImport` hosting / TASK-MIG compiled packaging tasks / PLAT-GAP consumer defaults, the #25 permission chain / Share-Scan probes / AOT startup path and #24 payload-in-libs + explicit W^X=0 + exec-memory probe; 6 haps (5 MAUI + 1 Blazor) + 8 zh-CN docs + `SHA256SUMS` + the hardened `verify-kit.sh` with per-hap payload-marker assertions and the re-anchored abc expectation `281052`/`20916`; side assets `aot-haps.tar.gz` (AOT MAUI variant + README), `ohos-interpreter-pack.tar.gz` (+ README/sidecar) and `harmony-haps.tar.gz`; size/sha256/tree digest read from the `device-test-kit` release notes `## Integrity` (kit #30 measured tar **196,992,264 B** / `a781c25b…`, tree **`cc1ca935…`**, sidecar **`a63cd34f…`**, `SHA256SUMS` 15 entries / 1,309 B / `3a369dd8…`; kit #28 comparison was tar 196,220,486 B / `091dcc56…`, tree `0a7a3215…`, sidecar `d7efd251…`), mirrored on `workload-latest`) | release `device-test-kit`, also attached to `workload-latest`; the same release carries the unsigned startup-crash probes P1–P4 (`hello-mauiapp-probe{1..4}-unsigned.hap`) |
| Workload bundle `openharmony-workload-1.0.0-preview.24.tar.gz` | GitHub release `workload-1.0.0-preview.24` (+ `workload-latest` with `SHA256SUMS`; the SDK release keeps an earlier snapshot) |
| Host library | `packs/Microsoft.OpenHarmony.Sdk/<ver>/hosts/arm64-v8a/libopenharmonyhost.so` (signed) |
| ArkTS shells | `packs/.../templates/ets/modules.abc` (headless) and `modules.ui.abc` (UI); preview.24 carries the T6/T8 archive (fingerprint fallback, keep-screen-on) |

**Step 0 — kit identity check (before installing anything).** Take the current tarball
size/sha256 and the extracted-tree digest from the `device-test-kit` release notes
(`## Integrity`; the kit #32 values: tar **207,114,608 B** / `8f690949…`, tree `645879bc…`, sidecar `344760e7…`; the kit #31 notes carried (tar **207,023,588 B** / `f4325d2f…`, tree **`52e77ee8…`**, sidecar **`7d0cba77…`**; the #30 comparison was tar **196,992,264 B** / `a781c25b…`; the #28 comparison was tar
196,220,486 B / `091dcc56…`, tree `0a7a3215…`; `workload-latest` mirrors them) or the `.sha256` sidecar. Then run the
quickstart's verify chain — ① `sha256sum -c device-test-kit.tar.gz.sha256` (or
`verify-kit.sh --anchor-file …`), ② extract, ③
`verify-kit.sh --expect-tree-digest <tree digest from the release notes>` — and confirm the
in-kit version line (`最终状态.md`「发布物」 or `README-交付说明.md`「构建基线」) reads
`1.0.0-preview.24`. Re-signed or pre-signed kits legitimately differ: compare only against the
release notes (or the sidecar) of the build you downloaded, never against a value copied into a
document. The six kit haps (five MAUI + the Blazor host, the latter with its own bundle `com.example.opendotnet`) are already legal (`bundleName` matches each shipped hap) and
band-aligned, so **no rename and no `module.json` edit** is needed.

The kit #23 verifier also asserts the payload facts per hap (`resources.index` present/non-empty,
abc `13.0.1.0` + current size (the kit #35 shell lands a new in-kit expectation — 339,164/23,516; the kit #34 shell 311,424/headless `20916`; the kit #33 shell `294976`/headless `20916`; the #29 value `281052`, the #28 value `264136`,
the #27 value `245412` and the #25/#26 value `234620` now FAIL by design),
14 libs, `dotnet.zip` composition, host ELF dependency policy); kit #24 adds the
`libs/arm64-v8a/.dotnet-payload.json` payload-in-libs assertion (missing/inconsistent marker =
FAIL): `FAIL` exits 1, `WARN` stays `KIT OK`. It passes on kit #22 and **reports real defects on
kit #21 and older (they will FAIL — expected, not a tool bug)**; use the kit's own verifier for an
old kit.

## 1. Install and launch

```
hdc install -r hello-maui-app.hap          # or: bm install -p <extracted dir>
hdc shell aa start -a EntryAbility -b com.example.hellomauiapp
```
Expected: the app starts; the status file (`<filesDir>/dotnet-status.txt`) contains
`bridge attached: registered=True`, `[hello-maui-app] starting MAUI application`,
`[maui] window created (Window), content=ContentPage`.

Kit #5 and later replace the earlier rename/band workarounds, so the haps install and start
under the shipped `bundleName` as-is. `9568344` still means the debug profile does not carry
this device's UDID (send the UDID, or p7b + p12 + cer + keyAlias for the `--external` pre-sign
path in the signing guide §4c). If the app exits ~1 s after `aa start` (`exit 254` / `JsError`), go to §8's
probe ladder instead of retrying.

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

## 6. S/T-series capabilities (preview.24)

These items need the preview.24 pack (the S1/T5 page assets, the T6 shell archive and the T8
keep-screen-on sink all live in it). Triggers are in the demo (`hello-maui-app.hap`) unless a
step says otherwise; every step also names the managed call, so an item can be driven from any
page event when the demo build has no control for it. The log lines are in
`<filesDir>/dotnet-status.txt` or `hilog`.

### 6.1 Blazor/hybrid validation page (S1, T5)

The demo's Home tab embeds a `HybridWebView` (`HybridRoot=wwwroot`, `DefaultFile=index.html`,
400 px high). Its handler registers the extracted `wwwroot` tree with the shell, which serves
the page and its assets from the MAUI hybrid origin `https://0.0.0.1/`. The page
(`wwwroot/index.html` + `js/app.js`) is a dependency-free bridge smoke test whose header lists
the expected probe values.

| Probe | Expected on the Blazor root (`https://0.0.0.0/`) | Expected on the hybrid origin (`https://0.0.0.1/`, the demo) |
|---|---|---|
| `typeof window.external` | `object` | `object` |
| `typeof window.external.sendMessage` | `function` | `function` |
| `typeof window.external.receiveMessage` | `function` | `function` |
| `typeof window.dotnetHost` | `object` | `object` |
| `typeof window.dotnetHost.postMessage` | `function` | `function` |
| `typeof window.__dispatchMessageCallback` | `function` | `undefined` |
| `typeof window.HybridWebView` | `undefined` | `object`, but only when the page loads `_framework/hybridwebview.js` (see the note) |
| `typeof window.Blazor` | `object` (once `blazor.webview.js` loads) | `undefined` |
| `typeof window.__ohosDotNet` | `object` | `object` |

Note: the page header's hybrid column assumes a stock hybrid page, which loads
`_framework/hybridwebview.js` (that script assigns `window.HybridWebView`). The demo page loads
only `js/app.js`, so its `HybridWebView` row reads `undefined` and **Send ping** goes through
`window.external.sendMessage`; a plain WebView without any registration leaves every row
`undefined` and the page reports that no bridge function was found.

| # | Action | Expected |
|---|---|---|
| 6.1.1 | Open the Home tab | the page renders "OpenHarmony bridge test"; the location line shows `origin: https://0.0.0.1` and `readyState: complete`; the probe table fills within a few seconds (the shell injects after the load event; the page refreshes for 15 s) |
| 6.1.2 | Read the probe table | the hybrid-origin values above; the probe values themselves are the confirmation (the `[maui] web finished: <url>` line is only written for a plain `IWebView`, not for this `HybridWebView`) |
| 6.1.3 | Tap **Send ping** | the status line shows `sent #N via window.external.sendMessage` plus the JSON ping (`{"kind":"ohos-bridge-ping",...}`) and "waiting for a reply (the stock Blazor IPC does not answer plain JSON)"; the demo label under the WebView changes to `hybrid raw message: {...}` (the managed `RawMessageReceived` hook). "Sent, no reply" is the expected stock result; `send #N FAILED via ...` means the channel registration broke |
| 6.1.4 | Watch the inbound log (message area) | when the app sends a host message (there is no automatic reply), it appears as `[time] <channel>: <payload>`; on this origin the channel is `HybridWebViewMessageReceived` (the shell shim's `receiveMessage`). `__dispatchMessageCallback` stays `undefined`, so **Self test inbound** reports "self test skipped: ... not a function yet" — expected, not a failure |
| 6.1.5 | Blazor root only (a page served from `https://0.0.0.0/`) | the Blazor-root column above; `Blazor.start()` loads `_framework/blazor.webview.js` (it first fetches `_framework/blazor.modules.json`, staged in `wwwroot/_framework/`); `__dispatchMessageCallback` is a function and **Self test inbound** logs a labelled page loopback (not a host reply) |

### 6.2 Keep screen on (T8)

`DeviceDisplay.Current.KeepScreenOn = true` queues `ohos_host_keep_screen_on(1)`; the preview.24
shell sink resolves the last window (`getLastWindow`) and calls `setWindowKeepScreenOn(true)`.
The managed getter caches the last value the host accepted (queued), not the window's real
state.

| # | Action | Expected |
|---|---|---|
| 6.2.1 | Turn Keep screen on on (demo control that sets `DeviceDisplay.Current.KeepScreenOn = true`) | no exception; the getter reads `true`; no log line on success |
| 6.2.2 | Leave the app foregrounded and untouched until the device's screen timeout would fire (>= 1 min) | the screen does not dim or lock |
| 6.2.3 | Turn it off (`= false`) | the normal screen timeout behaviour returns; the getter reads `false` |
| 6.2.4 | Watch the logs | window service rejected: hilog `[maui] keep screen on failed: ...`; missing host export: `[maui] keep-screen-on bridge unavailable (no host library)` once and the value stays `false` |

### 6.3 Static web asset fingerprint fallback + cache headers (T6)

The preview.24 shell serves hybrid and Blazor payload files with a fingerprint fallback
(`name.<8-32 lowercase hex>.ext` -> `name.ext`, exact name first, one retry) and cache headers,
and the hybrid and Blazor bridges share the path. The demo page references base names only, so
the fallback itself needs a manual request.

| # | Action | Expected |
|---|---|---|
| 6.3.1 | Request a fingerprinted name whose base file exists (WebView devtools console, a page `fetch()`, or app-side `EvaluateJavaScriptAsync`), e.g. `https://0.0.0.1/js/app.0a1b2c3d.js` or `https://0.0.0.0/_framework/blazor.webview.713e519f.js` | 200 with the base file's content (`js/app.js` / `_framework/blazor.webview.js`); an existing exact name always wins |
| 6.3.2 | Request names that must not be rewritten (`app.settings.css`, `.hidden.css`, 7/33 hex digits) | 404 unless an exact file exists; ordinary dotted names are served unchanged |
| 6.3.3 | Probe the headers (devtools console: `fetch(url).then(r => r.headers.get('cache-control'))`) | fingerprinted: `public, max-age=31536000, immutable`; base names (`blazor.webview.js`, `hybridwebview.js`, the host page, app assets): `no-cache` |
| 6.3.4 | Watch the `[maui]` lines | the file path itself is silent; a plain-`IWebView` document logs `[maui] web finished: <url>` (the hybrid handler logs no web lifecycle line); registration/injection failures show `[maui] hybrid assets registration failed: ...`, `[maui] blazor assets registration failed: ...` or `[maui] blazor bootstrap injection failed: ...` |
| 6.3.5 | Traversal guard | `..`, `\` and encoded traversal still answer 404 (the fallback can only shorten the last file name) |

The shell implements no `If-None-Match`/`If-Modified-Since`: `no-cache` relies on the WebView
re-asking and the shell always returns the full 200 body.

### 6.4 Share file (S4)

`Share.RequestAsync(new ShareFileRequest { File = new ShareFile(path) })` builds a `file://`
URI and a MIME type from the extension, then dispatches an implicit
`ohos.want.action.sendData` Want with `FLAG_AUTH_READ_URI_PERMISSION` (shell kind 3; the plain
text share path is kind 1 and unchanged).

| # | Action | Expected |
|---|---|---|
| 6.4.1 | Share a small `.txt` from `AppDataDirectory` (demo share action, or the managed call above) | the system share/ability picker appears; choose a target app (chat/email/file manager) |
| 6.4.2 | In the target app, open or read the shared item | the file has the right name and content; `text/plain` for `.txt` (20 extensions are mapped, others `*/*`) |
| 6.4.3 | Repeat with a `.pdf` | same; the picker may be narrowed to `application/pdf` targets |
| 6.4.4 | Watch the logs | success: `[maui] ability start dispatched: kind=3`; failure: `[maui] share file request could not be dispatched (<mime>)` and hilog `[maui] ability start failed: kind=3 ...` |
| 6.4.5 | Multiple files | exactly 1 file uses the same path; 0 or >1 files keep the documented no-op and log `[maui] share multiple files request (N files) needs Share Kit (not in this SDK)` |

The URI is a sandbox absolute path (`file:///data/...`); the read flag expresses the grant, and
whether the receiver can actually open the file is what this run proves.

### 6.5 Flashlight (S3)

`Flashlight.Default.TurnOnAsync()` / `TurnOffAsync()` / `IsSupportedAsync()` map to op 1/0/2 on
the Camera Kit torch bridge. No manifest permission is needed (only camera input/session APIs
carry `ohos.permission.CAMERA`). `setTorchMode` is synchronous and the boolean means "the kit
accepted the request", not "the LED is lit".

| # | Action | Expected |
|---|---|---|
| 6.5.1 | Turn the flashlight on (demo control) | the rear-camera torch LED lights; the call returns without throwing |
| 6.5.2 | Turn it off | the LED goes dark |
| 6.5.3 | Query support | `IsSupportedAsync()` is `true` on a device with a torch; `false` without a torch/Camera Kit or before the shell sink registers |
| 6.5.4 | Watch the `[maui]` lines | success is silent; a failed request writes `[maui] flashlight turn-on unavailable (no host/sink, no torch or kit error)` (or the `-off` variant); the shell logs `[maui] flashlight request failed: <message>` (e.g. 7400102 camera not allowed, 7400201 service fatal) |

### 6.6 Accessibility node count + A11Y self-check (S2, Q2)

The shell's `A11Y` overlay button (bottom-left, 44×24, does not take layout) opens an
"Accessibility self-check" dialog with the provider status and, when the host library exports
the count, the number of published nodes (`host.accessibilityNodeCount()`).

| # | Action | Expected |
|---|---|---|
| 6.6.1 | Tap **A11Y** | the dialog shows `accessibilityStatus: <n> (<label>)` and `accessibilityNodeCount: <count>` |
| 6.6.2 | Read the status | 0 = not attached, 1 = attached (expected), 2 = frame node refused, 3 = custom node not created, 4 = custom node attached but provider refused; other values show `<n> (unknown status)`. 0 is normal before `onPageShow`; after the page is mounted expect 1 |
| 6.6.3 | Read the node count | the last published node count (the same value the provider serves). Record it: it must be > 0 on a rendered page, identical when the dialog is re-opened without a page change, and change after navigating or switching tabs |
| 6.6.4 | Older host library | the dialog shows `accessibilityNodeCount: unavailable` (the status still resolves) |
| 6.6.5 | Check the status file | `[maui] accessibility provider status=<n>` (1 = attached, the ideal value; report 2/3/4 or unknown values with the line) |

### 6.7 Performance budget

The frame-path budget is enforced by the off-device interaction suite
(`test/maui-platform-verify`); its `[verify] perf` line is the number to quote:

```
[verify] perf warmup=8 frames=200 nodes=... avg=...ms p50=...ms p95=...ms max=...ms max/avg=...
allocDelta=...B alloc/frame=...B elapsed=...ms budget=avg<=20ms,max<=250ms,max/avg<=100
warmupOk=True within=True
```

| # | Action | Expected |
|---|---|---|
| 6.7.1 | Take the perf line from a recent suite/CI log | `within=True`; budget avg <= 20 ms, max <= 250 ms, max/avg <= 100 (recent host runs: avg 3.1-10.4 ms, p95 3.9-14.7 ms, max 5.8-20.0 ms) |
| 6.7.2 | With hdc: run the §5 smoke (30-item scroll, animations) while recording `hdc hilog > log.txt` | no visible stutter; attach the log excerpt plus the suite's perf line — the device frame path has no separate perf line, so the suite line is the reference budget |
| 6.7.3 | Without hdc | judge by §5.1/§5.2 and the in-app behaviour; note "perf line not collected (no hdc)" in the report |

## 7. Known test-side items (not device blockers)

* the pixel harness's checkbox-stroke sample reads a neighbouring colour (the check line itself
  is verified); the selection-tint sample needs the tap re-checked with fresh frames;
* both are test-side and tracked in the port status document; the renderer behaviour they cover
  is verified by the other 10 pixel assertions.

## 8. Reporting back

Collect `dotnet-status.txt`, `hilog` excerpts around a tap/typing/animation and any crash
traces, and record them in the fill-in template `2026-09-21-ohos-device-report-template.md`
(one page; its §0–§1 also pin the kit version and hashes). **If the app exits at startup
(`exit 254` / `JsError`) or a step dies with no log line**, add the minimal evidence from
`2026-09-21-ohos-device-crash-diagnostics.md` and walk the probe ladder in
`2026-09-21-ohos-crash-probes.md` — P1 shell-only, P2 host `dlopen`, P3 host entry/`dlsym`,
P4 per-dependency; its decision table names the failing layer, and its P4 section has a
no-app 14-library self-check (`hdc shell ls -l /system/lib64/...`). The probe haps are
unsigned and live on the same `device-test-kit` release. With those, the port validation is
complete and the remaining work is upstream API approval only. `tester-run.sh` v8 already packs
the app-lib/bootstrap/payload/kit-selfcheck/exec-memory evidence into `tester-report-<stamp>.tar.gz`; quote
its `summary.txt` keys (`bootstrap_errors`/`rawfile_errors`/`libload_errors`/`payload_present`/
`payload_marker`/`kit_index_ok`/`execmem_capture`/`execmem_lines`) in the report.
