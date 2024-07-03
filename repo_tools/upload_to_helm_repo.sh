#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No arguments supplied, need source git branch!"
    exit 1
fi

HELM_REPO_DST="notset"
if [ "$1" = "main" ]
  then
    echo "git main branch, setting helm branch to stable";
    HELM_REPO_DST="stable"
else
    echo "setting helm branch to $1";
    HELM_REPO_DST=$1
fi

echo "Creating Helm Archives"

for i in modules okapi okapicli secure-supertenant tenant zalando-pg vufind zalando-vufind-pg b3katimport lib-bvb-folio; do
  helm package ../$i
done

echo "Uploading"

username=gitlab-ci-token
password=$CI_JOB_TOKEN

for i in backups*.tgz edge*.tgz modules*.tgz okapi*.tgz secure-supertenant*.tgz tenant*.tgz zalando-pg*.tgz vufind*.tgz zalando-vufind-pg*.tgz b3katimport*.tgz lib-bvb-folio*.tgz; do
   curl --request POST --user "$username:$password" --form "chart=@$i" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/api/${HELM_REPO_DST}/charts"
   echo
done

echo "Deleting local Helm Archives"
rm *.tgz
