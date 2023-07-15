#!/bin/bash

docker run -it simplex:bot \
--mount type=bind,source="$(pwd)"/simplex_bot,target=/root/.simplex/ \