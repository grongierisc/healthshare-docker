#!/bin/bash

# This script is run as part of the "docker build" process.  It is intended to
# be run as root, much like irisinstall_silent. For best results, your
# Dockerfile should call irisinstall_silent and imageBuildSteps.sh in the same
# RUN layer (along with any other commands that might modify IRIS.DAT files)
# and shortly after calling this script your Dockerfile should change its USER.
#
# RUN irisinstall_silent && imageBuildSteps.sh
# USER $ISC_PACKAGE_MGRUSER
#
# For sample Dockerfiles, including InterSystems' own, please see
# https://github.com/intersystems/container-tools

main() {
  # Make sure we have environment variables we need.
  precondition_checks;

  # We're probably running as root, so any status files, sentinel files,
  # log files, etc will not be writeable by anyone else.  Let's chdir to
  # our home directory, so we don't leave anyone else a mess they can't
  # clean up.
  cd "$HOME"

  # Make sure IRIS is down.
  ensure_iris_stopped;
  
  # Bring IRIS up in single-user mode.  This will allow us to open
  # an IRIS session without requiring us to encode a password here.
  # Not all features are available in this mode, but it is suitable
  # for most maintenance tasks.
  start_iris_single_user;

  # Tell SYS.Container whether or not to terminate on error. Syntax errors
  # or ObjectScript functions failing does not alter the exit code of an
  # "iris session" process, but SYS.Container will exit(1), unless it is
  # told to continue on error.
  # Useful for figuring out *if* something went wrong.
  # The default is to terminate.  Set this variable to 1 to change that.
  #export SYS_CONTAINER_CONTINUE_ON_ERROR=1

  # Tell SYS.Container whether or not to print errors.
  # Useful for figuring out *what* went wrong.
  # The default is to print errors.  Set this variable to 1 to change that.
  #export SYS_CONTAINER_QUIET=1

  # Run routine or class method in %SYS.
  # Note that this is equivalent to a copy/paste into an iris session prompt,
  # which does not allow blocks which span multiple lines.
  # If your ObjectScript does not include SYS.Container methods, you are
  # responsible for setting your own exit code.
  ObjectScript='do ##class(SYS.Container).QuiesceForBundling() halt'
  runObjectScriptSingleUser "$ObjectScript"

  # Do not requirer Password change
  ObjectScript='Do ##class(Security.Users).UnExpireUserPasswords("*") halt'
  runObjectScriptSingleUser "$ObjectScript"

  # Bring the system down cleanly
  ensure_iris_stopped_single_user;

  # Some files are needed for durability guarantees when the system is
  # operating, but if we know we've stopped cleanly, they're unnecesary.
  # Removing them reduces the size of our Docker image.
  remove_WIJ;
  remove_journals;
  
  # If the IRISSYS environnment variable is set, we have changes to make to
  # ISCAgent. See "Installing as a Nonroot User" in the IRIS documentation
  # for more information about the IRISSYS environment variable.
  if [ -n "$IRISSYS" ]; then
    set_iscagent_groups
  fi

  set_permissions_container_utilities;

  return 0
}


precondition_checks() {
  if [ $UID -ne 0 ]; then
    error "This script is unlikely to work if you are not root."
  fi
  # IRIS images are expected to have all of the following environment
  # variables defined in the container at all times.
  assert_defined "ISC_PACKAGE_INSTANCENAME"
  assert_defined "ISC_PACKAGE_INSTALLDIR"
  assert_defined "ISC_PACKAGE_MGRUSER"
  assert_defined "ISC_PACKAGE_MGRGROUP"
  assert_defined "ISC_PACKAGE_IRISUSER"
  assert_defined "ISC_PACKAGE_IRISGROUP"

  if [ -n "$IRISSYS" ]; then
    test -d "$IRISSYS"
    exit_if_error "If IRISSYS is defined, it must be a valid directory"
  fi
}


assert_defined() {
  [[ -z "${!1}" ]] && echo "Environment variable $1 not set" && exit 1
}

exit_if_error() {
  if [ $(($(echo "${PIPESTATUS[@]}" | tr -s ' ' +))) -ne 0 ]; then
    error "$1"
    exit 1
  fi
}

error() {
  printf "%s Error: $1\n" $(date '+%Y%m%d-%H:%M:%S:%N')
}

