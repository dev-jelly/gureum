#!/bin/bash
#https://discuss.atom.io/t/sandbox-supposedly-enabled-but-application-loader-disagrees/26155
set -o pipefail

if [ ! "${CONFIGURATION}" ]; then
    CONFIGURATION='Release'
fi
SCRIPT_DIR="$(dirname "$0")"
# shellcheck source=tools/ready.sh
. "${SCRIPT_DIR}/ready.sh" || exit $?

if [ "${CONFIGURATION}" != 'Release' ]; then
    echo "Configuration is not Release: ${CONFIGURATION}"
    echo "Keep going?"
    read -r
fi

if [ -z "${BUILT_PRODUCTS_DIR:-}" ] || [ "${BUILT_PRODUCTS_DIR}" = "/" ]; then
    echo "error: invalid BUILT_PRODUCTS_DIR='${BUILT_PRODUCTS_DIR}'" >&2
    exit 1
fi
BUILT_PRODUCT_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"

rm -f ~/Downloads/"${PACKAGE_NAME}.pkg"
rm -rf -- "${BUILT_PRODUCT_PATH}"

if command -v xcpretty >/dev/null; then
    PRINTER="xcpretty"
else
    PRINTER="cat"
fi

(xcodebuild -project 'Gureum.xcodeproj' -scheme 'OSX' -destination="{ platform:macOS, name:Any Mac }" -configuration "${CONFIGURATION}" archive | "$PRINTER") && \
    echo "Archive dir path is required for further packaging (try paste)" && echo "Archive directory path>" && read -r archive_dir || \
    exit $?

if [ ! -d "$archive_dir" ]; then
    echo "invalid archive directory: ${archive_dir}" >&2
    exit 1
fi

bash "${SCRIPT_DIR}/notarize_product.sh" "$archive_dir"

