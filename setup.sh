#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin"
echo 

##--------------------------------------------------------------------------
#   @author :           aetherinox
#   @script :           Proteus App Manager
#   @when   :           2023-10-09 08:37:31
#   @url    :           https://github.com/Aetherinox/proteus-app-manager
#
#   requires chmod +x setup.sh
#
##--------------------------------------------------------------------------

##--------------------------------------------------------------------------
#   vars > colors
#
#   tput setab  [1-7]       – Set a background color using ANSI escape
#   tput setb   [1-7]       – Set a background color
#   tput setaf  [1-7]       – Set a foreground color using ANSI escape
#   tput setf   [1-7]       – Set a foreground color
##--------------------------------------------------------------------------

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
GREYL=$(tput setaf 242)
DEV=$(tput setaf 157)
DEVGREY=$(tput setaf 243)
FUCHSIA=$(tput setaf 198)
PINK=$(tput setaf 200)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

##--------------------------------------------------------------------------
#   vars > status messages
##--------------------------------------------------------------------------

STATUS_MISS="${BOLD}${GREYL} MISS ${NORMAL}"
STATUS_SKIP="${BOLD}${GREYL} SKIP ${NORMAL}"
STATUS_OK="${BOLD}${GREEN}  OK  ${NORMAL}"
STATUS_FAIL="${BOLD}${RED} FAIL ${NORMAL}"
STATUS_HALT="${BOLD}${YELLOW} HALT ${NORMAL}"

##--------------------------------------------------------------------------
#   vars > app
##--------------------------------------------------------------------------

app_repo_dev="Aetherinox"
app_repo="proteus-app-manager"
app_repo_apt="proteus-apt-repo"
app_repo_url="https://github.com/${app_repo_dev}/${app_repo}"
app_repo_aptpkg="aetherinox-${app_repo_apt}-archive"
app_title="Proteus App Manager (${app_repo_dev})"
app_ver=("1" "0" "0" "5")
app_dir=$PWD
app_dir_hosts="/etc/hosts"
app_dir_swizzin="$app_dir/libraries/swizzin"
apt_dir_deb="/var/cache/apt/archives"
app_file_this=$(basename "$0")
app_pid_spin=0
app_pid=$BASHPID
app_queue_restart=false
app_queue_restart_id="App Manager"
app_queue_restart_delay=1
app_queue_url=()
app_i=0
app_cfg_bDev_str=$([ -n "${OPT_DEV_ENABLE}" ] && echo "Enabled" || echo "Disabled" )

##--------------------------------------------------------------------------
#   vars > logs
##--------------------------------------------------------------------------

export DATE=$(date '+%Y%m%d')
export YEAR=$(date +'%Y')
export TIME=$(date '+%H:%M:%S')
export ARGS=$1
export LOGS_DIR="$app_dir/logs"
export LOGS_FILE="$LOGS_DIR/proteus_${DATE}.log"
export SECONDS=0

##--------------------------------------------------------------------------
#   vars > general
##--------------------------------------------------------------------------

gui_width=540
gui_height=525
gui_column="Available Packages"
gui_about="An app manager which allows you to install applications and packages with very minimal interaction."
gui_desc="Select the app / package you wish to install. Most apps will run as silent installs.\n\nStart typing or press <span color='#3477eb'><b>CTRL+F</b></span> to search for an app\n\nIf you encounter issues, review the logfile located at:\n      <span color='#3477eb'><b>${LOGS_FILE}</b></span>\n\n"

##--------------------------------------------------------------------------
#   distro
#
#   returns distro information.
##--------------------------------------------------------------------------

# freedesktop.org and systemd
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    OS_VER=$VERSION_ID

# linuxbase.org
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    OS_VER=$(lsb_release -sr)

# versions of Debian/Ubuntu without lsb_release cmd
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    OS_VER=$DISTRIB_RELEASE

# older Debian/Ubuntu/etc distros
elif [ -f /etc/debian_version ]; then
    OS=Debian
    OS_VER=$(cat /etc/debian_version)

# fallback: uname, e.g. "Linux <version>", also works for BSD
else
    OS=$(uname -s)
    OS_VER=$(uname -r)
fi

##--------------------------------------------------------------------------
#   func > get version
#
#   returns current version of app
#   converts to human string.
#       e.g.    "1" "2" "4" "0"
#               1.2.4.0
##--------------------------------------------------------------------------

function get_version()
{
    ver_join=${app_ver[@]}
    ver_str=${ver_join// /.}
    echo ${ver_str}
}

##--------------------------------------------------------------------------
#   options
#
#       -d      developer mode
#       -h      help menu
#       -n      developer: null run
#       -s      silent mode | logging disabled
#       -t      theme
##--------------------------------------------------------------------------

function opt_usage()
{
    echo
    printf "  ${BLUE}${app_title}${NORMAL}\n" 1>&2
    printf "  ${GRAY}${gui_about}${NORMAL}\n" 1>&2
    echo
    printf '  %-15s %-40s\n' "Usage:" "${0} [${GREYL}options${NORMAL}]" 1>&2
    printf '  %-15s %-40s\n\n' "    " "${0} [${GREYL}-h${NORMAL}] [${GREYL}-d${NORMAL}] [${GREYL}-n${NORMAL}] [${GREYL}-s${NORMAL}] [${GREYL}-t THEME${NORMAL}] [${GREYL}-v${NORMAL}]" 1>&2
    printf '  %-15s %-40s\n' "Options:" "" 1>&2
    printf '  %-15s %-5s %-40s\n' "    " "-d" "dev mode" 1>&2
    printf '  %-15s %-5s %-40s\n' "    " "-h" "show help menu" 1>&2
    printf '  %-15s %-5s %-40s\n' "    " "-n" "dev: null run" 1>&2
    printf '  %-15s %-5s %-40s\n' "    " "" "simulate app installs (no changes)" 1>&2
    printf '  %-15s %-5s %-40s\n' "    " "-s" "silent mode which disables logging" 1>&2
    printf '  %-15s %-5s %-40s\n' "    " "-t" "specify theme to use" 1>&2
    printf '  %-15s %-5s %-40s\n' "    " "" "    Adwaita" 1>&2
    printf '  %-15s %-5s %-40s\n' "    " "" "    Adwaita-dark" 1>&2
    printf '  %-15s %-5s %-40s\n' "    " "" "    HighContrast" 1>&2
    printf '  %-15s %-5s %-40s\n' "    " "" "    HighContrastInverse" 1>&2
    printf '  %-15s %-5s %-40s\n' "    " "-v" "current version of app manager" 1>&2
    echo
    echo
    exit 1
}

OPTIND=1
while getopts "dhnst:v" opt; do
    case ${opt} in
        d)
            OPT_DEV_ENABLE=true
            echo -e "  ${FUCHSIA}${BLINK}Devmode Enabled${NORMAL}"
            ;;

        h)
            opt_usage
            ;;

        n)
            OPT_DEV_NULLRUN=true
            echo -e "  ${FUCHSIA}${BLINK}Devnull Enabled${NORMAL}"

            ;;

        s)
            OPT_NOLOG=true
            echo -e "  ${FUCHSIA}${BLINK}Logging Disabled{NORMAL}"

            ;;

        t)
            OPT_THEME=${OPTARG}
            ;;

        v)
            echo
            echo -e "  ${GREEN}${BOLD}${app_title}${NORMAL} - v$(get_version)${NORMAL}"
            echo -e "  ${LGRAY}${BOLD}${app_repo_url}${NORMAL}"
            echo -e "  ${LGRAY}${BOLD}${OS} | ${OS_VER}${NORMAL}"
            echo
            exit 1
            ;;

        *)
            opt_usage
            ;;
    esac
done
shift $((OPTIND-1))

##--------------------------------------------------------------------------
#   GTK Theme
#
#   Invalid themes will default to 'Adwaita'
#       -   Adwaita
#       -   Adwaita-dark
#       -   HighContrast
#       -   HighContrastInverse
#       -   dark
#       -   ZorinBlue-Light
#       -   ZorinBlue-Dark
#       -        Red
#       -        Green
#       -        Grey
#       -        Orange
#       -        Purple
#   
#   If we're going for support on Ubuntu and Zorin, set default to theme
#   both commonly share.
#
##--------------------------------------------------------------------------

if [ -z "${OPT_THEME}" ]; then
    OPT_THEME="Adwaita-dark"
fi

export GTK_THEME="${OPT_THEME}"

##--------------------------------------------------------------------------
#   vars > /etc/hosts
#
#   this is for users who want to add new entries in their host file
#   for programs like pihole.
#   once an entry has been added, it will not be re-added if you use the
#   script and install this multiple times.
#
#   do not remove the \t in between the IP and domain. those characters
#   symbolize [TAB] when actually added to the hosts file.
##--------------------------------------------------------------------------

hosts="
127.0.0.5\tdevice.name.domain
127.0.0.6\tdevice.name.domain
127.0.0.7\tdevice.name.domain
"

