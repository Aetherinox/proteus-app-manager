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
import os
import gettext
import psutil
import shutil

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gio, GLib, GObject

from zorin_appearance import environment
from zorin_appearance import listbox
from zorin_appearance import widgets
from zorin_appearance import utils

t = gettext.translation('zorin-appearance', '/usr/share/locale',
                        fallback=True)
_ = t.gettext

USER_THEMES_EXTENSION = "user-theme@gnome-shell-extensions.gcampax.github.com"


AUTO_THEME_GSETTINGS_PATH = "com.zorin.desktop.auto-theme"
# Check if Auto Theme schema is installed
if Gio.SettingsSchemaSource.get_default().lookup(AUTO_THEME_GSETTINGS_PATH, True):
    AUTO_THEME_SCHEMA = Gio.Settings.new(AUTO_THEME_GSETTINGS_PATH)
    AUTO_THEME_FROM = 'schedule-from'
    AUTO_THEME_TO = 'schedule-to'
else:
    AUTO_THEME_SCHEMA = None
    AUTO_THEME_FROM = None
    AUTO_THEME_TO = None
AUTO_THEME_EXEC = "zorin-auto-theme"
AUTO_THEME_DESKTOP_FILE = "com.zorin.desktop.auto-theme.desktop"
APPLICATIONS_DIR = "/usr/share/applications/"
LOCAL_AUTOSTART_DIR = os.path.expanduser('~/.config/autostart/')
AUTO_THEME_PRESENT = os.path.isfile(APPLICATIONS_DIR + AUTO_THEME_DESKTOP_FILE)

ZORIN_THEMES = [
    ('ZorinBlue-Light', 'Blue', 'Light'),
    ('ZorinBlue-Dark', 'Blue', 'Dark'),
    ('ZorinGreen-Light', 'Green', 'Light'),
    ('ZorinGreen-Dark', 'Green', 'Dark'),
    ('ZorinOrange-Light', 'Orange', 'Light'),
    ('ZorinOrange-Dark', 'Orange', 'Dark'),
    ('ZorinRed-Light', 'Red', 'Light'),
    ('ZorinRed-Dark', 'Red', 'Dark'),
    ('ZorinPurple-Light', 'Purple', 'Light'),
    ('ZorinPurple-Dark', 'Purple', 'Dark'),
    ('ZorinGrey-Light', 'Grey', 'Light'),
    ('ZorinGrey-Dark', 'Grey', 'Dark')
    ]
ZORIN_THEME_BACKGROUNDS = [
    ('Light', utils.APP_DATA_PATH + 'theme/light.svg'),
    ('Auto', utils.APP_DATA_PATH + 'theme/auto.svg'),
    ('Dark', utils.APP_DATA_PATH + 'theme/dark.svg'),
    ]
ZORIN_THEME_COLORS = ['Blue', 'Green', 'Orange', 'Red', 'Purple', 'Grey']

LOCATION_SCHEMA = None
LOCATION_KEY = None

GNOME_INTERFACE_GSETTINGS_PATH = 'org.gnome.desktop.interface'
GNOME_INTERFACE_SCHEMA = Gio.Settings.new(GNOME_INTERFACE_GSETTINGS_PATH)
COLOR_SCHEME = 'color-scheme'
COLOR_SCHEME_VALUES = [
    'default',
    'prefer-dark',
    'prefer-light'
    ]

HAS_COLOR_SCHEME_KEY = False
gnome_interface_schema_source = Gio.SettingsSchemaSource.get_default().lookup(GNOME_INTERFACE_GSETTINGS_PATH, False)
if gnome_interface_schema_source and gnome_interface_schema_source.has_key(COLOR_SCHEME):
    HAS_COLOR_SCHEME_KEY = True

if environment._shell_loaded:
    INTERFACE_SCHEMA = GNOME_INTERFACE_SCHEMA
    APP_THEME = 'gtk-theme'
    ICON_THEME = 'icon-theme'
    SHELL_SCHEMA = Gio.Settings.new('org.gnome.shell.extensions.user-theme')
    SHELL_THEME = 'name'
    THEME_EXTENSION = environment._get_shell_extension(USER_THEMES_EXTENSION)
    LOCATION_SCHEMA = Gio.Settings.new('org.gnome.system.location')
    LOCATION_KEY = 'enabled'
