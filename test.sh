#!/bin/bash
# Unit-test the Markdown heuristic (no install, no Finder).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
xcrun swiftc Extension/Markdown.swift Tests/main.swift -o build/markdown-tests
build/markdown-tests
