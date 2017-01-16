#!/bin/bash
#QUEUE_URL="https://us-west-2.queue.amazonaws.com/038072554641/git"
QUEUE_URL="https://ap-northeast-1.queue.amazonaws.com/038072554641/git"
REGION=ap-northeast-1

REPOS=$1

if [ -z $REPOS ] || [ -z $(echo $REPOS |grep '^git@.*git$') ]
then
  echo "USAGE $0 {GIT REPOSITORY URI}"
  exit
fi

aws sqs --region ${REGION} send-message \
--queue-url "$QUEUE_URL" \
--message-body "$1"

