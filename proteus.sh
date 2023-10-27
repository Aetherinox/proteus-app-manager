#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin"
echo 

##--------------------------------------------------------------------------
#   @author :           aetherinox
#   @script :           Proteus App Manager
#   @when   :           2023-10-26 07:02:08
#   @url    :           https://github.com/Aetherinox/proteus-app-manager
#
#   requires chmod +x setup.sh
##--------------------------------------------------------------------------

##--------------------------------------------------------------------------
#   load secrets file to handle Github rate limiting via a PAF.
#   managed via https://github.com/settings/tokens?type=beta
##--------------------------------------------------------------------------

if [ -f secrets.sh ]; then
. ./secrets.sh
fi

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
ORANGE=$(tput setaf 208)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 156)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 033)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
GREYL=$(tput setaf 242)
DEV=$(tput setaf 157)
DEVGREY=$(tput setaf 243)
FUCHSIA=$(tput setaf 198)
PINK=$(tput setaf 200)
BOLD=$(tput bold)
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

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)
app_dir_home="$HOME/bin"
app_dir_dl="$app_dir_home/downloads"
app_dir_hosts="/etc/hosts"
app_dir_swizzin="$app_dir/libraries/swizzin"
apt_dir_deb="/var/cache/apt/archives"
app_file_this=$(basename "$0")
app_file_proteus="${app_dir_home}/proteus"
app_repo_author="Aetherinox"
app_title_short="Proteus"
app_title="${app_title_short} App Manager (${app_repo_author})"
app_ver=("1" "0" "0" "7")
app_repo="proteus-app-manager"
app_repo_branch="main"
app_repo_apt="proteus-apt-repo"
app_repo_apt_pkg="aetherinox-${app_repo_apt}-archive"
app_repo_url="https://github.com/${app_repo_author}/${app_repo}"
app_mnfst="https://raw.githubusercontent.com/${app_repo_author}/${app_repo}/${app_repo_branch}/manifest.json"
app_script="https://raw.githubusercontent.com/${app_repo_author}/${app_repo}/BRANCH/setup.sh"
app_dir=$PWD
app_nodejs_ver=(16 18 20)
app_php_ver=(php7.3 php7.3-fpm php7.4 php7.4-fpm php8.1 php8.1-fpm php8.2 php8.2-fpm)
app_pid_spin=0
app_pid=$BASHPID
app_queue_restart_delay=1
app_queue_url=()
app_i=0

#   --------------------------------------------------------------
#   vars > define passwd file
#
#   generated passwords will be stored in the app bin folder
#   and the perms on the file being severely restricted.
#   --------------------------------------------------------------

app_dir_bin_pwd="${app_dir_home}/pwd"
app_file_bin_pwd="${app_dir_bin_pwd}/mysql.pwd"

##--------------------------------------------------------------------------
#   exports
#
#   GDK_BACKEND     vital for running proteus in Ubuntu 23 which switches
#                   GNOME from x11 to Wayland as of Ubuntu 21.04 in 2021.
##--------------------------------------------------------------------------

export GDK_BACKEND=x11
export DATE=$(date '+%Y%m%d')
export YEAR=$(date +'%Y')
export TIME=$(date '+%H:%M:%S')
export ARGS=$1
export LOGS_DIR="$app_dir/logs"
export LOGS_FILE="$LOGS_DIR/proteus-${DATE}.log"
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

get_version()
{
    ver_join=${app_ver[*]}
    ver_str=${ver_join// /.}
    echo ${ver_str}
}

##--------------------------------------------------------------------------
#   func > version > compare greater than
#
#   this function compares two versions and determines if an update may
#   be available. or the user is running a lesser version of a program.
##--------------------------------------------------------------------------

get_version_compare_gt()
{
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

##--------------------------------------------------------------------------
#   options
#
#       -d      developer mode
#       -h      help menu
#       -i      install app from cli
#       -n      developer: null run
#       -q      quiet mode | logging disabled
#       -s      setup
#       -t      theme
#       -u      updates Proteus binary
#       -v      display version information
##--------------------------------------------------------------------------

opt_usage()
{
    echo
    printf "  ${BLUE}${app_title}${NORMAL}\n" 1>&2
    printf "  ${GREYL}${gui_about}${NORMAL}\n" 1>&2
    echo
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREYL}options${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${0} [${GREYL}-h${NORMAL}] [${GREYL}-d${NORMAL}] [${GREYL}-n${NORMAL}] [${GREYL}-s${NORMAL}] [${GREYL}-t THEME${NORMAL}] [${GREYL}-v${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREYL}-i \"NodeJS\" --njs-ver 18${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n' "Options:" "" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-d, --dev" "dev mode" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-h, --help" "show help menu" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-i, --install" "install app from cli" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${DEVGREY}-i \"members\"${NORMAL}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "    --njs-ver" "specify nodejs version to install" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    ${DEVGREY}-i \"NodeJS\" --njs-ver 18${NORMAL}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-n, --nullrun" "dev: null run" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "simulate app installs (no changes)" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-q, --quiet" "quiet mode which disables logging" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-t, --theme" "specify theme to use" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    Adwaita" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    Adwaita-dark" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    HighContrast" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "    HighContrastInverse" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-s, --setup" "install all ${app_title_short} prerequisites / dependencies" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-u, --update" "update ${app_file_proteus} executable" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "    --branch" "branch to update from" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-v, --version" "current version of app manager" 1>&2
    echo
    echo
    exit 1
}

OPT_APPS_CLI=()

while [ $# -gt 0 ]; do
  case "$1" in
    --php-ver*)
            if [[ "$1" != *=* ]]; then shift; fi
            arg="${1#*=}"

            if ! [[ $(echo ${app_php_ver[@]} | grep -f -w $arg) ]]; then
                php_available=$(printf " %s" "${app_php_ver[@]}")

                echo -e "  ${NORMAL}Bad PHP version provided."
                echo -e "  ${NORMAL}      Enter One:  ${YELLOW}${php_available}${NORMAL}"
                echo -e "  ${NORMAL}      Example:    ${LGRAY}./setup.sh -n -i php --php-ver 20${NORMAL}"
                echo
                exit 1
            else
                ARG_PHP_VER+=("${arg}")
            fi
            ;;
    --njs-ver*)
            if [[ "$1" != *=* ]]; then shift; fi
            arg="${1#*=}"

            if ! [[ $(echo ${app_nodejs_ver[@]} | grep -f -w $arg) ]]; then
                njs_available=$(printf " %s" "${app_nodejs_ver[@]}")

                echo -e "  ${NORMAL}Bad NodeJS version provided."
                echo -e "  ${NORMAL}      Enter One:  ${YELLOW}${njs_available}${NORMAL}"
                echo -e "  ${NORMAL}      Example:    ${LGRAY}./setup.sh -n -i NodeJS --njs-ver 20${NORMAL}"
                echo
                exit 1
            else
                ARG_NJS_VER+=("${arg}")
            fi
            ;;

    -d|--dev)
            OPT_DEV_ENABLE=true
            echo -e "  ${FUCHSIA}${BLINK}Devmode Enabled${NORMAL}"
            ;;

    -h*|--help*)
            opt_usage
            ;;

    -b*|--branch*)
            if [[ "$1" != *=* ]]; then shift; fi
            OPT_BRANCH="${1#*=}"
            if [ -z "${OPT_BRANCH}" ]; then
                echo -e "  ${NORMAL}Must specify a valid branch"
                echo -e "  ${NORMAL}      Default:  ${YELLOW}${app_repo_branch}${NORMAL}"

                exit 1
            fi
            ;;

    -i*|--install*)
            if [[ "$1" != *=* ]]; then shift; fi
            OPT_APP="${1#*=}"
            OPT_APPS_CLI+=("${OPT_APP}")
            ;;

    -n|--nullrun)
            OPT_DEV_NULLRUN=true
            echo -e "  ${FUCHSIA}${BLINK}Devnull Enabled${NORMAL}"
            ;;

    -q|--quiet)
            OPT_NOLOG=true
            echo -e "  ${FUCHSIA}${BLINK}Logging Disabled{NORMAL}"
            ;;

    -t*|--theme*)
            if [[ "$1" != *=* ]]; then shift; fi
            OPT_THEME="${1#*=}"
            ;;
        
    -u|--update)
            OPT_UPDATE=true
            ;;

    -s|--setup)
            OPT_SETUP=true
            ;;

    -v|--version)
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
  shift
done

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
#   vars > active repo branch
##--------------------------------------------------------------------------

app_repo_branch_sel=$( [[ -n "$OPT_BRANCH" ]] && echo "$OPT_BRANCH" || echo "$app_repo_branch"  )

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
netplan_macaddr=$( cat /sys/class/net/$netplan_adapt_old/address 2> /dev/null )

##--------------------------------------------------------------------------
#   arrays
#
#   stores the list of apps to populate list
##--------------------------------------------------------------------------

apps=()
devs=()

##--------------------------------------------------------------------------
#   line > comment
#
#   comment REGEX FILE [COMMENT-MARK]
#   comment "skip-grant-tables" "/etc/mysql/my.cnf"
##--------------------------------------------------------------------------

line_comment()
{
    local regx="${1:?}"
    local targ="${2:?}"
    local mark="${3:-#}"
    sudo sed -ri "s:^([ ]*)($regx):\\1$mark\\2:" "$targ"
}

##--------------------------------------------------------------------------
#   line > uncomment
#
#   uncomment REGEX FILE [COMMENT-MARK]
#   uncomment "skip-grant-tables" "/etc/mysql/my.cnf"
##--------------------------------------------------------------------------

line_uncomment()
{
    local regx="${1:?}"
    local targ="${2:?}"
    local mark="${3:-#}"
    sudo sed -ri "s:^([ ]*)[$mark]+[ ]?([ ]*$regx):\\1\\2:" "$targ"
}

##--------------------------------------------------------------------------
#   func > logs > begin
##--------------------------------------------------------------------------

Logs_Begin()
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
            printf "%-57s\n" "${TIME}      Creating new pipe ${LOGS_PIPE}" | tee -a "${LOGS_FILE}" >/dev/null
        fi

        LOGS_OBJ=${LOGS_FILE}
        exec 3>&1
        tee -a ${LOGS_OBJ} <$LOGS_PIPE >&3 &
        app_pid_tee=$!
        exec 1>$LOGS_PIPE
        PIPE_OPENED=1

        printf "%-57s\n" "${TIME}      Logging to ${LOGS_OBJ}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-57s\n" "${TIME}      Software  : ${app_title}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-57s\n" "${TIME}      Version   : v$(get_version)" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-57s\n" "${TIME}      Process   : $$" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-57s\n" "${TIME}      OS        : ${OS}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-57s\n" "${TIME}      OS VER    : ${OS_VER}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-57s\n" "${TIME}      DATE      : ${DATE}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-57s\n" "${TIME}      TIME      : ${TIME}" | tee -a "${LOGS_FILE}" >/dev/null

    fi
}

##--------------------------------------------------------------------------
#   func > logs > finish
##--------------------------------------------------------------------------

