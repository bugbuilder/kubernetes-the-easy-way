#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_PATH=$(dirname "$(readlink -f "$BASH_SOURCE")")

cd $SCRIPT_PATH/../cluster
vagrant up
