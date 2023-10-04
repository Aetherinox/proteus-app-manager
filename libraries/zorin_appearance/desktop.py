# This file is part of the Zorin Appearance program.
#
# Copyright 2016-2021 Zorin OS Technologies Ltd.
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

import gi
import gettext

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

from zorin_appearance import listbox
from zorin_appearance import widgets
from zorin_appearance import environment

t = gettext.translation('zorin-appearance', '/usr/share/locale', fallback=True)
_ = t.gettext

if environment._shell_loaded:
    installed_extensions = environment._shell.list_extensions()

    DESKTOP_ICONS_EXTENSION = 'zorin-desktop-icons@zorinos.com'

    ICONS_SCHEMA = 'org.gnome.shell.extensions.zorin-desktop-icons'
    SHOW_ICONS = 'show-desktop-icons'
    HOME_ICON_VISIBLE = 'show-home'
    TRASH_ICON_VISIBLE = 'show-trash'
    VOLUMES_VISIBLE = 'show-volumes'
    NETWORK_ICON_VISIBLE = 'show-network-volumes'
    ICON_SIZE = 'icon-size'
elif environment._desktop_environment == 'XFCE':
    ICONS_SCHEMA = 'xfce4-desktop'
    DESKTOP_SCHEMA = ICONS_SCHEMA
    SHOW_ICONS = '/desktop-icons/style'
    HOME_ICON_VISIBLE = '/desktop-icons/file-icons/show-home'
    TRASH_ICON_VISIBLE = '/desktop-icons/file-icons/show-trash'
    VOLUMES_VISIBLE = '/desktop-icons/file-icons/show-removable'
    FILESYSTEM_VISIBLE = '/desktop-icons/file-icons/show-filesystem'


class Icons(Gtk.Box):

    def __init__(self):
        Gtk.Box.__init__(
            self,
            orientation=Gtk.Orientation.VERTICAL,
            spacing=16,
            margin_start=16,
            margin_end=16,
            margin_left=16,
            margin_right=16,
            )
            
        self.selection_frame = Gtk.Frame()
        self.selection_box = Gtk.ListBox()
        self.selection_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self.selection_box.set_header_func(listbox.list_box_update_header_func,
                None)

        if environment._desktop_environment == 'XFCE':
            self.selection_box.add(widgets.Switch(_('Icons on Desktop'),
                                   DESKTOP_SCHEMA, SHOW_ICONS))
            self.selection_box.add(widgets.Check(_('Home'), ICONS_SCHEMA,
                                   HOME_ICON_VISIBLE, DESKTOP_SCHEMA,
                                   SHOW_ICONS))
            self.selection_box.add(widgets.Check(_('Trash'), ICONS_SCHEMA,
                                   TRASH_ICON_VISIBLE, DESKTOP_SCHEMA,
                                   SHOW_ICONS))
            self.selection_box.add(widgets.Check(_('Mounted Volumes'),
                                   ICONS_SCHEMA, VOLUMES_VISIBLE,
                                   DESKTOP_SCHEMA, SHOW_ICONS))
            self.selection_box.add(widgets.Check(_('Filesystem'),
                                   ICONS_SCHEMA, FILESYSTEM_VISIBLE,
                                   DESKTOP_SCHEMA, SHOW_ICONS))
        elif environment._shell_loaded and DESKTOP_ICONS_EXTENSION in installed_extensions:
            self.selection_box.add(widgets.SwitchExtension(_('Icons on Desktop'),
                                   [DESKTOP_ICONS_EXTENSION]))
            self.selection_box.add(widgets.ComboEnumExtension(_("Icon size"),
                                   ICONS_SCHEMA, ICON_SIZE,
                                   DESKTOP_ICONS_EXTENSION))
            self.selection_box.add(widgets.CheckExtension(_('Home'), ICONS_SCHEMA,
                                   HOME_ICON_VISIBLE, DESKTOP_ICONS_EXTENSION))
            self.selection_box.add(widgets.CheckExtension(_('Trash'), ICONS_SCHEMA,
                                   TRASH_ICON_VISIBLE, DESKTOP_ICONS_EXTENSION))
            self.selection_box.add(widgets.CheckExtension(_('Mounted Volumes'),
                                   ICONS_SCHEMA, VOLUMES_VISIBLE,
                                   DESKTOP_ICONS_EXTENSION))
            self.selection_box.add(widgets.CheckExtension(_('Network Servers'),
                                   ICONS_SCHEMA, NETWORK_ICON_VISIBLE,
                                   DESKTOP_ICONS_EXTENSION))

        self.selection_frame.add(self.selection_box)
        self.add(self.selection_frame)
