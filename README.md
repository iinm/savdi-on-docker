# SAVDI on Docker

![shellcheck](https://github.com/iinm/savdi-on-docker/workflows/shellcheck/badge.svg?branch=master)

This repository provides resources to build docker image that run Sophos Antivirus Dynamic Interface (SAVDI).
Note that additional proprietary resources are required to build image. (See `Makefile`)


Main processes launches following processes on container.
- savdi daemon   : savdi itself
- sophos updater : This process updates sophos periodically and reload savdi daemon if there is any updates.
- log watcher    : This process cat log file contents to stdout and truncate them periodically.

For more detail see `init.sh`.


## Build

```sh
# (optional) configure
edit ./savdid.conf
sed -i '' 's,# COPY savdid.conf,COPY savdid.conf,g' Dockerfile

# build image
make image

# or specify tag (defalt: branch name)
make tag=latest image

# or pass username / password if you have license
env SOPHOS_INSTALL_OPTIONS="--update-source-username=$username --update-source-password=$password" make image
```


## Run

```sh
docker run --rm -it -p 4010:4010 -e SOPHOS_UPDATE_INTERVAL_SEC=3600 savdi:<tag>
```


## Test

```sh
make run
```

```sh
echo '123' | ./scandata.sh
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' | ./scandata.sh
```
