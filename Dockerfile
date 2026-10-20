# Source build: pinned official toolchain, unchanged Cargo.lock, one Cargo job.
# Rust's Alpine image includes GCC, musl headers, binutils and CA certificates.
FROM rust:1.99.1-alpine3.22@sha256:2b3b5cdd9112f19366d21b94541ffcd3d58bf838f696451a0d50c8032088cb15 AS build
WORKDIR /src
ENV CARGO_BUILD_JOBS=1 \
    CARGO_INCREMENTAL=0 \
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1 \
    LZMA_API_STATIC=1 \
    AWS_LC_SYS_CMAKE_BUILDER=0

# Includes both workspace crates, embedded static assets, tests and MIT license.
COPY Cargo.toml Cargo.lock LICENSE README.md ./
COPY bloglite ./bloglite
COPY bloglite-auth ./bloglite-auth
RUN cargo fetch --locked
RUN set -eu; \
    case "$(uname -m)" in \
      x86_64) target=x86_64-unknown-linux-musl ;; \
      aarch64) target=aarch64-unknown-linux-musl ;; \
      *) echo "Only native linux/amd64 and linux/arm64 builds are supported" >&2; exit 1 ;; \
    esac; \
    cargo build --frozen --release --jobs 1 --package bloglite --target "$target"; \
    cp "target/$target/release/bloglite" /bloglite; \
    readelf --program-headers /bloglite > /program-headers.txt; \
    readelf --dynamic /bloglite > /dynamic.txt; \
    if grep -q INTERP /program-headers.txt || grep -q '(NEEDED)' /dynamic.txt; then \
      echo "Runtime requires a statically linked executable" >&2; exit 1; \
    fi; \
    mkdir -p /runtime-data

FROM scratch
LABEL org.opencontainers.image.source="https://github.com/NikitaBabenko/bloglite" \
      org.opencontainers.image.licenses="MIT"
COPY --from=build /bloglite /bloglite
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /src/LICENSE /LICENSE
COPY --from=build /runtime-data /data
ENV BLOGLITE_PRODUCTION=true \
    BLOGLITE_PORT=3000 \
    BLOGLITE_DATABASE_PATH=/data/db.sqlite \
    TOKIO_WORKER_THREADS=1
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD ["/bloglite", "check-health"]
CMD ["/bloglite", "serve"]
