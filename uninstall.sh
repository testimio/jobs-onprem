#!/usr/bin/env bash

set -e
msg() { echo -e "\e[32mINFO ---> $1\e[0m"; }
err() { echo -e "\e[31mERR ---> $1\e[0m" ; exit 1; }

check() { command -v $1 >/dev/null 2>&1 || err "$1 utility is requiered!"; }

check docker-compose

msg "Removing k3s..."

docker-compose down --volume