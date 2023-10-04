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
import dbus
import logging
import gettext
import pprint
import time

gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gio, GLib, GObject, Gdk

from zorin_appearance import environment
from zorin_appearance import listbox
from zorin_appearance import theme
from zorin_appearance import utils

t = gettext.translation('zorin-appearance', '/usr/share/locale',
                        fallback=True)
_ = t.gettext

(THEME_PREVIEW_WIDTH, THEME_PREVIEW_HEIGHT) = (150, 100)

DATA_DIR = '/usr/share'

LOCATION_PANEL = 'gnome-location-panel.desktop'

EXTENSIONS_SCHEMA = 'org.gnome.shell'

if environment._desktop_environment == 'XFCE':
    from zorin_appearance import xfconf
    XFCONF = xfconf.XfconfSetting()


# Desktop

class Switch(listbox.ListBoxRow):

    def __init__(
        self,
        name,
        schema,
        key_name,
        ):
        label = Gtk.Label(name)

        self.schema = schema
        self.key_name = key_name

        self.switch = Gtk.Switch()

        if environment._shell_loaded:
            setting = Gio.Settings.new(self.schema)
            setting.bind(self.key_name, self.switch, 'active',
                         Gio.SettingsBindFlags.DEFAULT)
        elif environment._desktop_environment == 'XFCE':
            self.switch.set_state(self._convert_xfce_setting(True,
                                  XFCONF.xfconf.GetProperty(self.schema,
                                  self.key_name)))
            self.switch.connect('state-set', self._on_switch_changed)
            XFCONF.bus.add_signal_receiver(self._on_setting_changed,
                    'PropertyChanged', 'org.xfce.Xfconf',
                    'org.xfce.Xfconf', '/org/xfce/Xfconf')

        listbox.ListBoxRow.__init__(self, label, self.switch)

    def _on_setting_changed(
        self,
        channel,
        property,
        value,
        ):
        if channel == self.schema and property == self.key_name:
            self.switch.set_state(self._convert_xfce_setting(True,
                                  value))

    def _on_switch_changed(self, switch, value):
        XFCONF.xfconf.SetProperty(self.schema, self.key_name,
                                  self._convert_xfce_setting(False,
                                  value))

    def _convert_xfce_setting(self, to_bool, value):
        if to_bool == True:
            return (True if value == 2 else False)
        else:
            return (2 if value == True else 0)


class Check(listbox.ListBoxRow):

    def __init__(
        self,
        name,
        schema,
        key_name,
        dependency_schema,
        dependency_key,
        ):
        self.check = Gtk.CheckButton.new_with_label(name)

        self.schema = schema
        self.key_name = key_name
        self.dependency_schema = dependency_schema
        self.dependency_key = dependency_key

        if environment._shell_loaded:
            setting = Gio.Settings.new(self.schema)
            setting.bind(self.key_name, self.check, 'active',
                         Gio.SettingsBindFlags.DEFAULT)

            if self.dependency_schema and self.dependency_key:
                self.dependency_setting = Gio.Settings.new(self.dependency_schema)
                self._set_sensitivity(self.dependency_setting,
                        self.dependency_key)
                self.dependency_setting.connect('changed::%s'
                        % self.dependency_key, self._set_sensitivity)
        elif environment._desktop_environment == 'XFCE':
            self.check.set_active(XFCONF.xfconf.GetProperty(self.schema,
                                  self.key_name))
            self.check.connect('toggled', self._on_check_changed)
            XFCONF.bus.add_signal_receiver(self._on_setting_changed,
                    'PropertyChanged', 'org.xfce.Xfconf',
                    'org.xfce.Xfconf', '/org/xfce/Xfconf')

            if self.dependency_schema and self.dependency_key:
                self._set_sensitivity(self.dependency_schema,
                        self.dependency_key)
                XFCONF.bus.add_signal_receiver(self._set_sensitivity,
                        'PropertyChanged', 'org.xfce.Xfconf',
                        'org.xfce.Xfconf', '/org/xfce/Xfconf')

        listbox.ListBoxRow.__init__(self, self.check, None)

    def _set_sensitivity(self, *args):
        if environment._shell_loaded:
            current_setting = args[0].get_boolean(args[1])
        elif environment._desktop_environment == 'XFCE':
            if args[0] != self.dependency_schema or args[1] != self.dependency_key:
                return
            else:
                current_setting = (True if XFCONF.xfconf.GetProperty(args[0],
                                      args[1]) else False)

        if current_setting == True:
            self.check.set_sensitive(True)
        else:
            self.check.set_sensitive(False)

    def _on_setting_changed(
        self,
        channel,
        property,
        value,
        ):
        if channel == self.schema and property == self.key_name:
            self.check.set_active(value)

    def _on_check_changed(self, check):
        XFCONF.xfconf.SetProperty(self.schema, self.key_name,
                                  self.check.get_active())


