 #!/bin/bash
# get_dock.sh
# -----------
# 
# Installs docker as well as docker-compose directly from docker sources using aptitude package manager.
# 🚫 ONLY LINUX UBUNTU/DEBIAN SYSTEMS SUPPORTED 
#
# @zudsniper
#############################################
# DOCKER INSTALLATION 
#############################################

# Include ANSI color schema
if [ -f ~/.ansi_colors.sh ]; then
    source ~/.ansi_colors.sh
else
    curl -o ~/.ansi_colors.sh https://raw.githubusercontent.com/zudsniper/bashbits/master/.ansi_colors.sh
    source ~/.ansi_colors.sh
fi

# Define log levels
declare -A LOG_LEVELS
LOG_LEVELS=([7]="silly" [6]="verbose" [5]="debug" [4]="http" [3]="info" [2]="warn" [1]="error" [0]="critical")

# Default log level
LOG_LEVEL="info"

function log() {
    local LEVEL_NUM=${LOG_LEVELS[$1]}
    shift
    if [ ${LOG_LEVELS[$LOG_LEVEL]} -ge $LEVEL_NUM ]; then
        echo -e "${@}"
    fi
}

function uninstall_dock() {
    log 3 "${A_YELLOW}Uninstalling Docker...${A_RESET}"
    # Uninstall docker the other ways you might have it....
    $(sudo snap remove docker --purge) || log 2 "didn't uninstall docker via snap!" 
    # Kill docker... 
    sudo apt-get purge -y docker-engine docker docker.io docker-ce 
    sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce 
    sudo umount /var/lib/docker/
    sudo rm -rf /var/lib/docker /etc/docker
    sudo rm -f /etc/apparmor.d/docker
    sudo groupdel docker
    sudo rm -rf /var/run/docker.sock
    sudo rm -rf /usr/bin/docker-compose
}

function install_dock() {
    log 3 "${A_GREEN}Installing Docker...${A_RESET}"
    sudo apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common sudo
    sudo curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
    sudo apt-get update -y
    sudo apt-get install docker-ce -y
    COMPOSE_VERSION=$(sudo curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    # Install docker-compose
    sudo sh -c "sudo curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose"
    sudo chmod +x /usr/local/bin/docker-compose
    sudo sh -c "sudo curl -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose"
    # Output compose version
    docker-compose -v
    sudo curl -fsSL https://get.docker.com/ -o get-docker.sh
    sudo sh get-docker.sh
}

# TODO: I guess we're not supporting long names...
# Parse CLI flags
while getopts "hVvdl:f" opt; do
    case ${opt} in
        h )
            echo "Usage:"
            echo "    -h          Display help"
            echo "    -V          Display version"
            echo "    -v          Set log level to verbose"
            echo "    -d          Set log level to debug"
            echo "    -l LEVEL    Set log level, accepts values or integers (7=silly, 0=critical)"
            echo "    -f          Force reinstallation of Docker"
            exit 0
            ;;
        V )
            VERSION=${VERSION:-"None"}
            echo "Version: $VERSION"
            exit 0
            ;;
        v )
            LOG_LEVEL="verbose"
            ;;
        d )
            LOG_LEVEL="debug"
            ;;
        l )
            LOG_LEVEL=${OPTARG}
            ;;
        f )
            FORCE_REINSTALL=true
            ;;
        \? )
            echo "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# print intro figfont 
echo "              __                __                  __                    
             /\\ \\__            /\\ \\                /\\ \\                   
   __      __\\ \\ ,_\\           \\_\\ \\    ___     ___\\ \\ \\/'\\         ____  
 /'_ \`\\  /'__\`\\ \\ \\/           /'_\` \\  / __\`\\  /'___\\ \\ , <        /',__\\ 
/\\ \\L\\ \\/\\  __/\\ \\ \\_         /\\ \\L\\ \\/\\ \\L\\ \\/\\ \\__/\\ \\ \\\\\`\\   __/\\__, \`\\
\\ \\____ \\ \\____\\\\ \\__\\        \\ \\___,_\\ \\____/\\ \\____\\\\ \\_\\ \\_\\/\\_\\/\\____/
 \\/___L\\ \\/____/ \\/__/  _______\\/__,_ /\\/___/  \\/____/ \\/_/\\/_/\\/_/\\/___/ 
   /\\____/             /\\______\\                                          
   \\_/__/              \\/______/                                          
 __         \n/\\ \\        \n\\ \\ \\___    \n \\ \\  _ \`\\  \n  \\ \\ \\ \\ \\ \n   \\ \\_\\ \\_\\\n    \\/_/\\/_/\n            \n            "

# Check if Docker or Docker Compose are already installed
if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
    if [[ $FORCE_REINSTALL ]]; then
        uninstall_dock
        install_dock
    else
        log 1 "${A_RED}Docker and Docker Compose are already installed. Use -f to reinstall.${A_RESET}"
        exit 1
    fi
else
    if [[ $1 == "install" || -z $1 ]]; then
        install_dock
    elif [[ $1 == "uninstall" ]]; then
        uninstall_dock
    elif [[ $1 == "reinstall" ]]; then
        uninstall_dock
        install_dock
    else
        log 1 "${A_RED}Invalid command. Use install, uninstall, or reinstall.${A_RESET}"
        exit 1
    fi
fi


log 3 "${A_GREEN}Done.${A_RESET}"