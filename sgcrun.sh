#!/bin/bash

NO_COLOR="\033[0m"
COLOR_RED="\033[1;31m"
COLOR_GREEN="\033[1;32m"
COLOR_YELLOW="\033[1;33m"
COLOR_PURPLE="\033[0;35m"
COLOR_CYAN="\033[0;36m"

LOG_PATH="/dev/null"

log () {
	echo -e "$1"
	echo -e "$1" >> "$LOG_PATH"
}

header() {
    log "$NO_COLOR                                                      "
    log "$NO_COLOR ███████╗ ██████╗  ██████╗██████╗ ██╗   ██╗███╗   ██╗ "
    log "$NO_COLOR ██╔════╝██╔════╝ ██╔════╝██╔══██╗██║   ██║████╗  ██║ "
    log "$NO_COLOR ███████╗██║  ███╗██║     ██████╔╝██║   ██║██╔██╗ ██║ "
    log "$NO_COLOR ╚════██║██║   ██║██║     ██╔══██╗██║   ██║██║╚██╗██║ "
    log "$NO_COLOR ███████║╚██████╔╝╚██████╗██║  ██║╚██████╔╝██║ ╚████║ "
    log "$NO_COLOR ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝ "
    log "$NO_COLOR                                                      "
}

ensure_binary() {
    BINARY_PATH=$(command -v "$1")
    if [ $? -ne 0 ]
    then
        log "${COLOR_RED}error: ${NO_COLOR}unable to locate '$1' utility"
        log ""
        exit 1
    fi
}

error() {
    log "${COLOR_RED}error: ${NO_COLOR}$1"
    log ""
    exit 1
}

header

ensure_binary "basename"
ensure_binary "realpath"

ensure_binary "date"
ensure_binary "echo"

ensure_binary "whoami"
ensure_binary "openssl"
ensure_binary "docker"
ensure_binary "curl"
ensure_binary "jq"

log "${COLOR_CYAN}info: ${NO_COLOR}script - $0"
log "${COLOR_CYAN}info: ${NO_COLOR}user - $(whoami 2>> /dev/null)"
log "${COLOR_CYAN}info: ${NO_COLOR}date - $(date -uIseconds 2>> /dev/null)"

##################################################
# Try to parse 'SGCRUN_LOG' environment variable #
##################################################
if [ -n "$SGCRUN_LOG" ]
then
    SGCRUN_LOG_REALPATH=$(realpath "$SGCRUN_LOG" 2> /dev/null)

    if [ -f  "$SGCRUN_LOG_REALPATH" ]
    then
        LOG_PATH="$SGCRUN_LOG_REALPATH"
    else
        log "${COLOR_YELLOW}warning: ${NO_COLOR}SGCRUN_LOG was set but log file does not exist"
    fi
fi

log "${COLOR_CYAN}info: ${NO_COLOR}log file - $LOG_PATH"

#################
# Validate ARGS #
#################
SGCRUN_ORGANIZATION="$1"
[[ "$SGCRUN_ORGANIZATION" =~ ^[0-9A-Za-z_-]+$ ]] || error "invalid github organization"

log "${COLOR_CYAN}info: ${NO_COLOR}organization - $SGCRUN_ORGANIZATION"

################
# Validate ENV #
################
[[ "$SGCRUN_GITHUB_TOKEN" =~ ^([0-9A-Za-z\_\-]+)$ ]] || error "unable to read SGCRUN_GITHUB_TOKEN"

#########################
# Create NAME Variables #
#########################
SGCRUN_RUNNER_DATE=$(date -u +"%Y%m%d%H%M%S" 2>> "$LOG_PATH")
if [ $? -ne 0 ]
then
    log "${COLOR_RED}error: ${NO_COLOR}unable to create date name"
    log ""
    exit 1
fi

SGCRUN_RUNNER_HEX=$(openssl rand -hex 4 2>> "$LOG_PATH")
if [ $? -ne 0 ]
then
    log "${COLOR_RED}error: ${NO_COLOR}unable to create hex name"
    log ""
    exit 1
fi

SGCRUN_RUNNER_NAME="sgcrun-$SGCRUN_RUNNER_DATE-$SGCRUN_RUNNER_HEX"
log "${COLOR_CYAN}info: ${NO_COLOR}runner - $SGCRUN_RUNNER_NAME"

#############################
# Fetch runner REGISTRATION #
#############################
SGCRUN_GITHUB_API_RESPONSE=$(
    curl -L \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $SGCRUN_GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/orgs/$SGCRUN_ORGANIZATION/actions/runners/registration-token" \
        2>> "$LOG_PATH"        
)
if [ $? -ne 0 ]
then
    log "${COLOR_RED}error: ${NO_COLOR}unable to fetch registration token"
    log ""
    exit 1
fi

SGCRUN_GITHUB_REGISTRATION_TOKEN=$(echo $SGCRUN_GITHUB_API_RESPONSE 2>> "$LOG_PATH" | jq -r ".token" 2>> "$LOG_PATH")
if [ $? -ne 0 ]
then
    log "${COLOR_RED}error: ${NO_COLOR}unable to parse registration token"
    log ""
    exit 1
fi
[[ "$SGCRUN_GITHUB_REGISTRATION_TOKEN" =~ ^([0-9A-Za-z]+)$ ]] || error "invalid github registration token"


###########################
# Create DOCKER container #
###########################
docker run \
    --detach \
    --restart no \
    --rm \
    --name $SGCRUN_RUNNER_NAME \
    --env RUNNER_NAME=$SGCRUN_RUNNER_NAME \
    --env RUNNER_ORG=$SGCRUN_ORGANIZATION \
    --env RUNNER_TOKEN=$SGCRUN_GITHUB_REGISTRATION_TOKEN \
    --env RUNNER_LABELS=sgcrun \
    --env RUNNER_EPHEMERAL=true \
    --volume /runner \
    --privileged \
    summerwind/actions-runner-dind:ubuntu-22.04 >> "$LOG_PATH" 2>> "$LOG_PATH"
if [ $? -ne 0 ]
then
    log "${COLOR_RED}error: ${NO_COLOR}unable to create docker container temporal file"
    log ""
    exit 1
fi

log ""
log "${COLOR_GREEN}success: ${NO_COLOR}created self-hosted github containerized runner."
log ""
