#!/bin/sh

echo "Creating builder group"
if ! (grep builder < "/etc/group") > /dev/null; then groupadd builder; fi

BUILDER_GID=$(getent group builder | cut -d: -f3)

echo "Creating builder user."
if ! (grep builder < "/etc/passwd") > /dev/null; then
    useradd -m -l -g "$BUILDER_GID" -G docker builder;
fi
