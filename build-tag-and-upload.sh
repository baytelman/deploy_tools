#!/bin/bash
# Builds, tags, and uploads container image

BLUE='\033[1;34m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color

export SHA=$(git log --pretty=format:'%h' -n 1)
export APP_NAME="$CLUSTER_NAME-$REPO_NAME"
if [ $NAMED_AWS_CLI ]
then
  export NAMED_PROFILE_AWS=" --profile "${NAMED_AWS_CLI}
else
  export NAMED_PROFILE_AWS=""
fi

printf "\n${BLUE}Building image: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"
BUILD="docker build $DOCKER_ARGS -t $REPO_NAME ."
echo $BUILD
eval $BUILD

printf "\n${BLUE}Tagging image: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"
docker tag $REPO_NAME $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:latest
docker tag $REPO_NAME $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:$ENV
docker tag $REPO_NAME $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:$SHA

printf "\n${BLUE}Pushing image: ${PURPLE}$REPO_NAME:$SHA ${NC}\n"

eval $(aws ecr get-login --no-include-email --region us-east-1)

docker push $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:latest
docker push $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:$ENV
docker push $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:$SHA
