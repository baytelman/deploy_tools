#!/bin/bash
# Builds, tags, and uploads container image
set -e

if [ $DOCKER_HOME ]
then
  cd $DOCKER_HOME
fi

if [[ "$(docker images -q $REPO_NAME:$SHA 2> /dev/null)" == "" ]]
then
  BUILD="docker build --compress $DOCKER_ARGS -t $REPO_NAME ."
  BUILD_FOR_ECHO="docker build ... -t $REPO_NAME ."
  echo $BUILD_FOR_ECHO
  eval $BUILD
else
  printf "\n${BLUE}Image already built: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"
fi
