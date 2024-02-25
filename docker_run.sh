#!/bin/bash

docker run -it \
--mount type=bind,source="$(pwd)",target=/project \
eradorta/simplex-chat:bot bash


# After running, execute the following
# cabal update
# cabal run simplex-bot-advanced
# cabal run simplex-anonymous-broadcast-bot