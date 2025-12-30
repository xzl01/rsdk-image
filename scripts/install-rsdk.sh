#!/bin/sh
set -e

USE_CN_MIRROR=0
while getopts "c" opt; do
  case "$opt" in
    c) USE_CN_MIRROR=1 ;;
    *) echo "Usage: $0 [-c]" 1>&2; exit 1 ;;
  esac
done

# Auto-detect if in China network if -c not specified
if [ "$USE_CN_MIRROR" -eq 0 ]; then
  if ! curl -s google.com | grep -q "301 Moved"; then
    USE_CN_MIRROR=1
  fi
fi

if [ "$USE_CN_MIRROR" -eq 1 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO=sudo
  else
    SUDO=
  fi
  # Switch Radxa and Debian sources to HUST mirrors
  $SUDO sed -i "s|https://radxa-repo.github.io|https://mirrors.hust.edu.cn/radxa-deb|g" /etc/apt/sources.list.d/*radxa*.list
  $SUDO sed -i 's/deb.debian.org/mirrors.hust.edu.cn/g' /etc/apt/sources.list.d/* || true
  $SUDO apt-get update
fi

# Install rsdk from the bundled deb if present; fetch deps as needed.
if [ -f /opt/rsdk.deb ]; then
  dpkg -i /opt/rsdk.deb || { apt-get update && apt-get -f install -y && dpkg -i /opt/rsdk.deb; }
else
  echo "rsdk.deb not found at /opt/rsdk.deb" 1>&2
  exit 1
fi
