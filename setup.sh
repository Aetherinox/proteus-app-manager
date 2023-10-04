#!/bin/bash
##--------------------------------------------------------------------------
#   @author :           aetherinox
#   @script :           ZorinOS App Manager
#   @when   :           2023-10-01 22:31:48
#   @url    :           https://github.com/Aetherinox/zorin-app-manager
#
#   requires chmod +x setup.sh
#
##--------------------------------------------------------------------------

##--------------------------------------------------------------------------
#   vars > General
##--------------------------------------------------------------------------

# working directory
dir=$(pwd)
dir_hosts="/etc/hosts"
dir_swizzin="$dir/libraries/swizzin"
file=$(basename "$0")

##--------------------------------------------------------------------------
#   vars > logs
##--------------------------------------------------------------------------

export DATE=$(date '+%Y%m%d')
export TIME=$(date '+%H:%M:%S')
export ARGS=$1
export LOGS_DIR="$dir/logs"
export LOGS_FILE="$LOGS_DIR/zorin_${DATE}.log"

##--------------------------------------------------------------------------
#   arguments
##--------------------------------------------------------------------------

OPTIND=1
while getopts ":S" opt ; do
    case $opt in
        S)
            NO_JOB_LOGGING="true"
            ;;
    esac
done

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
#   [ QUAD9 DNS ]
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
#   vars > gui menu
##--------------------------------------------------------------------------

gui_ver=("1" "0" "0" "0" )
gui_width=310
gui_height=425
gui_title="ZorinOS App Manager (Aetherx)"
gui_desc="Select the app / package you wish to install. Most apps will run as silent installs.\n\nIf you encounter issues, review the logfile located at:\n      ${LOGS_FILE}\n\nYou can search for an app by pressing tilde \`\n\n"
gui_column="Available Packages"
gui_uri_github="https://github.com/Aetherinox/zorin-app-manager"

##--------------------------------------------------------------------------
#   vars > developer
#
#   these settings should not be messed with. they cause the program to
#   act in unexpected ways.
##--------------------------------------------------------------------------

bDev=false
bDevNoAct=false
pid_spin=0
i_apps=0
SECONDS=0 # built-in var
dev_str=$(if [ "$bDev" = true ]; then echo "Enabled"; else echo "Disabled"; fi)

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
#   arrays
##--------------------------------------------------------------------------

apps=()
devs=()

##--------------------------------------------------------------------------
#   func > get version
##--------------------------------------------------------------------------

