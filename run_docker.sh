#!/bin/bash

DOCKER_BUILDKIT=1 docker build --tag simplex:bot .

docker run -it simplex:bot \
--mount type=bind,source="$(pwd)"/simplex_bot,target=/root/.simplex/ \