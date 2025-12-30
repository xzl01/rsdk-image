#!/bin/sh
set -e
# run-rsdk-image: run the installed offline image with sensible mounts
# Usage: run-rsdk-image [--name NAME] [-c] [--] [docker run args...]

IMAGE_HINT="rsdk-image"
ARCH=$(dpkg --print-architecture 2>/dev/null || echo amd64)
IMG_TAR="/usr/share/rsdk-image/images/${ARCH}/image.tar"

# If installed as package, the script will be copied to /usr/bin; ensure executable
umask 022


if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not installed or not in PATH" 1>&2
  exit 2
fi

# Ensure image exists locally; if not, try loading packaged tar
if [ -f "$IMG_TAR" ]; then
  # check whether an image with the hinted name exists
  if [ -z "$(docker images -q "$IMAGE_HINT")" ]; then
    echo "Loading image from $IMG_TAR ..."
    docker load -i "$IMG_TAR" >/dev/null || true
  fi
else
  echo "Note: packaged image tar not found at $IMG_TAR, will try to use existing images"
fi

# Select an image to run. Prefer hinted name, else fall back to first available image.
IMG_TO_RUN=""
if [ -n "$(docker images -q "$IMAGE_HINT")" ]; then
  IMG_TO_RUN="$IMAGE_HINT"
else
  IMG_TO_RUN=$(docker images --format '{{.Repository}}:{{.Tag}}' \
    | grep -v '^<none>:<none>$' \
    | head -n1)
fi

if [ -z "$IMG_TO_RUN" ]; then
  echo "ERROR: no docker image available to run" 1>&2
  exit 3
fi

# Prepare host dirs for mounts
HOST_PERSIST_DIR=/var/lib/rsdk-image
mkdir -p "$HOST_PERSIST_DIR"

# Default mounts: bind host network config and timezone for minimal access
DOCKER_RUN_OPTS="-it --rm"
DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS --privileged"
DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS -w /root"
DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS -e PS1='[rsdk] \u@\h:\w\$ '"
DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS -v /etc/resolv.conf:/etc/resolv.conf:ro"
DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS -v /etc/localtime:/etc/localtime:ro"
DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS -v /dev:/dev"
DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS -v /sys:/sys:ro"
DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS -v /tmp:/tmp"
DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS -v ${HOME}:/root"
DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS -v ${HOST_PERSIST_DIR}:/var/lib/rsdk:rw"

# Pass through host proxy environment variables if present
for _var in HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy; do
  _val=$(printenv "$_var" 2>/dev/null || true)
  if [ -n "$_val" ]; then
    DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS -e $_var=$_val"
  fi
done

# Allow passing extra args to docker run
USE_CN=0
EXTRA_ARGS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --)
      shift
      EXTRA_ARGS="$@"
      break
      ;;
    --name)
      DOCKER_RUN_OPTS="$DOCKER_RUN_OPTS --name $2"
      shift 2
      ;;
    -c)
      USE_CN=1
      shift
      ;;
    *)
      EXTRA_ARGS="$EXTRA_ARGS $1"
      shift
      ;;
  esac
done

if [ -z "$EXTRA_ARGS" ]; then
  if [ "$USE_CN" -eq 1 ]; then
    EXTRA_ARGS="/usr/local/bin/install-rsdk.sh -c && /bin/bash"
  else
    EXTRA_ARGS="/usr/local/bin/install-rsdk.sh && /bin/bash"
  fi
fi

echo "Running container from image: $IMG_TO_RUN"
exec docker run $DOCKER_RUN_OPTS "$IMG_TO_RUN" $EXTRA_ARGS
