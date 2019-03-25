#!/bin/bash
# Builds, tags, uploads and deploy current directory

if [ "$DEPLOY_ENV" != "development" ] && [ "$DEPLOY_ENV" != "load" ] && [ "$DEPLOY_ENV" != "production" ]
then
	echo "Unknown environment type specified: '$DEPLOY_ENV'. Supported types: development/production.";
	exit;
fi

if [ -n "$SLACK" ]
then
	curl -s -d "{\"text\": \"[STARTED] $( id -un) is deploying $TASK_NAME ($BRANCH:#$SHA)...\"}" -X POST $SLACK > /dev/null
fi

if [ $DOCKER_PROC ]
then
	while kill -0 $DOCKER_PROC 2> /dev/null
	do
		echo "Background docker-build: $DOCKER_PROC is still running"
		sleep 1
	done
	echo "Background docker-build: $DOCKER_PROC has finished"
fi

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/build-tag-and-upload.sh
source $DIR/update-task-and-deploy.sh
# source $DIR/cleanup.sh

DEPLOYED=false
WAIT=1
if [ $LIVE_URL ]
then
	echo "Checking for \"${SHA}\" in ${LIVE_URL} :"
	while [ ${DEPLOYED} != true ]
	do
		if curl -s -i  "$LIVE_URL" | grep "$SHA"
		then
			DEPLOYED=true
			echo "\"${SHA}\" found in ${LIVE_URL} !"
		else
			echo "Waiting (${WAIT}s) for \"${SHA}\" in ${LIVE_URL} ..."
			sleep $WAIT
			WAIT=$((1 + $WAIT))
		fi
	done

	if [ -n "$SLACK" ]
	then
		curl -s -d "{\"text\": \"[VALIDATED] $( id -un) deployed $TASK_NAME ($BRANCH:#$SHA)\"} – LIVE" -X POST $SLACK > /dev/null
	fi
fi