##--------------------------------------------------------------------------
#   vars > netplan
#
#   these settings are related to the netplan tweak.
#   this action renames your network device from whatever the default
#   may be over to 'eth0'.
#
#   it will also assign a specified static IP address to your network
#   adapter, as well as the default gateway. these are useful if you plan
#   on running a pihole server.
#
#   finally, it will set your network adapter to use Quad9's DNS servers
#       Malware Blocking, DNSSEC Validation
#
#   if you wish to use alternative Quad9 servers for No Malware Blocking
#   or ECS, the list is provided below
#
#   [ QUAD9 DNS ]                                                   DEFAULT
#
#       Malware Blocking, DNSSEC Validation (most typical configuration)
#            IPv4 Primary:          9.9.9.9
#            IPv4 Secondary:        149.112.112.112
#            IPv6 Primary:          2620:fe::fe
#            IPv6 Secondary:        2620:fe::9
#
#       Secured w/ECS: Malware blocking, DNSSEC Validation, ECS enabled
#            IPv4 Primary:          9.9.9.11
#            IPv4 Secondary:        149.112.112.11
#            IPv6 Primary:          2620:fe::11
#            IPv6 Secondary:        2620:fe::fe:11
#
#       Unsecured: No Malware blocking, no DNSSEC validation (experts only!)
#            IPv4 Primary:          9.9.9.10
#            IPv4 Secondary:        149.112.112.10
#            IPv6 Primary:          2620:fe::10
#            IPv6 Secondary:        2620:fe::fe:10
#
#   [ CLOUDFLARE ]                                                  DNSSEC
#
#            IPv4 Primary:          1.1.1.1
#            IPv4 Secondary:        1.0.0.1
#            IPv6 Primary:          2606:4700:4700::1111
#            IPv6 Secondary:        2606:4700:4700::1001
#
#   [ COMODO ]                                                      DNSSEC
#
#            IPv4 Primary:          8.26.56.26
#            IPv4 Secondary:        8.20.247.20
#
#   [ DNS.WATCH ]
#
#            IPv4 Primary:          84.200.69.80
#            IPv4 Secondary:        84.200.70.40
#            IPv6 Primary:          2001:1608:10:25::1c04:b12f
#            IPv6 Secondary:        2001:1608:10:25::9249:d69b
#
#   [ GOOGLE ]                                                 ECS, DNSSEC
#
#            IPv4 Primary:          1.1.1.1
#            IPv4 Secondary:        1.0.0.1
#            IPv6 Primary:          2606:4700:4700::1111
#            IPv6 Secondary:        2606:4700:4700::1001
#
#   [ OPENDNS ]                                                     DNSSEC
#
#            IPv4 Primary:          208.67.222.222
#            IPv4 Secondary:        208.67.220.220
#            IPv6 Primary:          2620:119:35::35
#            IPv6 Secondary:        2620:119:53::53
#
#   [ LEVEL3 ]
#
#            IPv4 Primary:          209.244.0.3
#            IPv4 Secondary:        209.244.0.4
#            IPv6 Primary:          2620:119:35::35
#            IPv6 Secondary:        2620:119:53::53
#
##--------------------------------------------------------------------------

netplan_adapt_old=enp0s3
netplan_adapt_new=eth0
netplan_ip_static=192.168.0.10/24
netplan_ip_gateway=192.168.0.1
netplan_dns_1=9.9.9.9
netplan_dns_2=149.112.112.112
netplan_macaddr=$(cat /sys/class/net/$netplan_adapt_old/address 2> /dev/null )

##--------------------------------------------------------------------------
#   arrays
#
#   stores the list of apps to populate list
##--------------------------------------------------------------------------

apps=()
devs=()

##--------------------------------------------------------------------------
#   func > logs > begin
##--------------------------------------------------------------------------

function Logs_Begin()
{
    if [ $OPT_NOLOG ] ; then
        echo
        echo
        printf '%-57s %-5s' "    Logging for this manager has been disabled." ""
        echo
        echo
        sleep 3
    else
        mkdir -p $LOGS_DIR
        LOGS_PIPE=${LOGS_FILE}.pipe

        # get name of display in use
        local display=":$(ls /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"

        # get user using display
        local user=$(who | grep '('$display')' | awk '{print $1}' | head -n 1)

        if ! [[ -p $LOGS_PIPE ]]; then
            mkfifo -m 775 $LOGS_PIPE
            printf "%-57s %-5s\n" "${TIME}      Creating new pipe ${LOGS_PIPE}" | tee -a "${LOGS_FILE}" >/dev/null
        fi

        LOGS_OBJ=${LOGS_FILE}
        exec 3>&1
        tee -a ${LOGS_OBJ} <$LOGS_PIPE >&3 &
        app_pid_tee=$!
        exec 1>$LOGS_PIPE
        PIPE_OPENED=1

        printf "%-57s %-5s\n" "${TIME}      Logging to ${LOGS_OBJ}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-57s %-5s\n" "${TIME}      Software  : ${app_title}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-57s %-5s\n" "${TIME}      Version   : v$(get_version)" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-57s %-5s\n" "${TIME}      Process   : $$" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-57s %-5s\n" "${TIME}      OS        : ${OS}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-57s %-5s\n" "${TIME}      OS VER    : ${OS_VER}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-57s %-5s\n" "${TIME}      DATE      : ${DATE}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-57s %-5s\n" "${TIME}      TIME      : ${TIME}" | tee -a "${LOGS_FILE}" >/dev/null

    fi
}

##--------------------------------------------------------------------------
#   func > logs > finish
##--------------------------------------------------------------------------

function Logs_Finish()
{
    if [ ${PIPE_OPENED} ] ; then
        exec 1<&3
        sleep 0.2
        ps --pid $app_pid_tee >/dev/null
        if [ $? -eq 0 ] ; then
            # using $(wait $app_pid_tee) would be better
            # however, some commands leave file descriptors open
            sleep 1
            kill $app_pid_tee >> $LOGS_FILE 2>&1
        fi

        printf "%-57s %-15s\n" "${TIME}      Destroying Pipe ${LOGS_PIPE} (${app_pid_tee})" | tee -a "${LOGS_FILE}" >/dev/null

        rm $LOGS_PIPE
        unset PIPE_OPENED
    fi

    duration=$SECONDS
    elapsed="$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

    printf "%-57s %-15s\n" "${TIME}      User Input: OnClick ......... Exit App" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-57s %-15s\n\n\n\n" "${TIME}      ${elapsed}" | tee -a "${LOGS_FILE}" >/dev/null

    sudo pkill -9 -f ".$LOGS_FILE." >> $LOGS_FILE 2>&1
}

##--------------------------------------------------------------------------
#   Begin Logging
##--------------------------------------------------------------------------

Logs_Begin

##--------------------------------------------------------------------------
#   Cache Sudo Password
#
#   require normal user sudo authentication for certain actions
##--------------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    sudo -k # make sure to ask for password on next sudo
    if sudo true && [ -n "${USER}" ]; then
        printf "\n%-57s %-5s\n\n" "${TIME}      SUDO [SIGN-IN]: Welcome, ${USER}" | tee -a "${LOGS_FILE}" >/dev/null
    else
        printf "\n%-57s %-5s\n\n" "${TIME}      SUDO Failure: Wrong Password x3" | tee -a "${LOGS_FILE}" >/dev/null
        exit 1
    fi
else
    if [ -n "${USER}" ]; then
        printf "\n%-57s %-5s\n\n" "${TIME}      SUDO [EXISTING]: $USER" | tee -a "${LOGS_FILE}" >/dev/null
    fi
fi

##--------------------------------------------------------------------------
#   func > spinner animation
##--------------------------------------------------------------------------

spin()
{
    spinner="-\\|/-\\|/"

    while :
    do
        for i in `seq 0 7`
        do
            echo -n "${spinner:$i:1}"
            echo -en "\010"
            sleep 0.4
        done
    done
}

##--------------------------------------------------------------------------
#   func > open url
#
#   opening urls in bash can be wonky as hell. just doing it the manual
#   way to ensure a browser gets opened.
##--------------------------------------------------------------------------

function open_url()
{
   local URL="$1"
   xdg-open $URL || firefox $URL || sensible-browser $URL || x-www-browser $URL || gnome-open $URL
}

##--------------------------------------------------------------------------
#   func > cmd title
##--------------------------------------------------------------------------

function title()
{
    printf '%-57s %-5s' "  ${1}" ""
    sleep 0.3
}

##--------------------------------------------------------------------------
#   func > begin action
##--------------------------------------------------------------------------

function begin()
{
    # start spinner
    spin &

    # spinner PID
    app_pid_spin=$!

    printf "%-57s %-5s\n\n" "${TIME}      NEW Spinner: PID (${app_pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null

    # kill spinner on any signal
    trap "kill -9 $app_pid_spin 2> /dev/null" `seq 0 15`

    printf '%-57s %-5s' "  ${1}" ""

    sleep 0.3
}

##--------------------------------------------------------------------------
#   func > finish action
#
#   this func supports opening a url at the end of the installation
#   however the command needs to have
#       finish "${1}"
#
##--------------------------------------------------------------------------

function finish()
{
    arg1=${1}

    if ps -p $app_pid_spin > /dev/null
    then
        kill -9 $app_pid_spin 2> /dev/null
        printf "\n%-57s %-5s\n" "${TIME}      KILL Spinner: PID (${app_pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null
    fi

    # if arg1 not empty
    if ! [ -z "${arg1}" ]; then
        assoc_uri="${get_docs_uri[$arg1]}"
        app_queue_url+=($assoc_uri)
    fi
}

##--------------------------------------------------------------------------
#   func > exit action
##--------------------------------------------------------------------------

function exit()
{
    finish
    clear
}