Logs_Finish()
{
    if [ ${PIPE_OPENED} ] ; then
        exec 1<&3
        sleep 0.2
        ps --pid $app_pid_tee >/dev/null
        local pipe_status=$?
        if [ $pipe_status -eq 0 ] ; then
            # using $(wait $app_pid_tee) would be better
            # however, some commands leave file descriptors open
            sleep 1
            kill $app_pid_tee >> $LOGS_FILE 2>&1
        fi

        printf "%-57s\n" "${TIME}      Destroying Pipe ${LOGS_PIPE} (${app_pid_tee})" | tee -a "${LOGS_FILE}" >/dev/null

        rm $LOGS_PIPE
        unset PIPE_OPENED
    fi

    duration=$SECONDS
    elapsed="$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

    printf "%-57s\n" "${TIME}      User Input: OnClick ......... Exit App" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-57s\n\n\n\n" "${TIME}      ${elapsed}" | tee -a "${LOGS_FILE}" >/dev/null
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
        printf "\n%-57s\n\n" "${TIME}      SUDO [SIGN-IN]: Welcome, ${USER}" | tee -a "${LOGS_FILE}" >/dev/null
    else
        printf "\n%-57s\n\n" "${TIME}      SUDO Failure: Wrong Password x3" | tee -a "${LOGS_FILE}" >/dev/null
        exit 1
    fi
else
    if [ -n "${USER}" ]; then
        printf "\n%-57s\n\n" "${TIME}      SUDO [EXISTING]: $USER" | tee -a "${LOGS_FILE}" >/dev/null
    fi
fi

##--------------------------------------------------------------------------
#   header > with comment
##--------------------------------------------------------------------------

show_header_comment()
{
    local reason=$([ "${1}" ] && echo "${1}" || echo "Not Specified" )

    clear

    sleep 0.3

    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo -e "  ${YELLOW}${reason}"${NORMAL}
    echo -e "  "
    echo -e "  ${WHITE}Please select another option.${NORMAL}"
    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo

    sleep 0.3

    echo -e "  ${BOLD}${NORMAL}Waiting on selection ..." >&2
    echo
}

##--------------------------------------------------------------------------
#   func > spinner animation
##--------------------------------------------------------------------------

spin()
{
    spinner="-\\|/-\\|/"

    while :
    do
        for i in $(seq 0 7)
        do
            echo -n "${spinner:$i:1}"
            echo -en "\010"
            sleep 0.4
        done
    done
}

##--------------------------------------------------------------------------
#   func > spinner > halt
##--------------------------------------------------------------------------

spinner_halt()
{
    if ps -p $app_pid_spin > /dev/null
    then
        kill -9 $app_pid_spin 2> /dev/null
        printf "\n%-57s\n" "${TIME}      KILL Spinner: PID (${app_pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null
    fi
}

##--------------------------------------------------------------------------
#   func > cli selection menu
##--------------------------------------------------------------------------

cli_options()
{
    opts_show()
    {
        local it=$1
        for i in ${!CHOICES[*]}; do
            if [[ "$i" == "$it" ]]; then
                tput rev
                printf '\e[1;33m'
                printf '%4d. \e[1m\e[33m %s\t\e[0m\n' $i "${LIME_YELLOW}  ${CHOICES[$i]}  "
                tput sgr0
            else
                printf '\e[1;33m'
                printf '%4d. \e[1m\e[33m %s\t\e[0m\n' $i "${LIME_YELLOW}  ${CHOICES[$i]}  "
            fi
            tput cuf 2
        done
    }

    tput civis
    it=0
    tput cuf 2

    opts_show $it

    while true; do
        read -rsn1 key
        local escaped_char=$( printf "\u1b" )
        if [[ $key == $escaped_char ]]; then
            read -rsn2 key
        fi

        tput cuu ${#CHOICES[@]} && tput ed
        tput sc

        case $key in
            '[A' | '[C' )
                it=$(($it-1));;
            '[D' | '[B')
                it=$(($it+1));;
            '' )
                return $it && exit;;
        esac

        local min_len=0
        local farr_len=$(( ${#CHOICES[@]}-1))
        if [[ "$it" -lt "$min_len" ]]; then
            it=$(( ${#CHOICES[@]}-1 ))
        elif [[ "$it" -gt "$farr_len"  ]]; then
            it=0
        fi

        opts_show $it

    done
}

##--------------------------------------------------------------------------
#   func > cli question
#
#   used for command-line to prompt the user with a question
##--------------------------------------------------------------------------

cli_question( )
{
    local syntax def response

    while true; do

        # end argument determines type of syntax
        if [ "${2:-}" = "Y" ]; then
            syntax="Y / n"
            def=Y
        elif [ "${2:-}" = "N" ]; then
            syntax="y / N"
            def=N
        else
            syntax="Y / N"
            def=
        fi

        #printf '%-60s %13s %-5s' "    $1 " "${YELLOW}[$syntax]${NORMAL}" ""
        echo -n "$1 [$syntax] "

        read -r response </dev/tty

        # NULL response uses default
        if [ -z "$response" ]; then
            response=$def
        fi

        # validate response
        case "$response" in
            Y|y|yes|YES)
                return 0
                ;;
            N|n|no|NO)
                return 1
                ;;
        esac

    done
}

##--------------------------------------------------------------------------
#   func > open url
#
#   opening urls in bash can be wonky as hell. just doing it the manual
#   way to ensure a browser gets opened.
##--------------------------------------------------------------------------

open_url()
{
   local URL="$1"
   xdg-open $URL || firefox $URL || sensible-browser $URL || x-www-browser $URL || gnome-open $URL
}

##--------------------------------------------------------------------------
#   func > cmd title
##--------------------------------------------------------------------------

title()
{
    printf '%-57s %-5s' "  ${1}" ""
    sleep 0.3
}

##--------------------------------------------------------------------------
#   func > begin action
##--------------------------------------------------------------------------

begin()
{
    # start spinner
    spin &

    # spinner PID
    app_pid_spin=$!

    printf "%-57s\n\n" "${TIME}      NEW Spinner: PID (${app_pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null

    # kill spinner on any signal
    trap "kill -9 $app_pid_spin 2> /dev/null" $(seq 0 15)

    printf '%-57s %-5s' "  ${1}" ""

    sleep 0.3
}

##--------------------------------------------------------------------------
#   func > finish action
#
#   this func supports opening a url at the end of the installation
#   however the command needs to have
#       finish "${1}"
##--------------------------------------------------------------------------

finish()
{
    arg1=${1}

    spinner_halt

    # if arg1 not empty
    if ! [ -z "${arg1}" ]; then
        assoc_uri="${get_docs_uri[$arg1]}"
        app_queue_url+=($assoc_uri)
    fi
}

##--------------------------------------------------------------------------
#   func > exit action
##--------------------------------------------------------------------------

exit()
{
    finish
    clear
}

##--------------------------------------------------------------------------
#   func > env path (add)
#
#   creates a new file inside /etc/profile.d/ which includes the new
#   proteus bin folder.
#
#   export PATH="$HOME/bin:$PATH"
##--------------------------------------------------------------------------

envpath_add()
{
    local file_env=/etc/profile.d/proteus.sh
    if [ "$2" = "force" ] || ! echo $PATH | $(which egrep) -q "(^|:)$1($|:)" ; then
        if [ "$2" = "after" ] ; then
            echo 'export PATH="$PATH:'$1'"' | sudo tee $file_env > /dev/null
        else
            echo 'export PATH="'$1':$PATH"' | sudo tee $file_env > /dev/null
        fi
    fi
}

##--------------------------------------------------------------------------
#   func > app update
#
#   updates the /home/USER/bin/proteus file which allows proteus to be
#   ran from anywhere.
##--------------------------------------------------------------------------

app_update()
{
    local repo_branch=$([ "${1}" ] && echo "${1}" || echo "${app_repo_branch}" )
    local branch_uri="${app_script/BRANCH/"$repo_branch"}"
    local IsSilent=${2}

    begin "Updating from branch [${repo_branch}]"

    sleep 1
    echo

    printf '%-57s %-5s' "    |--- Downloading update" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo wget -O "${app_file_proteus}" -q "$branch_uri" >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-57s %-5s' "    |--- Set ownership to ${USER}" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chgrp ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
        sudo chown ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-57s %-5s' "    |--- Set perms to u+x" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chmod u+x ${app_file_proteus} >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    echo

    sleep 1
    echo -e "  ${BOLD}${GREEN}Update Complete!${NORMAL}" >&2
    sleep 1

    finish
}

##--------------------------------------------------------------------------
#   func > app update
#
#   updates the /home/USER/bin/proteus file which allows proteus to be
#   ran from anywhere.
##--------------------------------------------------------------------------

if [ "$OPT_UPDATE" = true ]; then
    app_update ${app_repo_branch_sel}
fi

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

app_setup()
{

    clear

    local ReqTitle=${1}
    local bMissingWhip=false
    local bMissingCurl=false
    local bMissingWget=false
    local bMissingNotify=false
    local bMissingYad=false
    local bMissingGPG=false
    local bMissingRepo=false

    # require whiptail
    if ! [ -x "$(command -v whiptail)" ]; then
        bMissingWhip=true
    fi

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

    ##--------------------------------------------------------------------------
    #   add universe repo
    ##--------------------------------------------------------------------------

    sudo add-apt-repository --yes universe >> $LOGS_FILE 2>&1

    ##--------------------------------------------------------------------------
    #   Missing proteus-apt-repo gpg key
    #
    #   NOTE:   apt-key has been deprecated
    #           sudo add-apt-repository -y "deb [arch=amd64] https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}/master focal main" >> $LOGS_FILE 2>&1
    ##--------------------------------------------------------------------------

    if ! [ -f "/usr/share/keyrings/${app_repo_apt_pkg}.gpg" ]; then
        bMissingGPG=true
    fi

    ##--------------------------------------------------------------------------
    #   Missing proteus-apt-repo .list
    ##--------------------------------------------------------------------------

    if ! [ -f "/etc/apt/sources.list.d/${app_repo_apt_pkg}.list" ]; then
        bMissingRepo=true
    fi

    # Check if contains title
    # If so, called from another function
    if [ -n "$ReqTitle" ]; then
        if [ "$bMissingWhip" = true ] || [ "$bMissingCurl" = true ] || [ "$bMissingWget" = true ] || [ "$bMissingNotify" = true ] || [ "$bMissingYad" = true ] || [ "$bMissingGPG" = true ] || [ "$bMissingRepo" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            echo -e "[ ${STATUS_HALT} ]"
        fi
    else
        if [ "$bMissingWhip" = true ] || [ "$bMissingCurl" = true ] || [ "$bMissingWget" = true ] || [ "$bMissingNotify" = true ] || [ "$bMissingYad" = true ] || [ "$bMissingGPG" = true ] || [ "$bMissingRepo" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            echo
            title "First Time Setup ..."
            echo
            sleep 1
        fi
    fi

    ##--------------------------------------------------------------------------
    #   missing whiptail
    ##--------------------------------------------------------------------------

    if [ "$bMissingWhip" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-57s\n" "${TIME}      Installing whiptail package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Adding whiptail package" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install whiptail -y -qq >> /dev/null 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing curl
    ##--------------------------------------------------------------------------

    if [ "$bMissingCurl" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-57s\n" "${TIME}      Installing curl package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Adding curl package" ""
        sleep 0.5
    
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install curl -y -qq >> /dev/null 2>&1
        fi
    
        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing wget
    ##--------------------------------------------------------------------------

    if [ "$bMissingWget" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-57s\n" "${TIME}      Installing wget package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Adding wget package" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install wget -y -qq >> /dev/null 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing notify
    ##--------------------------------------------------------------------------

    if [ "$bMissingNotify" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-57s\n" "${TIME}      Installing notify-send package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Adding notify-send package" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install libnotify-bin notify-osd -y -qq >> /dev/null 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing yad
    ##--------------------------------------------------------------------------

    if [ "$bMissingYad" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-57s\n" "${TIME}      Installing yad package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Adding yad package" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install yad -y -qq >> /dev/null 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing gpg
    ##--------------------------------------------------------------------------

    if [ "$bMissingGPG" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-57s\n" "${TIME}      Adding ${app_repo_author} GPG key: [https://github.com/${app_repo_author}.gpg]" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Adding github.com/${app_repo_author}.gpg" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo wget -qO - "https://github.com/${app_repo_author}.gpg" | sudo gpg --batch --yes --dearmor -o "/usr/share/keyrings/${app_repo_apt_pkg}.gpg" >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing proteus apt repo
    ##--------------------------------------------------------------------------

    if [ "$bMissingRepo" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-57s\n" "${TIME}      Registering ${app_repo_apt}: https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}/master" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Registering ${app_repo_apt}" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/${app_repo_apt_pkg}.gpg] https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}/master $(lsb_release -cs) ${app_repo_branch}" | sudo tee /etc/apt/sources.list.d/${app_repo_apt_pkg}.list >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"

        printf "%-57s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Updating repo list" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   install app manager proteus file in /HOME/USER/bin/proteus
    ##--------------------------------------------------------------------------

    if ! [ -f "$app_file_proteus" ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-57s\n" "${TIME}      Installing App Manager" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-57s %-5s' "    |--- Installing App Manager" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            mkdir -p "$app_dir_home"

            local branch_uri="${app_script/BRANCH/"$app_repo_branch_sel"}"
            sudo wget -O "${app_file_proteus}" -q "$branch_uri" >> $LOGS_FILE 2>&1
            sudo chgrp ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
            sudo chown ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
            sudo chmod u+x ${app_file_proteus} >> $LOGS_FILE 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   add env path /home/USER/bin/
    ##--------------------------------------------------------------------------

    envpath_add '$HOME/bin'

    if [ -n "$ReqTitle" ]; then
        title "Retry: ${1}"
    fi

    sleep 0.5

}
app_setup

##--------------------------------------------------------------------------
#   func > app setup
#
#   forces the setup function to run
##--------------------------------------------------------------------------

if [ "$OPT_SETUP" = true ]; then
    app_setup

    printf '%-35s\n' "  ${BOLD}${DEVGREY}Setup Successfully Ran${NORMAL}"
    printf '%-35s\n' "  ${WHITE}To launch ${app_title_short}, run the command without the${NORMAL}"
    printf '%-35s\n' "  ${BOLD}${BLUE}-s${NORMAL} option.${NORMAL}"

    sleep 5
    exit 2
fi

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

notify-send()
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

[ -n "${OPT_DEV_ENABLE}" ] && printf "%-57s\n" "${TIME}      Notice: Dev Mode Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ -z "${OPT_DEV_ENABLE}" ] && printf "%-57s\n" "${TIME}      Notice: Dev Mode Disabled" | tee -a "${LOGS_FILE}" >/dev/null

[ -n "${OPT_DEV_NULLRUN}" ] && printf "%-57s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ -z "${OPT_DEV_NULLRUN}" ] && printf "%-57s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Disabled" | tee -a "${LOGS_FILE}" >/dev/null

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
bInstall_app_argon2=true
bInstall_app_blender_flatpak=true
bInstall_app_blender_snapd=true
bInstall_app_browser_chrome=true
bInstall_app_browser_librewolf=true
bInstall_app_browser_tor=true
bInstall_app_cdialog=true
bInstall_app_colorpicker_snapd=true
bInstall_app_conky=true
bInstall_app_conky_mngr=true
bInstall_app_curl=true
bInstall_app_debian_goodies=true
bInstall_app_debget=true
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
bInstall_app_mysql=true
bInstall_app_neofetch=true
bInstall_app_nginx=true
bInstall_app_nettools=true
bInstall_app_nodejs=true
bInstall_app_npm=true
bInstall_app_ocsurl=true
bInstall_app_pacman_game=true
bInstall_app_pacman_manager=true
bInstall_app_php=true
bInstall_app_phpmyadmin=true
bInstall_app_pihole=true
bInstall_app_python3_pip=true
bInstall_app_reprepro=true
bInstall_app_rpm=true
bInstall_app_seahorse=true
bInstall_app_snapd=true
bInstall_app_surfshark=true
bInstall_app_swizzin=true
bInstall_app_sysload=true
bInstall_app_teamviewer=true
bInstall_app_terminology=true
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
app_app_argon2="Argon 2"
app_blender_flatpak="Blender (using Flatpak)"
app_blender_snapd="Blender (using Snapd)"
app_browser_chrome="Browser: Google Chrome"
app_browser_librewolf="Browser: Librewolf"
app_browser_tor="Browser: Tor"
app_cdialog="cdialog (ComeOn Dialog)"
app_colorpicker_snapd="Color Picker (using Snapd)"
app_conky="Conky"
app_conky_mngr="Conky Manager"
app_curl="curl"
app_debian_goodies="Debian Goodies"
app_debget="deb-get"
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
app_lintian="Lintian"
app_makedeb="Makedeb"
app_members="Members"
app_mlocate="mlocate"
app_mysql="MySQL"
app_neofetch="Neofetch"
app_nginx="Nginx"
app_nettools="net-tools"
app_nodejs="NodeJS"
app_npm="NPM"
app_ocsurl="ocs-url"
app_pacman_game="Pacman (Game)"
app_pacman_manager="Pacman (Package Management)"
app_php="Php"
app_phpmyadmin="PhpMyAdmin"
app_python3_pip="Python: Pip"
app_pihole="Pi-Hole"
app_reprepro="Reprepro"
app_rpm="RPM Package Manager"
app_seahorse="Seahorse (Passwd &amp; Keys)"
app_snapd="Snapd"
app_surfshark="Surfshark VPN"
app_swizzin="Swizzin (Modular Seedbox)"
app_sysload="System Monitor"
app_teamviewer="Teamviewer"
app_terminology="Terminology"
app_tree="Tree"
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
    ["$app_app_argon2"]='fn_app_argon2'
    ["$app_blender_flatpak"]='fn_app_blender_flatpak'
    ["$app_blender_snapd"]='fn_app_blender_snapd'
    ["$app_browser_chrome"]='fn_app_browser_chrome'
    ["$app_browser_librewolf"]='fn_app_browser_librewolf'
    ["$app_browser_tor"]='fn_app_browser_tor'
    ["$app_cdialog"]='fn_app_cdialog'
    ["$app_colorpicker_snapd"]='fn_app_colorpicker_snapd'
    ["$app_conky"]='fn_app_conky'
    ["$app_conky_mngr"]='fn_app_conky_mngr'
    ["$app_curl"]='fn_app_curl'
    ["$app_debian_goodies"]='fn_debian_goodies'
    ["$app_debget"]='fn_app_debget'
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
    ["$app_mysql"]='fn_app_mysql'
    ["$app_neofetch"]='fn_app_neofetch'
    ["$app_nodejs"]='fn_app_nodejs'
    ["$app_nginx"]='fn_app_nginx'
    ["$app_nettools"]='fn_app_nettools'
    ["$app_npm"]='fn_app_npm'
    ["$app_ocsurl"]='fn_app_ocsurl'
    ["$app_pacman_game"]='fn_app_pacman_game'
    ["$app_pacman_manager"]='fn_app_pacman_manager'
    ["$app_php"]='fn_app_php'
    ["$app_phpmyadmin"]='fn_app_phpmyadmin'
    ["$app_pihole"]='fn_app_pihole'
    ["$app_python3_pip"]='fn_app_python3_pip'
    ["$app_reprepro"]='fn_app_reprepro'
    ["$app_rpm"]='fn_app_rpm'
    ["$app_seahorse"]='fn_app_seahorse'
    ["$app_snapd"]='fn_app_snapd'
    ["$app_surfshark"]='fn_app_surfshark'
    ["$app_swizzin"]='fn_app_swizzin'
    ["$app_sysload"]='fn_app_sysload'
    ["$app_teamviewer"]='fn_app_teamviewer'
    ["$app_terminology"]='fn_app_terminology'
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

fn_app_alien()
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

fn_app_appimage()
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

fn_app_app_outlet()
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
#   Argon2
#
#   URL:        https://packages.ubuntu.com/search?keywords=argon2
#   DESC:       argon2: memory-hard hashing function - utility
#               useful for hashing tokens with Bitwarden / Vaultwarden.
#   
##--------------------------------------------------------------------------

fn_app_app_outlet()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        app_setup "${1}"

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install argon2 -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Blender (using Flatpak)
##--------------------------------------------------------------------------

fn_app_blender_flatpak()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v flatpak)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${ORANGE}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing ...${NORMAL}" >&2
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

fn_app_blender_snapd()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v snap)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${ORANGE}Error:${NORMAL}${GREYL} Missing ${app_snapd}. Installing ...${NORMAL}" >&2
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

fn_app_browser_chrome()
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
#   Browser: librewolf
##--------------------------------------------------------------------------

fn_app_browser_librewolf()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install wget gnupg lsb-release apt-transport-https ca-certificates -y -qq >> $LOGS_FILE 2>&1

        distro=$(if echo " una bookworm vanessa focal jammy bullseye vera uma " | grep -q " $(lsb_release -sc) "; then lsb_release -sc; else echo focal; fi)

        sudo wget -O- https://deb.librewolf.net/keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/librewolf.gpg >> $LOGS_FILE 2>&1

sudo tee /etc/apt/sources.list.d/librewolf.sources << EOF > /dev/null
Types: deb
URIs: https://deb.librewolf.net
Suites: $distro
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/librewolf.gpg
EOF

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install librewolf -y -qq >> $LOGS_FILE 2>&1
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

fn_app_browser_tor()
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

fn_app_colorpicker_snapd()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v snap)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${ORANGE}Error:${NORMAL}${GREYL} Missing ${app_snapd}. Installing ...${NORMAL}" >&2
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

fn_app_cdialog()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
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
#   URL:        https://github.com/brndnmtthws/conky
#   DESC:       Conky is a system monitor software. It is free 
#               software released. under the terms of the GPL license. 
#               Conky is able to monitor many system variables 
#               including CPU, memory, swap, disk space,
#               temperature, top, upload, download, system messages, 
#               and much more.
#   
#               It is extremely configurable. Conky is a fork of torsmo. 
##--------------------------------------------------------------------------

fn_app_conky()
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
    fi

    # detect CPUs
    local get_cpus=$(nproc --all)

    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Creating config.conf" ""
    sleep 1

    local path_conky="/home/${USER}/.config/conky"
    local path_autostart="/home/${USER}/.config/autostart"
    local file_config="conky.conf"
    local file_autostart="conky.desktop"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
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
    fi

    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Setting perms" ""
    sleep 1

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo touch ${path_autostart}/${file_autostart} >> $LOGS_FILE 2>&1
        sudo chgrp ${USER} ${path_autostart}/${file_autostart} >> $LOGS_FILE 2>&1
        sudo chown ${USER} ${path_autostart}/${file_autostart} >> $LOGS_FILE 2>&1
        sudo chmod u+x ${path_autostart}/${file_autostart} >> $LOGS_FILE 2>&1
    fi

    echo -e "[ ${STATUS_OK} ]"
    printf '%-57s %-5s' "    |--- Starting conky" ""
    sleep 1

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        conky -q -d -c ~/.config/conky/conky.conf >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Conky Manager
#
#   URL:        https://github.com/zcot/conky-manager2
#   DESC:       Conky Manager is a graphical front-end for managing 
#               Conky config files. It provides options to start/stop,
#               browse and edit Conky themes installed on the system.
#               Packages are currently available in Launchpad for 
#               Ubuntu and derivatives (Linux Mint, etc).
##--------------------------------------------------------------------------

fn_app_conky_mngr()
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

fn_app_curl()
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
#   Debian Goodies
#
#   DESC:       includes tools such as downloading an apt .deb file
#               dman, debman, debmany, and debget
#
#               this package is different from the package deb-get
#
#               debman -p debian-goodies debman
#                   read man page from package debman
#               debman -p debian-goodies=0.79 debman
#                   read man page for specific verison
#               debman -f debian-goodies_0.79_all.deb dman
#                   read local deb files
##--------------------------------------------------------------------------

fn_app_debian_goodies()
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
#   Deb Get
#
#   URL:        https://github.com/wimpysworld/deb-get
#   DESC:       apt-get functionality for .debs published in 
#               3rd party repositories or via direct download
#
#               deb-get search <package-name>
#                   search for app / download .deb
#               deb-get purge <package-name>
#                   delete package
#               deb-get install <package-name>
#                   install package
#               deb-get reinstall packagename
#                   reinstall package
#               deb-get update
#               deb-get upgrade
##--------------------------------------------------------------------------

fn_app_debget()
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

fn_app_flatpak()
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
#   URL:        https://pkgs.org/download/gdebi
#   DESC:       A tiny little app that helps you install deb files more 
#               effectively by handling dependencies. Learn how to 
#               use Gdebi and make it the default application for 
#               installing deb packages.
##--------------------------------------------------------------------------

fn_app_gdebi()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
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

fn_app_git()
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

fn_app_github_desktop()
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

fn_app_gnome_ext_core()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v flatpak)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${ORANGE}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_flatpak "${app_flatpak}"

        begin "Retry: ${1}"

        sleep 1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo flatpak repair --system >> $LOGS_FILE 2>&1
        flatpak install flathub com.mattjakeman.ExtensionManager -y --noninteractive >> $LOGS_FILE 2>&1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install gnome-shell-extension-manager -y -qq >> $LOGS_FILE 2>&1
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

fn_app_gnome_ext_arcmenu()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v gnome-shell-extension-installer)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${ORANGE}Error:${NORMAL}${GREYL} Missing ${app_gnome_ext_core}. Installing ...${NORMAL}" >&2
        sleep 1

        fn_app_gnome_ext_core "${app_gnome_ext_core}"

        begin "Retry: ${1}"

        sleep 1
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        gnome-shell-extension-installer $app_ext_id_arcmenu --yes >> $LOGS_FILE 2>&1
    fi
    
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

fn_app_gnome_ext_ism()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v gnome-shell-extension-installer)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${ORANGE}Error:${NORMAL}${GREYL} Missing ${app_gnome_ext_core}. Installing ...${NORMAL}" >&2
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

fn_app_gnome_tweaks()
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

fn_app_gpick()
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

fn_app_kooha()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v flatpak)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${ORANGE}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing ...${NORMAL}" >&2
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

fn_app_lintian()
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

fn_app_makedeb()
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

fn_app_members()
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

fn_app_mlocate()
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
#   MySQL
##--------------------------------------------------------------------------

fn_app_mysql()
{

    local dbPasswdUpdated=2
    if [ -z "${i_pwd_try}" ]; then
        i_pwd_try=0
    fi

    #   --------------------------------------------------------------
    #   report back errors
    #   --------------------------------------------------------------

    if [ -n "${3}" ]; then
        clear
        echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
        echo -e "  ${ORANGE}Error${WHITE}"
        echo -e "  "
        echo -e "  ${WHITE}${3}${NORMAL}"
        echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
        echo
    fi

    #   --------------------------------------------------------------
    #   check mysql for existing password
    #   --------------------------------------------------------------

    mysql -u root -e "USE mysql;" 2>/dev/null
    local bFirstDB_OK=$?

    #   --------------------------------------------------------------
    #   existing database password detected
    #   --------------------------------------------------------------

    if [ "$bFirstDB_OK" -eq 1 ]; then
        echo
        echo -e "  ${BOLD}${FUCHSIA}MySQL  ${WHITE}has detected an existing password on your database.${NORMAL}"
        echo -e "  ${BOLD}${FUCHSIA}       ${WHITE}Please provide it below.${NORMAL}"
        echo
        printf "  Enter Password: ${LGRAY}█${NORMAL}"
        IFS= read -rs pwd_mysql_root < /dev/tty

        export pwd_mysql_root

        clear

        #   --------------------------------------------------------------
        #   check database existing password
        #   --------------------------------------------------------------

        if [ -n "$pwd_mysql_root" ]; then
            mysql -u root -p$pwd_mysql_root -e "USE mysql;" 2>/dev/null
            res=$?

            #   --------------------------------------------------------------
            #   existing mysql password doesnt match
            #   --------------------------------------------------------------
        
            if [ $res -ne 0 ]; then
    
                (( i_pwd_try++ ))

                #   --------------------------------------------------------------
                #   excessive password retries activated
                #   --------------------------------------------------------------

                if [ "$i_pwd_try" -ge "3" ]; then

                    echo
                    echo
                    echo -e "  ${BOLD}${ORANGE}Excessive Password Failures${NORMAL}"
                    echo -e "  ${BOLD}${WHITE}You have attempted ${YELLOW}$i_pwd_try${WHITE} failed password attempts.${NORMAL}"
                    echo -e "  ${BOLD}${WHITE}Would you like to perform an emergency password reset on root?${NORMAL}"
                    echo
                    echo

                    #   --------------------------------------------------------------
                    #   user choice to passwd reset
                    #   --------------------------------------------------------------

                    if cli_question "  Perform Reset? "; then
                            echo "password reset"
                        return

                    #   --------------------------------------------------------------
                    #   user choice to deny passwd reset
                    #   --------------------------------------------------------------

                    else
                        fn_app_mysql "${1}" ${FUNCNAME[0]} "You denied password reset. Try your password again."
                    fi

                #   --------------------------------------------------------------
                #   still has more retries left
                #   --------------------------------------------------------------

                else
                    fn_app_mysql "${1}" ${FUNCNAME[0]} "Incorrect password provided, try again."
                fi

            #   --------------------------------------------------------------
            #   existing mysql password match
            #   --------------------------------------------------------------

            else

                local pwd_mysql_old=$pwd_mysql_root

                echo
                echo
                echo -e "  ${BOLD}${GREEN}Connection Success${NORMAL}"
                echo -e "  ${BOLD}${WHITE}A connection has been established with your MySQL${NORMAL}"
                echo -e "  ${BOLD}${WHITE}database. Continuing ...${NORMAL}"
                echo
                echo

                if cli_question "  Would you like to change the password?"; then

                    echo
                    printf "  Enter Password: ${LGRAY}█${NORMAL}"
                    IFS= read -rs pwd_mysql_root < /dev/tty
                    clear

                    if [[ ${#pwd_mysql_root} -lt 2 ]]; then
                        fn_app_mysql "${1}" ${FUNCNAME[0]} "Password must be longer than 1 character."
                    fi

                    export pwd_mysql_root

                    echo
                    printf '%-57s %-5s' "    |--- Updating Root Password" ""
                    if [ -z "${OPT_DEV_NULLRUN}" ]; then
                        sudo mysql -u root -p$pwd_mysql_old -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$pwd_mysql_root'; FLUSH PRIVILEGES;" 2>/dev/null
                        dbPasswdUpdated=$?
                    fi
                    echo -e "[ ${STATUS_OK} ]"

                    #   assign mysql password to new var
                    #   edit existing variable to append -p to the front of the password
                    #   if a password exists
                    #   mysql requires -p <pass> in order to connect.

                    if [ -n "$pwd_mysql_root" ]; then
                        mysql -u root -p$pwd_mysql_root -e "USE mysql;" 2>/dev/null
                        res=$?
                    else
                        mysql -u root -e "USE mysql;" 2>/dev/null
                        res=$?
                    fi

                    if [ $res -ne 0 ]; then
                        fn_app_mysql "${1}" ${FUNCNAME[0]} "Error occured changing your mysql password, try again."
                    fi

                    #   create passwd file in /bin/
                    if [ -n "${pwd_mysql_root}" ]; then
                        mkdir -p "$app_dir_bin_pwd"
                        touch "$app_file_bin_pwd"

                        echo "$pwd_mysql_root" | tee "$app_file_bin_pwd" >/dev/null

                        sudo chown ${USER}:${USER} ${app_file_bin_pwd} >> $LOGS_FILE 2>&1
                        sudo chmod 600 ${app_file_bin_pwd} >> $LOGS_FILE 2>&1
                    fi

                    finish
                    clear

                    echo
                    echo
                    echo -e "  ${BOLD}${WHITE}MySQL root password was successfully changed.${NORMAL}"
                    echo -e "  ${BOLD}${WHITE}Ensure you write your MySQL root password down${NORMAL}"
                    echo -e "  ${BOLD}${WHITE}and keep it safe.${NORMAL}"
                    echo
                    echo -e "  ${BOLD}${WHITE}DELETE the file below once you have your password stored.${NORMAL}"
                    echo
                    echo -e "  ${BOLD}${FUCHSIA}ROOT PASSWORD     ${YELLOW}${pwd_mysql_root}${NORMAL}"
                    echo -e "  ${BOLD}${FUCHSIA}ROOT PWD FILE     ${YELLOW}${app_file_bin_pwd}${NORMAL}"
                    echo
                    echo -e "  ${BOLD}${BLINK}${GREYL}WRITE IT DOWN!!${NORMAL}"
                    echo
                    echo

                    return
                else
                    show_header_comment "MySQL existing password was not changed."
                    return
                    echo "run"
                fi

            fi

        #   --------------------------------------------------------------
        #   user pressed enter or left password blank
        #   --------------------------------------------------------------
    
        else
            fn_app_mysql "${1}" ${FUNCNAME[0]} "Must supply your existing MySQL password to continue"
        fi

    fi

    begin "${1}"

    echo

    #   --------------------------------------------------------------
    #   install password generation package > pwgen
    #   --------------------------------------------------------------

    if ! [ -x "$(command -v pwgen)" ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf '%-57s %-5s' "    |--- Installing Pwgen" ""
        sleep 1
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install pwgen -y -qq >> /dev/null 2>&1
        fi
        echo -e "[ ${STATUS_OK} ]"
        sleep 1
    fi

    #   --------------------------------------------------------------
    #   install mysql
    #   --------------------------------------------------------------

    printf '%-57s %-5s' "    |--- Installing MySQL-Server" ""
    sleep 1
    if ! [ -x "$(command -v mysql)" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install mysql-server -y -qq >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"
    sleep 1

    #   --------------------------------------------------------------
    #   generate passwords with pwgen installed earlier
    #
    #   pwgen docs:     https://manpages.ubuntu.com/manpages/trusty/man1/pwgen.1.html
    #   --------------------------------------------------------------

    if [ -x "$(command -v pwgen)" ] && [ -z "${pwd_mysql_root}" ]; then
        printf '%-57s %-5s' "    |--- Generating Root Password" ""
        sleep 1
        pwd_mysql_root=$( pwgen 20 1 );
        echo -e "[ ${STATUS_OK} ]"
        sleep 1
    fi

    #   --------------------------------------------------------------
    #   user
    #   --------------------------------------------------------------

    if [[ "${bGenerateMysqlPwd_User}" == "true" ]]; then
        pwd_mysql_user=$( pwgen 20 1 );
    fi

    #   --------------------------------------------------------------
    #   ensure mysql is installed and prompt the user for which type
    #   of setup they wish to run.
    #   --------------------------------------------------------------

    mysql --version >> $LOGS_FILE 2>&1
    if [[ $? != 127 ]]; then

        spinner_halt
        clear
        sleep 1

        echo
        echo
        echo -e "  ${BOLD}${FUCHSIA}ATTENTION  ${WHITE}Would you like to run the standard mysql_secure_installation${NORMAL}"
        echo -e "  ${BOLD}${FUCHSIA}           ${WHITE}or use ${app_title_short} for configuring MySQL?${NORMAL}"
        echo
        echo -e "  ${BOLD}${FUCHSIA}           ${WHITE}${app_title_short} method chooses the best security options.${NORMAL}"
        echo
        echo
            export CHOICES=( "Use ${app_title_short} Setup" "Use MySQL mysql_secure_installation" )
            cli_options
            case $? in
                0 )
                    bChoiceProteus=true
                ;;
                1 )
                    bChoiceSqlSecure=true
                ;;
            esac
    fi

    #   --------------------------------------------------------------
    #   Choice:     MySQL Secure Option (mysql_secure_installation)
    #   --------------------------------------------------------------

    if [ -n "${bChoiceSqlSecure}" ]; then
        echo
        sleep 1
        printf '%-57s %-5s' "    |--- Starting mysql_secure_installation" ""
        sleep 1
        echo -e "[ ${STATUS_OK} ]"

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sleep 0.5
            app_queue_trapcmd='sudo mysql_secure_installation'
        fi
    fi

    #   --------------------------------------------------------------
    #   Choice:     Proteus
    #   --------------------------------------------------------------

    if [ -n "${bChoiceProteus}" ]; then
        echo
        sleep 1
        printf '%-57s %-5s' "    |--- Starting MySQL ${app_title_short} Setup" ""
        sleep 1
        echo -e "[ ${STATUS_OK} ]"

        #   --------------------------------------------------------------
        #   mysql password generated
        #   --------------------------------------------------------------

        if [ -n "${pwd_mysql_root}" ]; then
            sleep 1
            printf '%-57s %-5s' "    |--- Adding Root Password" ""
            sleep 1
            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$pwd_mysql_root'; FLUSH PRIVILEGES;" 2>/dev/null
                dbPasswdUpdated=$?
            fi
            echo -e "[ ${STATUS_OK} ]"

        #   --------------------------------------------------------------
        #   mysql password not generated
        #   --------------------------------------------------------------

        else
            spinner_halt
            sleep 1
            echo
            echo -e "  ${BOLD}${FUCHSIA}MySQL  ${WHITE}could not find a password to use for your database${NORMAL}"
        fi

        sleep 1

        #   assign mysql password to new var
        #   edit existing variable to append -p to the front of the password
        #   if a password exists
        #   mysql requires -p <pass> in order to connect.

        if [ -n "$pwd_mysql_root" ]; then
            mysql -u root -p$pwd_mysql_root -e "USE mysql;" 2>/dev/null
            res=$?
        else
            mysql -u root -e "USE mysql;" 2>/dev/null
            res=$?
        fi

        if [ $res -ne 0 ]; then
            echo
            echo
            echo -e "  ${BOLD}${ORANGE}Error Occured${NORMAL}"
            echo -e "  ${BOLD}${WHITE}Could not connect to database with password supplied.${NORMAL}"
            echo -e "  ${BOLD}${WHITE}This appears be an internal issue.${NORMAL}"
            echo
            echo
        fi

        #   create passwd file in /bin/
        if [ -n "${pwd_mysql_root}" ]; then
            mkdir -p "$app_dir_bin_pwd"
            touch "$app_file_bin_pwd"

            echo "$pwd_mysql_root" | tee "$app_file_bin_pwd" >/dev/null

            sudo chown ${USER}:${USER} ${app_file_bin_pwd} >> $LOGS_FILE 2>&1
            sudo chmod 600 ${app_file_bin_pwd} >> $LOGS_FILE 2>&1
        fi

        mysql --version >> $LOGS_FILE 2>&1
        if [[ $? != 127 ]] || [ -x "$(command -v mysql)" ]; then

            spinner_halt
            clear
            sleep 1

            echo
            echo
            echo -e "  ${BOLD}${WHITE}MySQL has been successfully installed on your system. A root password${NORMAL}"
            echo -e "  ${BOLD}${WHITE}was also configured. Ensure you write your MySQL root password down${NORMAL}"
            echo -e "  ${BOLD}${WHITE}and keep it safe.${NORMAL}"
            echo
            echo -e "  ${BOLD}${WHITE}DELETE the file below once you have your password stored.${NORMAL}"
            echo
            echo -e "  ${BOLD}${FUCHSIA}ROOT PASSWORD     ${YELLOW}${pwd_mysql_root}${NORMAL}"
            echo -e "  ${BOLD}${FUCHSIA}ROOT PWD FILE     ${YELLOW}${app_file_bin_pwd}${NORMAL}"
            echo
            echo -e "  ${BOLD}${BLINK}${GREYL}WRITE IT DOWN!!${NORMAL}"
            echo
            echo

        else

            spinner_halt
            clear
            sleep 1

            echo
            echo
            echo -e "  ${BOLD}${ORANGE}Error Occured${NORMAL}"
            echo -e "  ${BOLD}${WHITE}${app_title_short} cannot locate MySQL on your system. An unexpected error may have occured${NORMAL}"
            echo -e "  ${BOLD}${WHITE}and requires manual attention from the administrator.${NORMAL}"
            echo
            echo

        fi

    fi

    sleep 1
    finish
}

##--------------------------------------------------------------------------
#   neofetch
##--------------------------------------------------------------------------

fn_app_neofetch()
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
#   NodeJS
#
#   DESC:       Allows users to install a newer version of NodeJS.
#
#               Currently, the options are v16, v18, and v20
##--------------------------------------------------------------------------

fn_app_nodejs()
{
    begin "${1}"
    sleep 0.5

    ##--------------------------------------------------------------------------
    #   skip dialog box if user provided nodejs version via CLI
    ##--------------------------------------------------------------------------

    if [ -z "$ARG_NJS_VER" ]; then
        objlist=$( GDK_BACKEND=x11 yad \
        --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
        --title="Select NodeJS Version" \
        --width=340 \
        --form \
        --borders=15 \
        --text "Select your desired version of NodeJS\n" \
        --button="!gtk-yes!yes:0" \
        --button="!gtk-close!exit:1" \
        --field="Version     :CB" $(IFS=! ; echo "${app_nodejs_ver[*]}" ) )
        RET=$?
        njs_sel_ver="${objlist//|}"
    fi

    #   check to see if either the CLI option is set, or the dialog box selection menu
    local njs_ver2install=$( [ "$njs_sel_ver" ] && echo "$njs_sel_ver" || [ "$ARG_NJS_VER" ] && echo "$ARG_NJS_VER" )

    sleep 0.5

    if [ -n "$njs_ver2install" ]; then
        export NODE_MAJOR=${njs_ver2install}

        echo

        printf '%-57s %-5s' "    |--- Downloading GPG Key" ""
        sleep 1
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo mkdir -p /etc/apt/keyrings

            #   -f, --fail              (HTTP) Fail fast with no output at all on server errors.
            #   -s, --silent            Silent or quiet mode. Do not show progress meter or error messages.
            #   -S, --show-error        When used with -s, --silent, it makes curl show an error message if it fails.
            #   -L, --location          (HTTP) If server reports requested page has moved to different location.
            #                           option makes curl redo the request on the new place.

            curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg >> $LOGS_FILE 2>&1
        fi
        echo -e "[ ${STATUS_OK} ]"

        printf '%-57s %-5s' "    |--- Adding Repo Source" ""
        sleep 1
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list >> $LOGS_FILE 2>&1
        fi
        echo -e "[ ${STATUS_OK} ]"

        printf '%-57s %-5s' "    |--- Installing ${1} v${NODE_MAJOR}.0" ""
        sleep 1
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> $LOGS_FILE 2>&1
            sudo apt-get install nodejs -y -qq >> $LOGS_FILE 2>&1
        fi
        echo -e "[ ${STATUS_OK} ]"

    else
        echo -e "[ ${STATUS_FAIL} ]"
    fi

    sleep 1

    finish
}

##--------------------------------------------------------------------------
#   nginx
##--------------------------------------------------------------------------

fn_app_nginx()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install nginx -y -qq >> $LOGS_FILE 2>&1
        sleep 1
        sudo systemctl start nginx >> $LOGS_FILE 2>&1
        sudo systemctl enable nginx >> $LOGS_FILE 2>&1
        sleep 1
        open_url "http://127.0.0.1"
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   net-tools
##--------------------------------------------------------------------------

fn_app_nettools()
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

fn_app_npm()
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

fn_app_ocsurl()
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

fn_app_pacman_game()
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

fn_app_pacman_manager()
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

fn_app_reprepro()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install reprepro -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   RPM Package Manager
##--------------------------------------------------------------------------

fn_app_rpm()
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

fn_app_seahorse()
{
    begin "${1}"

    echo

    printf '%-57s %-5s' "    |--- Remove Base" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo dpkg -r --force seahorse >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-57s %-5s' "    |--- Apt Update" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-57s %-5s' "    |--- Install seahorse" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get install seahorse seahorse-nautilus -y -qq >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Cache Sudo Password
##--------------------------------------------------------------------------

fn_app_snapd()
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

fn_app_surfshark()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        local surfshark_url=https://downloads.surfshark.com/linux/debian-install.sh
        local surfshark_file=surfshark-install

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

fn_app_swizzin()
{
    begin "${1}"

    echo

    local swizzin_url=s5n.sh
    local swizzin_file=swizzin.sh

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

fn_app_sysload()
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

fn_app_teamviewer()
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
#   Terminology
#
#   DESC:       A terminal on steroids
#               allows for backgrounds, font changes, themes, etc.
##--------------------------------------------------------------------------

fn_app_terminology()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install terminology -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   tree
##--------------------------------------------------------------------------

fn_app_tree()
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
#   Php
#
#   Developer has choosen to only support LTS versions of Ubuntu.
#   This means Ubuntu Focal and Jammy.
#
#   Ubuntu Lunar can get PHP installed, but it requires some edits
#   to the source list file.
##--------------------------------------------------------------------------

fn_app_php()
{
    begin "${1}"

    ##--------------------------------------------------------------------------
    #   skip dialog box if user provided PHP version via CLI
    ##--------------------------------------------------------------------------

    if [ -z "$ARG_PHP_VER" ]; then
        objlist=$( GDK_BACKEND=x11 yad \
        --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
        --title="Select PHP Version" \
        --width=340 \
        --form \
        --borders=15 \
        --text "Select your desired version of PHP\n" \
        --button="!gtk-yes!yes:0" \
        --button="!gtk-close!exit:1" \
        --fixed \
        --field="Version     :CB" $(IFS=! ; echo "${app_php_ver[*]}" ) )
        RET=$?
        php_sel_ver="${objlist//|}"
    fi

    #   check to see if either the CLI option is set, or the dialog box selection menu
    local php_ver2install=$( [ "$php_sel_ver" ] && echo "$php_sel_ver" || [ "$ARG_PHP_VER" ] && echo "$ARG_PHP_VER" )

    sleep 0.5

    if [ -n "$php_ver2install" ]; then
        echo

        printf '%-57s %-5s' "    |--- Adding ppa:ondrej/php" ""
        sleep 1
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo add-apt-repository --yes ppa:ondrej/php >> $LOGS_FILE 2>&1
            sudo apt-get update -y -q >> $LOGS_FILE 2>&1
            sudo apt-get install lsb-release ca-certificates apt-transport-https software-properties-common -y -qq >> $LOGS_FILE 2>&1
        fi
        echo -e "[ ${STATUS_OK} ]"

        printf '%-57s %-5s' "    |--- Installing ${php_ver2install}" ""
        sleep 1
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            #   remove -fpm from the end if exists
            local php_filter="-fpm"
            local php_lib=${php_ver2install/%$php_filter}

            #   full list
            #   php8.2-{amqp,apcu,ast,bcmath,bz2,cgi,cli,common,curl,dba,decimal,dev,ds,enchant,excimer,fpm,gd,gearman,gmagick,gmp,gnupg,grpc,http,igbinary,imagick,imap,inotify,interbase,intl,ldap,libvirt-php,lz4,mailparse,maxminddb,mbstring,mcrypt,memcache,memcached,mongodb,msgpack,mysql,oauth,odbc,pcov,pgsql,phpdbg,pinba,propro,protobuf,ps,pspell,psr,raphf,rdkafka,readline,redis,rrd,smbclient,snmp,soap,solr,sqlite3,ssh2,stomp,swoole,sybase,tideways,tidy,uopz,uploadprogress,uuid,vips,xdebug,xhprof,xml,xmlrpc,xsl,yac,yaml,zip,zmq,zstd}

            sudo apt-get update -y -q >> $LOGS_FILE 2>&1
            sudo apt-get install ${php_ver2install} -y -qq >> $LOGS_FILE 2>&1
            sudo apt-get install ${php_lib} ${php_lib}-{bcmath,bz2,cgi,cli,curl,common,gd,gmagick,gnupg,imagick,imap,mysql,mbstring,mcrypt,xml,yaml,zip}
        fi
        echo -e "[ ${STATUS_OK} ]"

    else
        echo -e "[ ${STATUS_FAIL} ]"
    fi

    sleep 1

    finish
}

##--------------------------------------------------------------------------
#   PhpMyAdmin
#
#   DESC:       w/o added PPA:      PhpMyAdmin 4.x
#               w/ added PPA:       PhpMyAdmin 5.2
#
#               originally we utilized the PPA to install phpMyAdmin,
#               however, by using the PPA, it limits the user's ability
#               to install plugins like 2FA. So from now on, manually
#               download and set things up.
#
#               the manual download includes U2F / Bacon-QR.
##--------------------------------------------------------------------------

fn_app_phpmyadmin()
{
    begin "${1}"
    echo

    local pma_uri_zip="https://phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip"
    local pma_uri_tar="https://phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz"
    local pma_dir_home="/usr/share/"
    local pma_dir_install="/usr/share/phpmyadmin"
    local pma_dir_themes="${pma_dir_install}/themes"
    local pma_dir_var="/var/lib/phpmyadmin"
    local pma_dir_tmp="${pma_dir_var}/tmp"
    local pma_dir_cfg="/etc/phpmyadmin"
    local pma_fil_zip="${pma_uri_zip##*/}"

    if ! [ -x "$(command -v mysql)" ]; then
        echo
        echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}MySQL not installed..${NORMAL}"
        echo -e "  ${BOLD}${WHITE}Please run the MySQL installer first before installing phpMyAdmin.${NORMAL}"
        echo

        finish
        show_header_comment "MySQL not installed on your system. Install MySQL before you run\n  the phpMyAdmin installation."
        return
    fi

    #   --------------------------------------------------------------
    #   password generation package
    #   --------------------------------------------------------------

    if ! [ -x "$(command -v pwgen)" ]; then
        printf '%-57s %-5s' "    |--- Installing Pwgen" ""
        sleep 1
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install pwgen -y -qq >> /dev/null 2>&1
        fi
        echo -e "[ ${STATUS_OK} ]"
    fi

    #   --------------------------------------------------------------
    #   require unzip to extract the themes
    #   wish they came in .tar but ya know, "consistency"
    #   might as well extract phpmyadmin with zip as well
    #   --------------------------------------------------------------

    if ! [ -x "$(command -v unzip)" ]; then
        printf '%-57s %-5s' "    |--- Installing Unzip" ""
        sleep 1
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install unzip -y -qq >> /dev/null 2>&1
        fi
        echo -e "[ ${STATUS_OK} ]"
    fi

    #   --------------------------------------------------------------
    #   phpMyAdmin already installed
    #   --------------------------------------------------------------

    if [[ -d ${pma_dir_install} ]] && [ ! -z "$(ls -A ${pma_dir_install})" ]; then
        echo
        echo
        echo -e "  ${BOLD}${FUCHSIA}ATTENTION  ${WHITE}phpMyAdmin already installed: ${pma_dir_install}${NORMAL}"
        echo
        echo
            export CHOICES=( "Uninstall phpMyAdmin" "Abort" )
            cli_options
            case $? in
                0 )
                    echo 
                    sleep 1
                    printf '%-57s %-5s' "    |--- Checking apt" ""
                    sleep 1
                    if [ -z "${OPT_DEV_NULLRUN}" ]; then
                        sudo apt-get -f install -y -q >> $LOGS_FILE 2>&1
                        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
                        sudo apt-get purge phpmyadmin -y -q >> $LOGS_FILE 2>&1
                    fi
                    echo -e "[ ${STATUS_OK} ]"

                    printf '%-57s %-5s' "    |--- Remove ${pma_dir_install}" ""
                    sleep 1
                    if [ -z "${OPT_DEV_NULLRUN}" ]; then
                        sudo rm -r ${pma_dir_install}
                    fi
                    echo -e "[ ${STATUS_OK} ]"

                    apacheCheck=$( dpkg --get-selections | grep apache && dpkg --get-selections | grep apache2 )
                    if [ -n "$apacheCheck" ]; then
                        printf '%-57s %-5s' "    |--- Restarting apache" ""
                        sleep 1
                        if [ -z "${OPT_DEV_NULLRUN}" ]; then
                            sudo a2disconf phpmyadmin >> $LOGS_FILE 2>&1
                            sudo systemctl restart apache
                            sudo systemctl restart apache2
                        fi
                        echo -e "[ ${STATUS_OK} ]"
                    fi

                    nginxCheck=$( dpkg --get-selections | grep nginx )
                    if [ -n "$nginxCheck" ]; then
                        printf '%-57s %-5s' "    |--- Restarting nginx" ""
                        sleep 1
                        if [ -z "${OPT_DEV_NULLRUN}" ]; then
                            sudo systemctl restart nginx
                        fi
                        echo -e "[ ${STATUS_OK} ]"
                    fi

                    finish
                    show_header_comment "Uninstalled phpMyAdmin. Re-launch phpMyAdmin installer to reinstall."
                    return
                ;;
                1 )
                    finish
                    show_header_comment "Aborted phpMyAdmin Install"
                    return
                    sleep 0.2
                ;;
            esac
    fi

    #   --------------------------------------------------------------
    #   check mysql database connection
    #   --------------------------------------------------------------

    mysql -u root -e "USE mysql;" 2>/dev/null
    local bFirstDB_OK=$?

    #   database checked for no password and failed
    #   database has password which is needed by user

    if [ "$bFirstDB_OK" -ne 0 ]; then
        echo
        echo -e "  ${BOLD}${FUCHSIA}phpMyAdmin  ${WHITE}needs you to provide your MySQL database password.${NORMAL}"
        echo -e "  ${BOLD}${FUCHSIA}            ${WHITE}Please enter it below.${NORMAL}"
        echo
        printf "  Enter Password: ${LGRAY}█${NORMAL}"
        IFS= read -rs pwd_mysql_root < /dev/tty

        export pwd_mysql_root

        clear
    fi

    if [ -n "$pwd_mysql_root" ]; then
        mysql -u root -p$pwd_mysql_root -e "USE mysql;" 2>/dev/null
    fi

    #   --------------------------------------------------------------
    #   generate passwords with pwgen installed earlier
    #   --------------------------------------------------------------

    local pwd_pma_ctrlpass=$( pwgen -c -y 20 1 );
    local pwd_pma_blowfish_secret=$( pwgen -c -y 20 1 );
    if [[ "${bGenerateMysqlPwd_User}" == "true" ]]; then
        pwd_mysql_user=$( pwgen -c -y 20 1 );
    fi

    #   --------------------------------------------------------------
    #   download pma zip file
    #   --------------------------------------------------------------

    printf '%-57s %-5s' "    |--- Downloading ${pma_fil_zip}" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo rm -rf ${app_dir_dl}/phpmyadmin*
        sudo wget -P "${app_dir_dl}" -q "${pma_uri_zip}" >> $LOGS_FILE 2>&1
        sudo chown -R ${USER}:${USER} ${app_dir_dl} >> $LOGS_FILE 2>&1
        sudo chmod -R 0741 ${app_dir_dl} >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    #   --------------------------------------------------------------
    #   create pma folder structure
    #   
    #       pma_uri_zip         https://phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip
    #       pma_uri_tar         https://phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
    #       pma_dir_install     /usr/share/phpmyadmin
    #       pma_dir_themes      /usr/share/phpmyadmin/themes
    #       pma_dir_var         /var/lib/phpmyadmin
    #       pma_dir_tmp         /var/lib/phpmyadmin/tmp
    #       pma_dir_cfg         /etc/phpmyadmin
    #       pma_fil_zip         phpMyAdmin-latest-all-languages.zip
    #   --------------------------------------------------------------

    printf '%-57s %-5s' "    |--- Creating pma structure" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo mkdir -p "${pma_dir_install}" >> $LOGS_FILE 2>&1
        sudo mkdir -p "${pma_dir_tmp}" >> $LOGS_FILE 2>&1
        sudo mkdir -p "${pma_dir_cfg}" >> $LOGS_FILE 2>&1
        sudo chown -R www-data:www-data ${pma_dir_var}
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-57s %-5s' "    |--- Extracting pma" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then

        #   --------------------------------------------------------------
        #   error: /home/${USER}/bin/phpMyAdmin*.zip missing
        #   --------------------------------------------------------------

        local bZipExists=false
        for file in ${app_dir_dl}/phpMyAdmin*.zip
        do
            if [ -e "$file" ]; then
                bZipExists=true
            fi
        done

        if [ "$bZipExists" = false ]; then
            show_header_comment "Could not locate ${pma_fil_zip} -- aborting"
            return
        fi

        #   --------------------------------------------------------------
        #   unzip phpMyAdmin*.zip
        #   send to "$HOME/bin/downloads"
        #   change owner to root && user to sudoer
        #   --------------------------------------------------------------

        sudo unzip -o -u -qq ${app_dir_dl}/phpMyAdmin*.zip -d "${app_dir_dl}"
        sudo chown -R ${USER}:${USER} ${app_dir_dl} >> $LOGS_FILE 2>&1
        sudo chmod -R 0741 ${app_dir_dl} >> $LOGS_FILE 2>&1

        #   --------------------------------------------------------------
        #   error: /usr/share/phpmyadmin missing after trying to create earlier
        #   --------------------------------------------------------------

        if [ ! -d ${pma_dir_install} ]; then
            echo -e "[ ${STATUS_FAIL} ]"
        
            show_header_comment "Could not locate ${pma_dir_install} -- aborting"
            return
        fi

        #   --------------------------------------------------------------
        #   yes we could cut the commands up
        #   move extracted phpmyadmin folder to /usr/share/phpmyadmin
        #   --------------------------------------------------------------

        sudo rm ${app_dir_dl}/phpMyAdmin*.zip
        sudo mv ${app_dir_dl}/phpMyAdmin-* ${app_dir_dl}/phpmyadmin
        sudo mv ${app_dir_dl}/phpmyadmin ${pma_dir_home}
    fi
    echo -e "[ ${STATUS_OK} ]"

    #   --------------------------------------------------------------
    #   create config.inc.php
    #
    #       copy        /usr/share/phpmyadmin/config.sample.inc.php =>
    #                   /etc/phpmyadmin/config.inc.php
    #
    #       define      blowfish secret for auth cookies
    #       define      all pma config options
    #       add         $cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';
    #       chmod       www-data:www-data "/var/lib/phpmyadmin"
    #   --------------------------------------------------------------

    printf '%-57s %-5s' "    |--- Creating config.inc.php" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo cp ${pma_dir_install}/config.sample.inc.php  ${pma_dir_cfg}/config.inc.php

        sudo sed -i 's/\$cfg\[\x27blowfish_secret\x27\] = \x27\x27\; \/\* YOU MUST FILL IN THIS FOR COOKIE AUTH! \*\//\$cfg\[\x27blowfish_secret\x27\] = \x27'${pwd_pma_blowfish_secret}'\x27\; \/\* YOU MUST FILL IN THIS FOR COOKIE AUTH! \*\//' ${pma_dir_cfg}/config.inc.php

        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controluser\x27\] \= \x27pma\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controluser\x27\] \= \x27pma\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controlpass\x27\] = \x27pmapass\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27controlpass\x27\] = \x27'${pwd_pma_ctrlpass}'\x27\;/' ${pma_dir_cfg}/config.inc.php

        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pmadb\x27\] \= \x27phpmyadmin\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pmadb\x27\] \= \x27phpmyadmin\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27bookmarktable\x27\] \= \x27pma__bookmark\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27bookmarktable\x27\] \= \x27pma__bookmark\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27relation\x27\] \= \x27pma__relation\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27relation\x27\] \= \x27pma__relation\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_info\x27\] \= \x27pma__table_info\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_info\x27\] \= \x27pma__table_info\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_coords\x27\] \= \x27pma__table_coords\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_coords\x27\] \= \x27pma__table_coords\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pdf_pages\x27\] \= \x27pma__pdf_pages\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27pdf_pages\x27\] \= \x27pma__pdf_pages\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27column_info\x27\] \= \x27pma__column_info\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27column_info\x27\] \= \x27pma__column_info\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27history\x27\] \= \x27pma__history\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27history\x27\] \= \x27pma__history\x27\;/' ${pma_dir_cfg}/config.inc.php

        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_uiprefs\x27\] \= \x27pma__table_uiprefs\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27table_uiprefs\x27\] \= \x27pma__table_uiprefs\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27tracking\x27\] \= \x27pma__tracking\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27tracking\x27\] \= \x27pma__tracking\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27userconfig\x27\] \= \x27pma__userconfig\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27userconfig\x27\] \= \x27pma__userconfig\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27recent\x27\] \= \x27pma__recent\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27recent\x27\] \= \x27pma__recent\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27favorite\x27\] \= \x27pma__favorite\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27favorite\x27\] \= \x27pma__favorite\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27users\x27\] \= \x27pma__users\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27users\x27\] \= \x27pma__users\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27usergroups\x27\] \= \x27pma__usergroups\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27usergroups\x27\] \= \x27pma__usergroups\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27navigationhiding\x27\] \= \x27pma__navigationhiding\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27navigationhiding\x27\] \= \x27pma__navigationhiding\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27savedsearches\x27\] \= \x27pma__savedsearches\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27savedsearches\x27\] \= \x27pma__savedsearches\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27central_columns\x27\] \= \x27pma__central_columns\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27central_columns\x27\] \= \x27pma__central_columns\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27designer_settings\x27\] \= \x27pma__designer_settings\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27designer_settings\x27\] \= \x27pma__designer_settings\x27\;/' ${pma_dir_cfg}/config.inc.php
        sudo sed -i 's/\/\/ \$cfg\[\x27Servers\x27\]\[\$i\]\[\x27export_templates\x27\] \= \x27pma__export_templates\x27\;/\$cfg\[\x27Servers\x27\]\[\$i\]\[\x27export_templates\x27\] \= \x27pma__export_templates\x27\;/' ${pma_dir_cfg}/config.inc.php

        #   ADD TempDir Path
        sudo sed -i '/cfg\[\x27SaveDir\x27\]/a\\$cfg[\x27TempDir\x27] = \x27'${pma_dir_tmp}'\x27\;' ${pma_dir_cfg}/config.inc.php

        #   permissions on var folder
        sudo chown -R www-data:www-data ${pma_dir_var}
    fi
    echo -e "[ ${STATUS_OK} ]"

    #   --------------------------------------------------------------
    #   permissions
    #   --------------------------------------------------------------

    printf '%-57s %-5s' "    |--- Setting 0644 config.inc.php" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chmod 0644 ${pma_dir_cfg}/config.inc.php
    fi
    echo -e "[ ${STATUS_OK} ]"

    finish

    apacheCheck=$( dpkg --get-selections | grep apache && dpkg --get-selections | grep apache2 )
    nginxCheck=$( dpkg --get-selections | grep nginx )

    if [ -z $apacheCheck ] && [ -z $nginxCheck ]; then
        show_header_comment "phpMyAdmin Installed\n\n  ${ORANGE}It appears you are missing Nginx or Apache\n  You must install one of the two in order to access phpMyAdmin.${WHITE}"
    else
        show_header_comment "phpMyAdmin Installed\n\n  ${WHITE}phpMyAdmin can usually be accessed via\n    ${BOLD}${FUCHSIA}http://127.0.0.1/phpmyadmin${WHITE}"
    fi

    return
}

