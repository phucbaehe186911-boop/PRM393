#!/bin/bash
set -e

# Tải Flutter SDK (bản stable)
git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter_sdk
export PATH="$PATH:$(pwd)/flutter_sdk/bin"

flutter config --enable-web
flutter doctor -v
flutter pub get
flutter build web --release