##--------------------------------------------------------------------------
#   func > first time setup
#
#   this is the default func executed when script is launched to make sure
#   end-user has all the required libraries.
#
#   since we're working on other distros, add curl and wget into the mix
#   since some distros don't include these.
#
#   [ GPG KEY / APT REPO ]
#
#   NOTE:   can be removed via:
#               sudo rm -rf /etc/apt/sources.list.d/aetherinox*list
#
#           gpg ksy stored in:
#               /usr/share/keyrings/aetherinox-proteus-apt-repo-archive.gpg
#               sudo rm -rf /usr/share/keyrings/aetherinox*gpg
#
#   as of 1.0.0.3-alpha, deprecated apt-key method removed for adding
#   gpg key. view readme for new instructions. registered repo now
#   contains two files
#       -   trusted gpg key:        aetherinox-proteus-apt-repo-archive.gpg
#       -   source .list:           /etc/apt/sources.list.d/aetherinox*list
#
#   ${1}    ReqTitle
#           contains a string if exists
#           triggers is function called from another function to check for
#               a prerequisite
##--------------------------------------------------------------------------

function app_setup
{

    clear

    ReqTitle=${1}
    bMissingCurl=false
    bMissingWget=false
    bMissingNotify=false
    bMissingYad=false
    bMissingGPG=false
    bMissingRepo=false

    # require curl
    if ! [ -x "$(command -v curl)" ]; then
        bMissingCurl=true
    fi

    # require wget
    if ! [ -x "$(command -v wget)" ]; then
        bMissingWget=true
    fi

    # require wget
    if ! [ -x "$(command -v notify-send)" ]; then
        bMissingNotify=true
    fi

    # require yad
    if ! [ -x "$(command -v yad)" ]; then
        bMissingYad=true
    fi

    #   NOTE:   apt-key has been deprecated
    #
    #   sudo add-apt-repository -y "deb [arch=amd64] https://raw.githubusercontent.com/${app_repo_dev}/${app_repo_apt}/master focal main" >> $LOGS_FILE 2>&1

    # Missing proteus-apt-repo gpg key
    if ! [ -f "/usr/share/keyrings/${app_repo_aptpkg}.gpg" ]; then
        bMissingGPG=true
    fi

    # Missing proteus-apt-repo .list
    if ! [ -f "/etc/apt/sources.list.d/${app_repo_aptpkg}.list" ]; then
        bMissingRepo=true
    fi

    # Check if contains title
    # If so, called from another function
    if [ -n "$ReqTitle" ]; then
        if [ "$bMissingCurl" = true ] || [ "$bMissingWget" = true ] || [ "$bMissingNotify" = true ] || [ "$bMissingYad" = true ] || [ "$bMissingGPG" = true ] || [ "$bMissingRepo" = true ]; then
            echo -e "[ ${STATUS_HALT} ]"
        fi
    else
        if [ "$bMissingCurl" = true ] || [ "$bMissingWget" = true ] || [ "$bMissingNotify" = true ] || [ "$bMissingYad" = true ] || [ "$bMissingGPG" = true ] || [ "$bMissingRepo" = true ]; then
            echo
            title "First Time Setup ..."
            echo
            sleep 1
        fi
    fi

    if [ "$bMissingCurl" = true ]; then
        printf "%-57s %-5s\n" "${TIME}      Installing curl package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Adding curl package" ""
        sleep 0.5
        sudo apt-get update -y -q >> /dev/null 2>&1
        sudo apt-get install curl -y -qq >> /dev/null 2>&1
        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    if [ "$bMissingWget" = true ]; then
        printf "%-57s %-5s\n" "${TIME}      Installing wget package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Adding wget package" ""
        sleep 0.5
        sudo apt-get update -y -q >> /dev/null 2>&1
        sudo apt-get install wget -y -qq >> /dev/null 2>&1
        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    if [ "$bMissingNotify" = true ]; then
        printf "%-57s %-5s\n" "${TIME}      Installing notify-send package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Adding notify-send package" ""
        sleep 0.5
        sudo apt-get update -y -q >> /dev/null 2>&1
        sudo apt-get install libnotify-bin notify-osd -y -qq >> /dev/null 2>&1
        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    if [ "$bMissingYad" = true ]; then
        printf "%-57s %-5s\n" "${TIME}      Installing yad package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Adding yad package" ""
        sleep 0.5
        sudo apt-get update -y -q >> /dev/null 2>&1
        sudo apt-get install yad -y -qq >> /dev/null 2>&1
        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    if [ "$bMissingGPG" = true ]; then
        printf "%-57s %-5s\n" "${TIME}      Adding ${app_repo_dev} GPG key: [https://github.com/${app_repo_dev}.gpg]" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Adding github.com/${app_repo_dev}.gpg" ""
        sleep 0.5
        sudo wget -qO - "https://github.com/${app_repo_dev}.gpg" | sudo gpg --batch --yes --dearmor -o "/usr/share/keyrings/${app_repo_aptpkg}.gpg" >> $LOGS_FILE 2>&1
        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    if [ "$bMissingRepo" = true ]; then
        printf "%-57s %-5s\n" "${TIME}      Registering ${app_repo_apt}: https://raw.githubusercontent.com/${app_repo_dev}/${app_repo_apt}/master" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Registering ${app_repo_apt}" ""
        sleep 0.5
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/${app_repo_aptpkg}.gpg] https://raw.githubusercontent.com/${app_repo_dev}/${app_repo_apt}/master $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/${app_repo_aptpkg}.list >> $LOGS_FILE 2>&1
        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"

        printf "%-57s %-5s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Updating repo list" ""
        sleep 0.5
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    if [ -n "$ReqTitle" ]; then
        title "Retry: ${1}"
    fi

    sleep 0.5

}
app_setup

##--------------------------------------------------------------------------
#   func > notify-send
#
#   because this script requires some actions as sudo, notify-send will not
#   work because it has no clue which user to send the notification to.
#
#   use this as a bypass to figure out what user is logged in.
#
#   could use zenity for this, but notifications are limited.
#
#   NOTE:   must be placed after func app_setup() otherwise notify-send
#           will not be detected as installed.
##--------------------------------------------------------------------------

function notify-send()
{
    # func name
    fn_name=${FUNCNAME[0]}

    # get name of display in use
    local display=":$(ls /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"

    # get user using display
    local user=$(who | grep '('$display')' | awk '{print $1}' | head -n 1)

    # detect id of user
    local uid=$(id -u $user)

    sudo -u $user DISPLAY=$display DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus $fn_name "$@"
}

##--------------------------------------------------------------------------
#   output some logging
##--------------------------------------------------------------------------

[ -n "${OPT_DEV_ENABLE}" ] && printf "%-57s %-5s\n" "${TIME}      Notice: Dev Mode Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ -z "${OPT_DEV_ENABLE}" ] && printf "%-57s %-5s\n" "${TIME}      Notice: Dev Mode Disabled" | tee -a "${LOGS_FILE}" >/dev/null

[ -n "${OPT_DEV_NULLRUN}" ] && printf "%-57s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ -z "${OPT_DEV_NULLRUN}" ] && printf "%-57s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Disabled" | tee -a "${LOGS_FILE}" >/dev/null

##--------------------------------------------------------------------------
#   vars > gnome extension ids
##--------------------------------------------------------------------------

app_ext_id_arcmenu=3628
app_ext_id_sysload=4585

##--------------------------------------------------------------------------
#   vars > packages
##--------------------------------------------------------------------------

bInstall_all=true
bInstall_app_alien=true
bInstall_app_appimage=true
bInstall_app_app_outlet=true
bInstall_app_blender_flatpak=true
bInstall_app_blender_snapd=true
bInstall_app_browser_chrome=true
bInstall_app_browser_tor=true
bInstall_app_cdialog=true
bInstall_app_colorpicker_snapd=true
bInstall_app_conky=true
bInstall_app_conky_mngr=true
bInstall_app_curl=true
bInstall_app_flatpak=true
bInstall_app_gdebi=true
bInstall_app_git=true
bInstall_app_github_desktop=true
bInstall_app_gnome_ext_arcmenu=true
bInstall_app_gnome_ext_core=true
bInstall_app_gnome_ext_ism=true
bInstall_app_gnome_tweaks=true
bInstall_app_gpick=true
bInstall_app_kooha=true
bInstall_app_lintian=true
bInstall_app_makedeb=true
bInstall_app_members=true
bInstall_app_mlocate=true
bInstall_app_neofetch=true
bInstall_app_nettools=true
bInstall_app_npm=true
bInstall_app_ocsurl=true
bInstall_app_pacman_game=true
bInstall_app_pacman_manager=true
bInstall_app_pihole=true
bInstall_app_reprepro=true
bInstall_app_rpm=true
bInstall_app_seahorse=true
bInstall_app_snapd=true
bInstall_app_surfshark=true
bInstall_app_swizzin=true
bInstall_app_sysload=true
bInstall_app_teamviewer=true
bInstall_app_tree=true
bInstall_twk_filepath=true
bInstall_twk_netplan=true
bInstall_twk_menu_new_textfile=true
bInstall_twk_network_hosts=true
bInstall_twk_vbox_additions_fix=true
bInstall_app_vsc_stable=true
bInstall_app_vsc_insiders=true
bInstall_app_wxhexeditor=true
bInstall_app_yad=true
bInstall_app_yarn=true
bInstall_app_ziet_cron=true
bInstall_app_zenity=true
bInstall_app_zorinospro_lo=true

##--------------------------------------------------------------------------
#   vars > app names > live
##--------------------------------------------------------------------------

