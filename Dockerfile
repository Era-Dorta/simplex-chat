FROM ubuntu:focal AS build

RUN mkdir -m 0755 /nix

ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN chown user /nix

RUN apt-get update && apt-get install -y curl git build-essential

USER $USERNAME

RUN ls -a /home/user/
RUN mkdir /home/user/.local && mkdir /home/user/.local/bin

RUN curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
RUN . /home/user/.nix-profile/etc/profile.d/nix.sh
ENV PATH="/home/user/.nix-profile/bin:$PATH"

RUN nix-env -iA nixpkgs.niv && \
    niv init && \
    niv add input-output-hk/haskell.nix -n haskellNix

RUN mkdir $HOME/.config && mkdir $HOME/.config/nix
RUN echo "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ= " > $HOME/.config/nix/nix.conf
RUN echo "substituters = https://cache.nixos.org/ https://cache.iog.io " >> $HOME/.config/nix/nix.conf

WORKDIR /home/user/test