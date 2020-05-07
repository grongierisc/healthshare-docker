#--------------------------------------------------------------------
# This Docker manifest file builds a container with:
# - HealthShare 2020.1 for RHEL x64 
# Build final application
# Use docker build --build-arg HS_DIST=HealthShare_UnifiedCareRecord_Insight_PatientIndex-2020.1-7015-0-lnxrhx64.tar.gz --build-arg HS_KEY=iris.key --squash -t ucr:2020.1 .
#--------------------------------------------------------------------

FROM centos:latest 

# build args
ARG HS_DIST
ARG HS_KEY
ARG HS_SUPERSERVER_PORT
ARG HS_WEBSERVER_PORT

# vars for iris
ENV ISC_PACKAGE_IRISGROUP=irisuser 
ENV ISC_PACKAGE_IRISUSER=irisuser 
ENV ISC_PACKAGE_MGRGROUP=irisowner 
ENV ISC_PACKAGE_MGRUSER=irisowner 
ENV IRISSYS=/home/irisowner/irissys 

RUN useradd -m $ISC_PACKAGE_MGRUSER --uid 51773 && useradd -m $ISC_PACKAGE_IRISUSER --uid 52773

# vars for HealthShare installation
ENV ISC_PACKAGE_INSTANCENAME="IRIS"
ENV ISC_PACKAGE_INSTALLDIR="/usr/healthshare"
ENV ISC_PACKAGE_INITIAL_SECURITY="Normal"
ENV ISC_PACKAGE_UNICODE="Y"
ENV ISC_PACKAGE_USER_PASSWORD="SYS"
ENV ISC_PACKAGE_CSPSYSTEM_PASSWORD="SYS"
ENV ISC_PACKAGE_SUPERSERVER_PORT="${HS_SUPERSERVER_PORT:-51773}"
ENV ISC_PACKAGE_WEBSERVER_PORT="${HS_WEBSERVER_PORT:-52773}"
ENV WEBTERMINAL_DIST="WebTerminal-v4.9.3.xml"

# update OS + dependencies & run HealthShare silent install
RUN yum -y update \
    && yum -y install which tar bzip2 hostname net-tools wget java \
    && yum -y clean all 

# setup variables for the HealthShare 
ENV TMP_INSTALL_DIR=/distrib

# HealthShare distribution_
# set-up and install HealthShare from distrib_tmp dir
RUN mkdir ${TMP_INSTALL_DIR}
WORKDIR ${TMP_INSTALL_DIR}
COPY distrib/${HS_DIST} ${TMP_INSTALL_DIR}
COPY ${WEBTERMINAL_DIST} ${TMP_INSTALL_DIR}

# run installer
RUN tar xzvf ${HS_DIST} 
RUN ./HealthShare*/irisinstall_silent
RUN iris stop $ISC_PACKAGE_INSTANCENAME quietly 
COPY keys/${HS_KEY} $ISC_PACKAGE_INSTALLDIR/mgr/iris.key

RUN iris start $ISC_PACKAGE_INSTANCENAME \
    && printf "SuperUser\n${ISC_PACKAGE_USER_PASSWORD}\n" \
    |  iris session $ISC_PACKAGE_INSTANCENAME -U USER "##class(%SYSTEM.OBJ).Load(\"${TMP_INSTALL_DIR}/${WEBTERMINAL_DIST}\",\"cdk\")"

RUN rm -rf ${TMP_INSTALL_DIR}/*
RUN iris stop $ISC_PACKAGE_INSTANCENAME quietly

# TCP sockets that can be accessed if user wants to (see 'docker run -p' flag)
EXPOSE 56772 56773 51773 52773 53773 54773 1972 22 80 443

COPY iris-main /iris-main
COPY irisHealth.sh /irisHealth.sh

ENTRYPOINT  ["/iris-main"]

