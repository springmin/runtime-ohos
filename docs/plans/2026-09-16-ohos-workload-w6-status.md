# OpenHarmony platform workload — W6 status (2026-09-16)

W6 packages the workload for delivery and wires it into the fork's SDK install/build flow.

## Workload bundle
- `ohos-workload/scripts/pack-workload-bundle.sh` -> `dist/ohos-workload-<version>.tar.gz`
  containing the manifest, `feed/*.nupkg` (six packs, ~26 MB) and
  `templates/install-ohos-workload.sh`.
- The bundle installer derives the SDK feature band from the installed SDK
  (`11.0.100-rc.1.26451.109` -> `11.0.100-rc.1`), copies the manifest into
  `sdk-manifests/<band>/` and runs
  `dotnet workload install openharmony --skip-manifest-update --source <feed>`.
  It is idempotent and supports `--dry-run` / `--dotnet <muxer>`.

## SDK install/build integration (sdk-ohos, branch feature/openharmony)
- `install-dotnet-ohos.sh`:
  - new `install_workload()` step (runs after signing, before verification);
  - a `workload` first argument installs only the workload into an existing SDK;
  - the bundle is found via `WORKLOAD_BUNDLE=<dir|tar.gz>`, next to the SDK
    (`<install>/workload/`), or downloaded from the release the SDK tarball came from
    (asset `ohos-workload-*.tar.gz`; graceful skip when absent). `INSTALL_WORKLOAD=0`
    and `WORKLOAD_DRY_RUN=1` control the step.
- `build-ohos-all.sh` stage 5 collects the bundle into the release outputs
  (`OHOS_WORKLOAD_BUNDLE`, or `~/springsources/ohos-workload/dist/` by default).
- Commits: `c5e9ae5dda` (workload step), `67c8dea8c1` (bundle looked up in the SDK's own
  release).

## Artifact hygiene fix
The workload repo accidentally committed the generated feed nupkgs (including the 26 MB
BCL runtime pack alias) in two commits. Since the repo is local-only, history was rewritten
(`git filter-branch --index-filter 'git rm -r --cached .feed dist .signing'`) and the
`.gitignore` now excludes `.feed/`, `dist/` and `.signing/`; the repo shrank from 138 MB to
19 MB while the on-disk artifacts are simply regenerated on demand:
`scripts/pack-local-workload.sh` / `scripts/pack-workload-bundle.sh` (verified: pack dirs
intact, bundle rebuilt, installer dry-run passes, and an OHOS library build still succeeds).

## Still open
- Publish the bundle as a release asset (or inside the SDK tarball) so the installer's
  download path works for end users; that changes releases and needs a maintainer decision.
- W4/W3 leftovers: the ArkTS declarative UI page needs the ets-loader toolchain, and the
  MAUI platform slice (`Microsoft.Maui.Controls` for openharmony) is the next large piece.
