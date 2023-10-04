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


class ZorinTouchShell(layout.Layout, Gtk.Box):

    __metaclass__ = layout.LayoutBox

    environment = 'zorin:GNOME'

    def __init__(self):
        Gtk.Box.__init__(self)

        self.enabled_extensions = ['zorin-taskbar@zorinos.com']
        self.disabled_extensions = \
            ['zorin-dash@zorinos.com',
             'zorin-menu@zorinos.com',
             'zorin-hide-activities-move-clock@zorinos.com']
            
        self.settings = [
            ('org.gnome.shell.extensions.zorin-panel', 'location-clock',
             GLib.Variant('s', 'STATUSRIGHT')),
            ('org.gnome.shell.extensions.zorin-panel',
             'show-activities-button', GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'taskbar-position',
             GLib.Variant('s', 'CENTEREDMONITOR')),
            ]
            
        self.settings = [
            ('org.gnome.desktop.wm.preferences', 'button-layout',
             GLib.Variant('s', 'appmenu:minimize,maximize,close')),
            ('org.gnome.desktop.interface', 'enable-hot-corners',
             GLib.Variant('b', False)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'panel-size',
             GLib.Variant('i', 48)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'animate-show-apps',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'activate-single-window',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'click-action',
             GLib.Variant('s', 'TOGGLE-SHOWPREVIEW')),
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
             GLib.Variant('s', '{"0":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":true,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"centerMonitor"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}],"1":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":true,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"centerMonitor"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}]}')),
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
             GLib.Variant('b', False)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'window-preview-size',
             GLib.Variant('i', 200)),
            ('org.gnome.nautilus.preferences', 'click-policy',
             GLib.Variant('s', 'single'))
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

        # Panel menu icon
        cr.set_line_width(4)
        cr.rectangle(4, layout.LAYOUT_PREVIEW_HEIGHT - 12, 8, 8)
        cr.stroke()

        # Panel activities icon
        cr.rectangle(18, layout.LAYOUT_PREVIEW_HEIGHT - 10, 4, 4)
        cr.fill()

        # Panel app icons
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 2, layout.LAYOUT_PREVIEW_HEIGHT - 10, 4, 4)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 10, layout.LAYOUT_PREVIEW_HEIGHT - 10, 4, 4)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 6, layout.LAYOUT_PREVIEW_HEIGHT - 10, 4, 4)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 18, layout.LAYOUT_PREVIEW_HEIGHT - 10, 4, 4)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 14, layout.LAYOUT_PREVIEW_HEIGHT - 10, 4, 4)
        cr.fill()

        # Indicators
        cr.rectangle(layout.LAYOUT_PREVIEW_WIDTH - 34,
                     layout.LAYOUT_PREVIEW_HEIGHT - 9, 30, 2)
        cr.fill()

        # Search bar
        cr.set_line_width(2)
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 17, 9, 34, 6)
        cr.stroke()

        # Grid app icons
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 18, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 18, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 6, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 18, 12, 12)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 18, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 6, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 6, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 6, 12, 12)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 42, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 18, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 30, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 18, 12, 12)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 42, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 6, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 30, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 6, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 18, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 42, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 6, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 42, 12, 12)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 18, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 30, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 6, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 30, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 42, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 42, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 30, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 42, 12, 12)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 42, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 30, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 30, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 30, 12, 12)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 66, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 18, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 54, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 18, 12, 12)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 66, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 6, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 54, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 6, 12, 12)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 66, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 42, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 54, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) - 42, 12, 12)
        cr.fill()
        
        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) - 66, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 30, 12, 12)
        cr.fill()

        cr.rectangle(round(layout.LAYOUT_PREVIEW_WIDTH / 2) + 54, round(layout.LAYOUT_PREVIEW_HEIGHT / 2) + 30, 12, 12)
        cr.fill()
