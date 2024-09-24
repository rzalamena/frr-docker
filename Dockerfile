FROM fedora:40

# Install commonly needed tools.
# - Networking tools:
#   - iproute
#   - iputils
#   - tcpdump
# - Development / debugging tools:
#   - clang-analyzer (to run `scan-build`)
#   - gdb
#   - libasan
#   - tmux
#   - valgrind
#   - vim
# - Build dependencies (libyang):
#   - cmake
#   - pcre2-devel
# - Build dependencies (frr):
#   - bison
#   - c-ares-devel
#   - diffutils
#   - elfutils-libelf-devel
#   - flex
#   - gcc-c++ (`--enable-grpc`: to compile `lib/northbound_grpc.cpp`)
#   - git (used by build system to generate code with git sha)
#   - grpc-devel (`--enable-grpc`: provides gRPC headers)
#   - json-c-devel
#   - libcap-devel
#   - libtool (pulls `autoconf` and `automake`)
#   - libunwind-devel (for better back traces)
#   - net-snmp-devel (`--enable-snmp=agentx`)
#   - patch (used by build system)
#   - protobuf-c-devel
#   - python3-devel
#   - python3-pytest (needed by `make check`)
#   - python3-sphinx (`--enable-doc`)
#   - readline-devel
#   - texinfo (required for man pages)
#   - which (`--enable-grpc`: used by build system to find protoc-gen-grpc)
# - Watchfrr run time dependencies:
#   - procps-ng
RUN echo 'fastestmirror=True' >> /etc/dnf/dnf.conf \
      && dnf install -y \
           bison \
           c-ares-devel \
           clang-analyzer \
           cmake \
           diffutils \
           elfutils-libelf-devel \
           flex \
           gcc-c++ \
           gdb \
           git \
           grpc-devel \
           iproute \
           iputils \
           json-c-devel \
           libasan \
           libcap-devel \
           libtool \
           libunwind-devel \
           net-snmp-devel \
           patch \
           pcre2-devel \
           procps-ng \
           protobuf-c-devel \
           python3-devel \
           python3-pytest \
           python3-sphinx \
           readline-devel \
           tcpdump \
           texinfo \
           tmux \
           valgrind \
           vim \
           which \
      && dnf debuginfo-install -y \
           glibc \
           json-c \
           libasan \
           libcap \
           libgcc \
           libstdc++ \
           libunwind \
           libxcrypt \
           pcre2 \
           systemd-libs \
           ;

# Configure system for FRR privilege drop
RUN groupadd -r -g 92 frr \
      && groupadd -r -g 85 frrvty \
      && adduser --system --gid frr --home /var/run/frr \
           --comment "FRR suite" --shell /sbin/nologin frr \
      && usermod -a -G frrvty frr

# Build and install libyang
WORKDIR /root
ARG LIBYANG_VERSION='2.1.128'
RUN curl -L "https://github.com/CESNET/libyang/archive/refs/tags/v${LIBYANG_VERSION}.tar.gz" \
      | tar -xvzf - \
      && cd /root/libyang-${LIBYANG_VERSION} \
      && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -B build \
      && make -C build -j $(nproc) install


COPY frr-start /usr/sbin/frr-start
COPY frr-build /usr/sbin/frr-build
COPY container-init /usr/sbin/container-init
ENTRYPOINT [ "/usr/sbin/frr-start" ]
