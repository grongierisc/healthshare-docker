#!/bin/bash

# $1 InterSystems IRIS instance
if [ -z "$ISC_PACKAGE_INSTANCENAME" ]; then
  ISC_PACKAGE_INSTANCENAME=IRIS
fi

# verify InterSystems IRIS up and running
line=$(iris qlist $ISC_PACKAGE_INSTANCENAME) 
state=$(echo $line | cut -d '^' -f4 | cut -d ',' -f1)
status=$(echo $line | cut -d '^' -f9)
if [ "$state" != "running" -o "$status" != "ok" ]; then
  exit 1
fi

exit $?
