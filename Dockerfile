FROM alpine:3.19

# Enable community repo
RUN echo "https://dl-cdn.alpinelinux.org/alpine/v3.19/community" >> /etc/apk/repositories

# Core packages (grub trigger fails in Docker overlay — safe to ignore)
RUN apk add --no-cache \
    grub \
    grub-bios \
    grub-efi \
    mtools \
    xorriso \
    squashfs-tools \
    bash \
    coreutils \
    util-linux \
    parted \
    linux-lts \
    mkinitfs \
    dosfstools \
    e2fsprogs \
    jq \
    wget \
    || true

# Build nwipe from source (avoids edge dependency conflicts)
RUN apk add --no-cache build-base ncurses-dev parted-dev autoconf automake pkgconf libconfig-dev linux-headers || true
RUN wget -q -O /tmp/nwipe.tar.gz https://github.com/martijnvanbrummelen/nwipe/archive/refs/tags/v0.37.tar.gz && \
    cd /tmp && tar xzf nwipe.tar.gz && ls /tmp/nwipe-* && \
    cd /tmp/nwipe-0.37 && \
    autoreconf -fi && \
    ./configure --prefix=/usr && make -j$(nproc) && make install && \
    nwipe --version && \
    cd / && rm -rf /tmp/nwipe*

# Working directory
WORKDIR /build

# Copy source files
COPY src/ /build/src/
COPY build-iso.sh /build/build-iso.sh
RUN chmod +x /build/build-iso.sh

CMD ["/build/build-iso.sh"]
