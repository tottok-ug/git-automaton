#!/bin/bash
QUEUE_URL="https://ap-northeast-1.queue.amazonaws.com/038072554641/git"
REGION=ap-northeast-1

if [ -z "$(cat ~/.ssh/known_hosts | grep 'NajEM4cVt7OjWLntNK7bO0AC2C8=')" ]
then
echo "|1|VcISOMaZo0Ed8BSSAry7tUrvC8U=|kRMcwGuMZXSVuU1UJK9s3tIqppg= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
|1|NajEM4cVt7OjWLntNK7bO0AC2C8=|Fm97/AW4+wCoX/u1jrhV1PF+fwc= ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=="  >> ~/.ssh/known_hosts
fi
while :
do 

MESSAGE=$(aws sqs --region $REGION receive-message \
--queue-url "$QUEUE_URL" \
--max-number-of-messages 1)

if [ -z "${MESSAGE}" ]
then
  echo "no message wait 120 sec. "
  sleep 1 
  continue
fi

RECEIPT_HANDLE=$(echo $MESSAGE |jq -r .Messages[0].ReceiptHandle)
BODY=$(echo $MESSAGE |jq -r .Messages[0].Body )
HOST=$(echo $BODY |perl -pe "s|git\@(.*?):(.*?)/(.*?).git|\1|g")
ORG=$(echo $BODY |perl -pe "s|git\@(.*?):(.*?)/(.*?).git|\2|g")
REPOS=$(echo $BODY |perl -pe "s|git\@(.*?):(.*?)/(.*?).git|\3|g")

S3BASEPATH="s3://commit-log/${HOST}/${ORG}/${REPOS}"

OLD_IFS=$IFS
[ -d ./repos/${HOST}/${ORG} ] || mkdir -p ./repos/${HOST}/${ORG}
pushd ./repos/${HOST}/${ORG} > /dev/null
  git clone $BODY
  mkdir -p ./${REPOS}.commit
  pushd $REPOS > /dev/null
  git log --all  --decorate \
    -n 99999999999999999999  --no-merges \
    --format='%H,"%cn","%ce","%ad","%s"' > ../${REPOS}.commit/$REPOS.log
  IFS='
'
  PREID=""
  for c in $(cat ../${REPOS}.commit/${REPOS}.log);
  do
    ID=$(echo $c |cut -d',' -f1)
    if [ ! -z "${PREID}" ];
    then
      echo $c > ../${REPOS}.commit/${ID}
      git diff ${ID} ${PREID} >> ../${REPOS}.commit/${ID}
      aws s3 cp ../${REPOS}.commit/${ID} ${S3BASEPATH}/${HOST}/${ORG}/${REPOS}/${ID}
#      rm "../${REPOS}.commit/${ID}"
    fi
    PREID=$ID
  done
  IFS=${OLD_IFS}
  popd > /dev/null
  rm -rf ${REPOS}
#  rm -rf ${REPOS}.commit/${REPOS}.log ${REPOS}
popd > /dev/null
# Messageの削除
aws sqs --region ${REGION} delete-message \
    --queue-url "$QUEUE_URL" \
    --receipt-handle "${RECEIPT_HANDLE}"

done
