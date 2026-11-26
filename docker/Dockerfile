# The base digest does not freeze the live Alpine package repository below.
# Packages can change or disappear. Reassess upstream availability for a successor
# release on failure; never disable verification or overwrite a published identity.
ARG ALPINE_IMAGE=alpine:3.22.5@sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

FROM ${ALPINE_IMAGE} AS cli-fetch

ARG TARGETARCH
ARG NEXTCLADE_VERSION=3.30.0
ARG NEXTCLADE_COMMIT=cbd10dcd913b930de1af452f434de4d58753f73f
ARG NEXTCLADE_AMD64_SHA256=e66a76a5650ee6498080e715eaa247e9f0992ac4a27d220e61a0c23e5c9ebff0
ARG NEXTCLADE_ARM64_SHA256=f09dc4a9eac8845844d25a885aaa4e2b1f11adff1e7cb129cc23562301033b9a
ARG NEXTCLADE_LICENSE_SHA256=7840a71ecf07a2d68ddae05e3a0dfd1bd4770ffca08f4bd204dc341e40bb6261
ARG NEXTCLADE_README_SHA256=fed0045e15945b056bc0cb004685e743d677ce9409212a788e3b31355c1818d9

# Official release assets and commit-pinned text have full SHA256 checks.
# Fixed URLs do not guarantee retention; investigate 404s or mismatches rather
# than blindly accepting a replacement digest.
RUN set -eux; \
    apk add --no-cache ca-certificates curl file; \
    case "${TARGETARCH}" in \
      amd64) asset="nextclade-x86_64-unknown-linux-musl"; asset_sha="${NEXTCLADE_AMD64_SHA256}" ;; \
      arm64) asset="nextclade-aarch64-unknown-linux-musl"; asset_sha="${NEXTCLADE_ARM64_SHA256}" ;; \
      *) echo "unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    asset_url="https://github.com/nextstrain/nextclade/releases/download/${NEXTCLADE_VERSION}/${asset}"; \
    curl --http1.1 -fSL --retry 5 --retry-delay 5 --retry-all-errors \
      -o /usr/local/bin/nextclade "${asset_url}"; \
    echo "${asset_sha}  /usr/local/bin/nextclade" | sha256sum -c -; \
    chmod 0755 /usr/local/bin/nextclade; \
    file /usr/local/bin/nextclade | grep -F 'ELF' >/dev/null; \
    mkdir -p /usr/share/doc/nextclade-upstream; \
    curl --http1.1 -fSL --retry 5 --retry-delay 5 --retry-all-errors \
      -o /usr/share/doc/nextclade-upstream/LICENSE \
      "https://raw.githubusercontent.com/nextstrain/nextclade/${NEXTCLADE_COMMIT}/LICENSE"; \
    curl --http1.1 -fSL --retry 5 --retry-delay 5 --retry-all-errors \
      -o /usr/share/doc/nextclade-upstream/README.md \
      "https://raw.githubusercontent.com/nextstrain/nextclade/${NEXTCLADE_COMMIT}/README.md"; \
    echo "${NEXTCLADE_LICENSE_SHA256}  /usr/share/doc/nextclade-upstream/LICENSE" | sha256sum -c -; \
    echo "${NEXTCLADE_README_SHA256}  /usr/share/doc/nextclade-upstream/README.md" | sha256sum -c -; \
    printf '%s\n' \
      "upstream_repo=https://github.com/nextstrain/nextclade" \
      "upstream_tag=${NEXTCLADE_VERSION}" \
      "upstream_commit=${NEXTCLADE_COMMIT}" \
      "cli_asset=${asset_url}" \
      "cli_asset_sha256=${asset_sha}" \
      "architecture=${TARGETARCH}" \
      > /tmp/cli-source.txt

FROM ${ALPINE_IMAGE} AS web-assets

ARG NEXTCLADE_VERSION=3.30.0
ARG NEXTCLADE_COMMIT=cbd10dcd913b930de1af452f434de4d58753f73f
ARG NEXTCLADE_WEB_SHA256=eb0d10d59cf355617985ab0a3794b2b53499b14f0a8982d46e93e6f7bb2208cf

# Official Web Actions artifacts expire, so preserve the verified out payload
# in this release. Provenance distinguishes the official ZIP from this tar.
COPY docker/nextclade-web-3.30.0.tar.gz /tmp/nextclade-web.tar.gz