elif environment._desktop_environment == 'XFCE':
    from zorin_appearance import xfconf
    XFCONF = xfconf.XfconfSetting()
    INTERFACE_SCHEMA = 'xsettings'
    APP_THEME = '/Net/ThemeName'
    ICON_THEME = '/Net/IconThemeName'
    WM_SCHEMA = 'xfwm4'
    WM_THEME = '/general/theme'
    ROUNDED_CORNERS_RADIUS = '/general/rounded_corners_radius'
    LOCATION_SCHEMA = Gio.Settings.new('com.zorin.desktop.agent-geoclue2')
    LOCATION_KEY = 'location-enabled'


class Themes(Gtk.Box):

    def __init__(self):
        Gtk.Box.__init__(
            self,
            orientation=Gtk.Orientation.VERTICAL,
            spacing=16,
            )

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        
        self.zorin_themes = ZorinThemes()
        self.other_themes = OtherThemes()

        self.stack.add_titled(self.zorin_themes, 'zorin', _('Zorin'))
        self.stack.add_titled(self.other_themes, 'other', _('Other'))
        
        stack_switcher = Gtk.StackSwitcher()
        stack_switcher.set_stack(self.stack)
        
        hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        hbox.pack_start(stack_switcher, True, False, 0)
        
        self.other_themes.connect("reset", self.reset_themes)

        self.add(hbox)
        self.pack_start(self.stack, True, True, 0)
        
    def set_active_page(self):
        current_app_theme = get_current_theme(INTERFACE_SCHEMA, APP_THEME)
        current_icon_theme = get_current_theme(INTERFACE_SCHEMA, ICON_THEME)
        current_desktop_environment_theme = current_app_theme
        if environment._shell_loaded:
            current_desktop_environment_theme = get_current_theme(SHELL_SCHEMA, SHELL_THEME)
        elif environment._desktop_environment == 'XFCE':
            current_desktop_environment_theme = get_current_theme(WM_SCHEMA, WM_THEME)

        zorin_theme_set = False
        
        for theme in ZORIN_THEMES:
            if current_app_theme == theme[0] and \
               current_icon_theme == theme[0] and \
               current_desktop_environment_theme == theme[0]:
                zorin_theme_set = True
                
        if zorin_theme_set:
            self.stack.set_visible_child_name('zorin')
        else:
            self.stack.set_visible_child_name('other')

    def reset_themes(self, widget):
        disable_auto_theme()
        self.zorin_themes.set_current_zorin_theme()
        self.set_active_page()


