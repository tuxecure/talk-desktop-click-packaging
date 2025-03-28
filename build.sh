#!/bin/bash
REPO_NAME="talk-desktop"
REPO_URL="https://github.com/tuxecure/talk-desktop"
REPO_VERSION="1.1.5a"
APP_TARGET="${REPO_NAME}/out/Nextcloud Talk-linux-arm64"

SPREED_NAME="spreed"
SPREED_URL="https://github.com/nextcloud/spreed"
SPREED_VERSION="21.0.1"

NODE_VERSION="22.2.0"
cleanup () {
  if [ -d "$1" ]; then
    echo "Cleaning up"
    rm -rf "${ROOT}/target"
  fi
}

clone () {
  local repo_dir="$1"

  # check if the cinny repository already exists locally with the required version
  if [ -d "$repo_dir" ]; then
    # if the folder exists, check it has got the required version
    echo "'$1' exists locally in '$repo_dir', going to check version"
    pushd "$repo_dir" > /dev/null  # changes into the repo folder
    local current_version=$(git describe --tags --abbrev=0)
    if [ "$current_version" = "v$2" ]; then
      echo "Repository '$1' in version '$2' exists locally, skip cloning"
      echo "now clearing all unstaged changes"
      git checkout . # undo all unstaged changes so patches are applied freshly
      popd > /dev/null # changes back to root folder
      return 0
    fi
    rm -rf "${repo_dir}"  # if version does not match, clear existing folder
    popd > /dev/null # changes back to root folder
  fi
  # if its not present or the wrong version, clone it
  echo "Cloning source repo"
  git clone "$3" "${repo_dir}" --branch="v${2}"
}

setup_node () {
  echo "Setting up node $NODE_VERSION"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
  nvm install $NODE_VERSION
}

build () {
  echo "Building talk"
  pushd ${ROOT}/${REPO_NAME} > /dev/null
  npm ci
  npm audit fix
  npm ci --prefix=spreed
  npm audit fix
  npm run build:linux:arm64
  popd > /dev/null # changes back to root folder
}

package () {
  echo "Packaging talk"
  ls
  cp -r "${APP_TARGET}" "${ROOT}/target"
  sed -i "s/@CLICK_ARCH@/$ARCH/g" "${ROOT}/manifest.json"
}

cleanup "${ROOT}/${REPO_NAME}"
cleanup "${ROOT}/${REPO_NAME}/${SPREED_NAME}"
setup_node
clone "$ROOT/${REPO_NAME}" ${REPO_VERSION} ${REPO_URL}
clone "${ROOT}/${REPO_NAME}/${SPREED_NAME}" ${SPREED_VERSION} ${SPREED_URL}
build
package
