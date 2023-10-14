#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin"
echo 

##--------------------------------------------------------------------------
#   @author :           aetherinox
#   @script :           Proteus Install Wizard
#   @when   :           2023-10-14 08:10:25
#   @url    :           https://github.com/Aetherinox/proteus-app-manager
#
#   requires chmod +x proteus_wizard.sh
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
#   vars > colors for whiptail
##--------------------------------------------------------------------------

export NEWT_COLORS='
root=,black
window=,lightgray
shadow=,
title=color8,
checkbox=,magenta
entry=,color8
label=blue,
actlistbox=,magenta
actsellistbox=,magenta
helpline=,magenta
roottext=,magenta
emptyscale=magenta
disabledentry=magenta,
'

##--------------------------------------------------------------------------
#   vars > status messages
##--------------------------------------------------------------------------

STATUS_SKIP="${BOLD}${GREYL} SKIP ${NORMAL}"
STATUS_OK="${BOLD}${GREEN}  OK  ${NORMAL}"
STATUS_FAIL="${BOLD}${RED} FAIL ${NORMAL}"

##--------------------------------------------------------------------------
#   vars > app
##--------------------------------------------------------------------------

apt_dir_home="$HOME/bin"
app_file_this=$(basename "$0")
app_file_proteus="${apt_dir_home}/proteus"
app_repo_dev="Aetherinox"
app_repo="proteus-app-manager"
app_repo_branch="main"
app_repo_apt="proteus-apt-repo"
app_repo_apt_pkg="aetherinox-${app_repo_apt}-archive"
app_title="Proteus Wizard"
app_repo_url="https://github.com/${app_repo_dev}/${app_repo}"
app_mnfst="https://raw.githubusercontent.com/${app_repo_dev}/${app_repo}/${app_repo_branch}/manifest/proteus-app/manifest.json"
app_script="https://raw.githubusercontent.com/${app_repo_dev}/${app_repo}/BRANCH/setup.sh"
app_ver=("1" "0" "0" "7")
app_dir=$PWD
app_pid_spin=0
app_pid=$BASHPID

##--------------------------------------------------------------------------
#   vars > general
##--------------------------------------------------------------------------

gui_about="Install & update wizard for Proteus App manager."

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
#   func > version > compare greater than
#
#   this function compares two versions and determines if an update may
#   be available. or the user is running a lesser version of a program.
##--------------------------------------------------------------------------

function get_version_compare_gt()
{
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
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
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREYL}options${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${0} [${GREYL}-h${NORMAL}] [${GREYL}-d${NORMAL}] [${GREYL}-n${NORMAL}] [${GREYL}-s${NORMAL}] [${GREYL}-t THEME${NORMAL}] [${GREYL}-v${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n' "Options:" "" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-d, --dev" "dev mode" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-h, --help" "show help menu" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-n, --nullrun" "dev: null run" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "simulate app installs (no changes)" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-u, --update" "update ${app_file_proteus} executable" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "    --branch" "branch to update from" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-v, --version" "current version of app manager" 1>&2
    echo
    echo
    exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
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

    -n|--nullrun)
            OPT_DEV_NULLRUN=true
            echo -e "  ${FUCHSIA}${BLINK}Devnull Enabled${NORMAL}"
            ;;

    -u|--update)
            OPT_UPDATE=true
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
#   vars > active repo branch
##--------------------------------------------------------------------------

app_repo_branch_sel=$( [[ -n "$OPT_BRANCH" ]] && echo "$OPT_BRANCH" || echo "$app_repo_branch"  )

##--------------------------------------------------------------------------
#   Cache Sudo Password
#
#   require normal user sudo authentication for certain actions
##--------------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    sudo -k # make sure to ask for password on next sudo
    if sudo true && [ -n "${USER}" ]; then
        printf "  ${NORMAL}Welcome, ${USER}${NORMAL}\n" 1>&2
    else
        printf "  ${NORMAL}Sudoer Error: Wrong password x3{NORMAL}\n" 1>&2
        exit 1
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

        read response </dev/tty

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
    spin &
    app_pid_spin=$!
    trap "kill -9 $app_pid_spin 2> /dev/null" `seq 0 15`
    sleep 0.3
}

##--------------------------------------------------------------------------
#   func > finish action
#
#   this func supports opening a url at the end of the installation
#   however the command needs to have
#       finish "${1}"
##--------------------------------------------------------------------------

