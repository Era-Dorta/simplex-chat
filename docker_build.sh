#!/bin/bash

# DOCKER_BUILDKIT=1 docker build --progress plain --platform linux/arm64 --tag eradorta/simplex-chat:bot .
docker buildx build --progress plain --tag eradorta/simplex-chat:bot-arm --load .