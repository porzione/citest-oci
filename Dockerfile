# vi: ft=dockerfile
FROM debian:buster-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn

ADD 01_nodoc /etc/dpkg/dpkg.cfg.d/
RUN for i in $(seq 1 8); do mkdir -p /usr/share/man/man${i}; done

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    apt-utils \
    bsdmainutils \
    ca-certificates \
    coreutils \
    curl \
    g++ \
    gcc \
    gettext-base \
    git \
    gnupg2 \
    jq \
    ldnsutils \
    less \
    libc6-dev \
    lsb-release \
    make \
    ncdu \
    net-tools \
    openssh-client \
    postgresql-client \
    procps \
    psmisc \
    python \
    python-pip \
    python-setuptools \
    python-wheel \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    redis-tools \
    ruby \
    ruby-faraday \
    ruby-oj \
    sudo \
    traceroute \
    uuid-runtime \
    vim-tiny \
    wget \
    xz-utils \
    && true

### python alternatives
### TODO: set v3 as default for oci, but ccm tested with v2

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python2.7 2 \
    && update-alternatives --set python /usr/bin/python3.7

### latest mediainfo


ARG MEDIAAREA_DEB=repo-mediaarea_1.0-16_all.deb
ARG MEDIAAREA_URL=https://mediaarea.net/repo/deb/${MEDIAAREA_DEB}
RUN wget $MEDIAAREA_URL \
    && dpkg -i $MEDIAAREA_DEB \
    && apt-get update \
    && apt-get install -y mediainfo \
    && rm $MEDIAAREA_DEB

### nodejs 8.x 10.x 11.x 12.x 13.x

ARG NODEJS_VERSION=12.x
RUN curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION} | bash - && apt-get install -y nodejs

### yarn stable https://yarnpkg.com/en/docs/install#debian-stable

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt update && apt install -y --no-install-recommends yarn

### golang

ARG GOLANG_VERSION_1=1.15.10
ARG GOLANG_VERSION_2=1.16.2
ARG GOLANG_DOWNLOAD_SHA256_1=4aa1267517df32f2bf1cc3d55dfc27d0c6b2c2b0989449c96dd19273ccca051d
ARG GOLANG_DOWNLOAD_SHA256_2=542e936b19542e62679766194364f45141fde55169db2d8d01046555ca9eb4b8
ARG GOLANG_DOWNLOAD_URL_1=https://golang.org/dl/go${GOLANG_VERSION_1}.linux-amd64.tar.gz
ARG GOLANG_DOWNLOAD_URL_2=https://golang.org/dl/go${GOLANG_VERSION_2}.linux-amd64.tar.gz
ARG GOLANG_DIR_1=/usr/local/go${GOLANG_VERSION_1}
ARG GOLANG_DIR_2=/usr/local/go${GOLANG_VERSION_2}

RUN curl -k -fsSL "$GOLANG_DOWNLOAD_URL_1" -o golang.tar.gz \
    && echo "$GOLANG_DOWNLOAD_SHA256_1  golang.tar.gz" | sha256sum -c - \
    && mkdir -p $GOLANG_DIR_1 \
    && tar -C $GOLANG_DIR_1 -xzf golang.tar.gz --strip-components=1 \
    && rm golang.tar.gz

RUN curl -k -fsSL "$GOLANG_DOWNLOAD_URL_2" -o golang.tar.gz \
    && echo "$GOLANG_DOWNLOAD_SHA256_2  golang.tar.gz" | sha256sum -c - \
    && mkdir -p $GOLANG_DIR_2 \
    && tar -C $GOLANG_DIR_2 -xzf golang.tar.gz --strip-components=1 \
    && rm golang.tar.gz

ENV GOPATH=/go
RUN mkdir -p $GOPATH/src" $GOPATH/bin" && chmod -R 755 $GOPATH
ENV PATH="$GOPATH/bin:$PATH"
#ENV PATH="/usr/local/go/bin:$PATH"

### oracle oci cli https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/climanualinst.htm

RUN pip3 install oci-cli

### k8s https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl

### cassandra cqlsh

RUN pip2 install cqlsh ccm
ADD cqlshrc /root/.cassandra/cqlshrc

### docker, without daemon packages: docker-ce, containerd.io

RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
    && echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee -a /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install docker-ce-cli

### ffmpeg

ARG FFMPEG_TAR=ffmpeg-git-amd64-static.tar.xz
ARG FFMPEG_DOWNLOAD_URL=https://johnvansickle.com/ffmpeg/builds/${FFMPEG_TAR}
ARG FFMPEG_DOWNLOAD_MD5=https://johnvansickle.com/ffmpeg/builds/${FFMPEG_TAR}.md5

RUN curl -k -fsSL "$FFMPEG_DOWNLOAD_MD5" -o "${FFMPEG_TAR}.md5" \
    && curl -k -fsSL "$FFMPEG_DOWNLOAD_URL" -o $FFMPEG_TAR \
    && md5sum -c "${FFMPEG_TAR}.md5" \
    && mkdir /tmp/ffmpeg \
    && tar --wildcards --strip-components 1 -xJf $FFMPEG_TAR -C /tmp/ffmpeg \
    && mv /tmp/ffmpeg/ffmpeg /tmp/ffmpeg/ffprobe /usr/local/bin \
    && rm -rf $FFMPEG_TAR "${FFMPEG_TAR}.md5" /tmp/ffmpeg

### cleanup

RUN ln -s /usr/bin/vim.tiny /usr/local/bin/vim
RUN rm -rf /usr/share/man && apt-get clean && rm -rf /var/lib/apt/lists/ && rm -rf /root/.cache

ARG SOURCE_BRANCH=""
ARG SOURCE_COMMIT=""
RUN echo $(date +'%y%m%d_%H%M%S_%Z') ${SOURCE_BRANCH} ${SOURCE_COMMIT} > /build.txt
SHELL ["/bin/bash", "-c"]
RUN echo "PATH=$PATH" > /etc/environment
