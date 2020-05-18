tag := $(shell git name-rev --name-only HEAD | sed 's,remotes/,,' | sed 's,origin/,,' | tr '/' '-')
image_name := savdi:$(tag)

SOPHOS_INSTALL_OPTIONS  ?= --update-free
DOCKER_IMAGE_BUILD_TIME ?= $(shell date "+%s")

container_id = $(shell docker ps | awk '$$2 == "$(image_name)" { print $$1 }')

all: ;

.PHONY: image
image: ./sav-linux-free-9.tgz ./savdi-linux-64bit.tar
	docker build -t $(image_name) \
		--build-arg SOPHOS_INSTALL_OPTIONS="$(SOPHOS_INSTALL_OPTIONS)" \
		--build-arg DOCKER_IMAGE_BUILD_TIME="$(DOCKER_IMAGE_BUILD_TIME)" \
		.

./sav-linux-free-9.tgz:
	$(error "Download $@ from https://www.sophos.com/en-us/products/free-tools/sophos-antivirus-for-linux.aspx")

./savdi-linux-64bit.tar:
	$(error "Download $@ from https://www.sophos.com/en-us/support/downloads/network/sav-dynamic-interface.aspx")

.PHONY: run
run:
	docker run --rm -it \
		-p 4010:4010 \
		-e DEBUG=yes \
		-e TZ=Asia/Tokyo \
		-e SOPHOS_UPDATE_INTERVAL_SEC=120 \
		-e LOGCAT_INTERVAL_SEC=1 \
		$(image_name)
.PHONY: stop
stop:
	docker kill -s TERM $(container_id)

.PHONY: attach
attach:
	docker exec -it $(container_id) bash

.PHONY: lint
lint:
	shellcheck $(shell find . -type f -name '*.sh')
