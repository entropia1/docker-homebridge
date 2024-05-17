#!/bin/bash

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t entropia1/homebridge:latest --push "$SRC"