class ZorinThemes(Gtk.Box):

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

        # Color selector
        self.color_label = Gtk.Label(_('Accent Color'))
        self.color_selector = widgets.ColorSelector(ZORIN_THEME_COLORS)
        self.color_selector.connect("color-changed", self.on_color_changed)
        self.selection_box.add(listbox.ListBoxRow(self.color_label, self.color_selector))

        # Background selector
        self.background_label = Gtk.Label(_('Background'))
        self.background_selector = widgets.BackgroundSelector(ZORIN_THEME_BACKGROUNDS)
        self.background_selector.connect("background-changed", self.on_background_changed)
        self.selection_box.add(listbox.ListBoxRow(self.background_label, self.background_selector))

        if AUTO_THEME_SCHEMA != None:
            # Auto Theme scheduling
            self.auto_theme_schedule = widgets.BooleanCombo(_('Schedule'),
                               AUTO_THEME_GSETTINGS_PATH, 'schedule-automatic', _('Sunset to Sunrise'), _('Manual'))
            AUTO_THEME_SCHEMA.connect('changed::schedule-automatic', self.on_auto_theme_schedule_changed)
            self.selection_box.add(self.auto_theme_schedule)

            # Manual timing
            self.to_selector = widgets.TimePicker(_('Light'), AUTO_THEME_SCHEMA, AUTO_THEME_TO)
            self.from_selector = widgets.TimePicker(_('Dark'), AUTO_THEME_SCHEMA, AUTO_THEME_FROM)
            self.auto_theme_manual = listbox.ListBoxRow(self.to_selector, self.from_selector)
            self.selection_box.add(self.auto_theme_manual)

        self.set_current_zorin_theme()
        if environment._shell_loaded:
            settings = INTERFACE_SCHEMA
            settings.connect('changed::' + APP_THEME,
                             self.set_current_zorin_theme)
            settings.connect('changed::' + ICON_THEME,
                             self.set_current_zorin_theme)
        elif environment._desktop_environment == 'XFCE':
            XFCONF.bus.add_signal_receiver(self.set_current_zorin_theme,
                                           'PropertyChanged', 'org.xfce.Xfconf',
                                           'org.xfce.Xfconf', '/org/xfce/Xfconf')

        self.selection_frame.add(self.selection_box)
        self.add(self.selection_frame)

    def get_current_zorin_theme(self):
        current_app_theme = get_current_theme(INTERFACE_SCHEMA, APP_THEME)
        current_icon_theme = get_current_theme(INTERFACE_SCHEMA, ICON_THEME)
        current_desktop_environment_theme = current_app_theme
        if environment._shell_loaded:
            current_desktop_environment_theme = get_current_theme(SHELL_SCHEMA, SHELL_THEME)
        elif environment._desktop_environment == 'XFCE':
            current_desktop_environment_theme = get_current_theme(WM_SCHEMA, WM_THEME)

        if current_app_theme == current_icon_theme and current_app_theme == current_desktop_environment_theme:
            index = 0
            for theme in ZORIN_THEMES:
                if current_app_theme == theme[0]:
                    self.current_color = theme[1]
                    if AUTO_THEME_SCHEMA != None and AUTO_THEME_SCHEMA.get_boolean('enabled'):
                        self.current_background = 'Auto'
                    else:
                        self.current_background = theme[2]
                    return
                index += 1

        self.current_color = None
        self.current_background = None

    def set_current_zorin_theme(self, *args):
        self.get_current_zorin_theme()
        self.set_current_zorin_theme_color()
        self.set_current_zorin_theme_background()
        self.set_auto_theme_visibility()

    def set_current_zorin_theme_color(self):
        self.color_selector.set_color(self.current_color)

    def set_current_zorin_theme_background(self):
        self.background_selector.set_background(self.current_background)

    def set_auto_theme_visibility(self):
        if AUTO_THEME_SCHEMA != None:
            if self.current_background == 'Auto':
                self.auto_theme_schedule.set_visible(True)
                self.set_auto_theme_manual_visibility()
            else:
                self.auto_theme_schedule.set_visible(False)
                self.auto_theme_manual.set_visible(False)

    def set_auto_theme_manual_visibility(self):
        if AUTO_THEME_SCHEMA.get_boolean('schedule-automatic'):
            self.auto_theme_manual.set_visible(False)
        else:
            self.auto_theme_manual.set_visible(True)

    def on_background_changed(self, selector, background):
        if self.current_background != background:
            if background == 'Auto':
                enable_auto_theme()
            else:
                disable_auto_theme()
                if HAS_COLOR_SCHEME_KEY:
                    if background == 'Light':
                        GNOME_INTERFACE_SCHEMA.set_enum(COLOR_SCHEME, COLOR_SCHEME_VALUES.index('prefer-light'))
                    elif background == 'Dark':
                        GNOME_INTERFACE_SCHEMA.set_enum(COLOR_SCHEME, COLOR_SCHEME_VALUES.index('prefer-dark'))
                    else:
                        GNOME_INTERFACE_SCHEMA.set_enum(COLOR_SCHEME, COLOR_SCHEME_VALUES.index('default'))
        self.current_background = background
        self.set_zorin_theme(self.current_color, self.current_background)
        self.set_auto_theme_visibility()

    def on_auto_theme_schedule_changed(self, selector, background):
        try:
            self.set_auto_theme_manual_visibility()
            if AUTO_THEME_SCHEMA.get_boolean('schedule-automatic') and LOCATION_SCHEMA != None and LOCATION_SCHEMA.get_boolean(LOCATION_KEY) == False:
                dialog = widgets.LocationServiceDialog()
                dialog.connect('response', dialog.destroy)
                dialog.show_all()
        except:
            print("Failed to enable Zorin Auto Theme")

    def on_color_changed(self, selector, color):
        if self.current_color != color:
            self.current_color = color
            self.set_zorin_theme(self.current_color, self.current_background)

    def set_zorin_theme(self, color, background):
        if color == None:
            color = 'Blue'
        if background == None:
            background = 'Light'

        variant = "Zorin" + color

        if environment._desktop_environment == 'XFCE':
            set_theme(WM_SCHEMA, ROUNDED_CORNERS_RADIUS, 8)

        if AUTO_THEME_SCHEMA != None:
            AUTO_THEME_SCHEMA.set_string('day-theme', variant + "-Light")
            AUTO_THEME_SCHEMA.set_string('night-theme', variant + "-Dark")
            if background == 'Auto':
                return
        else:
            if background == 'Auto':
                background = 'Light'

        new_theme = variant + "-" + background

        if environment._shell_loaded and THEME_EXTENSION != None:
            set_theme(SHELL_SCHEMA, SHELL_THEME, new_theme)
        elif environment._desktop_environment == 'XFCE':
            set_theme(WM_SCHEMA, WM_THEME, new_theme)

        set_theme(INTERFACE_SCHEMA, APP_THEME,
                  new_theme)
        set_theme(INTERFACE_SCHEMA, ICON_THEME,
                  new_theme)


