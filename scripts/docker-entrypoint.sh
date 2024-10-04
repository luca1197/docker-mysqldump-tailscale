#!/bin/bash

# Start tailscaled
echo "[tailscaled] -> Starting"
echo "[tailscaled] -> Version: $(tailscaled version)"

tailscaled &

sleep 3

# Log into tailscale
echo "[Tailscale] -> Logging in..."

tailscale up --login-server "$TS_LOGIN_SERVER" --accept-routes --hostname="$TS_HOSTNAME" --authkey=$TS_AUTHKEY

# Wait for VPN connection
until nc -z -v -w5 $DB_HOST $DB_PORT; do
    echo "[Tailscale] -> Waiting for database VPN connection to be open ..."
    sleep 1
done

sleep 3

# Create config file with user and password
touch mariadb-extra.cnf

chmod 600 mariadb-extra.cnf

cat <<EOF > mariadb-extra.cnf
[client]
user=$DB_USER
password=$DB_PASSWORD
EOF

# Cleanup trap
function cleanup {
    echo "[Cleanup] -> Removing mysql config"
    rm mariadb-extra.cnf
}

trap cleanup EXIT

# Output mysqldump version
echo "[mysqldump] -> Version: $(mysqldump --version)"

# Run mysqldump
echo "[mysqldump] -> Dumping... (This may take some time)"
mysqldump --defaults-extra-file=./mariadb-extra.cnf --single-transaction --host $DB_HOST --port $DB_PORT --databases $DB_DATABASE > /tmp/mysqldump/dump.sql
echo "[mysqldump] -> Finished dumping to /tmp/mysqldump/dump.sql"

# Compress dump
if [ -n "$DUMP_COMPRESS" ]; then
    echo "[mysqldump] -> Compressing dump..."
    gzip -k /tmp/mysqldump/dump.sql
    echo "[mysqldump] -> Finished compressing dump to /tmp/mysqldump/dump.sql.gz"
fi

echo "-> All done"
