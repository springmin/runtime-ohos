# OHOS scratch script rescue — 2026-10-03

Rescue pass over `/data/storage/el2/base/tmp/opencode` before the MISC-42 cleanup (`CLEANUP-20261003.md`).
Scope: scripts/tools (`*.sh|py|mjs|ps1`, small C/C++ probes, Makefile snippets, fixtures). Excluded:
logs, evidence, haps, tars, nupkgs, unpacked trees, release dirs, repo clones. Dirs with mtime in the
last 30 min were registered only; nothing was deleted.

## Inventory

| Slice | Scale | Note |
| --- | --- | --- |
| Scratch overall | 748k files / ~233 GB | mostly artifacts, clones, unpack trees |
| Script-ish files (raw) | ~70k | vendor/source trees dominate |
| Top-level scripts | 271 (+16 C/C++/Makefile) | session run/push/wait scripts |
| Depth ≤ 2 scripts | ~1,300 | session dirs + tool dirs |

### a) already in a repo (ignored)

| Scratch | Repo counterpart |
| --- | --- |
| `base-build-ohos-all.sh`, `sdk-ohos-scripts/*` | sdk-ohos `eng/ohos-install/build/**` (repo copy newer) |
| `pack-host-debug.sh`, `run-harness.sh` | ohos-workload `test/hello-blazorwasm/arkts-host/pack-host.sh` |
| `*verify-kit.sh` (device-test-kit, cloud-test) | ohos-workload `scripts/verify-kit.sh` |
| `interp-fix/package-interp-pack.py` | sdk-ohos `.../build/package-interp-pack.py` |
| `comp-interop/{contract_check,extract}.py` | ohos-workload `scripts/check-host-exports.py --cross-check` |
| `signer-combo.py` | ohos-selfsign upstream (0BSD) |
| ~40 `*push*.sh`, `fix*-push-and-ci.sh`, docs pushes | superseded by ohos-workload `scripts/commit-paths.sh`; docs landed |
| `a1-harmony/*`, `aot-v{2,3}/*`, `lo-b/*` asset builders | ohos-workload kit asset flow (`make-device-test-kit.sh`) |

### b) migrated by this rescue

| Scratch | Target | Commit |
| --- | --- | --- |
| `check-codesign.py` | sdk-ohos `eng/ohos-install/tests/check-elf-codesign.py` | 29270d2cf0 |
| `packsplit-equivalence.sh` | sdk-ohos `eng/ohos-install/tests/test-packsplit-equivalence.sh` | 29270d2cf0 |
| `refresh-anchors.sh` | sdk-ohos `eng/ohos-install/refresh-release-anchors.sh` | 29270d2cf0 |
| `blazor-host/serve-blazor.py` | ohos-workload `scripts/serve-blazor-wwwroot.py` | da4b396 |
| `p2-interop/migrate.py` | ohos-workload `scripts/migrate-dllimport-to-libraryimport.py` | da4b396 |
| `conventions_scan.sh` | runtime-ohos `scripts/ohos-conventions-scan.sh` | this commit |

### c) discarded / left in scratch

| Category | Examples | Why |
| --- | --- | --- |
| One-off orchestration | `fix*-push-and-ci.sh`, `rc2*-watch.sh`, `dwait*`, `hap-final*` | single-run; repo scripts/CI supersede |
| Bun test-rig tooling | `gen-report*.py`, `write_final_report*.py`, `check-ohos-checklist.sh`, `ohos-ref-check.sh` | bun repo is not one of the four targets |
| Patch appliers / probes | `patch_*.py`, `ab-edits-*.py`, `apply_fixes24.py`, `fdprobe*.mjs`, `cprobe2.c`, `bindprobe.c` | one-shot edits already committed; findings recorded in docs/plans |
| CDGSS app domain | `perf39/*`, `mapfix/*`, `hap-final1{1,2}/*` | app repo outside the four targets |
| Logs/evidence/products | `*.log`, haps, nupkgs, `unpacked/`, `release-*/` | not scripts |

## Migration result

- ohos-workload `da4b396` → pushed `origin/master` (aac8a8b..da4b396).
- sdk-ohos `29270d2cf0` → `feat/aotpack-rebuild` (no upstream; push attempted).
- runtime-ohos this commit → `feature/openharmony` (script + README + this plan; rebase, no force).
- maui-ohos: no b-class candidate — device harness lives in ohos-workload `test/`, gates were one-off wrappers.

- **Remaining scratch** — active (<30 min mtime): `aotpack-rebuild/`, `hap-final12/`, `hci/`, `t/`, `rc2-align/` — register only.
- Bun/CDGSS-domain tools and deep session dirs (depth ≥3, sampled not enumerated; `reg-kit*/ow` are clones).
- `feat/aotpack-rebuild` has no upstream: the sdk-ohos commit may need the branch owner to push/merge.