class SwitchExtension(listbox.ListBoxRow):

    def __init__(
        self,
        name,
        extensions
        ):
        label = Gtk.Label(name)

        self.extensions = extensions

        self.switch = Gtk.Switch()
                    
        self.extensions_setting = Gio.Settings.new(EXTENSIONS_SCHEMA)
        self._on_setting_changed()
        self.extensions_setting.connect('changed::enabled-extensions', self._on_setting_changed)
        
        self.switch.connect('state-set', self._on_switch_changed)

        listbox.ListBoxRow.__init__(self, label, self.switch)

    def _on_setting_changed(self, *args):
        all_extensions_enabled = True
        
        for extension in self.extensions:
            if environment._shell.extension_is_active(1, extension) != True:
                all_extensions_enabled = False
    
        if all_extensions_enabled == True:
            self.switch.set_state(True)
        else:
            self.switch.set_state(False)
            
    def _on_switch_changed(self, switch, value):
        for extension in self.extensions:
            if (value == True):
                environment._shell.enable_extension(extension)
            else:
                environment._shell.disable_extension(extension)


class CheckExtension(listbox.ListBoxRow):

    def __init__(
        self,
        name,
        schema,
        key_name,
        dependency_extension,
        ):
        self.check = Gtk.CheckButton.new_with_label(name)

        self.schema = schema
        self.key_name = key_name
        self.dependency_extension = dependency_extension

        setting = Gio.Settings.new(self.schema)
        setting.bind(self.key_name, self.check, 'active',
                     Gio.SettingsBindFlags.DEFAULT)

        self.extensions_setting = Gio.Settings.new(EXTENSIONS_SCHEMA)
        self._set_sensitivity()
        self.extensions_setting.connect('changed::enabled-extensions', self._set_sensitivity)

        listbox.ListBoxRow.__init__(self, self.check, None)

    def _set_sensitivity(self, *args):
        if environment._shell.extension_is_active(1, self.dependency_extension):
            self.check.set_sensitive(True)
        else:
            self.check.set_sensitive(False)

    def _on_setting_changed(
        self,
        channel,
        property,
        value,
        ):
        if channel == self.schema and property == self.key_name:
            self.check.set_active(value)


class GSettingsComboEnum(listbox.ListBoxRow):
    def __init__(self, name, schema, key_name):
    
        label = Gtk.Label(name)
    
        self.schema = schema
        self.key_name = key_name
    
        self.settings = Gio.Settings.new(self.schema)

        _type, values = self.settings.get_range(key_name)
        value = self.settings.get_string(key_name)
        self.settings.connect('changed::'+self.key_name, self._on_setting_changed)

        self.combo = build_combo_box_text(value, False, *[(v, _(v.replace("-", " ").title())) for v in values])
        self.combo.connect('changed', self._on_combo_changed)
        
        listbox.ListBoxRow.__init__(self, label, self.combo)

    def _values_are_different(self):
        # to stop bouncing back and forth between changed signals. I suspect there must be a nicer
        # Gio.settings_bind way to fix this
        return self.settings.get_string(self.key_name) != \
               self.combo.get_model().get_value(self.combo.get_active_iter(), 0)

    def _on_setting_changed(self, setting, key):
        assert key == self.key_name
        val = self.settings.get_string(key)
        model = self.combo.get_model()
        for row in model:
            if val == row[0]:
                self.combo.set_active_iter(row.iter)
                break

    def _on_combo_changed(self, combo):
        val = self.combo.get_model().get_value(self.combo.get_active_iter(), 0)
        if self._values_are_different():
            self.settings.set_string(self.key_name, val)


class ComboEnumExtension(GSettingsComboEnum):

    def __init__(self,
        name,
        schema,
        key_name,
        dependency_extension,
        ):
        
        GSettingsComboEnum.__init__(self,
                                    name,
                                    schema,
                                    key_name)
        
        self.dependency_extension = dependency_extension
        self.extensions_setting = Gio.Settings.new(EXTENSIONS_SCHEMA)
        self._set_sensitivity()
        self.extensions_setting.connect('changed::enabled-extensions', self._set_sensitivity)

    def _set_sensitivity(self, *args):
        if environment._shell.extension_is_active(1, self.dependency_extension):
            self.set_sensitive(True)
        else:
            self.set_sensitive(False)


