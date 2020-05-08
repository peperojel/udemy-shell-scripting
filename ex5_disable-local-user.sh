#!/bin/bash

# Script description:
    # Allows for a local Linux account to be disabled or deleted, and optionally archived (its home directory)
    
# Functional requirements:
    # All error messages are sended to STDERR
    # Enforces user to execute it with root privileges.
    # Provides a usage statement if the user doesn't supply an account name.
    # Disables (expires/lock) accounts by default.
    # Allow the following options:
        # -d Deletes accounts instead of disabling them.
        # -r Removes their home directory 
        # -a Creates an archive of the home directory and stores it in /archive
        # Any other option will be considered invalid and will trigger the display of the usage statement.
    # Accepts multiple accounts as arguments
    # Refuses to disable or delete any account that have UID less than 1000.
    # Informs the user if the account failed to be disabled, deleted or archived.
    # Display the username and any actions performed against the account.

# Implementation

# Function and constants definitions

ARCHIVE_DIR='/archive'

usage() {
    echo "Usage: ${0} [-dra] USER_1 [USERN]" >&2
    echo "Allows for a local Linux account to be disabled." >&2
    echo "  -d Deletes accounts instead of disabling them." >&2
    echo "  -r Removes the home directory associated with the account(s)." >&2
    echo "  -a Creates an archive of the home directory associated with the account(s) and stores it(them) in ${ARCHIVE_DIR}." >&2
    exit 1
}

# Check if user has root privileges
if [[ "${UID}" -ne 0 ]]
then
    echo 'You need root privileges.' >&2
    exit 1
fi

# Iterate over every option and stores them in a variable
while getopts dra OPTION
do
    case ${OPTION} in
        d) DELETE_USER='true';;
        r) REMOVE_HOME_DIR='-r';;
        a) ARCHIVE_HOME_DIR='true';;
        ?) usage ;;
    esac
done

# Remove options while leaving the remaining arguments
shift "$(( OPTIND - 1 ))"

# Check if at least one user id was provided as a parameter
if [[ "${#}" -lt 1 ]]
then
    usage
fi

# Iterate over the parameters and execute the intended behaviour.
for USERNAME in "${@}"
do
    echo "Processing user: ${USERNAME}"

    # Make sure the account exists or its UID is at least 1000.
    USERID=$(id -u ${USERNAME} 2> /dev/null)
    if [[ "${USERID}" -lt 1000 ]]
    then
        echo "The account ${USERNAME} doesn't exist on this system or its UID is lower than 1000." >&2
        exit 1
    fi

    # Create an archive if requested to do so.
    if [[ "${ARCHIVE_HOME_DIR}" = 'true' ]]
    then
        # Make sure the ARCHIVE_DIR directory exists.
        if [[ ! -d "${ARCHIVE_DIR}" ]]
        then
            echo "Creating ${ARCHIVE_DIR} directory."
            mkdir -p ${ARCHIVE_DIR}
            if [[ ${?} -ne 0 ]]
            then
                echo "The directory ${ARCHIVE_DIR} could not be created." >&2
                exit 1
            fi
        fi

        # Archive the user's home directory and move it into the ARCHIVE_DIR
        HOME_DIR="/home/${USERNAME}"
        ARCHIVE_FILE="${ARCHIVE_DIR}/${USERNAME}.tgz"
        if [[ -d "${HOME_DIR}" ]]
        then
            echo "Archiving ${HOME_DIR} to ${ARCHIVE_FILE}"
            tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &> /dev/null
            if [[ ${?} -ne 0 ]]
            then
                echo "Could not create ${ARCHIVE_FILE}." >&2
                exit 1
            fi
        else
            echo "${HOME_DIR} does not exist or is not a directory." >&2
            exit 1
        fi
    fi

    if [[ "${DELETE_USER}" = 'true' ]]
    then
        # Delete the account
        userdel ${REMOVE_HOME_DIR} ${USERNAME}

        # Check to see if the userdel command succeeded
        if [[ "${?}" -ne 0 ]]
        then
            echo "The account ${USERNAME} was NOT deleted." >&2
            exit 1
        fi
        
        echo "The user ${USERNAME} was deleted."
    else
        # Disable the account
        chage -E 0 ${USERNAME}

        # Check to see if the chage command succeeded.
        if [[ "${?}" -ne 0 ]]
        then
            echo "The account ${USERNAME} was NOT disabled." >&2
            exit 1
        fi
        echo "The account ${USERNAME} was disabled."
    fi
done

exit 0