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
import os.path

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

from zorin_appearance import listbox
from zorin_appearance import widgets
from zorin_appearance import environment

t = gettext.translation('zorin-appearance', '/usr/share/locale', fallback=True)
_ = t.gettext

if environment._shell_loaded:
    installed_extensions = environment._shell.list_extensions()

    ZORIN_MENU_EXTENSION = 'zorin-menu@zorinos.com'
    ZORIN_TASKBAR_EXTENSION = 'zorin-taskbar@zorinos.com'
    ZORIN_DASH_EXTENSION = 'zorin-dash@zorinos.com'
    WINDOW_MOVE_EFFECT_EXTENSION = 'zorin-window-move-effect@zorinos.com'
    MAGIC_LAMP_EFFECT_EXTENSION = 'zorin-magic-lamp-effect@zorinos.com'
    
    MENU_SCHEMA = 'org.gnome.shell.extensions.zorin-menu'

    WM_SCHEMA = 'org.gnome.desktop.wm.preferences'
    BUTTON_LAYOUT = 'button-layout'
    BUTTONS_LEFT = 'close,minimize,maximize:appmenu'
    BUTTONS_RIGHT = 'appmenu:minimize,maximize,close'
elif environment._desktop_environment == 'XFCE':
    WM_SCHEMA = 'xfwm4'
    BUTTON_LAYOUT = '/general/button_layout'
    BUTTONS_LEFT = 'CHM|O'
    BUTTONS_RIGHT = 'O|HMC'


class Interface(Gtk.Box):

    def __init__(self):
        Gtk.Box.__init__(
            self,
            orientation=Gtk.Orientation.VERTICAL,
            spacing=16,
            margin_start=16,
            margin_end=16,
            margin_left=16,
            margin_right=16,
            margin_bottom=16
            )

        self.selection_frame = Gtk.Frame()
        self.selection_box = Gtk.ListBox()
        self.selection_box.set_selection_mode(Gtk.SelectionMode.NONE)
        self.selection_box.set_header_func(listbox.list_box_update_header_func,
                None)

        self.selection_box.add(widgets.LeftRightButton(_('Titlebar Buttons'),
                               WM_SCHEMA, BUTTON_LAYOUT,
                               BUTTONS_LEFT, BUTTONS_RIGHT))

        if environment._shell_loaded:
            self.selection_box.add(widgets.Switch(_('Enable animations'),
                                   'org.gnome.desktop.interface',
                                   'enable-animations'))
            
            if WINDOW_MOVE_EFFECT_EXTENSION in installed_extensions: # The window move extension is the important one
                self.selection_box.add(widgets.SwitchExtension(_('Jelly Mode'),
                                       [WINDOW_MOVE_EFFECT_EXTENSION, MAGIC_LAMP_EFFECT_EXTENSION]))

            self.zorin_menu_shortcut = widgets.BooleanComboExtension(_('Left Super Key'),
                                                                      MENU_SCHEMA,
                                                                      'super-hotkey',
                                                                      'Zorin ' + _('Menu'),
                                                                      _('Activities Overview'),
                                                                      ZORIN_MENU_EXTENSION
                                                                      )
            self.selection_box.add(self.zorin_menu_shortcut)

            self.selection_box.add(widgets.Switch(_('Activities Overview Hot Corner'),
                                   'org.gnome.desktop.interface',
                                   'enable-hot-corners'))

        self.selection_frame.add(self.selection_box)
        self.add(self.selection_frame)


class PanelAndDash(Gtk.Box):

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

        if ZORIN_TASKBAR_EXTENSION in installed_extensions:
            taskbar_extension = environment._get_shell_extension(ZORIN_TASKBAR_EXTENSION)
            taskbar_prefs = os.path.join(taskbar_extension['path'], "prefs.js")
            if os.path.exists(taskbar_prefs):
                self.selection_box.add(widgets.ExtensionPrefsButton(
                                   _('Taskbar Settings'),
                                   taskbar_extension))

        if ZORIN_DASH_EXTENSION in installed_extensions:
            dash_extension = environment._get_shell_extension(ZORIN_DASH_EXTENSION)
            dash_prefs = os.path.join(dash_extension['path'], "prefs.js")
            if os.path.exists(dash_prefs):
                self.selection_box.add(widgets.ExtensionPrefsButton(
                                   "Dash " + _('Settings'),
                                   dash_extension))

        self.selection_frame.add(self.selection_box)
        self.add(self.selection_frame)
