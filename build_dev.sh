#!/bin/bash

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 --build-arg "HOMEBRIDGE_APT_PKG_VERSION=v1.7.10" -t entropia1/homebridge_dev:latest -f Dockerfile_dev --push "$SRC"
