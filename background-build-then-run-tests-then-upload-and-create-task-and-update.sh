#!/bin/bash
# Builds in background, run tests, builds and uploads container, create tasks and update service

set -e

export DEPLOY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export BLUE='\033[1;34m'
export PURPLE='\033[1;35m'
export NC='\033[0m' # No Color


# Run tests
if [ -z "$SKIP_TESTS" ]
then
  source $DEPLOY_DIR/build-docker.sh >> /dev/null &
  export DOCKER_PROC=$!
  echo "Running background docker-build with proc $DOCKER_PROC..."

  if [ -z "$SKIP_TESTS" ] && [[ "$(docker images -q $REPO_NAME:$SHA 2> /dev/null)" == "" ]]
  then
    printf "\n${BLUE}Running tests: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"
    cd $DIR
    yarn test
    cd -
  else
    printf "\n${BLUE}Image already built – Skipping tests: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"
  fi
else
  printf "\n${BLUE}Skipping tests (ENV): ${PURPLE}$REPO_NAME:$SHA ${NC}\n"
  source $DEPLOY_DIR/build-docker.sh
fi

# Continue deploy
$DEPLOY_DIR/rebuild-and-deploy.sh