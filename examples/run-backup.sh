#!/bin/bash

# Exit script on error
set -e

#
# https://github.com/luca1197/docker-mysqldump-tailscale
#
# This script will run the docker-mysqldump-tailscale container to get a dump of the database configured in the provided environment file.
# The dump will be saved in the provided output directory with a timestamped file name.
# Perfect to automatically backup a database on a schedule (e.g. using cron).
#

##########
# Config #
backup_name="my-mysql-backup" # Name used for the output file and container name
out_directory="/home/user/${backup_name}" # No trailing slash
env_file_path="/home/user/my-mysql-backup.env"
##########

# Exit trap to remove container
function cleanup {
	echo "[Script] -> Cleaing up"
	docker rm -f "${backup_name}"
}

trap cleanup EXIT

# Run mysqldump container
echo "[Script] -> Running mysqldump container"
docker run --name "${backup_name}" --env-file "${env_file_path}" --cap-add NET_ADMIN --cap-add SYS_MODULE -v "/dev/net/tun:/dev/net/tun" ghcr.io/luca1197/docker-mysqldump-tailscale:main

# Set output file
out_file_name="${backup_name}_$(date +"%Y_%m_%d-%H_%M_%S").sql.gz"
out_file_path="${out_directory}/${out_file_name}"

# Copy backup from container to host
echo "[Script] -> Copying backup from container to ${out_file_path}"
docker cp "${backup_name}:/tmp/mysqldump/dump.sql.gz" "${out_file_path}"

# Done
echo "[Script] -> DONE - Backup saved to ${out_file_path}"
