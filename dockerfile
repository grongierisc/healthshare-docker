# This Docker manifest file builds a container with:
# - HealthShare 2020.1 for RHEL x64 and 
# - it handles container PID 1 via ccontainermain which offers various flags
#
# build the new image with e.g. 
# $ docker build --force-rm --no-cache -t hs:2020.01 .
#--

# pull from this repository
# note that if you don't have the distribution you're after it will be automatically
# downloaded from Docker central hub repository (you'll have to create a user there)

FROM centos:latest

# setup variables for the HealthShare 
ENV TMP_INSTALL_DIR=/distrib
ENV HS_DIST="HealthShare_UnifiedCareRecord_Insight_PatientIndex-2020.1-7015-0-lnxrhx64.tar.gz"

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
ENV WEBTERMINAL_DIST="WebTerminal-v4.9.3.xml"


# HealthShare distribution_
# set-up and install HealthShare from distrib_tmp dir
RUN mkdir ${TMP_INSTALL_DIR}
WORKDIR ${TMP_INSTALL_DIR}
COPY distrib/${HS_DIST} ${TMP_INSTALL_DIR}
COPY ${WEBTERMINAL_DIST} ${TMP_INSTALL_DIR}


# update OS + dependencies & run HealthShare silent install
RUN yum -y update \
    && yum -y install which tar bzip2 hostname net-tools wget java \
    && yum -y clean all 

RUN tar xzvf ${HS_DIST} 
RUN ./HealthShare*/irisinstall_silent
RUN iris stop $ISC_PACKAGE_INSTANCENAME quietly 
COPY keys/iris.key $ISC_PACKAGE_INSTALLDIR/mgr/iris.key

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

# run via:
# docker run -d -p 57772:57772 -p 1972:1972 -e ROOT_PASS="linux" --name HSTEST hs:18.01 -i=HEALTHSHARE
#
# more options & explanations
# $ docker run -d            // detached in the background; accessed only via network
# --privileged                  // only for kernel =<3.16 like CentOS 6 & 7; it gives us root privileges to tune the kernel etc.
# -h <host_name>            // you can specify a host name
# -p 57772:57772             // TCP socket port mapping as host_external:container_internal
# -p 0.0.0.0:2222:22         // this means allow 2222 to be accesses from any ip on this host and map it to port 22 in the container
# -e ROOT_PASS="linux"        // -e for env var; tutum/centos extension for root pwd definition
# <docker_image_id>             // see docker images to fetch the right name & tag or id
#                             // after the Docker image id, we can specify all the flags supported by 'ccontainermain'
#                             // see this page for more info https://github.com/zrml/ccontainermain
# -i=HealthShare                    // this is the Cachè instance name
# -xstart=/run.sh                    // eXecute another service at startup time
#                            // run.sh starts sshd (part of tutum centos container)
#                            // for more info see https://docs.docker.com/reference/run/


