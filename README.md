<p align="center"><img src="docs/images/readme/banner_02.png" width="860"></p>
<h1 align="center"><b>Proteus App Manager</b></h1>

<div align="center">

![Version](https://img.shields.io/github/v/tag/Aetherinox/proteus-app-manager?logo=GitHub&label=version&color=ba5225) ![Release Date](https://img.shields.io/github/release-date-pre/Aetherinox/proteus-app-manager?color=eb1a58) ![Downloads](https://img.shields.io/github/downloads/Aetherinox/proteus-app-manager/total) ![Repo Size](https://img.shields.io/github/repo-size/Aetherinox/proteus-app-manager?label=size&color=59702a) ![Last Commit)](https://img.shields.io/github/last-commit/Aetherinox/proteus-app-manager?color=b43bcc) [![View Apt Repo](https://img.shields.io/badge/Repo%20-%20Here%20-%20%23f00e7f?logo=Proteus&logoColor=FFFFFF&label=Download)](https://github.com/Aetherinox/proteus-app-manager/releases/)

</div>

---

<br />

- [About](#about)
- [Packages](#packages)
- [Patches](#patches)
- [Usage](#usage)
  - [Install](#install)
  - [Configuration](#configuration)
  - [Prerequisites](#prerequisites)
  - [Logs](#logs)
- [Command-line Arguments](#command-line-arguments)
  - [Main](#main)
  - [Sub Options](#sub-options)
  - [Installing with CLI](#installing-with-cli)
- [Wiki](#wiki)
- [Footnotes](#footnotes)

<br />

---

<br />

## About
This is an application manager targeted toward `ZorinOS`, `Ubuntu 20.04 LTS`+. The Proteus App Manager allows users to install a number of apps, packages, and libraries right from the menu with little interaction. 

This manager features a selection menu which allows you to choose which programs you wish to install onto your device. Any programs that have dependencies will be taken care of automatically with no input from you unless the program requires you to configure it.

<br />

<p align="center"><img style="width: 100%;text-align: center;" src="docs/images/readme/272117231.gif"></p>

<br />

<p align="center"><img style="width: 100%;text-align: center;" src="docs/images/readme/272117234.gif"></p>

<br />

<p align="center"><img style="width: 100%;text-align: center;" src="docs/images/readme/272117233.gif"></p>

<br />

<p align="center"><img style="width: 100%;text-align: center;" src="docs/images/readme/271963150.png"></p>

<br />

<p align="center"><img style="width: 100%;text-align: center;" src="docs/images/readme/272117232.gif"></p>

<br />

---

<br />

## Packages
| App                                                                                         | Descript |
| ------------------------------------------------------------------------------------------- | -------- |
| [Alien Package Converter](http://joeyh.name/code/alien/)                              | Converts between the rpm, dpkg, stampede slp, and slackware tgz file formats |
| [AppImage Launcher](https://github.com/TheAssassin/AppImageLauncher)                  | Manage `.appimage` files in one place         |
| [App Outlet Manager](https://github.com/AppOutlet/AppOutlet)                          | Search / download applications that runs on most Linux distributions         |
| [Blender (Flatpak)](https://flathub.org/apps/org.blender.Blender)                     | Free / Open-source 3D creation suite          |
| [Blender (Snap)](https://snapcraft.io/blender)                                        | Free / Open-source 3D creation suite          |
| [Browser: Google Chrome](https://www.google.com/chrome/?platform=linux)               | Browser by Google          |
| [Browser: Tor](https://community.torproject.org/relay/setup/bridge/debian-ubuntu/)    | Browser built around privacy          |
| [cdialog (Comeon Dialog)](https://launchpad.net/~eugenesan/+archive/ubuntu/ppa)       | Create bash shell dialogs                     |
| [Color Picker (Snapd)](https://snapcraft.io/color-picker)                             | Advanced color-picker                         |
| [Conky](https://github.com/brndnmtthws/conky)                                         | System monitor software                       |
| [Conky Manager](https://github.com/zcot/conky-manager2)                               | GUI for managing Conky widgets / themes       |
| [curl](https://packages.ubuntu.com/search?keywords=curl)                              | Command line tool for transferring data with URL syntax |
| [deb-get](https://github.com/wimpysworld/deb-get)                                     | apt-get functionality for .deb packages |
| [Debian Goodies](https://packages.ubuntu.com/search?keywords=debian-goodies)          | Manage packages from the command line |
| [Flatpak](https://flatpak.org/)                                                       | Utility for software deployment and package management |
| [GDebi .deb Package Manager](https://pkgs.org/download/gdebi)                         | Program for installing debian executable files |
| [Git](https://git-scm.com/download/linux)                                             | Version control system (Command-line)         |
| [Github Desktop](https://github.com/Aetherinox/proteus-apt-repo/tree/master/incoming)   | Github Desktop for linux.                     |
| [Gnome Extension Manager (Core)](https://flathub.org/apps/com.mattjakeman.ExtensionManager) [^2] | Utility for browsing / installing GNOME Shell Extensions.         |
| [Gnome Extension: ArcMenu](https://extensions.gnome.org/extension/3628/arcmenu/) [^1]      | Replacement shell for Linux. Includes MacOS / Windows themes.  |
| [Gnome Extension: Internet Speed Monitor](https://github.com/rishuinfinity/InternetSpeedMonitor) [^1]  | Monitor network traffic as widget |
| [gPick (Color Picker)](https://github.com/thezbyg/gpick)                              | Color picker |
| [Kooha](https://github.com/SeaDve/Kooha)                                              | Screen recorder |
| [lintian](https://wiki.debian.org/Teams/Lintian)                                      | Package checker for creating Debian packages  |
| [Makedeb](https://github.com/makedeb/makedeb)                                         | A simplicity-focused packaging tool for Debian archives |
| [members](https://packages.ubuntu.com/search?keywords=members)                        | Tool for displaying the users of a group |
| [mlocate](https://github.com/msekletar/mlocate)                                       | Find files on your computer  |
| [MySQL](https://packages.ubuntu.com/search?keywords=mysql-server)                     | MySQL Database |
| [neofetch](https://github.com/dylanaraps/neofetch)                                    | Command-line system information tool  |
| [net-tools](https://packages.ubuntu.com/search?keywords=net-tools)                    | Network management toolkit |
| [Nginx](https://packages.ubuntu.com/search?keywords=nginx)                            | Webserver alternative to Apache |
| [NodeJS](https://nodejs.org/en/download/package-manager)                              | Build scalable network apps  |
| [NPM](https://npmjs.com/)                                                             | Package installer |
| [ocs-url](https://opendesktop.org/p/1136805/)                                         | Helper program for items served via ocs:// |
| [Pacman Package Management](https://gitlab.com/trivoxel/utilities/deb-pacman)         | Emulates the Archlinux Pacman package manager for Debian users who may prefer Pacman over Apt. |
| [Pihole](https://github.com/pi-hole/pi-hole/#one-step-automated-install)              | Ads and tracker blocking app which acts as a DNS sinkhole |
| [PHP](https://launchpad.net/~ondrej/+archive/ubuntu/php)                              | General-purpose scripting language geared towards web development |
| [PhpMyAdmin](https://packages.ubuntu.com/search?keywords=phpmyadmin)                  | Administration tool for MySQL and MariaDB |
| [reprepro (Apt on Github)](https://github.com/ionos-cloud/reprepro)                   | Debian package repository producer  |
| [RPM Package Manager](https://packages.ubuntu.com/focal/rpm)                          | RPM Package Manager |
| [Seahorse + seahorse-nautilus](https://github.com/GNOME/seahorse)                     | Manage encryption keys and passwords in GNOME Keyring |
| [Snapd](https://github.com/snapcore/snapd)                                            | Install and manage packages  |
| [Surfshark](https://surfshark.com/download/linux)                                     | VPN application |
| [Swizzin](https://github.com/swizzin/swizzin)                                         | Modular seedbox solution (torrents) 15+ apps bundled  |
| [System Monitor / Multiload Indicator](https://launchpad.net/indicator-multiload)     | Monitor CPU, Memory, Network stats in widget  |
| [Teamviewer](https://www.teamviewer.com/en-us/download/linux/)                        | Remote desktop application |
| [Tree](https://packages.ubuntu.com/search?keywords=tree)                              | View files in tree-like ASCII structure  |
| [Unrar](https://packages.ubuntu.com/search?keywords=unrar)                            | Manage rar files / extraction |
| [Visual Studio Code (Stable)](https://code.visualstudio.com/)                         | IDE for developers / source-code editor (Stable) |
| [Visual Studio Code (Insiders)](https://code.visualstudio.com/insiders/)              | IDE for developers / source-code editor (Testing) |
| [wxHexEditor)](https://github.com/EUA/wxHexEditor)                                    | Hex editor |
| [YAD (Yet Another Dialog)](https://github.com/v1cont/yad)                             | Create bash shell dialogs. Based on Zenity. |
| [Yarn](https://github.com/yarnpkg/berry)                                              | Modern package manager |
| [Zenity Dialogs](https://gitlab.gnome.org/GNOME/zenity)                               | Create bash shell dialogs |
| [Ziet Cron Manager](https://github.com/loimu/zeit)                                    | Manage crons in browser admin panel  |

<br />

## Patches
- File Manager displays full path in address bar
- Add "`Create New Text File`" to right-click context menu
  - Already installed in ZorinOS
  - Missing from Ubuntu, must be done manually
- Netplan Configuration
  - Default network adapter renamed to `eth0`
  - Automatically assigns static ip address
  - Configures network adapter to use Quad9 DNS servers
- Update Network /etc/hosts file
- VBox Additions package discrepancy issue with non-Pro releases.

<br />

---

<br />

## Usage
Information on getting started.

<br />

### Install
Instructions on how to run this script and what you shouldn't do.

<br />

> [!WARNING]
> Do NOT attempt to run this script as another user that you are not signed in as. If you are signed into your device as user `David`, don't `su` in terminal to another user and then attempt to run the script. Whatever user you're signed into the device with, is the user you should be running the script under.
>
> Do not `su root` and try to run the script. It will fail. You shouldn't be running things under root anyway.
> 
> You should also not need `sudo` to run the script. It will automatically ask you for sudo permission.

<br />

```shell
wget "https://raw.githubusercontent.com/Aetherinox/proteus-app-manager/main/proteus.sh"
```

Once you download the script to a location on your machine, set its permissions to be `executable`
```shell
sudo chmod +x proteus.sh
```

Finally, run the script
```shell
./proteus.sh
```

After the script is ran for the first time, you may need to sign out of your user account and sign back in. This is because a new file will be installed to `/home/USER/bin/proteus`. This file allows you to execute proteus from anywhere within terminal. In order for this to work, you must log out of the user and log back in after Proteus was started the first time. Then you'll be able to use it anywhere.

<br />

### Configuration
This script contains many features that may have settings that you might not want. It is HIGHLY recommended that you open the `proteus.sh` file in a text editor and review the settings. One particular feature is the `Netplan Configuration` which has default settings that include what static ip address to assign to the network adapter, as well as the default gateway, and Quad9 DNS servers.

<br />

### Prerequisites
If you make a selection that requires a prerequisite package, that package will be automatically installed first, and then your selected item.

<br />
<br />

### Logs
When this installer is launched, a `/logs/proteus-[DATE].log` file will be generated in the same location as the setup script. Most apps will be installed silently / unattended. If you wish to check the status of a task, view the `proteus-[DATE].log` file. 

> [!NOTE]
> If you create an Issue / Bug report on Github, you will be asked to copy/paste your logs. Ensure you do this so that your issue can be reviewed in full and not delayed.

<br />

---

<br />

## Command-line Arguments
The following options can be appended to the end of the `./proteus.sh` command

<br />


### Main
| Option | Name | Desc |
| --- | --- | --- |
| `-d`, `--dev` | Dev Mode | <br /> Specialized list of apps will appear instead of the installable list.<br />Also displays debugging prints. <br /> <br /> |
| `-h`, `--help` | Help | <br /> Display command help <br /> <br /> |
| `-i`, `--install` | Install | <br /> Installs one or multiple apps via command-line instead of launching the gui.<br /><br /> e.g.: `./proteus.sh -i curl -i "Github Desktop"`<br /> <br /> |
| `-n`, `--nullrun` | Dev: Null Run | <br /> Any of the installable applications selected will do a "fake" / null install. No actual install will take place. <br /> <br /> Only works without `-d` <br /> <br />  |
| `-q`, `--quiet` | Quiet | <br /> All logging will be disabled <br /> <br /> |
| `-s`, `--setup` | Setup | <br /> Install all Proteus prerequisites / dependencies <br /> <br /> |
| `-t`, `--theme [THEME]` | Theme | <br /> Switches the theme that the interface uses. <br /><br />`Adwaita`, `Adwaita-dark`, `HighContrast`, `HighContrastInverse`, `ZorinBlue-Light` [^3], `ZorinBlue-Dark` [^3] <br /> <br /> |
| `-v`, `--version` | Version | <br /> Version information <br /> <br />  |

<br />

### Sub Options
| Option | Desc | Options |
| --- | --- | --- |
| `--njs-ver` | <br /> Specifies the version of NodeJS to install. <br /> Required when using `-i NodeJS` <br /> <br /> | `16`, `18`, `20` |

<br />

### Installing with CLI

Proteus supports installing apps via the command-line instead of loading the GUI and selecting apps from the list. In order to install apps via command-line, the `-i` or `--install` option must be provided for each app you wish to install.

```bash
./proteus.sh -i curl -i "Github Desktop"
./proteus.sh --install tree -i Reprepro --install "ZorinOS Pro"
```

<br />

If you provide a very short generic name, Proeteus will find the first app based on alphabetical order.

<br />

As an example, if you do an install using `./proteus.sh -i "gi"` and Proteus doesn't have any packages specifically named `Gi`, then the app will assume you're referring to the package `Git` and ask if you wish to install that.

if you specify `./proteus.sh -i "gith"`, the system will assume `Github Desktop` _(unless there's another name that is closer to your query)_.

Upper and lower case characters do not matter.

<br />

---

<br />

## Wiki
For detailed documentation, please visit this repo's [Wiki](https://github.com/Aetherinox/proteus-app-manager/wiki)

<br />

---

<br />
<br />
<br />
<br />

## Footnotes
[^1]: This program requires Gnome Extension Manager to be installed first.
[^2]: If installing any of the Gnome extensions, this core must be installed first. Please note that when installing this app, it may take upwards of 5-10 minutes depending on your machine. The rotating cursor means that it is installing.
[^3]: Only available if using `ZorinOS`