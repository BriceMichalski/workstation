BROWN='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

WORKSTATION_DIR="/home/brice_michalski/.workstation"

title(){
    echo ""
    echo -e "${BROWN}===   $1   ===${NC}"
}

symlink(){
    source="$WORKSTATION_DIR/$1"
    dest="$2"

    mkdir -p $(dirname $dest)

    rm -rf $dest
    ln -sf $source $dest

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Created Link${NC} $dest -> $source"
    else
        echo -e "${RED}Link creation failed${NC} $dest -> $source"
    fi
}

sysd(){
    service="$1.service"
    systemctl enable "$service" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Enable Service${NC} [$service]"
    else
        echo -e "${RED}Service activation failed${NC} [$service]"
    fi
}

execute() {
    comm=$1
    command=$2

    echo -en "\r$comm "
    echo $command | bash > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e " [${GREEN}OK${NC}]"
    else
        echo -e " [${RED}KO${NC}]"
    fi
}

executeAs(){
    comm=$1
    user=$2
    command=$( echo $3 | sed 's/\//\\\//g')

    echo "launch :  sudo -H -u $user -i /bin/bash -c '$command'"

    echo -en "\r$comm "

    echo "sudo -H -u $user -i /bin/bash -c '$command'"
    echo "sudo -H -u $user -i /bin/bash -c '$command'" | bash > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e " [${GREEN}OK${NC}]"
    else
        echo -e " [${RED}KO${NC}]"
    fi
}

configd(){
    confName=$(echo $1 | sed 's/\.ini//g' )
    real_user_id=$(id -u brice_michalski )
    executeAs "$confName" "brice_michalski" "export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/${real_user_id}/bus' && dconf load / < $WORKSTATION_DIR/config/dconf/$1" > /dev/null 2>&1

    echo -e "${GREEN}Dconf settings applied${NC} [$confName]"
}

#
#   MAIN PROGRAM
#

NO_LOGOUT=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --no-logout)
      NO_LOGOUT=1
      shift # past argument
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

pacman --noconfirm -S figlet
figlet "Workstation Configuration"

# executeAs "Load dconf look"   "brice_michalski"     "dconf load / < /home/brice_michalski/.config/dconf/look.dconf"


# Create Simlink to configuration
title "Link Configuration File"

links=$(cat $WORKSTATION_DIR/links.json | jq -c ".links[]")
for link in $links
do
    source=$(echo $link | jq -r ".src")
    dest=$(echo $link | jq -r ".dest")
    symlink $source $dest
done


# Load Service
title "Enable Service" 

services=$(cat $WORKSTATION_DIR/services.json | jq -r ".services[]")
for service in $services
do
  sysd $service
done


# Load Service
title "Apply Dconf Settings"

files=$(ls -1 $WORKSTATION_DIR/config/dconf)
for file in $files
do  

    configd $file 
done


#End of script
echo -e "${GREEN}"
echo "==========================="
echo "====  CONFIG SUCESSED  ===="
echo "==========================="
echo -e "${NC}"

if [[ "$NO_LOGOUT" -eq 1 ]]
then
    exit 0
fi

for i in $(seq 5 -1 1)
do
  echo -en "\rLogout in $i s  "
  sleep 1
done


kill -9 -1


