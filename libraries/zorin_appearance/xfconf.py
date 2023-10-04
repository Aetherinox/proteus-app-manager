# This file is part of the Zorin Appearance program.
#
# Copyright 2017-2019 Zorin OS Technologies Ltd.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.

import dbus
from dbus.mainloop.glib import DBusGMainLoop


class XfconfSetting:

    def __init__(self):
        DBusGMainLoop(set_as_default=True)

        self.bus = dbus.SessionBus()
        self.xfconf = dbus.Interface(self.bus.get_object('org.xfce.Xfconf',
                                     '/org/xfce/Xfconf'), 'org.xfce.Xfconf')
