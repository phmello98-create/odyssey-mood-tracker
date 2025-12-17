#!/usr/bin/env bash
set -euo pipefail

# Build release APK for arm64-v8a with split-per-abi and tree-shake icons
# The resulting APK will be copied to the project root and named 'releasetest8dez.apk'.

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter CLI not found. Please install Flutter and add it to PATH."
  exit 1
fi

echo "Running: flutter pub get"
flutter pub get

echo "Building release APK for arm64-v8a (split-per-abi, tree-shake icons)"
flutter build apk --release --target-platform android-arm64 --split-per-abi --tree-shake-icons

src_dir="build/app/outputs/flutter-apk"
apk_name="app-arm64-v8a-release.apk"
output="releasetest8dez.apk"

if [ -f "${src_dir}/${apk_name}" ]; then
  cp "${src_dir}/${apk_name}" "${output}"
  echo "Copied ${src_dir}/${apk_name} -> ${output}"
  echo "Done. You can find the APK at: $(pwd)/${output}"
else
  echo "Expected APK not found: ${src_dir}/${apk_name}" >&2
  echo "Available APKs in ${src_dir}:"
  ls -la "${src_dir}"/*.apk || true
  exit 1
fi