app_all="⭐ All"
app_alien="Alien Package Converter"
app_appimage="AppImage Launcher"
app_app_outlet="App Outlet Manager"
app_blender_flatpak="Blender (using Flatpak)"
app_blender_snapd="Blender (using Snapd)"
app_browser_chrome="Browser: Google Chrome"
app_browser_tor="Browser: Tor"
app_cdialog="cdialog (ComeOn Dialog)"
app_colorpicker_snapd="Color Picker (using Snapd)"
app_conky="Conky"
app_conky_mngr="Conky Manager"
app_curl="curl"
app_flatpak="Flatpak"
app_gdebi="GDebi"
app_git="Git"
app_github_desktop="Github Desktop"
app_gnome_ext_arcmenu="Gnome Ext (ArcMenu)"
app_gnome_ext_core="Gnome Manager (Core)"
app_gnome_ext_ism="Gnome Ext (Speed Monitor)"
app_gnome_tweaks="Gnome Tweaks Tool"
app_gpick="gPick (Color Picker)"
app_kooha="Kooha (Screen Recorder)"
app_lintian="lintian"
app_makedeb="Makedeb"
app_members="members"
app_mlocate="mlocate"
app_neofetch="neofetch"
app_nettools="net-tools"
app_npm="npm"
app_ocsurl="ocs-url"
app_pacman_game="Pacman (Game)"
app_pacman_manager="Pacman (Package Management)"
app_pihole="Pi-Hole"
app_reprepro="reprepro (Apt on Github)"
app_rpm="RPM Package Manager"
app_seahorse="Seahorse (Passwd &amp; Keys)"
app_snapd="Snapd"
app_surfshark="Surfshark VPN"
app_swizzin="Swizzin (Modular Seedbox)"
app_sysload="System Monitor"
app_teamviewer="Teamviewer"
app_tree="tree"
twk_filepath="Patch: Path in File Explorer"
twk_netplan="Patch: Netplan Configuration"
twk_menu_new_textfile="Patch: Add Menu New Text File"
twk_network_hosts="Patch: Update Net Hosts"
twk_vbox_additions_fix="Patch: VBox Additions"
app_unrar="Unrar"
app_vsc_stable="VS Code (Stable)"
app_vsc_insiders="VS Code (Insiders)"
app_wxhexeditor="wxHexEditor"
app_yad="YAD (Yet Another Dialog)"
app_yarn="Yarn"
app_zenity="Zenity Dialogs"
app_ziet_cron="Ziet Cron Manager"
app_zorinospro_lo="ZorinOS Pro: Layouts"

##--------------------------------------------------------------------------
#   vars > app names > dev
##--------------------------------------------------------------------------

app_dev_a="apt-get update"
app_dev_b="apt-get upgrade"
app_dev_c="flatpak: repair"
app_dev_d="snap: refresh"
app_dev_e="Demo Blank E"
app_dev_f="Demo Blank F"

##--------------------------------------------------------------------------
#   associated app functions
##--------------------------------------------------------------------------

declare -A app_functions
app_functions=(
    ["$app_dev_a"]='fn_dev_a'
    ["$app_dev_b"]='fn_dev_b'
    ["$app_dev_c"]='fn_dev_c'
    ["$app_dev_d"]='fn_dev_d'
    ["$app_dev_e"]='fn_dev_e'
    ["$app_dev_f"]='fn_dev_f'

    ["$app_all"]='fn_app_all'
    ["$app_alien"]='fn_app_alien'
    ["$app_appimage"]='fn_app_appimage'
    ["$app_app_outlet"]='fn_app_app_outlet'
    ["$app_blender_flatpak"]='fn_app_blender_flatpak'
    ["$app_blender_snapd"]='fn_app_blender_snapd'
    ["$app_browser_chrome"]='fn_app_browser_chrome'
    ["$app_browser_tor"]='fn_app_browser_tor'
    ["$app_cdialog"]='fn_app_cdialog'
    ["$app_colorpicker_snapd"]='fn_app_colorpicker_snapd'
    ["$app_conky"]='fn_app_conky'
    ["$app_conky_mngr"]='fn_app_conky_mngr'
    ["$app_curl"]='fn_app_curl'
    ["$app_flatpak"]='fn_app_flatpak'
    ["$app_gdebi"]='fn_app_gdebi'
    ["$app_git"]='fn_app_git'
    ["$app_github_desktop"]='fn_app_github_desktop'
    ["$app_gnome_ext_arcmenu"]='fn_app_gnome_ext_arcmenu'
    ["$app_gnome_ext_core"]='fn_app_gnome_ext_core'
    ["$app_gnome_ext_ism"]='fn_app_gnome_ext_ism'
    ["$app_gnome_tweaks"]='fn_app_gnome_tweaks'
    ["$app_gpick"]='fn_app_gpick'
    ["$app_kooha"]='fn_app_kooha'
    ["$app_lintian"]='fn_app_lintian'
    ["$app_makedeb"]='fn_app_makedeb'
    ["$app_members"]='fn_app_members'
    ["$app_mlocate"]='fn_app_mlocate'
    ["$app_neofetch"]='fn_app_neofetch'
    ["$app_nettools"]='fn_app_nettools'
    ["$app_npm"]='fn_app_npm'
    ["$app_ocsurl"]='fn_app_ocsurl'
    ["$app_pacman_game"]='fn_app_pacman_game'
    ["$app_pacman_manager"]='fn_app_pacman_manager'
    ["$app_pihole"]='fn_app_serv_pihole'
    ["$app_reprepro"]='fn_app_reprepro'
    ["$app_rpm"]='fn_app_rpm'
    ["$app_seahorse"]='fn_app_seahorse'
    ["$app_snapd"]='fn_app_snapd'
    ["$app_surfshark"]='fn_app_surfshark'
    ["$app_swizzin"]='fn_app_swizzin'
    ["$app_sysload"]='fn_app_sysload'
    ["$app_teamviewer"]='fn_app_teamviewer'
    ["$app_tree"]='fn_app_tree'
    ["$twk_filepath"]='fn_twk_filepath'
    ["$twk_netplan"]='fn_twk_netplan'
    ["$twk_menu_new_textfile"]='fn_twk_menu_new_textfile'
    ["$twk_network_hosts"]='fn_twk_network_hosts'
    ["$twk_vbox_additions_fix"]='fn_twk_vbox_additions_fix'
    ["$app_unrar"]='fn_app_unrar'
    ["$app_vsc_stable"]='fn_app_vsc_stable'
    ["$app_vsc_insiders"]='fn_app_vsc_insiders'
    ["$app_wxhexeditor"]='fn_app_wxhexeditor'
    ["$app_yad"]='fn_app_yad'
    ["$app_yarn"]='fn_app_yarn'
    ["$app_zenity"]='fn_app_zenity'
    ["$app_ziet_cron"]='fn_app_ziet_cron'
    ["$app_zorinospro_lo"]='fn_app_zorinospro_lo'
)

##--------------------------------------------------------------------------
#   associated app urls
#
#   when certain apps are installed, we may want to open a browser window
#   so that the user can get a better understanding of where to find
#   resources for that app.
#
#   not all apps have to have a website, as that would get annoying.
##--------------------------------------------------------------------------

declare -A get_docs_uri
get_docs_uri=(
    ["$app_alien"]='http://joeyh.name/code/alien/'
    ["$app_conky"]='http://ifxgroup.net/conky.htm'
    ["$app_curl"]='https://manpages.ubuntu.com/manpages/trusty/man1/curl.1.html'
    ["$app_github_desktop"]='https://docs.github.com/en/desktop'
    ["$app_makedeb"]="https://docs.makedeb.org/introduction/welcome/"
    ["$app_snapd"]="https://snapcraft.io/docs"
    ["$app_swizzin"]="https://swizzin.ltd/getting-started"
    ["$app_yad"]="https://mankier.com/1/yad"
    ["$app_zenity"]="https://help.gnome.org/users/zenity/stable/"
    ["$app_zorinospro_lo"]="${app_repo_url}/wiki/Packages#zorinos-pro-layouts"
)

##--------------------------------------------------------------------------
#   Alien package converter
#
#   A program that converts between Red Hat rpm, Debian deb, Stampede slp,
#   Slackware tgz, and Solaris pkg file formats. If you want to use a
#   package from another linux distribution than the one you have
#   installed on your system, you can use alien to convert it to your
#   preferred package format and install it. It also supports LSB packages.
##--------------------------------------------------------------------------

function fn_app_alien()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install alien -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   App Image Launcher
##--------------------------------------------------------------------------

function fn_app_appimage()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo add-apt-repository --yes ppa:appimagelauncher-team/stable >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install appimagelauncher -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   App Outlet
#
#   URL:        https://github.com/AppOutlet/AppOutlet
#   DESC:       App Outlet is a Universal application store. It easily 
#               allows you to search and download applications that runs 
#               on most Linux distributions. It currently supports 
#               AppImages, Flatpaks and Snaps packages.
#   
##--------------------------------------------------------------------------

function fn_app_app_outlet()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        app_setup "${1}"

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install app-outlet -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Blender (using Flatpak)
##--------------------------------------------------------------------------

function fn_app_blender_flatpak()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v flatpak)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_flatpak "${app_flatpak}"

        begin "Retry: ${1}"

        sleep 1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo flatpak repair --system >> $LOGS_FILE 2>&1
        flatpak install flathub org.blender.Blender -y --noninteractive >> $LOGS_FILE 2>&1
    fi

    sleep 1
	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Blender (using Snapd)
##--------------------------------------------------------------------------

