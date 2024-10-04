FROM alpine:latest

# Install packages (Tailscale an MariaDB client) (mariadb-connector-c-dev is required because mysql requires the caching_sha2_password plugin which is provided by this package)
RUN apk add --no-cache netcat-openbsd bash tailscale mariadb-client mariadb-connector-c-dev

# Copy entrypoint script
COPY scripts/docker-entrypoint.sh ./entrypoint.sh
RUN [ "chmod", "+x", "./entrypoint.sh" ]

CMD ["./entrypoint.sh"]
