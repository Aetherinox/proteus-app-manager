# This file is part of the Zorin Appearance program.
#
# Copyright 2016-2021 Zorin OS Technologies Ltd.
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
import os

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gio, Gdk

from zorin_appearance import theme
from zorin_appearance import desktop
from zorin_appearance import interface
from zorin_appearance import fonts
from zorin_appearance import environment
from zorin_appearance import layout
from zorin_appearance import utils

t = gettext.translation('zorin-appearance', '/usr/share/locale',
                        fallback=True)
_ = t.gettext

WINDOW_WIDTH = 824
WINDOW_HEIGHT = 604
SIDEBAR_WIDTH = 172

ZORIN_APPEARANCE_GSETTINGS_PATH = "com.zorin.desktop.appearance"
# Check if Auto Theme schema is installed
if Gio.SettingsSchemaSource.get_default().lookup(ZORIN_APPEARANCE_GSETTINGS_PATH, True):
    ZORIN_APPEARANCE_SCHEMA = Gio.Settings.new(ZORIN_APPEARANCE_GSETTINGS_PATH)
else:
    ZORIN_APPEARANCE_SCHEMA = None

DOC_PATH = "/usr/share/doc"

class ZorinAppearance(Gtk.Window):

    def __init__(self):
        Gtk.Window.__init__(self)
        self.set_resizable(False)
        self.set_size_request(WINDOW_WIDTH, WINDOW_HEIGHT)
        self.set_position(Gtk.WindowPosition.CENTER)

        icon = Gio.ThemedIcon(name='zorin-appearance')
        theme_icon = Gtk.IconTheme.get_default().lookup_by_gicon(icon,
                48, 0)
        image = Gtk.Image.new_from_gicon(icon, Gtk.IconSize.DIALOG)
        if theme_icon:
            self.set_default_icon(theme_icon.load_icon())

        hb = Gtk.HeaderBar()
        hb.set_show_close_button(True)
        self.set_titlebar(hb)

        grid = Gtk.Grid()
        self.add(grid)

        stack = Gtk.Stack()
        stack.set_hexpand(True)
        stack.set_vexpand(True)
        stack.set_transition_type(Gtk.StackTransitionType.SLIDE_UP_DOWN)
        grid.attach(stack, 1, 0, 1, 1)

        stack_sidebar = Gtk.StackSidebar()
        stack_sidebar.set_stack(stack)
        stack_sidebar.set_size_request(SIDEBAR_WIDTH, -1)
        grid.attach(stack_sidebar, 0, 0, 1, 1)
        
	# Layout tab
        layout_scrolled = Gtk.ScrolledWindow()
        layout_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL,
                              spacing=16)
        layout_box.set_border_width(16)
        layout_box.add(layout.Layouts())
        layout_scrolled.add(layout_box)

        stack.add_titled(layout_scrolled, 'layout', _('Layout'))
        
	# Theme tab
        theme_scrolled = Gtk.ScrolledWindow()
        theme_scrolled.set_policy(Gtk.PolicyType.NEVER,
                                  Gtk.PolicyType.AUTOMATIC)
        theme_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL,
                            spacing=16)
        theme_box.set_border_width(16)
        self.themes = theme.Themes()
        theme_box.add(self.themes)
        theme_scrolled.add(theme_box)
        stack.add_titled(theme_scrolled, 'theme', _('Theme'))
        
	# Interface tab
        if (environment._shell_loaded):
            interface_scrolled = Gtk.ScrolledWindow()
            interface_scrolled.set_policy(Gtk.PolicyType.NEVER,
                                      Gtk.PolicyType.AUTOMATIC)
            interface_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL,
                                  spacing=16)
            interface_box.set_border_width(16)
            interface_box.add(interface.Interface())
            if environment._shell_loaded:
                interface_box.add(interface.PanelAndDash())
            interface_scrolled.add(interface_box)
            stack.add_titled(interface_scrolled, 'interface', _('Interface'))

	# Desktop tab
        desktop_scrolled = Gtk.ScrolledWindow()
        desktop_scrolled.set_policy(Gtk.PolicyType.NEVER,
                                  Gtk.PolicyType.AUTOMATIC)
        desktop_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL,
                              spacing=16)
        desktop_box.set_border_width(16)
        desktop_box.add(desktop.Icons())
        desktop_scrolled.add(desktop_box)
        stack.add_titled(desktop_scrolled, 'desktop', _('Desktop'))

	# Fonts tab
        fonts_scrolled = Gtk.ScrolledWindow()
        fonts_scrolled.set_policy(Gtk.PolicyType.NEVER,
                                  Gtk.PolicyType.AUTOMATIC)
        fonts_box = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL,
            spacing=16,
            margin_start=16,
            margin_end=16,
            margin_left=16,
            margin_right=16,
            border_width=16,
            )
        fonts_box.add(fonts.Fonts())
        fonts_scrolled.add(fonts_box)
        stack.add_titled(fonts_scrolled, 'fonts', _('Fonts'))

        self.show()


def main():
    css_provider = Gtk.CssProvider()
    css_provider.load_from_path(utils.APP_DATA_PATH + 'css/application.css')
    screen = Gdk.Screen.get_default()
    style_context = Gtk.StyleContext()
    style_context.add_provider_for_screen(screen, css_provider,
                                          Gtk.STYLE_PROVIDER_PRIORITY_USER)

    window = ZorinAppearance()
    window.set_title('Zorin Appearance')
    window.connect('delete-event', Gtk.main_quit)
    window.show_all()
    window.themes.zorin_themes.set_auto_theme_visibility()
    window.themes.set_active_page()
    Gtk.main()


if __name__ == '__main__':
    main()