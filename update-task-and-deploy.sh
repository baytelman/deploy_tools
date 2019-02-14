#!/bin/bash
# Creates aws task, register it to aws and deploy the task to our instances

# Requirements:
#   brew install gettext
#   brew link --force gettext

if [ $NAMED_AWS_CLI ]
then
  export NAMED_PROFILE_AWS=" --profile "${NAMED_AWS_CLI}
else
  export NAMED_PROFILE_AWS=""
fi

printf "\n${BLUE}Creating task: ${PURPLE}$TASK_NAME:$SHA ${NC}\n"
mkdir -p $DIR/tmp
export SECRETS=$(cat $PWD/secrets.$DEPLOY_ENV.jsonpart)
cat $DIR/task-def-tmpl.json | envsubst > $DIR/tmp/task-def-$TASK_NAME.json
export SECRETS=""

printf "\n${BLUE}Registering task: ${PURPLE}$TASK_NAME:$SHA ${NC}\n"
CMD="aws ecs register-task-definition --cli-input-json file://$DIR/tmp/task-def-$TASK_NAME.json $NAMED_PROFILE_AWS"
echo $CMD
$CMD

printf "\n${BLUE}Running latest task: ${PURPLE}$TASK_NAME:$SHA ${NC}\n"
CMD="aws ecs update-service --cluster $CLUSTER_NAME --service $REPO_NAME --task-definition $TASK_NAME $NAMED_PROFILE_AWS"
echo $CMD
$CMD \
    | egrep "status|taskD|clusterArn|serviceArn" \
    | head -4

printf "\n${BLUE}Tagging deployed commit in git and image in the repo: ${PURPLE}$TASK_NAME:$SHA ${NC}\n"
docker push $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPO_NAME:$DEPLOY_ENV

set +e
# Track this unique deploy
git tag --force $TASK_NAME-$SHA >/dev/null
git push origin $TASK_NAME-$SHA > /dev/null

# Track the current deploy
git tag --delete $TASK_NAME > /dev/null
git push --delete origin $TASK_NAME > /dev/null
git tag --force $TASK_NAME >/dev/null
git push origin $TASK_NAME > /dev/null
set -e

printf " \
\n${BLUE}Service: \
\n- ${PURPLE}https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/$CLUSTER_NAME/services/$REPO_NAME/details \
\n${BLUE}Repositories – Cleanup unused images: \
\n- ${PURPLE}https://console.aws.amazon.com/ecs/home?region=us-east-1#/repositories/$REPO_NAME \
\n${NC} "

if [ -n "$SLACK" ]
then
	curl -s -d "{\"text\": \"[FINISHED] $( id -un) deployed $CLUSTER_NAME ($BRANCH:#$SHA)\"}" -X POST $SLACK > /dev/null
fi