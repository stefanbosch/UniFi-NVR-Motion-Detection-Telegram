#!/bin/sh
#
# Version: 2.0
# Created by Stefan Bosch on 02-06-2018
# Last edited: 01-07-2018
#
####################################################
#
# Dependancies:
# yum install curl wget
#
# Install jq:
# wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
# chmod +x ./jq
# cp jq /usr/bin
#
####################################################
#
# tail -f /opt/UniFi-Video/logs/motion.log | grep '<CAM_ID>.*start\|start.*<CAM_ID>'
# journalctl -u motion-uvc_voordeur.service -f
#
####################################################
#
# VARIABLES:
#
####################################################

TELEGRAM_KEY=""		# [ telegram bot api sleutel ]
CHATID=				# [ chat ID van het gesprek waar de snapshot heen gestuurd worden, te vinden in de bot api ]

UNIFI_IP="" 		# [ IP:PORT adres van de UniFi NVR controller (bijvoorbeeld: 192.168.1.100:7080) ]
UNIFI_KEY=			# [ API KEY van de UniFi Controller, staat onder USERS > API ACCESS. ]
CAM_ID="" 			# [ ID van de camera, te achter halen: http://<IP:PORT>/api/2.0/camera/?apiKey=<API_KEY> de laatste _id (per camera) ]
LOG_CAM_ID=""

TIMEBREAKS=120  	# [ seconds - anpassen naar wens. Hoe lager hoe meer spam ]
IMAGESIZE=720   	# [ Formaat van het te versturen afbeelding ]


####################################################
#
# Start script
#
####################################################

URL="https://api.telegram.org/bot${TELEGRAM_KEY}/sendPhoto"

# set time var to '0' at start.
time=0

tail -fn0 /opt/UniFi-Video/logs/motion.log | \
while read line ; do
        echo "$line" | grep -q "${LOG_CAM_ID}.*start"
        if [ $? = 0 ]
        then
        diff=$[`date +%s` - $time]
                if [ "$diff" -gt $TIMEBREAKS ]
                then
                        # Grab camera image
                        wget -q --no-check-certificate "http://${UNIFI_IP}/api/2.0/snapshot/camera/${CAM_ID}?force=true&width=${IMAGESIZE}&apiKey=${UNIFI_KEY}" -O /root/snap.jpeg

                        echo ""
                        lastRecordingId1=$(curl -s -X GET http://${UNIFI_IP}/api/2.0/camera/$CAM_ID?apiKey=${UNIFI_KEY} | jq '.data[].lastRecordingId' | awk -F '"' '{print $2}')
                        echo $lastRecordingId1

                        echo "Motion detected at `date`"

                        # Change time var to current time
                        time=`date +%s`

                        sleep 1s
                        lastRecordingId2=$(curl -s -X GET http://${UNIFI_IP}/api/2.0/camera/$CAM_ID?apiKey=${UNIFI_KEY} | jq '.data[].lastRecordingId' | awk -F '"' '{print $2}')
                        echo $lastRecordingId2

                        sleep 1s
                        lastRecordingId=$(curl -s -X GET http://${UNIFI_IP}/api/2.0/camera/$CAM_ID?apiKey=${UNIFI_KEY} | jq '.data[].lastRecordingId' | awk -F '"' '{print $2}')
                        echo $lastRecordingId

                                                # 2s sleep geeft altijd de juiste LastRecordingId, ander is de json nog niet geupdatet, de echos zijn voor debugging. # journalctl -u motion-uvc_voordeur.service -f

                        nvrURL="http://${UNIFI_IP}/recordings/${lastRecordingId}"

                        # telegram api
                        curl -s -X POST ${URL} \
                        -F chat_id=$CHATID \
                        -F photo="@/root/snap.jpeg" \
                        -F parse_mode="markdown" \
                        -F caption="`date '+%Y-%m-%d %H:%M:%S'` [View recording](${nvrURL})" 2>/dev/null

                        echo ""
                fi
        fi
done