##--------------------------------------------------------------------------
#   Pihole
##--------------------------------------------------------------------------

fn_app_pihole()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get upgrade -q >> $LOGS_FILE 2>&1

        #   -s, --silent            Silent or quiet mode. Do not show progress meter or error messages.
        #   -S, --show-error        When used with -s, --silent, it makes curl show an error message if it fails.
        #   -L, --location          (HTTP) If server reports requested page has moved to different location.
        #                           option makes curl redo the request on the new place.

        curl -sSL https://install.pi-hole.net | sudo PIHOLE_SKIP_OS_CHECK=true bash
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
#   python3 > pip
##--------------------------------------------------------------------------

fn_app_python3_pip()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install python3-pip -y -qq >> $LOGS_FILE 2>&1
        sudo apt-get install python3-venv -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Tweaks > File Paths in File Browser
##--------------------------------------------------------------------------

fn_twk_filepath()
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

fn_twk_netplan()
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

fn_twk_menu_new_textfile()
{
    begin "${1}"

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        path_template_new="/home/${USER}/Templates/Text File.txt"
        if [ ! -f "$path_template_new" ]; then
            touch "$path_template_new"
        fi
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Network host file
##--------------------------------------------------------------------------

fn_twk_network_hosts()
{
    begin "${1}"

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
            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sed -i -e '1i'$item "$app_dir_hosts"
            fi
            echo -e "[ ${STATUS_OK} ]"
        fi
    done

    sleep 1
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

fn_twk_vbox_additions_fix()
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

    app_queue_restart_id="${1}"

    finish
}

##--------------------------------------------------------------------------
#   unrar
##--------------------------------------------------------------------------

fn_app_unrar()
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

fn_app_vsc_stable()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v snap)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${ORANGE}Error:${NORMAL}${GREYL} Missing ${app_snapd}. Installing ...${NORMAL}" >&2
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