function fn_app_blender_snapd()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v snap)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_snapd}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_snapd "${app_snapd}"

        begin "Retry: ${1}"

        sleep 1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo flatpak repair --system >> $LOGS_FILE 2>&1
        flatpak install flathub org.blender.Blender -y --noninteractive >> $LOGS_FILE 2>&1
    fi

    sleep 1
	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Browser: Chrome
##--------------------------------------------------------------------------

function fn_app_browser_chrome()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install wget -y -qq >> $LOGS_FILE 2>&1

        sudo wget -P "${apt_dir_deb}" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" >> $LOGS_FILE 2>&1

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install ${apt_dir_deb}/google-chrome*.deb -f -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Browser: Tor
#
#   URL:        https://torproject.org/download/
#   DESC:       Tor Browser uses the Tor network to protect your privacy
#               and anonymity.
#   
##--------------------------------------------------------------------------

function fn_app_browser_tor()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install tor torbrowser-launcher -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Color Picker
##--------------------------------------------------------------------------

function fn_app_colorpicker_snapd()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v snap)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_snapd}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_snapd "${app_snapd}"

        begin "Retry: ${1}"

        sleep 1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo snap install color-picker >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   cdialog (ComeOn Dialog)
##--------------------------------------------------------------------------

function fn_app_cdialog()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo add-apt-repository --yes universe >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install dialog -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Conky Package
#
#   Conky is a system monitor software. It is free software released 
#   under the terms of the GPL license. Conky is able to monitor many
#   system variables including CPU, memory, swap, disk space,
#   temperature, top, upload, download, system messages, and much more.
#   
#   It is extremely configurable. Conky is a fork of torsmo. 
##--------------------------------------------------------------------------

function fn_app_conky()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then

        sudo add-apt-repository --yes ppa:teejee2008/foss >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install lm-sensors hddtemp -y -qq >> $LOGS_FILE 2>&1
        sleep 1
        yes | sudo sensors-detect >> $LOGS_FILE 2>&1
        sleep 1
        sudo apt-get install conky-all -y -qq >> $LOGS_FILE 2>&1

        # detect CPUs
        get_cpus=$(nproc --all)

        echo -e "[ ${STATUS_OK} ]"
        printf '%-57s %-5s' "    |--- Creating config.conf" ""
        sleep 1

        path_conky="/home/${USER}/.config/conky"
        path_autostart="/home/${USER}/.config/autostart"
        file_config="conky.conf"
        file_autostart="conky.desktop"

        if [ ! -d "${path_conky}" ]; then
            mkdir -p "${path_conky}" >> $LOGS_FILE 2>&1
        fi

        cp "${app_dir}/libraries/conky/conky_base/${file_config}" "${path_conky}/${file_config}"

        # sloppy way, but it works for now
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            while IFS='' read -r a; do
                echo "${a//VAL_CPU/${get_cpus}}"
            done < "${path_conky}/${file_config}" > "${path_conky}/${file_config}.t"

            mv "${path_conky}/${file_config}"{.t,} >> $LOGS_FILE 2>&1

            sleep 3

            while IFS='' read -r a; do
                echo "${a//VAL_GENERATED/${DATE}}"
            done < "${path_conky}/${file_config}" > "${path_conky}/${file_config}.t"

            mv "${path_conky}/${file_config}"{.t,} >> $LOGS_FILE 2>&1
        fi

        echo -e "[ ${STATUS_OK} ]"
        printf '%-57s %-5s' "    |--- Setting perms" ""
        sleep 1

        sudo touch ${path_autostart}/${file_autostart} >> $LOGS_FILE 2>&1
        sudo chgrp ${USER} ${path_autostart}/${file_autostart} >> $LOGS_FILE 2>&1
        sudo chown ${USER} ${path_autostart}/${file_autostart} >> $LOGS_FILE 2>&1
        chmod u+x ${path_autostart}/${file_autostart} >> $LOGS_FILE 2>&1

        echo -e "[ ${STATUS_OK} ]"
        printf '%-57s %-5s' "    |--- Starting conky" ""
        sleep 1

        conky -q -d -c ~/.config/conky/conky.conf >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Conky Manager
#
#   Conky Manager is a graphical front-end for managing Conky config 
#   files. It provides options to start/stop, browse and edit Conky
#   themes installed on the system. Packages are currently available
#   in Launchpad for Ubuntu and derivatives (Linux Mint, etc).
##--------------------------------------------------------------------------

function fn_app_conky_mngr()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo add-apt-repository --yes ppa:teejee2008/foss >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install conky-manager2 -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   curl
##--------------------------------------------------------------------------

function fn_app_curl()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install curl -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Flatpak
##--------------------------------------------------------------------------

function fn_app_flatpak()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install flatpak -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   GDebi .deb package manager
#
#   A tiny little app that helps you install deb files more effectively
#   by handling dependencies. Learn how to use Gdebi and make it the
#   default application for installing deb packages.
##--------------------------------------------------------------------------

function fn_app_gdebi()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo add-apt-repository --yes universe >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install gdebi -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Git
##--------------------------------------------------------------------------

function fn_app_git()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install git -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Github Desktop
##--------------------------------------------------------------------------

function fn_app_github_desktop()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        app_setup "${1}"

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install github-desktop -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Gnome Extension Manager
##--------------------------------------------------------------------------

function fn_app_gnome_ext_core()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v flatpak)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_flatpak "${app_flatpak}"

        begin "Retry: ${1}"

        sleep 1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo flatpak repair --system >> $LOGS_FILE 2>&1
        flatpak install flathub com.mattjakeman.ExtensionManager -y --noninteractive >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Plugins" ""

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get upgrade -q >> $LOGS_FILE 2>&1
        sudo apt-get install gnome-shell-extensions -y -qq >> $LOGS_FILE 2>&1
        sudo apt-get install gnome-tweaks -y -qq >> $LOGS_FILE 2>&1
        sudo apt-get install chrome-gnome-shell -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Installer" ""

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo wget -O gnome-shell-extension-installer -q "https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer" >> $LOGS_FILE 2>&1
        sudo chmod +x gnome-shell-extension-installer
        sudo mv gnome-shell-extension-installer /usr/bin/
    fi

    sleep 1
	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   ArcMenu
#   can be uninstalled with
#       - gnome-extensions uninstall "arcmenu@arcmenu.com"
##--------------------------------------------------------------------------

function fn_app_gnome_ext_arcmenu()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v gnome-shell-extension-installer)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_gnome_ext_core}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_gnome_ext_core "${app_gnome_ext_core}"

        begin "Retry: ${1}"

        sleep 1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        gnome-shell-extension-installer $app_ext_id_arcmenu --yes >> $LOGS_FILE 2>&1
    fi
    
    # END ------------------------------------
    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Restarting Shell" ""
    sleep 3

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo pkill -TERM gnome-shell >> $LOGS_FILE 2>&1
    fi

    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Enable ArcMenu" ""
    sleep 3

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        gnome-extensions enable "arcmenu@arcmenu.com"
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Internet Speed Monitor
##--------------------------------------------------------------------------

function fn_app_gnome_ext_ism()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v gnome-shell-extension-installer)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_gnome_ext_core}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_gnome_ext_core "${app_gnome_ext_core}"

        begin "Retry: ${1}"

        sleep 1
    fi

    # Internet Speed Monitor
    # this is the one with the bar at the bottom with up/down/total text

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        gnome-shell-extension-installer $app_ext_id_sysload --yes >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Restarting Shell" ""
    sleep 3

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo pkill -TERM gnome-shell >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Enabling" ""
    sleep 1

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        gnome-extensions enable "InternetSpeedMonitor@Rishu"
    fi

    sleep 1
	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Gnome Tweaks Tool
##--------------------------------------------------------------------------

function fn_app_gnome_tweaks()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install gnome-tweak-tool -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   gPick (Color Picker)
##--------------------------------------------------------------------------

function fn_app_gpick()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install gpick -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Kooha (Screen Recorder)
##--------------------------------------------------------------------------

function fn_app_kooha()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v flatpak)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_flatpak "${app_flatpak}"

        begin "Retry: ${1}"

        sleep 1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo flatpak repair --system >> $LOGS_FILE 2>&1
        flatpak remote-add --comment="Screen recorder" --if-not-exists flathub "https://flathub.org/repo/flathub.flatpakrepo"
        flatpak install flathub io.github.seadve.Kooha -y --noninteractive >> $LOGS_FILE 2>&1
    fi

    sleep 1
	echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Install pipewire" ""
    sleep 1

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo add-apt-repository --yes ppa:pipewire-debian/pipewire-upstream >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install pipewire -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Lintian
#
#   URL:        https://wiki.debian.org/Teams/Lintian
#   DESC:       required for creating debian packages
#               e.g.
#                   dpkg-deb --root-owner-group --build package-name
#                   lintian package-name.deb --no-tag-display-limit
##--------------------------------------------------------------------------

function fn_app_lintian
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install lintian -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Makedeb 
#
#   URL:        https://www.makedeb.org/
#   DESC:       makedeb creates packages through the use of PKGBUILDs: 
#               packaging format designed to be concise and easy to pick 
#               up, all while remaining powerful enough to match the 
#               flexibility of standard Debian packaging tools.
##--------------------------------------------------------------------------

function fn_app_makedeb()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        export MAKEDEB_RELEASE='makedeb'
        bash -c "$(wget -qO - 'https://shlink.makedeb.org/install')" >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    # arg1      : app name sent to function finish to find associated URL and open
    finish "${1}"
}

