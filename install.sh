#!/bin/bash
ARCHINSTALL_CONFIG_URL="https://raw.githubusercontent.com/BriceMichalski/workstation/main/archinstall"
WORKDIR="/tmp/archinstall"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

help(){
  echo "Personnal workstation Arch Install Script"
  echo "USAGE:"
  echo "  $ install.sh [ARGS]"
  echo "ARGS:"
  echo "-d,--disk-name                  Disk that will be parted" 
  echo "-e,--encrypt-password           Root partition encryption password" 
  echo "-h,--hostname                   Hostname of the station"
  echo "-r,--root-password              Root password"  
  echo "-u,--user-password              User password"  
}

if [ $# -eq 0 ]; then
  help
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--disk-name)
      DISK_NAME=$( echo $2 | sed 's/\//\\\//g')
      shift # past argument
      shift # past value
      ;;
    -e|--encrypt-password)
      ENCRYPT_PASSWORD="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--hostname)
      HOSTNAME="$2"
      shift # past argument
      shift # past value
      ;;
    -r|--root-password)
      ROOT_PASSWORD="$2"
      shift # past argument
      shift # past value
      ;;
    -u|--user-password)
      USER_PASSWORD="$2"
      shift # past argument
      shift # past value
      ;;
    --help)
      help
      exit 0
      ;;   
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

pacman -Sy
pacman -S --noconfirm archinstall
mkdir -p $WORKDIR

# Download Archinstall Template
curl $ARCHINSTALL_CONFIG_URL/user_credentials.json --output $WORKDIR/creds.json
curl $ARCHINSTALL_CONFIG_URL/user_configuration.json --output $WORKDIR/config.json
curl $ARCHINSTALL_CONFIG_URL/user_disk_layout.json --output $WORKDIR/disk.json

# POPULATE TEMPLATE WITH VALUE
sed -i "s/USER_PASSWORD/$USER_PASSWORD/" $WORKDIR/creds.json
sed -i "s/ROOT_PASSWORD/$ROOT_PASSWORD/" $WORKDIR/creds.json
sed -i "s/ENCRYPT_PASSWORD/$ENCRYPT_PASSWORD/" $WORKDIR/creds.json

sed -i "s/DISK_NAME/$DISK_NAME/" $WORKDIR/config.json
sed -i "s/HOSTNAME/$HOSTNAME/" $WORKDIR/config.json

sed -i "s/DISK_NAME/$DISK_NAME/" $WORKDIR/disk.json


# Launch Archinstall
archinstall --silent --debug --creds $WORKDIR/creds.json --config $WORKDIR/config.json --disk_layouts $WORKDIR/disk.json

if [ $? -eq 0 ]; then
    echo -e "${GREEN}"
    echo "============================"
    echo "====  INSTALL SUCESSED  ===="
    echo "============================"
    echo -e "${NC}"
else
    echo -e "${RED}"
    echo "============================"
    echo "====   INSTALL FAILED   ===="
    echo "============================"
    echo -e "${NC}"
    exit 1
fi

for i in $(seq 30 -1 1)
do
  echo -en "\rPlease remove your installation support within the time limit : $i s"
  sleep 1
done

echo "now reboot."
reboot