RUN set -eux; \
    echo "${NEXTCLADE_WEB_SHA256}  /tmp/nextclade-web.tar.gz" | sha256sum -c -; \
    mkdir -p /usr/share/nextclade-web; \
    tar -xzf /tmp/nextclade-web.tar.gz -C /usr/share/nextclade-web; \
    grep -F '"version": "'"${NEXTCLADE_VERSION}"'"' /usr/share/nextclade-web/app.json >/dev/null; \
    grep -F '"commitHash": "'"${NEXTCLADE_COMMIT}"'"' /usr/share/nextclade-web/app.json >/dev/null; \
    find /usr/share/nextclade-web -type f -name '*.html' \
      -exec sed -i 's#https://clades.nextstrain.org/#/#g' {} +; \
    telemetry_pattern='function u({domain:e,plausibleDomain:t="https://plausible.io"}){'; \
    telemetry_files="$(find /usr/share/nextclade-web -type f -name '*.js' -exec grep -lF "${telemetry_pattern}" {} +)"; \
    set -- ${telemetry_files}; \
    test "$#" -eq 1; \
    sed -i 's#function u({domain:e,plausibleDomain:t="https://plausible.io"}){#function u(){return null}function u_disabled({domain:e,plausibleDomain:t="https://plausible.io"}){#' "$1"; \
    grep -F 'function u(){return null}function u_disabled' "$1" >/dev/null; \
    find /usr/share/nextclade-web -type f -name '*.map' -delete; \
    test -s /usr/share/nextclade-web/index.html; \
    rm -f /tmp/nextclade-web.tar.gz

FROM ${ALPINE_IMAGE}

ARG NEXTCLADE_VERSION=3.30.0
ARG NEXTCLADE_COMMIT=cbd10dcd913b930de1af452f434de4d58753f73f
ARG NEXTCLADE_SOURCE_SHA256=7d812c01bd67571a93c94d1664b5abaccc5130b4d54d1674bf9eb41ccc1bff3c
ARG NEXTCLADE_WEB_SHA256=eb0d10d59cf355617985ab0a3794b2b53499b14f0a8982d46e93e6f7bb2208cf

LABEL org.opencontainers.image.title="Nextclade" \
      org.opencontainers.image.description="Nextclade CLI and official Nextclade Web client" \
      org.opencontainers.image.source="https://github.com/nextstrain/nextclade" \
      org.opencontainers.image.version="3.30.0" \
      org.opencontainers.image.revision="cbd10dcd913b930de1af452f434de4d58753f73f" \
      org.opencontainers.image.licenses="MIT"

# Runtime apk packages still resolve from live v3.22 repositories. The package
# inventory records this build, not a permanent package-repository snapshot.
RUN set -eux; \
    apk add --no-cache bash ca-certificates jq nginx; \
    mkdir -p /usr/local/libexec /usr/share/nextclade-taffish; \
    apk info -vv > /usr/share/nextclade-taffish/alpine-packages.txt

COPY --from=cli-fetch /usr/local/bin/nextclade /usr/local/libexec/nextclade
COPY --from=cli-fetch /usr/share/doc/nextclade-upstream /usr/share/doc/nextclade-upstream
COPY --from=cli-fetch /tmp/cli-source.txt /usr/share/nextclade-taffish/cli-source.txt
COPY --from=web-assets /usr/share/nextclade-web /usr/share/nextclade-web
COPY docker/nextclade-launcher /usr/local/bin/nextclade
COPY docker/nextclade-web /usr/local/bin/nextclade-web
COPY docker/nextclade-datasets /usr/local/bin/nextclade-datasets
COPY docker/nextclade-smoke /usr/local/bin/nextclade-smoke
COPY docker/fixtures /usr/share/nextclade-taffish/fixtures

RUN set -eux; set -o pipefail; \
    chmod 0755 /usr/local/bin/nextclade /usr/local/bin/nextclade-web /usr/local/bin/nextclade-datasets /usr/local/bin/nextclade-smoke; \
    ln -s nextclade /usr/local/bin/nextalign; \
    printf '%s\n' \
      "source_archive=https://github.com/nextstrain/nextclade/archive/refs/tags/${NEXTCLADE_VERSION}.tar.gz" \
      "source_archive_sha256=${NEXTCLADE_SOURCE_SHA256}" \
      "web_artifact_workflow_run=https://github.com/nextstrain/nextclade/actions/runs/45417989354" \
      "web_artifact_id=14933762687" \
      "web_artifact_name=out" \
      "web_artifact_github_digest=sha256:06ab897cf4ae65863ab901e74d0c0489ac993fb5a0b1695c53674577711dd30c" \
      "web_archive_sha256=${NEXTCLADE_WEB_SHA256}" \
      "web_local_adjustments=local asset URLs; Plausible telemetry disabled; source maps removed" \
      >> /usr/share/nextclade-taffish/cli-source.txt; \
    nextclade --version | grep -Fx "nextclade ${NEXTCLADE_VERSION}" >/dev/null; \
    nextclade-datasets --version | grep -Fx 'nextclade-datasets 3.30.0-r1' >/dev/null; \
    grep -F '"commitHash": "'"${NEXTCLADE_COMMIT}"'"' /usr/share/nextclade-web/app.json >/dev/null

ENV TAFFISH_ENV=TAFFISH \
    TAFFISH_NAME=nextclade \
    TAFFISH_VERSION=3.30.0 TAFFISH_RELEASE=1

WORKDIR /root

CMD ["nextclade", "--help"]
