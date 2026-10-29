#!/bin/zsh
set -euo pipefail
SWINGSET_ROOT="${0:A:h:h}"
SWINGSET_SDK="${SWINGSET_SDK:-/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk}"
cd "$SWINGSET_ROOT"
swift build -c release --scratch-path build/spm -Xswiftc -sdk -Xswiftc "$SWINGSET_SDK" -Xcc -isysroot -Xcc "$SWINGSET_SDK"
SWINGSET_APP="$SWINGSET_ROOT/build/Swingset.app"
mkdir -p "$SWINGSET_APP/Contents/MacOS" "$SWINGSET_APP/Contents/Resources/Widgets"
cp build/spm/release/Swingset "$SWINGSET_APP/Contents/MacOS/Swingset"
cp Resources/Info.plist "$SWINGSET_APP/Contents/Info.plist"
cp Resources/Widgets/* "$SWINGSET_APP/Contents/Resources/Widgets/"
python3 - "$SWINGSET_APP" <<'PY'
import sys,json,pathlib,plistlib
app=pathlib.Path(sys.argv[1]);info=plistlib.loads((app/'Contents/Info.plist').read_bytes());path=app/'Contents/Resources/Widgets/manifest.json';manifest=json.loads(path.read_text());manifest['version']=info['CFBundleShortVersionString']+'+'+info['CFBundleVersion'];path.write_text(json.dumps(manifest,indent=2,ensure_ascii=False))
PY
swiftc -sdk "$SWINGSET_SDK" -parse-as-library Sources/Swingset/SwingsetIcon.swift scripts/make-icon.swift -o build/make-icon
build/make-icon "$SWINGSET_APP/Contents/Resources" "$SWINGSET_ROOT/docs/assets"
plutil -lint "$SWINGSET_APP/Contents/Info.plist"
codesign --force --sign - --options runtime "$SWINGSET_APP"
print "Built $SWINGSET_APP"
