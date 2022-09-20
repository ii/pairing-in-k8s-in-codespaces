FROM ubuntu:latest
ARG localWorkspaceFolder
RUN DEBIAN_FRONTEND=noninteractive \
  apt update \
  && apt upgrade -y \
  && apt install -y \
    sudo \
    iproute2 \
    net-tools \
    netcat \ 
    vim \
    conntrack \
    curl \
    gettext-base
RUN curl -o /tmp/cri-dockerd.deb -L https://github.com/Mirantis/cri-dockerd/releases/download/v0.2.5/cri-dockerd_0.2.5.3-0.ubuntu-jammy_amd64.deb \
  && apt install -y /tmp/cri-dockerd.deb
RUN mkdir -p /etc/sudoers.d && \
  echo "%sudo    ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/sudo \
  && useradd -m -G users,sudo -s /bin/bash ii
COPY /host /
USER ii
