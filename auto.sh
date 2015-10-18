#!/bin/bash


################################################################################
#
# C O N S T A N T S
#
################################################################################ 

ACTION=$1
DIR=$2

# override the options and use host networking
HOST_NET=0

USAGE="
USAGE: ${0} [install|build] image
    install - installs/updates docker and dependencies on this host
    build - builds an image specified by image
    image - directory name which matches container name
    NOTE: Linux requires superuser or sudo.

    Example: (builds and starts dns docker container)
    ${0} build dns"

OSX_INST="
    OSX detected.  Please ensure boot2docker is installed and active."

LIN_INST="
    Linux detected.  Please use root or sudo to execute this script."


################################################################################
#
# F U N C T I O N S
#
################################################################################ 

dprint() {
    echo "---> ${@}" >&2
}

# install docker and dependencies
install_docker() {
    WGET=`which wget`
    apt-get update
    apt-get -y upgrade
    if [ ! -e "$WGET" ]; then
        apt-get install -y wget
    fi

    if [ -e '/usr/bin/docker' ]; then
        dprint 
        dprint "installation has already been completed"
    else
        wget -qO- https://get.docker.com/ | sh
    fi

    return $?
}

# build an image
build() {
    # dir cannot be zero length
    if [ -z "$DIR" ]; then
        dprint "build parameter requires name of image to build"
        return 1
    # dir must exist on disk
    elif [ -d "$DIR" ]; then
        # define options specific for each image
        if [ "$HOST_NET" -eq 1 ]; then
            OPTIONS="--net host"
        elif [ "$DIR" == "dns" ]; then
            OPTIONS="-p 53:53/udp -p 53:53" 
        elif [ "$DIR" == "ldap" ]; then
            OPTIONS="-p 389:389/udp -p 389:389 -p 636:636/udp -p 636:636"
        elif [ "$DIR" == "dhcp" ]; then
            OPTIONS="--net host"
        fi
        dprint "OPTIONS: using '${OPTIONS}'"

        # simplify vars
        IMAGE=$DIR
        IMAGE_NAME="auto_${IMAGE}"

        # build image
        dprint "building new image $IMAGE_NAME in ./${DIR}"
        docker build -t $IMAGE_NAME ./${DIR}/.

        # copy startup for container
        if [ -e "./docker_${IMAGE}.conf" ]; then
            if [ $LINUX -eq 1 ]; then
                dprint "copying upstart script to /etc/init/"
                cp ${DIR}/docker_${IMAGE}.conf /etc/init/
            fi
        fi

        # run start a container based on new image
        docker run --name $IMAGE -v ${PWD}/${IMAGE}/config:/data/${IMAGE} $OPTIONS $IMAGE_NAME
    else
        dprint "directory/image `pwd`/${DIR} does not exist"
    fi
}


################################################################################
#
# M A I N
#
################################################################################ 

# detect OSX/Linux
LINUX=1
if [ "$TERM_PROGRAM" != "" ]; then
    LINUX=0
fi

if [ $LINUX -eq 1 ]; then
    dprint "$LIN_INST"
else
    dprint "$OSX_INST"
fi

# switch on action
if [ "$ACTION" == "build" ]; then
    dprint "building ${DIR} ..."
    build
elif [ "$ACTION" == "install" ]; then
    dprint "installing docker ..."
    install_docker
elif [ "$ACTION" == "help" -o "$ACTION" == "" ]; then
    dprint "${USAGE}"
else
    dprint "invalid action ${ACTION} ${USAGE}"
    exit 1
fi

exit 0
