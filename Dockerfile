FROM debian:trixie

LABEL org.opencontainers.image.title="Homebridge in Docker"
LABEL org.opencontainers.image.description="Official Homebridge Docker Image"
LABEL org.opencontainers.image.authors="homebridge"
LABEL org.opencontainers.image.url="https://github.com/homebridge/docker-homebridge"
LABEL org.opencontainers.image.licenses="GPL-3.0"

# Latest release is supplied as a build argument
ARG HOMEBRIDGE_APT_PKG_VERSION
ARG FFMPEG_FOR_HOMEBRIDGE_VERSION
ARG DOCKER_HOMEBRIDGE_VERSION

# ENV HOMEBRIDGE_APT_PKG_VERSION=${HOMEBRIDGE_APT_PKG_VERSION:-v1.4.1}
ARG HOMEBRIDGE_APT_PKG_FILE=${HOMEBRIDGE_APT_PKG_VERSION}
# ENV FFMPEG_FOR_HOMEBRIDGE_VERSION=${FFMPEG_FOR_HOMEBRIDGE_VERSION:-v2.1.1}
# ENV DOCKER_HOMEBRIDGE_VERSION=${DOCKER_HOMEBRIDGE_VERSION:-latest}

ENV DEBIAN_FRONTEND=noninteractive

ENV S6_OVERLAY_VERSION=3.2.0.2 \
  S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
  S6_KEEP_ENV=1 \
  ENABLE_AVAHI=0 \
  USER=root \
  HOMEBRIDGE_APT_PACKAGE=1 \
  UIX_CUSTOM_PLUGIN_PATH="/var/lib/homebridge/node_modules" \
  PATH="/opt/homebridge/bin:/var/lib/homebridge/node_modules/.bin:$PATH" \
  HOME="/home/homebridge" \
  npm_config_prefix=/opt/homebridge

RUN set -x \
  && case "$(uname -m)" in \
  x86_64) S6_CPU_ARCH='x86_64'; HOMEBRIDGE_CPU_ARCH='amd64'; FFMPEG_CPU_ARCH='x86_64';; \
  armv7l) S6_CPU_ARCH='armhf'; HOMEBRIDGE_CPU_ARCH='armhf'; FFMPEG_CPU_ARCH='arm32v7';; \
  aarch64) S6_CPU_ARCH='aarch64'; HOMEBRIDGE_CPU_ARCH='arm64'; FFMPEG_CPU_ARCH='aarch64';; \
  *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && apt-get update \
  && apt-get install -y curl xz-utils \
  && cd /tmp \
  && curl -SLOf https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz \
  && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
  && curl -SLOf  https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_CPU_ARCH}.tar.xz \
  && tar -C / -Jxpf /tmp/s6-overlay-${S6_CPU_ARCH}.tar.xz \
  && curl -Lfs https://github.com/homebridge/ffmpeg-for-homebridge/releases/download/${FFMPEG_FOR_HOMEBRIDGE_VERSION}/ffmpeg-alpine-${FFMPEG_CPU_ARCH}.tar.gz | tar xzf - -C / --no-same-owner \
  && curl -sSLf -o /homebridge_${HOMEBRIDGE_APT_PKG_VERSION}.deb https://github.com/homebridge/homebridge-apt-pkg/releases/download/${HOMEBRIDGE_APT_PKG_VERSION}/homebridge_${HOMEBRIDGE_APT_PKG_FILE}_${HOMEBRIDGE_CPU_ARCH}.deb \
  && apt-get autoremove --purge -y curl apt-utils apt-transport-https xz-utils \
  && apt-get install -y jq psmisc make net-tools dbus-daemon libatomic1 \
# && apt-get install -y tzdata libatomic1 apt-transport-https jq openssl net-tools \
  && ln -snf /usr/share/zoneinfo/Etc/GMT /etc/localtime && echo Etc/GMT > /etc/timezone \
# && apt-get install -y python3 python3-pip pipx python3-setuptools git make g++ libnss-mdns \
# avahi-discover libavahi-compat-libdnssd-dev python3-venv python3-dev \
#&& pipx install tzupdate \
#&& chmod 0755 /bin/ping \
  && rm -rf /etc/cron.daily/apt-compat /etc/cron.daily/dpkg /etc/cron.daily/passwd /etc/cron.daily/exim4-base \
  && dpkg --force-all -i /homebridge_${HOMEBRIDGE_APT_PKG_VERSION}.deb \
  && rm -rf /homebridge_${HOMEBRIDGE_APT_PKG_VERSION}.deb \
  && chown -R root:root /opt/homebridge \
  && rm -rf /var/lib/homebridge \
  && apt-get clean \
  && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* \
  && rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN HB_CONFIG_UI_X_VERSION=$(jq -r '.dependencies["homebridge-config-ui-x"]' /opt/homebridge/package.json) && \
  echo "Homebridge Docker Package Manifest\n\n" \
  "Release Version: ${DOCKER_HOMEBRIDGE_VERSION}\n\n" \
  "| Package | Version |\n" \
  "|:-------:|:-------:|\n" \
  "|Ubuntu|24.04|\n" \
  "|ffmpeg for homebridge|${FFMPEG_FOR_HOMEBRIDGE_VERSION}|\n" \
  "|Homebridge APT Package|${HOMEBRIDGE_APT_PKG_VERSION}|\n" \
  "|NodeJS|$(jq -r '.dependencies.node' /opt/homebridge/package.json)|\n" \
  "|Homebridge UI|${HB_CONFIG_UI_X_VERSION}|\n" \
  "|Homebridge|$(jq -r '.dependencies.homebridge' /opt/homebridge/package.json)|\n" \
  > /opt/homebridge/Docker.manifest

# Fix Docker-Homebridge Update info wrong #645

RUN echo "# Appended by docker-homebridge" >> /opt/homebridge/source.sh \
  && echo "export DOCKER_HOMEBRIDGE_VERSION=${DOCKER_HOMEBRIDGE_VERSION}" >> /opt/homebridge/source.sh \
  && echo "export FFMPEG_FOR_HOMEBRIDGE_VERSION=${FFMPEG_FOR_HOMEBRIDGE_VERSION}" >> /opt/homebridge/source.sh \
  && echo "export HOMEBRIDGE_APT_PKG_VERSION=${HOMEBRIDGE_APT_PKG_VERSION}" >> /opt/homebridge/source.sh

COPY rootfs /

EXPOSE 8581/tcp
VOLUME /homebridge
WORKDIR /homebridge

ENTRYPOINT [ "/init" ]
