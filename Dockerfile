FROM ubuntu:20.04

RUN apt-get update \
    && apt-get install -y tzdata lsb-release \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ADD ./sav-linux-free-9.tgz /tmp
ADD ./savdi-linux-64bit.tar /tmp

# Install Sophos Anti-Virus for Linux
# for debug
# RUN sed -i 's,sophos-av/install.sh,bash -x sophos-av/install.sh,' /tmp/sophos-av/install.sh
ARG SOPHOS_INSTALL_OPTIONS
RUN /tmp/sophos-av/install.sh /opt/sophos-av --acceptlicence --autostart=False --enableOnBoot=False --automatic --ignore-existing-installation $SOPHOS_INSTALL_OPTIONS

# Install SAV Dynamic Interface
# for debug
# RUN sed -i 's,exec bash,exec bash -x,' /tmp/savdi-install/savdi_install.sh
ENV LD_LIBRARY_PATH=/opt/sophos-av/lib64
RUN /tmp/savdi-install/savdi_install.sh

# Update
# disable cache
ARG DOCKER_IMAGE_BUILD_TIME
RUN /opt/sophos-av/bin/savupdate

COPY ./scandata.sh ./healthcheck.sh /usr/local/bin/
# COPY savdid.conf /usr/local/savdi/savdid.conf

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
COPY ./init.sh /usr/local/bin/
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["init.sh"]
