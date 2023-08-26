##########################################################
# Emulating the x86_64 image
##########################################################
# This was too slow
sudo apt-get install qemu binfmt-support qemu-user-static
sudo update-binfmts --enable qemu-x86_64

##########################################################
# Compiling ghc manually
##########################################################
# This is not needed
wget http://downloads.haskell.org/~ghc/8.10.7/ghc-8.10.7-aarch64-deb10-linux.tar.xz
tar -xf ghc-8.10.7-aarch64-deb10-linux.tar.xz
cd ghc-8.10.7

./configure CONF_CC_OPTS_STAGE2="-marm -march=armv8-a" CFLAGS="-marm -march=armv8-a"

##########################################################
#  locally
##########################################################
sudo apt-get update && sudo apt-get install -y curl git build-essential libgmp3-dev zlib1g-dev libssl-dev libnuma-dev llvm-11
sudo apt install pkg-config --no-install-recommends -y

a=$(arch); sudo curl https://downloads.haskell.org/~ghcup/$a-linux-ghcup -o /usr/bin/ghcup && \
    sudo chmod +x /usr/bin/ghcup

# Add to bashrc
PATH=$PATH:/home/user/.ghcup/bin/:/usr/lib/llvm-11/bin
CPLUS_INCLUDE_PATH=$(llvm-config-11 --includedir):$CPLUS_INCLUDE_PATH
LD_LIBRARY_PATH=$(llvm-config-11 --libdir):$LD_LIBRARY_PATH


#
# Cross compiling
# 
sudo mkdir -m 0755 /nix && sudo chown user /nix

curl -L https://nixos.org/nix/install | sh
. /home/user/.nix-profile/etc/profile.d/nix.sh


#
# Static chroot, this one doesn't work because loop cannot be mounted
#
unxz ubuntu-22.04.2-preinstalled-server-arm64+raspi.img.xz
sudo dd if=/dev/zero bs=1M count=10240 >> ubuntu-22.04.2-preinstalled-server-arm64+raspi.img


#
# Using nix to cross compile
#

# Spin up the container and run 
nix-build
rsync -av $(nix-store -qR result-2) user@192.168.178.11:/nix/store
rsync -av result-2 user@192.168.178.11:


