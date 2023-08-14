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
#   - libprotobuf-c-dev
#   - libreadline-dev
#   - libsnmp-dev (`--enable-snmp=agentx`)
#   - libtool (pulls `autoconf` and `automake`)
#   - libunwind-dev (for better back traces)
#   - pkg-config (for configure and libyang build)
#   - protobuf-c-compiler
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
#   - snmp
#   - snmp-mibs-downloader
#   - snmpd
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
      libprotobuf-c-dev \
      libreadline-dev \
      libsnmp-dev \
      libtool \
      libunwind-dev \
      neovim \
      net-tools \
      pkg-config \
      protobuf-c-compiler \
      protobuf-compiler-grpc \
      python2 \
      python3-dev \
      python3-pytest \
      python3-pytest-xdist \
      python3-scapy \
      python3-sphinx \
      snmp \
      snmpd \
      snmp-mibs-downloader \
      sudo \
      tcpdump \
      texinfo \
      tmux \
      valgrind \
      ;

# Patch required SNMP MIB for topotest
RUN curl -o /usr/share/snmp/mibs/ietf/SNMPv2-PDU \
      http://pastebin.com/raw.php?i=p3QyuXzZ

# Configure system for FRR privilege drop
RUN groupadd -r -g 92 frr && \
      groupadd -r -g 85 frrvty && \
      adduser --system --ingroup frr --home /var/run/frr \
        --gecos "FRR suite" --shell /sbin/nologin frr && \
      usermod -a -G frrvty frr

# Build and install libyang
WORKDIR /root
ARG LIBYANG_VERSION='2.1.80'
RUN curl -L "https://github.com/CESNET/libyang/archive/refs/tags/v${LIBYANG_VERSION}.tar.gz" \
      | tar -xvzf - \
      && cd /root/libyang-${LIBYANG_VERSION} \
      && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build \
      && make -C build -j $(nproc) install

# Install topotest dependencies
RUN curl -L https://bootstrap.pypa.io/pip/2.7/get-pip.py > /root/get-pip.py \
      && python2 /root/get-pip.py \
      && useradd -r -d /var/run/exabgp -s /bin/false exabgp \
      && python2 -m pip install 'exabgp<4.0.0'

# Install topotest socat version
RUN apt install -y yodl \
      && git clone https://github.com/opensourcerouting/socat.git \
      && cd /root/socat \
      && echo "\"opensourcerouting/socat@`git rev-parse --short HEAD`\"" > VERSION \
      && autoconf \
      && ./configure \
      && make -j $(nproc) \
      && make install \
      && cd /root \
      && rm -rf socat \
      && apt purge -y yodl \
      ;

# Set python3 as default (required by `frr-reload.py` and `topotests`)
RUN ln -sv /usr/bin/python3 /usr/bin/python

COPY frr-start /usr/sbin/frr-start
COPY frr-build /usr/sbin/frr-build
COPY container-init /usr/sbin/container-init
ENTRYPOINT [ "/usr/sbin/frr-start" ]
