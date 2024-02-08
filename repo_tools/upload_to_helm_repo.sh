#!/bin/bash

echo "Creating Helm Archives"

for i in backups edge modules okapi okapicli secure-supertenant tenant zalando-pg vufind zalando-vufind-pg b3katimport; do
  helm package ../$i
done

echo "Uploading"

username=gitlab-ci-token
password=$CI_JOB_TOKEN

for i in backups*.tgz edge*.tgz modules*.tgz okapi*.tgz secure-supertenant*.tgz tenant*.tgz zalando-pg*.tgz vufind*.tgz zalando-vufind-pg*.tgz b3katimport*.tgz ; do
   curl --request POST --user "$username:$password" --form "chart=@$i" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/helm/api/stable/charts"
   echo
done

echo "Deleting local Helm Archives"
rm *.tgz
