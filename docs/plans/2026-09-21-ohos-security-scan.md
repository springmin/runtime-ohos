# Five-repo OpenHarmony port — consolidated security scan (2026-09-21)

Scope: `runtime-ohos`, `aspnetcore-ohos`, `ohos-workload`, `maui-ohos`, `sdk-ohos`.

## Verdict

**PASS WITH FINDINGS.** 23 candidates were triaged and all 23 are now resolved: 22 fully fixed plus B6
fixed by construction (implemented and off-device verified, but resting on event-ordering assumptions that
only a device can confirm — see the accepted risks under Residual Risk). Since the initial scan the B4
managed decoder, B6 navigation interception and B7 status-log hardening all landed (fix commits are cited
per finding below). All High-severity host, IPC and supply-chain findings are fixed in the scanned trees. A
further 16 areas were investigated and closed with no finding. No fix has been verified on a device (device
install is blocked by org policy), so every device-visible behaviour claim below is explicitly marked as
device-unverified.

## Scope

| Repo | Branch | Commits carrying the scan results |
|---|---|---|
| `runtime-ohos` | `feature/openharmony` | `8a600e49fa4052fcb958e85f3818f3f123c3b7da` (C1 doc), `0adc3edc4d01b4ebaea2d6aff65e498e0ba94640` (C5 doc) |
| `ohos-workload` | `master` | `46eea0a9c5bae5f41960a6e2dcd13e4d5e11cb3b` (A1-A8), `89a292f876ac60aa375b16d0eda5e101a16cf116` (B1-B5 shell), `b93f1e5fd3e4d14792aeb78d932ca058833c270c` (C1), `083c9dd0cece181013b76ff548bd91d5d563d72e` (C3/C4/C5), `dc6b66baeef74f25bd4a280b1cff0ad4b5fb94b6` (C8); harness pin `524dbd46caa3f6f32b8311151cc196dc1675a34b` |
| `maui-ohos` | `feature/openharmony` | `c90a018e6b8497f9f17c0bc968127fe430db4092` (A3/A4), `7c402a142344988259e7670085f9ae1942bcaabc` (B1-B3/B5) |
| `sdk-ohos` | `feature/openharmony` | `d57e58e28cb69d7bb96cac1a27e0fe04b8ec1bb1` (C2/C6/C7), `ebd82459b0b787cb3c9e22cadc6ad0588bfb4dd9` (minified GitHub API digest parser + owner/repo URL fix) |
| `aspnetcore-ohos` | `feature/openharmony` | no changes — ported RID/flag wiring only, no finding |

Method: team-mode was unavailable, so the audit ran as 3 parallel hunter subagents — A: native/managed
boundary, B: data flow/injection, C: build/supply chain — over all five trees. Candidates were confirmed
by code reading and, where possible, by a deterministic off-device repro (ASan for A1; scratch drivers for
A3/A4) before any fix. Fixes then landed reproduce-then-fix in parallel batches (F1-F6, B2, B-a/B-b).
This report was assembled read-only with `git log` / `git show` / `grep`; no builds or test runs were
performed for it.

Verification already produced by the fix batches (not re-run for this report):

- host: `ohos-workload/scripts/build-host.sh` + `scripts/selfsign.sh` — build + self-sign OK, **120 exported symbols identical to the pre-fix baseline**.
- harness: `ohos-workload/test/maui-platform-verify` — 244 `[verify]` lines, 0 Unhandled, `perf within=True`; README documents `dotnet build -v:q && dotnet bin/Debug/net11.0/verify.dll | grep -c '\[verify\]'`.
- shell: `TYPECHECK=1 ohos-workload/scripts/build-arkts-shell.sh` — 0 ArkTS errors, `modules.abc` = 88756 B; slice build 0 errors.
- CI: workflow runs `35569919416`, `35569919487`, `35569919479` all success after C8.

Severity below is exploitability × impact at three coarse levels (High/Medium/Low) plus Info; it is **not**
a CVSS claim. Status: F = fixed (off-device verified), F† = fixed by construction (implemented and
off-device verified, but with event-ordering assumptions that cannot be exercised off-device — see B6
under Residual Risk), P = partial, W = work in progress. No candidate remains at P or W.