class LeftRightButton(listbox.ListBoxRow):

    def __init__(self, name, schema, key_name, left_value, right_value):
        label = Gtk.Label(name)
        button_box = Gtk.ButtonBox(orientation=Gtk.Orientation.HORIZONTAL,
                                   spacing=0)
        button_box.set_layout(Gtk.ButtonBoxStyle.EXPAND)

        self._left = Gtk.RadioButton.new_with_label_from_widget(None,
                _('Left'))
        self._left.set_property("draw-indicator", False)

        self._right = Gtk.RadioButton.new_with_label_from_widget(self._left,
                _('Right'))
        self._right.set_property("draw-indicator", False)

        button_box.pack_start(self._left, True, True, 0)
        button_box.pack_start(self._right, True, True, 0)

        if environment._shell_loaded:
            setting = Gio.Settings.new(schema)
            self._select_current_option(setting, key_name)

            self._left.connect('toggled', self._on_side_changed,
                               setting, key_name, left_value)
            self._right.connect('toggled', self._on_side_changed,
                                setting, key_name, right_value)

            setting.connect('changed::%s' % key_name,
                            self._select_current_option)
        elif environment._desktop_environment == 'XFCE':
            self._select_current_option(schema, key_name)

            self._left.connect('toggled', self._on_side_changed,
                               schema, key_name, left_value)
            self._right.connect('toggled', self._on_side_changed,
                               schema, key_name, right_value)

        listbox.ListBoxRow.__init__(self, label, button_box)

    def _on_side_changed(self, button, schema, key_name, value):
        if button.get_active():
            if environment._shell_loaded:
                schema.set_string(key_name, value)
            elif environment._desktop_environment == 'XFCE':
                XFCONF.xfconf.SetProperty(schema, key_name, value)

    def _select_current_option(self, schema, key_name):
        if environment._shell_loaded:
            current_setting = schema.get_string(key_name)

            for i in range(len(current_setting) - 1):
                if current_setting[i] == ':':  # If the expander comes first,
                    self._left.set_active(False)  # the close button is on the right
                    self._right.set_active(True)
                    return
                elif current_setting[i] == 'c': # If the close button comes first,
                    self._left.set_active(True)  # the close button is on the left
                    self._right.set_active(False)
                    return
        elif environment._desktop_environment == 'XFCE':
            current_setting = XFCONF.xfconf.GetProperty(schema, key_name)

            for i in range(len(current_setting) - 1):
                if current_setting[i] == '|':  # If the expander comes first,
                    self._left.set_active(False)  # the close button is on the right
                    self._right.set_active(True)
                    return
                elif current_setting[i] == 'C': # If the close button comes first,
                    self._left.set_active(True)  # the close button is on the left
                    self._right.set_active(False)
                    return


# Time Picker

class TimePicker(Gtk.Box):

    def __init__(self, name, schema, key_name):

        Gtk.Box.__init__(self, orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

        self.schema = schema
        self.key_name = key_name

        label = Gtk.Label(name)
        self.pack_start(label, False, False, 0)

        time_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)

        self.hours_spinbutton = Gtk.SpinButton(max_width_chars=2, orientation="vertical", numeric=True, wrap=True, digits=0)
        self.hours_adjustment = Gtk.Adjustment(lower=0, upper=23, step_increment=1, page_increment=10)
        self.hours_spinbutton.set_adjustment(self.hours_adjustment)
        self.hours_adjustment.connect("value-changed", self.on_time_changed)
        self.hours_spinbutton.connect('output', self._format_time)
        time_box.pack_start(self.hours_spinbutton, False, False, 0)

        separator = Gtk.Label(_(':'))
        time_box.pack_start(separator, False, False, 0)

        self.minutes_spinbutton = Gtk.SpinButton(max_width_chars=2, orientation="vertical", numeric=True, wrap=True, digits=0)
        self.minutes_adjustment = Gtk.Adjustment(lower=0, upper=59, step_increment=1, page_increment=10)
        self.minutes_spinbutton.set_adjustment(self.minutes_adjustment)
        self.minutes_adjustment.connect("value-changed", self.on_time_changed)
        self.minutes_spinbutton.connect('output', self._format_time)
        time_box.pack_start(self.minutes_spinbutton, False, False, 0)

        self.pack_start(time_box, False, False, 0)

        self.update_time(schema, key_name)
        #TODO Update values in spinbuttons when Gsetting changed, perhaps using gsettings.bind on a new "decimal time" property

    def update_time(self, schema, key_name):
        self.hours, self.minutes = self._decimal_to_time(schema.get_double(key_name))
        self.hours_spinbutton.set_value(self.hours)
        self.minutes_spinbutton.set_value(self.minutes)

    def on_time_changed(self, adjustment):
        hours = self.hours_spinbutton.get_value()
        minutes = self.minutes_spinbutton.get_value()
        self.schema.set_double(self.key_name, self._time_to_decimal(hours, minutes))

    def _decimal_to_time(self, decimal_value):
        hours = decimal_value // 1
        if hours > 23:
            hours = 23
        elif hours < 0:
            hours = 0

        minutes_decimal = decimal_value % 1
        minutes = 0
        if minutes_decimal > 0:
            minutes = (60 * minutes_decimal) // 1

        return hours, minutes

    def _time_to_decimal(self, hours, minutes):
        return hours + (minutes / 60)

    def _format_time(self, spinbutton):
        adjustment = spinbutton.get_adjustment()
        text = '%02d' % adjustment.get_value()
        spinbutton.set_text(text)
        return True


