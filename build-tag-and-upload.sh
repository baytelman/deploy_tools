#!/bin/bash
# Builds, tags, and uploads container image
set -e

if [ $NAMED_AWS_CLI ]
then
  export NAMED_PROFILE_AWS=" --profile "${NAMED_AWS_CLI}
else
  export NAMED_PROFILE_AWS=""
fi

if [[ "$(docker images -q $REPO_NAME:$SHA 2> /dev/null)" == "" ]]
then
  printf "\n${BLUE}Building image: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"
  BUILD="docker build $DOCKER_ARGS -t $REPO_NAME ."
  echo $BUILD
  eval $BUILD
  docker tag $REPO_NAME $REPO_NAME:$SHA
else
  printf "\n${BLUE}Image already built: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"
fi

printf "\n${BLUE}Tagging image: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"
docker tag $REPO_NAME $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:latest
docker tag $REPO_NAME $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:$DEPLOY_ENV
docker tag $REPO_NAME $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:$SHA

printf "\n${BLUE}Pushing image: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"

eval $(aws ecr get-login --no-include-email --region us-east-1)

docker push $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:latest
docker push $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:$DEPLOY_ENV
docker push $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:$SHA