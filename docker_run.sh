#!/bin/bash

docker run -it \
--mount type=bind,source="$(pwd)",target=/home/user/test \
eradorta/simplex-chat:bot-arm bash
