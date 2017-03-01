#    Copyright (c) 2013 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.


from os.path import join, dirname

from Selenium2Library import Selenium2Library

from _Settings import _SettingsReader
from keywords import *

execfile(join(dirname(__file__), 'version.py'))

__version__ = VERSION

_SettingsReader.read()


class WebUIlib(Selenium2Library, _WebUIlib):
    """
    This class supports WebUi related testing using the Robot Framework.
    """

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION


class Rest(_Rest):
    """
    This class supports Rest related testing using the Robot Framework.
    """

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION


class DB(Pydblibrary):
    """
    This library supports database-related testing using the Robot Framework.
    """

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = VERSION
