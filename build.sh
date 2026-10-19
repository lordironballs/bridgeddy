#!/bin/bash
# Compila o BridgEddy. Por padrão instala em ~/Applications e abre.
#   SKIP_INSTALL=1 ./build.sh   → só compila em build/
# Precisa das ferramentas de linha de comando do Xcode (xcode-select --install).
set -e
cd "$(dirname "$0")"
NAME="BridgEddy"
APP="build/$NAME.app"
VERSION=$(cat VERSION 2>/dev/null || echo "0.0.0")
BUILD_NUMBER=$(git rev-list --count HEAD 2>/dev/null || echo 1)

rm -rf build; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" docs

echo "Gerando ícone..."
mkdir -p build/AppIcon.iconset
cp assets/AppIcon.png build/icon_1024.png
for s in 16 32 128 256 512; do
  sips -z $s $s build/icon_1024.png --out build/AppIcon.iconset/icon_${s}x${s}.png >/dev/null
  d=$((s*2)); sips -z $d $d build/icon_1024.png --out build/AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
sips -z 256 256 build/icon_1024.png --out docs/icon.png >/dev/null   # ícone usado no README

[ -f assets/avatar.jpg ] && cp assets/avatar.jpg "$APP/Contents/Resources/avatar.jpg"

echo "Compilando $NAME $VERSION ($BUILD_NUMBER)..."
swiftc -O -swift-version 5 -parse-as-library \
  -target "$(uname -m)-apple-macos13.0" \
  Sources/*.swift -o "$APP/Contents/MacOS/$NAME" \
  -framework SwiftUI -framework AppKit -framework CoreImage

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$NAME</string>
  <key>CFBundleDisplayName</key><string>$NAME</string>
  <key>CFBundleIdentifier</key><string>br.com.eddyantonini.bridgeddy</string>
  <key>CFBundleExecutable</key><string>$NAME</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$BUILD_NUMBER</string>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleLocalizations</key><array><string>pt</string><string>en</string><string>es</string></array>
  <key>NSHumanReadableCopyright</key><string>© 2026 Eddy Antonini — eddyantonini.com.br — MIT License</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
</dict></plist>
PLIST

# Assinatura para uso local
ID=$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/Apple Development|Developer ID Application/{print $2; exit}')
if [ -n "$ID" ]; then
  codesign --force --deep -s "$ID" "$APP" && echo "Assinado com: $ID"
else
  codesign --force --deep -s - "$APP"
  echo "Assinatura ad-hoc (uso local)."
fi

if [ -z "$SKIP_INSTALL" ]; then
  mkdir -p ~/Applications
  pkill -x "$NAME" 2>/dev/null || true
  rm -rf ~/Applications/"$NAME".app
  cp -R "$APP" ~/Applications/
  echo "✅ Instalado em ~/Applications/$NAME.app"
  open ~/Applications/"$NAME".app
else
  echo "✅ Compilado em $APP"
fi
