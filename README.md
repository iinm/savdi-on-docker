# savdi on docker

## Build

```sh
# (optional) configure
edit ./savdid.conf
sed -i '' 's,# COPY savdid.conf,COPY savdid.conf,g' Dockerfile

# build image
make image

# or
env SOPHOS_INSTALL_OPTIONS="--update-source-username=$username --update-source-password=$password" make image
```


## Test

```sh
make run
```

```sh
echo '123' | ./scandata.sh
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' | ./scandata.sh
```
