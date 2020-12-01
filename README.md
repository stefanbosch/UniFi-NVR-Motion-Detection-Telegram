## Dependancies:
* yum install curl wget
* Install jq:
* wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
* chmod +x ./jq
* cp jq /usr/bin

## Instructions

**Create file:**
vi /root/motion-uvc_voordeur.sh

**Create daemon file:**
vi /etc/systemd/system/motion-uvc_voordeur.service

## Start daemon:
systemctl start unifi-video.service

## Make sure the daemon start at boot:
systemctl enable unifi-video.service
