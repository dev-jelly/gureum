#!/bin/bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PACKAGE_VERSION="1.0-test"
PACKAGE_NAME="Gureum-${PACKAGE_VERSION}"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gureum-notary-test.XXXXXX")"

cleanup() {
    find "$TEST_ROOT" -depth -delete
}
trap cleanup EXIT

fail() {
    echo "notarize_product_test: $*" >&2
    exit 1
}

assert_equal() {
    if [ "$1" != "$2" ]; then
        fail "expected '$1' to equal '$2'"
    fi
}

FAKE_BIN="${TEST_ROOT}/bin"
mkdir -p "$FAKE_BIN"

cat > "${FAKE_BIN}/xcodebuild" <<'EOF'
#!/bin/bash
echo "export PRODUCT_NAME=Gureum"
EOF

cat > "${FAKE_BIN}/xcrun" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "${NOTARY_TEST_LOG}"

if [ "$1" = "notarytool" ] && [ "$2" = "submit" ]; then
    case "$3" in
        *.zip)
            [ "${NOTARY_TEST_FAILURE:-}" = "zip" ] && exit "${NOTARY_TEST_STATUS}"
            ;;
        *.pkg)
            [ "${NOTARY_TEST_FAILURE:-}" = "pkg" ] && exit "${NOTARY_TEST_STATUS}"
            ;;
    esac
elif [ "$1" = "stapler" ] && [ "$2" = "staple" ]; then
    [ "${NOTARY_TEST_FAILURE:-}" = "staple" ] && exit "${NOTARY_TEST_STATUS}"
fi

exit 0
EOF

cat > "${FAKE_BIN}/cat" <<EOF
#!/bin/bash
if [ "\$1" = "OSX/Version.xcconfig" ]; then
    echo "VERSION = ${PACKAGE_VERSION}"
else
    /bin/cat "\$@"
fi
EOF

chmod +x "${FAKE_BIN}/cat" "${FAKE_BIN}/xcodebuild" "${FAKE_BIN}/xcrun"

run_case() {
    name="$1"
    failure="$2"
    failure_status="$3"
    expected_status="$4"
    expected_calls="$5"

    case_root="${TEST_ROOT}/${name}"
    archive="${case_root}/archive"
    home="${case_root}/home"
    temp="${case_root}/tmp"
    log="${case_root}/xcrun.log"
    mkdir -p "$archive" "$home" "$temp"
    touch "${archive}/${PACKAGE_NAME}.zip" "${archive}/${PACKAGE_NAME}.pkg"

    set +e
    HOME="$home" \
        TMPDIR="$temp" \
        PATH="${FAKE_BIN}:${PATH}" \
        CONFIGURATION=Release \
        NOTARY_KEYCHAIN_PROFILE=test-profile \
        NOTARY_TEST_LOG="$log" \
        NOTARY_TEST_FAILURE="$failure" \
        NOTARY_TEST_STATUS="$failure_status" \
        bash "${REPO_ROOT}/tools/notarize_product.sh" "$archive" >/dev/null 2>&1
    status=$?
    set -e

    assert_equal "$expected_status" "$status"
    actual_calls="$(sed "s#${archive}#ARCHIVE#g" "$log")"
    assert_equal "$expected_calls" "$actual_calls"

    if [ "$expected_status" -eq 0 ]; then
        [ ! -e "${archive}/${PACKAGE_NAME}.pkg" ] || fail "success left pkg in archive"
        [ -e "${home}/Downloads/${PACKAGE_NAME}.pkg" ] || fail "success did not move pkg"
    else
        [ -e "${archive}/${PACKAGE_NAME}.pkg" ] || fail "failure advanced to package movement"
        [ ! -e "${home}/Downloads/${PACKAGE_NAME}.pkg" ] || fail "failure moved package"
    fi
}

zip_call="notarytool submit ARCHIVE/${PACKAGE_NAME}.zip --keychain-profile test-profile --wait"
pkg_call="notarytool submit ARCHIVE/${PACKAGE_NAME}.pkg --keychain-profile test-profile --wait"
staple_call="stapler staple ARCHIVE/${PACKAGE_NAME}.pkg"

run_case zip_failure zip 17 17 "$zip_call"
run_case pkg_failure pkg 23 23 "${zip_call}
${pkg_call}"
run_case staple_failure staple 31 31 "${zip_call}
${pkg_call}
${staple_call}"
run_case success "" 0 0 "${zip_call}
${pkg_call}
${staple_call}"

echo "notarize_product_test: passed"
