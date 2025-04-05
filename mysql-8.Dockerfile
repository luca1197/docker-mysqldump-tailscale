ARG DEBIAN_FRONTEND=noninteractive
FROM debian:bookworm-slim

# URL to Percona Server tarball
ARG PERCONA_SERVER_URL="https://downloads.percona.com/downloads/Percona-Server-8.0/Percona-Server-8.0.41-32/binary/tarball/Percona-Server-8.0.41-32-Linux.x86_64.glibc2.35-minimal.tar.gz"
###

# Install base packages
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends netcat-openbsd curl tar ca-certificates; \
    rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN set -eux; \
    mkdir -p --mode=0755 /usr/share/keyrings; \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null; \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends tailscale; \
    rm -rf /var/lib/apt/lists/*

# Install mysqldump from Percona Server package
RUN set -eux; \
    # Vars
    PERCONA_SERVER_TGZ="percona-server.tar.gz"; \
    EXTRACT_DIR="percona-server-extract"; \
    \
    # Download Percona Server
    echo "Downloading Percona Server from ${PERCONA_SERVER_URL}"; \
    curl -fsSL -o "${PERCONA_SERVER_TGZ}" "${PERCONA_SERVER_URL}"; \
    \
    # Extract Percona Server
    mkdir "${EXTRACT_DIR}"; \
    tar -xzf "${PERCONA_SERVER_TGZ}" -C "${EXTRACT_DIR}" --strip-components=1; \
    # Copy mysqldump to /usr/bin
    cp "${EXTRACT_DIR}/bin/mysqldump" /usr/bin/mysqldump; \
    chmod +x /usr/bin/mysqldump; \
    # Cleanup download
    rm -rf "${PERCONA_SERVER_TGZ}" "${EXTRACT_DIR}"; \
    \
    # Cleanup build-only packages
    apt-get purge -y --auto-remove curl

# Copy entrypoint script
COPY scripts/docker-entrypoint.sh ./entrypoint.sh
RUN [ "chmod", "+x", "./entrypoint.sh" ]

CMD ["./entrypoint.sh"]