# Fonts

class FontButton(listbox.ListBoxRow):

    def __init__(
        self,
        name,
        schema,
        key_name,
        ):
        label = Gtk.Label(name)

        self.schema = schema
        self.key_name = key_name

        self.button = Gtk.FontButton()

        if environment._shell_loaded:
            setting = Gio.Settings.new(self.schema)
            setting.bind(self.key_name, self.button, 'font-name',
                         Gio.SettingsBindFlags.DEFAULT)
        elif environment._desktop_environment == 'XFCE':
            self.button.set_font_name(XFCONF.xfconf.GetProperty(self.schema,
                    self.key_name))
            self.button.connect('font-set', self._on_button_changed)
            XFCONF.bus.add_signal_receiver(self._on_setting_changed,
                    'PropertyChanged', 'org.xfce.Xfconf',
                    'org.xfce.Xfconf', '/org/xfce/Xfconf')

        listbox.ListBoxRow.__init__(self, label, self.button)

    def _on_setting_changed(
        self,
        channel,
        property,
        value,
        ):
        if channel == self.schema and property == self.key_name:
            self.button.set_font_name(value)

    def _on_button_changed(self, button):
        XFCONF.xfconf.SetProperty(self.schema, self.key_name,
                                  button.get_font_name())


class ExtensionPrefsButton(listbox.ListBoxRow):

    def __init__(
        self,
        name,
        extension,
        ):
        label = Gtk.Label(name)

        self.extension = extension
        self.uuid = self.extension['uuid']
        self.path = self.extension['path']

        self.button = Gtk.Button.new_from_icon_name("emblem-system-symbolic", Gtk.IconSize.BUTTON)
        self.button.props.valign = Gtk.Align.CENTER
        self.button.connect("clicked", self._on_configure_clicked, self.uuid)
        
        listbox.ListBoxRow.__init__(self, label, self.button)
            
        self.extensions_setting = Gio.Settings.new(EXTENSIONS_SCHEMA)
        self._set_sensitivity()
        self.extensions_setting.connect('changed::enabled-extensions', self._set_sensitivity)

    def _on_configure_clicked(
        self,
        button,
        uuid
        ):
        utils.execute_subprocess(['gnome-extensions', 'prefs', uuid], block=False)
        
    def _set_sensitivity(self, *args):
        if environment._shell.extension_is_active(1, self.uuid):
            self.set_sensitive(True)
        else:
            self.set_sensitive(False)


class BooleanCombo(listbox.ListBoxRow):

    def __init__(
        self,
        name,
        schema,
        key_name,
        true_name,
        false_name,
        ):
        label = Gtk.Label(name)
        
        self.settings = Gio.Settings.new(schema)
        
        options = [("True", true_name), ("False", false_name)]

        self.combo = build_combo_box_text(str(self.settings.get_boolean(key_name)),
                                          True, *options)

        self.combo.connect('changed', self._on_combo_changed,
                           self.settings, key_name)
        self.settings.connect('changed::' + key_name,
                              self._on_setting_changed)

        listbox.ListBoxRow.__init__(self, label, self.combo)

    def _on_setting_changed(self, *args):
        value = str(self.settings.get_boolean(args[1]))

        model = self.combo.get_model()
        for row in model:
            if value == row[0]:
                self.combo.set_active_iter(row.iter)
                return

        self.combo.set_active(-1)

    def _on_combo_changed(
        self,
        combo,
        schema,
        key_name,
        ):
        _iter = combo.get_active_iter()
        if _iter:
            value = combo.get_model().get_value(_iter, 0)
            self.settings.set_boolean(key_name, utils.strtobool(value))


