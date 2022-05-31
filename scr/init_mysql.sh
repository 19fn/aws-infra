#!/bin/bash

apt update
git clone https://github.com/19fn/docker-pack.git && /bin/bash docker-pack/install.sh
git clone https://github.com/19fn/local-environment.git