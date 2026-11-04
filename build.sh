#!/bin/zsh
# Baut Vokabelheft.apk ohne Android Studio (aapt2 + javac + d8 + apksigner)
set -e
cd "$(dirname "$0")"
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH="$JAVA_HOME/bin:$PATH"
SDK=$HOME/Library/Android/sdk
BT=$SDK/build-tools/34.0.0
PLAT=$SDK/platforms/android-34/android.jar
VERSION_CODE=${VERSION_CODE:-1}
VERSION_NAME=${VERSION_NAME:-1.0}

rm -rf build && mkdir -p build/gen build/classes build/dex
$BT/aapt2 compile --dir res -o build/res.zip
$BT/aapt2 link -o build/base.apk -I $PLAT --manifest AndroidManifest.xml -A assets \
  --java build/gen --min-sdk-version 26 --target-sdk-version 34 \
  --version-code $VERSION_CODE --version-name $VERSION_NAME build/res.zip
javac -source 11 -target 11 -Xlint:-options -classpath $PLAT -d build/classes \
  $(find src build/gen -name '*.java')
$BT/d8 --release --min-api 26 --lib $PLAT --output build/dex $(find build/classes -name '*.class')
cp build/base.apk build/unsigned.apk
(cd build/dex && zip -q ../unsigned.apk classes.dex)
$BT/zipalign -f -p 4 build/unsigned.apk build/aligned.apk

# Signier-Schlüssel: einmal erzeugen und AUFHEBEN, sonst lassen sich spätere Updates nicht installieren
if [ ! -f vokabelheft.keystore ]; then
  PASS=$(openssl rand -hex 12)
  echo "$PASS" > keystore-passwort.txt
  keytool -genkeypair -keystore vokabelheft.keystore -alias vokabelheft -keyalg RSA -keysize 2048 \
    -validity 10000 -storepass "$PASS" -keypass "$PASS" -dname "CN=Vokabelheft" >/dev/null 2>&1
fi
PASS=$(cat keystore-passwort.txt)
$BT/apksigner sign --ks vokabelheft.keystore --ks-pass pass:$PASS --out Vokabelheft.apk build/aligned.apk
$BT/apksigner verify Vokabelheft.apk && echo "Fertig: $(pwd)/Vokabelheft.apk"