class OtherThemes(Gtk.Box):

    __gsignals__ = {"reset": (GObject.SIGNAL_RUN_FIRST,
                                 GObject.TYPE_NONE,
                                 ())
                   }

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

        self.selection_box.add(widgets.AppThemeSwitcher())
        self.selection_box.add(widgets.IconThemeSwitcher())

        if environment._shell_loaded and THEME_EXTENSION != None and THEME_EXTENSION['state'] == 1:
            self.selection_box.add(widgets.ShellThemeSwitcher())
        elif environment._desktop_environment == 'XFCE':
            self.selection_box.add(widgets.XFWMThemeSwitcher())

        self.selection_frame.add(self.selection_box)
        self.add(self.selection_frame)

        self.add(widgets.ThemeResetButton(self.on_reset_themes))

    def on_reset_themes(self):
        self.emit("reset")


def set_theme(schema, key_name, value):
    if environment._shell_loaded:
        schema.set_string(key_name, value)
    elif environment._desktop_environment == 'XFCE':
        XFCONF.xfconf.SetProperty(schema, key_name, value)

def get_current_theme(schema, key_name):
    if environment._shell_loaded:
        return schema.get_string(key_name)
    elif environment._desktop_environment == 'XFCE':
        return XFCONF.xfconf.GetProperty(schema, key_name)

def is_process_running(process_name):
    for process in psutil.process_iter():
        try:
            if process_name.lower() in process.name().lower():
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    return False;

def spawn_process(args=[]):
    return Gio.Subprocess.new(args, Gio.SubprocessFlags.NONE)

def enable_auto_theme():
    try:
        AUTO_THEME_SCHEMA.set_boolean('enabled', True)
        if is_process_running('zorin-auto-theme') == False:
            spawn_process([AUTO_THEME_EXEC])
        if AUTO_THEME_SCHEMA.get_boolean('schedule-automatic') and LOCATION_SCHEMA != None and LOCATION_SCHEMA.get_boolean(LOCATION_KEY) == False:
            dialog = widgets.LocationServiceDialog()
            dialog.connect('response', dialog.destroy)
            dialog.show_all()
    except:
        print("Failed to enable Zorin Auto Theme")

    try:
        if not os.path.exists(LOCAL_AUTOSTART_DIR):
            os.makedirs(LOCAL_AUTOSTART_DIR)
        shutil.copy(APPLICATIONS_DIR + AUTO_THEME_DESKTOP_FILE, LOCAL_AUTOSTART_DIR)
    except:
        print("Failed to copy " + AUTO_THEME_DESKTOP_FILE + " into local autostart directory")

def disable_auto_theme():
    try:
        AUTO_THEME_SCHEMA.set_boolean('enabled', False)
    except:
        print("Failed to disable Zorin Auto Theme")

    try:
        if os.path.isfile(LOCAL_AUTOSTART_DIR + AUTO_THEME_DESKTOP_FILE):
            os.remove(LOCAL_AUTOSTART_DIR + AUTO_THEME_DESKTOP_FILE)
    except:
        print("Failed to delete " + AUTO_THEME_DESKTOP_FILE + " from local autostart directory")