function get_version()
{
    ver_join=${gui_ver[@]}
    ver_str=${ver_join// /.}
    echo ${ver_str}
}

##--------------------------------------------------------------------------
#   func > notify-send
#
#   because this script requires some actions as sudo, notify-send will not
#   work because it has no clue which user to send the notification to.
#
#   use this as a bypass to figure out what user is logged in.
#
#   could use zenity for this, but notifications are limited.
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
#   distro
##--------------------------------------------------------------------------

if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
    OS_VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
    OS_VER=$(lsb_release -sr)
elif [ -f /etc/lsb-release ]; then
    # For some versions of Debian/Ubuntu without lsb_release command
    . /etc/lsb-release
    OS=$DISTRIB_ID
    OS_VER=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    # Older Debian/Ubuntu/etc.
    OS=Debian
    OS_VER=$(cat /etc/debian_version)
else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
    OS_VER=$(uname -r)
fi


##--------------------------------------------------------------------------
#   func > logs > begin
##--------------------------------------------------------------------------

function Logs_Begin()
{
    if [ $NO_JOB_LOGGING ] ; then
        zenity --info \
        --width="250" \
        --height="100" \
        --title="Silent Mode" \
        --text="Logging disabled, running in silent mode" \
        --ok-label "I Understand"
    else
        mkdir -p $LOGS_DIR
        Pipe=${LOGS_FILE}.pipe

        # get name of display in use
        local display=":$(ls /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"

        # get user using display
        local user=$(who | grep '('$display')' | awk '{print $1}' | head -n 1)

        if ! [[ -p $Pipe ]]; then
            mkfifo -m 775 $Pipe
            printf "%-30s %-5s\n" "${TIME}      Creating new pipe ${Pipe}" | tee -a "${LOGS_FILE}" >/dev/null
        fi

        LOGS_OBJ=${LOGS_FILE}
        exec 3>&1
        tee -a ${LOGS_OBJ} <$Pipe >&3 &
        teepid=$!
        exec 1>$Pipe
        PIPE_OPENED=1

        printf "%-30s %-5s\n" "${TIME}      Logging to ${LOGS_OBJ}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-30s %-5s\n" "${TIME}      Software  : ${gui_title}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-30s %-5s\n" "${TIME}      Version   : v$(get_version)" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-30s %-5s\n" "${TIME}      Process   : $$" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-30s %-5s\n" "${TIME}      OS        : ${OS}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-30s %-5s\n" "${TIME}      OS VER    : ${OS_VER}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-30s %-5s\n" "${TIME}      DATE      : ${DATE}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-30s %-5s\n" "${TIME}      TIME      : ${TIME}" | tee -a "${LOGS_FILE}" >/dev/null

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
        ps --pid $teepid >/dev/null
        if [ $? -eq 0 ] ; then
            # wait $teepid whould be better but some
            # commands leave file descriptors open
            sleep 1
            kill  $teepid
        fi

        printf "%-30s %-15s\n" "${TIME}      Destroying Pipe ${Pipe} (${teepid})" | tee -a "${LOGS_FILE}" >/dev/null

        rm $Pipe
        unset PIPE_OPENED
    fi

    duration=$SECONDS
    elapsed="$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

    printf "%-30s %-15s\n" "${TIME}      User Input: OnClick ......... Exit App" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-30s %-15s\n\n\n\n" "${TIME}      ${elapsed}" | tee -a "${LOGS_FILE}" >/dev/null

    sudo pkill -9 -f ".$LOGS_FILE." >> $LOGS_FILE 2>&1
}

Logs_Begin

##--------------------------------------------------------------------------
#   Cache Sudo Password
##--------------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    sudo -k # make sure to ask for password on next sudo
    if sudo true && [ -n "${USER}" ]; then
        printf "\n%-30s %-5s\n\n" "${TIME}      SUDO [SIGN-IN]: Welcome, ${USER}" | tee -a "${LOGS_FILE}" >/dev/null
    else
        printf "\n%-30s %-5s\n\n" "${TIME}      SUDO Failure: Wrong Password x3" | tee -a "${LOGS_FILE}" >/dev/null
        exit 1
    fi
else
    if [ -n "${USER}" ]; then
        printf "\n%-30s %-5s\n\n" "${TIME}      SUDO [EXISTING]: $USER" | tee -a "${LOGS_FILE}" >/dev/null
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
#   func > begin action
##--------------------------------------------------------------------------

function begin()
{
    # start spinner
    spin &

    # spinner PID
    pid_spin=$!

    printf "%-30s %-5s\n\n" "${TIME}      NEW Spinner: PID (${pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null

    # kill spinner on any signal
    trap "kill -9 $pid_spin 2> /dev/null" `seq 0 15`

    printf '%-46s %-5s' "  ${1}" ""

    sleep 0.3
}

##--------------------------------------------------------------------------
#   func > finish action
##--------------------------------------------------------------------------

function finish()
{
    if ps -p $pid_spin > /dev/null
    then
        kill -9 $pid_spin 2> /dev/null
        printf "\n%-30s %-5s\n" "${TIME}      KILL Spinner: PID (${pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null
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
#   output some logging
##--------------------------------------------------------------------------

[ "$bDev" = true ] && printf "%-30s %-5s\n" "${TIME}      Notice: Dev Mode Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ "$bDev" = false ] && printf "%-30s %-5s\n" "${TIME}      Notice: Dev Mode Disabled" | tee -a "${LOGS_FILE}" >/dev/null

[ "$bDevNoAct" = true ] && printf "%-30s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ "$bDevNoAct" = false ] && printf "%-30s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Disabled" | tee -a "${LOGS_FILE}" >/dev/null

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
bInstall_app_cdialog=true
bInstall_app_blender_flatpak=true
bInstall_app_blender_snapd=true
bInstall_app_colorpicker_snapd=true
bInstall_app_conky=true
bInstall_app_curl=true
bInstall_app_flatpak=true
bInstall_app_gdebi=true
bInstall_app_git=true
bInstall_app_gnome_ext_arcmenu=true
bInstall_app_gnome_ext_core=true
bInstall_app_gnome_ext_ism=true
bInstall_app_gpick=true
bInstall_app_kooha=true
bInstall_app_members=true
bInstall_app_mlocate=true
bInstall_app_neofetch=true
bInstall_app_nettools=true
bInstall_app_ocsurl=true
bInstall_app_pacman=true
bInstall_app_pihole=true
bInstall_app_reprepro=true
bInstall_app_rpm=true
bInstall_app_seahorse=true
bInstall_app_snapd=true
bInstall_app_swizzin=true
bInstall_app_sysload=true
bInstall_app_teamviewer=true
bInstall_app_tree=true
bInstall_twk_filepath=true
bInstall_twk_netplan=true
bInstall_twk_network_hosts=true
bInstall_twk_vbox_additions_fix=true
bInstall_app_vsc_stable=true
bInstall_app_vsc_insiders=true
bInstall_app_wxhexeditor=true
bInstall_app_yad=true
bInstall_app_ziet_cron=true
bInstall_app_zenity=true
bInstall_app_zorinospro_lo=true

##--------------------------------------------------------------------------
#   vars > app names > live
##--------------------------------------------------------------------------

app_all="⭐ All"
app_alien="Alien Package Converter"
app_appimage="AppImage Launcher"
app_blender_flatpak="Blender (using Flatpak)"
app_blender_snapd="Blender (using Snapd)"
app_cdialog="cdialog (ComeOn Dialog)"
app_colorpicker_snapd="Color Picker (using Snapd)"
app_conky="Conky Manager"
app_curl="curl"
app_flatpak="Flatpak"
app_gdebi="GDebi"
app_git="Git"
app_gnome_ext_arcmenu="Gnome Ext (ArcMenu)"
app_gnome_ext_core="Gnome Manager (Core)"
app_gnome_ext_ism="Gnome Ext (Speed Monitor)"
app_gpick="gPick (Color Picker)"
app_kooha="Kooha (Screen Recorder)"
app_members="members"
app_mlocate="mlocate"
app_neofetch="neofetch"
app_nettools="net-tools"
app_ocsurl="ocs-url"
app_pacman="Pacman Package Management"
app_pihole="Pi-Hole"
app_reprepro="reprepro (Apt on Github)"
app_rpm="RPM Package Manager"
app_seahorse="Seahorse (Passwd & Keys)"
app_snapd="Snapd"
app_swizzin="Swizzin (Modular Seedbox)"
app_sysload="System Monitor"
app_teamviewer="Teamviewer"
app_tree="tree"
twk_filepath="Patch: Path in File Explorer"
twk_netplan="Patch: Netplan Configuration"
twk_network_hosts="Patch: Update Net Hosts"
twk_vbox_additions_fix="Patch: VBox Additions"
app_unrar="Unrar"
app_vsc_stable="VS Code (Stable)"
app_vsc_insiders="VS Code (Insiders)"
app_wxhexeditor="wxHexEditor"
app_yad="YAD (Yet Another Dialog)"
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

declare -A get_functions
get_functions=(
    ["$app_dev_a"]='fn_dev_a'
    ["$app_dev_b"]='fn_dev_b'
    ["$app_dev_c"]='fn_dev_c'
    ["$app_dev_d"]='fn_dev_d'
    ["$app_dev_e"]='fn_dev_e'
    ["$app_dev_f"]='fn_dev_f'

    ["$app_all"]='fn_app_all'
    ["$app_alien"]='fn_app_alien'
    ["$app_appimage"]='fn_app_appimg'
    ["$app_blender_flatpak"]='fn_app_blender_flatpak'
    ["$app_blender_snapd"]='fn_app_blender_snapd'
    ["$app_colorpicker_snapd"]='fn_app_colorpicker_snapd'
    ["$app_cdialog"]='fn_app_cdialog'
    ["$app_conky"]='fn_app_conky'
    ["$app_curl"]='fn_app_curl'
    ["$app_flatpak"]='fn_app_flatpak'
    ["$app_gdebi"]='fn_app_gdebi'
    ["$app_git"]='fn_app_git'
    ["$app_gnome_ext_arcmenu"]='fn_app_gnome_ext_arcmenu'
    ["$app_gnome_ext_core"]='fn_app_gnome_ext_core'
    ["$app_gnome_ext_ism"]='fn_app_gnome_ext_ism'
    ["$app_gpick"]='fn_app_gpick'
    ["$app_kooha"]='fn_app_kooha'
    ["$app_members"]='fn_app_members'
    ["$app_mlocate"]='fn_app_mlocate'
    ["$app_neofetch"]='fn_app_neofetch'
    ["$app_nettools"]='fn_app_nettools'
    ["$app_ocsurl"]='fn_app_ocsurl'
    ["$app_pacman"]='fn_app_pacman'
    ["$app_pihole"]='fn_app_serv_pihole'
    ["$app_reprepro"]='fn_app_reprepro'
    ["$app_rpm"]='fn_app_rpm'
    ["$app_seahorse"]='fn_app_seahorse'
    ["$app_snapd"]='fn_app_snapd'
    ["$app_swizzin"]='fn_app_swizzin'
    ["$app_sysload"]='fn_app_sysload'
    ["$app_teamviewer"]='fn_app_teamviewer'
    ["$app_tree"]='fn_app_tree'
    ["$twk_filepath"]='fn_twk_filepath'
    ["$twk_netplan"]='fn_twk_netplan'
    ["$twk_network_hosts"]='fn_twk_network_hosts'
    ["$twk_vbox_additions_fix"]='fn_twk_vbox_additions_fix'
    ["$app_unrar"]='fn_app_unrar'
    ["$app_vsc_stable"]='fn_app_vsc_stable'
    ["$app_vsc_insiders"]='fn_app_vsc_insiders'
    ["$app_wxhexeditor"]='fn_app_wxhexeditor'
    ["$app_yad"]='fn_app_yad'
    ["$app_zenity"]='fn_app_zenity'
    ["$app_ziet_cron"]='fn_app_ziet_cron'
    ["$app_zorinospro_lo"]='fn_app_zorinospro_lo'
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

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install alien -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   App Image Launcher
##--------------------------------------------------------------------------

function fn_app_appimg()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo add-apt-repository --yes ppa:appimagelauncher-team/stable >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install appimagelauncher -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Blender (using Flatpak)
##--------------------------------------------------------------------------

function fn_app_blender_flatpak()
{
    begin "${1}"

    if ! [ -x "$(command -v flatpak)" ]; then
	    echo -e "[ ${STATUS_HALT} ]"
        echo
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing first ...${NORMAL}" >&2
        echo

        fn_app_flatpak

        printf '%-46s %-5s' "  ${1}" ""
        sleep 1
    fi

    if [ "$bDevNoAct" = false ] ; then

        sudo flatpak repair --system >> $LOGS_FILE 2>&1
        flatpak install flathub org.blender.Blender -y --noninteractive >> $LOGS_FILE 2>&1

    fi

	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Blender (using Snapd)
##--------------------------------------------------------------------------

function fn_app_blender_snapd()
{
    begin "${1}"

    if ! [ -x "$(command -v snap)" ]; then
	    echo -e "[ ${STATUS_HALT} ]"
        echo
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing first ...${NORMAL}" >&2
        echo

        fn_app_snapd

        printf '%-46s %-5s' "  ${1}" ""
        sleep 1
    fi

    if [ "$bDevNoAct" = false ] ; then

        sudo flatpak repair --system >> $LOGS_FILE 2>&1
        flatpak install flathub org.blender.Blender -y --noninteractive >> $LOGS_FILE 2>&1

    fi

	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Color Picker
##--------------------------------------------------------------------------

function fn_app_colorpicker_snapd()
{
    begin "${1}"

    if ! [ -x "$(command -v snap)" ]; then
	    echo -e "[ ${STATUS_HALT} ]"
        echo
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing first ...${NORMAL}" >&2
        echo

        fn_app_snapd

        printf '%-46s %-5s' "  ${1}" ""
        sleep 1
    fi

    if [ "$bDevNoAct" = false ] ; then

        sudo snap install color-picker >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   cdialog (ComeOn Dialog)
##--------------------------------------------------------------------------

function fn_app_cdialog()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo add-apt-repository --yes universe >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install dialog -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Conky Manager
##--------------------------------------------------------------------------

function fn_app_conky()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo add-apt-repository --yes ppa:teejee2008/foss >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1

        sudo apt-get install conky-all -y -qq >> $LOGS_FILE 2>&1
        sudo apt-get install conky-manager2 -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   curl
##--------------------------------------------------------------------------

function fn_app_curl()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install curl -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Flatpak
##--------------------------------------------------------------------------

function fn_app_flatpak()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install flatpak -y -qq >> $LOGS_FILE 2>&1

    fi

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

    if [ "$bDevNoAct" = false ] ; then

        sudo add-apt-repository --yes universe >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install gdebi -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Git
##--------------------------------------------------------------------------

function fn_app_git()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install git -y -qq >> $LOGS_FILE 2>&1

    fi

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

    if ! [ -x "$(command -v gnome-shell-extension-installer)" ]; then
	    echo -e "[ ${STATUS_HALT} ]"
        echo
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_gnome_ext_core}. Installing first ...${NORMAL}" >&2
        echo

        fn_app_gnome_ext_core

        printf '%-46s %-5s' "  ${1}" ""
        sleep 1
    fi

    if [ "$bDevNoAct" = false ] ; then

        gnome-shell-extension-installer $app_ext_id_arcmenu --yes >> $LOGS_FILE 2>&1

        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Restarting Shell" ""

        sleep 3

        sudo pkill -TERM gnome-shell >> $LOGS_FILE 2>&1

        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Enable ArcMenu" ""

        sleep 3

        gnome-extensions enable "arcmenu@arcmenu.com"

    fi

	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Gnome Extension Manager
##--------------------------------------------------------------------------

function fn_app_gnome_ext_core()
{
    begin "${1}"

    if ! [ -x "$(command -v flatpak)" ]; then
	    echo -e "[ ${STATUS_HALT} ]"
        echo
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing first ...${NORMAL}" >&2
        echo

        fn_app_flatpak

        printf '%-46s %-5s' "  ${1}" ""
        sleep 1
    fi

    if [ "$bDevNoAct" = false ] ; then

        sudo flatpak repair --system >> $LOGS_FILE 2>&1

        flatpak install flathub com.mattjakeman.ExtensionManager -y --noninteractive >> $LOGS_FILE 2>&1

        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Plugins" ""

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get upgrade -q >> $LOGS_FILE 2>&1
        sudo apt-get install gnome-shell-extensions -y -qq >> $LOGS_FILE 2>&1
        sudo apt-get install gnome-tweaks -y -qq >> $LOGS_FILE 2>&1
        sudo apt-get install chrome-gnome-shell -y -qq >> $LOGS_FILE 2>&1

        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Installer" ""

        wget -O gnome-shell-extension-installer -q "https://github.com/brunelli/gnome-shell-extension-installer/raw/master/gnome-shell-extension-installer" >> $LOGS_FILE 2>&1
        sudo chmod +x gnome-shell-extension-installer
        sudo mv gnome-shell-extension-installer /usr/bin/

    fi

	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Internet Speed Monitor
##--------------------------------------------------------------------------

function fn_app_gnome_ext_ism()
{
    begin "${1}"

    if ! [ -x "$(command -v gnome-shell-extension-installer)" ]; then
	    echo -e "[ ${STATUS_HALT} ]"
        echo
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_gnome_ext_core}. Installing first ...${NORMAL}" >&2
        echo

        fn_app_gnome_ext_core

        printf '%-46s %-5s' "  ${1}" ""
        sleep 1
    fi

    if [ "$bDevNoAct" = false ] ; then

        # Internet Speed Monitor
        # this is the one with the bar at the bottom with up/down/total text

        gnome-shell-extension-installer $app_ext_id_sysload --yes >> $LOGS_FILE 2>&1

        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Restarting Shell" ""

        sleep 3

        sudo pkill -TERM gnome-shell >> $LOGS_FILE 2>&1

        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Enabling" ""

        sleep 3

        gnome-extensions enable "InternetSpeedMonitor@Rishu"

    fi

	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   gPick (Color Picker)
##--------------------------------------------------------------------------

function fn_app_gpick()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install gpick -y -qq >> $LOGS_FILE 2>&1

    fi

	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Kooha (Screen Recorder)
##--------------------------------------------------------------------------

function fn_app_kooha()
{
    begin "${1}"

    if ! [ -x "$(command -v flatpak)" ]; then
	    echo -e "[ ${STATUS_HALT} ]"
        echo
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing first ...${NORMAL}" >&2
        echo

        fn_app_flatpak

        printf '%-46s %-5s' "  ${app_gnome_ext_core}" ""
        sleep 1
    fi

    if [ "$bDevNoAct" = false ] ; then

        sudo flatpak repair --system >> $LOGS_FILE 2>&1
        flatpak remote-add --comment="Screen recorder" --if-not-exists flathub "https://flathub.org/repo/flathub.flatpakrepo"
        flatpak install flathub io.github.seadve.Kooha -y --noninteractive >> $LOGS_FILE 2>&1

        printf '%-46s %-5s' "    |--- Install pipewire" ""
        sleep 1

        sudo add-apt-repository --yes ppa:pipewire-debian/pipewire-upstream >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install pipewire -y -qq >> $LOGS_FILE 2>&1

    fi

	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Member Package > Group Management
##--------------------------------------------------------------------------

function fn_app_members()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install members -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   mlocate
##--------------------------------------------------------------------------

function fn_app_mlocate()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install mlocate -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   neofetch
##--------------------------------------------------------------------------

function fn_app_neofetch()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install neofetch -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   net-tools
##--------------------------------------------------------------------------

function fn_app_nettools()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install net-tools -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   ocs-url
##--------------------------------------------------------------------------

function fn_app_ocsurl()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then
        sudo wget -P /var/cache/apt/archives/ https://raw.githubusercontent.com/Aetherinox/zorin-app-manager/main/packages/dists/focal/main/ocs-url_3.1.0-0ubuntu1_amd64.deb >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install libqt5svg5 qml-module-qtquick-controls -y -qq >> $LOGS_FILE 2>&1
        sudo apt-get install /var/cache/apt/archives/ocs-url*.deb >> $LOGS_FILE 2>&1
        # sudo dpkg --force-depends --install /var/cache/apt/archives/ocs-url*.deb >> $LOGS_FILE 2>&1
    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Pacman Package Manager
##--------------------------------------------------------------------------

function fn_app_pacman()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install pacman -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   reprepro
##--------------------------------------------------------------------------

function fn_app_reprepro()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install app_reprepro -y -qq >> $LOGS_FILE 2>&1

    fi

	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   RPM Package Manager
##--------------------------------------------------------------------------

function fn_app_rpm()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install rpm -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Seahorse Passwords and Keys
##--------------------------------------------------------------------------

function fn_app_seahorse()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        echo

        printf '%-46s %-5s' "    |--- Remove Base" ""
        sleep 1
        sudo dpkg -r --force seahorse >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Apt Update" ""
        sleep 1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Install seahorse" ""
        sleep 1
        sudo apt-get install seahorse -y -qq >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Install seahorse-nautilus" ""
        sleep 1
        sudo apt-get install seahorse-nautilus -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Cache Sudo Password
##--------------------------------------------------------------------------

function fn_app_snapd()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install snapd -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Swizzin
##--------------------------------------------------------------------------

function fn_app_swizzin()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        echo

        swizzin_url=s5n.sh
        swizzin_file=swizzin.sh

        printf '%-46s %-5s' "    |--- Download s5n.sh" ""
        sleep 1
        wget -O "${swizzin_file}" -q "${swizzin_url}"
        sudo chmod +x "${swizzin_file}"
        echo -e "[ ${STATUS_OK} ]"

        sleep 1

        printf '%-46s %-5s' "    |--- Adding Zorin Compatibility" ""
        sleep 1
        while IFS='' read -r a; do
            echo "${a//Debian|Ubuntu/Debian|Ubuntu|Zorin}"
        done < "${swizzin_file}" > "${swizzin_file}.t"

        mv "${swizzin_file}"{.t,} >> $LOGS_FILE 2>&1

        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Killing apt-get" ""
        sleep 1
        # instances where an issue will cause apt-get to hang and keeps the installation
        # wizard from running again. ensure
        sudo pkill -9 -f "apt-get update" >> $LOGS_FILE 2>&1
        echo

        sleep 2

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

    if [ "$bDevNoAct" = false ] ; then

        sudo add-apt-repository --yes ppa:indicator-multiload/stable-daily >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install indicator-multiload -y -qq >> $LOGS_FILE 2>&1

    fi

	echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Teamviewer
##--------------------------------------------------------------------------

function fn_app_teamviewer()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install -y libminizip1 -qq >> $LOGS_FILE 2>&1

        wget -q "https://download.teamviewer.com/download/linux/teamviewer_amd64.deb" >> $LOGS_FILE 2>&1
        sudo dpkg -i teamviewer_*.deb >> $LOGS_FILE 2>&1
        sudo apt-get -y -f install -qq >> $LOGS_FILE 2>&1

        sudo rm teamviewer_*.deb >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   tree
##--------------------------------------------------------------------------

function fn_app_tree()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install tree -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Pihole
##--------------------------------------------------------------------------

function fn_app_serv_pihole()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get upgrade -q >> $LOGS_FILE 2>&1

        #curl -sSL https://install.pi-hole.net | sudo PIHOLE_SKIP_OS_CHECK=true bash

    fi

	echo -e "[ ${STATUS_OK} ]"

    if [ "$bDevNoAct" = false ] ; then

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

    if [ "$bDevNoAct" = false ] ; then

        # current user
        gsettings set org.gnome.nautilus.preferences always-use-location-entry true >> $LOGS_FILE 2>&1

        # root
        sudo gsettings set org.gnome.nautilus.preferences always-use-location-entry true >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Netplan configuration
##--------------------------------------------------------------------------

function fn_twk_netplan()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then
        if [ -z "${netplan_macaddr}" ]; then
            netplan_macaddr=$(cat /sys/class/net/*/address | awk 'NR == 1' )
        fi

sudo tee /etc/netplan/50-cloud-init.yaml >/dev/null <<EOF
# This file is auto-generated by ZorinOS App Manager
# ${gui_uri_github}
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

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Network host file
##--------------------------------------------------------------------------

function fn_twk_network_hosts()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        echo

        if [ ! -f "$dir_hosts" ]; then
            touch "$dir_hosts"
        fi

        for item in $hosts
        do
            id=$(echo "$item"  | sed 's/ *\\t.*//')

            printf '%-46s %-5s' "    |--- + $id" ""
            sleep 1

            if grep -Fxq "$id" $dir_hosts
            then
                echo -e "[ ${STATUS_SKIP} ]"
            else
                sed -i -e '1i'$item "$dir_hosts"
                echo -e "[ ${STATUS_OK} ]"
            fi
        done

    else

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

    if [ "$bDevNoAct" = false ] ; then

        echo

        printf '%-46s %-5s' "    |--- Updating packages" ""
        sleep 1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Installing dependencies" ""
        sleep 1
        sudo apt-get install gcc make build-essential dkms linux-headers-$(uname -r) -y -qq >> $LOGS_FILE 2>&1
        echo -e "[ ${STATUS_OK} ]"

        printf '%-46s %-5s' "    |--- Remove open-vm-tools*" ""
        sleep 1

        sudo apt-get remove open-vm-tools -y -qq >> $LOGS_FILE 2>&1
        sleep 2
        # apt-get remove doesnt seem to remove everything related to open-vm, so now we have to hit it
        # with a double shot. this is what fixes it.
        sudo dpkg -P open-vm-tools-desktop >> $LOGS_FILE 2>&1
        sleep 2
        sudo dpkg -P open-vm-tools >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    prompt_reboot=$(zenity --info \
    --width="250" \
    --height="100" \
    --title="Restart Required" \
    --text="To complete removal of open-vm-tools, reboot your machine." \
    --extra-button "Restart Now" \
    --ok-label "OK")
    ret=$?

    if [[ "$prompt_reboot" == "Restart Now" ]]; then
        sudo shutdown -r +1 "System will reboot in 1 minute" >> $LOGS_FILE 2>&1
        notify-send -u critical "Restart Pending" "A system restart will occur in 1 minute." >> $LOGS_FILE 2>&1
    fi

    finish
}

##--------------------------------------------------------------------------
#   unrar
##--------------------------------------------------------------------------

function fn_app_unrar()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install unrar -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Visual Studio Code ( Stable )
##--------------------------------------------------------------------------

function fn_app_vsc_stable()
{
    begin "${1}"

    if ! [ -x "$(command -v snap)" ]; then
	    echo -e "[ ${STATUS_HALT} ]"
        echo
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing first ...${NORMAL}" >&2
        echo

        fn_app_snapd

        printf '%-46s %-5s' "  ${1}" ""
        sleep 1
    fi

    if [ "$bDevNoAct" = false ] ; then

        sudo snap install --classic code >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   Visual Studio Code ( Insiders )
##--------------------------------------------------------------------------

function fn_app_vsc_insiders()
{
    begin "${1}"

    if ! [ -x "$(command -v snap)" ]; then
	    echo -e "[ ${STATUS_HALT} ]"
        echo
        echo -e "  ${BOLD}${RED}Error:${NORMAL}${GREYL} Missing ${app_flatpak}. Installing first ...${NORMAL}" >&2
        echo

        fn_app_snapd

        printf '%-46s %-5s' "  ${1}" ""
        sleep 1
    fi

    if [ "$bDevNoAct" = false ] ; then

        sudo snap install --classic code-insiders >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   wxhexeditor
##--------------------------------------------------------------------------

function fn_app_wxhexeditor()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install wxhexeditor -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   YAD (Yet another dialog)
##--------------------------------------------------------------------------

function fn_app_yad()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install yad -y -qq >> $LOGS_FILE 2>&1

    fi

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

    if [ "$bDevNoAct" = false ] ; then

        sudo add-apt-repository --yes universe >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install zenity -y -qq >> $LOGS_FILE 2>&1

    fi

    if [ -z "${3}" ]; then
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

    if [ "$bDevNoAct" = false ] ; then

        sudo add-apt-repository --yes ppa:blaze/main >> $LOGS_FILE 2>&1
        sudo apt-get update -y -q >> $LOGS_FILE 2>&1
        sudo apt-get install zeit -y -qq >> $LOGS_FILE 2>&1

    fi

    echo -e "[ ${STATUS_OK} ]"

    finish
}

##--------------------------------------------------------------------------
#   ZorinOS Pro Layouts
##--------------------------------------------------------------------------

function fn_app_zorinospro_lo()
{
    begin "${1}"

    if [ "$bDevNoAct" = false ] ; then

        echo

        printf '%-46s %-5s' "    |--- clean /appearance" ""
        sleep 1

        # clean existing backup folder /zorin_appearance_bk/
        if [ -d "/usr/lib/python3/dist-packages/zorin_appearance_bk" ]
        then
            sudo rm -rf "/usr/lib/python3/dist-packages/zorin_appearance_bk" >> $LOGS_FILE 2>&1
            echo -e "[ ${STATUS_OK} ]"
        else
            echo -e "[ ${STATUS_SKIP} ]"
        fi

        printf '%-46s %-5s' "    |--- clean /appearance-4.1.egg" ""
        sleep 1

        # clean existing backup folder /zorin_appearance-4.1.egg-info_bk/
        if [ -d "/usr/lib/python3/dist-packages/zorin_appearance-4.1.egg-info_bk" ]
        then
            sudo rm -rf "/usr/lib/python3/dist-packages/zorin_appearance-4.1.egg-info_bk" >> $LOGS_FILE 2>&1
            echo -e "[ ${STATUS_OK} ]"
        else
            echo -e "[ ${STATUS_SKIP} ]"
        fi

        printf '%-46s %-5s' "    |--- backup /appearance" ""
        sleep 1

        # backup /zorin_appearance/
        if [ -d "/usr/lib/python3/dist-packages/zorin_appearance" ]
        then
            sudo mv -f /usr/lib/python3/dist-packages/zorin_appearance /usr/lib/python3/dist-packages/zorin_appearance_bk >> $LOGS_FILE 2>&1
            echo -e "[ ${STATUS_OK} ]"
        else
            echo -e "[ ${STATUS_MISS} ]"
        fi

        printf '%-46s %-5s' "    |--- backup /appearance-4.1.egg" ""
        sleep 1

        # backup /zorin_appearance-4.1.egg-info/
        if [ -d "/usr/lib/python3/dist-packages/zorin_appearance-4.1.egg-info" ]
        then
            sudo mv -f /usr/lib/python3/dist-packages/zorin_appearance-4.1.egg-info /usr/lib/python3/dist-packages/zorin_appearance-4.1.egg-info_bk >> $LOGS_FILE 2>&1
            echo -e "[ ${STATUS_OK} ]"
        else
            echo -e "[ ${STATUS_MISS} ]"
        fi

        # move new /zorin_appearance/

        printf '%-46s %-5s' "    |--- install /appearance" ""
        sleep 1

        if [ -d "$dir/libraries/zorin_appearance" ]
        then
            sudo cp -rf "$dir/libraries/zorin_appearance" "/usr/lib/python3/dist-packages/zorin_appearance" >> $LOGS_FILE 2>&1
            echo -e "[ ${STATUS_OK} ]"
        else
            echo -e "[ ${STATUS_FAIL} ]"
        fi

        printf '%-46s %-5s' "    |--- install /appearance-4.1.egg" ""
        sleep 1

        # move new /zorin_appearance-4.1.egg-info/
        if [ -d "$dir/libraries/zorin_appearance-4.1.egg-info" ]
        then
            sudo cp -rf "$dir/libraries/zorin_appearance-4.1.egg-info" "/usr/lib/python3/dist-packages/zorin_appearance-4.1.egg-info" >> $LOGS_FILE 2>&1
            echo -e "[ ${STATUS_OK} ]"
        else
            echo -e "[ ${STATUS_FAIL} ]"
        fi
    else

        echo -e "[ ${STATUS_OK} ]"

    fi

    finish
}

##--------------------------------------------------------------------------
#   register apps to show in list
##--------------------------------------------------------------------------

if [ "$bInstall_all" = true ] ; then
    apps+=("${app_all}")
fi

if [ "$bInstall_app_alien" = true ] ; then
    apps+=("${app_alien}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_appimage" = true ] ; then
    apps+=("${app_appimage}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_blender_flatpak" = true ] ; then
    apps+=("${app_blender_flatpak}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_blender_snapd" = true ] ; then
    apps+=("${app_blender_snapd}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_colorpicker_snapd" = true ] ; then
    apps+=("${app_colorpicker_snapd}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_cdialog" = true ] ; then
    apps+=("${app_cdialog}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_conky" = true ] ; then
    apps+=("${app_conky}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_curl" = true ] ; then
    apps+=("${app_curl}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_flatpak" = true ] ; then
    apps+=("${app_flatpak}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_gdebi" = true ] ; then
    apps+=("${app_gdebi}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_git" = true ] ; then
    apps+=("${app_git}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_gnome_ext_arcmenu" = true ] ; then
    apps+=("${app_gnome_ext_arcmenu}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_gnome_ext_core" = true ] ; then
    apps+=("${app_gnome_ext_core}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_gnome_ext_ism" = true ] ; then
    apps+=("${app_gnome_ext_ism}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_gpick" = true ] ; then
    apps+=("${app_gpick}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_members" = true ] ; then
    apps+=("${app_members}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_mlocate" = true ] ; then
    apps+=("${app_mlocate}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_neofetch" = true ] ; then
    apps+=("${app_neofetch}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_nettools" = true ] ; then
    apps+=("${app_nettools}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_ocsurl" = true ] ; then
    apps+=("${app_ocsurl}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_pacman" = true ] ; then
    apps+=("${app_pacman}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_pihole" = true ] ; then
    apps+=("${app_pihole}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_reprepro" = true ] ; then
    apps+=("${app_reprepro}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_rpm" = true ] ; then
    apps+=("${app_rpm}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_seahorse" = true ] ; then
    apps+=("${app_seahorse}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_snapd" = true ] ; then
    apps+=("${app_snapd}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_swizzin" = true ] ; then
    apps+=("${app_swizzin}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_sysload" = true ] ; then
    apps+=("${app_sysload}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_teamviewer" = true ] ; then
    apps+=("${app_teamviewer}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_tree" = true ] ; then
    apps+=("${app_tree}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_twk_filepath" = true ] ; then
    apps+=("${twk_filepath}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_twk_netplan" = true ] ; then
    apps+=("${twk_netplan}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_twk_network_hosts" = true ] ; then
    apps+=("${twk_network_hosts}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_twk_vbox_additions_fix" = true ] ; then
    apps+=("${twk_vbox_additions_fix}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_unrar" = true ] ; then
    apps+=("${app_unrar}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_vsc_stable" = true ] ; then
    apps+=("${app_vsc_stable}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_vsc_insiders" = true ] ; then
    apps+=("${app_vsc_insiders}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_wxhexeditor" = true ] ; then
    apps+=("${app_wxhexeditor}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_yad" = true ] ; then
    apps+=("${app_yad}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_zenity" = true ] ; then
    apps+=("${app_zenity}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_ziet_cron" = true ] ; then
    apps+=("${app_ziet_cron}")
    let i_apps=i_apps+1
fi

if [ "$bInstall_app_zorinospro_lo" = true ] ; then
    apps+=("${app_zorinospro_lo}")
    let i_apps=i_apps+1
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
    sleep 0.5

    for i in "${arr_install[@]}"
    do
        printf '%-46s %-5s' "    |--- ${i}" ""
        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
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
    echo -e " ${GREEN}${BOLD} ${gui_title} - v$(get_version)${NORMAL}${MAGENTA}"
    echo
    echo -e "  This wizard will install some of the basic every-day software that will"
    echo -e "  be needed for this server to operate. It will also apply some OS mods"
    echo -e "  for a better overall experience."
    echo
    echo -e "  Some of these programs and libraries may take up to 10 minutes to"
    echo -e "  install, please do not force close the installer."
    echo
    printf '%-30s %-40s\n' "  ${BOLD}${DEVGREY}PID ${NORMAL}" "${BOLD}${FUCHSIA} $$ ${NORMAL}"
    printf '%-30s %-40s\n' "  ${BOLD}${DEVGREY}USER ${NORMAL}" "${BOLD}${FUCHSIA} ${USER} ${NORMAL}"
    printf '%-30s %-40s\n' "  ${BOLD}${DEVGREY}APPS ${NORMAL}" "${BOLD}${FUCHSIA} ${i_apps} ${NORMAL}"
    printf '%-30s %-40s\n' "  ${BOLD}${DEVGREY}DEV ${NORMAL}" "${BOLD}${FUCHSIA} ${dev_str} ${NORMAL}"
    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo

    sleep 0.3

    printf "%-30s %-5s\n" "${TIME}      Successfully loaded ${i_apps} apps" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-30s %-5s\n" "${TIME}      Waiting for user input ..." | tee -a "${LOGS_FILE}" >/dev/null

    echo -e "  ${BOLD}${NORMAL}Waiting on selection ..." >&2
    echo
}

##--------------------------------------------------------------------------
#   Selection Menu
#
#   allow users to select the desired option manually.
#   this may not be fully integrated yet.
##--------------------------------------------------------------------------

function show_menu()
{

    if ! [ -x "$(command -v zenity)" ]; then

        printf "%-30s %-5s\n" "${TIME}      Warning: Zenity package missing. Attempting to install." | tee -a "${LOGS_FILE}" >/dev/null

        echo
        echo -e "  ${BOLD}${FUCHSIA} Setting up for the first time ...${NORMAL}" >&2
        echo

        #   param   str     | App Name
        #   param   str     | function name
        #   param   bool    | bSilent
        fn_app_zenity ${app_zenity} nil true

        if [ -x "$(command -v zenity)" ]; then
            printf "%-30s %-5s\n" "${TIME}      Install successful. Package now available to use." | tee -a "${LOGS_FILE}" >/dev/null
        fi

        sleep 0.5
    fi

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

    if [ "$bDev" = true ] ; then
        app_list=("${devs[@]}")
    fi

    ##--------------------------------------------------------------------------
    #   sort array
    ##--------------------------------------------------------------------------

    IFS=$'\n' apps_sorted=($(sort <<<"${app_list[*]}"))
    unset IFS

    while true; do
        dev=$(zenity --list \
        --width="${gui_width}" \
        --height="${gui_height}" \
        --title="${gui_title} - v$(get_version)" \
        --text="${gui_desc}" \
        --extra-button Github \
        --ok-label "Install" \
        --cancel-label "Leave" \
        --column="${gui_column}" ${app_all} "${apps_sorted[@]}")

        RET=$?

        ##--------------------------------------------------------------------------
        #   button > github
        ##--------------------------------------------------------------------------

        if [ "${dev}" == "Github" ]; then
            firefox "${gui_uri_github}" || xdg-open "${gui_uri_github}" &
            zenity --notification --text='Website will open in browser'

            printf "%-30s %-5s\n" "${TIME}      User Input: OnClick ......... Github (Button)" | tee -a "${LOGS_FILE}" >/dev/null
            continue
        fi

        ##--------------------------------------------------------------------------
        #   kill menu from exit / leave button
        ##--------------------------------------------------------------------------

        if [ $RET -eq 1 ]; then
            Logs_Finish
            exit
            sleep 0.2
            break
        fi

        ##--------------------------------------------------------------------------
        #   options
        ##--------------------------------------------------------------------------

        case "$dev" in
            "${dev[0]}")
                printf "%-30s %-15s\n" "${TIME}      User Input: OnClick ......... ${dev} (App)" | tee -a "${LOGS_FILE}" >/dev/null

                assoc_func="${get_functions[$dev]}"
                $assoc_func "${dev}" "${assoc_func}"

                if [ "$bDev" = true ] ; then
                    arr_len=${#app_list[@]}
                    printf "%-42s %-15s" "    |--- ${BOLD}${DEVGREY} Spin PID ${NORMAL}" "${BOLD}${DEV} ${pid_spin} ${NORMAL}"
                    printf "\n%-42s %-15s" "    |--- ${BOLD}${DEVGREY} Func ${NORMAL}" "${BOLD}${DEV} ${assoc_func} ${NORMAL}"
                    printf "\n%-42s %-15s" "    |--- ${BOLD}${DEVGREY} Siblings PID ${NORMAL}" "${BOLD}${DEV} ${arr_len} ${NORMAL}"

                    echo
                fi;;
            *) echo "Ooops! Invalid option.";;
        esac
    done
}

show_menu get_functions