#!/bin/bash
set -o pipefail

run_with_echo() {
    echo "$@" && "$@" || exit $?
}

SCRIPT_DIR="$(dirname "$0")"
# shellcheck source=tools/ready.sh
. "${SCRIPT_DIR}/ready.sh" || exit $?

if command -v xcpretty >/dev/null; then
    PRINTER="xcpretty"
else
    PRINTER="cat"
fi

(xcodebuild -project 'Gureum.xcodeproj' -scheme 'OSX' -configuration "${CONFIGURATION}" | $PRINTER) || exit $?
if [ ! "${INSTALL_PATH}" ]; then
    echo "something wrong" && exit 255
fi
# Match uninstall.sh / ScriptSupport: only the system Input Methods path.
if [ "${INSTALL_PATH}" != "/Library/Input Methods" ]; then
    echo "Refusing unexpected INSTALL_PATH: ${INSTALL_PATH}" >&2
    exit 255
fi
if [ "${PRODUCT_NAME}" != "Gureum" ]; then
    echo "Refusing unexpected PRODUCT_NAME: ${PRODUCT_NAME}" >&2
    exit 255
fi

APP_BUNDLE="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
ENTITLEMENTS="OSX/Gureum.entitlements"
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "missing build product: ${APP_BUNDLE}" >&2
    exit 255
fi
if [ ! -f "${ENTITLEMENTS}" ]; then
    echo "missing entitlements: ${ENTITLEMENTS}" >&2
    exit 255
fi

# Source entitlements (not Xcode-internal .xcent layout). Fail closed before sudo install.
/usr/bin/codesign --force --sign - --entitlements "${ENTITLEMENTS}" --timestamp=none "${APP_BUNDLE}" || exit $?

run_with_echo sudo rm -rf "${INSTALL_PATH}/${PRODUCT_NAME}.app"
run_with_echo sudo cp -R "${APP_BUNDLE}" "${INSTALL_PATH}/"
run_with_echo sudo killall -15 "${PRODUCT_NAME}"
