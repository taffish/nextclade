# 来源边界：digest 固定基础镜像，不冻结下方 Alpine 在线包仓库。
# apk 包可滚动更新或撤下；若未来构建失败，应重新核验仓库与依赖后发后继 release，
# 不关闭 TLS/校验、不覆盖已发布身份，也不承诺上游永远保留下载对象。
ARG ALPINE_IMAGE=alpine:3.22.5@sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

FROM ${ALPINE_IMAGE} AS cli-fetch

ARG TARGETARCH
ARG NEXTCLADE_VERSION=3.25.0
ARG NEXTCLADE_COMMIT=d415f3c396fabc7f792c676d60ac9b50236830c1
ARG NEXTCLADE_AMD64_SHA256=cf8efa780adfef3ffc995ad5a30ea6dce3eb876a04f3ce1b5a3e41daf8b0e698
ARG NEXTCLADE_ARM64_SHA256=27128659c9ffaeac46e4659c68c0f823132c94863561abc2c8bd3a995225535f
ARG NEXTCLADE_LICENSE_SHA256=7840a71ecf07a2d68ddae05e3a0dfd1bd4770ffca08f4bd204dc341e40bb6261
ARG NEXTCLADE_README_SHA256=fed0045e15945b056bc0cb004685e743d677ce9409212a788e3b31355c1818d9

# 官方 release 资产及固定 commit 文本均校验完整 SHA256；固定 URL 并不保证保留期。
# 404 或摘要不一致须先核对 upstream，不可仅刷新 checksum 让构建通过。
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

ARG NEXTCLADE_VERSION=3.25.0
ARG NEXTCLADE_COMMIT=d415f3c396fabc7f792c676d60ac9b50236830c1
ARG NEXTCLADE_WEB_SHA256=56e17d3ad7613d5683a570ab7d0edbc5e3498dca75f5448306c5ab9708a5dc5f

# 官方 Web Actions artifact 有保留期限，故将已核验的 out 内容随本 release 保存。
# 下方 provenance 同时记录官方 ZIP digest 与仓库内重打包 tar digest；两者不是同一对象。
COPY docker/nextclade-web-3.25.0.tar.gz /tmp/nextclade-web.tar.gz

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
    test -s /usr/share/nextclade-web/_next/static/chunks/pages/_app-f5edbc42da022c40.js; \
    rm -f /tmp/nextclade-web.tar.gz

FROM ${ALPINE_IMAGE}

ARG NEXTCLADE_VERSION=3.25.0
ARG NEXTCLADE_COMMIT=d415f3c396fabc7f792c676d60ac9b50236830c1
ARG NEXTCLADE_SOURCE_SHA256=413061b849cbb39c9dc9791c8bc6f68a278448e10f48d3adeaa06874bc4d2edd
ARG NEXTCLADE_WEB_SHA256=56e17d3ad7613d5683a570ab7d0edbc5e3498dca75f5448306c5ab9708a5dc5f

LABEL org.opencontainers.image.title="Nextclade" \
      org.opencontainers.image.description="Nextclade CLI and official Nextclade Web client" \
      org.opencontainers.image.source="https://github.com/nextstrain/nextclade" \
      org.opencontainers.image.version="3.25.0" \
      org.opencontainers.image.revision="d415f3c396fabc7f792c676d60ac9b50236830c1" \
      org.opencontainers.image.licenses="MIT"

# 运行期 apk 仍来自在线 v3.22 仓库；alpine-packages.txt 是本次解析记录，不是永久锁仓。
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
      "web_artifact_workflow_run=https://github.com/nextstrain/nextclade/actions/runs/38405743562" \
      "web_artifact_id=11818424076" \
      "web_artifact_name=out" \
      "web_artifact_github_digest=sha256:86f2437bf6ec9a0139206e1e69d17e18cfe178ac2c545b61f1f04424d8862b67" \
      "web_archive_sha256=${NEXTCLADE_WEB_SHA256}" \
      "web_local_adjustments=local asset URLs; Plausible telemetry disabled; source maps removed" \
      >> /usr/share/nextclade-taffish/cli-source.txt; \
    nextclade --version | grep -F "nextclade ${NEXTCLADE_VERSION}" >/dev/null; \
    nextclade --help | grep -F 'Run sequence analysis' >/dev/null; \
    nextclade-web --help | grep -F 'foreground browser service' >/dev/null; \
    nextclade-datasets --help | grep -F 'version-pinned Nextclade datasets' >/dev/null; \
    nextclade-datasets --version | grep -Fx 'nextclade-datasets 3.25.0-r1' >/dev/null; \
    grep -F '"commitHash": "'"${NEXTCLADE_COMMIT}"'"' /usr/share/nextclade-web/app.json >/dev/null

ENV TAFFISH_ENV=TAFFISH \
    TAFFISH_NAME=nextclade

WORKDIR /root

CMD ["nextclade", "--help"]
