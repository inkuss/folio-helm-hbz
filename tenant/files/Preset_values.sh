#!/bin/bash

cd `dirname $0`

OKAPICLI="../OkapiCLI.py --url $OKAPI_URL --username $ADMIN_USERNAME --password $ADMIN_PASSWORD --tenant $TENANT"

# usage create_json id name with_source
function create_json() {
SOURCE=',
  "source": "local"'
if [ "$3" == "false" ] ; then
    SOURCE=""
  fi
  echo '{
  "id": "'${1}'",
  "name": "'${2}'"'$SOURCE'
}'
}


# usage update_reference_data APIEndpint with_source
function update_reference_data() {
cat ${1}.txt | while read x y ; do 
if OUT=`$OKAPICLI raw -r "/${1}/$x"` ; then
  echo "$1 Id $x already there"
  NAME=`echo "$OUT" |jq .name`
  if [ "$NAME" != "\"$y\"" ] ; then
    echo "Name mismatch: $NAME - \"$y\" - fixing"
    create_json $x "$y" $2
    create_json $x "$y" $2 | $OKAPICLI -v raw -r "/${1}/${x}" -m put
  fi
else
  echo "Creating $1 $x $y"
  create_json $x "$y" $2 | $OKAPICLI -v raw -r "/${1}" -m post
fi
done
}

# check if we are ready
if $OKAPICLI -v raw -r "/material-types" ; then 
  update_reference_data item-note-types
  update_reference_data instance-note-types
  update_reference_data alternative-title-types
  update_reference_data loan-types false
  update_reference_data material-types
  # Contributor Types hat name und code, in dem xsl ist nur der code angegeben
  # update_reference_data contributor-types
  # Instance Status hat auch code
  # update_reference_data instance-statuses
  update_reference_data identifier-types
  update_reference_data holdings-types
  # Vorbelegungen Inventory App Incident 211320
  update_reference_data classification-types
  update_reference_data electronic-access-relationships
  update_reference_data holdings-note-types
  



else
  exit 1
fi
