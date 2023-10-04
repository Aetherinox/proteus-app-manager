# This file is part of the Zorin Appearance program.
#
# Copyright 2016-2019 Zorin OS Technologies Ltd.
# Based on code from gnome-tweak-tool by John Stowers, Copyright 2011.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.

import os.path
import logging

from gi.repository import Gio, GLib

from zorin_appearance.gsettings import GSettingsSetting


class _ShellProxy:
    def __init__(self):
        d = Gio.bus_get_sync(Gio.BusType.SESSION, None)

        self.proxy = Gio.DBusProxy.new_sync(
                            d, 0, None,
                            'org.gnome.Shell',
                            '/org/gnome/Shell',
                            'org.gnome.Shell',
                            None)

        # GNOME Shell > 3.5 added a separate extension interface
        self.proxy_extensions = Gio.DBusProxy.new_sync(
                            d, 0, None,
                            'org.gnome.Shell',
                            '/org/gnome/Shell',
                            'org.gnome.Shell.Extensions',
                            None)

        val = self.proxy.get_cached_property("Mode")
        self._mode = val.unpack()

        val = self.proxy.get_cached_property("ShellVersion")
        self._version = val.unpack()

    @property
    def mode(self):
        return self._mode

    @property
    def version(self):
        return self._version


class GnomeShell:

    EXTENSION_STATE = {
        "ENABLED"       :   1,
        "DISABLED"      :   2,
        "ERROR"         :   3,
        "OUT_OF_DATE"   :   4,
        "DOWNLOADING"   :   5,
        "INITIALIZED"   :   6,
    }

    EXTENSION_TYPE = {
        "SYSTEM"        :   1,
        "PER_USER"      :   2
    }

    DATA_DIR = os.path.join(GLib.get_user_data_dir(), "gnome-shell")
    EXTENSION_DIR = os.path.join(GLib.get_user_data_dir(), "gnome-shell", "extensions")

    EXTENSION_ENABLED_KEY = "enabled-extensions"
    EXTENSION_DISABLED_KEY = "disabled-extensions"
    SUPPORTS_EXTENSION_PREFS = True

    def __init__(self, shellproxy, shellsettings):
        self._proxy = shellproxy
        self._settings = shellsettings

    def extension_is_active(self, state, uuid):
        return state == GnomeShell.EXTENSION_STATE["ENABLED"] and \
                self._settings.setting_is_in_list(self.EXTENSION_ENABLED_KEY, uuid)

    def enable_extension(self, uuid):
        self._settings.setting_add_to_list(self.EXTENSION_ENABLED_KEY, uuid)
        self._settings.setting_remove_from_list(self.EXTENSION_DISABLED_KEY, uuid)

    def disable_extension(self, uuid):
        self._settings.setting_remove_from_list(self.EXTENSION_ENABLED_KEY, uuid)
        self._settings.setting_add_to_list(self.EXTENSION_DISABLED_KEY, uuid)

    def list_extensions(self):
        return self._proxy.proxy_extensions.ListExtensions()

    def uninstall_extension(self, uuid):
        return self._proxy.proxy_extensions.UninstallExtension('(s)', uuid)

    def install_remote_extension(self, uuid, reply_handler, error_handler, user_data):
        self._proxy.proxy_extensions.InstallRemoteExtension('(s)', uuid,
            result_handler=reply_handler, error_handler=error_handler, user_data=user_data)

    @property
    def mode(self):
        return self._proxy.mode

    @property
    def version(self):
        return self._proxy.version

class GnomeShellFactory:
    def __init__(self):
        try:
            proxy = _ShellProxy()
            settings = GSettingsSetting("org.gnome.shell")
            v = list(map(int, proxy.version.split(".")))

            if v >= [3, 5, 0]:
                self.shell = GnomeShell(proxy, settings)
            else:
                logging.warn("Shell version not supported")
                self.shell = None

            logging.debug("Shell version: %s", str(v))
        except:
            self.shell = None
            logging.warn("Shell not installed or running")

    def get_shell(self):
        return self.shell
