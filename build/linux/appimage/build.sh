#!/usr/bin/env bash

set -ex

CALLER_DIR=$( pwd )

APP_NAME="OrangePi Code"
BINARY_NAME="orangepicode"

cd "$( dirname "${BASH_SOURCE[0]}" )"

if [[ "${VSCODE_ARCH}" == "x64" ]]; then
  GITHUB_RESPONSE=$( curl --silent --location "https://api.github.com/repos/AppImage/pkg2appimage/releases/latest" )
  APPIMAGE_URL=$( echo "${GITHUB_RESPONSE}" | jq --raw-output '.assets | map(select( .name | test("x86_64.AppImage(?!.zsync)"))) | map(.browser_download_url)[0]' )

  if [[ -z "${APPIMAGE_URL}" ]]; then
    echo "The url for pkg2appimage.AppImage hasn't been found"
    exit 1
  fi

  wget -c "${APPIMAGE_URL}" -O pkg2appimage.AppImage

  chmod +x ./pkg2appimage.AppImage

  ./pkg2appimage.AppImage --appimage-extract && mv ./squashfs-root ./pkg2appimage.AppDir

  # add update's url
  sed -i "s/generate_type2_appimage/generate_type2_appimage -u 'gh-releases-zsync|${APP_NAME}|${BINARY_NAME}|latest|*.AppImage.zsync'/" pkg2appimage.AppDir/AppRun

  # remove check so build in docker can succeed
  sed -i 's/grep docker/# grep docker/' pkg2appimage.AppDir/usr/share/pkg2appimage/functions.sh

  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s|@@NAME@@|${APP_NAME}-Insiders|g" recipe.yml
    sed -i "s|@@APPNAME@@|${BINARY_NAME}-insiders|g" recipe.yml
    sed -i "s|@@ICON@@|${BINARY_NAME}-insiders|g" recipe.yml
  else
    sed -i "s|@@NAME@@|${APP_NAME}|g" recipe.yml
    sed -i "s|@@APPNAME@@|${BINARY_NAME}|g" recipe.yml
    sed -i "s|@@ICON@@|${BINARY_NAME}|g" recipe.yml
  fi

  # workaround that enforces x86 ARCH for pkg2appimage having /__w/vscodium/vscodium/build/linux/appimage/VSCodium/VSCodium.AppDir/usr/share/codium/resources/app/node_modules/rc/index.js is of architecture armhf
  export ARCH=x86_64
  bash -ex pkg2appimage.AppDir/AppRun recipe.yml

  rm -f pkg2appimage-*.AppImage
  rm -rf pkg2appimage.AppDir
  rm -rf ${APP_NAME}*
fi

cd "${CALLER_DIR}"
