#!/bin/bash
GITURL=${FILEPULLERURL/\/\//\/\/${FILEPULLERUSER}:${FILEPULLERPASS}@}
git clone $GITURL --branch ${FILEPULLERBRANCH} /data
cd /data
while git pull ; do
    sleep $FILEPULLERSLEEP
done    
