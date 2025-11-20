#!/usr/bin/env bash

cd "$(dirname "$0")/ray"
./ray_interface.sh "${@:1}"
