# <*******************
# 
# Copyright 2016 Juniper Networks, Inc. All rights reserved.
# Licensed under the Juniper Networks Script Software License (the "License").
# You may not use this script file except in compliance with the License, which is located at
# http://www.juniper.net/support/legal/scriptlicense/
# Unless required by applicable law or otherwise agreed to in writing by the parties, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# 
# *******************>

FROM ubuntu:14.04

MAINTAINER Iddo Cohen <icohen@juniper.net>

ADD requirements.txt requirements.txt

# Editing sources and update apt.
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe multiverse restricted" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu trusty-security main universe multiverse restricted" >> /etc/apt/sources.list && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes \
    build-essential \
    python-setuptools \
    python-dev \
    libxml2-dev \
    libxslt-dev \
    libssl-dev \
    libffi6=3.1~rc1+r3.0.13-12 \
    libffi-dev \
    python-lxml \
    wget \
    git \
    git-core \
\
&& wget https://bootstrap.pypa.io/get-pip.py -O - | python \
&& pip install -r requirements.txt

### Packages for 64bit systems
# For 64bit systems one gets "usr/bin/ld: cannot find -lz" at PyEZ installation, solution install lib32z1-dev and zlib1g-dev
# Note: Because sh -c is executed via Docker, it is not == but =
RUN if [ "$(uname -m)" = "x86_64" ]; then apt-get install -y lib32z1-dev zlib1g-dev; fi

### Retrieving bootstrap.sh form SaltStack
# Installation manager for SaltStack.
# Carbon release to avoid grains/facts bugs with __proxy__.
#-M Install master, -d ignore install check, -X do not start the deamons and -P allows pip installation of some packages.
RUN wget https://raw.githubusercontent.com/saltstack/salt-bootstrap/stable/bootstrap-salt.sh | bash -s -- -d -M -X -P git carbon

### Creating directories for SaltStack
RUN mkdir -p /srv/salt /srv/pillar

### Replacing salt-minion configuration
RUN sed -i 's/^#master: salt/master: localhost/;s/^#id:/id: minion/' /etc/salt/minion

#Slim the container a litte.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
