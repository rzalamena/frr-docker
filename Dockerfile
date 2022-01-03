FROM ubuntu:22.04

# Install commonly needed tools.
# - Networking tools:
#   - curl
#   - iproute2
#   - iputils-ping
#   - iputils-tracepath
#   - tcpdump
# - Debugging tools:
#   - gdb
#   - neovim
#   - tmux
#   - valgrind
# - Build dependencies (libyang):
#   - build-essential
#   - cmake
#   - libpcre2-dev
# - Build dependencies (frr):
#   - bison
#   - flex
#   - git (used by build system to generate code with git sha)
#   - install-info
#   - libcap-dev
#   - libc-ares-dev
#   - libelf-dev
#   - libgrpc++-dev (`--enable-grpc`: provides gRPC headers)
#   - libjson-c-dev
#   - libreadline-dev
#   - libsnmp-dev (`--enable-snmp=agentx`)
#   - libtool (pulls `autoconf` and `automake`)
#   - libunwind-dev (for better back traces)
#   - pkg-config (for configure and libyang build)
#   - protobuf-compiler-grpc (`--enable-grpc`: provides `protoc-gen-grpc`)
#   - python3-dev
#   - python3-pytest (topotests / make check)
#   - python3-sphinx (`--enable-doc`)
#   - sudo (topotests uses for `--cli-on-error`)
#   - texinfo
# - Topotest dependencies:
#   - net-tools
#   - python3-pytest-xdist
#   - python3-scapy
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y \
      bison \
      build-essential \
      cmake \
      curl \
      flex \
      gdb \
      git \
      install-info \
      iproute2 \
      iputils-ping \
      iputils-tracepath \
      libcap-dev \
      libc-ares-dev \
      libelf-dev \
      libgrpc++-dev \
      libjson-c-dev \
      libpcre2-dev \
      libreadline-dev \
      libsnmp-dev \
      libtool \
      libunwind-dev \
      neovim \
      net-tools \
      pkg-config \
      protobuf-compiler-grpc \
      python2 \
      python3-dev \
      python3-pytest \
      python3-pytest-xdist \
      python3-sphinx \
      sudo \
      tcpdump \
      texinfo \
      tmux \
      valgrind \
      ;

# Configure system for FRR privilege drop
RUN groupadd -r -g 92 frr && \
      groupadd -r -g 85 frrvty && \
      adduser --system --ingroup frr --home /var/run/frr \
        --gecos "FRR suite" --shell /sbin/nologin frr && \
      usermod -a -G frrvty frr

# Build and install libyang
WORKDIR /root
ARG LIBYANG_VERSION='2.0.7'
RUN curl -L "https://github.com/CESNET/libyang/archive/refs/tags/v${LIBYANG_VERSION}.tar.gz" \
      | tar -xvzf - \
      && cd /root/libyang-${LIBYANG_VERSION} \
      && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build \
      && make -C build install

# Install topotest dependencies
RUN curl -L https://bootstrap.pypa.io/pip/2.7/get-pip.py > /root/get-pip.py \
      && python2 /root/get-pip.py \
      && useradd -d /var/run/exabgp -s /bin/false exabgp \
      && python2 -m pip install 'exabgp<4.0.0'

COPY frr-start.sh /usr/sbin/frr-start.sh
COPY frr-build.sh /usr/sbin/frr-build.sh
COPY container-init.sh /usr/sbin/container-init.sh
ENTRYPOINT [ "/usr/sbin/frr-start.sh" ]
