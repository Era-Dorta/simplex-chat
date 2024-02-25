#!/bin/bash

# Docker v23 builds with buildx automatically but I'm getting no internet during the building process
# docker build --progress plain --tag eradorta/simplex-chat:bot .

DOCKER_BUILDKIT=0 docker build --tag eradorta/simplex-chat:bot .