##--------------------------------------------------------------------------
#   Member Package > Group Management
##--------------------------------------------------------------------------

function fn_app_members()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install members -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   mlocate
##--------------------------------------------------------------------------

function fn_app_mlocate()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install mlocate -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   neofetch
##--------------------------------------------------------------------------

function fn_app_neofetch()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install neofetch -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   net-tools
##--------------------------------------------------------------------------

function fn_app_nettools()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install net-tools -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   npm
##--------------------------------------------------------------------------

function fn_app_npm()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install npm -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   ocs-url
##--------------------------------------------------------------------------

function fn_app_ocsurl()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        app_setup "${1}"

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install libqt5svg5 qml-module-qtquick-controls -y -qq >> $LOGS_FILE 2>&1
        sleep 1
        sudo apt-get install ocs-url -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Pacman (Game)
#
#   You are Pacman, and you are supposed to eat all the small dots to get to
#   the next level. You are also supposed to keep away from the ghosts,
#   if they take you, you lose one life, unless you have eaten a large dot,
#   then you can, for a limited amount of time, chase and eat the ghosts.
#   There is also bonus available, for a limited amount of time.
#   An X gives just points, but a little pacman gives an extra life.
##--------------------------------------------------------------------------

function fn_app_pacman_game()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install pacman -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Pacman Package Manager
#   
#   Emulates the Archlinux Pacman package manager feel for Debian/Ubuntu 
#   and OpenSUSE users who may prefer the style of Pacman over Apt. 
#
#   This program does not require any additional dependencies!
#   Don't expect all features to be added because Apt simply 
#   doesn't support all Pacman features and some Pacman features 
#   would be too tedious to replicate anyways. 
#
#   Casual users should find no trouble with the lack of features 
#   as all the most common Pacman functionality is present.
#
#   NOTE:       https://gitlab.com/trivoxel/utilities/deb-pacman
##--------------------------------------------------------------------------

function fn_app_pacman_manager()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        app_setup true

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install deb-pacman -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   reprepro
##--------------------------------------------------------------------------

function fn_app_reprepro()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install app_reprepro -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   RPM Package Manager
##--------------------------------------------------------------------------

function fn_app_rpm()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install rpm -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Seahorse Passwords and Keys
##--------------------------------------------------------------------------

function fn_app_seahorse()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then

        echo

        printf '%-57s %-5s' "    |--- Remove Base" ""
        sleep 1
        sudo dpkg -r --force seahorse >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"

        printf '%-57s %-5s' "    |--- Apt Update" ""
        sleep 1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"

        printf '%-57s %-5s' "    |--- Install seahorse" ""
        sleep 1
        sudo apt-get install seahorse -y -qq >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"

        printf '%-57s %-5s' "    |--- Install seahorse-nautilus" ""
        sleep 1
        sudo apt-get install seahorse-nautilus -y -qq >> $LOGS_FILE 2>&1

    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Cache Sudo Password
##--------------------------------------------------------------------------

function fn_app_snapd()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install snapd -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Surfshark VPN
##--------------------------------------------------------------------------

function fn_app_surfshark()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then

        surfshark_url=https://downloads.surfshark.com/linux/debian-install.sh
        surfshark_file=surfshark-install

        sudo wget -O "${surfshark_file}" -q "${surfshark_url}"
        sudo chmod +x "${surfshark_file}" >> $LOGS_FILE 2>&1

        sudo bash "./${surfshark_file}" >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Swizzin
##--------------------------------------------------------------------------

function fn_app_swizzin()
{
    begin "${1}"

    echo

    swizzin_url=s5n.sh
    swizzin_file=swizzin.sh

    sleep 1
    printf '%-57s %-5s' "    |--- Download ${swizzin_url}" ""

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo wget -O "${swizzin_file}" -q "${swizzin_url}"
        sudo chmod +x "${swizzin_file}"
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Adding Zorin Compatibility" ""

    # Add Zorin compatibility to install script
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        while IFS='' read -r a; do
            echo "${a//Debian|Ubuntu/Debian|Ubuntu|Zorin}"
        done < "${swizzin_file}" > "${swizzin_file}.t"

        mv "${swizzin_file}"{.t,} >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Killing apt-get" ""

    # instances where an issue will cause apt-get to hang and keeps the installation
    # wizard from running again. ensure
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo pkill -9 -f "apt-get update" >> $LOGS_FILE 2>&1
    fi

    echo
    sleep 2

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo bash "./${swizzin_file}"
    fi

    finish
}

##--------------------------------------------------------------------------
#   System Load Indicator
##--------------------------------------------------------------------------

function fn_app_sysload()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo add-apt-repository --yes ppa:indicator-multiload/stable-daily >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install indicator-multiload -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Teamviewer
##--------------------------------------------------------------------------

function fn_app_teamviewer()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install -y libminizip1 -qq >> $LOGS_FILE 2>&1

        sudo wget -P "${apt_dir_deb}" "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb" >> $LOGS_FILE 2>&1

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install ${apt_dir_deb}/teamviewer_*.deb -f -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   tree
##--------------------------------------------------------------------------

function fn_app_tree()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install tree -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Pihole
##--------------------------------------------------------------------------

function fn_app_serv_pihole()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get upgrade -q >> $LOGS_FILE 2>&1

        #curl -sSL https://install.pi-hole.net | sudo PIHOLE_SKIP_OS_CHECK=true bash
    fi

	echo -e "[ ${STATUS_OK} ]"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then

        echo
        echo
        echo -e " ${NORMAL} Please specify a Pihole ${GREEN}password${NORMAL}:"
        echo
        echo
        pihole -a -p
        echo
        echo

    fi

    finish
}

##--------------------------------------------------------------------------
#   Tweaks > File Paths in File Browser
##--------------------------------------------------------------------------

function fn_twk_filepath()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then

        # current user
        gsettings set org.gnome.nautilus.preferences always-use-location-entry true >> $LOGS_FILE 2>&1

        # root
        sudo gsettings set org.gnome.nautilus.preferences always-use-location-entry true >> $LOGS_FILE 2>&1

    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Netplan configuration
##--------------------------------------------------------------------------

function fn_twk_netplan()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        if [ -z "${netplan_macaddr}" ]; then
            netplan_macaddr=$(cat /sys/class/net/*/address | awk 'NR == 1' )
        fi

sudo tee /etc/netplan/50-cloud-init.yaml >/dev/null <<EOF
# This file is auto-generated by ${app_title}
# ${app_repo_url}
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    ${netplan_adapt_old}:
      dhcp4: no
      addresses:
        - ${netplan_ip_static}
      gateway4: ${netplan_ip_gateway}
      match:
          macaddress: ${netplan_macaddr}
      set-name: ${netplan_adapt_new}
      nameservers:
          addresses:
              - ${netplan_dns_1}
              - ${netplan_dns_2}
EOF

        # depending on certain configurations, these steps are needed
        sudo systemctl start systemd-networkd >> $LOGS_FILE 2>&1
        sudo netplan apply >> $LOGS_FILE 2>&1
        sleep 2
        udo systemctl restart NetworkManager.service >> $LOGS_FILE 2>&1

    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Tweak: Add 'New Text File' to Context Menu
#
#   DESC:       Creates a new template on Ubuntu systems which adds
#               "New Document" -> "Text File" to the right-click context
#               menu.
#
#               File placed in "~/Templates/Empty\ Document"
##--------------------------------------------------------------------------

function fn_twk_menu_new_textfile()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        path_template_new="/home/${USER}/Templates/Text File.txt"
        if [ ! -f "$path_template_new" ]; then
            echo "ran"
            touch "$path_template_new"
        fi
    else

        sleep 1
        echo -e "[ ${STATUS_OK} ]"

    fi

    finish
}

##--------------------------------------------------------------------------
#   Network host file
##--------------------------------------------------------------------------

function fn_twk_network_hosts()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then

        echo

        if [ ! -f "$app_dir_hosts" ]; then
            touch "$app_dir_hosts"
        fi

        for item in $hosts
        do
            id=$(echo "$item"  | sed 's/ *\\t.*//')

            printf '%-57s %-5s' "    |--- + $id" ""
            sleep 1

            if grep -Fxq "$id" $app_dir_hosts
            then
                echo -e "[ ${STATUS_SKIP} ]"
            else
                sed -i -e '1i'$item "$app_dir_hosts"
                echo -e "[ ${STATUS_OK} ]"
            fi
        done

    else

        sleep 1
        echo -e "[ ${STATUS_OK} ]"

    fi

    finish
}

##--------------------------------------------------------------------------
#   Virtualbox Guest Additional Tools Fix
#
#   there seems to be a difference between ZorinOS Pro and ZorinOS Core
#   ZorinOS Core appears to have VM tools pre-installed which conflicts
#   with the virtualbox guest addition tools. when installing virtualbox
#   guest addition tools, a reboot will cause the system to freeze on the
#   boot screen and take upwards of 5 minutes to fully boot.
#
#   ZorinOS Pro on the other hand, does not have this issue and VirtualBox
#   Guest tools can be installed and work out of box.
#
#   this fix will uninstall the packages:
#       - open-vm-tools-desktop
#       - open-vm-tools
#
#   ZorinOS Pro appears to not have the two packages above installed.
#   this can be confirmed by executing
#       dpkg -l | grep virtualbox
#
#   user can then mount the Virtualbox Guest Additional Tools and use them
#   without issue, and without the massive delay on startup.
##--------------------------------------------------------------------------

