#!/bin/bash

docker run -it \
--mount type=bind,source="$(pwd)"/simplex_bot,target=/root/.simplex/ \
simplex:bot
