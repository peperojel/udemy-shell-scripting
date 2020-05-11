#!/bin/bash

# Script description:
    # This script executes a given command on multiple servers.

# Functional requirements:
    # 1. Executes all arguments as a single command on every server listed in the /vagrant/servers file by default.
    # 2. Executes the provided command as the user executing the script.
    # 3. Uses "ssh -o ConnectTimeout=2" to connect to a host.
    # 4. Allows to specify the following options:
        # -f FILE   Override the default file.
        # -n Dry run displaying the commands.
        # -s Run the commands with sudo on the remote servers.
        # -v Enable verbose which displays the name of the server for which the commands is being executed on.
    # 5. Enforces that it be executed without root privileges.
    # 6. Provides a usage statement if no command is given as a parameter.
    # 7. Informs the user if the command was not able to be executed succesfully on a remote host.
    # 8. Exits with an exit status of 0 or the most recent non-zero exit status of the ssh command.

# Implementation.

# Definitions.

# A list of servers, one per line.
SERVER_LIST='/vagrant/servers'

# Options for the ssh command.
SSH_OPTION='-o ConnectTimeout=2'

usage() {
    echo "Usage: ${0} [-nsv] [-f FILE] COMMAND" >&2
    echo "Executes COMMAND on all servers defined in ${SERVER_LIST}." >&2
    echo "  -f FILE Use FILE for the list of servers. Default: ${SERVER_LIST}" >&2
    echo "  -n      Dry run displaying the commands to execute." >&2
    echo "  -s      Run the commands with sudo on the remote servers." >&2
    echo "  -v      Enable verbose mode." >&2
    exit 1
}

# Check if its being executed with root privileges.
if [[ "${UID}" -eq 0 ]]
then
    echo "Do not execute this script as root. Use the -s option instead." >&2
    usage
fi

# Iterate over every option and act accordingly,
while getopts nsvf: OPTION
do
    case ${OPTION} in
    f) SERVER_LIST=${OPTARG} ;;
    v) VERBOSE='true' ;;
    s) SUDO='sudo' ;;
    n) DRY_RUN='true' ;;
    ?) usage ;;
    esac
done

# Remove options while leaving the remaining arguments
shift "$(( OPTIND - 1 ))"

# Check if the command was given as an argument
if [[ "${#}" -lt 1 ]]
then
    usage
fi

COMMAND="${@}"

# Check the existance of SERVER_LIST.
if [[ ! -e "${SERVER_LIST}" ]]
then
    echo "Could not open the server list file ${SERVER_LIST}." >&2
    exit 1
fi

# Iterate over every server.
for SERVER in $(cat ${SERVER_LIST})
do
    # If verbose display the server.
    if [[ "${VERBOSE}" = 'true' ]]
    then
        echo "${SERVER}"
    fi

    SSH_COMMAND="ssh ${SSH_OPTION} ${SERVER} 'set -o pipefail;${SUDO} ${COMMAND}'"
    
    if [[ "${DRY_RUN}" = true ]]
    then
        echo "DRY RUN: ${SSH_COMMAND}"
    else
        eval ${SSH_COMMAND}
        LAST_EXIT="${?}"

        # Capture any non-zero exit status from the SSH_COMMAND and report to the user.
        if [[ "${LAST_EXIT}" -ne 0 ]]
        then
            EXIT_STATUS="${LAST_EXIT}"
            echo "The command failed when executing on ${SERVER}." >&2
        fi
    fi
done

exit "${EXIT_STATUS}"