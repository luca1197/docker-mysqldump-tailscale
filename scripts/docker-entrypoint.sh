#!/bin/bash

echo "-> Starting tailscaled"

tailscaled --version

tailscaled &

sleep 3

echo "-> Logging into Tailscale"

tailscale up --login-server "$TS_LOGIN_SERVER" --accept-routes --hostname="$TS_HOSTNAME" --authkey=$TS_AUTHKEY

until nc -z -v -w5 $DB_HOST $DB_PORT; do
    echo "-> Waiting for database VPN connection to be open ..."
    sleep 1
done

sleep 3

# Run entrypoint command (exec replaces the current bash process to make sure signals will be forwarded)
exec "$@"
