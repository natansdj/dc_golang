#!/bin/bash
#
if [ -z "$GO_SVC" ]
then
  echo "Empty GO_SVC!!!"
  exit 1
fi

#
WORKDIR="/go/src/${GO_SVC}"

#
if [ -z "$WORKDIR" ]; then
    echo "Empty WORKDIR!!!"
    exit 1
fi

if [ -z "$GOBIN" ]; then
    GOBIN=$GOPATH/bin
fi

if [ -z "$ENV" ]; then
    ENV="dev"
fi

if [ -z "$TARGET_GOOS" ]; then
  TARGET_GOOS="linux"
fi

if [ -z "$TARGET_GOARCH" ]; then
  TARGET_GOARCH="$(go env GOARCH)"
fi

if [ -z "$GO_BUILD_PATH" ]; then
  GO_BUILD_PATH="."
fi

if [ -z "$GO_BUILD_OUTPUT" ]; then
  GO_BUILD_OUTPUT=".svc-bin"
fi

#
if ! cd "$WORKDIR"; then
  exit 1
fi
echo "WORKDIR : ${WORKDIR}"
echo "GO_SVC : ${GO_SVC}"
echo "ENV : ${ENV}"

echo "## go mod..."
go mod download

if [ -z "$DOCKER_UID" ]; then
  echo "## empty DOCKER_UID skip atribute update..."
else
  echo "## update file & folder attributes"
  chown -R ${DOCKER_UID}:${DOCKER_GID} .
fi

#
if [ "$ENV" == "local" ]; then
  echo "## build & watch"
  # $GOBIN/bee run
  CGO_ENABLED=0 GOOS=${TARGET_GOOS} GOARCH=${TARGET_GOARCH} go build -o "${GO_BUILD_OUTPUT}" "${GO_BUILD_PATH}" && ./${GO_BUILD_OUTPUT}
elif [ "$ENV" == "dev" ] || [ "$ENV" == "staging" ]; then
  echo "## build & start go service"
  CGO_ENABLED=0 GOOS=${TARGET_GOOS} GOARCH=${TARGET_GOARCH} go build -o "${GO_BUILD_OUTPUT}" "${GO_BUILD_PATH}" && ./${GO_BUILD_OUTPUT}
else
  echo "## start go service"
  ./${GO_SVC}
fi
