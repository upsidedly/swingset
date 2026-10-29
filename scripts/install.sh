#!/bin/zsh
set -euo pipefail
SWINGSET_ROOT="${0:A:h:h}"
if pgrep -x Swingset >/dev/null; then print -u2 'Quit Swingset before installing an update.'; exit 1; fi
if [[ ${1:-} != --no-build ]]; then "$SWINGSET_ROOT/scripts/build.sh"; fi
if [[ -e /Applications/Swingset.app ]]; then
    SWINGSET_BACKUP="$HOME/Library/Application Support/Swingset/Backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$SWINGSET_BACKUP"
    mv /Applications/Swingset.app "$SWINGSET_BACKUP/Swingset.app"
fi
ditto "$SWINGSET_ROOT/build/Swingset.app" /Applications/Swingset.app
codesign --verify --deep --strict /Applications/Swingset.app
print 'Installed /Applications/Swingset.app'
