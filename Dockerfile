FROM ubuntu:focal AS build

# Install curl and simplex-chat-related dependencies
RUN apt-get update && apt-get install -y curl git build-essential libgmp3-dev zlib1g-dev libssl-dev
RUN apt install pkg-config libnuma1 --no-install-recommends -y

# Install ghcup
RUN a=$(arch); curl https://downloads.haskell.org/~ghcup/$a-linux-ghcup -o /usr/bin/ghcup && \
    chmod +x /usr/bin/ghcup

# Install ghc
RUN ghcup install ghc 8.10.7
# Install cabal
RUN ghcup install cabal
# Set both as default
RUN ghcup set ghc 8.10.7 && \
    ghcup set cabal

COPY . /project
WORKDIR /project

# Adjust PATH
ENV PATH="/root/.cabal/bin:/root/.ghcup/bin:$PATH"

# Adjust build
RUN cp ./scripts/cabal.project.local.linux ./cabal.project.local

# Compile simplex-chat
RUN cabal update
RUN cabal install

# Create a smaller run-time only stage, the previous one is about 5GB and this one is around 200Mb
FROM ubuntu:focal

# Install run-time dependencies
RUN apt-get update \
    && apt install -y libssl1.1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Get the binaries from the previous stage
COPY --from=build /root/.cabal/bin/simplex-anonymous-broadcast-bot /usr/bin/
COPY --from=build /root/.cabal/bin/simplex-bot-advanced /usr/bin/
COPY --from=build /project/run_bots.sh /usr/bin/

# Run the broadcast bot and the ping bot
CMD ["/usr/bin/run_bots.sh"]