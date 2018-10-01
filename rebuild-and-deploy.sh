#!/bin/bash
# Builds, tags, uploads and deploy current directory

export SHA=$(git log --pretty=format:'%h' -n 1)
export BRANCH=$(git branch | grep \* | cut -d ' ' -f2)

if [ "$DEPLOY_ENV" != "development" ] && [ "$DEPLOY_ENV" != "production" ]
then
	echo "Unknown environment type specified: '$DEPLOY_ENV'. Supported types: development/production.";
	exit;
fi

if [ -n "$SLACK" ]
then
	curl -s -d "{\"text\": \"[STARTED] $( id -un) is deploying $CLUSTER_NAME ($BRANCH:#$SHA)...\"}" -X POST $SLACK
fi

export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/build-tag-and-upload.sh
source $DIR/update-task-and-deploy.sh
# source $DIR/cleanup.sh

DEPLOYED=false
WAIT=1
if [ $LIVE_URL ]
then
	echo "Checking for \"${SHA}\" in ${LIVE_URL}:"
	while [ ${DEPLOYED} != true ]
	do
		if curl -s -i  "$LIVE_URL" | grep "$SHA"
		then
			DEPLOYED=true
			echo "\"${SHA}\" found in ${LIVE_URL}!"
		else
			echo "Waiting (${WAIT}s) for \"${SHA}\" in ${LIVE_URL}..."
			sleep $WAIT
			WAIT=$((1 + $WAIT))
		fi
	done

	if [ -n "$SLACK" ]
	then
		curl -s -d "{\"text\": \"[VALIDATED] $( id -un) deployed $CLUSTER_NAME ($BRANCH:#$SHA)\"} – LIVE" -X POST $SLACK
	fi
fi
