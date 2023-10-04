# This file is part of the Zorin Appearance program.
#
# Copyright 2016-2019 Zorin OS Technologies Ltd.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.

import gi
import os
import subprocess
import logging

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gio, GLib


APP_DATA_PATH = '/usr/share/zorin-appearance/'


class XSettingsOverrides:

    VARIANT_TYPES = {'Gtk/ShellShowsAppMenu': GLib.Variant.new_int32,
                     'Gtk/EnablePrimaryPaste': GLib.Variant.new_int32,
                     'Gdk/WindowScalingFactor': GLib.Variant.new_int32}

    def __init__(self):
        self._settings = Gio.Settings(schema='org.gnome.settings-daemon.plugins.xsettings')
        self._variant = self._settings.get_value('overrides')

    def _dup_variant_as_dict(self):
        items = {}
        for k in list(self._variant.keys()):
            try:

                # variant override doesnt support .items()

                v = self._variant[k]
                items[k] = self.VARIANT_TYPES[k](v)
            except KeyError:
                pass
        return items

    def _dup_variant(self):
        return GLib.Variant('a{sv}', self._dup_variant_as_dict())

    def _set_override(self, name, v):
        items = self._dup_variant_as_dict()
        items[name] = self.VARIANT_TYPES[name](v)
        n = GLib.Variant('a{sv}', items)
        self._settings.set_value('overrides', n)
        self._variant = self._settings.get_value('overrides')

    def _get_override(self, name, default):
        try:
            return self._variant[name]
        except KeyError:
            return default

    # while I could store meta type information in the VARIANT_TYPES
    # dict, its easiest to do default value handling and missing value
    # checks in dedicated functions

    def set_shell_shows_app_menu(self, v):
        self._set_override('Gtk/ShellShowsAppMenu', int(v))

    def get_shell_shows_app_menu(self):
        return self._get_override('Gtk/ShellShowsAppMenu', True)

    def set_enable_primary_paste(self, v):
        self._set_override('Gtk/EnablePrimaryPaste', int(v))

    def get_enable_primary_paste(self):
        return self._get_override('Gtk/EnablePrimaryPaste', True)

    def set_window_scaling_factor(self, v):
        self._set_override('Gdk/WindowScalingFactor', int(v))

    def get_window_scaling_factor(self):
        return self._get_override('Gdk/WindowScalingFactor', 1)


def walk_directories(dirs, filter_func):
    valid = []
    try:
        for thdir in dirs:
            if os.path.isdir(thdir):
                for t in os.listdir(thdir):
                    if filter_func(os.path.join(thdir, t)):
                        valid.append(t)
    except:
        logging.critical('Error parsing directories', exc_info=True)
    return valid


def execute_subprocess(cmd_then_args, block=True):
    p = subprocess.Popen(
            cmd_then_args,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, close_fds=True,
            universal_newlines=True)
    if block:
        stdout, stderr = p.communicate()
        return stdout, stderr, p.returncode


def strtobool (val):
    val = val.lower()
    if val in ('y', 'yes', 't', 'true', 'on', '1'):
        return 1
    elif val in ('n', 'no', 'f', 'false', 'off', '0'):
        return 0
    else:
        raise ValueError("invalid truth value %r" % (val,))
