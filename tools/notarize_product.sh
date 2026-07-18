#!/bin/bash
#https://discuss.atom.io/t/sandbox-supposedly-enabled-but-application-loader-disagrees/26155
set -o pipefail

if [ ! "${CONFIGURATION}" ]; then
    CONFIGURATION='Release'
fi

SCRIPT_DIR="$(dirname "$0")"
# shellcheck source=tools/ready.sh
. "${SCRIPT_DIR}/ready.sh" || exit $?

if [ $# -lt 1 ] || [ -z "$1" ]; then
    echo "run archive and put archive path as 1st argument" >&2
    exit 1
fi

ZIP_PATH="$1/${PACKAGE_NAME}.zip"
PKG_PATH="$1/${PACKAGE_NAME}.pkg"

if [ ! -e "$1" ]; then
    echo "unexisting path: $1" >&2
    exit 1
fi

if [ ! -e "$ZIP_PATH" ] || [ ! -e "$PKG_PATH" ]; then
    echo "The given path doesn't include .zip or .pkg" >&2
    echo "  app: $ZIP_PATH" >&2
    echo "  pkg: $PKG_PATH" >&2
    exit 1
fi

if [ -z "${NOTARY_KEYCHAIN_PROFILE:-}" ]; then
    echo "NOTARY_KEYCHAIN_PROFILE is required" >&2
    exit 1
fi

echo "Notarizing app..."
cmd=(xcrun notarytool submit "${ZIP_PATH}" \
    --keychain-profile "${NOTARY_KEYCHAIN_PROFILE}" --wait)
echo "${cmd[@]}"
"${cmd[@]}"
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
    echo "Notarizing app failed: ${ZIP_PATH}" >&2
    exit "$exit_code"
fi

echo "Notarizing pkg..."
cmd=(xcrun notarytool submit "$PKG_PATH" \
    --keychain-profile "${NOTARY_KEYCHAIN_PROFILE}" --wait)
echo "${cmd[@]}"
"${cmd[@]}"
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
    echo "Notarizing pkg failed: ${PKG_PATH}" >&2
    exit "$exit_code"
fi

echo "Stapling pkg..."
xcrun stapler staple "$PKG_PATH"
exit_code=$?
if [ "$exit_code" -ne 0 ]; then
    echo "Stapling pkg failed: ${PKG_PATH}" >&2
    exit "$exit_code"
fi

mkdir -p ~/Downloads
mv -f "$PKG_PATH" ~/Downloads/
