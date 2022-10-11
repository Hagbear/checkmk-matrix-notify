#!/bin/bash
# Push Notification (using Matrix)
#
# Script Name   : check_mk_matrix-notify.sh
# Description   : Send Check_MK notifications by Matrix
# Orginal Author        : https://github.com/filipnet/checkmk-telegram-notify
# License       : BSD 3-Clause "New" or "Revised" License
# ======================================================================================

# Matrix Server
if [ -z ${NOTIFY_PARAMETER_1} ]; then
        echo "No Matrix server provided. Exiting" >&2
        exit 2
else
        HOST="${NOTIFY_PARAMETER_1}"
fi

# Matrix API Token
if [ -z ${NOTIFY_PARAMETER_2} ]; then
        echo "No Matric token ID provided. Exiting" >&2
        exit 2
else
        TOKEN="${NOTIFY_PARAMETER_2}"
fi

# Matrix Chat-ID or Group-ID
if [ -z ${NOTIFY_PARAMETER_3} ]; then
        echo "No Matrix Chat-ID or Group-ID provided. Exiting" >&2
        exit 2
else
        ROOM="${NOTIFY_PARAMETER_3}"
fi

# Privacy settings to anonymize/masking IP addresses
if [[ ${NOTIFY_PARAMETER_4} == "privacy" ]]; then
        # IPv4 IP addresses
        if [ ${NOTIFY_HOST_ADDRESS_4} ]; then
                slice="${NOTIFY_HOST_ADDRESS_4}"
                count=1
                while [ "$count" -le 4 ]
                do
                        declare sec"$count"="${slice%%.*}"
                        slice="${slice#*.}"
                        count=$((count+1))
                done
                # Adjust the output to your privacy needs here (Details in the readme.md)
                NOTIFY_HOST_ADDRESS_4="${sec1}.${sec2}.2.${sec4}"
        fi

        # IPv6 IP addresses
        if [ ${NOTIFY_HOST_ADDRESS_6} ]; then
                slice="${NOTIFY_HOST_ADDRESS_6}"
                count=1
                while [ "$count" -le 8 ]
                do
                        declare sec"$count"="${slice%%:*}"
                        slice="${slice#*:}"
                        count=$((count+1))
                done
                # Adjust the output to your privacy needs here (Details in the readme.md)
                NOTIFY_HOST_ADDRESS_6="${sec1}:${sec2}:${sec3}:${sec4}:ffff:ffff:ffff:${sec8}"
        fi

else
        echo "Invalid privacy parameter, check your Check_MK settings." >&2
fi



# Set an appropriate emoji for the current state
# Feel free to change the emoji to your own taste. This is done by customizing the UTF8 code. Examples here: https://apps.timwhitlock.info/emoji/tables/unicode
if [[ ${NOTIFY_WHAT} == "SERVICE" ]]; then
        STATE="${NOTIFY_SERVICESHORTSTATE}"
else
        STATE="${NOTIFY_HOSTSHORTSTATE}"
fi
case "${STATE}" in
    OK|UP)
        EMOJI=$'\xE2\x9C\x85' # white heavy check mark
        ;;
    WARN)
        EMOJI=$'\xE2\x9A\xA0' # warning sign
        ;;
    CRIT|DOWN)
        EMOJI=$'\xF0\x9F\x86\x98' # squared sos
        ;;
    UNKN)
        EMOJI=$'\xF0\x9F\x94\x84' # anticlockwise downwards and upwards open circle arrows
        ;;
esac

# Create a MESSAGE variable to send to your Matrix
MESSAGE="${NOTIFY_HOSTNAME} (${NOTIFY_HOSTALIAS})<br>"
MESSAGE+="${EMOJI} ${NOTIFY_WHAT} ${NOTIFY_NOTIFICATIONTYPE}<br><br>"
if [[ ${NOTIFY_WHAT} == "SERVICE" ]]; then
        MESSAGE+="${NOTIFY_SERVICEDESC}<br>"
        MESSAGE+="State changed from ${NOTIFY_PREVIOUSSERVICEHARDSHORTSTATE} to ${NOTIFY_SERVICESHORTSTATE}<br>"
        MESSAGE+="${NOTIFY_SERVICEOUTPUT}<br>"
else
        MESSAGE+="State changed from ${NOTIFY_PREVIOUSHOSTHARDSHORTSTATE} to ${NOTIFY_HOSTSHORTSTATE}<br>"
        MESSAGE+="${NOTIFY_HOSTOUTPUT}<br>"
fi
MESSAGE+="<br>IPv4: ${NOTIFY_HOST_ADDRESS_4} <br>IPv6: ${NOTIFY_HOST_ADDRESS_6}<br>"
MESSAGE+="${NOTIFY_SHORTDATETIME} | ${OMD_SITE}"


# Send message to Matrix

URL="https://${HOST}/_matrix/client/r0/rooms/${ROOM}/send/m.room.message?access_token=${TOKEN}"
BODY='{"msgtype":"m.text", "body":"'"${MESSAGE}"'","format":"org.matrix.custom.html", "formatted_body":"'"${MESSAGE}"'"}'

curl -S -X POST -d "${BODY}" "${URL}"

if [ $? -ne 0 ]; then
        echo "Not able to send Matric message" >&2
        exit 2
else
        exit 0
fi
