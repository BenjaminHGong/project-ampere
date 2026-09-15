# Use Ubuntu 22.04 as base
FROM ubuntu:22.04

# Set DEBIAN_FRONTEND to noninteractive to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install essentials
RUN apt-get update && apt-get install -y \
  curl \
  python3 \
  expect-dev \
  software-properties-common \
  cmake \
  ninja-build \
  clang \
  lld \
  qtbase5-dev \
  qtchooser \
  qt5-qmake \
  qtbase5-dev-tools \
  qtdeclarative5-dev \
  qml-module-qtquick2 \
  qml-module-qtquick-controls \
  qml-module-qtquick-layouts \
  qml-module-qtgraphicaleffects \
  squashfs-tools \
  squashfuse \
  git \
  python-setuptools \
  pkgconf \
  binfmt-support \
  systemd \
  libncurses6 \
  libncurses5 \
  libtinfo5 \
  libtinfo6 \
  libncurses-dev \
  libsdl2-dev \
  libepoxy-dev \
  libssl-dev \
  llvm
# Add FEX PPA and clone
RUN add-apt-repository -y ppa:fex-emu/fex
RUN git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git

# Build FEX
WORKDIR FEX
RUN sed -i 's@USE_LEGACY_BINFMTMISC "Uses legacy method of setting up binfmt_misc" FALSE@USE_LEGACY_BINFMTMISC "Uses legacy method of setting up binfmt_misc" TRUE@' ./CMakeLists.txt
RUN mkdir Build
WORKDIR /FEX/Build
RUN CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja ..
RUN ninja
RUN ninja install
RUN ninja binfmt_misc
RUN ninja binfmt_misc_64

# Create user
RUN useradd -m steam

# Create the Steam directory and set proper permissions as root
RUN mkdir -p /home/steam/Steam && chown root:root /home/steam/Steam && chmod 777 /home/steam/Steam

# Copy the init-server.sh script
COPY ./init-server.sh /home/steam/init-server.sh

# Set ownership for the script as root
RUN chmod 755 /home/steam/init-server.sh && chown steam:steam /home/steam/init-server.sh

# Switch to steam user
USER steam

# Install FEX root FS as steam
RUN bash -c "unbuffer FEXRootFSFetcher -y -x"

# Setup Steam (create a Steam directory for extraction and switch to it)
WORKDIR /home/steam/Steam

# Extract SteamCMD into the Steam directory (This is where the steam user has write access)
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C /home/steam/Steam

# Switch to steam user for running the container
ENTRYPOINT ["/home/steam/init-server.sh"]