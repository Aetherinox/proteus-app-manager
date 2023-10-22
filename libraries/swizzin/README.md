<p align="center"><img src="https://raw.githubusercontent.com/Aetherinox/proteus-app-manager/main/docs/images/readme/libraries/swizzin/banner_panel.png" width="860"></p>
<h1 align="center"><b>What is Swizzin?</b></h1>

<br />

<div align="center">

[![View](https://img.shields.io/badge/%20-%20View%20Official%20Swizzin%20Repo%20-%20%23de2343?style=for-the-badge&logo=firefox&logoColor=FFFFFF)](https://github.com/swizzin/swizzin)

</div>

<br />
<br />

Swizzin is a light, modular seedbox solution that can be installed on Debian 10/11/12 or Ubuntu 20.04/22.04. The QuickBox package repo has been ported over for your installing pleasure, including the panel -- if you so choose!

Box has been revamped to reduce and consolidate the amount of commands you need to remember to manage your seedbox. More on this below. In addition to that, additional add-on packages can be installed during installation. No need to wait until the installer finishes! Now with unattended installs!

Swizzin includes the following apps bundled with the script:

| Category | Apps |
| --- | --- |
| <center>`Automation`</center> | Autobrr, Autodl, Bazarr, Lidarr, Medusa, Mylar3, Ombi, Sickchill, Sickgear, Sonarr, Radarr, Prowlarr |
| <center>`Backup & Sync`</center> | Resilio, Nextcloud, Rclone, Syncthing, vsftpd |
| <center>`Indexers`</center> | Jackett, NZBHydra2 |
| <center>`IRC`</center> | Lounge, Quassel, ZNC |
| <center>`Media Servers`</center> | Airsonic, Calibre-Web, Emby, Jellyfin, Mango, Navidrome, Plex, Tautulli |
| <center>`Torrents`</center> | Deluge, Flood, qBittorrent, rTorrent, ruTorrent, Transmission |
| <center>`Usenet`</center> | NZBGet, SABnzbd, NZBHydra |
| <center>`Utilities`</center> | ffmpeg, jfago, Librespeed, Netdata, Pyload, Quota, Rapidleech, Wireguard, X2go, xmrig |
| <center>`Web`</center> | DuckDNS, Filebrowser, Letsencrypt, Nginx, Organizr, Panel, Shellinabox, Webmin |

<br />

---

<br />

# What Is This Folder?
This folder contains a modified `setup.sh` Swizzin installation file. This is for users who wish to install Swizzin separate from using the Proteus App Manager.

To execute the install script
```bash
sudo bash libraries/swizzin/setup.sh --local
```

<br />

---

<br />

# Proteus App Manager
If you decide to use the Proteus App Manager, it will automatically download the latest version of the Swizzin install script directly from their official website to ensure all the files are the latest. It will then make the required edits automatically before initializing the Swizzin installation wizard. There's no need on your part to edit anything.