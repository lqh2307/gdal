#!/bin/sh

# abort install if any errors occur and enable tracing
set -o errexit
set -o xtrace

sudo chown -Rv _apt:root /var/cache/apt/archives/partial/
sudo chmod -Rv 700 /var/cache/apt/archives/partial/

sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -V ca-certificates wget
wget https://apache.jfrog.io/artifactory/arrow/ubuntu/apache-arrow-apt-source-latest-jammy.deb -O /tmp/apache-arrow-apt-source-latest-jammy.deb
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -V /tmp/apache-arrow-apt-source-latest-jammy.deb
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -V libarrow-dev libparquet-dev libarrow-dataset-dev
