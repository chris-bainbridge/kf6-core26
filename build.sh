#!/bin/bash
# Build the kf6-core26 runtime content snap (the core26/resolute
# equivalent of the store's kf6-core24, which is noble-built and whose
# libxkbcommon-x11.so.0 ABI-mismatches the resolute base's
# libxkbcommon.so.0.13.1 -> ksmserver SIGSEGV / black screen).
#
# The snap is DERIVED from the locally-built kf6-core26-sdk snap
# (base: core26, resolute): its usr/ tree holds the KF6 6.30.0 runtime
# and its nested kde-qt6-core26-sdk/usr/ tree the Qt 6.11.1 runtime.
# Both are resolute-built, so libxkbcommon-x11.so.0.13.1 matches the
# base's libxkbcommon.so.0.13.1 (byte-identical libxkbcommon).
#
# The SDKs do NOT ship the X11 keymap/locale data that the session
# snap's XKB_CONFIG_ROOT/XLOCALEDIR point at ($SNAP/kf6/usr/share/X11/
# {xkb,locale}), so those are copied from the resolute host (xkb-data
# 2.46-2 / x11-common), matching the base's libxkbcommon.

set -euo pipefail

if [ "$(id -un)" = chrb ]; then
    exec sudo -u copilot -- "$0" "$@"
fi

SDK_SNAP="${KF6_SDK_SNAP:-$(ls -t ../kf6-core-sdk/kf6-core26-sdk_*.snap 2>/dev/null | head -1)}"
if [[ -z ${SDK_SNAP} || ! -e ${SDK_SNAP} ]]; then
    echo "Missing kf6-core26-sdk snap (build it in ../kf6-core-sdk first)" >&2
    exit 1
fi

VERSION=6.11.1-6.30.0-6.7.5-26.04.2
OUT="kf6-core26_${VERSION}_amd64.snap"

rm -rf sdk-root content-root "${OUT}"
mkdir -p content-root

echo "== Unsquashing ${SDK_SNAP}"
unsquashfs -d sdk-root "${SDK_SNAP}" >/dev/null

echo "== Merging KF6 usr/ + Qt6 usr/"
cp -a sdk-root/usr content-root/
cp -a sdk-root/kde-qt6-core26-sdk/usr/. content-root/usr/

echo "== Adding resolute X11 xkb + locale data"
mkdir -p content-root/usr/share/X11
# /usr/share/X11/xkb is a symlink to ../xkeyboard-config-2 on resolute;
# dereference it so the data lands as a real directory in the snap.
# The SDKs ship an empty xkb dir; drop it first so the copy is clean.
rm -rf content-root/usr/share/X11/xkb
cp -aL /usr/share/X11/xkb content-root/usr/share/X11/
cp -a /usr/share/X11/locale content-root/usr/share/X11/

echo "== Writing meta/snap.yaml"
mkdir -p content-root/meta
cat > content-root/meta/snap.yaml <<EOF
name: kf6-core26
version: ${VERSION}
summary: KDE Frameworks 6
description: KDE Frameworks are addons and useful extensions to Qt
architectures:
- amd64
base: core26
confinement: strict
grade: stable
environment:
  LD_LIBRARY_PATH: \${SNAP_LIBRARY_PATH}\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}:\$SNAP/lib:\$SNAP/usr/lib:\$SNAP/lib/x86_64-linux-gnu:\$SNAP/usr/lib/x86_64-linux-gnu
  PATH: \$SNAP/usr/sbin:\$SNAP/usr/bin:\$SNAP/sbin:\$SNAP/bin:\$PATH
slots:
  kf6-core26-slot:
    content: kf6-core26-all
    interface: content
    read:
    - .
  kf6-core26:
    content: kf6-core26
    interface: content
    read:
    - .
EOF

echo "== Packing ${OUT}"
mksquashfs content-root "${OUT}" -noappend -comp lzo >/dev/null

echo "== Done: ${OUT}"
ls -la "${OUT}"