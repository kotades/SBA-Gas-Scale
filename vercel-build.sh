#!/usr/bin/env bash
# Vercel Build Script for Flutter Web
set -e

echo "==> Setting up Flutter SDK in Vercel environment..."
if [ ! -d "_flutter" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git _flutter
fi

export PATH="$PATH:$(pwd)/_flutter/bin"

echo "==> Enabling Flutter Web..."
flutter config --enable-web

echo "==> Resolving dependencies..."
flutter pub get

echo "==> Compiling Flutter Web production release..."
flutter build web --release

echo "==> Successfully compiled Flutter Web into build/web!"
