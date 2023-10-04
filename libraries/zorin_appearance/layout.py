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
from gi.repository import Gtk, Gdk, Gio

from zorin_appearance import environment
from zorin_appearance import utils
from zorin_appearance.Layouts import *

t = gettext.translation('zorin-appearance', '/usr/share/locale', fallback=True)
_ = t.gettext


class Layouts(Gtk.Box):

    def __init__(self):
        Gtk.Box.__init__(self, orientation=Gtk.Orientation.VERTICAL,
            spacing=16,
            margin_start=16,
            margin_end=16,
            margin_left=16,
            margin_right=16,
            margin_bottom=16,
            )

        self.flowbox = Gtk.FlowBox()
        self.flowbox.set_valign(Gtk.Align.START)
        self.flowbox.set_row_spacing(32)
        self.flowbox.set_column_spacing(32)
        self.flowbox.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.flowbox.connect('child-activated', self.on_layout_changed)

        for interface_layout in layout.Layout.__subclasses__():
            if interface_layout.environment == environment._desktop_environment:
                self.flowbox.add(interface_layout())

        self.flowbox.connect('show', self.select_current_layout)

        self.pack_start(self.flowbox, True, True, 0)

    def create_layout_option(self, layout, image):
        selectable = Gtk.Box()
        selectable.pack_start(image, True, False, 0)

        return selectable

    def select_current_layout(self, flowbox):
        index = 0
        for interface_layout in self.flowbox.get_children():
            if interface_layout.get_child().is_current_layout():
                self.flowbox.select_child(interface_layout)
                return
            index += 1

        pass

    def on_layout_changed(self, box, child):
        child.get_child().on_clicked()

