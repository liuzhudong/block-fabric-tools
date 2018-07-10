#!/bin/bash
set -ue

HYPERLEDGER_FABRIC_IMAGE_TAG=":x86_64-1.1.0"
XN_FABRIC_CFG_PATH=/tmp

function envSetting(){
  PARENT_DIR_NAME=`dirname $0`
  if [[ "." != ${PARENT_DIR_NAME} ]]; then
    echo "ERROR:script execute path error"
    exit 0
  fi
  DEPLOY_ENV_ROOT="$PWD/"
  DEPLOY_ENV_HOME="${DEPLOY_ENV_ROOT}/.."
}

function clearDocker(){
    echo "===> rm docker container xn_fabric_tools_* and Exited "
    docker ps -a | grep xn_fabric_tools_ | grep Exited 
    echo
    docker rm $(docker ps -a | grep xn_fabric_tools_ | grep Exited | awk '{print $1}')
}

function runDocker(){
    echo 
    local tools_cmd=$1
    local CUR_TIME=$(date +%Y%m%d%H%M%S)
    docker run --name xn_fabric_tools_${CUR_TIME} -v ${DEPLOY_ENV_ROOT}data:/tmp \
    hyperledger/fabric-tools${HYPERLEDGER_FABRIC_IMAGE_TAG} \
    bash -c "cd /tmp; ${tools_cmd}"
    echo
    if [[ "${DOCKER_CLEAR_FLAG}" == "true" ]]; then
        clearDocker
    fi
}


function cryptogen(){
    echo "===> cryptogen generate crypto-config"
    runDocker "cryptogen generate --config=${XN_FABRIC_CFG_PATH}/crypto-config.yaml"
}

function cryptogenExtend(){
    echo "===> cryptogen extend crypto-config"
    runDocker "cryptogen extend --config=${XN_FABRIC_CFG_PATH}/crypto-config.yaml"
}

function blockGenesis(){
    echo "===> configtxgen generate orderer block"
    runDocker "export FABRIC_CFG_PATH=${XN_FABRIC_CFG_PATH};configtxgen -profile ${CONFIGTXGEN_PROFILE_BLOCKGENESIS} -outputBlock orderer.block"
}

function channel(){
    local channel_name=$1
    local channel_file_name="$(echo ${channel_name} | tr '[:upper:]' '[:lower:]')"
    echo "===> configtxgen generate channel ${channel_file_name}"
    runDocker "export FABRIC_CFG_PATH=${XN_FABRIC_CFG_PATH};configtxgen -profile ${channel_name} -outputCreateChannelTx ${channel_file_name}.tx -channelID ${channel_file_name}"
}

function channelAnchor(){
    local channel_name=$1
    local channel_file_name="$(echo ${channel_name} | tr '[:upper:]' '[:lower:]')"
    echo "===> configtxgen generate channel ${channel_file_name}"
    runDocker "export FABRIC_CFG_PATH=${XN_FABRIC_CFG_PATH};configtxgen -profile ${channel_name} -outputAnchorPeersUpdate ${channel_file_name}${MSPID}anchors.tx -channelID ${channel_file_name} -asOrg ${MSPID}"
}


function config(){
    DOCKER_CLEAR_FLAG=false
    echo "===> config"
    sleep 2
    cryptogen
    sleep 2
    blockGenesis
    sleep 2
    channel ${CHANNEL}
    sleep 2
    channelAnchor ${CHANNEL}

    sleep 2
    clearDocker

    echo
}

function printHelp() {
    local shcmd="run.sh"
    echo
    echo "Usage: "
    echo "  ${shcmd} -m (operate) -C (channel name) -M (peer mspid) -O (orderer genesis block name) -f (docker clear flag)"
    echo "  ${shcmd} -h|--help (print this message)"
    echo
    echo "${shcmd} command"
    echo "	${shcmd} -m operate (must param)"
    echo "	${shcmd} -C channel name "
    echo "	${shcmd} -M peer mspid "
    echo "	${shcmd} -O orderer genesis block name "
    echo "	${shcmd} -f docker clear flag "
    echo "	${shcmd} -h help "
    echo
}

# Parse commandline args
while getopts "h?m:C:M:O:f:" opt; do
    case "$opt" in
        h|\?)
        printHelp
        exit 0
        ;;
        m)  MODE=$OPTARG
        ;;
        C)  CHANNEL=$OPTARG
        ;;
        M)  MSPID=$OPTARG
        ;;
        O)  CONFIGTXGEN_PROFILE_BLOCKGENESIS=$OPTARG
        ;;
        f)  DOCKER_CLEAR_FLAG=$OPTARG
        ;;
    esac
done

: ${CHANNEL:="XnChannel"}
: ${DOCKER_CLEAR_FLAG:="true"}
: ${MSPID:="Org1MSP"}
: ${CONFIGTXGEN_PROFILE_BLOCKGENESIS:="SoloOrgOrdererGenesis"}
: ${MODE:=""}

envSetting

if [ "${MODE}" == "cryptogen" ]; then
    cryptogen
elif [ "${MODE}" == "cryptogenExtend" ]; then
    cryptogenExtend
elif [ "${MODE}" == "block" ]; then
    blockGenesis
elif [ "${MODE}" == "channel" ]; then
    channel ${CHANNEL}
elif [ "${MODE}" == "channelanchor" ]; then
    channelAnchor ${CHANNEL}
elif [ "${MODE}" == "all" ]; then
    config
else
    printHelp
    exit 0
fi

echo
