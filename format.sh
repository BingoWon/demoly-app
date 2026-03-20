#!/bin/bash

# Demoly iOS App - Code Formatter
# Uses apple/swift-format (AST-based, official Swift formatter)

set -e

cd "$(dirname "$0")"

if ! command -v swift-format &> /dev/null; then
    echo "Error: swift-format not found"
    echo "Install with: brew install swift-format"
    exit 1
fi

echo "Formatting..."
swift-format format --configuration .swift-format --recursive --in-place Demoly/ DemolyTests/ DemolyUITests/

echo "Linting..."
swift-format lint --configuration .swift-format --recursive Demoly/ DemolyTests/ DemolyUITests/ 2>&1 || true

echo "Done."