function fn_twk_vbox_additions_fix()
{
    begin "${1}"

    echo
    printf '%-57s %-5s' "    |--- Updating packages" ""
    sleep 1

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Installing dependencies" ""
    sleep 1

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get install build-essential make gcc perl dkms linux-headers-$(uname -r) -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Remove open-vm-tools*" ""
    sleep 1

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get remove open-vm-tools -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    
    # apt-get remove doesnt seem to remove everything related to open-vm, so now we have to hit it
    # with a double shot. this is what fixes it.
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo dpkg -P open-vm-tools-desktop >> $LOGS_FILE 2>&1
    fi

    sleep 1

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo dpkg -P open-vm-tools >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    app_queue_restart=true
    app_queue_restart_id="${1}"

    finish
}

##--------------------------------------------------------------------------
#   unrar
##--------------------------------------------------------------------------

function fn_app_unrar()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install unrar -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Visual Studio Code ( Stable )
##--------------------------------------------------------------------------

function fn_app_vsc_stable()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v snap)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_snapd}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_snapd "${app_snapd}"

        begin "Retry: ${1}"

        sleep 1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo snap install --classic code >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Visual Studio Code ( Insiders )
##--------------------------------------------------------------------------

function fn_app_vsc_insiders()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v snap)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_snapd}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_snapd "${app_snapd}"

        begin "Retry: ${1}"

        sleep 1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo snap install --classic code-insiders >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   wxhexeditor
##--------------------------------------------------------------------------

function fn_app_wxhexeditor()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install wxhexeditor -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   YAD (Yet another dialog)
##--------------------------------------------------------------------------

function fn_app_yad()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install yad -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   yarn
##--------------------------------------------------------------------------

function fn_app_yarn()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v npm)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_npm}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_npm "${app_npm}"

        begin "Retry: ${1}"

        sleep 1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        npm install --silent --global yarn >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Zenity Dialogs / GUI
#
#   gives a user the ability to generate custom dialog boxes.
##--------------------------------------------------------------------------

function fn_app_zenity()
{

    if [ -z "${3}" ]; then
        begin "${1}"
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo add-apt-repository --yes universe >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install zenity -y -qq >> $LOGS_FILE 2>&1
    fi

    if [ -z "${3}" ]; then
        sleep 1
        echo -e "[ ${STATUS_OK} ]"
        finish
    fi
}

##--------------------------------------------------------------------------
#   Ziet Cron Manager
##--------------------------------------------------------------------------

function fn_app_ziet_cron()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo add-apt-repository --yes ppa:blaze/main >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install zeit -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   ZorinOS Pro Layouts
#
#   list of layouts provided in ZorinOS Pro
#   served via proteus-apt-repo
##--------------------------------------------------------------------------

function fn_app_zorinospro_lo()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        app_setup true

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install zorin-pro-layouts -y -qq >> $LOGS_FILE 2>&1
        sleep 1
        sudo dpkg -i --force-overwrite "/var/cache/apt/archives/zorin-pro-layouts_*.deb" >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   register apps to show in list
##--------------------------------------------------------------------------

if [ "$bInstall_all" = true ]; then
    apps+=("${app_all}")
fi

if [ "$bInstall_app_alien" = true ]; then
    apps+=("${app_alien}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_appimage" = true ]; then
    apps+=("${app_appimage}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_app_outlet" = true ]; then
    apps+=("${app_app_outlet}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_blender_flatpak" = true ]; then
    apps+=("${app_blender_flatpak}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_blender_snapd" = true ]; then
    apps+=("${app_blender_snapd}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_browser_chrome" = true ]; then
    apps+=("${app_browser_chrome}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_browser_tor" = true ]; then
    apps+=("${app_browser_tor}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_cdialog" = true ]; then
    apps+=("${app_cdialog}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_colorpicker_snapd" = true ]; then
    apps+=("${app_colorpicker_snapd}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_conky" = true ]; then
    apps+=("${app_conky}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_conky_mngr" = true ]; then
    apps+=("${app_conky_mngr}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_curl" = true ]; then
    apps+=("${app_curl}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_flatpak" = true ]; then
    apps+=("${app_flatpak}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_gdebi" = true ]; then
    apps+=("${app_gdebi}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_git" = true ]; then
    apps+=("${app_git}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_github_desktop" = true ]; then
    apps+=("${app_github_desktop}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_gnome_ext_arcmenu" = true ]; then
    apps+=("${app_gnome_ext_arcmenu}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_gnome_ext_core" = true ]; then
    apps+=("${app_gnome_ext_core}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_gnome_ext_ism" = true ]; then
    apps+=("${app_gnome_ext_ism}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_gnome_tweaks" = true ]; then
    apps+=("${app_gnome_tweaks}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_gpick" = true ]; then
    apps+=("${app_gpick}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_kooha" = true ]; then
    apps+=("${app_kooha}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_lintian" = true ]; then
    apps+=("${app_lintian}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_makedeb" = true ]; then
    apps+=("${app_makedeb}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_members" = true ]; then
    apps+=("${app_members}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_mlocate" = true ]; then
    apps+=("${app_mlocate}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_neofetch" = true ]; then
    apps+=("${app_neofetch}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_nettools" = true ]; then
    apps+=("${app_nettools}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_npm" = true ]; then
    apps+=("${app_npm}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_ocsurl" = true ]; then
    apps+=("${app_ocsurl}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_pacman_game" = true ]; then
    apps+=("${app_pacman_game}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_pacman_manager" = true ]; then
    apps+=("${app_pacman_manager}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_pihole" = true ]; then
    apps+=("${app_pihole}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_reprepro" = true ]; then
    apps+=("${app_reprepro}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_rpm" = true ]; then
    apps+=("${app_rpm}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_seahorse" = true ]; then
    apps+=("${app_seahorse}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_snapd" = true ]; then
    apps+=("${app_snapd}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_surfshark" = true ]; then
    apps+=("${app_surfshark}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_swizzin" = true ]; then
    apps+=("${app_swizzin}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_sysload" = true ]; then
    apps+=("${app_sysload}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_teamviewer" = true ]; then
    apps+=("${app_teamviewer}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_tree" = true ]; then
    apps+=("${app_tree}")
    let app_i=app_i+1
fi

if [ "$bInstall_twk_filepath" = true ]; then
    apps+=("${twk_filepath}")
    let app_i=app_i+1
fi

if [ "$bInstall_twk_netplan" = true ]; then
    apps+=("${twk_netplan}")
    let app_i=app_i+1
fi

if [ "$bInstall_twk_menu_new_textfile" = true ]; then
    apps+=("${twk_menu_new_textfile}")
    let app_i=app_i+1
fi

if [ "$bInstall_twk_network_hosts" = true ]; then
    apps+=("${twk_network_hosts}")
    let app_i=app_i+1
fi

if [ "$bInstall_twk_vbox_additions_fix" = true ]; then
    apps+=("${twk_vbox_additions_fix}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_unrar" = true ]; then
    apps+=("${app_unrar}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_vsc_stable" = true ]; then
    apps+=("${app_vsc_stable}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_vsc_insiders" = true ]; then
    apps+=("${app_vsc_insiders}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_wxhexeditor" = true ]; then
    apps+=("${app_wxhexeditor}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_yad" = true ]; then
    apps+=("${app_yad}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_yarn" = true ]; then
    apps+=("${app_yarn}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_zenity" = true ]; then
    apps+=("${app_zenity}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_ziet_cron" = true ]; then
    apps+=("${app_ziet_cron}")
    let app_i=app_i+1
fi

if [ "$bInstall_app_zorinospro_lo" = true ]; then
    apps+=("${app_zorinospro_lo}")
    let app_i=app_i+1
fi

##--------------------------------------------------------------------------
#   dev functions
##--------------------------------------------------------------------------

function fn_dev_a()
{
    begin "${1}"
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"
    finish
}

function fn_dev_b()
{
    begin "${1}"
        sudo apt-get upgrade -q >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"
    finish
}

function fn_dev_c()
{
    begin "${1}"
        sudo flatpak repair --system >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"
    finish
}

function fn_dev_d()
{
    begin "${1}"
        sudo snap refresh >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"
    finish
}

function fn_dev_e()
{
    begin "${1}"
	    echo -e "[ ${STATUS_OK} ]"
    finish
}

function fn_dev_f()
{
    begin "${1}"
	    echo -e "[ ${STATUS_OK} ]"
    finish
}

##--------------------------------------------------------------------------
#   dev menu
#
#   used for testing purposes only
##--------------------------------------------------------------------------

devs+=("${app_dev_a}")
devs+=("${app_dev_b}")
devs+=("${app_dev_c}")
devs+=("${app_dev_d}")
devs+=("${app_dev_e}")
devs+=("${app_dev_f}")

##--------------------------------------------------------------------------
#   All Apps
#
#   installs all applications.
#   needs to be at the end of all other available functions so that an
#   array of apps can be populated.
##--------------------------------------------------------------------------

function fn_app_all()
{
    begin "${app_all}"
    echo

    # prep array to remove 'All' so we dont get an endless loop
    arr_install=("${apps[@]}")
    arr_delete=${app_all}
    for target in "${arr_delete[@]}"; do
        for i in "${!arr_install[@]}"; do
            if [[ ${arr_install[i]} = $target ]]; then
                unset 'arr_install[i]'
            fi
        done
    done

    # ensure code has caught up
    sleep 1

    for i in "${arr_install[@]}"
    do
        assoc_func="${app_functions[$i]}"
        $assoc_func "${i}" "${assoc_func}"
    done

    finish
}

