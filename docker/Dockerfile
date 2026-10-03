ARG ALPINE_IMAGE=alpine:3.22.5@sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

FROM ${ALPINE_IMAGE} AS cli-fetch

ARG TARGETARCH
ARG NEXTCLADE_VERSION=3.24.0
ARG NEXTCLADE_COMMIT=529db53e8f5b16d8a5d1161abd8b60ef04109817
ARG NEXTCLADE_AMD64_SHA256=df74c89053fd9d5f914f0d26a006d13191dc13f66f61c4fd0dcae001278cb4a7
ARG NEXTCLADE_ARM64_SHA256=c3f3c9ca5f6b61c1485f69abce095548bdbe36723f69288397935cdcc42c66ad
ARG NEXTCLADE_LICENSE_SHA256=7840a71ecf07a2d68ddae05e3a0dfd1bd4770ffca08f4bd204dc341e40bb6261
ARG NEXTCLADE_README_SHA256=3b19595f1e2b2fcb183eb3ce05aeb30b7e1a3f5b9513cb031be51fb4f59fb816

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

ARG NEXTCLADE_VERSION=3.24.0
ARG NEXTCLADE_COMMIT=529db53e8f5b16d8a5d1161abd8b60ef04109817
ARG NEXTCLADE_WEB_SHA256=e321818a3bdd38412a3bf62faf429ddd7124b077c752d18a9e844c6a6f70298b

COPY docker/nextclade-web-3.24.0.tar.gz /tmp/nextclade-web.tar.gz

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
    test -s /usr/share/nextclade-web/_next/static/chunks/pages/_app-963ff874e3b68999.js; \
    rm -f /tmp/nextclade-web.tar.gz

FROM ${ALPINE_IMAGE}

ARG NEXTCLADE_VERSION=3.24.0
ARG NEXTCLADE_COMMIT=529db53e8f5b16d8a5d1161abd8b60ef04109817
ARG NEXTCLADE_SOURCE_SHA256=6c6e9e7daf18fe655a227830483e62a806df2a506a01406eb49acecba00a940f
ARG NEXTCLADE_WEB_SHA256=e321818a3bdd38412a3bf62faf429ddd7124b077c752d18a9e844c6a6f70298b

LABEL org.opencontainers.image.title="Nextclade" \
      org.opencontainers.image.description="Nextclade CLI and official Nextclade Web client" \
      org.opencontainers.image.source="https://github.com/nextstrain/nextclade" \
      org.opencontainers.image.version="3.24.0" \
      org.opencontainers.image.revision="529db53e8f5b16d8a5d1161abd8b60ef04109817" \
      org.opencontainers.image.licenses="MIT"

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

RUN set -eux; \
    chmod 0755 /usr/local/bin/nextclade /usr/local/bin/nextclade-web /usr/local/bin/nextclade-datasets /usr/local/bin/nextclade-smoke; \
    ln -s nextclade /usr/local/bin/nextalign; \
    printf '%s\n' \
      "source_archive=https://github.com/nextstrain/nextclade/archive/refs/tags/${NEXTCLADE_VERSION}.tar.gz" \
      "source_archive_sha256=${NEXTCLADE_SOURCE_SHA256}" \
      "web_artifact_workflow_run=https://github.com/nextstrain/nextclade/actions/runs/36701820873" \
      "web_artifact_id=11090603375" \
      "web_artifact_name=out" \
      "web_artifact_github_digest=sha256:a315fba46857b6163152430c73d5cc61e74f8e1d44b5a7e0696f82e6fe231ba4" \
      "web_archive_sha256=${NEXTCLADE_WEB_SHA256}" \
      "web_local_adjustments=local asset URLs; Plausible telemetry disabled; source maps removed" \
      >> /usr/share/nextclade-taffish/cli-source.txt; \
    nextclade --version | grep -F "nextclade ${NEXTCLADE_VERSION}" >/dev/null; \
    nextclade --help | grep -F 'Run sequence analysis' >/dev/null; \
    nextclade-web --help | grep -F 'foreground browser service' >/dev/null; \
    nextclade-datasets --help | grep -F 'version-pinned Nextclade datasets' >/dev/null; \
    nextclade-datasets --version | grep -Fx 'nextclade-datasets 3.24.0-r1' >/dev/null; \
    grep -F '"commitHash": "'"${NEXTCLADE_COMMIT}"'"' /usr/share/nextclade-web/app.json >/dev/null

ENV TAFFISH_ENV=TAFFISH \
    TAFFISH_NAME=nextclade

WORKDIR /root

CMD ["nextclade", "--help"]
