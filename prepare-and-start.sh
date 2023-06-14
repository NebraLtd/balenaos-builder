#!/bin/bash

set -e

VERBOSE=${VERBOSE:-0}
[ "${VERBOSE}" = "verbose" ] && set -x

#shellcheck disable=SC1091
source /balena-docker.inc

trap 'balena_docker_stop fail' SIGINT SIGTERM
# INSTALL_DIR="/work/$TARGET_REPO_NAME"

# Below part is disabled because the same logic is now in Dockerfile and preempts this one.

# Create the normal user to be used for bitbake (barys)
echo "[INFO] Creating groups."
if ! (grep builder < "/etc/group") > /dev/null; then groupadd -g "$BUILDER_GID" builder; fi
if ! (grep docker < "/etc/group") > /dev/null; then groupadd docker; fi

# BUILDER_GID=$(getent group builder | cut -d: -f3)
# export BUILDER_GID=$BUILDER_GID
printf "[INFO] BUILDER_GID = %s\n" "$BUILDER_GID"

echo "[INFO] Creating user."
if ! (grep builder < "/etc/passwd") > /dev/null; then
    useradd -m -l -u "$BUILDER_UID" -g builder -G docker builder
fi

# BUILDER_UID=$(id -u builder)
# export BUILDER_UID=$BUILDER_UID
printf "[INFO] BUILDER_UID = %s\n" "$BUILDER_UID"

# Make the "builder" user inherit the $SSH_AUTH_SOCK variable set-up so he can use the host ssh keys for various operations
# (like being able to clone private git repos from within bitbake using the ssh protocol)
echo 'Defaults env_keep += "SSH_AUTH_SOCK"' > /etc/sudoers.d/ssh-auth-sock

# Disable host authenticity check when accessing git repos using the ssh protocol
# (not disabling it will make this script fail because /home/builder/.ssh/known_hosts file is empty)
mkdir -p /home/builder/.ssh/
echo "StrictHostKeyChecking no" > /home/builder/.ssh/config

# Clone the target base board repo
# printf "Cloning %s repo on %s branch...\n" "$TARGET_REPO_NAME" "$GIT_BRANCH"
# git clone -b "$GIT_BRANCH" --single-branch --depth 1 --recursive "https://github.com/NebraLtd/$TARGET_REPO_NAME.git" /work/tmp-repo
# mv /work/tmp-repo/* "$INSTALL_DIR"
if [ -d "/work/$TARGET_REPO_NAME" ]; then
    printf "Repo already exists. Pulling latest changes.\n"
    sudo -H -u builder -g builder git --git-dir="/work/$TARGET_REPO_NAME/.git" --work-tree="/work/$TARGET_REPO_NAME" checkout "$GIT_BRANCH"
    sudo -H -u builder -g builder git --git-dir="/work/$TARGET_REPO_NAME/.git" --work-tree="/work/$TARGET_REPO_NAME" pull --force
    sudo -H -u builder -g builder git --git-dir="/work/$TARGET_REPO_NAME/.git" --work-tree="/work/$TARGET_REPO_NAME" reset --hard HEAD
else
    printf "Cloning %s repo on %s branch...\n" "$TARGET_REPO_NAME" "$GIT_BRANCH"
    sudo -H -u builder -g builder git clone -b "$GIT_BRANCH" --single-branch --depth 1 --recursive "https://github.com/NebraLtd/$TARGET_REPO_NAME.git" "/work/$TARGET_REPO_NAME"
fi

if [ ! -d "/work/$TARGET_REPO_NAME/build" ]; then
    printf "Creating build folder.\n"
    sudo -H -u builder -g builder mkdir -p "/work/$TARGET_REPO_NAME/build"
fi

# TODO test start
# chmod +x "$INSTALL_DIR/barys"
# cp "$INSTALL_DIR/barys" "$INSTALL_DIR/balena-yocto-scripts/build"
# chmod +x "$INSTALL_DIR/generate-conf-notes.sh"
# cp "$INSTALL_DIR/generate-conf-notes.sh" "$INSTALL_DIR/balena-yocto-scripts/build"
# cp "$INSTALL_DIR/oe-setup-builddir" "$INSTALL_DIR/layers/poky/scripts"
# TODO test end

# Fixing a strange bug, which happened on the VPS. The docker image had created a new user with 1001 id and
# made the build folder owned by it. This has created build issues.
chown -R builder:builder "$INSTALL_DIR"

# Start docker
balena_docker_start
balena_docker_wait

sudo -H -u builder -g builder git config --global user.name "Resin Builder"
sudo -H -u builder -g builder git config --global user.email "buildy@builder.com"
echo "[INFO] The configured git credentials for user builder are:"
sudo -H -u builder -g builder git config --get user.name
sudo -H -u builder -g builder git config --get user.email

# Start barys with all the arguments requested
echo "[INFO] Running build as builder user..."
if [ -d "${INSTALL_DIR}/balena-yocto-scripts" ]; then
    sudo -H -u builder -g builder "${INSTALL_DIR}/balena-yocto-scripts/build/barys" "-m" "$BASE_BOARD" "-l" "--bitbake-args" "-k" &
else
    sudo -H -u builder -g builder "${INSTALL_DIR}/resin-yocto-scripts/build/barys" "-m" "$BASE_BOARD" "-l"  "--bitbake-args" "-k" &
fi

barys_pid=$!
wait $barys_pid || true

balena_docker_stop

exit 0
