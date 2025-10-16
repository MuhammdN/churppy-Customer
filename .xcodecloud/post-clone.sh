#!/bin/sh
set -e
echo "Running Flutter setup for Xcode Cloud"
flutter pub get
cd ios
pod install
cd ..

