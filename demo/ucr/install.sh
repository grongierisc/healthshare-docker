#!/bin/bash
# Usage install.sh [instanceName] [password] [namespace]

die () {
    echo >&3 "$@"
    exit 1
}

[ "$#" -eq 3 ] || die "Usage install.sh [instanceName] [password] [Namespace]"

DIR=$(dirname $0)
if [ "$DIR" = "." ]; then
DIR=$(pwd)
fi

instanceName=$1
password=$2
NameSpace=$3

DirSrc=$DIR


echo "+-------------------------------------------------+"
echo "|              Now it's show time !               |"
echo "|         iris session going in action            |"
echo "+-------------------------------------------------+"
irissession $instanceName -U USER <<EOF
sys
$2
WRITE "[ OK ] Start a terminal session for the instance $instanceName"

ZN "$NameSpace"
WRITE "[ OK ] Set $NameSpace namespace as current namespace"

do ##class(HS.Util.Installer).InstallDemo()






WRITE "[ OK ] Everything is OK."
halt
EOF
