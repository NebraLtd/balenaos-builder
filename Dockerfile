FROM balena/yocto-build-env:df924ec

ENV DOCKER_VERSION="5:20.10.24~3-0~ubuntu-bionic"
RUN apt-get update && apt-get install -y docker-ce=${DOCKER_VERSION} docker-ce-cli=${DOCKER_VERSION} containerd.io && rm -rf /var/lib/apt/lists/*
VOLUME /var/lib/docker

ARG TARGET_REPO_NAME
ARG BASE_BOARD
ARG BUILDER_GID
ARG BUILDER_UID
ARG GIT_BRANCH

ENV TARGET_REPO_NAME=$TARGET_REPO_NAME
ENV INSTALL_DIR=/work/$TARGET_REPO_NAME
ENV BASE_BOARD=$BASE_BOARD
ENV BUILDER_GID=$BUILDER_GID
ENV BUILDER_UID=$BUILDER_UID
ENV GIT_BRANCH=$GIT_BRANCH

RUN apt-get update \
    && apt-get -y --no-install-recommends install python3.8=3.8.0-3ubuntu1~18.04.2 \
    && mv /usr/bin/python /usr/bin/python3.6 \
    && ln -s "$(which python3.8)" /usr/bin/python \
    && rm /usr/bin/python3 \
    && ln -s "$(which python3.8)" /usr/bin/python3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY prepare-and-start.sh /prepare-and-start.sh
COPY balena-docker.inc /balena-docker.inc

# ENTRYPOINT ["../prepare-and-start.sh"]
