#!/bin/bash

# 1. Download Flutter
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Enable Web
echo "Enabling web support..."
flutter config --enable-web

# 4. Build the project
echo "Building for Web (Release)..."
flutter build web --release

echo "Build complete!"
