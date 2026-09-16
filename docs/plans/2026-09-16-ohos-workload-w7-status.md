# OpenHarmony platform workload — W7 status (2026-09-16)

W7 publishes the workload as releases (A + B + rolling), hardens the installer, and opens
the UI build path.

## Publishing (A + B + rolling latest)
| Release (springmin/sdk-ohos) | Kind | Asset |
|---|---|---|
| `workload-1.0.0-preview.1` | immutable, workload's own version line (B) | `openharmony-workload-1.0.0-preview.1.tar.gz` |
| `workload-latest` | rolling | `openharmony-workload-latest.tar.gz` (stable name) |
| `v11.0.100-rc.1.26451.109-openharmony` | SDK release (A) | same `openharmony-workload-1.0.0-preview.1.tar.gz` attached |

`ohos-workload/scripts/publish-workload-release.sh` automates the versioned + rolling
releases and, with `--also-sdk-release <tag>`, the A attachment.

## Installer resolution order (A and B coexist)
1. `WORKLOAD_BUNDLE=<dir|tar.gz>`
2. a bundle cached next to the SDK (`<dotnet-root>/workload/openharmony-workload-*.tar.gz`)
   or next to the script (legacy `ohos-workload-*.tar.gz` accepted)
3. `WORKLOAD_RELEASE_TAG=<tag>` (pin a versioned workload release or an SDK release snapshot)
4. the rolling `workload-latest` asset via a **direct URL** (no GitHub API, 7-day cache)
5. the newest `workload-*` release (API lookup)
6. the release the SDK came from (A fallback)

Verified on device: rolling download (asset download counter +1), caching, idempotent
install; the SDK-release path skips gracefully when no asset is attached.

## UI build path
- The headless shell stays `es2abc`-compiled. A UI build supplies its own `modules.abc`
  (ArkTS toolchain: ets-loader under hvigor, or DevEco Studio) through the new packaging
  properties:
  - `-p:OpenHarmonyArktsModulesAbc=<path to modules.abc>`
  - `-p:OpenHarmonyUIPage=pages/Index` (writes `main_pages.json`)
- Verified with a placeholder abc: the hap carries the page list and the supplied abc, and
  `verify-app` succeeds.
- `templates/ets/entryability/EntryAbility.ui.ets` (loadContent + full lifecycle) and
  `templates/ets/pages/{Index.ets,README.md}` document the recipe; `pages/Index.ets` hands
  its `NodeContent` to the host, which forwards it to the managed app
  (`OpenHarmonyBridge.NodeContent`) — the hook for an XComponent/Skia rendering surface.

## Next (W8)
- Drive the SDK's `ets-loader` rollup pipeline (or require DevEco) to produce a real UI
  `modules.abc`; then attach an XComponent and hand its surface to the managed side.
- MAUI platform slice on top of the lifecycle bridge + UI surface.
