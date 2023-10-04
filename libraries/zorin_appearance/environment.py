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

import os
from zorin_appearance.gshellwrapper import GnomeShell, GnomeShellFactory

_shell = GnomeShellFactory().get_shell()
_shell_loaded = _shell is not None

_desktop_environment = os.environ['XDG_CURRENT_DESKTOP']

def _get_shell_extension(
    extension_uuid
    ):
    extensions = _shell.list_extensions().values()
    ext = None

    for extension in extensions:
        if extension.get("uuid") == extension_uuid:
            ext = extension

    return ext
