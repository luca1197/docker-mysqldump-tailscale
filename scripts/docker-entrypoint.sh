#!/bin/bash

# Check if tailscale should be skipped
if [ -n "$SKIP_TAILSCALE" ]; then
    echo "[Tailscale] -> Skipping tailscale setup (SKIP_TAILSCALE is set)"
else
    # Start tailscaled
    echo "[tailscaled] -> Starting"
    echo "[tailscaled] -> Version: $(tailscaled version)"

    tailscaled &

    sleep 3

    # Log into tailscale
    echo "[Tailscale] -> Logging in... (Login server: $([ -n "$TS_LOGIN_SERVER" ] && echo "$TS_LOGIN_SERVER" || echo "Tailscale official"))"

    tailscale_extra_args=()
    if [ -n "$TS_LOGIN_SERVER" ]; then
        tailscale_extra_args+=("--login-server" "$TS_LOGIN_SERVER")
    fi

    tailscale up --accept-routes --hostname="$TS_HOSTNAME" --authkey=$TS_AUTHKEY "${tailscale_extra_args[@]}"
fi

# Wait for VPN / database connection
echo "[Database] -> Testing database connection..."
until nc -z -v -w5 "$DB_HOST" "$DB_PORT"; do
    echo "[Database] -> Waiting for database connection to be open ..."
    sleep 1
done
echo "[Database] -> Database connection ok"

sleep 1

# Create config file with user and password
touch mysql-extra.cnf

chmod 600 mysql-extra.cnf

cat <<EOF > mysql-extra.cnf
[client]
user=$DB_USER
password=$DB_PASSWORD
EOF

# Append MariaDB-specific config
if [ "$MARIADB_VERIFY_SERVER_SSL" == "false" ]; then
    cat <<EOF >> mysql-extra.cnf
[client-mariadb]
disable-ssl-verify-server-cert
EOF
fi

# Cleanup trap
function cleanup {
    echo "[Cleanup] -> Removing mysql config"
    rm mysql-extra.cnf
}

trap cleanup EXIT

# Create dump directory
mkdir -p /tmp/mysqldump

# Output mysqldump version
echo "[mysqldump] -> Version: $(mysqldump --version)"

# Run mysqldump
echo "[mysqldump] -> Dumping... (This may take some time)"
mysqldump --defaults-extra-file=./mysql-extra.cnf --single-transaction --host $DB_HOST --port $DB_PORT --databases $DB_DATABASE > /tmp/mysqldump/dump.sql
echo "[mysqldump] -> Finished dumping to /tmp/mysqldump/dump.sql"

# Compress dump
if [ -n "$DUMP_COMPRESS" ]; then
    echo "[mysqldump] -> Compressing dump..."
    gzip -k /tmp/mysqldump/dump.sql
    echo "[mysqldump] -> Finished compressing dump to /tmp/mysqldump/dump.sql.gz"
fi

echo "-> All done"