fn_app_vsc_insiders()
{
    begin "${1}"
    sleep 1

    if ! [ -x "$(command -v snap)" ]; then
        echo -e "[ ${STATUS_HALT} ]"
        sleep 1
        echo -e "  ${BOLD}${ORANGE}Error:${NORMAL}${GREYL} Missing ${app_snapd}. Installing ...${NORMAL}" >&2
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

fn_app_wxhexeditor()
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

fn_app_yad()
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

fn_app_yarn()
{
    begin "${1}"
    sleep 1

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install wget -y -qq >> $LOGS_FILE 2>&1

        #   -q, --quiet             Turn off wget's output. 
        #   -O, --output-document   Output-document

        sudo wget -qO - https://dl.yarnpkg.com/debian/pubkey.gpg | sudo gpg --dearmor -o /usr/share/keyrings/yarn.gpg
        echo "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list >/dev/null

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install yarn -y -qq >> $LOGS_FILE 2>&1
    fi

    sleep 1
    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Zenity Dialogs
#
#   DESC:       gives a user the ability to generate custom dialog boxes.
#
#   PARAM:      (str)   App Name
#   PARAM:      (str)   function name
#   PARAM:      (bool)  bSilent
##--------------------------------------------------------------------------

fn_app_zenity()
{

    if [ -z "${3}" ]; then
        begin "${1}"
    fi

    if [ -z "${OPT_DEV_NULLRUN}" ]; then
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
#
#   PARAM:      (str)   App Name
#   PARAM:      (str)   function name
##--------------------------------------------------------------------------

fn_app_ziet_cron()
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
#   DESC:       list of layouts provided in ZorinOS Pro served via 
#               proteus-apt-repo
#
#   PARAM:      (str)   App Name
#   PARAM:      (str)   function name
##--------------------------------------------------------------------------

fn_app_zorinospro_lo()
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
    (( app_i++ ))
fi

if [ "$bInstall_app_appimage" = true ]; then
    apps+=("${app_appimage}")
    (( app_i++ ))
fi

if [ "$bInstall_app_app_outlet" = true ]; then
    apps+=("${app_app_outlet}")
    (( app_i++ ))
fi

if [ "$bInstall_app_argon2" = true ]; then
    apps+=("${app_argon2}")
    (( app_i++ ))
fi

if [ "$bInstall_app_blender_flatpak" = true ]; then
    apps+=("${app_blender_flatpak}")
    (( app_i++ ))
fi

if [ "$bInstall_app_blender_snapd" = true ]; then
    apps+=("${app_blender_snapd}")
    (( app_i++ ))
fi

if [ "$bInstall_app_browser_chrome" = true ]; then
    apps+=("${app_browser_chrome}")
    (( app_i++ ))
fi

if [ "$bInstall_app_browser_librewolf" = true ]; then
    apps+=("${app_browser_librewolf}")
    (( app_i++ ))
fi

if [ "$bInstall_app_browser_tor" = true ]; then
    apps+=("${app_browser_tor}")
    (( app_i++ ))
fi

if [ "$bInstall_app_cdialog" = true ]; then
    apps+=("${app_cdialog}")
    (( app_i++ ))
fi

if [ "$bInstall_app_colorpicker_snapd" = true ]; then
    apps+=("${app_colorpicker_snapd}")
    (( app_i++ ))
fi

if [ "$bInstall_app_conky" = true ]; then
    apps+=("${app_conky}")
    (( app_i++ ))
fi

if [ "$bInstall_app_conky_mngr" = true ]; then
    apps+=("${app_conky_mngr}")
    (( app_i++ ))
fi

if [ "$bInstall_app_curl" = true ]; then
    apps+=("${app_curl}")
    (( app_i++ ))
fi

if [ "$bInstall_app_debian_goodies" = true ]; then
    apps+=("${app_debian_goodies}")
    (( app_i++ ))
fi

if [ "$bInstall_app_debget" = true ]; then
    apps+=("${app_debget}")
    (( app_i++ ))
fi

if [ "$bInstall_app_flatpak" = true ]; then
    apps+=("${app_flatpak}")
    (( app_i++ ))
fi

if [ "$bInstall_app_gdebi" = true ]; then
    apps+=("${app_gdebi}")
    (( app_i++ ))
fi

if [ "$bInstall_app_git" = true ]; then
    apps+=("${app_git}")
    (( app_i++ ))
fi

if [ "$bInstall_app_github_desktop" = true ]; then
    apps+=("${app_github_desktop}")
    (( app_i++ ))
fi

if [ "$bInstall_app_gnome_ext_arcmenu" = true ]; then
    apps+=("${app_gnome_ext_arcmenu}")
    (( app_i++ ))
fi

if [ "$bInstall_app_gnome_ext_core" = true ]; then
    apps+=("${app_gnome_ext_core}")
    (( app_i++ ))
fi

if [ "$bInstall_app_gnome_ext_ism" = true ]; then
    apps+=("${app_gnome_ext_ism}")
    (( app_i++ ))
fi

if [ "$bInstall_app_gnome_tweaks" = true ]; then
    apps+=("${app_gnome_tweaks}")
    (( app_i++ ))
fi

if [ "$bInstall_app_gpick" = true ]; then
    apps+=("${app_gpick}")
    (( app_i++ ))
fi

if [ "$bInstall_app_kooha" = true ]; then
    apps+=("${app_kooha}")
    (( app_i++ ))
fi

if [ "$bInstall_app_lintian" = true ]; then
    apps+=("${app_lintian}")
    (( app_i++ ))
fi

if [ "$bInstall_app_makedeb" = true ]; then
    apps+=("${app_makedeb}")
    (( app_i++ ))
fi

if [ "$bInstall_app_members" = true ]; then
    apps+=("${app_members}")
    (( app_i++ ))
fi

if [ "$bInstall_app_mlocate" = true ]; then
    apps+=("${app_mlocate}")
    (( app_i++ ))
fi

if [ "$bInstall_app_mysql" = true ]; then
    apps+=("${app_mysql}")
    (( app_i++ ))
fi

if [ "$bInstall_app_neofetch" = true ]; then
    apps+=("${app_neofetch}")
    (( app_i++ ))
fi

if [ "$bInstall_app_nodejs" = true ]; then
    apps+=("${app_nodejs}")
    (( app_i++ ))
fi

if [ "$bInstall_app_nginx" = true ]; then
    apps+=("${app_nginx}")
    (( app_i++ ))
fi

if [ "$bInstall_app_nettools" = true ]; then
    apps+=("${app_nettools}")
    (( app_i++ ))
fi

if [ "$bInstall_app_npm" = true ]; then
    apps+=("${app_npm}")
    (( app_i++ ))
fi

if [ "$bInstall_app_ocsurl" = true ]; then
    apps+=("${app_ocsurl}")
    (( app_i++ ))
fi

if [ "$bInstall_app_pacman_game" = true ]; then
    apps+=("${app_pacman_game}")
    (( app_i++ ))
fi

if [ "$bInstall_app_pacman_manager" = true ]; then
    apps+=("${app_pacman_manager}")
    (( app_i++ ))
fi

if [ "$bInstall_app_php" = true ]; then
    apps+=("${app_php}")
    (( app_i++ ))
fi

if [ "$bInstall_app_phpmyadmin" = true ]; then
    apps+=("${app_phpmyadmin}")
    (( app_i++ ))
fi

if [ "$bInstall_app_pihole" = true ]; then
    apps+=("${app_pihole}")
    (( app_i++ ))
fi

if [ "$bInstall_app_python3_pip" = true ]; then
    apps+=("${app_python3_pip}")
    (( app_i++ ))
fi

if [ "$bInstall_app_reprepro" = true ]; then
    apps+=("${app_reprepro}")
    (( app_i++ ))
fi

if [ "$bInstall_app_rpm" = true ]; then
    apps+=("${app_rpm}")
    (( app_i++ ))
fi

if [ "$bInstall_app_seahorse" = true ]; then
    apps+=("${app_seahorse}")
    (( app_i++ ))
fi

if [ "$bInstall_app_snapd" = true ]; then
    apps+=("${app_snapd}")
    (( app_i++ ))
fi

if [ "$bInstall_app_surfshark" = true ]; then
    apps+=("${app_surfshark}")
    (( app_i++ ))
fi

if [ "$bInstall_app_swizzin" = true ]; then
    apps+=("${app_swizzin}")
    (( app_i++ ))
fi

if [ "$bInstall_app_sysload" = true ]; then
    apps+=("${app_sysload}")
    (( app_i++ ))
fi

if [ "$bInstall_app_teamviewer" = true ]; then
    apps+=("${app_teamviewer}")
    (( app_i++ ))
fi

if [ "$bInstall_app_terminology" = true ]; then
    apps+=("${app_terminology}")
    (( app_i++ ))
fi

if [ "$bInstall_app_tree" = true ]; then
    apps+=("${app_tree}")
    (( app_i++ ))
fi

if [ "$bInstall_twk_filepath" = true ]; then
    apps+=("${twk_filepath}")
    (( app_i++ ))
fi

if [ "$bInstall_twk_netplan" = true ]; then
    apps+=("${twk_netplan}")
    (( app_i++ ))
fi

if [ "$bInstall_twk_menu_new_textfile" = true ]; then
    apps+=("${twk_menu_new_textfile}")
    (( app_i++ ))
fi

if [ "$bInstall_twk_network_hosts" = true ]; then
    apps+=("${twk_network_hosts}")
    (( app_i++ ))
fi

if [ "$bInstall_twk_vbox_additions_fix" = true ]; then
    apps+=("${twk_vbox_additions_fix}")
    (( app_i++ ))
fi

if [ "$bInstall_app_unrar" = true ]; then
    apps+=("${app_unrar}")
    (( app_i++ ))
fi

if [ "$bInstall_app_vsc_stable" = true ]; then
    apps+=("${app_vsc_stable}")
    (( app_i++ ))
fi

if [ "$bInstall_app_vsc_insiders" = true ]; then
    apps+=("${app_vsc_insiders}")
    (( app_i++ ))
fi

if [ "$bInstall_app_wxhexeditor" = true ]; then
    apps+=("${app_wxhexeditor}")
    (( app_i++ ))
fi

if [ "$bInstall_app_yad" = true ]; then
    apps+=("${app_yad}")
    (( app_i++ ))
fi

if [ "$bInstall_app_yarn" = true ]; then
    apps+=("${app_yarn}")
    (( app_i++ ))
fi

if [ "$bInstall_app_zenity" = true ]; then
    apps+=("${app_zenity}")
    (( app_i++ ))
fi

if [ "$bInstall_app_ziet_cron" = true ]; then
    apps+=("${app_ziet_cron}")
    (( app_i++ ))
fi

if [ "$bInstall_app_zorinospro_lo" = true ]; then
    apps+=("${app_zorinospro_lo}")
    (( app_i++ ))
fi

##--------------------------------------------------------------------------
#   dev functions
##--------------------------------------------------------------------------

fn_dev_a()
{
    begin "${1}"
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"
    finish
}

fn_dev_b()
{
    begin "${1}"
        sudo apt-get upgrade -q >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"
    finish
}

fn_dev_c()
{
    begin "${1}"
        sudo flatpak repair --system >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"
    finish
}

fn_dev_d()
{
    begin "${1}"
        sudo snap refresh >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"
    finish
}

fn_dev_e()
{
    begin "${1}"
	    echo -e "[ ${STATUS_OK} ]"
    finish
}

fn_dev_f()
{
    begin "${1}"
	    echo -e "[ ${STATUS_OK} ]"
    finish
}

##--------------------------------------------------------------------------
#   dev menu
#
#   DESC:       used for testing purposes only
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
#   DESC:       installs all apps.
#               needs to be at end of all other functions
#
##--------------------------------------------------------------------------

fn_app_all()
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

show_header()
{
    clear

    sleep 0.3

    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo -e " ${GREEN}${BOLD} ${app_title} - v$(get_version)${NORMAL}${MAGENTA}"
    echo
    echo -e "  This manager allows you to install a large number of libraries"
    echo -e "  and apps on your device. It also includes an array of patches &"
    echo -e "  mods to change how the OS works. Select from the list below."
    echo
    echo -e "  Some of these programs and libraries may take several minutes to"
    echo -e "  install; do not force kill this wizard."
    echo

    if [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}PID ${NORMAL}" "${BOLD}${FUCHSIA} $$ ${NORMAL}"
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}USER ${NORMAL}" "${BOLD}${FUCHSIA} ${USER} ${NORMAL}"
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}APPS ${NORMAL}" "${BOLD}${FUCHSIA} ${app_i} ${NORMAL}"
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}DEV ${NORMAL}" "${BOLD}${FUCHSIA} $([ -n "${OPT_DEV_ENABLE}" ] && echo "Enabled" || echo "Disabled" ) ${NORMAL}"
        echo
    fi

    if [ -n "$(ls -A "${app_dir_bin_pwd}" 2>/dev/null)" ]; then
        echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
        echo
        echo -e " ${BLINK}${ORANGE}${BOLD} WARNING ${WHITE} ! ${ORANGE} WARNING ${WHITE} ! ${ORANGE} WARNING ${WHITE} ! ${ORANGE} WARNING ${WHITE} ! ${ORANGE} WARNING ${WHITE} ! ${ORANGE} WARNING${NORMAL}"
        echo
        echo -e "  ${YELLOW}${BOLD}${app_dir_bin_pwd}${NORMAL} CONTAINS SENSITIVE FILES!"
        echo -e "  DELETE THE FILES IN THE ABOVE FOLDER TO SILENCE THIS MESSAGE."
        echo
    fi

    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo

    sleep 0.3

    printf "%-57s\n" "${TIME}      Successfully loaded ${app_i} apps" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-57s\n" "${TIME}      Waiting for user input ..." | tee -a "${LOGS_FILE}" >/dev/null

    echo -e "  ${BOLD}${NORMAL}Waiting on selection ..." >&2
    echo
}

