#!/usr/bin/env bash
set -euo pipefail

# Script to build Android APKs with the requested flags and copy outputs
# to a timestamped folder to avoid overwriting existing files in flutter-apk.

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter CLI not found. Please install Flutter and add it to PATH."
  exit 1
fi

timestamp=$(date +%Y%m%d_%H%M%S)
outdir="flutter-apk-${timestamp}"
mkdir -p "${outdir}"

echo "Running: flutter pub get"
flutter pub get

# Build per-abi APKs and disable tree-shake icons
# --split-per-abi creates smaller per-ABI apks
cmd=(flutter build apk --release --no-tree-shake-icons --split-per-abi)

echo "Building apks: ${cmd[*]}"
"${cmd[@]}"

srcdir="build/app/outputs/flutter-apk"
if [ -d "${srcdir}" ]; then
  echo "Copying APKs to ${outdir}"
  for f in "${srcdir}"/*.apk; do
    if [ -f "$f" ]; then
      base=$(basename "$f")
      cp "$f" "${outdir}/${base%.apk}-${timestamp}.apk"
    fi
  done
  echo "Done. Built apks copied to ${outdir}."
else
  echo "No APK outputs found at ${srcdir}. Build may have failed." >&2
  exit 1
fi