# If IRIS is up, we bring it down and verify this.
# If IRIS is already down, this will be very fast.
ensure_iris_stopped() {
  assert_defined "ISC_PACKAGE_INSTANCENAME"
  assert_defined "ISC_PACKAGE_INSTALLDIR"

  iris stop "$ISC_PACKAGE_INSTANCENAME" quietly "$1"
  exit_if_error "Could not stop $ISC_PACKAGE_INSTANCENAME"
  "$ISC_PACKAGE_INSTALLDIR"/dev/Cloud/ICM/waitISC.sh "$ISC_PACKAGE_INSTANCENAME" 60 "down"
  exit_if_error "Could not stop $ISC_PACKAGE_INSTANCENAME"
}

# Start IRIS in single-user mode.  For more about this mode, see the
# System Administration Guide: "Controlling an InterSystems IRIS Instance" 
start_iris_single_user() {
  assert_defined "ISC_PACKAGE_INSTANCENAME"
  assert_defined "ISC_PACKAGE_INSTALLDIR"

  iris start "$ISC_PACKAGE_INSTANCENAME" nostu
  "$ISC_PACKAGE_INSTALLDIR"/dev/Cloud/ICM/waitISC.sh "$ISC_PACKAGE_INSTANCENAME" 60 "sign-on inhibited"
  exit_if_error "Could not start $ISC_PACKAGE_INSTANCENAME in single-user mode"
}

# Stop IRIS when it is in single-user mode.
ensure_iris_stopped_single_user() {
  ensure_iris_stopped "bypass"
}

# Run ObjectScript in single-user mode.  We will always start in %SYS,
# and not all system features will be available.
# Single-user mode is especially useful for bootstrapping code that enables
# OS Authentication.
runObjectScriptSingleUser() {
  assert_defined "ISC_PACKAGE_INSTANCENAME"

  echo "$1" | iris session "$ISC_PACKAGE_INSTANCENAME" -B
  exit_if_error "ObjectScript payload failed!  Payload was:\n$1"
}

# Remove WIJ
# The WIJ is necessary for normal operation and durability, but if the
# system has stopped properly then we have no need of it and can remove
# it safely.
remove_WIJ() {
  assert_defined "ISC_PACKAGE_INSTALLDIR"

  # We don't rm with -f here, because this function should only be called
  # when there is a WIJ to remove.
  rm "$ISC_PACKAGE_INSTALLDIR"/mgr/IRIS.WIJ
  exit_if_error "Could not remove WIJ"
}

# Remove all journal files
# Journal files are necessary for normal operation and durability, but if the
# system has stopped properly then we have no need of them and can remove
# them safely.
remove_journals() {
  assert_defined "ISC_PACKAGE_INSTALLDIR"

  # Journal files will not exist if we've only run in single-user mode,
  # and this is okay, so we rm with -f
  rm -f "$ISC_PACKAGE_INSTALLDIR"/mgr/journal/* 
  exit_if_error "Could not remove journal files"
}

# ISCAgent in user mode needs to be able to write to the IRISSYS directory,
# so we give irisowner permissions to do so.  We also make the user
# part of the "iscagent" group to allow it to function fully.
set_iscagent_groups() {
  assert_defined "ISC_PACKAGE_MGRUSER"
  assert_defined "ISC_PACKAGE_MGRGROUP"
  assert_defined "IRISSYS"

  test -d "$IRISSYS"
  exit_if_error "If IRISSYS is defined, it must be a valid directory"

  chown root:"$ISC_PACKAGE_MGRGROUP" "$IRISSYS"
  exit_if_error "Could not chown $IRISSYS"
  chmod 775 "$IRISSYS"
  exit_if_error "Could not chmod $IRISSYS"
  usermod -a -G iscagent "$ISC_PACKAGE_MGRUSER"
  exit_if_error "Could not add $ISC_PACKAGE_MGRUSER to iscagent group"
}

set_permissions_container_utilities() {
  assert_defined "ISC_PACKAGE_MGRUSER"
  assert_defined "ISC_PACKAGE_MGRGROUP"
  assert_defined "ISC_PACKAGE_INSTALLDIR"

  # This enables sessions owned by $ISC_PACKAGE_MGRUSER to run irisstat.
  chown "$ISC_PACKAGE_MGRUSER":"$ISC_PACKAGE_MGRGROUP"  "$ISC_PACKAGE_INSTALLDIR"/bin/irisstat
  exit_if_error "Could not chown $ISC_PACKAGE_INSTALLDIR/bin/irisstat"
}

main
exit $?