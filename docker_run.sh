#!/bin/bash

docker run -it \
--mount type=bind,source="$(pwd)",target=/project \
eradorta/simplex-chat:bot bash
