#!/bin/bash

source ../CONFIG

TAG=${VERSION}

# build
# fetch latest image
podman pull quay.io/fedora/fedora
podman build -t quay.io/wcaban/stress-ng -f Containerfile
podman tag quay.io/wcaban/stress-ng:latest quay.io/wcaban/stress-ng:$TAG

# publish
if [ "$1" == "publish" ]; then
  podman push quay.io/wcaban/stress-ng:latest
  podman push quay.io/wcaban/stress-ng:$TAG
fi
