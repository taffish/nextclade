# Nextclade

`nextclade` packages [Nextclade](https://github.com/nextstrain/nextclade) for
TAFFISH. The same image contains the native CLI and official Nextclade Web
client from one pinned upstream commit.

Package identity:

- name: `nextclade`
- command: `taf-nextclade`
- kind: `tool`
- version: `3.23.0-r2`
- TAFFISH app license: Apache-2.0
- upstream license: MIT
- native platforms: `linux/amd64`, `linux/arm64`
- upstream release: [3.23.0](https://github.com/nextstrain/nextclade/releases/tag/3.23.0)
- upstream commit: `629ea8fb0cfe3165db13ddc75dab16d3c2292dbd`

This same-upstream successor fixes the published `3.23.0-r1` Web helper on a
read-only Apptainer SIF. Alpine Nginx otherwise tries to create its error log
and request-body/proxy temporary directories below `/var/lib/nginx`. Release 2
places every Nginx runtime write in a unique `/tmp/nextclade-web.*` directory,
uses stderr for the error log, and supervises the owned process group. It also
adds a version-pinned reusable dataset helper and wrapper-managed read-only
dataset mounts. Upstream software identity remains 3.23.0.

## Installation

After this release is published and present in the refreshed local Hub index:

```sh
taf update
taf install nextclade 3.23.0-r2
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
[`32247980559`](https://github.com/nextstrain/nextclade/actions/runs/32247980559)
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
  3.23.0/members/<dataset-id>/<dataset-tag>/
```

Interrupted or incomplete members are not advertised as ready. A root manifest
and TSV inventory describe every complete member; `--force` uses a rollback
backup while replacing an existing member. Inspect or validate the prepared
root with:

```sh
taf-nextclade nextclade-datasets list-installed
taf-nextclade nextclade-datasets verify
taf-nextclade nextclade-datasets path --name DATASET_ID --tag DATASET_TAG
```

The standard personal root, `/usr/local/share/taffish/datasets/nextclade/3.23.0`,
and `/opt/taffish/datasets/nextclade/3.23.0` are discovered in that order and
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

Automatic mounting is preferred because the app supplies both the read-only
bind and the integrity marker. If site policy requires manual runtime binds,
disable discovery and preserve the same preflight explicitly:

```sh
TAFFISH_NEXTCLADE_DATASET_AUTO_MOUNT=0 \
TAFFISH_DOCKER_RUN_ARGS="-v /host/root/3.23.0:/opt/taffish/datasets/nextclade:ro -e TAFFISH_NEXTCLADE_DATASET_MOUNTED=1" \
TAFFISH_CONTAINER_BACKEND=docker taf-nextclade nextclade-datasets verify

TAFFISH_NEXTCLADE_DATASET_AUTO_MOUNT=0 \
TAFFISH_PODMAN_RUN_ARGS="-v /host/root/3.23.0:/opt/taffish/datasets/nextclade:ro -e TAFFISH_NEXTCLADE_DATASET_MOUNTED=1" \
TAFFISH_CONTAINER_BACKEND=podman taf-nextclade nextclade-datasets verify

TAFFISH_NEXTCLADE_DATASET_AUTO_MOUNT=0 \
TAFFISH_APPTAINER_RUN_ARGS="--bind /host/root/3.23.0:/opt/taffish/datasets/nextclade:ro --env TAFFISH_NEXTCLADE_DATASET_MOUNTED=1" \
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
| CLI and exact offline smoke | validated | validated | validated, actual read-only SIF | Final native amd64 receipts cover all three; native arm64 Docker is also validated. |
| Prepared dataset install | automatic read-write bind from `TAFFISH_NEXTCLADE_DATASET_INSTALL_ROOT` | same | same | Host directory must already exist and be writable; helper confirms an actual bind for `/dataset-install`. |
| Prepared dataset reuse | automatic read-only bind | automatic read-only bind | automatic read-only bind | Complete personal/site/override version root only. |
| Web service | loopback `-p` mapping | loopback `-p` mapping | shared host network, no `-p` | Foreground helper; no authentication/TLS; keep loopback-only and choose an unused site-allowed port. |

Final validation covers native amd64 Linux Docker, rootless Podman, and
Apptainer, plus native arm64 Docker, with both direct smoke and real generated
wrapper tests. Arm64 Podman/Apptainer were not separately validated; there is
no claim of an all-platform/backend Cartesian product. Podman requires a
working host-side init binary for `--init`; the validation host's maintainer
supplied catatonit before the final tests. No backend exception is used.

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
Nginx process is alive and its health endpoint answers. It supervises that
process continuously; a critical exit names the component, shows a log tail,
cleans up, and exits nonzero. Ctrl-C and TERM use bounded process-group cleanup
with statuses 130 and 143. During that cleanup, further INT/TERM/HUP signals are
ignored so they cannot interrupt the final process cleanup and stopped marker.
For a remote host, keep the published port on
127.0.0.1 and use the printed SSH tunnel. Apptainer shares the host network, so
the selected port must also satisfy site policy and firewall rules. Browser
uploads and displayed/exported results may reveal filenames, sequence or sample
identifiers, and analysis results; use a trusted browser session and never expose
this unauthenticated service beyond loopback.

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
checkout, current TAFFISH 0.11.0 `taf run` is not a safe long-service entry:
its generator path buffers the startup card, Ctrl-C exits through the
TAFFISH/SBCL interrupt handler instead of 130, and the attached container can
remain running. This is a TAFFISH core boundary, not a helper failure.

Build the generated wrapper and run that wrapper directly for unpublished
local testing:

```sh
taf build
TAFFISH_DOCKER_RUN_ARGS="-p 127.0.0.1:8765:8000" \
  TAFFISH_CONTAINER_BACKEND=docker \
  target/taf-nextclade-v3.23.0-r2 \
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
| `/dataset-install/3.23.0` | dataset helper | persistent | only an actual explicit writable host bind |
| requested CLI outputs/workdir | Nextclade CLI | persistent | caller's wrapper-bound working directory |
| image root (`/opt`, `/usr`, `/var/lib/nginx`) | nobody at runtime | immutable | no runtime chmod/chown or write dependency |

Network is required for `dataset list|get`, helper network installation,
`run --dataset-name`, parts of `sort`, and normal Web discovery. A run with
preserved local input and dataset is offline-safe. The manifest smoke does not
perform implicit network access.

Upstream maintains paired CLI tags (`3.23.0`) and Web tags (`web-3.23.0`) for
the same stable commit. The watch rule intentionally filters `web-*` and strips
that prefix before version comparison, preventing unrelated mixed-tag lines from
masking future stable updates while tracking the browser surface packaged here.

## Packaging, Provenance, and Size

The final image uses a digest-pinned Alpine base and upstream native musl
binaries. A thin packaged `nextclade` launcher performs full verification before
any automatically mounted dataset is consumed, including TAFFISH automatic
command mode, while preserving stdout for machine-readable upstream commands.
Web assets and CLI provenance are embedded; download tools, Web
archive, source maps, toolchains, caches, headers, and sysroots are absent from
the final filesystem. Bash, `jq`, Nginx, CA certificates, and small POSIX helpers
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

## Testing Boundary

The manifest smoke checks all packaged commands, exact identity/provenance, a
real explicit-reference analysis, schema generation, an offline exact-member
install, transaction rollback, traversal/integrity corruption rejection, Web
readiness, startup/ready signals, nonzero and zero-status critical-process
supervision, cleanup, and invalid arguments. Every manifest command must also
run in a fresh offline container with a read-only image root and only its
documented `/tmp` and workdir writes. Docker/Podman resource binds and a real
read-only SIF must be tested separately through generated wrappers.

The final `3.23.0-r2` runtime passed all 17 command-existence entries and 10
exact manifest tests independently in fresh offline Docker/Podman containers,
read-only Docker/Podman proxies, and an actual read-only amd64 SIF. Native
arm64 Docker passed its normal and read-only matrices too. Real generated
wrappers separately passed actual writable installation binds, read-only
reuse (including an attempted write rejected by the mounted filesystem),
integrity failures, argument ordering, whitespace log paths, and foreground
service lifecycle tests. These final receipts supersede the intermediate
argument workaround and invalid exit-127 read-only test; neither is reused.

The official Web client loaded a purely synthetic local fixture, completed
its tiny path, opened a language menu with a real pointer, and exported a
nonempty JSON result. Layout was visually checked at 1280x720 and 1440x900.
This is a direct browser app, not a noVNC desktop: window-manager, desktop
geometry and noVNC chrome checks are not applicable. Tree/peptide exports
requiring annotation or a tree were not qualified by this bare-reference
fixture; the upstream assets and commands remain packaged.

Resource transaction tests use a tiny prepared member, not a production
catalog download or a shared multi-user installation. Full production dataset
acquisition, selected-member terms, site permissions and scientific suitability
remain user/site responsibilities. The helper's network retry path does not
claim byte-range resume; preserved exact members can be reused offline.

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
