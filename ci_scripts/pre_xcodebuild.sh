#!/bin/bash
set -e

echo "🚀 Running Flutter pre-build setup for Xcode Cloud..."

# Navigate to Flutter project root
cd ..

# Clean & get dependencies
flutter clean
flutter pub get

# iOS setup
cd ios
pod repo update
pod install

echo "✅ Flutter & Pods setup complete."
