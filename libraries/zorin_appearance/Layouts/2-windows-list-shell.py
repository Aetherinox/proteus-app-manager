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


class WindowsListShell(layout.Layout, Gtk.Box):

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
             GLib.Variant('s', 'ALL')),
            ('org.gnome.shell.extensions.zorin-taskbar', 'panel-size',
             GLib.Variant('i', 40)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'activate-single-window',
             GLib.Variant('b', True)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'click-action',
             GLib.Variant('s', 'CYCLE-MIN')),
            ('org.gnome.shell.extensions.zorin-taskbar', 'dot-style-focused',
             GLib.Variant('s', 'CILIORA')),
            ('org.gnome.shell.extensions.zorin-taskbar', 'dot-style-unfocused',
             GLib.Variant('s', 'DOTS')),
            ('org.gnome.shell.extensions.zorin-taskbar', 'group-apps',
             GLib.Variant('b', False)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'group-apps-label-max-width',
             GLib.Variant('i', 160)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'group-apps-use-fixed-width',
             GLib.Variant('b', False)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'group-apps-use-launchers',
             GLib.Variant('b', False)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'intellihide',
             GLib.Variant('b', False)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'multi-monitors',
             GLib.Variant('b', False)),
            ('org.gnome.shell.extensions.zorin-taskbar', 'panel-element-positions',
             GLib.Variant('s', '{"0":[{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}],"1":[{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}]}')),
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
        cr.move_to(2, layout.LAYOUT_PREVIEW_HEIGHT - 9)
        cr.line_to(layout.LAYOUT_PREVIEW_WIDTH - 2,
                   layout.LAYOUT_PREVIEW_HEIGHT - 9)
        cr.stroke()
        cr.move_to(0, 0)

        # Menu
        cr.set_line_width(2)
        cr.rectangle(5, layout.LAYOUT_PREVIEW_HEIGHT - 83, 60, 70)
        cr.stroke()

        # Menu icon 1
        cr.rectangle(8, layout.LAYOUT_PREVIEW_HEIGHT - 80, 4, 4)
        cr.fill()

        # Menu text 1
        cr.rectangle(14, layout.LAYOUT_PREVIEW_HEIGHT - 79, 15, 2)
        cr.fill()

        # Menu icon 2
        cr.rectangle(8, layout.LAYOUT_PREVIEW_HEIGHT - 72, 4, 4)
        cr.fill()

        # Menu text 2
        cr.rectangle(14, layout.LAYOUT_PREVIEW_HEIGHT - 71, 10, 2)
        cr.fill()

        # Menu icon 3
        cr.rectangle(8, layout.LAYOUT_PREVIEW_HEIGHT - 64, 4, 4)
        cr.fill()

        # Menu text 3
        cr.rectangle(14, layout.LAYOUT_PREVIEW_HEIGHT - 63, 12, 2)
        cr.fill()

        # Menu icon 4
        cr.rectangle(8, layout.LAYOUT_PREVIEW_HEIGHT - 56, 4, 4)
        cr.fill()

        # Menu text 4
        cr.rectangle(14, layout.LAYOUT_PREVIEW_HEIGHT - 55, 11, 2)
        cr.fill()

        # Menu icon 5
        cr.rectangle(8, layout.LAYOUT_PREVIEW_HEIGHT - 48, 4, 4)
        cr.fill()

        # Menu text 5
        cr.rectangle(14, layout.LAYOUT_PREVIEW_HEIGHT - 47, 9, 2)
        cr.fill()

        # Menu icon 6
        cr.rectangle(8, layout.LAYOUT_PREVIEW_HEIGHT - 40, 4, 4)
        cr.fill()

        # Menu text 6
        cr.rectangle(14, layout.LAYOUT_PREVIEW_HEIGHT - 39, 14, 2)
        cr.fill()

        # Menu icon 7
        cr.rectangle(8, layout.LAYOUT_PREVIEW_HEIGHT - 32, 4, 4)
        cr.fill()

        # Menu text 7
        cr.rectangle(14, layout.LAYOUT_PREVIEW_HEIGHT - 31, 8, 2)
        cr.fill()

        # Menu icon 8
        cr.rectangle(8, layout.LAYOUT_PREVIEW_HEIGHT - 24, 4, 4)
        cr.fill()

        # Menu text 8
        cr.rectangle(14, layout.LAYOUT_PREVIEW_HEIGHT - 23, 10, 2)
        cr.fill()

        # Menu right text 1
        cr.rectangle(44, layout.LAYOUT_PREVIEW_HEIGHT - 79, 10, 2)
        cr.fill()

        # Menu right text 2
        cr.rectangle(44, layout.LAYOUT_PREVIEW_HEIGHT - 71, 14, 2)
        cr.fill()

        # Menu right text 3
        cr.rectangle(44, layout.LAYOUT_PREVIEW_HEIGHT - 63, 8, 2)
        cr.fill()

        # Menu right text 4
        cr.rectangle(44, layout.LAYOUT_PREVIEW_HEIGHT - 55, 12, 2)
        cr.fill()

        # Menu right text 5
        cr.rectangle(44, layout.LAYOUT_PREVIEW_HEIGHT - 47, 15, 2)
        cr.fill()

        # Menu right text 6
        cr.rectangle(44, layout.LAYOUT_PREVIEW_HEIGHT - 39, 11, 2)
        cr.fill()

        # Menu right text 7
        cr.rectangle(44, layout.LAYOUT_PREVIEW_HEIGHT - 31, 12, 2)
        cr.fill()

        # Menu right text 8
        cr.rectangle(44, layout.LAYOUT_PREVIEW_HEIGHT - 23, 10, 2)
        cr.fill()

        # Panel menu icon
        cr.set_line_width(2)
        cr.rectangle(3, layout.LAYOUT_PREVIEW_HEIGHT - 8, 6, 6)
        cr.stroke()

        # Panel app text 1
        cr.rectangle(14, layout.LAYOUT_PREVIEW_HEIGHT - 6, 32, 2)
        cr.fill()

        # Panel app text 2
        cr.rectangle(50, layout.LAYOUT_PREVIEW_HEIGHT - 6, 32, 2)
        cr.fill()

        # Panel app text 3
        cr.rectangle(86, layout.LAYOUT_PREVIEW_HEIGHT - 6, 32, 2)
        cr.fill()

        # Indicators
        cr.rectangle(layout.LAYOUT_PREVIEW_WIDTH - 34,
                     layout.LAYOUT_PREVIEW_HEIGHT - 6, 30, 2)
        cr.fill()