class BooleanComboExtension(BooleanCombo):

    def __init__(self,
        name,
        schema,
        key_name,
        true_name,
        false_name,
        dependency_extension,
        ):
        
        BooleanCombo.__init__(self,
                              name,
                              schema,
                              key_name,
                              true_name,
                              false_name
                              )
        
        self.dependency_extension = dependency_extension
        self.extensions_setting = Gio.Settings.new(EXTENSIONS_SCHEMA)
        self._set_sensitivity()
        self.extensions_setting.connect('changed::enabled-extensions', self._set_sensitivity)

    def _set_sensitivity(self, *args):
        if environment._shell.extension_is_active(1, self.dependency_extension):
            self.set_sensitive(True)
        else:
            self.set_sensitive(False)


class ThemeResetButton(Gtk.Box):

    def __init__(
        self,
        _callback = None
        ):
        Gtk.Box.__init__(self)
        
        self.callback = _callback
        
        self.button = Gtk.Button.new_with_label(_('Reset to defaults'))
        self.button.connect("clicked", self._on_clicked)
        
        self.pack_end(self.button, False, False, 0)
        
    def _on_clicked(self, button):
        theme_types = [(theme.INTERFACE_SCHEMA, theme.APP_THEME),
                       (theme.INTERFACE_SCHEMA, theme.ICON_THEME)]
        
        if environment._shell_loaded:
            theme_types.append((theme.SHELL_SCHEMA, theme.SHELL_THEME))
        elif environment._desktop_environment == 'XFCE':
            theme_types.append((theme.WM_SCHEMA, theme.WM_THEME))
                       
        for theme_type in theme_types:
            self._reset_theme(theme_type[0], theme_type[1])

        if self.callback:
            self.callback()

    def _reset_theme(self, schema, key_name):
        if environment._shell_loaded:
            schema.reset(key_name)
        elif environment._desktop_environment == 'XFCE':
            XFCONF.xfconf.ResetProperty(schema, key_name, False)

class LocationServiceDialog(Gtk.Dialog):

    def __init__(self):

        Gtk.Dialog.__init__(self, None, None, Gtk.DialogFlags.USE_HEADER_BAR | Gtk.DialogFlags.MODAL, [], use_header_bar=True)

        self.set_default_size(400, 120)
        self.set_resizable(False)

        self.add_button(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL)
        button = None
        if environment._shell_loaded:
            button = self.add_button(_('Location Settings'), Gtk.ResponseType.OK)
        else:
            button = self.add_button(_('Enable'), Gtk.ResponseType.OK)
        button.get_style_context().add_class('suggested-action')

        self.area = self.get_content_area()
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, margin=18, spacing=18, vexpand=True)
        self.area.add(box)

        icon = Gio.ThemedIcon(name="mark-location-symbolic")
        image = Gtk.Image.new_from_gicon(icon, Gtk.IconSize.DIALOG)
        box.pack_start(image, True, True, 0)

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, margin=0, spacing=6)
        box.add(vbox)

        vbox.pack_start(Gtk.Label(_('Turn on location services to find your location')), True, True, 0)
        vbox.pack_start(Gtk.Label(_("Your location will be used to change the desktop theme at sunrise and sunset.")), True, True, 0)

        self.connect("response", self.on_response)

    def on_response(self, dialog, response):
        if response == Gtk.ResponseType.OK:
            if environment._shell_loaded:
                location_info = Gio.DesktopAppInfo.new(LOCATION_PANEL)

                try:
                    display = Gdk.Display.get_default();
                    location_info.launch([], display.get_app_launch_context())
                except:
                    print('Launching location panel failed')
            else:
                try:
                    theme.LOCATION_SCHEMA.set_boolean(theme.LOCATION_KEY, True)
                except:
                    print('Failed to enable location services')

        self.destroy()


class ColorRadioButton(Gtk.Overlay):

    def __init__(self, name):

        Gtk.Overlay.__init__(self)

        self.name = name
        self.hidden = False

        self.button = Gtk.RadioButton.new()
        self.button.set_property("draw-indicator", False)
        self.button.connect("toggled", self.on_button_toggled)
        style_context = self.button.get_style_context()
        style_context.add_class(name)

        self.active_image = Gtk.Image()
        self.active_image.set_halign(Gtk.Align.CENTER)
        self.active_image.set_valign(Gtk.Align.CENTER)

        self.add(self.button)
        self.add_overlay(self.active_image)
        self.set_overlay_pass_through(self.active_image, True)

        self.on_button_toggled(self.button)

    def on_button_toggled(self, button):
        if button.get_active() and self.hidden != True:
            self.active_image.set_from_file(utils.APP_DATA_PATH + "theme/checked.svg")
        else:
            self.active_image.clear()

    def set_hidden(self, hidden):
        self.hidden = hidden
        if hidden:
            self.active_image.clear()

