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
import gettext

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

from zorin_appearance import listbox
from zorin_appearance import widgets
from zorin_appearance import environment

t = gettext.translation('zorin-appearance', '/usr/share/locale',
                        fallback=True)
_ = t.gettext

if environment._shell_loaded:
    INTERFACE_SCHEMA = 'org.gnome.desktop.interface'
    WM_SCHEMA = 'org.gnome.desktop.wm.preferences'
    APP_FONT = 'font-name'
    TITLEBAR_FONT = 'titlebar-font'
    DOCUMENT_FONT = 'document-font-name'
    MONOSPACE_FONT = 'monospace-font-name'
elif environment._desktop_environment == 'XFCE':
    INTERFACE_SCHEMA = 'xsettings'
    WM_SCHEMA = 'xfwm4'
    APP_FONT = '/Gtk/FontName'
    TITLEBAR_FONT = '/general/title_font'
    MONOSPACE_FONT = '/Gtk/MonospaceFontName'


class Fonts(Gtk.Frame):

    def __init__(self):
        Gtk.Frame.__init__(self)

        self.fonts_box = Gtk.ListBox()
        self.fonts_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self.fonts_box.set_header_func(listbox.list_box_update_header_func,
                None)

        self.fonts_box.add(widgets.FontButton(_('Interface Text'),
                           INTERFACE_SCHEMA, APP_FONT))
        if environment._shell_loaded:
            self.fonts_box.add(widgets.FontButton(_('Document Text'),
                               INTERFACE_SCHEMA, DOCUMENT_FONT))      
        self.fonts_box.add(widgets.FontButton(_('Monospace Text'),
                           INTERFACE_SCHEMA, MONOSPACE_FONT))
        self.fonts_box.add(widgets.FontButton(_('Legacy Window Titles'),
                           WM_SCHEMA, TITLEBAR_FONT))

        self.add(self.fonts_box)