##--------------------------------------------------------------------------
#   header
##--------------------------------------------------------------------------

function show_header()
{
    clear

    sleep 0.3

    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo -e " ${GREEN}${BOLD} ${app_title} - v$(get_version)${NORMAL}${MAGENTA}"
    echo
    echo -e "  This wizard will install some of the basic every-day software that will"
    echo -e "  be needed for this server to operate. It will also apply some OS mods"
    echo -e "  for a better overall experience."
    echo
    echo -e "  Some of these programs and libraries may take up to 10 minutes to"
    echo -e "  install, please do not force close the installer."
    echo
    printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}PID ${NORMAL}" "${BOLD}${FUCHSIA} $$ ${NORMAL}"
    printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}USER ${NORMAL}" "${BOLD}${FUCHSIA} ${USER} ${NORMAL}"
    printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}APPS ${NORMAL}" "${BOLD}${FUCHSIA} ${app_i} ${NORMAL}"
    printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}DEV ${NORMAL}" "${BOLD}${FUCHSIA} ${app_cfg_bDev_str} ${NORMAL}"
    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo

    sleep 0.3

    printf "%-57s %-5s\n" "${TIME}      Successfully loaded ${app_i} apps" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-57s %-5s\n" "${TIME}      Waiting for user input ..." | tee -a "${LOGS_FILE}" >/dev/null

    echo -e "  ${BOLD}${NORMAL}Waiting on selection ..." >&2
    echo
}

function show_about()
{

    yad --about \
    --image=./img/Tux.png \
    --website-label="Github" \
    --website="${app_repo_url}" \
    --authors="${app_repo_dev}" \
    --license="MIT" \
    --comments="An installation manager developed specifically for ZorinOS / Ubuntu 20.04 LTS. " \
    --copyright="Copyright (c) ${YEAR} ${app_repo_dev}" \
    --pversion="v$(get_version)" \
    --pname="Test Application"

}

##--------------------------------------------------------------------------
#   Selection Menu
#
#   allow users to select the desired option manually.
#   this may not be fully integrated yet.
##--------------------------------------------------------------------------

function show_menu()
{

    show_header

    # prep array to remove 'All' so we dont get an endless loop
    app_list=("${apps[@]}")
    arr_delete=${app_all}
    for target in "${arr_delete[@]}"; do
        for i in "${!app_list[@]}"; do
            if [[ ${app_list[i]} = $target ]]; then
                unset 'app_list[i]'
            fi
        done
    done
    if [ -n "${OPT_DEV_ENABLE}" ]; then
        app_list=("${devs[@]}")
    fi

    ##--------------------------------------------------------------------------
    #   sort array
    ##--------------------------------------------------------------------------

    IFS=$'\n' apps_sorted=($(sort <<<"${app_list[*]}"))
    unset IFS

    while true; do
        objlist=$(yad \
        --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
        --width="${gui_width}" \
        --height="${gui_height}" \
        --list \
        --search-column=1 \
        --tooltip-column=1 \
        --title="${app_title} - v$(get_version)" \
        --text="${gui_desc}" \
        --buttons-layout=end \
        --button="Install:0" \
        --button="App Docs!!Click app then click this button to view docs:4" \
        --button="Github:3" \
        --button="!gtk-close!exit:1" \
        --borders=15 \
        --column="${gui_column}" ${app_all} "${apps_sorted[@]}")
        RET=$?
        #echo $RET
        res="${objlist//|}"

        ##--------------------------------------------------------------------------
        #   button > docs
        #
        #   get associated url for app
        ##--------------------------------------------------------------------------

        if [ $RET -eq 4 ]; then
            if ! [ -z "${res}" ] && [ "${res}" != "${app_all}" ]; then
                assoc_uri="${get_docs_uri[$res]}"
                if ! [ -z "${assoc_uri}" ]; then
                    open_url ${assoc_uri}
                else
                    query=$( yad \
                    --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
                    --center \
                    --width=150 \
                    --height=125 \
                    --fixed \
                    --title "No Docs Available" \
                    --borders=10 \
                    --button="!gtk-yes!yes:0" \
                    --button="!gtk-close!exit:1" \
                    --text "The app <span color='#3477eb'><b>${res}</b></span> does not have any provided docs\nor websites to show.\n\nReach out to the developer if you feel this entry should\nhave docs." )
                fi
            else
                query=$( yad \
                --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
                --center \
                --width=150 \
                --height=155 \
                --fixed \
                --title "No Selection" \
                --borders=10 \
                --button="!gtk-yes!yes:0" \
                --button="!gtk-close!exit:1" \
                --text "Select an individual app from the list and then click the <span color='#3477eb'><b>App Docs</b></span>\nbutton to view the documentation.\n\nThe option <span color='#3477eb'><b>${app_all}</b></span> is not a valid option. Do you really want ${app_i}\nbrowser windows open?" )
            fi
            continue
        fi

        ##--------------------------------------------------------------------------
        #   button > github
        ##--------------------------------------------------------------------------

        if [ $RET -eq 3 ]; then
            open_url ${app_repo_url}
            printf "%-57s %-5s\n" "${TIME}      User Input: OnClick ......... Github (Button)" | tee -a "${LOGS_FILE}" >/dev/null
            continue
        fi

        ##--------------------------------------------------------------------------
        #   button > about
        ##--------------------------------------------------------------------------

        if [ $RET -eq 5 ]; then
            ab=$( yad --pname="Test Application" --about )
            continue
        fi

        ##--------------------------------------------------------------------------
        #   kill menu from exit / leave button
        ##--------------------------------------------------------------------------

        if [ $RET -eq 1 ] || [ $RET -eq 252 ]; then
            Logs_Finish
            exit
            sleep 0.2
            break
        fi

        ##--------------------------------------------------------------------------
        #   confirmation dialog to make sure we really want to install
        ##--------------------------------------------------------------------------

        if [ $RET -eq 0 ]; then
            answer=$( yad \
            --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
            --center \
            --width=240 \
            --height=125 \
            --fixed \
            --title "Install ${res}?" \
            --borders=10 \
            --button="!gtk-yes!yes:0" \
            --button="!gtk-close!exit:1" \
            --text "Are you sure you want to install the app\n\n<span color='#3477eb'><b>${res}</b></span>?" )
            ANSWER=$?

            if [ $ANSWER -eq 1 ] || [ $ANSWER -eq 252 ]; then
                continue
            fi
        fi

        ##--------------------------------------------------------------------------
        #   options
        ##--------------------------------------------------------------------------

        case "$res" in
            "${res[0]}")
                printf "%-57s %-15s\n" "${TIME}      User Input: OnClick ......... ${res} (App)" | tee -a "${LOGS_FILE}" >/dev/null

                assoc_func="${app_functions[$res]}"
                $assoc_func "${res}" "${assoc_func}"

                ##--------------------------------------------------------------------------
                #   queue: restart
                ##--------------------------------------------------------------------------

                if [ "$app_queue_restart" = true ]; then
                    prompt_reboot=$( yad \
                    --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
                    --center \
                    --width=150 \
                    --height=125 \
                    --fixed \
                    --margins=15 \
                    --borders=10 \
                    --title "Restart Required" \
                    --button="Restart"\!\!"System restarts in ${app_queue_restart_delay} minute(s)":1 \
                    --button="Later"\!gtk-quit\!"Restart Later":0 \
                    --text "The app <span color='#3477eb'><b>${app_queue_restart_id}</b></span> has requested a restart.\nYour machine will reboot in <span color='#f41881'><b>${app_queue_restart_delay} minute(s)</b></span>." )
                    RET=$?

                    if [ $RET -eq 1 ]; then
                        sleep 1
                        if [ -z "${OPT_DEV_NULLRUN}" ]; then
                            sudo shutdown -r +${app_queue_restart_delay} "System will reboot in ${app_queue_restart_delay} minute" >> $LOGS_FILE 2>&1
                        fi
                        notify-send -u critical "Restart Pending" "A system restart will occur in ${app_queue_restart_delay} minute." >> $LOGS_FILE 2>&1
                        sleep 1
                        finish
                        sleep 1
                        #kill -9 $BASHPID 2> /dev/null
                    fi
                fi

                ##--------------------------------------------------------------------------
                #   queue: pending web urls
                ##--------------------------------------------------------------------------

                for i in "${!app_queue_url[@]}"; do
                    app_url=${app_queue_url[i]}
                    open_url ${app_url}
                    sleep 1
                done

                # clear array
                app_queue_url=()

                ##--------------------------------------------------------------------------
                #   developer logs
                ##--------------------------------------------------------------------------

                if [ -n "${OPT_DEV_ENABLE}" ]; then
                    arr_len=${#app_list[@]}
                    printf "%-42s %-15s" "    |--- ${BOLD}${DEVGREY} Spin PID ${NORMAL}" "${BOLD}${DEV} ${app_pid_spin} ${NORMAL}"
                    printf "\n%-42s %-15s" "    |--- ${BOLD}${DEVGREY} Func ${NORMAL}" "${BOLD}${DEV} ${assoc_func} ${NORMAL}"
                    printf "\n%-42s %-15s" "    |--- ${BOLD}${DEVGREY} Siblings PID ${NORMAL}" "${BOLD}${DEV} ${arr_len} ${NORMAL}"

                    echo
                fi

                ;;
            *)
                echo "Ooops! Invalid option."
            ;;
        esac
    done
}

show_menu app_functions