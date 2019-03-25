#!/bin/bash
# Builds, tags, and uploads container image
set -e

if [ $DOCKER_HOME ]
then
  cd $DOCKER_HOME
fi

if [[ "$(docker images -q $REPO_NAME-tmp:$SHA 2> /dev/null)" == "" ]]
then
  printf "\n${BLUE}Building image: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"
  BUILD="docker build --compress $DOCKER_ARGS -t $REPO_NAME ."
  BUILD_FOR_ECHO="docker build ... -t $REPO_NAME ."
  echo $BUILD_FOR_ECHO
  eval $BUILD
  docker tag $REPO_NAME $REPO_NAME-tmp:$SHA
else
  printf "\n${BLUE}Image already built: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"
fi
