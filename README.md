# docker-mysqldump-tailscale
A Docker image that runs mysqldump but with a Tailscale connection local to the container.

This allows you to dump / backup MySQL databases which are behind a Tailscale network without having to install and run Tailscale on the host.

## Running
For the Tailscale connection to work, the container requires a bind mount to `/dev/net/tun` (`/dev/net/tun:/dev/net/tun`) and the `NET_ADMIN` and `SYS_MODULE` capabilities.

The container requires your input for the Tailscale and MySQL connection. These details need to be set using environment variables, for which an example is provided in the `.env.example` file.

After the container is done dumping, the dump is written to `/tmp/mysqldump/dump.sql` in the containers file system. There are several ways to access this file on the host:
* Using `docker cp` (`docker cp <containerId>:/tmp/mysqldump/dump.sql ./somehwere-on-the-host/dump.sql`)
* Using a bind mount to `/tmp/mysqldump` (`./somewhere-on-the-host:/tmp/mysqldump`)
* ... your own way ✨ ...

If you enabled compression by setting the `DUMP_COMPRESS` environment variable to anything non-empty, the dump will be gzip-compressed to `/tmp/mysqldump/dump.sql.gz`.

## Ready-to-use examples
A ready-to-use script for backing up a MySQL database (e.g. for use with cron) is provided in the `examples/` folder in this repository. Just configure the config variables at the top of the file.
