FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg git build-essential devscripts dpkg-dev sudo bash-completion \
  && rm -rf /var/lib/apt/lists/*

# Install Radxa archive keyring package (latest release) and add signed repo
RUN keyring="$(mktemp)" \
  && version="$(curl -fsSL https://github.com/radxa-pkg/radxa-archive-keyring/releases/latest/download/VERSION)" \
  && curl -fsSL -o "$keyring" "https://github.com/radxa-pkg/radxa-archive-keyring/releases/latest/download/radxa-archive-keyring_${version}_all.deb" \
  && dpkg -i "$keyring" \
  && rm -f "$keyring" \
  && echo "deb [signed-by=/usr/share/keyrings/radxa-archive-keyring.gpg] https://radxa-repo.github.io/bookworm/ bookworm main" > /etc/apt/sources.list.d/70-radxa.list

WORKDIR /tmp

# Copy rsdk from local, install build-deps, build deb; leave rsdk.deb in the image (not installed)
COPY rsdk /tmp/rsdk
RUN cd /tmp/rsdk \
  && apt-get update \
  && apt-get build-dep -y ./ \
  && make deb \
  && mv ../rsdk_*.deb /opt/rsdk.deb \
  && rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache

# Optional runtime installer helper (provided externally in repo)
COPY scripts/install-rsdk /usr/local/bin/install-rsdk
RUN chmod 0755 /usr/local/bin/install-rsdk
