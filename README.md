# Nextclade

`nextclade` packages [Nextclade](https://github.com/nextstrain/nextclade) for
TAFFISH. It includes the upstream command-line program and the official
Nextclade Web client from the same upstream commit.

Package identity:

- name: `nextclade`
- command: `taf-nextclade`
- kind: `tool`
- version: `3.23.0-r1`
- TAFFISH app license: Apache-2.0
- upstream license: MIT
- platforms: native `linux/amd64` and `linux/arm64`
- upstream release: [3.23.0](https://github.com/nextstrain/nextclade/releases/tag/3.23.0)
- upstream commit: `629ea8fb0cfe3165db13ddc75dab16d3c2292dbd`

## What This App Packages

Nextclade analyzes viral genome sequences. The CLI exposes upstream alignment,
mutation calling, clade assignment, quality control, phylogenetic placement,
dataset discovery/download, pathogen sorting, annotation inspection, schema
generation, shell completions, and generated Markdown help.

The browser interface is the official static Nextclade Web build produced by
upstream workflow run
[`32247980559`](https://github.com/nextstrain/nextclade/actions/runs/32247980559)
for the pinned commit. The package serves those assets locally with Nginx.
Local packaging rewrites official-site asset URLs to the local service,
disables Plausible analytics, and removes source maps; it does not replace the
analysis code or UI with a third-party frontend.

## Scope

This app supports:

- `nextclade run` with a local dataset or explicit reference/annotation/tree
  inputs
- `nextclade dataset list|get`, including custom dataset servers
- `nextclade sort`, `read-annotation`, `schema write`, `completions`, and
  `help-markdown`
- the historical upstream `nextalign` executable name as a symlink to the
  current `nextclade` binary
- the official browser UI through the foreground `nextclade-web` helper

This app does not bundle pathogen datasets, sequence data, a Web browser,
authentication, or TLS. It does not freeze the continually updated “latest”
dataset selected by a network-backed command or by the Web dataset chooser.

## Container Contents

- `nextclade`: pinned upstream musl CLI binary
- `nextalign`: upstream-compatible symlink to `nextclade`
- `nextclade-web`: foreground local Web service helper
- `nginx`: static asset server used only by `nextclade-web`
- `nextclade-smoke`: packaging verification helper
- `/usr/share/nextclade-web`: pinned official Web assets
- `/usr/share/nextclade-taffish/cli-source.txt`: source and artifact provenance

The CLI is a self-contained Rust executable. Its FASTA and dataset compression
support is internal; no hidden host-side bioinformatics executables are used.
Nginx is required only for the optional Web interface.

## CLI Usage

Show upstream help and identity:

```sh
taf-nextclade -- --help
taf-nextclade -- --version
```

TAFFISH command mode treats a non-option first argument as an executable name.
Therefore use the explicit packaged executable before upstream subcommands:

```sh
taf-nextclade nextclade run --help
taf-nextclade nextclade dataset list
```

Do not write `taf-nextclade run ...`: that asks the container to execute a
program named `run`.

Current TAFFISH automatic command mode reconstructs a shell command line. If a
path contains whitespace, ordinary outer-shell quoting alone is insufficient;
include literal single quotes inside that argument. For example:

```sh
taf-nextclade nextclade schema write --for output-json \
  --output "'results/schema with spaces.json'"
```

The inner single quotes are intentional. Prefer whitespace-free paths when
possible.

### Reproducible dataset workflow

First inspect and download a named, version-tagged dataset while network access
is available:

```sh
taf-nextclade nextclade dataset list --name sars-cov-2
taf-nextclade nextclade dataset get \
  --name sars-cov-2 --tag DATASET_TAG --output-dir dataset
```

Record the chosen dataset tag and preserve the resulting directory or zip.
Then analyze FASTA input with the local copy:

```sh
taf-nextclade nextclade run \
  --input-dataset dataset \
  --output-all results \
  sequences.fasta
```

Using `run --dataset-name NAME` downloads the current default dataset on every
run. It is convenient but can change results over time, so it is not the
recommended reproducibility contract.

### Explicit-reference workflow

A dataset is not required when the reference is supplied directly:

```sh
taf-nextclade nextclade run \
  --input-ref reference.fasta \
  --input-annotation annotation.gff3 \
  --output-tsv results.tsv \
  sequences.fasta
```

`--input-annotation`, `--input-tree`, and `--input-pathogen-json` are optional
in this mode. Without annotation, amino-acid translation and amino-acid
mutation reporting are unavailable. Without a pathogen configuration or tree,
dataset-specific clades, QC rules, and phylogenetic placement may be absent.

## Browser Interface

No analysis file is required merely to open and inspect the UI. With Docker:

```sh
TAFFISH_DOCKER_RUN_ARGS="-p 127.0.0.1:8765:8000" \
  TAFFISH_CONTAINER_BACKEND=docker \
  taf-nextclade nextclade-web --port 8000 --host-port 8765
```

With Podman, use the equivalent loopback mapping through the Podman runtime
arguments. Open `http://127.0.0.1:8765/` after the helper prints
`Nextclade Web is ready.` The helper prints the URL, SSH tunnel example,
Ctrl-C instruction, and internal log path before startup can block. Ctrl-C
stops the service and its child processes.

Apptainer/Singularity normally shares the host network, so no `-p` mapping is
used. The helper detects that backend and defaults to a loopback-only bind:

```sh
TAFFISH_CONTAINER_BACKEND=apptainer \
  taf-nextclade nextclade-web --port 8765 --host-port 8765
```

For a remote Docker/Podman host, keep the published port on loopback and create
the printed SSH tunnel before opening the local URL. The helper provides no
authentication or TLS and should not be exposed directly to an untrusted
network.

The Web client normally contacts the official Nextclade data server to list
and download datasets. Computation occurs in the browser. For offline use,
load sequence files and a previously preserved local Nextclade dataset through
the UI; discovery and downloading cannot work without network access.

### Local source-checkout service testing

Installed users should use the `taf-nextclade` examples above. For an
unpublished source checkout, do not use `taf run ... nextclade-web` with the
current local TAFFISH 0.11.0: its long-running `taf run` path buffers the
startup card, Ctrl-C exits through the TAFFISH/SBCL interrupt handler instead
of returning 130, and the container can remain running. This is a TAFFISH core
service-forwarding boundary rather than a `nextclade-web` helper failure.

Build the local image and generated wrapper, then test the wrapper directly:

```sh
taf build --image
taf build

TAFFISH_DOCKER_RUN_ARGS="-p 127.0.0.1:8765:8000" \
  TAFFISH_CONTAINER_BACKEND=docker \
  target/taf-nextclade-v3.23.0-r1 \
  nextclade-web --port 8000 --host-port 8765
```

This checkout-only procedure is intentionally absent from `docs/help.md`,
which documents the already installed wrapper.

## Inputs and Outputs

CLI inputs include FASTA (`.gz`, `.bz2`, `.xz`, and `.zst` are supported), a
dataset directory/zip, reference FASTA, optional GFF3 annotation, optional
Auspice tree JSON, and optional pathogen JSON. See `nextclade run --help` for
the complete contract.

Outputs can include aligned FASTA, CSV/TSV, JSON/NDJSON, translations, GFF/TBL
annotation, and Auspice/Newick trees. `--output-all DIR` creates the standard
set; individual `--output-*` flags select exact files. Nextclade may create
parent directories for requested outputs. Treat output schemas and biological
interpretation as upstream contracts tied to the pinned program and dataset.

## Resources, Network, and Platform

Both declared platforms use upstream native musl binaries. The Web client is
architecture-independent static content. CPU time and memory grow with input
sequence count/length and with the selected pathogen dataset; the browser adds
its own memory use outside the container.

Network access is required for `dataset list`, `dataset get`,
`run --dataset-name`, `sort` when it retrieves indexes, and normal Web dataset
discovery/download. A run using preserved local inputs can be performed
offline. Proxy options belong to the upstream CLI and are shown in its help.

## Packaging and Size

The final image starts from a digest-pinned Alpine base and installs only CA
certificates and Nginx around the upstream CLI and Web assets. Download tools,
the vendored compressed Web archive, and Web source maps are absent from the
final filesystem. Per-architecture asset SHA256 values, upstream documentation
checksums, the Web artifact digest, and source provenance are recorded in the
image.

The final local images measure 45,495,603 bytes on amd64 and 42,607,581 bytes
on arm64. Their dominant required payloads are the native CLI (14.6 MB amd64 or
about 11.3 MB arm64), 20.1 MB of Web assets, the Alpine base, and Nginx. Layer
and filesystem inspection found no retained downloader, source archive, build
toolchain, cache, source map, header, or sysroot with significant safe removal
potential.

## Troubleshooting

- `executable file not found ... run`: use `taf-nextclade nextclade run ...`.
- dataset commands fail offline: download and preserve a version-tagged dataset
  while online, then pass it with `--input-dataset`.
- Web UI opens but has no dataset list: allow access to the official dataset
  server or load a preserved local dataset.
- browser cannot connect: confirm the helper says ready, the container port is
  mapped to the printed host port, and the mapping is on `127.0.0.1`.
- port already in use: choose matching free values for the runtime mapping,
  `--port`, and `--host-port`.
- missing amino-acid or clade results: supply the appropriate annotation and
  pathogen dataset/configuration; a bare reference has a narrower result set.

## Testing Boundaries

The package smoke gates independently verify identity and provenance, public
CLI help surfaces, a real local-reference analysis, schema generation, local
Web serving, startup output order, startup-time Ctrl-C, ready-time TERM, and
invalid-argument behavior. The generated wrapper is separately checked with a
literal-quoted whitespace-bearing path. Every index smoke command is designed
for a fresh network-disabled container. Browser interaction is also checked separately;
automated smoke is not a substitute for scientific validation on production
sequences and an appropriate frozen pathogen dataset.

## License and Citation

TAFFISH app packaging is Apache-2.0. Nextclade and the packaged upstream Web
assets retain the upstream MIT license, included in the image.

Upstream requests citation of:

> Aksamentov I, Roemer C, Hodcroft EB, Neher RA. Nextclade: clade assignment,
> mutation calling and quality control for viral genomes. Journal of Open
> Source Software. 2021;6(67):3773.

DOI: [10.21105/joss.03773](https://doi.org/10.21105/joss.03773).

Detailed upstream documentation:
[Nextclade documentation](https://docs.nextstrain.org/projects/nextclade/en/stable/).
