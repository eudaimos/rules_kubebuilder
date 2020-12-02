#!/bin/bash

set -euo pipefail

VERSION="0.18.12"

ROOT=$(git rev-parse --show-toplevel)
DEST="$ROOT/deepcopy-gen/bin"

test -d "$ROOT/build/tmp" && rm -rf "$ROOT/build/tmp"
mkdir -p "$ROOT/build/tmp"
cd "$ROOT/build/tmp"

# Fetch and unpack v0.3.0
echo "Downloading and extracting code-generator version $VERSION"
curl -sL "https://github.com/kubernetes/code-generator/archive/v${VERSION}.tar.gz" | tar xfz -

cd "code-generator-$VERSION"

mkdir -p "$ROOT/bin"
echo "Building deepcopy-gen"
GOOS=darwin GOARCH=amd64 go build ./cmd/deepcopy-gen
mv deepcopy-gen "$DEST/deepcopy-gen.darwin"
GOOS=linux GOARCH=amd64 go build ./cmd/deepcopy-gen
mv deepcopy-gen "$DEST/deepcopy-gen.linux"

echo "Binaries built:"
file "$DEST"/*
