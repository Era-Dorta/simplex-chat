#!/bin/bash

docker run -it \
--restart always \
--mount type=bind,source="$(pwd)"/simplex_bot,target=/root/.simplex/ \
simplex:bot
