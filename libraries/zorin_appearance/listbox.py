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
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk


class ListBoxRow(Gtk.ListBoxRow):

    def __init__(self, left, right):
        Gtk.ListBoxRow.__init__(self)

        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL,
                      spacing=18)
        box.set_hexpand(True)
        box.set_margin_start(12)
        box.set_margin_end(12)
        box.set_margin_top(12)
        box.set_margin_bottom(12)

        left.set_halign(Gtk.Align.START)
        left.set_valign(Gtk.Align.CENTER)
        left.set_hexpand(True)
        box.pack_start(left, True, True, 0)

        if right:
            box.pack_end(right, False, True, 0)

        self.add(box)
        self.set_activatable(False)


def list_box_update_header_func(row, before, user_data):
    if before == None:
        row.set_header(None)
        return

    current = row.get_header()

    if current == None:
        current = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        row.set_header(current)