class ColorSelector(Gtk.Box):

    def __init__(self, colors):

        Gtk.Box.__init__(self, orientation=Gtk.Orientation.HORIZONTAL, spacing=12, name="zorin-colors")

        GObject.signal_new('color-changed', self, GObject.SIGNAL_RUN_FIRST, None, (str,))


        self.colors = colors

        self.hidden_radio = ColorRadioButton('hidden')
        self.hidden_radio.button.set_active(True)
        self.hidden_radio.set_hidden(True)
        self.pack_start(self.hidden_radio, False, False, 0)
        
        first_button = self.hidden_radio.button

        for color in self.colors:
            radio = ColorRadioButton(color)
            radio.button.connect("toggled", self.on_color_toggled, radio.name)
            radio.button.set_active(False)
            radio.button.join_group(first_button)
            self.pack_start(radio, False, False, 0)

    def on_color_toggled(self, button, name):
        if button.get_active():
            self.emit("color-changed", name)

    def set_color(self, selected_color):
        index = 1
        for color in self.colors:
            if selected_color == color:
                self.get_children()[index].button.set_active(True)
                return
            index += 1

        self.hidden_radio.button.set_active(True)


class BackgroundRadioButton(Gtk.RadioButton):

    def __init__(self, name, image_path):

        Gtk.RadioButton.__init__(self)

        self.name = name

        self.set_property("draw-indicator", False)
        self.connect("toggled", self.on_button_toggled)
        style_context = self.get_style_context()
        style_context.add_class(name)

        if image_path != None:
            self.background_image = Gtk.Image()
            self.background_image.set_from_file(image_path)
            self.background_image.set_halign(Gtk.Align.CENTER)
            self.background_image.set_valign(Gtk.Align.CENTER)
            self.set_image(self.background_image)

    def on_button_toggled(self, button):
        pass


class BackgroundSelector(Gtk.Box):

    def __init__(self, backgrounds):

        Gtk.Box.__init__(self, orientation=Gtk.Orientation.HORIZONTAL, spacing=6, name="zorin-backgrounds")

        GObject.signal_new('background-changed', self, GObject.SIGNAL_RUN_FIRST, None, (str,))

        self.backgrounds = backgrounds

        self.hidden_radio = BackgroundRadioButton('hidden', None)
        self.hidden_radio.set_active(True)
        self.pack_start(self.hidden_radio, False, False, 0)
        
        first_button = self.hidden_radio

        for background in self.backgrounds:
            radio = BackgroundRadioButton(background[0], background[1])
            radio.connect("toggled", self.on_background_toggled, radio.name)
            radio.set_active(False)
            radio.join_group(first_button)
            self.pack_start(radio, False, False, 0)
            if background[0] == 'Auto' and theme.AUTO_THEME_SCHEMA == None:
                radio.set_sensitive(False)

    def on_background_toggled(self, button, name):
        if button.get_active():
            self.emit("background-changed", name)

    def set_background(self, selected_background):
        index = 1
        for background in self.backgrounds:
            if selected_background == background[0]:
                self.get_children()[index].set_active(True)
                return
            index += 1

        self.hidden_radio.set_active(True)


class ThemeComboSwitcher(listbox.ListBoxRow):

    def __init__(
        self,
        name,
        schema,
        key_name,
        key_options,
        ):
        label = Gtk.Label(name)

        self.schema = schema
        self.key_name = key_name

        if environment._shell_loaded:
            self.settings = Gio.Settings.new(self.schema)

            self.combo = build_combo_box_text(self.settings.get_string(self.key_name),
                                              True, *key_options)

            self.combo.connect('changed', self._on_combo_changed,
                               self.settings, self.key_name)
            self.settings.connect('changed::' + self.key_name,
                                  self._on_setting_changed)
        elif environment._desktop_environment == 'XFCE':
            self.combo = build_combo_box_text(XFCONF.xfconf.GetProperty(self.schema,
                                              self.key_name), True, *key_options)

            self.combo.connect('changed', self._on_combo_changed,
                               self.schema, self.key_name)
            XFCONF.bus.add_signal_receiver(self._on_setting_changed,
                                           'PropertyChanged', 'org.xfce.Xfconf',
                                           'org.xfce.Xfconf', '/org/xfce/Xfconf')

        listbox.ListBoxRow.__init__(self, label, self.combo)

    def _on_setting_changed(self, *args):
        if environment._shell_loaded:
            value = self.settings.get_string(args[1])
        elif environment._desktop_environment == 'XFCE':
            if args[0] != self.schema or args[1] != self.key_name:
                return
            else:
                value = args[2]

        model = self.combo.get_model()
        for row in model:
            if value == row[0]:
                self.combo.set_active_iter(row.iter)
                return

        self.combo.set_active(-1)

    def _on_combo_changed(
        self,
        combo,
        schema,
        key_name,
        ):
        _iter = combo.get_active_iter()
        if _iter:
            value = combo.get_model().get_value(_iter, 0)
            theme.set_theme(schema, key_name, value)
            theme.disable_auto_theme()