## Findings

| ID | Sev | Status | Finding | One-line rationale |
|---|---|---|---|---|
| A1 | High | F | Pending-context use-after-free in the native host | Launch thread reads/frees the pending context while another thread replaces it → memory corruption |
| A2 | High | F | Accessibility node table freed under ArkUI readers | Free-under-reader of native string fields reachable from the ArkUI provider → memory corruption / crash |
| A3 | Medium | F | Managed a11y snapshot mutated under enumeration | "Collection was modified" thrown back through a reverse P/Invoke → app crash, no corruption |
| A4 | Medium | F | Unbounded page → .NET payload | Page script can force multi-MiB managed allocations → memory-exhaustion DoS |
| A5 | Low | F | Accessibility event info leaked per published event | Slow unmanaged leak, only while a11y events are published |
| A6 | Medium | F | Early lifecycle events / NodeContent dropped | Events before bridge registration were lost → app start/availability failure |
| A7 | Low | F | `startApp` re-entry race | In-process API misuse only; could double-initialise the host |
| A8 | Low | F | IME UTF-8 truncation | Truncated multi-byte sequences violated the managed TextInput contract (garbled text) |
| B1 | High | F | Fabricated `AppOrigin` in Blazor IPC | Any page script could inject messages dispatched as if from the app origin → confused deputy |
| B2 | High | F | Origin-independent hybrid bridge + invoke-result forgery | Foreign pages could dispatch to handlers or complete another page's invocation → forged results |
| B3 | Medium | F | App → page delivery to the wrong document | Evals could land in a document the handler did not serve → cross-document script injection |
| B4 | Medium | F | Wire-protocol injection in kit record fields | Unescaped `\t`/`\n`/`\` could forge/split records; the shell escapes and the managed decoder now splits before unescaping and skips malformed records |
| B5 | High | F | `HybridRoot`/`DefaultFile` traversal | Crafted root/default file could escape the payload directory and serve arbitrary files |
| B6 | Medium | F† | Navigation interception gap | Un-originated main-frame navigations are now cancelled and re-issued only on a one-shot managed `Navigating` approval; event-ordering assumptions device-unverified |
| B7 | Low | F | Status file unbounded + URL/path leakage | `dotnet-status.txt` is capped at 256 KiB (newest whole lines) and the web navigation URL is logged without query/fragment at ≤ 2 KiB |
| C1 | High | F | Signing secret in shared scratch / fixed-path helper exec | Same-UID code replacement could steal the p12 password; residual argv exposure documented |
| C2 | High | F | Installer downloads executed/extracted unverified | Unverified selfsign binary exec / tarball extract = supply-chain RCE on a dev or CI machine |
| C3 | High | F | Runtime-pack digest gate inert | A 60-char digest could never match, and an explicit artifact was unpacked with no check at all |
| C4 | Medium | F | Publish without an independent digest / blind `--clobber` | A substituted or rebuilt artifact could be published or overwrite a different one |
| C5 | Medium | F | Kit only self-authenticated | `SHA256SUMS` ships inside the archive, so it proves internal consistency, not provenance |
| C6 | High | F | CI downloads unverified before extract/exec | Tampered toolchain/packages could run inside the CI job |
| C7 | High | F | NDK/OpenSSL/ICU extracted without digests | Tampered SDK artifacts were extracted, and the cache key did not bind the digests |
| C8 | Medium | F | CI token scope + mutable action/ref pins | Workflow token could write, and mutable action tags/refs could be moved under CI |

## Finding details

### Native / managed boundary (A)

- **A1 pending-context UAF — High, fixed.** Evidence `ohos-workload/src/OpenHarmonyHost/openharmony_host.c:212` (`g_context_mutex`), `:275-277` (replace), `:331-345` (take-once adoption); wrapper guard `ohos-workload/src/OpenHarmonyHost/host_napi.cpp:1548,1575`. Attack path: the launch thread `strdup`s the pending context snapshot while `ohos_host_set_app_context` frees and replaces it (pre-fix ASan UAF). Fix: mutex + take-once hand-off; failed launches clear state. Verification: ASan repro before the fix, host rebuild + selfsign, 120 exported symbols identical; the harness pins the native pending/adoption ownership contract (`Program.cs:2550-2561`), 244 checks, 0 Unhandled.
- **A2 a11y table freed under readers — High, fixed.** Evidence `ohos-workload/src/OpenHarmonyHost/openharmony_host.c:1780` (`g_a11y_mutex`), `:1816` (per-thread copies via pthread key), `:1881-1893` (begin under lock), `:1901-1959` (publish/get); contract note `ohos-workload/src/OpenHarmonyHost/openharmony_host.h:233-240`. Attack path: `ohos_host_accessibility_begin/commit` frees the table while the ArkUI provider iterates and reads its string fields. Fix: lock the table and copy strings into per-thread storage. Verification: the 16-arg publish and 17-arg getter ABI are unchanged and asserted at `ohos-workload/test/maui-platform-verify/Program.cs:2206`; host rebuild OK. Regression: a11y contract pins in the same harness.
- **A3 managed a11y race — Medium, fixed.** Evidence `maui-ohos/src/Core/src/Platform/OpenHarmony/OpenHarmonyAccessibility.cs:75,199,235,263,275-276` (immutable snapshots + `Volatile` swaps), `:122-127` (callback try/catch). Attack path: the accessibility thread enumerated a list while `Refresh` cleared/rebuilt it, and the resulting exception crossed back through the host's `A11yExecuteAction` reverse P/Invoke. Fix: publish immutable snapshots, atomic reference swaps, never let a managed exception cross into native. Verification: scratch repro driver + harness 244 checks; commit `maui-ohos c90a018e6b84`. Regression: a11y snapshot/click/publish pins (`Program.cs:441-472,2206`).
- **A4 unbounded page payload — Medium, fixed.** Evidence `maui-ohos/src/Core/src/Platform/OpenHarmony/OpenHarmonyHybridWebViewHandler.cs:72` (`MaxPagePayloadLength = 4 * 1024 * 1024`), `:437-440`, `:673`, `:762-791`. Attack path: page JS sends arbitrarily large `__RawMessage`/invoke payloads that the host marshals whole and the managed side parses. Fix: 4 MiB cap; oversized raw messages are dropped with a status log, oversized completions fail the pending invocation, oversized arguments return an error payload. Verification: scratch driver for oversized/malformed payloads + harness. Regression: long-bridge payload fuzz at `Program.cs:3221`.
- **A5 accessibility event info leak — Low, fixed.** Evidence `ohos-workload/src/OpenHarmonyHost/host_napi.cpp:2394-2410`. Attack path: one `ArkUI_AccessibilityEventInfo` was leaked per published event. Fix: `OH_ArkUI_DestoryAccessibilityEventInfo` after the async send and on the error path. Verification: host rebuild + selfsign; no dedicated off-device pin for this path — device verification pending.
- **A6 early lifecycle / NodeContent dropped — Medium, fixed.** Evidence `ohos-workload/src/OpenHarmonyHost/openharmony_host.c:264-270` (pending globals), `:432-442` (transfer in `start_app`), `:570-584` (flush via `register_bridge`), `:1136-1137,1149,1162` (queue). Attack path: lifecycle events and the ArkUI `NodeContent` arriving before the handle/bridge existed were discarded, so the first launch could miss its surface/launch sequence. Fix: bounded pending queue guarded by `g_context_mutex`, flushed on bridge registration; NULL-handle calls fall back to `g_app`. Verification: host rebuild; pending-context ownership/adoption pins at `Program.cs:2550-2561`. Residual: the queue drains only on a successful launch.
- **A7 `startApp` re-entry — Low, fixed.** Evidence `ohos-workload/src/OpenHarmonyHost/host_napi.cpp:40-44,1575-1578` (`g_launch_lock`), `ohos-workload/src/OpenHarmonyHost/openharmony_host.c:270,332-337,442` (`g_launch_in_progress`). Attack path: two `startApp` calls could initialise the host twice. Fix: reject the second call in both layers; failed launches clear the guard; rejected calls allocate nothing. Verification: static review + host rebuild; no dedicated off-device pin for the re-entry guard. Residual: later `startApp` in the same process stays rejected (no teardown).
- **A8 IME UTF-8 truncation — Low, fixed.** Evidence `ohos-workload/src/OpenHarmonyHost/openharmony_host.c:797-803,826` (back off to a sequence boundary), `:841-874` (surrogate folding), `:904` (`set_text` truncation). Attack path: truncating a multi-byte sequence mid-character produced invalid UTF-8 for the managed `TextInput`. Fix: code-point-boundary truncation, surrogate pairs folded to one 4-byte sequence. Verification: host rebuild + selfsign (the build exercises the helper); no dedicated off-device pin for the IME truncation paths — device verification pending.

### JS / IPC bridge (B)

- **B1 fabricated `AppOrigin` in Blazor IPC — High, fixed.** Evidence `maui-ohos/src/Core/src/Platform/OpenHarmony/OpenHarmonyBlazorWebViewHandler.cs:324-358` (envelope + origin/id validation); shell side `ohos-workload/packs/Microsoft.OpenHarmony.Sdk/1.0.0-preview.24/templates/ets/pages/Index.ets:311-330` (`__OHORIGIN|<document url>|<document id>` envelope, id selection). Attack path: a page script sent a bare message that was dispatched to `WebViewManager.MessageReceived` with a fabricated `AppOrigin`. Fix: require the shell envelope, match the Blazor origin and this handler's registration id; reject and log mismatches. Verification: the shared envelope parser rejection cases are pinned by the hybrid checks (`Program.cs:1215-1227`); the Blazor origin/id gate itself has no dedicated harness pin; shell typecheck 0 errors. Residual: on-device untested.
- **B2 origin-independent bridge + invoke-result forgery — High, fixed.** Evidence `maui-ohos/src/Core/src/Platform/OpenHarmony/OpenHarmonyHybridWebViewHandler.cs:646-746` (origin check + single-handler `ResolveMessageHandler`), `:779-791`, `:862-877` (completion must match handler + page id), `:89,830` (`PendingInvoke`). Attack path: hybrid messages were dispatched without a document binding, and a page that harvested a task id could complete another page's JS invocation. Fix: origin/id match, one handler per dispatch, `PendingInvoke` ownership check. Verification: harness pins foreign-origin/foreign-id/missing-envelope rejection (`Program.cs:1215-1227`); 244 checks/0 Unhandled.
- **B3 app → page delivery to the wrong document — Medium, fixed.** Evidence `maui-ohos/.../OpenHarmonyHybridWebViewHandler.cs:609-636` (marker-checked eval), `maui-ohos/.../OpenHarmonyBlazorWebViewHandler.cs:503-527`; shell stamping `Index.ets:355-370`. Attack path: a host → page eval was delivered to whatever document was currently loaded, even a foreign one. Fix: the shell stamps `window.__ohHybridId` / `window.__ohBlazorId` only into documents it served for that registration; deliveries skip when the marker is missing/mismatched. Verification: shell typecheck, `modules.abc` 88756 B, static review of the skip path; no dedicated harness pin for the marker skip. Residual: on-device untested.
- **B4 kit wire-protocol injection — Medium, fixed.** Evidence shell `Index.ets:579-601` (`escapeRecordField`:
  `\` → `\\`, tab/LF/CR → `\t`/`\n`/`\r`); managed decoder
  `maui-ohos/src/Core/src/Platform/OpenHarmony/OpenHarmonyCalendarContacts.cs:408-567` (`OpenHarmonyKitRecords`,
  shared by the contacts, calendar and Bluetooth parsers). Attack path: an unescaped separator in
  contacts/calendar/Bluetooth record fields could forge additional fields or split records at the managed
  parser. Fix: reversible escaping at the shell join plus a shell-compatible decoder that splits records on
  raw LF and fields on raw TAB *before* decoding (`:423-487`, `:500-516`), reverses `\\`/`\t`/`\n`/`\r` in
  one left-to-right pass (`:519-567`), requires exactly the expected field count, caps a field at 512
  decoded chars (`:411`), caps a payload at 2000 records (`:414`) and skips malformed records (unknown
  escape, trailing `\`, over-long field) without throwing. Injection guard: a raw LF before the record's
  first TAB folds into field 0 as literal text (never forges a record); a raw LF after a TAB drops the
  record and skips the rest of its line, so the remaining fields cannot start a new record. Verification:
  slice build 0 errors, 15/15 decoder driver checks, harness 244/0 with the B4 assertions
  (`escapedDecoded`/`injectionGuarded`/`tablessDropped`); those pins are now committed (`ohos-workload
  f828c9f`: contacts/calendar/Bluetooth parsing shapes plus escape/injection coverage; count stays 244).
  Commit `maui-ohos 9c6a89a5`. Residual: on-device untested.
- **B5 `HybridRoot`/`DefaultFile` traversal — High, fixed.** Evidence `maui-ohos/.../OpenHarmonyHybridWebViewHandler.cs:250-254,297-316` (`IsSafeRelativePath`), `maui-ohos/.../OpenHarmonyBlazorWebViewHandler.cs:298-307` (+ `ResolveAssetPath`), shell `Index.ets:1161-1171,1186-1223,1236-1260` (reject + 404). Attack path: `HybridRoot`/`DefaultFile` containing `..`, `\` or a leading `/` could escape the extracted payload directory. Fix: both layers accept only ordinary relative path segments; registration is rejected otherwise. Verification: `Program.cs:2318` pins `ResolveAssetPath(..., "css\\evil.css") == null`; harness pins; typecheck 0 errors.
- **B6 navigation interception — Medium, fixed by construction.** Evidence shell `Index.ets:1742-1768`
  (`onLoadIntercept`: main frame only; app origins, `about:`/`data:`/`blob:`/`javascript:`/`file:` and
  relative references pass untouched), `:365-383` (`isAppNavigation`), `:385-415` (one-shot
  `consumeApprovedNavigation`/`retireNavigationMarker`), `:417-447` (`askManagedAboutNavigation`: UUID id,
  5 s TTL, 8 pending cap, oldest evicted), `:449-467` (`approveNavigation`: the id must be pending and the
  URL must match exactly, then one `loadUrl`); managed
  `maui-ohos/src/Core/src/Platform/OpenHarmony/OpenHarmonyWebViewHandler.cs:193-240` (`HandleJsMessage`
  routes `__OHNAV|` to `HandleNavigationRequest` and never fans it out to `JsMessage`/HybridWebView; raises
  `Navigating` and sends the `nav` approval back). Attack path: a navigation the shell did not originate
  could leave a document whose bridge state was stale relative to the handler. Fix: the shell cancels the
  load it did not originate and sends `__OHNAV|<url>|<id>`; the managed handler raises `Navigating`
  (`NewPage`) on the connected WebViews and, unless a handler cancels, approves the exact `(id, url)` pair;
  the shell re-issues only that URL through a one-shot, loop-guarded marker that `onPageBegin` consumes, so
  one load raises one event. Page-originated envelopes are inert (an approval is honoured only for an
  id/URL the shell itself cancelled), and a rejected, expired or malformed request leaves the load blocked.
  Verification: the B6 scenario asserts
  `approval`/`cancelBlocked`/`channelScoped`/`malformedInert`/`startedSuppressed`/`oneShot` all true; shell
  `TYPECHECK=1` 0 ArkTS errors; slice build 0 errors; those pins are now committed (`ohos-workload d636436`)
  and the harness reports 247 `[verify]` lines (244 + 2 B7 pins + 1 B6 pin), 0 Unhandled and
  `perf within=True`; CI's floor (224) is unchanged. Commits `ohos-workload 57a147c` (three `Index.ets` copies
  byte-identical), `maui-ohos e2d68ddf`. Accepted risks (device-unverified): the
  `onLoadIntercept`/`loadUrl` event ordering and `isMainFrame()` cannot be exercised off-device, and an
  unexpected event error fails open (the load is allowed); an allowed POST form navigation is re-issued by
  `loadUrl` as GET (the interceptor exposes no method/body); a redirect produces a second, correctly
  re-checked `Navigating`. Residual: on-device untested.
- **B7 status-file cap + URL redaction — Low, fixed.** Evidence `ohos-workload/src/Microsoft.OpenHarmony.Hosting/OpenHarmonyApp.cs:641-710`
  (`StatusFileMaxBytes = 256 * 1024`, `StatusMessageMaxChars = 4 * 1024`, `s_statusSync`, `TrimStatusFile`
  keeps the newest whole lines that fit under the lock) and managed URL sanitization
  `maui-ohos/src/Core/src/Platform/OpenHarmony/OpenHarmonyWebViewHandler.cs:28,303-321,426`
  (`SanitizeUrlForLog`: scheme+host+path only, query/fragment stripped, `MaxLoggedUrlLength = 2048`).
  Attack path: unbounded growth plus URLs/paths copied into diagnostics that can leave the app sandbox.
  Fix: the status file cannot exceed 256 KiB (oldest lines dropped, every line truncated to 4 KiB) and the
  page-finish navigation URL is logged without query/fragment and at most 2 KiB long. Verification: 300 ×
  ~4 KiB URLs produced a 260820-byte file, within the cap, with no queries; the two B7 pins are now
  committed (`ohos-workload d636436`, same 247-line harness). Commits `ohos-workload
  57a147c`, `maui-ohos e2d68ddf`. Residual: the cap drops the oldest diagnostic lines by design; see
  Residual Risk for the remaining narrower image-handler logging gaps; on-device untested.

### Build / supply chain (C)

- **C1 signing secrets — High, fixed.** Evidence `ohos-workload/scripts/sign-huawei.sh:13-17,39,42-47` (private `mktemp -d` 0700, traps, env-passed secret), `:50-57`; `ohos-workload/scripts/sign-for-device.sh` (env forwarding); doc `runtime-ohos docs/plans/2026-09-19-ohos-signing-and-udid-guide.md` (commit `8a600e49fa40`). Attack path: the decrypted p12 password was written to a predictable shared-scratch path before `chmod`, and a fixed-path `decrypt.js` was executed verbatim, so any same-UID process could tamper with the helper and harvest the Studio password (the encrypted password also travelled in node's argv). Fix: helper generated into a private temp dir removed on exit/INT/TERM/HUP, secret via environment, stale shared-scratch leftovers deleted. Verification: script inspection. Residual: `hap-sign-tool` still needs the password in `-keyPwd`/`-keystorePwd` argv (no tty-less stdin mode) — documented.
- **C2 installer downloads — High, fixed.** Evidence `sdk-ohos/eng/ohos-install/install-dotnet-ohos.sh:156-185` (`sha256_of`/`verify_sha256`), `:197-229` (digest resolution), `:231-274` (`download_verified`, `verify_local_file`), `:330` (selfsign), `:375-383` (local/cached tarballs). Attack path: a downloaded selfsign binary could be executed, and tarballs extracted, before any digest check. Fix: downloads land in `mktemp` files, are sha256-verified before exec/extract, and fail closed when no digest resolves; `ALLOW_UNVERIFIED=1` is the explicit insecure opt-out. Verification: script inspection; commit `sdk-ohos d57e58e28c`.
- **C3 runtime-pack digest gate — High, fixed.** Evidence `ohos-workload/scripts/prepare-packs.sh:19-22` (fixed 64-char digest of the published nupkg), `:55-80` (`digest_artifact`, refuse without expectation), `:146-153` (stale download cache dropped). Attack path: the recorded digest was 60 chars so both checks could never pass, and an explicit artifact argument was unpacked with no verification at all. Fix: every unpacked artifact must match a 64-char expectation (`--sha256`/`RUNTIME_PACK_SHA256`, or a `<artifact>.sha256` record written once with `--record-sha256` for local builds), else refuse. Verification: commit `ohos-workload 083c9dd0cece`; fail-closed branches by inspection (no pack rebuild for this report).
- **C4 publish integrity — Medium, fixed.** Evidence `ohos-workload/scripts/publish-workload-release.sh:54-57,93-114` (independent expected digest required for a real publish), `:119-160` (`published_asset_digest`, `guard_clobber`: `--clobber` only when the published digest matches, otherwise `--allow-clobber-mismatch` is required and logged). Attack path: publishing trusted only the local artifact, and `--clobber` could replace a different published asset blindly. Fix: fail-closed digest gate plus digest-compare clobber guard. Verification: commit `083c9dd0cece`; inspection only.
- **C5 kit self-authentication — Medium, fixed.** Evidence `ohos-workload/scripts/verify-kit.sh:14-27,90-121` (`--anchor`/`KIT_ANCHOR` binds the extracted tree to the outer `.tar.gz` sha256, fails closed when uncheckable); docs `runtime-ohos docs/plans/2026-09-21-ohos-delivery-kit-readme.md`, `docs/plans/2026-09-20-ohos-tester-quickstart.md` (commit `0adc3edc4d0`); `make-device-test-kit.sh` now takes docs from the repo source. Attack path: `SHA256SUMS` lives inside the archive it covers, so it proved only internal consistency; a swapped archive would still verify. Fix/verification: outer-anchor check implemented; inspection only.
- **C6 CI downloads — High, fixed.** Evidence `sdk-ohos/eng/ohos-install/build/build-ohos-all.sh:39-45,102-108,171-175,236+` (`--fetch-verified <url> <dest> [sha256]`, pins for dotnet-install.sh/netstandard/host pack); `sdk-ohos/.github/workflows/ohos-full-build.yml` (all downloads routed through it); `ohos-full-build.yml:133-165` (digest resolution + cache key). Attack path: CI fetched and executed/extracted toolchain packages without verification. Fix: fail-closed verified fetch everywhere; releases publish `SHA256SUMS`. Verification: commit `d57e58e28c`; inspection. Residual: pre-digest GitHub release assets need an explicit pin/override.
- **C7 NDK/OpenSSL/ICU extraction — High, fixed.** Evidence `sdk-ohos/eng/ohos-install/build/ohos-ci-env.sh:28-40` (per-artifact pins, resolution order, refuse unless `--allow-unverified`), `:83-107,117-155,196-209` (`verify_digest`, `github_asset_digest`, `resolve_digest`, `--print-digest`), `:171-175`; workflow cache key `ohos-full-build.yml:165` includes the resolved digests + script/versions hash. Attack path: SDK artifacts were extracted without verification and cached under a key not bound to content. Fix: digests resolved/verified before extraction, cache key digest-bound. Verification: commit `d57e58e28c`; inspection. Follow-up `ebd82459b0` normalised the minified GitHub API JSON parser and fixed the owner/repo URL in `build-ohos-all.sh`.
- **C8 CI least privilege — Medium, fixed.** Evidence `ohos-workload/.github/workflows/interaction-regression.yml:38-39,54-65`, `pixel-regression.yml:29-30,45-56`, `markdownlint.yml:24-34`. Attack path: workflows had write-capable default tokens, persisted credentials, and referenced mutable action tags / the mutable `maui-ohos feature/openharmony` branch, so a moved tag or branch could run unreviewed code in CI. Fix: `permissions: contents: read`, `persist-credentials: false`, actions pinned to verified SHAs (`checkout@11d5960…`, `setup-dotnet@67a3573…`, `setup-node@49933ea…`), cross-repo ref pinned to `90c8373` with a `workflow_dispatch` override. Verification: runs `35569919416`/`35569919487`/`35569919479` all success (commit `dc6b66baeef7`).

## Downgraded or Rejected Candidates

No finding after investigation; none of these became a fix.

| Candidate | Result | Evidence |
|---|---|---|
| Archive traversal during kit/pack extraction | Not exploitable | `toybox tar 0.8.12` and Python 3.14 both refuse `../` members and symlink writes (toy verification) |
| `runtime-ohos` ported code | No surface | RID/flag wiring only; no downloads, extracts or privileged operations |
| `aspnetcore-ohos` ported code | No surface | RID/flag wiring only; no downloads, extracts or privileged operations |
| Sensors | No finding | Data stays in-app; no privileged handling |
| Clipboard | No finding | Payload marshalling checked; no injection sink |
| Notifications | No finding | No cross-app content or privileged op |
| Device info | No finding | Read-only, app-sandboxed |
| Geolocation / permissions | No finding | No over-request found |
| Camera / file picker / print | No finding | No path/URI injection sink into privileged APIs |
| Launcher / browser / share implicit wants | No finding | Intents carry app-scoped URIs only |
| `module.json5` | No finding | No over-grant found in the manifests |
| TSFN sink lifecycle | No finding | Registration/teardown ordered correctly |
| Surface replay / window lifetime | No finding | No dangling window use outside A1/A6 |
| WebView asset resolution | No finding | Resolution bounded to the extracted payload (see B3/B5 fixes) |
| Managed context parsing | No finding | Parsing bounded and app-scoped |
| Delegate rooting / reflection seams | No finding | PII stays app-sandboxed; no cross-boundary escape |

## Residual Risk

- **No on-device verification of any fix**: device install is blocked by org policy. All A/B/C verification above is off-device (host rebuild, harness, typecheck, CI) unless stated otherwise.
- **`hap-sign-tool` argv password**: the p12 password remains visible in the signing child's `-keyPwd`/`-keystorePwd` argv; no tty-less alternative exists. Documented in `ohos-workload/scripts/sign-huawei.sh` and the signing guide.
- **Pre-digest GitHub release assets** still need an explicit sha256 pin/override; without one the installer fails closed (or the operator sets `ALLOW_UNVERIFIED=1`, which is insecure by design).
- **npm transitive dependencies** used by `markdownlint` (`npx`) are not digest-pinned; noted `ohos-workload dc6b66baeef7`.
- **B1/B3 hybrid/Blazor flows are on-device untested**; the off-device pins prove the reject paths, not ArkWeb's actual document/marker behaviour.
- **App-content XSS is not defended**: a hostile script *inside the app's own document* can read the hybrid/Blazor marker and forge completions. The envelope fixes defend cross-document/cross-origin delivery, not script injected into the app's own page.
- **A2 per-thread copy lifetime** is documented in `openharmony_host.h:233-240` (valid until the next get on the same thread; freed on thread exit).
- **A6 queue drains only on a successful launch**; a launch that never succeeds leaves bounded pending events queued.
- **A7 rejects later `startApp` in-process** (no teardown path), by design.
- **B4 harness pins committed (`ohos-workload f828c9f`)**: the decoder change was verified off-device
  (slice build, 15/15 decoder driver checks, the 244-check harness with the three B4 assertions covering
  the `escapedDecoded`/`injectionGuarded`/`tablessDropped` shapes and the contacts/calendar/Bluetooth
  parsers; count stays 244). The managed decoder remains on-device untested.
- **B6 is fixed by construction, device-unverified**: the `onLoadIntercept`/`loadUrl` event ordering and
  `isMainFrame()` cannot be exercised off-device, and unexpected event errors fail open (the load is
  allowed); an allowed POST form navigation is re-issued by `loadUrl` as GET (the interceptor exposes no
  method/body); a redirect produces a second, correctly re-checked `Navigating`.
- **B7 residual logging gaps (accepted, log-only)**: the launcher/browser and image "file not found"
  logs now reuse `SanitizeUrlForLog` (`maui-ohos 883e2b73`), but the image handler's general failure log
  (`image load failed: {ex.Message}`, ~line 46) can still embed a raw path, and a filename literally
  containing `?`/`#` is truncated by the sanitizer; the cap drops the oldest diagnostic lines by design.
- **C4 `--allow-clobber-mismatch`** remains available to an operator; it is explicit and logged, but still a bypass of the digest guard.

## Method note

Team-mode orchestration was unavailable in this session, so the scan used 3 parallel hunter subagents —
A: native/managed boundary (host C/NAPI, managed a11y/IME), B: data/injection (JS ↔ .NET IPC, kit
records, paths), C: build/supply chain (installers, pack/publish scripts, CI) — each returning candidate
findings with file:line evidence. Candidates were deduplicated into 23 items (A1-A8, B1-B7, C1-C8) plus
16 no-finding areas; exploitability was checked against the app sandbox model before severity was
assigned. Fixes ran in parallel batches (F1-F6 host/managed, B2/B-a/B-b IPC, C batches) with
reproduce-then-fix discipline and off-device verification. This consolidated report is a point-in-time
snapshot of the trees at the commits listed under Scope; it does not re-run any build or test.
