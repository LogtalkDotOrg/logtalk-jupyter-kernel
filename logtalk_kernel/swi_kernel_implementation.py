#############################################################################
#
#  Copyright (c) 2022-2023 Paulo Moura  
#  Copyright (c) 2022 Anne Brecklinghaus, Michael Leuschel, dgelessus
#  SPDX-License-Identifier: MIT
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in all
#  copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.
#
#############################################################################


"""
Default SWI-Prolog kernel implementation.

Defines the inspection for other predicates than the ones defined in the module jupyter.
"""


from logtalk_kernel.logtalk_kernel_base_implementation import LogtalkKernelBaseImplementation

# When overriding this at a different location, add the location of the logtalk_kernel_base_implementation.py file defining the LogtalkKernelBaseImplementation class to the search path for modules
#sys.path.append('/path/to/kernel/logtalk_kernel/logtalk_kernel')
#from logtalk_kernel_base_implementation import LogtalkKernelBaseImplementation


class LogtalkKernelImplementation(LogtalkKernelBaseImplementation):

    def do_inspect(self, code, cursor_pos, detail_level=0, omit_sections=()):
        """
        For SWI-Prolog, help for a predicate can be accessed with help/1.
        When inspecting a token, the output of this predicate precedes the docs for predicates from module jupyter.
        """
        # Get the matching predicates from module jupyter
        token, jupyter_data = self.get_token_and_jupyter_predicate_inspection_data(code, cursor_pos)

        if not token:
            # There is no token which can be inspected
            return {'status': 'ok', 'data': {}, 'metadata': {}, 'found': False}

        try:
            # Request predicate help with help/1
            response_dict = self.server_request(0, 'call', {'code':'help(' + token + ')'})
            help_output = response_dict["result"]["1"]["output"]

        except Exception as exception:
            self.logger.error(exception, exc_info=True)
            help_output = ''

        found = True

        if help_output == '':
            # There is no help/1 ouput
            if jupyter_data == {}:
                data = {}
                found = False
            else:
                data = jupyter_data
        else:
            # There is help/1 ouput
            jupyter_docs_plain = help_output
            jupyter_docs_md = '<pre>' + help_output.replace('\n', '<br>').replace('$', '&#36;') + '</pre>'

            if jupyter_data != {}:
                # Append the jupyter docs
                jupyter_docs_plain += '\n\n' + '_'*80 + '\n\n' + jupyter_data['text/plain']
                jupyter_docs_md += '<br>' + '_'*80 + '<br><br>' + jupyter_data['text/markdown']

            data = {'text/plain': jupyter_docs_plain, 'text/markdown': jupyter_docs_md}

        return {'status': 'ok', 'data': data, 'metadata': {}, 'found': found}
