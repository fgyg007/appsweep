#!/bin/zsh
set -eu
cd "${0:A:h:h}"
mkdir -p build
source scripts/swift-env.sh
xcrun swiftc "${SWIFT_FLAGS[@]}" Sources/Core.swift Sources/Tests.swift -o build/core-tests
build/core-tests
