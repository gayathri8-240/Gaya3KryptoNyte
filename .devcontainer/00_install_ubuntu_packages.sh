#!/usr/bin/env bash
set -euo pipefail

# Mirror the base package installation performed in the Dockerfile.
sudo apt-get update -y

export DEBIAN_FRONTEND=noninteractive
sudo apt update
sudo apt install -y \
    software-properties-common \
    curl \
    zip \
    unzip \
    tar \
    ca-certificates \
    git \
    wget \
    build-essential \
    vim \
    jq
sudo apt clean
unset DEBIAN_FRONTEND
