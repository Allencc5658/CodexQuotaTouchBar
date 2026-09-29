#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h}
sdk_path=$(xcrun --show-sdk-path)
build_dir="${CODEX_QUOTA_BUILD_DIR:-$project_dir/.build}"
app_dir="$project_dir/Codex Quota.app"
mkdir -p "$build_dir" "$app_dir/Contents/MacOS"
mkdir -p "$app_dir/Contents/Resources"

for arch_target in x86_64-apple-macosx10.14 arm64-apple-macosx11.0; do
  arch_name=${arch_target%%-*}
  mkdir -p "$build_dir/ModuleCache-$arch_name"
  export CLANG_MODULE_CACHE_PATH="$build_dir/ModuleCache-$arch_name"
  clang -target "$arch_target" -fobjc-arc -isysroot "$sdk_path" \
    -c "$project_dir/Sources/TouchBarBridge.m" \
    -o "$build_dir/TouchBarBridge-$arch_name.o"
  swiftc -O -module-cache-path "$build_dir/ModuleCache-$arch_name" \
    -sdk "$sdk_path" -target "$arch_target" \
    "$project_dir/Sources/QuotaModel.swift" \
    "$project_dir/Sources/Localizer.swift" \
    "$project_dir/Sources/CodexClient.swift" \
    "$project_dir/Sources/QuotaTouchBarView.swift" \
    "$project_dir/Sources/AppDelegate.swift" \
    "$project_dir/Sources/main.swift" \
    "$build_dir/TouchBarBridge-$arch_name.o" -framework AppKit \
    -o "$build_dir/CodexQuotaTouchBar-$arch_name"
done
lipo -create "$build_dir/CodexQuotaTouchBar-x86_64" \
  "$build_dir/CodexQuotaTouchBar-arm64" \
  -output "$app_dir/Contents/MacOS/CodexQuotaTouchBar"
cp "$project_dir/Info.plist" "$app_dir/Contents/Info.plist"
cp "$project_dir/Assets/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
for language_dir in "$project_dir"/Resources/*.lproj; do
  ditto "$language_dir" "$app_dir/Contents/Resources/${language_dir:t}"
done
codesign --force --sign - "$app_dir"
echo "Built: $app_dir"
