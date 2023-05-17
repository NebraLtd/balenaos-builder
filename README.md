# BalenaOS Builder

This repository contains practical files for building Yocto based BalenaOS for supported flavors. It uses already built `balena/yocto-build-env` Docker container and modifies some of the files inside the container as they are not really compatible with our current workflow.

## Prerequisites

To run the image creation script, `create-host-user-group.sh` script has to be run first, if never executed. That's because the Docker container which will create the image will be running in privileged mode and write the artifacts in the output folder. This script creates user and group called `builder` and passes the ID's to the container. This way file permissions would get adjusted properly.

This script has to be run with sudo privileges.

## Usage

For starting the build process simply run `build-balenaos-image.sh` with the following parameters supplied.

* `-b <base-board-name>`: Base board name which is recognized by the target balenaos yocto repository.
* `-o <output-folder-path>`: Output folder path which will contain the final image and a lot of temporary files. So don't forget to clean it up after finishing. The default is relative `build` folder if not supplied.

**Example:**

```sh
./build-balenaos-image.sh -b orange-pi-zero -o build
```

This would start building a Docker container. It would start with `balena/yocto-build-env` container and modify some of the existing files inside of it (`prepare-and-start.sh` and `balena-docker.inc`) and then clones corresponding git repository, which would take some time.

After building the container, the script starts it parametrically and starts building the image. It would take a lot of time and would consume a lot of disk space, around 150 GB's.

## The Final Image

The output image could be found under the output folder. The final artifact can be found at `./build/tmp/deploy/images/<BASE_BOARD_NAME>` and has `balena-img` file extension.

## Notes
* Ignore the permission error logged at the end of the terminal output. It's caused by the internal balena script, which is trying to write to a log file even though it's not requested. It's not been fixed to stay away from maintenance burden.
* Since this task takes a lot of time to complete, `screen` shell could be used in an SSH session to gain freedom to login and logout while the final image is getting built on a remote machine.
