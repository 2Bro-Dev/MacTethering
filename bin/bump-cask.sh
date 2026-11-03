#!/bin/bash
# Check a MacTethering build the way `brew install` will, and keep the cask in
# step with it.
#
#   bin/bump-cask.sh                    # inspect the published DMG
#   bin/bump-cask.sh path/to/Local.dmg  # or a local build, before uploading
#
# While the cask carries `sha256 :no_check` (unversioned download URL) there is
# nothing to bump and this only reports. Once the cask moves to versioned URLs
# it rewrites version and sha256 from the image. Builds that Gatekeeper would
# reject are refused either way: `brew install` runs the same check on every
# user's Mac.
set -euo pipefail

cd "$(dirname "$0")/.."
CASK="Casks/mactethering.rb"
DEFAULT_URL="$(awk -F'"' '/^ *url "/{print $2; exit}' "${CASK}")"
# The cask URL pins a released version. Checking "the current build" means the
# newest one, which GitHub serves under the same asset name via /latest/.
DEFAULT_URL="$(printf '%s' "${DEFAULT_URL}" |
  sed 's|/releases/download/v#{version}/|/releases/latest/download/|')"
SOURCE="${1:-${DEFAULT_URL}}"

TMP="$(mktemp -d)"
MOUNT="${TMP}/mnt"
cleanup() {
  [[ -d "${MOUNT}" ]] && hdiutil detach "${MOUNT}" -force >/dev/null 2>&1
  rm -rf "${TMP}"
}
trap cleanup EXIT

if [[ -f "${SOURCE}" ]]
then
  DMG="${SOURCE}"
else
  DMG="${TMP}/MacTethering.dmg"
  echo "==> Downloading ${SOURCE}"
  curl -fsSL --retry 3 -o "${DMG}" "${SOURCE}"
fi

# A missing file on the site answers 200 with index.html instead of 404, so an
# unchecked download would hand users a web page as their disk image.
if ! hdiutil imageinfo "${DMG}" >/dev/null 2>&1
then
  KIND="$(file -b "${DMG}" || true)"
  echo "error: ${SOURCE} is not a disk image (${KIND})" >&2
  exit 1
fi

mkdir -p "${MOUNT}"
hdiutil attach "${DMG}" -nobrowse -readonly -mountpoint "${MOUNT}" >/dev/null
APP="${MOUNT}/MacTethering.app"
[[ -d "${APP}" ]] || {
  echo "error: no MacTethering.app inside the image" >&2
  exit 1
}

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' \
  "${APP}/Contents/Info.plist")"
SHA="$(shasum -a 256 "${DMG}" | cut -d' ' -f1)"

GATEKEEPER="notarised"
ASSESS="$(spctl --assess --type exec -vv "${APP}" 2>&1 || true)"
if ! grep -q 'source=Notarized Developer ID' <<<"${ASSESS}"
then
  GATEKEEPER="NOT notarised"
  echo "${ASSESS}" >&2
  if [[ "${ALLOW_UNNOTARIZED:-}" != "1" ]]
  then
    echo "error: build is not notarised; brew install would fail Homebrew's" >&2
    echo "       Gatekeeper check. Rebuild with CODESIGN_ID and" >&2
    echo "       NOTARIZE_PROFILE set, or re-run with ALLOW_UNNOTARIZED=1." >&2
    exit 1
  fi
  echo "warning: continuing with an unnotarised build" >&2
fi

echo "==> MacTethering ${VERSION}, ${GATEKEEPER}, sha256 ${SHA}"

if grep -q '^  sha256 :no_check' "${CASK}"
then
  echo "    cask tracks the unversioned URL; nothing to rewrite"
  exit 0
fi

/usr/bin/sed -i '' \
  -e "s|^  version \".*\"|  version \"${VERSION}\"|" \
  -e "s|^  sha256 \".*\"|  sha256 \"${SHA}\"|" \
  "${CASK}"

command -v brew >/dev/null && brew style "${CASK}" >/dev/null

echo "==> ${CASK} updated"
git --no-pager diff -- "${CASK}"