function finish()
{
    if ps -p $app_pid_spin > /dev/null
    then
        kill -9 $app_pid_spin 2> /dev/null
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
#   func > env path (add)
#
#   creates a new file inside /etc/profile.d/ which includes the new
#   proteus bin folder.
##--------------------------------------------------------------------------

function envpath_add()
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
    {

        local progress=0
        local bUpdated=false
        local cachedVer=$(get_version)

        local repo_branch=$([ "${1}" ] && echo "${1}" || echo "${app_repo_branch}" )
        local repo_branch_uri="${app_script/BRANCH/"$repo_branch"}"
        local repo_strip="https://raw.githubusercontent.com/"
        local repo_url=${repo_branch_uri//$repo_strip/}

        for i in {1..4}
        do
            progress=$(( $progress + $[ $RANDOM % 5 + 1 ] ))
            echo -e "XXX\n${progress}\nFetching Update Server\nXXX"
            sleep 0.$(( 100 + RANDOM % 800 ))
        done

        local REPO_CONN=$(curl -s "$app_mnfst")
        local REPO_NAME=$( jq -r '.name' <<< "${REPO_CONN}" )
        local REPO_VER=$( jq -r '.version' <<< "${REPO_CONN}" )
        local REPO_URL=$( jq -r '.url' <<< "${REPO_CONN}" )

        # To return true, second var needs to be lower
        if get_version_compare_gt $REPO_VER $(get_version); then
            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 5 + 1 ] ))
                echo -e "XXX\n${progress}\nUpdate Found! Updating to v${REPO_VER}\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 5 + 1 ] ))
                echo -e "XXX\n${progress}\nDownloading ${repo_url}\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo wget -O "${app_file_proteus}" -q "$repo_branch_uri" >/dev/null
            fi

            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 5 + 1 ] ))
                echo -e "XXX\n${progress}\nSetting owner of ${app_file_proteus} for user ${USER}\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo chgrp ${USER} ${app_file_proteus} >/dev/null
                sudo chown ${USER} ${app_file_proteus} >/dev/null
            fi

            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 5 + 1 ] ))
                echo -e "XXX\n${progress}\nGranting u+w on ${app_file_proteus} for user ${USER}\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo chmod u+x ${app_file_proteus} >/dev/null
            fi

            bUpdated=${REPO_VER}

        fi

        if [ "$bUpdated" == false ]; then
            sleep 2
            progress=60
            echo -e "XXX\n${progress}\nNo update found\nXXX"
            sleep 2
        fi

        for i in {1..4}
        do
            progress=$(( $progress + $[ $RANDOM % 3 + 1 ] ))
            echo -e "XXX\n${progress}\nConfirming ${app_file_proteus} exists\nXXX"
            sleep 0.$(( 100 + RANDOM % 800 ))
        done

        if [ -f ${app_file_proteus} ]; then
            progress=$(( $progress + $[ $RANDOM % 5 + 1 ] ))
            echo -e "XXX\n${progress}\nFound ${app_file_proteus}\nXXX"
            sleep 2

            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 5 + 1 ] ))
                echo -e "XXX\n${progress}\nValidating permissions\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            owner=$(stat -c '%U' ${app_file_proteus})

            if [ "x${owner}" = "x${USER}" ]; then
                progress=$(( $progress + $[ $RANDOM % 5 + 1 ] ))
                echo -e "XXX\n${progress}\nPermissions OK. Owner is ${app_file_proteus}\nXXX"
            else
                progress=$(( $progress + $[ $RANDOM % 5 + 1 ] ))
                echo -e "XXX\n${progress}\nPermissions FAILED. Fixing ...\nXXX"

                for i in {1..4}
                do
                    progress=$(( $progress + $[ $RANDOM % 3 + 1 ] ))
                    echo -e "XXX\n${progress}\nSetting owner of ${app_file_proteus} for user ${USER}\nXXX"
                    sleep 0.$(( 100 + RANDOM % 800 ))
                done

                if [ -z "${OPT_DEV_NULLRUN}" ]; then
                    sudo chgrp ${USER} ${app_file_proteus} >/dev/null
                    sudo chown ${USER} ${app_file_proteus} >/dev/null
                fi

                for i in {1..4}
                do
                    progress=$(( $progress + $[ $RANDOM % 3 + 1 ] ))
                    echo -e "XXX\n${progress}\nGranting u+w on ${app_file_proteus} for user ${USER}\nXXX"
                    sleep 0.$(( 100 + RANDOM % 800 ))
                done

                if [ -z "${OPT_DEV_NULLRUN}" ]; then
                    sudo chmod u+x ${app_file_proteus} >/dev/null
                fi

            fi

            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 3 + 1 ] ))
                echo -e "XXX\n${progress}\nCleaning up\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done
        fi

        echo -e "XXX\n100\nUpdater Complete!\nXXX"

        if [ "$bUpdated" != false ]; then
            result="Update Complete!\nv${cachedVer} => v${REPO_VER}\n\nBinary located at: ${app_file_proteus}"
            echo $result > result
        else
            result="No update found.\nYou are running the latest version v${cachedVer}\n\nBinary located at: ${app_file_proteus}"
            echo $result > result
        fi

    } | whiptail --gauge "Starting Updater ..." 6 110 0
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
    {

        local progress=0

        local repo_branch=$([ "${1}" ] && echo "${1}" || echo "${app_repo_branch}" )
        local repo_branch_uri="${app_script/BRANCH/"$repo_branch"}"
        local repo_strip="https://raw.githubusercontent.com/"
        local repo_url=${repo_branch_uri//$repo_strip/}

        local REPO_CONN=$(curl -s "$app_mnfst")
        local REPO_NAME=$( jq -r '.name' <<< "${REPO_CONN}" )
        local REPO_VER=$( jq -r '.version' <<< "${REPO_CONN}" )
        local REPO_URL=$( jq -r '.url' <<< "${REPO_CONN}" )

        local bMissingWhip=false
        local bMissingCurl=false
        local bMissingWget=false
        local bMissingNotify=false
        local bMissingYad=false
        local bMissingGPG=false
        local bMissingRepo=false

        for i in {1..4}
        do
            progress=$(( $progress + $[ $RANDOM % 2 + 1 ] ))
            echo -e "XXX\n${progress}\nInitializing Dependencies\nXXX"
            sleep 0.$(( 100 + RANDOM % 800 ))
        done

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

        # require notify-send
        if ! [ -x "$(command -v notify-send)" ]; then
            bMissingNotify=true
        fi

        # require yad
        if ! [ -x "$(command -v yad)" ]; then
            bMissingYad=true
        fi

        ##--------------------------------------------------------------------------
        #   Missing proteus-apt-repo gpg key
        #
        #   NOTE:   apt-key has been deprecated
        #           sudo add-apt-repository -y "deb [arch=amd64] https://raw.githubusercontent.com/${app_repo_dev}/${app_repo_apt}/master focal main" >/dev/null
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
        if [ "$bMissingWhip" = true ] ||  [ "$bMissingCurl" = true ] || [ "$bMissingWget" = true ] || [ "$bMissingNotify" = true ] || [ "$bMissingYad" = true ] || [ "$bMissingGPG" = true ] || [ "$bMissingRepo" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 2 + 1 ] ))
                echo -e "XXX\n${progress}\nDependencies Missing\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done
        fi
        
        ##--------------------------------------------------------------------------
        #   missing whiptail
        ##--------------------------------------------------------------------------

        if [ "$bMissingWhip" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 3 + 1 ] ))
                echo -e "XXX\n${progress}\nInstalling Package: Whiptail\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo apt-get update -y -q >> /dev/null 2>&1
                sudo apt-get install whiptail -y -qq >> /dev/null 2>&1
            fi
        fi

        ##--------------------------------------------------------------------------
        #   missing curl
        ##--------------------------------------------------------------------------

        if [ "$bMissingCurl" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 3 + 1 ] ))
                echo -e "XXX\n${progress}\nInstalling Package: Curl\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo apt-get update -y -q >> /dev/null 2>&1
                sudo apt-get install curl -y -qq >> /dev/null 2>&1
            fi
        fi

        ##--------------------------------------------------------------------------
        #   missing wget
        ##--------------------------------------------------------------------------

        if [ "$bMissingWget" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            for i in {1..7}
            do
                progress=$(( $progress + $[ $RANDOM % 3 + 1 ] ))
                echo -e "XXX\n${progress}\nInstalling Package: wget\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo apt-get update -y -q >> /dev/null 2>&1
                sudo apt-get install wget -y -qq >> /dev/null 2>&1
            fi
        fi

        ##--------------------------------------------------------------------------
        #   missing notify
        ##--------------------------------------------------------------------------

        if [ "$bMissingNotify" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            for i in {1..6}
            do
                progress=$(( $progress + $[ $RANDOM % 3 + 1 ] ))
                echo -e "XXX\n${progress}\nInstalling Package: notify-send\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo apt-get update -y -q >> /dev/null 2>&1
                sudo apt-get install libnotify-bin notify-osd -y -qq >> /dev/null 2>&1
            fi
        fi

        ##--------------------------------------------------------------------------
        #   missing yad
        ##--------------------------------------------------------------------------

        if [ "$bMissingYad" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            for i in {1..5}
            do
                progress=$(( $progress + $[ $RANDOM % 2 + 1 ] ))
                echo -e "XXX\n${progress}\nInstalling Package: yad\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo apt-get update -y -q >> /dev/null 2>&1
                sudo apt-get install yad -y -qq >> /dev/null 2>&1
            fi
        fi

        ##--------------------------------------------------------------------------
        #   missing gpg
        ##--------------------------------------------------------------------------

        if [ "$bMissingGPG" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 2 + 1 ] ))
                echo -e "XXX\n${progress}\nAdding github.com/${app_repo_dev}.gpg\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo wget -qO - "https://github.com/${app_repo_dev}.gpg" | sudo gpg --batch --yes --dearmor -o "/usr/share/keyrings/${app_repo_apt_pkg}.gpg" >/dev/null
            fi
        fi

        ##--------------------------------------------------------------------------
        #   missing proteus apt repo
        ##--------------------------------------------------------------------------

        if [ "$bMissingRepo" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 2 + 1 ] ))
                echo -e "XXX\n${progress}\nRegistering ${app_repo_apt}\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/${app_repo_apt_pkg}.gpg] https://raw.githubusercontent.com/${app_repo_dev}/${app_repo_apt}/master $(lsb_release -cs) ${app_repo_branch}" | sudo tee /etc/apt/sources.list.d/${app_repo_apt_pkg}.list >/dev/null
            fi

            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 2 + 1 ] ))
                echo -e "XXX\n${progress}\nUpdating repo list\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo apt-get update -y -q >/dev/null
            fi
        fi

        ##--------------------------------------------------------------------------
        #   install app manager proteus file in /HOME/USER/bin/proteus
        ##--------------------------------------------------------------------------

        if ! [ -f "$app_file_proteus" ] || [ -n "${OPT_DEV_NULLRUN}" ]; then

            for i in {1..4}
            do
                progress=$(( $progress + $[ $RANDOM % 2 + 1 ] ))
                echo -e "XXX\n${progress}\nInstalling Proteus: ${repo_url}\nXXX"
                sleep 0.$(( 100 + RANDOM % 800 ))
            done

            if [ -z "${OPT_DEV_NULLRUN}" ]; then
                sudo wget -O "${app_file_proteus}" -q "$repo_branch_uri" >/dev/null
                sudo chgrp ${USER} ${app_file_proteus} >/dev/null
                sudo chown ${USER} ${app_file_proteus} >/dev/null
                sudo chmod u+x ${app_file_proteus} >/dev/null
            fi
        fi

        ##--------------------------------------------------------------------------
        #   add env path /HOME/USER/bin/
        ##--------------------------------------------------------------------------

        envpath_add $HOME/bin

        for i in {1..4}
        do
            progress=$(( $progress + $[ $RANDOM % 2 + 1 ] ))
            echo -e "XXX\n${progress}\nRegistering ENV var: ${HOME}/bin\nXXX"
            sleep 0.$(( 100 + RANDOM % 800 ))
        done

        echo -e "XXX\n100\nSetup Complete!\nXXX"

        sleep 0.5

        result="Proteus App Manager v${REPO_VER} has been installed\n\nBinary located at: ${app_file_proteus}"
        echo $result > result

    } | whiptail --gauge "Starting Wizard ..." 6 110 0
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
    echo -e "  This wizard will allow you to install Proteus or add the Proteus Apt"
    echo -e "  Repo to your system."
    echo
    printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}PID ${NORMAL}" "${BOLD}${FUCHSIA} $$ ${NORMAL}"
    printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}USER ${NORMAL}" "${BOLD}${FUCHSIA} ${USER} ${NORMAL}"
    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo

    sleep 0.3

    echo
}

##--------------------------------------------------------------------------
#   show header
##--------------------------------------------------------------------------

show_header
sleep 1

##--------------------------------------------------------------------------
#   selection menu
##--------------------------------------------------------------------------

while true; do
    CHOICE=$( whiptail \
        --title "Selection Menu" \
        --backtitle "${app_title} v$(get_version)" \
        --menu "\nMake a selection from the menu options below. To switch between SELECT and EXIT, press <TAB>.\n\nUse the arrow keys to move between options.\n\n" 22 66 3 \
        --ok-button Select \
        --cancel-button Exit \
        "1" "    Install Proteus" \
        "2" "    Update Proteus & Verify" \
        "Q" "    Quit"  3>&2 2>&1 1>&3 )

    case $CHOICE in
        "1")
	        app_setup
		    read -r result < result
            whiptail --msgbox "$result" 13 80
            ;;

        "2")
	        app_update
		    read -r result < result
            whiptail --msgbox "$result" 13 80
            ;;
    
        "Q")
            exit
            break 2
            exit
            ;;
    esac
    status=$?

    # exit
    # choice returns blank
    if [ -z ${CHOICE} ]; then
        break 2
        exit
    fi

done