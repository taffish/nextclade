# Nextclade

`nextclade` packages [Nextclade](https://github.com/nextstrain/nextclade) for
TAFFISH. The same image contains the native CLI and official Nextclade Web
client from one pinned upstream commit.

Package identity:

- name: `nextclade`
- command: `taf-nextclade`
- kind: `tool`
- version: `3.28.0-r1`
- TAFFISH app license: Apache-2.0
- upstream license: MIT
- native platforms: `linux/amd64`, `linux/arm64`
- upstream release: [3.28.0](https://github.com/nextstrain/nextclade/releases/tag/3.28.0)
- upstream commit: `9a2ca6ec5af0e543e1c1fdf0749654c0b6acfe14`

This upstream update advances both CLI and Web from 3.25.1 to 3.28.0. It retains
the previous release's read-only-SIF-safe Web helper, supervised foreground
service, and personal/site dataset preparation and read-only reuse interfaces.
Nginx runtime writes remain in unique `/tmp/nextclade-web.*` directories.

The 3.26–3.28 upstream series refreshes the tree viewer to Auspice 3.1,
improves narrow-screen layouts, adds metadata/tree exports and clade-color
controls, and fixes output, input, TLS and dataset-extraction error handling.
Upstream now honors a dataset's alignment preset and reports additional
alignment warnings; results can therefore differ from 3.25.1 with the same
inputs. Both surfaces retain the official upstream analysis code.
This package neither changes the upstream algorithms nor disables TLS checks.

Version 3.25.0 introduced the optional `--penalty-gap-enter-cds` alignment parameter
(default 0), warnings for loss of an unambiguous ATG start codon, collapsible
Web tree/export sidebars, and an Auspice JSON download on the tree page.
Choose a nonzero alignment penalty deliberately; this app does not change the
upstream default. The start-codon warnings also appear in JSON/NDJSON/CSV/TSV
and in the Web sequence-name tooltip. Ambiguous codons are not called lost.
Mutation patterns introduced in 3.24 remain available; they require
`mutationPatterns` in `pathogen.json` and a reference tree.
See the [official release notes](https://github.com/nextstrain/nextclade/releases/tag/3.28.0).

## Installation

After this release is published and present in the refreshed local Hub index:

```sh
taf update
taf install nextclade 3.28.0-r1
```

Unpublished checkout testing uses the generated target wrapper described below;
the presence of a local candidate image does not mean this release is published.

## What This App Packages

- `nextclade`: upstream alignment, mutation calling, clade assignment, quality
  control, phylogenetic placement, dataset and utility CLI
- `nextalign`: compatibility symlink to the same CLI binary
- `nextclade-web`: foreground service for the pinned official Web client
- `nextclade-datasets`: exact-member dataset preparation, integrity and reuse
- `nginx`: static server used only by `nextclade-web`
- `nextclade-smoke`: packaging and runtime test helper

The Web assets came from upstream workflow run
[`40728181151`](https://github.com/nextstrain/nextclade/actions/runs/40728181151)
for the pinned commit. Packaging rewrites official-site asset URLs to the local
service, disables Plausible analytics, and removes source maps. It does not
replace the upstream analysis code or visible UI.

The upstream repository and release ship both the native CLI and the official
browser client; no separate package extra, plugin, companion desktop project,
or noVNC layer is needed. The CLI is the primary command-reproducible surface.
The Web client is an optional official browser interface served as static files,
not a native desktop application; native-window and noVNC geometry checks are
therefore N/A.

The app does not bundle pathogen datasets, sequence data, a browser,
authentication, or TLS. It does not freeze the changing dataset selected by a
network-backed “latest” request.

## CLI Usage and Command Mode

Show upstream identity and help:

```sh
taf-nextclade -- --version
taf-nextclade -- --help
taf-nextclade nextclade run --help
```

TAFFISH automatic command mode interprets a non-option first argument as a
packaged executable. Use `taf-nextclade nextclade run ...`, not
`taf-nextclade run ...`. Use `--` for option-leading input to the default
`nextclade` command.

Run with a preserved local dataset:

```sh
taf-nextclade nextclade run \
  --input-dataset dataset \
  --output-all results \
  sequences.fasta
```

Or supply explicit references:

```sh
taf-nextclade nextclade run \
  --input-ref reference.fasta \
  --input-annotation annotation.gff3 \
  --output-tsv results.tsv \
  sequences.fasta
```

The latter can omit annotation, tree, or pathogen JSON, but that narrows the
scientific result: amino-acid results, dataset-specific QC/clades, and
phylogenetic placement may be unavailable.

## Reusable Dataset Contract

Nextclade datasets form an evolving selectable family; the whole catalog is
not one stable scientific resource. The smallest reusable unit used here is an
explicit dataset ID at an immutable dataset tag. `nextclade-datasets` never
chooses a pathogen, resolves “latest”, or downloads the complete family.
The moving `latest` and `unreleased` selectors are rejected locally.

Prepare one member in the standard personal root:

```sh
base=${XDG_DATA_HOME:-$HOME/.local/share}/taffish/datasets/nextclade
mkdir -p "$base"
TAFFISH_NEXTCLADE_DATASET_INSTALL_ROOT="$base" \
  taf-nextclade nextclade-datasets install \
    --name DATASET_ID --tag DATASET_TAG
```

The existing host directory is mounted read-write at `/dataset-install`; the
helper refuses a marker-only or image-root install target. It resolves the
exact member, performs bounded fresh-staging retries without byte-range resume,
verifies required metadata and the requested tag, rejects links and special
files, records a per-file SHA256 inventory, and promotes the member atomically
under:

```text
${XDG_DATA_HOME:-$HOME/.local/share}/taffish/datasets/nextclade/
  3.28.0/members/<dataset-id>/<dataset-tag>/
```

Every install first verifies the entire existing resource root under its lock,
using the same version, manifest, inventory and member-integrity checks as
`verify` and mounted CLI use. Unindexed members, stray payload files and symlinks
inside the member tree are rejected. An empty root may be initialized; an
invalid nonempty root is never silently relabelled or reindexed, including when
adding a new member or using `--force`. Preserve an invalid root and restore its
exact known-good contents, or install selected members into a fresh root.
`--force` replaces a member only in a fully verified root; it is not a repair
override for a damaged library.

Interrupted or incomplete members are not advertised as ready. A root manifest
and TSV inventory describe every complete member; `--force` uses a rollback
backup while replacing an existing member. Inspect or validate the prepared
root with:

```sh
taf-nextclade nextclade-datasets list-installed
taf-nextclade nextclade-datasets verify
taf-nextclade nextclade-datasets path --name DATASET_ID --tag DATASET_TAG
```

If an installation is interrupted by Ctrl-C/INT or TERM, wait for it to exit
before inspecting or retrying. A signal handled before cleanup returns 130 or
143. Before the verified commit point, the helper restores the previous member
and root metadata; after that point, the verified replacement is retained.
Cleanup runs once and ignores INT/TERM/HUP, so a signal arriving during cleanup
of an already committed installation can still leave a successful exit 0.
Other installed members are not replaced. Lock cleanup is armed before lock
acquisition; INT/TERM/HUP are deferred only across the acquisition/ownership
handoff. A handled signal in that earliest window removes this install's lock,
but never another writer's lock. Empty initialization directories may remain
and are safe to reuse on retry.
Verify the root, then repeat the same install command (including `--force` if
replacement is intended). A successful repeated install without `--force`
leaves complete members unchanged.

Each transaction exclusively creates a private `0700` lock directory and keeps
its staging, index temporaries and replacement backup inside that directory.
Cleanup checks the lock's device/inode identity and refuses a replaced directory
or symlink. Legacy `.staging.*`, `.backup.*` and nonempty `.taffish` paths are
not owned by a new install: installation fails and preserves them for inspection.
Live and dangling control-directory symlinks are rejected, never followed for
cleanup. Do not delete old recovery paths merely because their PID matches a
new container process.

If cleanup itself fails because of storage or permissions, the helper exits 74
and preserves the transaction lock and available recovery files. Do not blindly
delete `.taffish-install.lock` or `.backup.*`. Stop all writers, preserve a copy
of the whole root, and have its owner inspect the exact transaction: an existing
`.taffish-install.lock/backup` is the old member; the lock contains its previous root
manifest/inventory/ready markers. After resolving the underlying error, restore
that exact member to its original ID/tag path and the saved root markers, then
verify the whole root before removing only that inspected transaction's lock
(including its `staging` and `index` children). Legacy recovery paths remain
separate and must not be removed by a newer transaction.
Do not overwrite an uninspected member. Alternatively preserve the failed root
and install the selected exact members into a fresh version root from known
sources. A stale lock is intentionally not removed automatically.

SIGKILL, machine failure, and power loss cannot run shell cleanup. The same
preserve-and-inspect recovery boundary applies; this helper is not a durable
database journal. It does not promise atomicity against arbitrary disk failure
or uninterrupted readers during a multi-file root-index update.

The standard personal root, `/usr/local/share/taffish/datasets/nextclade/3.28.0`,
and `/opt/taffish/datasets/nextclade/3.28.0` are discovered in that order and
mounted read-only at `/opt/taffish/datasets/nextclade`. Set
`TAFFISH_NEXTCLADE_DATASET_PATH` to select another complete version root, or
`TAFFISH_NEXTCLADE_DATASET_AUTO_MOUNT=0` to disable discovery. The explicit
path is fail-closed: an empty, incomplete, or unsafe root stops before container
command execution. Prepared-root paths must not contain whitespace, commas,
colons, or glob characters; symlinks are resolved to a physical path before
validation. The thin container-side launcher quietly recomputes complete
member inventories and cross-checks member identity, root manifest, root TSV and
ready markers before every `nextclade` or `nextalign` invocation that can consume
an automatically mounted root. It then `exec`s the original pinned binary without
changing argv, help, exit/signal behavior, or machine-readable stdout. Pass the
container path printed by `nextclade-datasets path` to
`nextclade run --input-dataset`.

An exact older tag remains valid when the catalog has a newer default tag.
The helper checks membership in `versions`, passes your exact tag to the
upstream downloader, and verifies the downloaded `pathogen.json` tag. It does
not silently substitute the catalog's `version` (latest) field.

Prepared roots are app-version scoped. A 3.25.1 prepared root is not silently
relabelled as 3.28.0: keep it for the older wrapper, or prepare the same exact
upstream ID/tag into the new version root. Explicit upstream `--input-dataset`
remains available for independently preserved ordinary dataset directories.

Automatic mounting is preferred because the app supplies both the read-only
bind and the integrity marker. If site policy requires manual runtime binds,
disable discovery and preserve the same preflight explicitly:

```sh
TAFFISH_NEXTCLADE_DATASET_AUTO_MOUNT=0 \
TAFFISH_DOCKER_RUN_ARGS="-v /host/root/3.28.0:/opt/taffish/datasets/nextclade:ro -e TAFFISH_NEXTCLADE_DATASET_MOUNTED=1" \
TAFFISH_CONTAINER_BACKEND=docker taf-nextclade nextclade-datasets verify

TAFFISH_NEXTCLADE_DATASET_AUTO_MOUNT=0 \
TAFFISH_PODMAN_RUN_ARGS="-v /host/root/3.28.0:/opt/taffish/datasets/nextclade:ro -e TAFFISH_NEXTCLADE_DATASET_MOUNTED=1" \
TAFFISH_CONTAINER_BACKEND=podman taf-nextclade nextclade-datasets verify

TAFFISH_NEXTCLADE_DATASET_AUTO_MOUNT=0 \
TAFFISH_APPTAINER_RUN_ARGS="--bind /host/root/3.28.0:/opt/taffish/datasets/nextclade:ro --env TAFFISH_NEXTCLADE_DATASET_MOUNTED=1" \
TAFFISH_CONTAINER_BACKEND=apptainer taf-nextclade nextclade-datasets verify
```

Omitting the marker bypasses automatic preflight and is unsupported. The three
forms above expose the same container path; replace the final `verify` command
with the intended Nextclade invocation only after it succeeds.

For site installation, an administrator creates a dedicated writable parent
at `/usr/local/share/taffish/datasets/nextclade`, runs the same exact-member
install with `TAFFISH_NEXTCLADE_DATASET_INSTALL_ROOT` pointing there, verifies
the root, and leaves directories mode 0755 and files mode 0644. Ordinary users
then discover and reuse it read-only without write permission. Do not combine
personal and site writers, and do not modify a prepared member in place.

Important resource limits:

- upstream dataset tags are fixed selectors, but the catalog evolves;
- the upstream catalog/repository does not publish a uniform resource license,
  member byte size, or authoritative checksum;
- run `--dry-run` before installation to inspect host `available_bytes` and
  reserve space conservatively because the member size is unavailable;
- installation fails before creating a lock or moving an old member if the
  filesystem cannot be measured or has less than the minimum free-space bound.
  Local sources require twice their measured bytes plus 1 MiB; unknown remote
  sizes have only a 1 MiB metadata floor, not a complete capacity guarantee;
- failed network attempts restart into fresh staging rather than resuming a
  partial transfer; a completed prepared root or `--source-dir` is the reuse path;
- `--dry-run` reports size/checksum as unavailable, and the recorded
  SHA256 values are post-download local integrity evidence, not upstream
  authenticity evidence;
- review the selected dataset's provenance and terms before installing or
  sharing it at site scope;
- preparation requires network unless `--source-dir` supplies an already
  acquired exact member; verify, lookup, and local analysis can be offline.

## Backend Capability Matrix

| Capability | Docker | Podman | Apptainer | Boundary |
| --- | --- | --- | --- | --- |
| CLI and exact offline smoke | supported | supported | supported, read-only SIF | Current-candidate validation status is recorded in release.md. |
| Prepared dataset install | automatic read-write bind from `TAFFISH_NEXTCLADE_DATASET_INSTALL_ROOT` | same | same | Host directory must already exist and be writable; helper confirms an actual bind for `/dataset-install`. |
| Prepared dataset reuse | automatic read-only bind | automatic read-only bind | automatic read-only bind | Complete personal/site/override version root only. |
| Web service | loopback `-p` mapping | loopback `-p` mapping | shared host network, no `-p` | Foreground helper; no authentication/TLS; keep loopback-only and choose an unused site-allowed port. |

The required validation axes are native amd64 Linux Docker, rootless Podman,
and Apptainer on xjp, plus native arm64 Docker and Podman, with direct smoke
and generated-wrapper tests. See release.md for the completed current receipts;
older receipts do not establish this candidate's readiness. There is no claim
of an all-platform/backend Cartesian product. Podman
requires a working host-side init binary for `--init`. See release.md for the
actual evidence of this candidate, not the previous release's receipts.

## Browser Interface

Docker:

```sh
TAFFISH_DOCKER_RUN_ARGS="-p 127.0.0.1:8765:8000" \
  TAFFISH_CONTAINER_BACKEND=docker \
  taf-nextclade nextclade-web --port 8000 --host-port 8765
```

Podman uses the equivalent Podman runtime option:

```sh
TAFFISH_PODMAN_RUN_ARGS="-p 127.0.0.1:8765:8000" \
  TAFFISH_CONTAINER_BACKEND=podman \
  taf-nextclade nextclade-web --port 8000 --host-port 8765
```

Apptainer shares the host network:

```sh
TAFFISH_CONTAINER_BACKEND=apptainer \
  taf-nextclade nextclade-web --port 8765 --host-port 8765
```

The helper prints starting status, URL, SSH tunnel, Ctrl-C instruction, and log
path before a blocking child starts, then prints ready only after the owned
Nginx process belongs to this session and its readiness endpoint returns this
session's unique identity. A pre-existing service on the same port cannot make
a failed second session report ready. It supervises that
process continuously; a critical exit names the component, shows a log tail,
cleans up, and exits nonzero. Ctrl-C and TERM use bounded process-group cleanup
with statuses 130 and 143. During that cleanup, further INT/TERM/HUP signals are
ignored so they cannot interrupt the final process cleanup and stopped marker.
Closing the output pipe does not bypass cleanup or change a handled signal's
status. If child termination or runtime-directory removal fails, the helper
returns 74 and retains available diagnostic files instead of reporting stopped.
If the runtime directory's identity changes, it is not removed or followed;
already recorded owned processes are still stopped and the helper fails with 74.
An early-interrupt cleanup recovers the owned PID/group from the private
handshake before waiting, including the launch-to-registration window.
For a remote host, keep the published port on
127.0.0.1 and use the printed SSH tunnel. Apptainer shares the host network, so
the selected port must also satisfy site policy and firewall rules. Browser
uploads and displayed/exported results may reveal filenames, sequence or sample
identifiers, and analysis results; use a trusted browser session and never expose
this unauthenticated service beyond loopback.

For the commands above on a remote host, open a separate local terminal:

```sh
ssh -N -L 8765:127.0.0.1:8765 user@server
```

Then open `http://127.0.0.1:8765/` locally. Stop the service in its original
terminal with Ctrl-C, and stop the SSH tunnel separately when finished.

The Web client normally contacts the official data server for discovery and
download, while computation occurs in the browser. Offline Web use requires
uploading sequence input and a previously preserved dataset through the UI;
the CLI read-only mount is not automatically injected into browser state.

For a persistent HTTP log, set `TAFFISH_NEXTCLADE_WEB_LOG_FILE` before any of
the backend commands above, using a path inside the wrapper-bound working
directory or home:

```sh
export TAFFISH_NEXTCLADE_WEB_LOG_FILE="$PWD/web session.log"
```

The app forwards this value without joining command arguments. A nonempty value
selects the log; an explicit `nextclade-web --log-file FILE` overrides it.
Unset or empty values retain the disposable per-session log. This interface
preserves whitespace paths across Docker, Podman, and Apptainer; it does not
change unrelated host mounts or make an image-root path writable.

Current TAFFISH automatic command mode reconstructs a shell command line, so
ordinary shell quotes alone do not preserve CLI argument boundaries. For other
CLI input/output paths containing spaces, pass literal quotes, for example
`'"input file.fasta"'` as one argument. Avoid shell metacharacters in such paths;
the Web log environment-variable interface above is preferred for service logs.
The image includes Bash for the generated complex-command shell path; adding
Bash to the host would not supply this container dependency.

### Local source-checkout service testing

Installed users should use the `taf-nextclade` commands above. In a source
checkout, use the generated wrapper for long-running services. The previous
3.23.0-r2 audit observed buffered startup output and incomplete interrupt
cleanup with TAFFISH 0.11.0 `taf run`; this update does not re-qualify that core
entry path. Its service evidence is for generated wrappers, not `taf run`.

Build the generated wrapper and run that wrapper directly for unpublished
local testing:

```sh
taf build
TAFFISH_DOCKER_RUN_ARGS="-p 127.0.0.1:8765:8000" \
  TAFFISH_CONTAINER_BACKEND=docker \
  target/taf-nextclade-v3.28.0-r1 \
  nextclade-web --port 8000 --host-port 8765
```

Final generated wrappers passed terminal Ctrl-C during readiness and after
ready (130), and TERM (143), with stopping confirmation, closed ports and no
owned service residue. Docker/Podman TERM targeted the actually attached
runtime client; Apptainer TERM targeted the explicitly owned terminal-session
process group. In every case the outer wrapper was awaited and returned 143.
PID-only TERM to the generic wrapper shell or Apptainer runtime parent is not
a supported service-manager contract under current TAFFISH. Cleanup ignores
additional INT/TERM/HUP while the first stop is already being completed, so a
second signal cannot interrupt the bounded cleanup. These are foreground
terminal-session guarantees, not a daemon deployment interface.

## Inputs and Outputs

Inputs include FASTA (including gzip, bzip2, xz, or zstd compression), a local
dataset directory/zip, reference FASTA, optional GFF3 annotation, optional
Auspice tree JSON, and optional pathogen JSON.

`--output-all DIR` writes the standard aligned FASTA, CSV/TSV, JSON,
translation, annotation, and tree outputs. Individual `--output-*` options
select exact paths. Treat output schemas and biological interpretation as
upstream contracts tied to both the pinned program and selected dataset.

## Runtime Write Map and Network Boundary

| Path | Writer | Lifetime | Mount/cleanup contract |
| --- | --- | --- | --- |
| `/tmp/nextclade-web.*` | Web helper/Nginx | one service | unique directory; removed on normal, signal, startup, or critical exit |
| `TAFFISH_NEXTCLADE_WEB_LOG_FILE` / explicit `--log-file FILE` | Web helper/Nginx | caller-selected | persistent wrapper-bound output; parent must be writable |
| `/tmp/nextclade-dataset-*` | dataset helper | one command | catalog/log scratch; removed by trap |
| `/dataset-install/3.28.0` | dataset helper | persistent | only an actual explicit writable host bind |
| requested CLI outputs/workdir | Nextclade CLI | persistent | caller's wrapper-bound working directory |
| image root (`/opt`, `/usr`, `/var/lib/nginx`) | nobody at runtime | immutable | no runtime chmod/chown or write dependency |

Network is required for `dataset list|get`, helper network installation,
`run --dataset-name`, parts of `sort`, and normal Web discovery. A run with
preserved local input and dataset is offline-safe. The manifest smoke does not
perform implicit network access.

Upstream maintains paired CLI tags (`3.28.0`) and Web tags (`web-3.28.0`) for
the same stable commit. The watch rule intentionally filters `web-*` and strips
that prefix before version comparison, preventing unrelated mixed-tag lines from
masking future stable updates while tracking the browser surface packaged here.

## Packaging, Provenance, and Size

The final image uses a digest-pinned Alpine base and upstream native musl
binaries. A thin packaged `nextclade` launcher performs full verification before
any automatically mounted dataset is consumed, including TAFFISH automatic
command mode, while preserving stdout for machine-readable upstream commands.
Web assets and CLI provenance are embedded; build-only `curl`/`file`, the Web
archive, source maps, toolchains, build caches, headers, and sysroots are absent
from the final filesystem. BusyBox `wget` remains for explicit dataset downloads.
Bash, `jq`, Nginx, CA certificates, and small POSIX helpers
are intentional runtime dependencies for generated wrapper commands, dataset
validation and the Web service. The already-executable upstream binary is not
chmod'ed again in the final stage, avoiding a duplicate binary layer without
removing runtime payloads.

Per-architecture image sizes and final filesystem profiles are recorded in the
release note after the canonical builds; the required CLI and Web assets remain
the dominant payloads.

## Troubleshooting

- `executable file not found ... run`: use `taf-nextclade nextclade run ...`.
- dataset install refuses `/dataset-install`: set the install-root environment
  variable to an existing writable host directory; a marker alone is rejected.
- selected dataset root is invalid: run `nextclade-datasets verify`, repair or
  replace it, select another root, or explicitly disable auto-mount.
- Web UI has no dataset list: permit access to the official server, or supply
  preserved local resources through the upstream Web URL-parameter interface;
  remote catalog discovery cannot work offline. CLI filesystem binds do not
  automatically supply the browser's dataset state.
- browser cannot connect: wait for ready and match host/container port mapping.
- missing amino-acid, clade, QC, or placement results: use the appropriate
  complete pathogen dataset instead of a bare reference.
- custom Web tree fails in the diversity panel: retain the Auspice
  `meta.genome_annotations.nuc` genome map, even when there are no protein CDSs.
  A minimal tree accepted by the CLI need not contain all Web display metadata.

## Testing Boundary

The manifest smoke checks all packaged commands, exact identity/provenance, a
real explicit-reference analysis, schema generation, an offline exact-member
install, transaction rollback, traversal/integrity corruption rejection, Web
readiness, startup/ready signals, nonzero and zero-status critical-process
supervision, cleanup, and invalid arguments. Every manifest command must also
run in a fresh offline container with a read-only image root and only its
documented `/tmp` and workdir writes. Docker/Podman resource binds and a real
read-only SIF must be tested separately through generated wrappers.

The manifest retains synthetic CDS-boundary and start-codon regressions,
including default-versus-explicit penalty, JSON/NDJSON/TSV, and ambiguous codons.
It retains the four-substitution mutation-pattern/no-tree regression and adds
an offline catalog-parser unit for fixed older tags and missing-tag rejection.
All declared exist entries and independent smoke commands must be rerun against
this exact candidate; historical 3.25.1-r1 PASS does not qualify this update.
New packaging regressions cover closed-output cleanup, cleanup failure, free
space and upstream JSON/error-output contracts. Current receipts, image
identities and remaining boundaries are recorded in release.md.

Browser qualification uses synthetic local inputs, real pointer interaction,
and a nonempty downloaded result. This is a direct browser app, not a noVNC
desktop: window-manager, desktop geometry and noVNC chrome checks are N/A.
JSON, SVG and Newick exports and the current narrow-screen layout are checked;
the upstream 3.26–3.28 series replaces the older crowded navigation and clipped
tree layout. Exact current browser evidence is recorded with this release.

Resource transaction tests use tiny synthetic members, including real-wrapper
HTTP catalog/ZIP download from a private loopback server, installation,
idempotence, rollback, recovery, and read-only reuse. A root-owned disposable
test site additionally verifies one administrator install followed by ordinary
user read-only reuse on all three Linux backends. This is not a production
catalog download or a deployment into real system site directories. Standard-path
priority is separately tested in a private prefix, not by modifying system paths.
Full production dataset acquisition, selected-member terms, site permissions and scientific suitability
remain user/site responsibilities. The helper's network retry path does not
claim byte-range resume; preserved exact members can be reused offline.
Signal regressions additionally inject INT/TERM immediately before and after
lock acquisition, and at backup, staging, promotion and root-index boundaries,
including repeated signals during rollback and a recovery-rename failure.
Both existing roots and fresh roots are covered; a competing caller must not
remove another writer's lock. Invalid versions, inventories, content, missing
or dangling markers, unindexed members, orphan files and linked member parents
must fail through verification, discovery and normal/forced installation.
Tests check preservation, trusted-copy recovery, successful retry, and
SHA256/mtime/ownership/mode-preserving idempotence through real wrappers and
actual writable host binds. No scientific code is patched.
Cleanup ownership regressions also preserve colliding legacy staging, backup
and control-metadata paths, external sentinels behind live or dangling links,
and locks replaced by a symlink or another directory. Rejected roots remain
untouched while recovery and idempotence are tested in a fresh root.

These engineering gates do not replace biological validation on production
sequences with an appropriate fixed pathogen dataset.

## License and Citation

TAFFISH packaging is Apache-2.0. Nextclade software and packaged Web assets are
MIT licensed. Dataset licensing is separate and not declared uniformly by the
upstream catalog.

Cite: Aksamentov I, Roemer C, Hodcroft EB, Neher RA. Nextclade: clade
assignment, mutation calling and quality control for viral genomes. *Journal
of Open Source Software*. 2021;6(67):3773.
[doi:10.21105/joss.03773](https://doi.org/10.21105/joss.03773).

Detailed upstream manual:
[Nextclade documentation](https://docs.nextstrain.org/projects/nextclade/en/stable/).
