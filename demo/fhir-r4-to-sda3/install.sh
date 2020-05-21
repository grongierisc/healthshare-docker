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

# Source dir to install by source installer
DirSrc=$DIR/src


echo "+-------------------------------------------------+"
echo "|              Now it's show time !               |"
echo "|         iris session going in action            |"
echo "+-------------------------------------------------+"
irissession $instanceName -U USER <<EOF
sys
$2
WRITE "[ OK ] Start a terminal session for the instance $instanceName"


ZN "HSLIB"
WRITE "[ OK ] Set HSLIB namespace as current namespace"

Do ##class(HS.HC.Util.Installer).InstallFoundation("$NameSpace")

zn "$NameSpace" 
WRITE "[ OK ] Set $NameSpace namespace as current namespace"

SET source="$DirSrc"
SET tSc = \$SYSTEM.OBJ.ImportDir(source, "*.cls;*.inc;*.mac", "cubk", .tErrors, 1)
WRITE:(tSc'=1) "[ FAIL ] Import and compile sources: "_\$System.Status.GetErrorText(tSc)
DO:(tSc'=1) \$SYSTEM.Process.Terminate(,1),h
WRITE "[ OK ] Compile sources"

zw ##class(Ens.Director).StartProduction("FHIRTOSDA.Production")
WRITE:(tSc'=1) "[ FAIL ] Start production"
DO:(tSc'=1) \$SYSTEM.Process.Terminate(,1),h
WRITE "[ OK ] Start production"

SET tSc = \$classmethod("Ens.Director", "SetAutoStart", "FHIRTOSDA.Production", 0)
WRITE:(tSc'=1) "[ FAIL ] SetAutoStart production"
DO:(tSc'=1) \$SYSTEM.Process.Terminate(,1),h
WRITE "[ OK ] Production set as default and running for the namespace"

Set ^HS.XF.LookupTable("vR4","SDA3","identifier-type","HS.SDA3.PatientNumber:NumberType","SS") = "SSN"

WRITE "[ OK ] Everything is OK."
halt
EOF
