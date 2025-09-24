#!/bin/bash

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 --build-arg "HOMEBRIDGE_APT_PKG_VERSION=v1.7.10" --build-arg "FFMPEG_FOR_HOMEBRIDGE_VERSION=v2.2.0" --build-arg "DOCKER_HOMEBRIDGE_VERSION=cratsch_custom" -t entropia1/homebridge:latest --push "$SRC"
