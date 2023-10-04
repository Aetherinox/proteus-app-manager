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

from os.path import dirname, basename, isfile
import glob
modules = glob.glob(dirname(__file__) + '/*.py')
__all__ = [basename(f)[:-3] for f in modules if isfile(f) and f != '__init__.py']
__all__.sort()
