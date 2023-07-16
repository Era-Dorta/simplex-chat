#!/bin/bash

# DOCKER_BUILDKIT=1 docker build --progress plain --tag simplex:bot .

# Buildkit doesn't connect to the internet, so building with default instead
docker build --tag eradorta/simplex-chat:bot .