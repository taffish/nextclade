nextclade 3.24.0-r1
Purpose:
  Use the primary headless CLI for viral-genome analysis, or start the optional
  official Web client as a foreground static browser service.

Usage:
  taf-nextclade -- --help
  taf-nextclade nextclade run --help
  taf-nextclade nextclade dataset --help

Common tasks:
  Analyze with a preserved dataset:
    taf-nextclade nextclade run --input-dataset dataset \
      --output-all results sequences.fasta
  Analyze with explicit references:
    taf-nextclade nextclade run --input-ref reference.fasta \
      --input-annotation annotation.gff3 --output-tsv results.tsv sequences.fasta

Prepare one exact reusable dataset member:
  base=${XDG_DATA_HOME:-$HOME/.local/share}/taffish/datasets/nextclade
  mkdir -p "$base"
  TAFFISH_NEXTCLADE_DATASET_INSTALL_ROOT="$base" \
    taf-nextclade nextclade-datasets install --name DATASET_ID --tag DATASET_TAG
  taf-nextclade nextclade-datasets list-installed
  taf-nextclade nextclade-datasets path --name DATASET_ID --tag DATASET_TAG

  Select an exact ID/tag; the helper does not download the whole family.
  Use --dry-run first. Upstream size/checksum/license are not uniformly supplied:
  leave enough space and review dataset terms before installation or sharing.
  Installation needs network; later verify/path/analysis can be offline.

Use a prepared dataset root:
  root=/absolute/root/3.24.0
  target=/opt/taffish/datasets/nextclade
  Read-only roots: use paths without whitespace, commas, colons or glob characters.
    TAFFISH_NEXTCLADE_DATASET_PATH="$root" TAFFISH_CONTAINER_BACKEND=BACKEND \
      taf-nextclade nextclade-datasets verify
  Manual fallback disables discovery and preserves the integrity marker:
    marker=TAFFISH_NEXTCLADE_DATASET_MOUNTED=1
    TAFFISH_NEXTCLADE_DATASET_AUTO_MOUNT=0 \
      TAFFISH_DOCKER_RUN_ARGS="-v $root:$target:ro -e $marker" \
      TAFFISH_CONTAINER_BACKEND=docker taf-nextclade nextclade-datasets verify
    TAFFISH_NEXTCLADE_DATASET_AUTO_MOUNT=0 \
      TAFFISH_PODMAN_RUN_ARGS="-v $root:$target:ro -e $marker" \
      TAFFISH_CONTAINER_BACKEND=podman taf-nextclade nextclade-datasets verify
    TAFFISH_NEXTCLADE_DATASET_AUTO_MOUNT=0 \
      TAFFISH_APPTAINER_RUN_ARGS="--bind $root:$target:ro --env $marker" \
      TAFFISH_CONTAINER_BACKEND=apptainer taf-nextclade nextclade-datasets verify
  After verify, rerun the same assignments with nextclade run and the member
  path printed by nextclade-datasets path as --input-dataset.
Browser service by backend:
  Docker:
    TAFFISH_DOCKER_RUN_ARGS="-p 127.0.0.1:8765:8000" \
      TAFFISH_CONTAINER_BACKEND=docker taf-nextclade \
      nextclade-web --port 8000 --host-port 8765
  Podman:
    TAFFISH_PODMAN_RUN_ARGS="-p 127.0.0.1:8765:8000" \
      TAFFISH_CONTAINER_BACKEND=podman taf-nextclade \
      nextclade-web --port 8000 --host-port 8765
  Apptainer (shared host network; no -p):
    TAFFISH_CONTAINER_BACKEND=apptainer taf-nextclade \
      nextclade-web --port 8765 --host-port 8765

  Wait for "Nextclade Web is ready", then open http://127.0.0.1:8765/.
  On a remote host use the printed SSH tunnel. Press Ctrl-C to stop. The helper
  has no authentication or TLS; keep it on loopback. Normal Web dataset discovery
  needs network; offline use requires sequence files and a preserved dataset.
  With Apptainer, choose an unused host port allowed by site/firewall policy.
  The browser may expose filenames, sequence identifiers, and results; use a
  trusted browser session and do not publish the service beyond loopback.
  Optional persistent HTTP log, before any backend command above:
    export TAFFISH_NEXTCLADE_WEB_LOG_FILE="$PWD/web session.log"

Immediate notes:
  TAFFISH command mode treats the first non-option argument as an executable.
  Use "taf-nextclade nextclade run ...", not "taf-nextclade run ...".
  For CLI paths with spaces, preserve literal quotes, e.g. '"input file.fasta"'.
  Latest/network-selected datasets can change. Record an exact tag and use
  --input-dataset for reproducible work.
  Patterns need pathogen.json + tree; Web markers: choose Relative to Parent.

Key outputs:
  --output-all writes aligned FASTA, CSV/TSV, JSON, translations and tree files.
  Individual --output-* options select exact files; see upstream run help.

Wrapper options:
  taf-nextclade --help       Show this TAFFISH help.
  taf-nextclade --version    Show TAFFISH wrapper version.
  taf-nextclade --compile    Print the generated wrapper shell.
  taf-nextclade -- --help    Pass option-leading input to default nextclade.
