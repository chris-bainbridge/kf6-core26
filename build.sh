#!/bin/bash
# Build the kf6-core26 runtime content snap.
#
# Since the deb-repack conversion this is a plain snapcraft build that
# stages runtime packages from the KDE Neon unstable/resolute apt suite
# (see snapcraft.yaml) instead of deriving the snap from the locally
# built kf6-core26-sdk.

set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

snapcraft pack "$@"

# Older tooling resolves the runtime content snap by the fixed name
# kf6-core26.snap; snapcraft pack produces a versioned name, so keep a
# copy under the fixed name (newest packed snap wins).
latest="$(ls -t kf6-core26_*_amd64.snap 2>/dev/null | head -1)"
if [ -n "$latest" ]; then
    cp -f "$latest" kf6-core26.snap
fi
