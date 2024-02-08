#!bin/bash
mc alias set s3server $FILEPULLERURL $FILEPULLERUSER $FILEPULLERPASS
mc mirror --overwrite --watch --remove s3server/$FILEPULLERPATH /data