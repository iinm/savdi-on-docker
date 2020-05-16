branch     := $(shell git name-rev --name-only HEAD | sed 's,remotes/,,' | sed 's,origin/,,' | tr '/' '-')
image_name := savdi:$(branch)

all: ;

.PHONY: image
image: ./sav-linux-free-9.tgz ./savdi-linux-64bit.tar
	docker build -t $(image_name) --build-arg SOPHOS_INSTALL_OPTIONS="$(SOPHOS_INSTALL_OPTIONS)" .

.PHONY: run
run:
	docker run --rm -it \
		-p 4010:4010 \
		-e TZ=Asia/Tokyo \
		-e SOPHOS_UPDATE_INTERVAL_SEC=120 \
		-e WATCH_LOG_INTERVAL_SEC=1 \
		$(image_name)

.PHONY: attach
attach:
	docker exec -it $(shell docker ps | awk '$$2 == "$(image_name)" { print $$1 }') bash

./sav-linux-free-9.tgz:
	echo "Download from https://www.sophos.com/en-us/products/free-tools/sophos-antivirus-for-linux.aspx"

./savdi-linux-64bit.tar:
	echo "Download from https://www.sophos.com/en-us/support/downloads/network/sav-dynamic-interface.aspx"
