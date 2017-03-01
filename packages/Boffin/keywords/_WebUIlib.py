#    Copyright (c) 2013 Mirantis, Inc
#
#    Licensed under the Apache License, Version 2 0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www apache org/licenses/LICENSE-2 0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License

from time import sleep

from robot.libraries.BuiltIn import BuiltIn

from _Utils import _Utils


# Decorator for framed elements.
def _framed(framed_element_name):
    def real_framed(function):
        def wrapper(self, *args):
            co_varnames = function.func_code.co_varnames
            upper_varnames = [varnames.upper() for varnames in co_varnames]
            index = upper_varnames.index(framed_element_name.upper())

            element_frame = \
                self.get_web_element_frame(args[index - 1])
            if element_frame:
                self.set_current_frame(element_frame)

            res = function(self, *args)

            if element_frame:
                self.unselect_frame()

            return res

        return wrapper

    return real_framed


class _WebUIlib(_Utils):

    def navigate_to(self, path, dont_wait=None):
        """
        Navigates to the page by given links sequence.

        *Arguments:*
            - path: sequence of links separated by '>'.
            - dont_wait: optional parameter. Should be set to skip waiting \
            for page loaded.

        *Return:*
            - None.

        *Examples:*
        | Navigate to | Careers>Account Executive |
        """
        links = path.split('>')

        for link in links:
            self.click_link(link)
            self.wait_for_page_loaded(dont_wait)

    @_framed('over_element_name')
    def click_on_submenu(self, over_element_name, name, dont_wait=None):
        """
        Puts mouse over menu element and then clicks on submenu element by \
        given selector names and waits for page loaded if needed.

        *Arguments:*
            - over_element_name: menu selector title taken from object \
            repository.
            - name: submenu selector title taken from object repository.
            - dont_wait: optional parameter. Should be set to skip waiting \
            for page loaded.

        *Return:*
            - None.

        *Examples:*
        | Click on submenu | Settings | Profile |
        """
        self.put_mouse_over(over_element_name)
        sleep(1)
        self.click_on(name)
        self.wait_for_page_loaded(dont_wait)

    def click_on_link(self, link, dont_wait=None):
        """
        Clicks the link by given localor and waits for page loaded if needed.

        *Arguments:*
            - link: this attribute can contain one of following: id, name, \
            href or link text.
            - dont_wait: optional parameter. Should be set to skip waiting \
            for page loaded.

        *Return:*
            - None.

        *Examples:*
        | Click on link | Move to Trash |
        | Click on link | Delete | don't wait |
        """
        self.wait_for_element_found(link, 'a', 'this')
        self.click_link(link)
        self.wait_for_page_loaded(dont_wait)

    def wait_for_page_loaded(self, dont_wait=None, page_load_timeout=60):
        """
        Waits for 'complete' page state during predefined page load timeout.

        Does not wait for page loading if wait argument is set to any value \
        except the ${empty}.

        *Arguments:*
            - dont_wait: optional parameter. Should be set to skip waiting \
            for page loaded.
            - page_load_timeout: optional parameter. Timeout for page loading.

        *Return:*
            - None.

        *Examples:*
        | Wait for page loaded |
        | Wait for page loaded | don't wait |
        """
        ajax_wait_timeout = \
            BuiltIn().get_variable_value('${ajax_wait_timeout}')

        if ajax_wait_timeout:
            self.wait_for_condition('return window.jQuery.active == 0',
                                    ajax_wait_timeout,
                                    'Ajax request was not loaded in '
                                    '%s second(s)' % ajax_wait_timeout)

        if not dont_wait:
            self.wait_for_condition('return document.readyState == "complete"',
                                    page_load_timeout,
                                    'Page was not loaded in '
                                    '%s second(s)' % page_load_timeout)

    def title_should_contain(self, text):
        """
        Verifies that current page title contains given text.

        *Arguments:*
            - text: text which should be in the title set in test case.

        *Return:*
            - None.

        *Examples:*
        | Title should contain | Account Executive |
        """
        title = self.get_title()
        BuiltIn().should_contain(title, text)

    @_framed('name')
    def click_on(self, name, dont_wait=None):
        """
        Clicks the element by given selector name and waits for page loaded \
        if needed.

        *Arguments:*
            - name: selector title taken from object repository.
            - dont_wait: optional parameter. Should be set to skip waiting \
            for page loaded.

        *Return:*
           - None.

        *Examples:*
        | Click on | Dashboard . Users button |
        """
        selector = self.wait_for_element_found(name, 'button/input/a', 'this')
        self.click_element(selector)
        self.wait_for_page_loaded(dont_wait)

    def set_current_frame(self, name):
        """
        Sets frame identified by given selector name as current frame.

        *Arguments:*
            - name: selector title taken from object repository.

        *Return:*
            - None.

        *Examples:*
        | Set current frame | Post Editor Frame |
        """
        selector = self.get_web_element_selector(name)
        self.select_frame(selector)

    def element_text_should_contain(self, name, text):
        """
        Verifies that element with given selector type contains the given text.

        *Arguments:*
            - name: selector title taken from object repository.
            - text: text to be found set in test.

        *Return:*
            - None.

        *Examples:*
        | Element Text Should Contain | Dashboard . Message text | \
        Post Updated |
        """
        selector = self.get_web_element_selector(name)
        self.element_should_contain(selector, text)

    def element_text_should_be_equal_to(self, name, text):
        """
        Verifies that element with given selector type equals to the \
        given text.

        *Arguments:*
            - name: selector title taken from object repository.
            - text: text to be found set in test.

        *Return:*
        - None.

        *Examples:*
        | Element Text Should Be Equal To | Dashboard . Message text | \
        User deleted |
        """
        selector = self.get_web_element_selector(name)
        self.element_text_should_be(selector, text)

    def element_text_should_not_contain(self, name, text):
        """
        Verifies that element with given selector type not contain the \
        given text.

        *Arguments:*
            - name: selector title taken from object repository.
            - text: text to be found set in test.

        *Return:*
            - None.

        *Examples:*
        | Element Text Should Not Contain | Dashboard . Message text \
        | Post Updated. |
        """
        selector = self.get_web_element_selector(name)
        self.element_should_not_contain(selector, text)

    def element_text_should_not_be_equal_to(self, name, text):
        """
        Verifies that element text with given selector type not qual to the \
        given text.

        *Arguments:*
            - name: selector title taken from object repository.
            - text: text to be found set in test.

        *Return:*
            - None.

        *Examples:*
        | Element Text Should Not Be Equal To | Dashboard . Message text \
        | Post Updated. |
        """
        selector = self.get_web_element_selector(name)
        self.element_text_should_not_be(selector, text)

    def element_should_not_contain(self, selector, text):
        """
        Verifies element identified by given selector does not contain \
        given text.

        *Arguments:*
            - selector: element identificator in the object repository.
            - text: text to be checked.

        *Return:*
            - None.

        *Examples:*
        | Element Should Not Contain | xpath=//div[@id='moderated']/p \
        | rude message |
        """
        obj_text = self.get_text(selector)
        BuiltIn().should_not_contain(obj_text, text)

    def element_text_should_not_be(self, selector, text):
        """
        Verifies element identified by given selector does not equal to the \
        given text.

        *Arguments:*
            - selector: element identificator in the object repository.
            - text: text to be checked.

        *Return:*
            - None.

        *Examples:*
        | Element Should Not Be | xpath=//div[@id='moderated']/p \
        | rude message |
        """
        obj_text = self.get_text(selector)
        BuiltIn._should_not_be_equal(obj_text, text)

    def page_should_have_number_of_elements(self, count, name):
        """
        Verifies that current page contains given number of elements with \
        given selector type.

        *Arguments:*
            - count: number of element to be found.
            - name: selector title taken from object repository.

        *Return:*
            - None.

        *Examples:*
        | Page should have number of elements | 4 | Banner Buttons |
        """
        element = self.get_element_from_repo(name)
        self.xpath_should_match_x_times(element[1], count)

    def page_should_have_element(self, name):
        """
        Verifies that current page contains given element.

        *Arguments:*
            - name: selector title taken from object repository.

        *Return:*
            - None.

        *Examples:*
        | Page should have element | Contact Us button |
        """
        selector = self.get_web_element_selector(name)
        self.page_should_contain_element(selector)

    def page_should_not_have_element(self, name):
        """
        Verifies that current page does not contain given element.

        *Arguments:*
            - name: selector title taken from object repository.

        *Return:*
            - None.

        *Examples:*
        | Page should not have element | Contact Us button |
        """
        selector = self.get_web_element_selector(name)
        self.page_should_not_contain_element(selector)

    def put_mouse_over(self, name):
        """
        Simulates hovering mouse over the element specified by selector name.

        *Arguments:*
            - name: selector title taken from object repository.

        *Return:*
            - None.

        *Examples:*
        | Put mouse over | Dashboard . Posts button |
        """
        selector = self.get_web_element_selector(name)
        self.mouse_over(selector)

    @_framed('field_name')
    def fill_field(self, field_name, text):
        """
        Gets element by its field name and fills it with given text.
            Note: If field name will be 'password' then \
            ${text} won't be logged.

        *Arguments:*
            - field_name: selector title taken from object repository.
            - text: text to be entered into field.

        *Return:*
            - None.

        *Examples:*
        | Fill field | Dashboard . New Post Title field | Test blog-post |
        """
        selector = self.wait_for_element_found(field_name, 'input/textarea',
                                               'next')

        if 'PASSWORD' in field_name.upper():
            self.input_password(selector, text)
        else:
            self.input_text(selector, text)

    def wait_for_element_found(self, element_name, element_type, method):
        """
        Makes 10 retries to get element by its name with defined retry \
        interval (1 second).

        *Arguments:*
            - element_name: selector title taken from object repository;
            - element_type: element tag, could take several tags at once \
            (e.g. select/input/a);
            - method: a method of how to search for the element.

        *Return:*
            - selector: element identificator from object repository.

        *Examples:*
        | ${selector} | Wait for element found | Dashboard Menu Title field \
        | input | next |
        """
        for attempt in range(10):
            try:
                page_source_code = self.get_source()
                selector = self.get_web_element_selector(element_name,
                                                         page_source_code,
                                                         element_type,
                                                         method)
            except:
                pass
            if selector:
                break

            sleep(1)

        if not selector:
            BuiltIn().run_keyword('Capture Page Screenshot')
            raise AssertionError('Web element "%s" was not found in object '
                                 'repository and on page.' % element_name)

        return selector

    @_framed('name')
    def select_item_from_list(self, name, item_name):
        """
        Selects specified item from given list.

        *Arguments:*
            - name: selector title taken from object repository.
            - item_name: list box item.

        *Return:*
            - None.

        *Examples:*
        | Select item from list | Dashboard . User Action dropdown | Delete |
        """
        selector = self.wait_for_element_found(name, 'select', 'next')
        self.select_from_list(selector, item_name)

    @_framed('name')
    def set_checkbox_on(self, name):
        """
        Set checkbox with given title on.

        *Arguments:*
            - name: selector title taken from object repository.

        *Return:*
            - None.

        *Examples:*
        | Set checkbox on | Dashboard . Delete Posts Role checkbox |
        """
        selector = self.wait_for_element_found(name, 'select', 'previous')
        self.select_checkbox(selector)

    @_framed('name')
    def set_checkbox_off(self, name):
        """
        Set checkbox with given title off.

        *Arguments:*
            - name: selector title taken from object repository.

        *Return:*
            - None.

        *Examples:*
        | Set checkbox off | Dashboard . Delete Posts Role checkbox |
        """
        selector = self.wait_for_element_found(name, 'select', 'previous')
        self.unselect_checkbox(selector)

    @_framed('from_name')
    def drag_and_drop_to(self, from_name, to_name):
        """
        Drags and drops from one given element to other.

        *Arguments:*
            - from_name: selector title taken from object repository to get \
            content from;
            - to_name: selector title taken from object repository to put \
            content to.

        *Return:*
            - None.

        *Examples:*
        | Drag And Drop To | Photo gallery | User avatar |
        """
        from_selector = self.wait_for_element_found(from_name,
                                                    'button/input/a/img/div',
                                                    'this')
        to_selector = self.wait_for_element_found(to_name,
                                                  'button/input/a/img/div',
                                                  'this')
        self.drag_and_drop_to(from_selector, to_selector)

    def find_associated_element(self, first_element, desired_element):
        """
        This method allows to find element, which located near other element \
        and returns xpath of this element.
        Sometimes we have many identical elements on page and we can find \
        correct element based on nearest unique elements.

        *Arguments:*
            - First_Element: base element, near this element we want to find \
            other element.
            - Desired_Element: this is element which we want to find.

        *Return:*
            - xpath of Desired_Element or None

        *Examples:*
        | {element_xpath} | Find Associated Element | MyUniqueElement \
        | DesiredElement |
        """
        element = self.wait_for_element_found(first_element, desired_element,
                                              'associated')

        return element

    @_framed('name')
    def select_radio_by_selector(self, name, value):
        """
        Sets selection of radio button group identified by selector name \
        to value.

        *Arguments:*
            - name: selector title taken from object repository.
            - value: value to be selected, is used for the value attribute or \
            for the id attribute.

        *Return:*
            - None.

        *Examples:*
        | Select Radio By Selector | Dashboard . Questionnaire | Yes |
        """
        selector = self.wait_for_element_found(name, 'input', 'previous')
        self.select_radio_button(selector, value)

    def get_table_row_with(self, element):
        """
        This method allows to find table row with specific element. \
        After this xpath of table row can be used like base for xpath of \
        different elements in this table.

        *Arguments:*
            - element: the unique element from table.

        *Return:*
            - xpath of table row for this element

        *Examples:*
        | {table_xpath} | Get Table Row With | MyUniqueElement |
        | Click Element \ \ | xpath={table_xpath}/td[4]/button |
        """
        source_code = self.get_source()
        result = self.get_table_row_xpath(source_code, element)

        return result

    @_framed('name')
    def element_should_be_invisible(self, name):
        """
        Verifies that element is invisible on the page.

        *Arguments:*
            - name: selector title taken from object repository.

        *Return:*
            - None.

        *Examples:*
        | Element Should Be Invisible | Dashboard . Post Publish button |
        """
        selector = self.wait_for_element_found(name,
                                               'button/input/a/img',
                                               'this')
        self.element_should_not_be_visible(selector)

    @_framed('name')
    def element_should_not_be_invisible(self, name):
        """
        Verifies that element is visible on the page.

        *Arguments:*
            - name: selector title taken from object repository.

        *Return:*
            - None.

        *Examples:*
        | Element Should Not Be Invisible | Dashboard . Post Publish button |
        """
        selector = self.wait_for_element_found(name,
                                               'button/input/a/img',
                                               'this')
        self.element_should_be_visible(selector)

    @_framed('name')
    def get_element_text(self, name):
        """
        Gets text of given element.

        *Arguments:*
            - name: selector title taken from object repository.

        *Return:*
            - text of element.

        *Examples:*
        | ${text} | Get Element Text | Main header |
        """
        selector = self.wait_for_element_found(name,
                                               'button/input/a/img',
                                               'this')
        text = self.get_text(selector)

        return text

    @_framed('name')
    def get_attribute_of_element(self, name, attribute):
        """
        Gets attribute of given element.

        *Arguments:*
            - name: selector title taken from object repository.
            - attribute: attribute that would be taken.

        *Return:*
            - text of element attribute.

        *Examples:*
        | ${id_text} | Get Attribute Of Element | Main header | id |
        """
        selector = self.wait_for_element_found(name,
                                               'button/input/a/img',
                                               'this')
        attr_selector = '%s@%s' % (selector, attribute)
        attr_text = self.get_element_attribute(attr_selector)

        return attr_text
