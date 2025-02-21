FROM ubuntu:24.04

# Install commonly needed tools.
# - Networking tools:
#   - curl
#   - iproute2
#   - iputils-ping
#   - iputils-tracepath
#   - tcpdump
# - Debugging tools:
#   - gdb
#   - tmux
#   - valgrind
#   - vim
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
#   - python3-exabgp
#   - python3-pytest-asyncio
#   - python3-pytest-xdist
#   - python3-scapy
#   - snmp
#   - snmpd
#   - snmp-mibs-downloader
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
      net-tools \
      pkg-config \
      protobuf-c-compiler \
      protobuf-compiler-grpc \
      python3-dev \
      python3-exabgp \
      python3-pytest \
      python3-pytest-asyncio \
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
      vim \
      ;

# Patch required SNMP MIB for topotest
RUN curl -o /usr/share/snmp/mibs/ietf/SNMPv2-PDU \
      https://raw.githubusercontent.com/FRRouting/frr-mibs/main/ietf/SNMPv2-PDU

# Configure system for FRR privilege drop
RUN groupadd -r -g 92 frr && \
      groupadd -r -g 85 frrvty && \
      adduser --system --ingroup frr --home /var/run/frr \
        --gecos "FRR suite" --shell /sbin/nologin frr && \
      usermod -a -G frrvty frr

# Build and install libyang
WORKDIR /root
ARG LIBYANG_VERSION='2.1.128'
RUN curl -L "https://github.com/CESNET/libyang/archive/refs/tags/v${LIBYANG_VERSION}.tar.gz" \
      | tar -xvzf - \
      && cd /root/libyang-${LIBYANG_VERSION} \
      && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build \
      && make -C build -j $(nproc) install

# Create exabgp user for topotest
RUN useradd -r -d /var/run/exabgp -s /bin/false exabgp


COPY frr-start /usr/sbin/frr-start
COPY frr-build /usr/sbin/frr-build
COPY container-init /usr/sbin/container-init
ENTRYPOINT [ "/usr/sbin/frr-start" ]
