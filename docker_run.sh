#!/bin/bash

docker run -it \
--restart always \
--mount type=bind,source="$(pwd)"/simplex_bot,target=/root/.simplex/ \
eradorta/simplex-chat:bot
