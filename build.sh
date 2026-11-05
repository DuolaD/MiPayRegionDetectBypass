#!/usr/bin/env bash
# 不依赖 Gradle，直接用 Android SDK 命令行工具打包 LSPosed 模块 APK。
#
# 依赖：JDK 17+、Android SDK（build-tools 与 platforms 各一个即可）。
#   ANDROID_HOME  SDK 根目录（默认 Homebrew 的 android-commandlinetools 路径）
#   JAVA_HOME     JDK 根目录（未设置时使用 PATH 里的 javac）
#   KEYSTORE      签名用的 keystore（默认 ~/.android/debug.keystore，不存在会自动生成调试密钥）
#
# 用法：./build.sh   产物输出到本目录 out/
set -euo pipefail

VERSION_NAME="1.0.0"
VERSION_CODE=1
MIN_SDK=30
TARGET_SDK=36

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/out"
BUILD="$HERE/build"

ANDROID_HOME="${ANDROID_HOME:-/opt/homebrew/share/android-commandlinetools}"
BT="$(ls -d "$ANDROID_HOME"/build-tools/* 2>/dev/null | sort -V | tail -1)"
PLATFORM="$(ls -d "$ANDROID_HOME"/platforms/android-* 2>/dev/null | sort -V | tail -1)"
[ -n "$BT" ] && [ -n "$PLATFORM" ] || { echo "找不到 build-tools 或 platforms，请检查 ANDROID_HOME=$ANDROID_HOME" >&2; exit 1; }
ANDROID_JAR="$PLATFORM/android.jar"

if [ -n "${JAVA_HOME:-}" ]; then export PATH="$JAVA_HOME/bin:$PATH"; fi

KEYSTORE="${KEYSTORE:-$HOME/.android/debug.keystore}"
KS_PASS="${KS_PASS:-android}"
KS_ALIAS="${KS_ALIAS:-androiddebugkey}"
if [ ! -f "$KEYSTORE" ]; then
    mkdir -p "$(dirname "$KEYSTORE")"
    keytool -genkeypair -keystore "$KEYSTORE" -storepass "$KS_PASS" -keypass "$KS_PASS" \
        -alias "$KS_ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=Android Debug,O=Android,C=US" >/dev/null
fi

rm -rf "$BUILD"
mkdir -p "$BUILD"/{res,stubs,classes,dex} "$OUT"

# 1. 资源与清单
"$BT/aapt2" compile --dir "$HERE/src/main/res" -o "$BUILD/res.zip"
"$BT/aapt2" link -o "$BUILD/base.apk" -I "$ANDROID_JAR" \
    --manifest "$HERE/src/main/AndroidManifest.xml" \
    --min-sdk-version "$MIN_SDK" --target-sdk-version "$TARGET_SDK" \
    --version-code "$VERSION_CODE" --version-name "$VERSION_NAME" \
    -A "$HERE/src/main/assets" "$BUILD/res.zip"

# 2. 编译 Java：Xposed API 桩代码只参与编译，不进 dex
javac --release 17 -nowarn -d "$BUILD/stubs" $(find "$HERE/stubs" -name '*.java')
javac --release 17 -nowarn -cp "$ANDROID_JAR:$BUILD/stubs" -d "$BUILD/classes" \
    $(find "$HERE/src/main/java" -name '*.java')

# 3. 转 dex
"$BT/d8" --release --min-api "$MIN_SDK" --lib "$ANDROID_JAR" --classpath "$BUILD/stubs" \
    --output "$BUILD/dex" $(find "$BUILD/classes" -name '*.class')

# 4. 打包、对齐、签名
cp "$BUILD/base.apk" "$BUILD/unsigned.apk"
(cd "$BUILD/dex" && zip -q -X "$BUILD/unsigned.apk" classes.dex)
"$BT/zipalign" -f -p 4 "$BUILD/unsigned.apk" "$BUILD/aligned.apk"
APK="$OUT/FixMiPay-RegionBypass-v${VERSION_NAME}.apk"
"$BT/apksigner" sign --ks "$KEYSTORE" --ks-pass "pass:$KS_PASS" --ks-key-alias "$KS_ALIAS" \
    --out "$APK" "$BUILD/aligned.apk"
rm -f "$APK.idsig"

echo "已生成：$APK"
