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
import zorin_appearance.Layouts.layout as layout
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gio, GLib


class WindowsXShell(layout.Layout, Gtk.Box):

    __metaclass__ = layout.LayoutBox

    environment = 'zorin:GNOME'

    def __init__(self):
        Gtk.Box.__init__(self)

        self.enabled_extensions = ['zorin-menu@zorinos.com',
                                   'zorin-taskbar@zorinos.com']
        self.disabled_extensions = \
            ['zorin-dash@zorinos.com',
             'zorin-hide-activities-move-clock@zorinos.com']
        self.settings = [
            ('org.gnome.desktop.wm.preferences', 'button-layout',
             GLib.Variant('s', 'appmenu:minimize,maximize,close')),
            ('org.gnome.desktop.interface', 'enable-hot-corners',
             GLib.Variant('b', False)),
            ('org.gnome.shell.extensions.zorin-menu', 'layout',
             GLib.Variant('s', 'APP_GRID')),
            ('org.gnome.shell.extensions.zorin-taskbar', 'panel-size',
             GLib.Variant('i', 48)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'activate-single-window',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'click-action',
             GLib.Variant('s', 'CYCLE-MIN')),
            ('org.gnome.shell.extensions.zorin-taskbar', 'dot-style-focused',
             GLib.Variant('s', 'CILIORA')),
            ('org.gnome.shell.extensions.zorin-taskbar', 'dot-style-unfocused',
             GLib.Variant('s', 'DOTS')),
            ('org.gnome.shell.extensions.zorin-taskbar', 'group-apps',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'group-apps-use-launchers',
             GLib.Variant('b', False)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'intellihide',
             GLib.Variant('b', False)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'multi-monitors',
             GLib.Variant('b', False)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'panel-element-positions',
             GLib.Variant('s', '{"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"centerMonitor"},{"element":"activitiesButton","visible":true,"position":"centerMonitor"},{"element":"taskbar","visible":true,"position":"centerMonitor"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}],"1":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"centerMonitor"},{"element":"taskbar","visible":true,"position":"centerMonitor"},{"element":"activitiesButton","visible":true,"position":"centerMonitor"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}]}')),
            ('org.gnome.shell.extensions.zorin-taskbar', 'panel-element-positions-monitors-sync',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'panel-positions',
             GLib.Variant('s', '{"0":"BOTTOM"}')),
            ('org.gnome.shell.extensions.zorin-taskbar', 'peek-mode',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'show-favorites',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'show-favorites-all-monitors',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'show-running-apps',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'show-tooltip',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'show-window-previews',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'window-preview-size',
             GLib.Variant('i', 200)),
            ('org.gnome.nautilus.preferences', 'click-policy',
             GLib.Variant('s', 'double'))
            ]
        self.enable_app_menu = False

        preview = Gtk.DrawingArea()
        preview.connect('draw', self.draw_layout_preview)
        preview.set_size_request(layout.LAYOUT_PREVIEW_WIDTH,
                                 layout.LAYOUT_PREVIEW_HEIGHT)

        self.pack_start(preview, True, False, 0)

    def draw_layout_preview(self, widget, cr):
        style_context = widget.get_style_context()
        color = style_context.get_color(Gtk.StateFlags.NORMAL)
        cr.set_source_rgba(*color)

        # Outline
        cr.set_line_width(2)
        cr.rectangle(1, 1, layout.LAYOUT_PREVIEW_WIDTH - 2,
                     layout.LAYOUT_PREVIEW_HEIGHT - 2)
        cr.stroke()

        # Panel
        cr.set_line_width(2)
        cr.move_to(2, layout.LAYOUT_PREVIEW_HEIGHT - 15)
        cr.line_to(layout.LAYOUT_PREVIEW_WIDTH - 2,
                   layout.LAYOUT_PREVIEW_HEIGHT - 15)
        cr.stroke()
        cr.move_to(0, 0)

        # Menu
        cr.set_line_width(2)
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 50, layout.LAYOUT_PREVIEW_HEIGHT - 89, 68, 70)
        cr.stroke()
               
        # Search bar
        cr.set_line_width(2)
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 42, layout.LAYOUT_PREVIEW_HEIGHT - 81, 52, 6)
        cr.stroke()
        
        # Menu app icons
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 43, layout.LAYOUT_PREVIEW_HEIGHT - 68, 6, 6)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 31, layout.LAYOUT_PREVIEW_HEIGHT - 68, 6, 6)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 19, layout.LAYOUT_PREVIEW_HEIGHT - 68, 6, 6)
        cr.fill()
   
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 7, layout.LAYOUT_PREVIEW_HEIGHT - 68, 6, 6)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 5, layout.LAYOUT_PREVIEW_HEIGHT - 68, 6, 6)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 43, layout.LAYOUT_PREVIEW_HEIGHT - 56, 6, 6)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 31, layout.LAYOUT_PREVIEW_HEIGHT - 56, 6, 6)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 19, layout.LAYOUT_PREVIEW_HEIGHT - 56, 6, 6)
        cr.fill()
   
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 7, layout.LAYOUT_PREVIEW_HEIGHT - 56, 6, 6)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 5, layout.LAYOUT_PREVIEW_HEIGHT - 56, 6, 6)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 43, layout.LAYOUT_PREVIEW_HEIGHT - 44, 6, 6)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 31, layout.LAYOUT_PREVIEW_HEIGHT - 44, 6, 6)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 19, layout.LAYOUT_PREVIEW_HEIGHT - 44, 6, 6)
        cr.fill()
   
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 7, layout.LAYOUT_PREVIEW_HEIGHT - 44, 6, 6)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 5, layout.LAYOUT_PREVIEW_HEIGHT - 44, 6, 6)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 43, layout.LAYOUT_PREVIEW_HEIGHT - 32, 6, 6)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 31, layout.LAYOUT_PREVIEW_HEIGHT - 32, 6, 6)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 19, layout.LAYOUT_PREVIEW_HEIGHT - 32, 6, 6)
        cr.fill()
   
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 7, layout.LAYOUT_PREVIEW_HEIGHT - 32, 6, 6)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 5, layout.LAYOUT_PREVIEW_HEIGHT - 32, 6, 6)
        cr.fill()
        
        # Panel menu icon
        cr.set_line_width(2)
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 19, layout.LAYOUT_PREVIEW_HEIGHT - 11, 6, 6)
        cr.stroke()

        # Panel app icons
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 2, layout.LAYOUT_PREVIEW_HEIGHT - 10, 4, 4)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 10, layout.LAYOUT_PREVIEW_HEIGHT - 10, 4, 4)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 6, layout.LAYOUT_PREVIEW_HEIGHT - 10, 4, 4)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 14, layout.LAYOUT_PREVIEW_HEIGHT - 10, 4, 4)
        cr.fill()

        # Indicators
        cr.rectangle(layout.LAYOUT_PREVIEW_WIDTH - 34,
                     layout.LAYOUT_PREVIEW_HEIGHT - 9, 30, 2)
        cr.fill()
