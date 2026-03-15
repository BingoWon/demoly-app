#!/bin/bash

# Swipop iOS App - Code Formatter
# Uses SwiftFormat to format all Swift files

set -e

cd "$(dirname "$0")"

echo "Formatting Swift code..."

if ! command -v swiftformat &> /dev/null; then
    echo "Error: swiftformat not found"
    echo "Install with: brew install swiftformat"
    exit 1
fi

swiftformat . --config .swiftformat

echo "Done."
