#!/bin/bash
# Creates tag and deploy current SHA

# Requirements:
#   brew install gettext
#   brew link --force gettext

BLUE='\033[1;34m'
PURPLE='\033[1;35m'
NC='\033[0m' # No Color

export SHA=$(git log --pretty=format:'%h' -n 1)
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export APP_NAME="$CLUSTER_NAME-$REPO_NAME"
export TASK_NAME="$REPO_NAME-$DEPLOY_ENV"

if [ $NAMED_AWS_CLI ]
then
  export NAMED_PROFILE_AWS=" --profile "${NAMED_AWS_CLI}
else
  export NAMED_PROFILE_AWS=""
fi

export ENVIRONMENTS="production|development"

MAX_ACTIVE_TASKS=10
printf "\n${BLUE}Deregistering old task-definitions: ${PURPLE}$TASK_NAME:$SHA ${NC}\n"
aws ecs list-task-definitions --family-prefix $TASK_NAME --sort DESC | \
    grep $TASK_NAME | tail -n +$MAX_ACTIVE_TASKS | sed 's/"//g' | sed 's/,//g' | \
    while read -r line; do
        echo "Deregistering $line";
        IGNORE=$(aws ecs deregister-task-definition --task-definition $line);
    done;

printf "\n${BLUE}Deleting unused images (not tagged $ENVIRONMENTS): ${PURPLE}$TASK_NAME:$SHA ${NC}\n"
LIST_IMAGES=$(      aws ecr list-images --repository-name $REPO_NAME | tr '\n,' '@' | sed 's/", *"imageTag/--/g' )
ACTIVE_IMAGES=$(    echo $LIST_IMAGES | tr '}' '\n' | grep sha | egrep -h "$ENVIRONMENTS" | sed 's/.*sha256:\([a-z0-9]*\).*/\1/g' | sort)
ALL_IMAGES=$(       echo $LIST_IMAGES | tr '}' '\n' | grep sha | sed 's/.*sha256:\([a-z0-9]*\).*/\1/g' | sort)
INACTIVE_IMAGES=$(  echo $ALL_IMAGES | tr ' ' '\n' | egrep -v $(echo $ACTIVE_IMAGES | tr ' ' '|') )

echo $INACTIVE_IMAGES | tr ' ' '\n' | \
    while read -r line; do
        echo "Deleting $line";
        IGNORE=$(aws ecr batch-delete-image --repository-name $REPO_NAME --image-ids imageDigest=sha256:$line);
    done;
