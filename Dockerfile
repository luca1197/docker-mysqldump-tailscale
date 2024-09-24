FROM alpine:latest

# Install packages (Tailscale an MariaDB client)
RUN apk add --no-cache netcat-openbsd bash tailscale mariadb-client

# Copy entrypoint script
COPY scripts/docker-entrypoint.sh ./entrypoint.sh
RUN [ "chmod", "+x", "./entrypoint.sh" ]

ENTRYPOINT [ "./entrypoint.sh" ]
CMD ["mysqldump", "--help"]
