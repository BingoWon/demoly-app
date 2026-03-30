#!/bin/bash

# demoly-app/format.sh
# 格式化整个 iOS 项目代码

echo "Running SwiftFormat..."
if command -v swiftformat &> /dev/null; then
  swiftformat .
else
  echo "Error: swiftformat is not installed."
  echo "Please install it using: brew install swiftformat"
  exit 1
fi
