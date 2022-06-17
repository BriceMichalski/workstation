BROWN='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
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

    echo -en "$comm "
    echo $command | bash > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo -e "\r[${GREEN}OK${NC}] $comm"
    else
        echo -e "\r[${RED}KO${NC}] $comm"
    fi
}

executeAs(){
    comm=$1
    user=$2
    command=$3

    if [[ "$DEBUG" -eq 1 ]]
    then
        echo -e "${CYAN}"
        echo ">    sudo -H -u $user -i /bin/bash -c '$command'"
        echo -e "${NC}"
    fi

    echo -en "$comm "

    if [[ "$DEBUG" -eq 1 ]]
    then
        echo "sudo -H -u $user -i /bin/bash -c '$command'" | bash 
    else
        echo "sudo -H -u $user -i /bin/bash -c '$command'" | bash  > /dev/null 2>&1
    fi
    

    if [ $? -eq 0 ]; then
        echo -e "\r[${GREEN}OK${NC}] $comm"
    else
        echo -e "\r[${RED}KO${NC}] $comm"
    fi
}

configd(){
    confName=$(echo $1 | sed 's/\.ini//g' )
    real_user_id=$(id -u brice_michalski )
    executeAs "$confName" "brice_michalski" "export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/${real_user_id}/bus' && dconf load / < $WORKSTATION_DIR/config/dconf/$1" > /dev/null 2>&1

    echo -e "${GREEN}Dconf settings applied${NC} [$confName]"
}

rua(){
    repo=$1
    appName=$(basename $1 | sed 's/\.git//g' )
    cpwd=$PWD
    aurPath="/home/brice_michalski/.aur/$appName"

    echo -en "Install $appName"
    executeAs "create aur dir" "brice_michalski"  "mkdir -p $aurPath"

    if [ -d "$aurPath/.git" ] 
    then
        cd $aurPath
        executeAs "pull repo" "brice_michalski"  "cd $aurPath && git pull"

    else
        executeAs "clone repos" "brice_michalski" "git clone $repo $aurPath"
    fi

    executeAs "makepkg" "brice_michalski" "cd $aurPath && makepkg --noconfirm -si"
    cd $cpwd

    if [ $? -eq 0 ]; then
        echo -e "\r[${GREEN}OK${NC}] $appName"
    else
        echo -e "\r[${RED}KO${NC}] $appName"
    fi 
}

#####################
#                   #
#   MAIN PROGRAM    #
#                   #
#####################

NO_LOGOUT=0
DEBUG=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --no-logout)
      NO_LOGOUT=1
      shift # past argument
      ;;
    --debug)
      DEBUG=1
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



figlet "Workstation Configuration"

# Oh my zsh
title "Custom Bash"

executeAs 'remove exiting oh-my-zsh'        'brice_michalski'   'rm -rf ~/.oh-my-zsh'
executeAs 'install oh-my-zsh'               'brice_michalski'   'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
executeAs 'remove exiting oh-my-zsh'        'brice_michalski'   'rm -rf ~/.zshrc.pre-oh-my-zsh'
executeAs 'zsh-autosuggestions plugin'      'brice_michalski'   'git clone https://github.com/zsh-users/zsh-autosuggestions          ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions'
executeAs 'zsh-syntax-highlighting plugin'  'brice_michalski'   'git clone https://github.com/zsh-users/zsh-syntax-highlighting.git  ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting'
execute 'Set default bash to zh' "usermod --shell /usr/bin/zsh brice_michalski"


# Install Aur
title "Aur installation"

repos=$(cat $WORKSTATION_DIR/packages.json | jq -r ".aur.repos[]")
for repo in $repos
do
    rua $repo
done

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


