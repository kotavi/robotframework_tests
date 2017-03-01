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
from setuptools import setup

execfile(join(dirname(__file__), 'src', 'Boffin', 'version.py'))

setup(
    name='robotframework-boffin',
    version=VERSION,
    author='Mirantis, Inc.',
    license='Apache License 2.0',
    description='Extension for Robot Framework',
    long_description=open('README.rst').read(),
    package_dir={'': 'src'},
    packages=['Boffin', 'Boffin.keywords'],
    install_requires=['robotframework>=2.8.1',
                      'selenium>=2.33.0',
                      'robotframework-selenium2library>=1.2.0',
                      'robotframework-pydblibrary>=1.1',
                      'beautifulsoup4>=4.2.1',
                      'requests>=1.2.0', 'robot'],
    platforms='any',
    zip_safe=False
)
