#!/bin/sh

BASE_BOARD=""
TARGET_REPO_NAME=""
OUTPUT_FOLDER="build"
GIT_BRANCH="main"

ERROR_PARAM=1
ERROR_UNSUPPORTED_PLATFORM=2

usage () {
    printf  "USAGE:\n"
    printf  "./build-balenaos-image.sh [-b <base-board-name>] [-o <output-folder-path>] [-g <git-branch>]\n"
    printf "OPTIONS:\n"
    printf "    -b base-board\n"
    printf "        orange-pi-zero, bobcat-px30\n"
    printf "    -o output-folder\n"
    printf "        Any valid absolute or relative path\n"
    printf "    -g git-branch\n"
    printf "        The branch for the target repository. If omitted 'main' will be used.\n"
    printf "    -h\n"
    printf "        Prints this help.\n"
}

# Parse the command line options and validate.
while getopts 'b:o:g:h' opt; do
  case "$opt" in
    b)
        BASE_BOARD="$OPTARG"
        ;;

    o)
        OUTPUT_FOLDER="$OPTARG"
        ;;

    g)
        GIT_BRANCH="$OPTARG"
        ;;

    h)
        usage
        exit 0
        ;;

    ?)
        printf "Error: Unknown parameter (%s)\nUse '-h' flag for help." "$OPTARG"
        exit $ERROR_PARAM
        ;;

  esac
done
shift "$((OPTIND - 1))"

# TODO Check prerequisites

if [ "$BASE_BOARD" = "" ]; then
    printf "Error: Base board parameter is mandatory.\n"
    exit $ERROR_PARAM
elif [ "$BASE_BOARD" = "orange-pi-zero" ]; then
    TARGET_REPO_NAME="balena-allwinner"
elif [ "$BASE_BOARD" = "bobcat-px30" ]; then
    TARGET_REPO_NAME="balena-bobcat-px30"
fi

if [ "$TARGET_REPO_NAME" = "" ]; then
    printf "Error: The specified base device is not supported.\n"
    exit $ERROR_UNSUPPORTED_PLATFORM
fi

if [ "$GIT_BRANCH" = "" ]; then
    printf "Error: Git branch name cannot be empty.\n"
    exit $ERROR_PARAM
fi

printf "Building BalenaOS image for %s...\n" "$BASE_BOARD"

NOW=$(date)
printf "Starting at %s\n" "$NOW"

echo "Creating builder group"
if ! (grep builder < "/etc/group") > /dev/null; then
    printf "Please run 'create-host-user-group.sh' first with sudo privileges\n"
    exit 3
fi

BUILDER_GID=$(getent group builder | cut -d: -f3)
export BUILDER_GID="$BUILDER_GID"

BUILDER_UID=$(id -u builder)
export BUILDER_UID="$BUILDER_UID"

# Check for the output folder
if [ ! "$(printf '%s' "$OUTPUT_FOLDER" | cut -c 1)" = "/" ]; then
    OUTPUT_FOLDER=$(pwd)/$OUTPUT_FOLDER
fi

# Create folder if necessary
if [ ! -d "$OUTPUT_FOLDER" ]; then
    printf "Creating output folder.\n"
    mkdir -p "$OUTPUT_FOLDER"
fi

printf "Building docker image...\n"
docker build \
    --build-arg TARGET_REPO_NAME="$TARGET_REPO_NAME" \
    --build-arg BASE_BOARD="$BASE_BOARD" \
    --build-arg BUILDER_GID="$BUILDER_GID" \
    --build-arg BUILDER_UID="$BUILDER_UID" \
    --build-arg GIT_BRANCH="$GIT_BRANCH" \
    -t balenaos-builder-$TARGET_REPO_NAME .

printf "Starting image build via running docker image. This would take some time...\n"
docker run \
    --privileged \
    --mount type=bind,source="$OUTPUT_FOLDER",target=/work/$TARGET_REPO_NAME/build \
    -t balenaos-builder-$TARGET_REPO_NAME

NOW=$(date)
printf "Finished at %s\n" "$NOW"
