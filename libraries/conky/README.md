<p align="center"><img src="https://raw.githubusercontent.com/Aetherinox/proteus-app-manager/main/docs/images/readme/libraries/conky/conky_banner.png" width="860"></p>
<h1 align="center"><b>What is Conky + Manager?</b></h1>

<br />

<div align="center">

[![View](https://img.shields.io/badge/%20-%20View%20Original%20Conky%20Manager%20Repo%20-%20%23de2343?style=for-the-badge&logo=github&logoColor=FFFFFF)](https://github.com/teejee2008/conky-manager)

[![View](https://img.shields.io/badge/%20-%20View%20Forked%20Conky%20Manager%20Repo%20-%20%23de2343?style=for-the-badge&logo=github&logoColor=FFFFFF&color=1a67ed)](https://github.com/zcot/conky-manager2)

[![View](https://img.shields.io/badge/%20-%20View%20Conky%20Remake%20Repo%20-%20%23de2343?style=for-the-badge&logo=github&logoColor=FFFFFF&color=581c8c)](https://github.com/brndnmtthws/conky)

</div>

<br />
<br />

`Conky` is a system monitor software. It is free software released under the terms of the GPL license. Conky is able to monitor many system variables including CPU, memory, swap, disk space, temperature, top, upload, download, system messages, and much more. It is extremely configurable. Conky is a fork of torsmo. 

`Conky Manager` is a graphical front-end for managing Conky config files. It provides options to start/stop, browse and edit Conky themes installed on the system. Packages are currently available in Launchpad for Ubuntu and derivatives (Linux Mint, etc).

<br />

---

<br />

# What Is This Folder?
This folder contains numerous subfolders
- `Conky Base`
- `Conky Manager`

If you use to modify your desktop using config files and manual edits, then you only need `Conky Base`. However, if you wish to have a GUI front-end which allows you to manage your themes, you will need `Conky Base` + `Conky Manager`.

<br />

---

<br />

# Proteus App Manager
If you decide to use the Proteus App Manager, it will provide you with options to install `Conky Base` and `Conky Manager`. There will be no need to utilize any of the files in this folder.

<br />

---

<br />

# Note on Conky Remake Repo
In regards to the link at the top of this page related to the `Conky Remake Repo`, it is listed as a warning for people who may find that repo while searching for Conky. 

When running the `appimage` for that particular version, ZorinOS 16 users will receive the error

```bash
./conky-x86_64.AppImage: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.34' not found (required by /tmp/.mount_conky-aIz6xO/usr/bin/../lib/libpulse.so.0)
./conky-x86_64.AppImage: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.32' not found (required by /tmp/.mount_conky-aIz6xO/usr/bin/../lib/libpulse.so.0)
./conky-x86_64.AppImage: /lib/x86_64-linux-gnu/libc.so.6: version `GLIBC_2.33' not found (required by /tmp/.mount_conky-aIz6xO/usr/bin/../lib/libcurl-gnutls.so.4)

[Continued]...
```

This is due to ZorinOS 16 running Glibc `2.31`. The only safe solution is to wait until Zorin 17 releases. Glibc is a system-wide library, and attempting to build your own upgraded package can result in bricking your operating system.

Use the versions of Conky provided in the Proteus App Manager for now.