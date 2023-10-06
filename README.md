<p align="center"><img src="docs/images/readme/banner.jpg" width="860"></p>
<h1 align="center"><b>ZorinOS App Manager (yad)</b></h1>

<br />
<br />

> [!WARNING]
> This script has been specifically developed for ZorinOS v16.x [based on 20.04.6 LTS (Focal Fossa)]. There is absolutely no guarantee that this will work on other distros. There's a good likelihood that most features will work, but use at your own risk.

<br />
<br />

## Yad
This is an unreleased future version of Zorin App Manager which utilizes `yad` for its dialog library instead of zenity due to the limitations that zenity has.

<br />
<br />

## About
This is a simple application manager which allows you to install a number of programs right from the menu with little interaction. The packages and libraries provided are from personal choice, since these are the things I like to have when I get a new server going. The latest version includes a GUI which allows you to select the programs you wish to install.

<p align="center"><img style="width: 100%;text-align: center;" src="docs/images/readme/272117231.gif"></p>

<br />

---

<br />

## Packages Included
- Alien Package Converter
- AppImage Launcher
- Blender (using Flatpak)
- Blender (using Snap)
- cdialog (Comeon Dialog)
- Color Picker (using Snapd)
- Conky Manager
- curl
- Flatpak
- GDebi .deb Package Manager
- Git
- Gnome Extension Manager (Core) [^2]
- Gnome Extension: ArcMenu [^1]
- Gnome Extension: Internet Speed Monitor [^1]
- gPick (Color Picker)
- Kooha (Screen Recorder)
- members
- mlocate
- neofetch
- net-tools
- NPM
- ocs-url
- Pacman Package Management
- Pihole [^3]
- reprepro (Apt on Github)
- RPM Package Manager
- Seahorse + seahorse-nautilus
- Snapd
- Surfshark
- Swizzin
- System Monitor
- Teamviewer
- Tree
- Unrar
- Visual Studio Code (Stable)
- Visual Studio Code (Insiders)
- wxHexEditor
- YAD (Yet Another Dialog)
- Yarn
- Zenity Dialogs
- Ziet Cron Manager
- ZorinOS Pro: Layouts

<br />

## Tweaks / Changes
- File Manager displays full path in address bar
- Netplan Configuration
  - Default network adapter renamed to `eth0`
  - Automatically assigns static ip address
  - Configures network adapter to use Quad9 DNS servers
- Update Network /etc/hosts file
- VBox Additions package disrepency issue with non-Pro releases.
- ZorinOS Pro Layouts

<br />

---

<br />

## Usage
Information related to using this ation wizard.

<br />

### Configuration
This script contains many features that may have settings that you might not want. It is HIGHLY recommended that you open the `setup.sh` file in a text editor and review the settings. One particular feature is the `Netplan Configuration` which has default settings that include what static ip address to assign to the network adapter, as well as the default gateway, and Quad9 DNS servers.

<br />

### Install
To use this script, do the following:
```shell
wget "https://github.com/Aetherinox/zorinos-app-manager/main/setup.sh"
```

Once you download the script to a location on your machine, set its permissions to be `executable`
```shell
sudo chmod +x setup.sh
```

Finally, run the script
```shell
./setup.sh
```

Because certain features require `sudo`, you will be asked to enter your sudo password to give the proper permissions.

<br />
<br />

### Prerequisites
If you make a selection that requires a prerequisite package, that package will be automatically installed first, and then your selected item.

<br />
<br />

### Logs
When this installer is launched, a `/logs/zorin_[DATE].log` file will be generated in the same location as the setup script. Most apps will be installed silently / unattended. If you wish to check the status of a task, view the `zorin_[DATE].log` file. 

> [!NOTE]
> If you create an Issue / Bug report on Github, you will be asked to copy/paste your logs. Ensure you do this so that your issue can be reviewed in full and not delayed.

<br />

---

<br />

## ZorinOS Pro Features
Even though this release includes ZorinOS Pro layouts, there are still reasons to purchase ZorinOS Pro which include:
- Zorin Installation Support
- Support developers of ZorinOS

<br />

---

<br />

