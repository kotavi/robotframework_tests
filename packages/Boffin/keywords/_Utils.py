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

from ConfigParser import ConfigParser
from os import getcwd
from os.path import join
from bs4 import BeautifulSoup
from robot.libraries.BuiltIn import BuiltIn


class _ArtificialIntelligence:
    """
    This class allows to find input and select controls \
    without manual input of identificators.
    We can find input fields by labels near those fields. \
    Boffin heart.
    """

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'

    def __init__(self, page_source):
        """
        Class constructor.

        *Arguments:*
            - page_source: web page source code.

        *Return:*
            - None.
        """
        self.page_source = page_source

    def _get_xpath_of_element(self, element):
        """
        This function allows to get xpath of soup elements.

        *Arguments:*
            - element: selector name.

        *Return:*
            - element xpath.
        """

        number = 1
        try:
            number += len(element.find_previous_siblings(element.name))
        except:
            pass

        xpath = element.name
        if number > 1:
            xpath += '[' + str(number) + ']'

        for parent in element.findParents():
            if parent.name != '[document]':
                k = 0
                for tag in parent.find_previous_siblings():
                    if tag.name == parent.name:
                        k += 1
                if k == 0:
                    xpath = parent.name + '/' + xpath
                else:
                    xpath = parent.name + '[' + str(k + 1) + ']/' + xpath

        return xpath

    def extra_search(self, soup, value, tag=None):
        """
        This function allows to get element by its parameters.

        *Arguments:*
            - soup: soup structure.
            - value: element name.

        *Return:*
            - label_element.
        """

        label_element = None

        if label_element is None:
            label_element = soup.find(tag, text=str(value))
        if label_element is None:
            label_element = soup.find(tag, attrs={'value': value})
        if label_element is None:
            label_element = soup.find(tag, attrs={'title': value})

        if label_element is None:
            try:
                for element in soup.find_all(tag):
                    if str(value) in element.text:
                        label_element = element
            except:
                pass

        return label_element

    def find_element(self, label, element_type='input', method='next',
                     result='xpath'):
        """
        Looks for specified element on the page.

        *Arguments:*
            - label: selector name.
            - element_type: element tag name. It could be any tag or \
            several tags (then they are listed as 'select/input/a').
            - method: element search method. If 'next' is set, then \
            function is looking for the next input field after the \
            specified element.
            Otherwise it returns the specified element itself.

        *Return:*
            - element xpath.

        *Examples:*
        | ${xpath} | Find element | E-mail | input | next |
        | ${xpath} | Find element | Cancel | a/div | this |
        """
        html = str(self.page_source.encode("utf-8", "replace"))

        " load html to soup structure for parsing "
        soup = BeautifulSoup(html)

        " search element after the label"
        try:
            element_types = element_type.split('/')
            element = None

            label_element = self.extra_search(soup, label)
            for element_type in element_types:
                if method == 'next':
                    element = label_element.parent.find_next(element_type)

                elif method == 'previous':
                    element = label_element.parent.find_previous(element_type)

                elif method == 'associated':
                    for t in ['a', 'button', 'input', 'select']:
                        elements = label_element.parent.find_all_next(t)
                        for e in elements:
                            if element_type in e.text:
                                element = e
                        if element:
                            break
                        elements = label_element.parent.find_all_previous(t)
                        for e in elements:
                            if element_type in e.text:
                                element = e
                        if element:
                            break
                else:
                    element = self.extra_search(soup, label, element_type)

                if element:
                    break

            " return xpath of element "
            if result == 'xpath':
                return self._get_xpath_of_element(element)
            else:
                return element
        except:
            return None


class _Utils(object):
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'

    def get_element_from_repo(self, element_name):
        """
        Returns element type, identificator and frame from \
        the 'resources/objrepo/%screen_name%.ini' file by element name.

        *Arguments:*
            - elementName: screen name and selector name divided by dot.

        *Return:*
            - <list> [elType, elIdentificator, elFrame].

        *Example:*
        | @{element} | Get Element From Repo | Home . Banner Page 2 Button |
        """
        try:
            p = BuiltIn().get_variable_value('${resources_path}')
            if p is not None:
                _objRepoPath = join(p, 'objrepo')
            else:
                _objRepoPath = join(getcwd(), 'resources', 'objrepo')

            element_name = element_name.lower().replace(' ', '')
            print "Element Name: " + element_name 
            inputElement = element_name.split('.')

            if len(inputElement) == 1:
                fileName = 'common.ini'
                name = element_name

            else:
                fileName = '%s.ini' % inputElement[0]
                name = inputElement[1]

            fullFileName = join(_objRepoPath, fileName)
            print "fullFileName " + fullFileName
            conf = ConfigParser()
            conf.read(fullFileName)

            print "A: " + conf.get(str(name), 'type')
            print "A: " + conf.get(name, 'type')

            if not conf.has_section(name):
                print name
                return ['', None, '']
            element_type = conf.get(name, 'type')

            element_identificator = ''
            element_parent_name = conf.get(name, 'parent')
            if element_parent_name:
                element_identificator = \
                    self.get_element_from_repo(element_parent_name)[1] + \
                    element_identificator

            element_identificator += conf.get(name, 'identificator')

            element_frame = conf.get(name, 'frame')
            return [element_type, element_identificator, element_frame]
        except:
            return ['', None, '']

    def get_web_element_frame(self, elementName):
        """
        Returns element frame by its name in the
        'resources/objrepo/%screen_name%.ini' file.

        *Arguments:*
            - elementName: screen name and selector name divided by dot.

        *Return:*
            - elFrame.

        *Example:*
        | ${elFrame} | GetElementFrame | Blog . Post Text field |
        """
        type, id, frame = self.get_element_from_repo(elementName)
        return frame

    def get_web_element_selector(self, name, page_source=None,
                                 element_type='input', method='next',
                                 result='xpath'):
        """
        Returns element selector by its name in the \
        'resources/ObjRepo.ini' file.

        *Arguments:*
            - name: selector name.
            - page_source: web page source code.
            - element_type: element tag name. It could be any tag or several \
             tags (then they are listed as 'select/input/a').
            - method: element search method. If 'next' is set, then function
             is looking for the next input field after the specified element.
             Otherwise it returns the specified element itself.

        *Return:*
            - elIdentificator.

        *Examples:*
        | ${selector} | Get element selector | User Name | ${source_code} \
        | input | next |
        | ${selector} | Get element selector | Submit Button | ${source_code} \
        | a | this |
        """
        type, id, frame = self.get_element_from_repo(name)

        if not id and page_source:
            boffin = _ArtificialIntelligence(page_source)
            id = boffin.find_element(name, element_type, method, result)
            if result != 'xpath':
                return id
            if id:
                type = 'xpath'

        identificator = None
        if id:
            identificator = '%s%s' % \
                            ('' if not type else '%s=' % str(type), str(id))

        return identificator

    def get_table_row_xpath(self, page_source, name):
        """
        This method allows to parse tables on web pages \
        and determine the table row by element from table.

        *Arguments:*
            - page_source: web page source code.
            - name: identificator of row element.

        *Return:*
            - xpath of table row.

        *Example:*
        | ${elXpath} | Get Table Row Xpath | Entity 123 |
        """
        _type = 'td/a/label/input/select'
        element = self.get_web_element_selector(name, page_source,
                                            _type, method='this',
                                            result='element')
        tag = element.name
        while tag != 'tr' and tag:
            try:
                tag = element.parent.name
                element = element.parent
            except:
                tag = None
                pass

        e = _ArtificialIntelligence(page_source)
        return e._get_xpath_of_element(element)
