#!/bin/bash

set -e

k3d cluster create \
cloudopshub-local \
--servers 1 \
--agents 1