class AppThemeSwitcher(ThemeComboSwitcher):

    def __init__(self):
        if environment._shell_loaded:
            schema = 'org.gnome.desktop.interface'
            key_name = 'gtk-theme'
        elif environment._desktop_environment == 'XFCE':
            schema = 'xsettings'
            key_name = '/Net/ThemeName'

        ThemeComboSwitcher.__init__(self, _('Applications'), schema,
                                    key_name,
                                    make_combo_list(self._get_app_themes(),
                                    True))

    def _get_app_themes(self):

        # Only shows themes that have variations for gtk+-3 and gtk+-2

        dirs = (os.path.join(DATA_DIR, 'themes'),
                os.path.join(GLib.get_user_data_dir(), 'themes'),
                os.path.join(os.path.expanduser('~'), '.themes'))
        valid = utils.walk_directories(dirs, lambda d: \
                os.path.exists(os.path.join(d, 'gtk-2.0')) \
                and os.path.exists(os.path.join(d, 'gtk-3.0')))

        remove_zorin_themes(valid)

        return valid

    def _on_combo_changed(
        self,
        combo,
        schema,
        key_name,
        ):
        _iter = combo.get_active_iter()
        if _iter:
            value = combo.get_model().get_value(_iter, 0)
            theme.set_theme(schema, key_name, value)
            theme.disable_auto_theme()
            if theme.HAS_COLOR_SCHEME_KEY:
                if value.lower().endswith("-dark"):
                    theme.GNOME_INTERFACE_SCHEMA.set_enum(theme.COLOR_SCHEME, theme.COLOR_SCHEME_VALUES.index('prefer-dark'))
                else:
                    theme.GNOME_INTERFACE_SCHEMA.set_enum(theme.COLOR_SCHEME, theme.COLOR_SCHEME_VALUES.index('default'))
            if environment._desktop_environment == 'XFCE':
                theme.set_theme(theme.WM_SCHEMA, theme.ROUNDED_CORNERS_RADIUS, 0)


class IconThemeSwitcher(ThemeComboSwitcher):

    def __init__(self):
        if environment._shell_loaded:
            self.schema = 'org.gnome.desktop.interface'
            self.key_name = 'icon-theme'
        elif environment._desktop_environment == 'XFCE':
            self.schema = 'xsettings'
            self.key_name = '/Net/IconThemeName'

        ThemeComboSwitcher.__init__(self, _('Icons'), self.schema,
                                    self.key_name,
                                    make_combo_list(self._get_icon_themes(),
                                    True))

    def _get_icon_themes(self):
        dirs = (os.path.join(DATA_DIR, 'icons'),
                os.path.join(GLib.get_user_data_dir(), 'icons'),
                os.path.join(os.path.expanduser('~'), '.icons'))
        valid = utils.walk_directories(dirs, lambda d: os.path.isdir(d) \
                and os.path.exists(os.path.join(d, 'index.theme')) \
                and not os.path.exists(os.path.join(d, 'cursors')) )

        remove_zorin_themes(valid)

        return valid


class XFWMThemeSwitcher(ThemeComboSwitcher):

    def __init__(self):
        self.schema = 'xfwm4'
        self.key_name = '/general/theme'

        ThemeComboSwitcher.__init__(self, _('Window Manager'), self.schema,
                                    self.key_name,
                                    make_combo_list(self._get_xfwm_themes(),
                                    True))

    def _get_xfwm_themes(self):
        dirs = (os.path.join(DATA_DIR, 'themes'),
                os.path.join(GLib.get_user_data_dir(), 'themes'),
                os.path.join(os.path.expanduser('~'), '.themes'))
        valid = utils.walk_directories(dirs, lambda d: \
                os.path.exists(os.path.join(d, 'xfwm4')))

        remove_zorin_themes(valid)

        return valid