##--------------------------------------------------------------------------
#   Selection Menu
#
#   allow users to select the desired option manually.
#   this may not be fully integrated yet.
##--------------------------------------------------------------------------

show_menu()
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

    ##--------------------------------------------------------------------------
    #   screen positioning
    #
    #   on Ubuntu v20.04 and older, simply appending --center, --fixed would
    #   center the yad dialog.
    #
    #   however, on Ubuntu 21.04 and newer, Ubuntu was switched from X11 to
    #   wayland, which broke yad's --center functionality.
    #
    #   manually calculate the screen size and position the interface
    #   center screen.
    ##--------------------------------------------------------------------------

    local ScrW=$( xrandr -q | grep -w Screen | sed 's/.*current //;s/,.*//' | awk '{print $1}' )
    local ScrH=$( xrandr -q | grep -w Screen | sed 's/.*current //;s/,.*//' | awk '{print $3}' )

    ##--------------------------------------------------------------------------
    #   calc > main ui
    ##--------------------------------------------------------------------------

    local main_geo_pos_w=$((($ScrW-$gui_width)/2))
    local main_geo_pos_h=$((($ScrH-$gui_height)/2))

    ##--------------------------------------------------------------------------
    #   calc > dialog > normal
    ##--------------------------------------------------------------------------

    local dialog_siz_w_nr=280
    local dialog_siz_h_nr=125

    local dialog_pos_w_nr=$((($ScrW-$dialog_siz_w_nr-125)/2))
    local dialog_pos_h_nr=$((($ScrH-$dialog_siz_h_nr)/2))

    ##--------------------------------------------------------------------------
    #   calc > dialog > large
    ##--------------------------------------------------------------------------

    local dialog_siz_w_lg=270
    local dialog_siz_h_lg=155

    local dialog_pos_w_lg=$((($ScrW-$dialog_siz_w_lg)/2))
    local dialog_pos_h_lg=$((($ScrH-$dialog_siz_h_lg)/2))

    ##--------------------------------------------------------------------------
    #   main interface
    ##--------------------------------------------------------------------------

    while true; do
        objlist=$( GDK_BACKEND=x11 yad \
        --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
        --width="$gui_width" \
        --height="$gui_height" \
        --fixed \
        --geometry="+$main_geo_pos_w+$main_geo_pos_h" \
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
                    query=$( GDK_BACKEND=x11 yad \
                    --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
                    --fixed \
                    --geometry="+${dialog_pos_w_nr}+${dialog_pos_h_nr}" \
                    --title "No Docs Available" \
                    --borders=10 \
                    --button="!gtk-yes!OK:0" \
                    --text "The app <span color='#3477eb'><b>${res}</b></span> does not have any\nprovided docs or websites to show.\n\nReach out to the developer if you feel this entry\nshould have docs." )
                fi
            else
                query=$( GDK_BACKEND=x11 yad \
                --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
                --fixed \
                --geometry="+${dialog_pos_w_nr}+${dialog_pos_h_nr}" \
                --title "No Selection" \
                --borders=10 \
                --button="!gtk-yes!yes:0" \
                --button="!gtk-close!exit:1" \
                --text "Select an individual app from the list and then click the\n<span color='#3477eb'><b>App Docs</b></span> button to view the documentation.\n\nThe item <span color='#3477eb'><b>${app_all}</b></span> is not a valid option. Do you really\nwant ${app_i} browser windows open?" )
            fi
            continue
        fi

        ##--------------------------------------------------------------------------
        #   button > github
        ##--------------------------------------------------------------------------

        if [ $RET -eq 3 ]; then
            open_url ${app_repo_url}
            printf "%-57s\n" "${TIME}      User Input: OnClick ......... Github (Button)" | tee -a "${LOGS_FILE}" >/dev/null
            continue
        fi

        ##--------------------------------------------------------------------------
        #   button > about
        ##--------------------------------------------------------------------------

        if [ $RET -eq 5 ]; then
            ab=$( GDK_BACKEND=x11 yad --pname="Test Application" --about )
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
            answer=$( GDK_BACKEND=x11 yad \
            --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
            --geometry="+${dialog_pos_w_nr}+${dialog_pos_h_nr}" \
            --title "Install ${res}?" \
            --borders=10 \
            --button="!gtk-yes!Install:0" \
            --button="!gtk-close!Cancel:1" \
            --text "Are you sure you want to install the application           \n\n<span color='#3477eb'><b>${res}</b></span>" )
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
                printf "%-57s\n" "${TIME}      User Input: OnClick ......... ${res} (App)" | tee -a "${LOGS_FILE}" >/dev/null

                assoc_func="${app_functions[$res]}"
                $assoc_func "${res}" "${assoc_func}"

                ##--------------------------------------------------------------------------
                #   queue: restart
                ##--------------------------------------------------------------------------

                if [ -n "$app_queue_restart_id" ]; then
                    prompt_reboot=$( GDK_BACKEND=x11 yad \
                    --window-icon="/usr/share/grub/themes/zorin/icons/zorin.png" \
                    --width=$dialog_siz_w_nr \
                    --height=$dialog_siz_h_nr \
                    --fixed \
                    --geometry="+$dialog_pos_w_nr+$dialog_pos_h_nr" \
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

                if [ -n "$app_queue_trapcmd" ]; then
                    Logs_Finish
                    trap "${app_queue_trapcmd}" 0
                    exit
                    sleep 0.2
                    break
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

##--------------------------------------------------------------------------
#   Command-line Searching > Search user provided arguments
#
#   DESC:       supports executing this script with the options
#               --install or -i <package-name> in order to install
#               packages without the gui.
#   
##--------------------------------------------------------------------------

if (( ${#OPT_APPS_CLI[@]} )); then
    declare -A results=()
    pendinstall=()

    IFS=$'\n' apps_sorted=($(sort <<<"${apps[*]}"))
    unset IFS

    for key in "${!OPT_APPS_CLI[@]}"
    do

        # array of searched terms
        search_term="${OPT_APPS_CLI[$key]}"
        count=0

        # array of all apps
        for i in "${!apps[@]}"
        do
            app="${apps_sorted[$i]}"
            if [[ "${app,,}" == *"${search_term,,}"* ]]; then
                (( count++ ))

                if [ -n "${OPT_DEV_ENABLE}" ]; then
                    echo "App .................... ${app}"
                    echo "Search Term ............ ${search_term}"
                    echo "found";

                    echo
                    echo
                fi

                results+=( ["${search_term}"]="${count}" )
                pendinstall+=("${app}")

                break
            fi
        done
    done

    ##--------------------------------------------------------------------------
    #   Command-line Searching > Too many results
    #
    #   DESC:       obviously we dont want the user using words that will 
    #               cause the script to install anything it can find.
    #
    #               the term "Git" alone would install 3 different packages.
    #               
    #               if each search term returns more than 1 result, notify
    #               the user so that they can re-specify their terms in a
    #               more detailed string.
    #   
    ##--------------------------------------------------------------------------

    if (( ${#results[@]} )); then
        printf '  %-25s %-20s %-20s\n\n' "" "" "" 1>&2
        echo -e "  ${BOLD}${GREEN}Packages Found: ${NORMAL}The following will be installed:"
        echo

        for k in ${!pendinstall[@]}; do
            key="${k}"
            val="${pendinstall[${key}]}"
            echo -e "      ‣ ${BOLD}${LIME_YELLOW}${val}${NORMAL}"
        done

        sleep 0.5
        echo

        if cli_question "  Install the above packages?"; then

            # ensure code has caught up
            echo
            sleep 0.5

            for key in "${!pendinstall[@]}"
            do
                app_name="${pendinstall[${key}]}"
                app_func="${app_functions[$app_name]}"

                $app_func "${app_name}" "${app_func}"
            done
        fi
    fi

    Logs_Finish
    exit 0
    sleep 0.2

else
    if ! [ "$OPT_SETUP" = true ]; then
        show_menu app_functions
    fi
fi