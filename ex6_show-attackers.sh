#!/bin/bash

# Script description:
    # This scripts displays the number of failed login attempts by IP, address and location.

# Functional requirements:
    # Requires that a file is provided as an argument.
    # If there are more than LIMIT failed login attempts, display the number of attempts, the IP address of the attacker and his location.
    # Produce the output in CSV fomat.

# Implementation:

LIMIT=10
LOG_FILE=${1}

# Make sure the file was supplied as an argument and that exists.
if [[ ! -e "${LOG_FILE}" ]]
then
    echo "Cannot open log file: ${LOG_FILE}" >&2
    exit 1
fi

# Display the CSV header
echo "Count,IP,Location"

# Aggregates the relevant information in the log file
ATTEMPTS=$(grep Failed syslog-sample | awk '{print $(NF - 3)}' | sort | uniq -c | sort -nr)

echo "${ATTEMPTS}" | while read -r COUNT IP
do
    # If the number of failed attempts is greater than LIMIT display count, IP, and location
    if [[ "${COUNT}" -gt "${LIMIT}" ]]
    then
        # Looking up the location of the attacker
        FROM=$(geoiplookup ${IP} | awk -F ', ' '{print $NF}')
        echo "${COUNT},${IP},${FROM}"
    fi
done

exit 0