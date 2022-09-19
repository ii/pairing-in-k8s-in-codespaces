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
    vim
RUN mkdir -p /etc/sudoers.d && \
  echo "%sudo    ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/sudo \
  && useradd -m -G users,sudo -s /bin/bash ii
COPY /host /
USER ii
