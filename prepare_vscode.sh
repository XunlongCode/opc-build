#!/usr/bin/env bash
# shellcheck disable=SC1091,2154

set -e

# include common functions
. ./utils.sh

cd vscode || { echo "'vscode' dir not found"; exit 1; }

chmod +x ../update_settings.sh
../update_settings.sh

# apply patches
{ set +x; } 2>/dev/null

echo "APP_NAME=\"${APP_NAME}\""
echo "APP_CODE=\"${APP_CODE}\""
echo "APP_NAME_LC=\"${APP_NAME_LC}\""
echo "BINARY_NAME=\"${BINARY_NAME}\""
echo "GH_REPO_PATH=\"${GH_REPO_PATH}\""
echo "VERSION_REPO_NAME=\"${VERSION_REPO_NAME}\""
echo "ORG_NAME=\"${ORG_NAME}\""

set -x

export ELECTRON_SKIP_BINARY_DOWNLOAD=1
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

if [[ "${OS_NAME}" == "linux" ]]; then
  export VSCODE_SKIP_NODE_VERSION_CHECK=1

   if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
elif [[ "${OS_NAME}" == "windows" ]]; then
  if [[ "${npm_config_arch}" == "arm" ]]; then
    export npm_config_arm_version=7
  fi
fi

mv .npmrc .npmrc.bak
cp ../npmrc .npmrc

for i in {1..5}; do # try 5 times
  npm i && break
  if [[ $i == 3 ]]; then
    echo "Npm install failed too many times" >&2
    exit 1
  fi
  echo "Npm install failed $i, trying again..."

  sleep $(( 15 * (i + 1)))
done

mv .npmrc.bak .npmrc

setpath() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --arg 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

setpath_json() {
  local jsonTmp
  { set +x; } 2>/dev/null
  jsonTmp=$( jq --arg 'path' "${2}" --argjson 'value' "${3}" 'setpath([$path]; $value)' "${1}.json" )
  echo "${jsonTmp}" > "${1}.json"
  set -x
}

# package.json
cp package.json{,.bak}

setpath "package" "version" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\1/p" )"
setpath "package" "release" "$( echo "${RELEASE_VERSION}" | sed -n -E "s/^(.*)\.([0-9]+)(-insider)?$/\2/p" )"

# announcements
replace "s|\\[\\/\\* BUILTIN_ANNOUNCEMENTS \\*\\/\\]|$( tr -d '\n' < ../announcements-builtin.json )|" src/vs/workbench/contrib/welcomeGettingStarted/browser/gettingStarted.ts

chmod +x ../undo_telemetry.sh
../undo_telemetry.sh

if [[ "${OS_NAME}" == "linux" ]]; then
  # microsoft adds their apt repo to sources
  # unless the app name is code-oss
  # as we are renaming the application to ${BINARY_NAME}
  # we need to edit a line in the post install template
  if [[ "${VSCODE_QUALITY}" == "insider" ]]; then
    sed -i "s/code-oss/${BINARY_NAME}-insiders/" resources/linux/debian/postinst.template
  else
    sed -i "s/code-oss/${BINARY_NAME}/" resources/linux/debian/postinst.template
  fi

  # fix the packages metadata
  # code.appdata.xml
  sed -i "s|Visual Studio Code|${APP_NAME}|g" resources/linux/code.appdata.xml
  sed -i "s|https://code.visualstudio.com/docs/setup/linux|https://github.com/${GH_REPO_PATH}#download-install|" resources/linux/code.appdata.xml
  sed -i "s|https://code.visualstudio.com/home/home-screenshot-linux-lg.png|https://${BINARY_NAME}.com/img/${BINARY_NAME}.png|" resources/linux/code.appdata.xml
  sed -i "s|https://code.visualstudio.com|https://${BINARY_NAME}.com|" resources/linux/code.appdata.xml

  # control.template
  sed -i "s|Microsoft Corporation <vscode-linux@microsoft.com>|${APP_NAME} Team https://github.com/${GH_REPO_PATH}/graphs/contributors|"  resources/linux/debian/control.template
  sed -i "s|Visual Studio Code|${APP_NAME}|g" resources/linux/debian/control.template
  sed -i "s|https://code.visualstudio.com/docs/setup/linux|https://github.com/${GH_REPO_PATH}#download-install|" resources/linux/debian/control.template
  sed -i "s|https://code.visualstudio.com|https://${BINARY_NAME}.com|" resources/linux/debian/control.template

  # code.spec.template
  sed -i "s|Microsoft Corporation|${APP_NAME} Team|" resources/linux/rpm/code.spec.template
  sed -i "s|Visual Studio Code Team <vscode-linux@microsoft.com>|${APP_NAME} Team https://github.com/${GH_REPO_PATH}/graphs/contributors|" resources/linux/rpm/code.spec.template
  sed -i "s|Visual Studio Code|${APP_NAME}|" resources/linux/rpm/code.spec.template
  sed -i "s|https://code.visualstudio.com/docs/setup/linux|https://github.com/${GH_REPO_PATH}#download-install|" resources/linux/rpm/code.spec.template
  sed -i "s|https://code.visualstudio.com|https://${BINARY_NAME}.com|" resources/linux/rpm/code.spec.template

  # snapcraft.yaml
  sed -i "s|Visual Studio Code|${APP_NAME}|"  resources/linux/rpm/code.spec.template
elif [[ "${OS_NAME}" == "windows" ]]; then
  # code.iss
  sed -i 's|https://code.visualstudio.com|https://vscodium.com|' build/win32/code.iss
  sed -i "s|Microsoft Corporation|${APP_NAME}|" build/win32/code.iss
fi

cd ..