## Packages
Some of the packages in this wizard include what ZorinOS Pro comes with. If you are a ZorinOS Lite or Core user, some of the packages here will give you the features that a ZorinOS Pro user would have including:
- [ArcMenu Extension](#arcmenu)
- [Conky Manager](#conky-manager)
- [Internet Speed Monitor](#internet-speed-monitor)
- [System Load Indicator (Multiload)](#system-load-indicator-multiload)

<br />

### ArcMenu
ZorinOS Pro includes numerous shell themes which will simulate Windows 10 / 11 & MacOS. While ZorinOS Pro has a specialized extension, this is where another extension comes into play.
`ArcMenu` is an extension which provides interface changes featured in ZorinOS Pro and includes skins such as Windows 10 & 11, MacOS, and a multitude of others. The ArcMenu extension actually includes more skins and features than what ZorinOS Pro includes.

<p align="center"><img style="width: 75%;text-align: center;" src="docs/images/readme/271899251.png"></p>

You may use the `setup.sh` script in this repo to install ArcMenu. However, if you've like to manually install it; it requires a few steps.

<br />

### Conky Manager
`Conky Manager` is what displays a widget on your desktop which shows various statistics about your machine. This package comes with ZorinOS Pro, however, non-Pro users can also install it.

<p align="center"><img style="width: 100%;text-align: center;" src="docs/images/readme/271900503.gif"></p>

<p align="center"><img style="width: 65%;text-align: center;" src="docs/images/readme/2c624f4da.gif"></p>


The package can be manually installed with
```shell
sudo add-apt-repository --yes ppa:teejee2008/foss
sudo apt-get update
    
sudo apt-get install conky-all
sudo apt-get install conky-manager2
```

After installing Conky, click the ZorinOS start button and find `Startup Applications`. Select `Add` and enter the following:

<p align="center"><img style="width: 45%;text-align: center;" src="docs/images/readme/271899510.png"></p>

Once you've done the above steps, `reboot` the system. You should sign back into ZorinOS with a widget on your desktop.

If you want to move where the widget displays on your desktop, open `Terminal` and execute
```shell
sudo nano /etc/conky/conky.conf
```

In the config file, change `conky.config.alignment`

```bash
conky.config = {
    alignment = 'top_right',
...
```

You can edit the other properties in the config, for mine, I've decreased the font size as well
```bash
font = 'DejaVu Sans Mono:size=9
```

<br />

### Internet Speed Monitor
`Internet Speed Monitor` is a Gnome extension to show internet upload speed, download speed and daily data usage in a minimal fashion. 

After running the setup scripts in this repo, you can access this extension by clicking the `start menu` and searching for `Extension Manager`. 

<p align="center"><img style="width: 100%;text-align: center;" src="docs/images/readme/271907326.gif"></p>

The extension will rest within your ZorinOS taskbar.

<p align="center"><img style="width: 75%;text-align: center;" src="docs/images/readme/271906959.gif"></p>

Overall, the extension is very basic and includes minimal settings.

<p align="center"><img style="width: 75%;text-align: center;" src="docs/images/readme/271907511.png"></p>

<br />

### System Load Indicator (Multiload)
`System Load Indicator` is a system load monitor capable of displaying graphs for CPU, ram, harddisk, and swap space use, plus network traffic. The widget will sit within your ZorinOS taskbar, and also includes many customization options.

<p align="center"><img style="width: 100%;text-align: center;" src="docs/images/readme/271901792.gif"></p>

To access the customizations, right click on the graph in the taskbar and select `Preferences`

<p align="center"><img style="width: 100%;text-align: center;" src="docs/images/readme/271902501.gif"></p>

You can then modify the preferences to fit your needs.

<p align="center"><img style="width: 55%;text-align: center;" src="docs/images/readme/271902528.png"></p>

> [!WARNING]
> Ensure you don't set the `System Monitor Update Interval` too low, otherwise your system may experience performance issues. Under normal conditions, I set this to `3000 - 5000` which means the stats will update every 3-5 seconds.

<br />

---

<br />

## Swizzin
The official Swizzin repo does not support ZorinOS. Attempting to install the stock Swizzin program will result in an **unsupported OSA** error. This app manager includes a modified setup installation script which allows for ZorinOS to be installed without issues.

<br />

---

<br />

## Notes
Things to remember about this program

<br />

### Developer Vars
This program has numerous variables that the general public shouldn't modify. They make development easier instead of keeping multiple modified copies of the code.

| Var | Default | Desc |
| --- | --- | --- |
| `app_cfg_bDev` | false | <br /> `True`: Specialized list of apps will appear instead of the installable list.<br />Also displays debugging prints. <br /> <br /> |
| `app_cfg_bDev_NullRun` | false | <br /> `True`: Any of the installable applications selected will do a "fake" install. No actual install will take place. <br /> <br /> Requires `app_cfg_bDev = false` <br /> <br />  |

<br />

---

<br />
<br />
<br />
<br />

## Footnotes
[^1]: This program requires Gnome Extension Manager to be installed first.
[^2]: If installing any of the Gnome extensions, this core must be installed first. Please note that when installing this app, it may take upwards of 5-10 minutes depending on your machine. The rotating cursor means that it is installing.