class ShellThemeSwitcher(listbox.ListBoxRow):

    THEME_EXT_NAME = 'user-theme@gnome-shell-extensions.gcampax.github.com'
    THEME_GSETTINGS_DIR = os.path.join(GLib.get_user_data_dir(),
            'gnome-shell', 'extensions', THEME_EXT_NAME, 'schemas')
    LEGACY_THEME_DIR = os.path.join(GLib.get_home_dir(), '.themes')
    THEME_DIR = os.path.join(GLib.get_user_data_dir(), 'themes')

    def __init__(self, **options):
        label = Gtk.Label(_('Shell'))

        # check the shell is running and the usertheme extension is present

        error = _('Unknown error')
        self._shell = environment._shell

        if self._shell is None:
            logging.warning(_('Shell not running'), exc_info=True)
            error = _('Shell not running')
        else:
            try:
                extensions = self._shell.list_extensions()
                if ShellThemeSwitcher.THEME_EXT_NAME in extensions \
                    and extensions[ShellThemeSwitcher.THEME_EXT_NAME]['state'
                        ] == 1:

                    # check the correct gsettings key is present

                    try:
                        self._settings = theme.SHELL_SCHEMA
                        name = self._settings.get_string(theme.SHELL_THEME)

                        ext = extensions[ShellThemeSwitcher.THEME_EXT_NAME]
                        logging.debug('Shell user-theme extension\n%s'
                                % pprint.pformat(ext))

                        error = None
                    except:
                        logging.warning('Could not find user-theme extension in %s'
                                 % ','.join(extensions.keys()),
                                exc_info=True)
                        error = _('Shell user-theme extension incorrectly installed')
                else:

                    error = _('Shell user-theme extension not enabled')
            except Exception as e:
                logging.warning(_('Could not list shell extensions'),
                                exc_info=True)
                error = _('Could not list shell extensions')

        if error:
            pass
        else:

            # include both system, and user themes
            # note: the default theme lives in /system/data/dir/gnome-shell/theme
            #      and not themes/, so add it manually later

            dirs = [os.path.join(d, 'themes') for d in
                    GLib.get_system_data_dirs()]
            dirs += [ShellThemeSwitcher.THEME_DIR]
            dirs += [ShellThemeSwitcher.LEGACY_THEME_DIR]

            valid = utils.walk_directories(dirs, lambda d: \
                    os.path.exists(os.path.join(d, 'gnome-shell')) \
                    and os.path.exists(os.path.join(d, 'gnome-shell',
                    'gnome-shell.css')))

            # as Gnome's default shell theme doesn't have a name, we're setting it ourselves

            valid.extend(('Default', ))

            remove_zorin_themes(valid)

            # build a combo box with all the valid theme options

            cb = build_combo_box_text(self._settings.get_string(theme.SHELL_THEME),
                    True,
                    *make_combo_list(valid, title=True))
            cb.connect('changed', self._on_combo_changed)
            self._combo = cb

            self.settings = Gio.Settings.new('org.gnome.shell.extensions.user-theme')
            self.settings.connect('changed::name',
                                  self._on_setting_changed)

            listbox.ListBoxRow.__init__(self, label, self._combo)

    def _on_combo_changed(self, combo):
        _iter = combo.get_active_iter()
        if _iter:
            value = combo.get_model().get_value(_iter, 0)
            self._settings.set_string(theme.SHELL_THEME, value)
            theme.disable_auto_theme()

    def _on_setting_changed(self, *args):
        value = self.settings.get_string(args[1])

        model = self._combo.get_model()
        for row in model:
            if value == row[0]:
                self._combo.set_active_iter(row.iter)
                return

        self._combo.set_active(-1)


def build_combo_box_text(selected, sort_alphabetically, *values):
    """
    builds a GtkComboBox and model containing the supplied values.
    @values: a list of 2-tuples (value, name)
    """
    store = Gtk.ListStore(str, str)
    
    if sort_alphabetically:
        store.set_sort_column_id(0, Gtk.SortType.ASCENDING)

    selected_iter = None
    for (val, name) in values:
        _iter = store.append((val, name))
        if val == selected:
            selected_iter = _iter

    combo = Gtk.ComboBox(model=store)
    renderer = Gtk.CellRendererText()
    combo.pack_start(renderer, True)
    combo.add_attribute(renderer, 'markup', 1)
    if selected_iter:
        combo.set_active_iter(selected_iter)

    return combo


def make_combo_list(opts, title):
    """
    Turns a list of values into a list of value,name (where name is the
    display name a user will see in a combo box). If a value is opt is
    equal to that supplied in default the display name for that value is
    modified to "value <i>(default)</i>"

    @opts: a list of value
    @returns: a list of 2-tuples (value, name)
    """

    themes = []
    for t in opts:
        if t.lower() == 'default':

            # some themes etc are actually called default. Dont show them if they
            # are not the actual default value

            continue

        if title and len(t):
            name = t[0].upper() + t[1:]
        else:
            name = t

        themes.append((t, name))

    return themes


def remove_zorin_themes(all_themes):
    for i in theme.ZORIN_THEMES:
        try:
            all_themes.remove(i[0])
        except ValueError as e:
            pass

    if 'Zorin' in all_themes:
        all_themes.remove('Zorin')
