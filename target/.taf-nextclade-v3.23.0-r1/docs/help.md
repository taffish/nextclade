nextclade 3.23.0-r1

Purpose:
  Analyze viral genomes with Nextclade alignment, mutation calling, clade
  assignment, quality control, phylogenetic placement, or the official Web UI.

Upstream help and identity:
  taf-nextclade -- --help
  taf-nextclade -- --version
  taf-nextclade nextclade run --help
  taf-nextclade nextclade dataset --help

Important command-mode rule:
  Put "nextclade" before an upstream subcommand. For example, use
  "taf-nextclade nextclade run ...", not "taf-nextclade run ...".
  For a spaced path, include literal single quotes inside the shell argument:
    --output "'results/schema with spaces.json'"
  The inner quotes are intentional; prefer paths without whitespace.

Reproducible CLI workflow:
  1. List datasets while online:
     taf-nextclade nextclade dataset list --name sars-cov-2
  2. Download and preserve an exact dataset tag:
     taf-nextclade nextclade dataset get --name sars-cov-2 \
       --tag DATASET_TAG --output-dir dataset
  3. Analyze local FASTA input with that preserved dataset:
     taf-nextclade nextclade run --input-dataset dataset \
       --output-all results sequences.fasta

Explicit-reference workflow:
  taf-nextclade nextclade run --input-ref reference.fasta \
    --input-annotation annotation.gff3 --output-tsv results.tsv \
    sequences.fasta

Browser interface with Docker:
  TAFFISH_DOCKER_RUN_ARGS="-p 127.0.0.1:8765:8000" \
    TAFFISH_CONTAINER_BACKEND=docker \
    taf-nextclade nextclade-web --port 8000 --host-port 8765

  Wait for "Nextclade Web is ready", then open:
    http://127.0.0.1:8765/
  No input file is needed just to inspect the UI. Press Ctrl-C to stop it.

Remote server:
  Keep the mapped port on 127.0.0.1 and use the SSH tunnel printed by the
  helper. The service has no authentication or TLS.

Apptainer/Singularity:
  These backends normally share the host network. Do not use a Docker -p
  mapping; use the same free value for --port and --host-port. The helper
  defaults to a loopback-only bind under these backends.

Packaged commands:
  nextclade        Main upstream CLI.
  nextalign        Compatibility name for the same CLI binary.
  nextclade-web    Foreground service for the official Web client.

Inputs:
  FASTA input; local dataset directory or zip; or an explicit reference FASTA.
  Optional inputs include GFF3 annotation, Auspice tree JSON, and pathogen JSON.
  FASTA and dataset inputs may use gzip, bzip2, xz, or zstd compression.

Key outputs:
  Aligned FASTA; CSV/TSV; JSON/NDJSON; translations; GFF/TBL annotation;
  and Auspice or Newick trees. --output-all writes the standard output set.

Network and reproducibility boundaries:
  dataset list/get, run --dataset-name, parts of sort, and normal Web dataset
  discovery need network access. "Latest" datasets can change over time.
  Preserve a named dataset tag and use --input-dataset for reproducible runs.
  Local-input CLI analysis can run offline. Web computation occurs locally,
  but offline Web use requires sequence files and a preserved local dataset.

Scientific boundaries:
  A bare reference permits alignment and nucleotide comparison but may omit
  annotation-derived amino-acid results, pathogen QC, clades, and placement.
  Use a suitable frozen dataset and validate real scientific outputs yourself.

Detailed documentation:
  https://github.com/taffish/nextclade
  https://docs.nextstrain.org/projects/nextclade/en/stable/

Wrapper options:
  taf-nextclade --help       Show this TAFFISH help.
  taf-nextclade --version    Show the TAFFISH wrapper version.
  taf-nextclade --compile    Print generated wrapper code.
  taf-nextclade -- --help    Pass option-leading input to default nextclade.
