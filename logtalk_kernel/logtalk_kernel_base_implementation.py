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
Base class for the actual execution of requests received by the Logtalk Jupyter kernel.
It provides code for starting a Logtalk server and communicating with it.
Additionally, code completion and inspection are implemented.

By subclassing this, basically all functionality of the Logtalk kernel can be overriden.
For further information, see 'kernel.py'.
"""


import json
import logging
import os
import platform
import subprocess
import csv
import io
import matplotlib.pyplot as plt

from graphviz import render
from IPython.core.completer import CompletionSplitter
from IPython.utils.tokenutil import line_at_cursor
from os import remove
from signal import signal, SIGINT

from http.server import BaseHTTPRequestHandler

path = os.path.dirname(__file__)  # pylint: disable=invalid-name


class LogtalkKernelBaseImplementation:
    """
    Base implementation of the Logtalk Jupyter kernel
    """

    error_ansi_escape_codes =  "\x1b[1;31m" # red and bold

    def __init__(self, kernel):
        self.kernel = kernel

        self.logger = kernel.logger
        self.logger.setLevel(logging.DEBUG)

        self.backend = kernel.backend
        self.backend_data = kernel.active_backend_data

        self.logtalk_proc = None
        self.is_server_restart_required = False

        # Run handle_signal_interrupt when the kernel is interrupted
        signal(SIGINT, self.handle_signal_interrupt)

        # Start the Logtalk server
        self.start_logtalk_server()

        self.configure_token_splitters()
        #self.retrieve_predicate_information()

    def start_logtalk_server(self):
        """Tries to (re)start the Logtalk server process with the configured arguments."""
        # Check if the Logtalk server is to be started with the default program arguments
        # Otherwise, the provided path needs to be absolute or relative to the current working directory
        program_arguments = self.backend_data["program_arguments"]
        if program_arguments == "default":
            # Use the default
            program_arguments = self.kernel.default_program_arguments[self.backend]
            # The third element of the list is the path to the Logtalk source code relative to the directory this file is located in
            # In order for it to be found, the path needs to be extended to the location of this file
            program_arguments[3] = program_arguments[3].replace("logtalk_server/loader.lgt", os.path.join(path, os.path.join("logtalk_server", "loader.lgt")))
            program_arguments[3] = program_arguments[3].replace("\\", "\\\\")

        # Log the program arguments and the directory from which the program is tried to be started
        self.logger.debug('Trying to start the Logtalk server from ' + str(os.getcwd()) + ' with arguments: ' + str(program_arguments))

        # Kill the running Logtalk server
        self.kill_logtalk_server()
        self.logtalk_proc = None

        # Start the Logtalk server
        if platform.system() == 'Windows':
            extended_program_arguments = ["pwsh.exe", "-ExecutionPolicy", "Unrestricted", "-Command"] + program_arguments
        else:
            extended_program_arguments = program_arguments
        
        self.logtalk_proc = subprocess.Popen(
            extended_program_arguments,
            stdout=subprocess.PIPE,
            stdin=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            encoding='UTF-8'
        )
        self.logger.debug(str(self.logtalk_proc))

        # Test if the server was started correctly by requesting the Prolog backend identifier
        try:
            # In case of SICStus Prolog, if the implementation is started with a file which does not exist, no response can be read
            # The kernel cannot stop from trying to read a response and therefore cannot output an error message
            backend_response_dict = self.server_request(0, 'backend', log_response=False)
            self.logger.debug("Started the Logtalk server with the '" + backend_response_dict["result"] + "' backend")
            self.is_server_restart_required = False
            # If logging is configured for the server, send a request to create a log file and thereby enable logging
            if self.kernel.server_logging == True:
                logging_response = self.server_request(0, 'enable_logging', log_response=False)
                if logging_response == 'false':
                    self.logger.debug('No log file could be created by the Logtalk server')
        except Exception as exception:
            raise Exception("The Logtalk server could not be started with the arguments " + str(program_arguments))


    def handle_signal_interrupt(self, signal_received, frame):
        self.handle_interrupt()


    def handle_interrupt(self):
        # Interrupting the kernel interrupts the running Prolog processes, so all of them need to be restarted
        self.kernel.interrupt_all()


    def kill_logtalk_server(self):
        """Kills the Logtalk server process if it is still running."""
        if self.logtalk_proc is not None:
            self.logger.debug(self.backend + ': Kill Logtalk server')
            self.logtalk_proc.kill()
            self.is_server_restart_required = True


    def configure_token_splitters(self):
        """Configures splitters which are used to determine the token which is to be completed/inspected."""
        splitter_delims = ' ,\t\n()[{]}|;\'"'
        self.completion_splitter = CompletionSplitter()
        self.completion_splitter.delims = splitter_delims
        # For the inspection additionally use ':' as a delimiter for splitting as most of the predicate names the tokens are compared to are not module name expanded
        self.inspection_splitter = CompletionSplitter()
        self.inspection_splitter.delims = splitter_delims + ':'


    def retrieve_predicate_information(self):
        """Requests information from the Logtalk server which is needed for code completion and inspection."""
        try:
            # The currently defined predicates are used for code completion
            response_dict = self.server_request(0, 'call', {'code':'jupyter::update_completion_data.'}, log_response=False)
            self.current_predicates = response_dict['result']['1']['predicate_atoms']

            # Retrieve the documentation texts which are shown when a predicate provided by the Logtalk server in the module 'jupyter' is inspected
            jupyter_predicate_docs_dict = self.server_request(0, 'jupyter_predicate_docs', log_response=False)
            self.jupyter_predicate_docs = jupyter_predicate_docs_dict["result"]

        except Exception as exception:
            self.logger.error(exception, exc_info=True)


    ############################################################################
    # Overridden kernel methods
    ############################################################################


    def do_shutdown(self, restart):
        self.kill_logtalk_server()
        return {'status': 'ok', 'restart': restart}


    def do_execute(self, code, silent, store_history=True, user_expressions=None, allow_stdin=False):
        """
        A request to execute code was received.
        The code is tried to be executed by sending it to the Logtalk server.

        If the execution is interrupted or an exception occurs, an error response is sent to the frontend.
        """
        if not silent:
            error_prefix = self.backend_data["error_prefix"]
            try:
                # Check if the server had been shutdown (because of 'halt', an interrupt, or an exception) and a server restart is necessary
                if self.is_server_restart_required:
                    self.logger.debug(self.backend + ': Restart Logtalk server')
                    self.start_logtalk_server()
                    self.send_response_display_data(self.backend_data["informational_prefix"] + 'The Logtalk server was restarted', self.error_ansi_escape_codes)

                # Send an execution request and handle the response
                response_dict = self.server_request(self.kernel.execution_count, 'call', {'code':code})
                if 'result' in response_dict:
                    reply_object = self.handle_success_response(response_dict)
                else:
                    # 'error' in response_dict:
                    reply_object = self.handle_error_response(response_dict)

            except KeyboardInterrupt:
                self.handle_interrupt()
                return {'status': 'error', 'ename' : 'interrupt', 'evalue' : '', 'traceback' : ''}
            except BrokenPipeError:
                self.logger.error(error_prefix + 'Broken pipe\n' + error_prefix + 'The Logtalk server needs to be restarted', self.error_ansi_escape_codes)
                self.is_server_restart_required = True
                self.send_response_display_data(error_prefix + 'Something went wrong\n' + error_prefix + 'The Logtalk server needs to be restarted\n', self.error_ansi_escape_codes)
                return {'status': 'error', 'ename' : 'broken pipe', 'evalue' : '', 'traceback' : ''}
            except Exception as exception:
                self.logger.error(exception, exc_info=True)
                self.is_server_restart_required = True
                self.send_response_display_data(error_prefix + 'Something went wrong\n' + error_prefix + 'The Logtalk server needs to be restarted\n', self.error_ansi_escape_codes)
                return {'status': 'error', 'ename' : 'exception', 'evalue' : '', 'traceback' : ''}
        else:
            response_dict = self.server_request(self.kernel.execution_count, 'call', {'code':code})
            if 'result' in response_dict:
               reply_object = {
                    'status': 'ok',
                    'execution_count': self.kernel.execution_count,
                    'payload': [],
                    'user_expressions': {},
                }
            else:
                # 'error' in response_dict:
                reply_object = {
                    'status' : 'error',
                    'ename' : 'error',
                    'evalue' : '',
                    'traceback' : [],
                }

        return reply_object


    def do_complete(self, code, cursor_pos):
        if self.current_predicates is None:
            return {'matches' : [],
                    'cursor_end' : cursor_pos,
                    'cursor_start' : cursor_pos,
                    'metadata' : {},
                    'status' : 'ok'}

        token = self.get_current_token(self.completion_splitter, code, cursor_pos)

        # Find the matching predicates
        # If a key of the dictionary contains the current token, the element is assumed to match
        matching_predicates = [pred for pred in self.current_predicates if (token in pred)]

        return {'matches' : matching_predicates,
                'cursor_end' : cursor_pos,
                'cursor_start' : cursor_pos - len(token),
                'metadata' : {},
                'status' : 'ok'}


    def do_inspect(self, code, cursor_pos, detail_level=0, omit_sections=()):
        """
        Inspection is supported for the predicates from module jupyter.
        By overriding this method, inspection for further predicates can be implemented.
        """
        token, data = self.get_token_and_jupyter_predicate_inspection_data(code, cursor_pos)

        if data == {}:
            found = False
        else:
            found = True

        return {'status': 'ok', 'data': data, 'metadata': {}, 'found': found}


    def get_token_and_jupyter_predicate_inspection_data(self, code, cursor_pos):
        token = self.get_current_token(self.inspection_splitter, code, cursor_pos)

        if not token:
            # There is no token which can be inspected
            data = {}
        else:
            # Find all matching predicate inspection data
            # If a key of the dictionary contains the current token, the element is assumed to match
            matching_predicate_data = {pred:self.jupyter_predicate_docs[pred] for pred in self.jupyter_predicate_docs if (token in pred)}

            if len(matching_predicate_data) == 0:
                # There is no matching predicate
                data = {}
            else:
                 # Compute plain text and markdown output for the matching predicate data
                jupyter_docs_plain = ''
                jupyter_docs_md = ''
                for pred, data in matching_predicate_data.items():
                    jupyter_docs_plain += data + '\n\n'
                    jupyter_docs_md += '<pre>' + data.replace('\n', '<br>').replace('$', '&#36;') + '<br><br></pre>'

                data = {'text/plain': jupyter_docs_plain, 'text/markdown': jupyter_docs_md}

        return token, data


    def get_current_token(self, splitter, code, cursor_pos):
        if cursor_pos is None:
            cursor_pos = len(code)
        # Get the line where the cursor is and the character offset of the start of the line
        line, offset = line_at_cursor(code, cursor_pos)
        line_cursor = cursor_pos - offset

        # Get the current token in the line
        return splitter.split_line(line, line_cursor)


    ############################################################################
    # Handle server requests and responses
    ############################################################################


    def server_request(self, id, method, params=None, log_response=True):
        """
        Sends a request to the Logtalk server, reads the JSON response, deserializes and returns it.

        If something goes wrong, raises an exception so that an error response is sent to the frontend.

        Raises
        ------
        JSONDecodeError if the response could not be deserialized
        """
        # Create a JSON-RCP Request object (https://www.jsonrpc.org/specification#request_object)
        if params is None:
            request = json.dumps({'jsonrpc':'2.0', 'id':id, 'method':method})
        else:
            request = json.dumps({'jsonrpc':'2.0', 'id':id, 'method':method, 'params':params})
        self.logger.debug('The Request object is: ' + str(request))

        # Send the request to the Logtalk server
        self.logtalk_proc.stdin.write(request)
        self.logtalk_proc.stdin.write('\n')
        self.logtalk_proc.stdin.flush()

        # Read the JSON-RCP Response object (http://www.jsonrpc.org/specification#response_object)
        response_string = self.logtalk_proc.stdout.readline()
        # Write response_string to a file for debugging
        # with open("logtalk_kernel_response_debug.txt", "a", encoding="utf-8") as debug_file:
        #     debug_file.write(response_string + "\n")
        if log_response:
            self.logger.debug('response: ' + response_string)

        try:
            return json.loads(response_string)
        except json.decoder.JSONDecodeError as exception:
            self.logger.debug('The Response object is no valid JSON object: ' + str(response_string))
            self.logger.debug(len(str(response_string)))
            self.logger.debug(ord(str(response_string)))
            raise


    def handle_success_response(self, response_dict):
        """
        Handles a success response by computing output for each term result and sending it to the frontend.

        The dictionary response_dict contains the key 'result'.
        The corresponding value contains the results of the Logtalk terms read from the cell.
        These are given as a dictionary where the keys are integers starting from 1.

        Each of the results is a dictionary with a status member which is either 'halt', 'success', or 'error'.
        For each result, a corresponding response is sent to the client.

        In case of CLPFD a variable might not have been assigned a single value, but a domain instead.
        In that case, the dictionary value of the variable is a dictionary where the value of 'dom' is a string representing the domain.
        If there is a single value, the binding is displayed by the frontend with a '=' (e.g. M = 1).
        Otherwise, it is displayed with 'in' (e.g. X in 1..3).

        Example
        ------
        For the cell code
          "member(M, [1,2,3]), print(M)."
        the result dictionary is:
        {
          "1": {
            "status": "success",
            "type": "query",
            "bindings": {
              "M": "1"
            },
            "output": ""
          }
        }
        The following variable bindings are sent to the frontend:
          M = 1

        CLPFD Example
        ------
        For the cell code
          "X in 1..7, Y #= X+X, Y #\= 3."
        the result dictionary is:
        {
          "1": {
            "status": "success",
            "type": "query",
            "bindings": {
              "X": {
                "dom": "1..7"
              },
              "Y": {
                "dom": "{2}\\/(4..14)"
              }
            },
            "output": ""
          }
        }
        The following variable bindings are sent to the frontend:
          X in 1..7,
          Y in {2}\/(4..14)
        """

        # Read the term results
        result = response_dict["result"]

        if result is None or result == '':
            return {
                'status': 'ok',
                'execution_count': self.kernel.execution_count,
                'payload': [],
                'user_expressions': {},
            }

        is_error = False
        first_error_object = None

        index = 1
        while str(index) in result:
            term_result = result[str(index)]
            status = term_result["status"]

            if status == "halt":
                # The Logtalk server was stopped, so it has to be restarted the next time code is to be executed
                self.kill_logtalk_server()
                self.send_response_display_data(self.backend_data["informational_prefix"] + 'Successfully halted')
            elif status == "error":
                is_error = True
                error_object = self.handle_error_response(term_result)
                if not first_error_object:
                    first_error_object = error_object
            elif status == "success":
                # Handle any additional data and check if the handling was successful
                additional_data_error_keys = self.handle_additional_data(term_result)
                is_error = is_error or additional_data_error_keys
                if is_error and not first_error_object:
                    first_error_object = {
                        'status' : 'error',
                        'ename' : 'error',
                        'evalue' : '',
                        'traceback' : ['The handling of additional data failed for ' + ", ".join(additional_data_error_keys)],
                    }

                # Send the output to the frontend
                output = term_result["output"]
                if output != "":
                    self.send_response_display_data(str(output))

                if term_result["type"] == "query":
                    ansi_escape_codes = ""
                    # Send the variable names and values or a success or failure response to the frontend
                    bindings = term_result["bindings"]
                    if bindings == {}:
                        if additional_data_error_keys:
                            # The handling of the additional data has failed
                            response_text = self.backend_data["failure_response"]
                            ansi_escape_codes = "\x1b[31m" # red
                        else:
                            response_text = self.backend_data["success_response"]
                    else:
                        # Read the variable values
                        variable_values = []
                        for var, val in bindings.items():
                            if isinstance(val, dict):
                                if 'dom' in val:
                                    # CLPFD: the variable has not been assigned a single value, but a domain
                                    variable_values.append(str(var) + ' in ' + str(val['dom']))
                            else:
                                variable_values.append(str(var) + ' = ' + str(val))
                        response_text = ",\n".join(variable_values)

                    self.send_response_display_data(response_text, "\x1b[1m" + ansi_escape_codes) # bold
            index = index + 1

        # If at least one of the terms caused an error, an error reply is sent to the client (corresponding to the first error which was encountered)
        if is_error:
            if first_error_object:
                return first_error_object
            else:
                return {
                    'status' : 'error',
                    'ename' : 'error',
                    'evalue' : '',
                    'traceback' : [],
                }
        else:
            return {
                'status': 'ok',
                'execution_count': self.kernel.execution_count,
                'payload': [],
                'user_expressions': {},
            }


    def handle_error_response(self, response_dict):
        """
        Handles an error response by sending an error message to the frontend.

        The dictionary response_dict contains the key 'error'.
        The corresponding value is a dictionary containing the error data.
        The member 'data' can contain members 'logtalk_message' (e.g. a more specific error message)
        and 'output' (output of the request before the error occurred).

        Example
        ------
        For the cell code
          "print(test), 3 is 1 + x."
        the error dictionary is:
        {
            "code": -4712,
            "message": "Exception",
            "data": {
                "logtalk_message": "! Type error in argument 2 of (is)/2\n! expected evaluable, but found x/0\n! goal:  3 is 1+x",
                "output": "test"
            }
        }
        """

        error = response_dict["error"]
        error_code = error['code']

        if error['data']:
            self.handle_additional_data(error['data'])

            # Send the output to the client
            if 'output' in error['data']:
                output = error['data']['output']
                self.send_response_display_data(output)
            else:
                output = ''

        if error_code == -4711:
            ename = 'failure'
            if error['data']['logtalk_message'] != '':
                output += '\n' + error['data']['logtalk_message']
                response_text = error['data']['logtalk_message']
            else:
                output += '\n' + self.backend_data["failure_response"]
                response_text = self.backend_data["failure_response"]
        elif error_code == -4712:
            # Exception: "logtalk_message" contains the error message
            ename = 'exception'
            output += '\n' + error['data']['logtalk_message']
            response_text = error['data']['logtalk_message'] + '\n'
        elif error_code == -4715:
            # Unhandled exception: the server needs to be restarted
            ename = 'unhandled exception'
            output += '\n' + error['data']['logtalk_message']
            self.kill_logtalk_server()
            response_text = error['data']['logtalk_message'] + '\n' + self.backend_data["error_prefix"] + 'The Logtalk server needs to be restarted'
        else:
            ename = 'error'
            output += '\n' + error['message']
            response_text = self.backend_data["error_prefix"] + str(error['message']) + '\n'

        self.send_response_display_data(response_text, self.error_ansi_escape_codes)

        return {
           'status' : 'error',
           'ename' : ename,
           'evalue' : '',
           'traceback' : [output], # Needed for nbgrader validation
        }


    def send_response_display_data(self, text, ansi_escape_codes=""):
        """Sends a response to the frontend containing plain text."""
        display_data = {
            'data': {
                'text/plain': ansi_escape_codes + text
            },
            'metadata': {}
        }   
        self.kernel.send_response(self.kernel.iopub_socket, 'display_data', display_data)

    def send_widget_html(self, html_content):
        """Send widget HTML content to the frontend."""
        # Ensure html_content is properly escaped and handled as a string
        if isinstance(html_content, dict) and 'widget_html' in html_content:
            html_content = str(html_content['widget_html'])
        else:
            html_content = str(html_content)
            
        display_data = {
            'data': {
                'text/html': html_content
            },
            'metadata': {}
        }
        self.kernel.send_response(self.kernel.iopub_socket, 'display_data', display_data)


    ############################################################################
    # Handling of additional data
    ############################################################################


    def handle_additional_data(self, dict):
        """
        Handles additional data which may be present in the dict.
        Any of the data processing methods should return True if something goes wrong during the handling.
        Returns a list containing the dictionary keys for which the handling did not succeed.
        """
        failure_keys = []

        if 'predicate_atoms' in dict:
            if self.handle_completion_data_update(dict['predicate_atoms']):
                failure_keys.append(['predicate_atoms'])
        if 'print_sld_tree' in dict:
            if self.handle_print_graph(dict['print_sld_tree']):
                failure_keys.append(['print_sld_tree'])
        if 'print_table' in dict:
            if self.handle_print_table(dict['print_table']):
                failure_keys.append(['print_table'])
        if 'print_and_save_table' in dict:
            if self.handle_print_and_save_table(dict['print_and_save_table']):
                failure_keys.append(['print_and_save_table'])
        if 'show_data' in dict:
            if self.handle_show_data(dict['show_data']):
                failure_keys.append(['show_data'])
        if 'print_transition_graph' in dict:
            if self.handle_print_graph(dict['print_transition_graph']):
                failure_keys.append(['print_transition_graph'])
        if 'set_prolog_backend' in dict:
            if self.handle_set_prolog_backend(dict['set_prolog_backend']):
                failure_keys.append(['set_prolog_backend'])
        if 'widget_html' in dict:
            if self.handle_widget_html(dict['widget_html']):
                failure_keys.append(['widget_html'])

        return failure_keys


    def handle_completion_data_update(self, predicate_atoms):
        """The user requested to update the predicate data used for code completion."""
        self.current_predicates = predicate_atoms


    def handle_print_graph(self, graph_file_content):
        """
        The string graph_file_content corresponds to the content of a file defining a graph.
        It is used to render an svg file with dot, of which the content is then read in and sent to the frontend so that the graph is displayed.

        Example
        ------
        graph_file_content can look like the following
        graph {
            "1" [label="user:pred"]
            "2" [label="user:sub_goal_1"]
            "3" [label="user:sub_goal_1_1"]
            "4" [label="user:sub_goal_1_2"]
            "5" [label="user:sub_goal_2"]
            "6" [label="user:sub_goal_2_1"]
            "7" [label="user:sub_goal_2_2"]
            "1" -- "2"
            "2" -- "3"
            "2" -- "4"
            "1" -- "5"
            "5" -- "6"
            "5" -- "7"
        }
        """

        # Write the content to a file
        with open("graph.gv", "w") as f:
            f.write(graph_file_content)

        # Render a svg file
        render(engine='dot', format='svg', filepath='graph.gv', outfile='graph.svg').replace('\\', '/')

        # Read the svg file content
        with open("graph.svg", "r") as svg_file:
            svg_content = svg_file.read()

        # Remove the created files
        remove("graph.gv")
        remove("graph.svg")

        # Send the data to the client
        display_data = {
            'data': {
                'text/plain': graph_file_content,
                'image/svg+xml': svg_content
            },
            'metadata': {}}
        self.kernel.send_response(self.kernel.iopub_socket, 'display_data', display_data)


    def handle_print_table(self, print_table_dict):
        """
        The dictionary print_table_dict contains the members 'ValuesLists' and 'VariableNames'.
        ValuesLists is a list of lists where each of them is used to compute one line of the table.
        VariableNames is a list of strings from which the header of the table is created.

        Example
        ------
        For the cell code
          "print_table((member(Member, [10,20,30]), Square is Member*Member))."
        the variables dictionary is:
          {'ValuesLists': [['10', '100'], ['20', '400'], ['30', '900']], 'VariableNames': ['Member', 'Square']}
        The markdown text sent to the frontend is:
          Member | Square |
          :- | :- |
          10 | 100 |
          20 | 400 |
          30 | 900 |
        """
        values_lists = print_table_dict["ValuesLists"]
        variable_names = print_table_dict["VariableNames"]

        table_markdown_string = self.create_markdown_table(variable_names, values_lists)
        self.send_markdown_table_to_frontend(table_markdown_string)


    def handle_print_and_save_table(self, print_and_save_table_dict):
        """
        The dictionary print_and_save_table_dict contains the members 'ValuesLists', 'VariableNames', 'Format', and 'File'.
        ValuesLists is a list of lists where each of them is used to compute one line of the table.
        VariableNames is a list of strings from which the header of the table is created.
        Format is either 'csv' or 'tsv'.

        Example
        ------
        For the cell code
          "print_and_save_table((member(Member, [10,20,30]), Square is Member*Member), tsv, 'squares.tsv')."
        the variables dictionary is:
          {'ValuesLists': [['10', '100'], ['20', '400'], ['30', '900']], 'VariableNames': ['Member', 'Square'], 'Format': 'tsv', 'File': 'squares.tsv'}
        The markdown text sent to the frontend is:
          Member | Square |
          :- | :- |
          10 | 100 |
          20 | 400 |
          30 | 900 |
        """
        values_lists = print_and_save_table_dict["ValuesLists"]
        variable_names = print_and_save_table_dict["VariableNames"]
        output_format = print_and_save_table_dict["Format"]
        output_file = print_and_save_table_dict["File"]

        table_markdown_string = self.create_markdown_table(variable_names, values_lists)
        self.send_markdown_table_to_frontend(table_markdown_string)
        self.save_table_to_file(variable_names, values_lists, output_format, output_file)


    def create_markdown_table(self, variable_names, values_lists):
        """Create a markdown formatted table string.
        
        Args:
            variable_names: List of column headers
            values_lists: List of row values
            
        Returns:
            Formatted markdown table string
        """
        table_header_markdown_string = ""
        table_markdown_string = ""

        # Create a header line with the variable names
        for variable_name in variable_names:
            table_header_markdown_string = table_header_markdown_string + str(variable_name) + " | "
            table_markdown_string = table_markdown_string + ":- | "

        table_markdown_string = table_header_markdown_string  + "\n" + table_markdown_string

        # For each values list, add a markdown table line
        for values_list in values_lists:
            line_markdown_string = ""
            for value in values_list:
                line_markdown_string = line_markdown_string + str(value) + " | "

            table_markdown_string = table_markdown_string + "\n" + line_markdown_string
            
        return table_markdown_string


    def send_markdown_table_to_frontend(self, table_markdown_string):
        """Sends the markdown table string to the frontend."""
        display_data = {
            'data': {
                'text/plain': table_markdown_string,
                'text/markdown': table_markdown_string.replace('$', '\$').replace('~', '\~')
            },
            'metadata': {}
        }
        self.kernel.send_response(self.kernel.iopub_socket, 'display_data', display_data)


    def save_table_to_file(self, variable_names, values_lists, output_format, output_file):
        """Saves the table to a file in the specified format."""
        delimiters = {"csv": ",", "tsv": "\t"}
        delimiter = delimiters.get(output_format, "\t")
        with open(output_file, 'w') as csvfile:
            csvwriter = csv.writer(csvfile, delimiter=delimiter)
            csvwriter.writerow(variable_names)
            csvwriter.writerows(values_lists)


    def handle_show_data(self, show_data_dict):
        """
        The dictionary show_data_dict contains pairs describing how to visualize the data.

        Example
        ------
          {'type':'pie', 'title':'Pie Graph', 'x':[35, 20, 30, 40, 50, 30], 'labels':['Apple','Banana','Grapes','Orange','PineApple','Dragon Fruit']}
        """
        try:
            fig, ax = plt.subplots()
            
            for key, value in show_data_dict.items():
                if value == "true":
                    show_data_dict[key] = True
                elif value == "false":
                    show_data_dict[key] = False
                elif value == "none":
                    show_data_dict[key] = None
            
            data_type = show_data_dict["type"]
            show_data_dict.pop("type", None)
            
            if "title" in show_data_dict:
                data_title = show_data_dict["title"]
                show_data_dict.pop("title", None)
            
            if "suptitle" in show_data_dict:
                data_suptitle = show_data_dict["suptitle"]
                show_data_dict.pop("suptitle", None)
            
            if "bar_label" in show_data_dict:
                data_bar_label = show_data_dict["bar_label"]
                show_data_dict.pop("bar_label", None)
            
            if "xlabel" in show_data_dict:
                data_xlabel = show_data_dict["xlabel"]
                show_data_dict.pop("xlabel", None)
                if isinstance(data_xlabel, dict):
                    data_xlabel_label = data_xlabel["label"]
                    data_xlabel.pop("label", None)
                    plt.xlabel(data_xlabel_label, **data_xlabel)
                else:
                    plt.xlabel(data_xlabel)
            if "ylabel" in show_data_dict:
                data_ylabel = show_data_dict["ylabel"]
                show_data_dict.pop("ylabel", None)
                if isinstance(data_ylabel, dict):
                    data_ylabel_label = data_ylabel["label"]
                    data_ylabel.pop("label", None)
                    plt.ylabel(data_ylabel_label, **data_ylabel)
                else:
                    plt.ylabel(data_ylabel)
            
            if "xscale" in show_data_dict:
                data_xscale = show_data_dict["xscale"]
                show_data_dict.pop("xscale", None)
                plt.xscale(data_xscale)
            if "yscale" in show_data_dict:
                data_yscale = show_data_dict["yscale"]
                show_data_dict.pop("yscale", None)
                plt.yscale(data_yscale)
            
            if "xticks" in show_data_dict:
                data_xticks = show_data_dict["xticks"]
                show_data_dict.pop("xticks", None)
                plt.xticks(**data_xticks)
            if "yticks" in show_data_dict:
                data_yticks = show_data_dict["yticks"]
                show_data_dict.pop("yticks", None)
                plt.yticks(**data_yticks)
            
            if "xlim" in show_data_dict:
                data_xlim = show_data_dict["xlim"]
                show_data_dict.pop("xlim", None)
                plt.xlim(**data_xlim)
            if "ylim" in show_data_dict:
                data_ylim = show_data_dict["ylim"]
                show_data_dict.pop("ylim", None)
                plt.ylim(**data_ylim)
            
            if "margins" in show_data_dict:
                data_margins = show_data_dict["margins"]
                show_data_dict.pop("margins", None)
                plt.margins(**data_margins)
            
            if "rc" in show_data_dict:
                data_rc = show_data_dict["rc"]
                show_data_dict.pop("rc", None)
                data_rc_label = data_rc["label"]
                data_rc.pop("label", None)
                plt.rc(data_rc_label, **data_rc)
            
            if "grid" in show_data_dict:
                data_grid = show_data_dict["grid"]
                show_data_dict.pop("grid", None)
                plt.grid(**data_grid)
            
            if "thetagrids" in show_data_dict:
                data_thetagrids = show_data_dict["thetagrids"]
                show_data_dict.pop("thetagrids", None)
                plt.thetagrids(**data_thetagrids)
            
            if "rgrids" in show_data_dict:
                data_rgrids = show_data_dict["rgrids"]
                show_data_dict.pop("rgrids", None)
                plt.rgrids(**data_rgrids)
            
            if "autoscale" in show_data_dict:
                data_autoscale = show_data_dict["autoscale"]
                show_data_dict.pop("autoscale", None)
                plt.autoscale(**data_autoscale)
            
            if "tight_layout" in show_data_dict:
                data_tight_layout = show_data_dict["tight_layout"]
                show_data_dict.pop("tight_layout", None)
                plt.tight_layout(**data_tight_layout)
            
            if "legend" in show_data_dict:
                data_legend = show_data_dict["legend"]
                show_data_dict.pop("legend", None)
            
            if "annotate" in show_data_dict:
                data_annotate = show_data_dict["annotate"]
                show_data_dict.pop("annotate", None)
                data_annotate_text = data_annotate["text"]
                data_annotate.pop("text", None)
                data_annotate_xy = data_annotate["xy"]
                data_annotate.pop("xy", None)
                plt.annotate(data_annotate_text, data_annotate_xy, **data_annotate)
            
            if "text" in show_data_dict:
                data_text = show_data_dict["text"]
                show_data_dict.pop("text", None)
                data_text_x = data_text["x"]
                data_text.pop("x", None)
                data_text_y = data_text["y"]
                data_text.pop("y", None)
                data_text_s = data_text["s"]
                data_text.pop("s", None)
                plt.text(data_text_x, data_text_y, data_text_s, **data_text)
            
            if "figtext" in show_data_dict:
                data_text = show_data_dict["text"]
                show_data_dict.pop("text", None)
                data_text_x = data_text["x"]
                data_text.pop("x", None)
                data_text_y = data_text["y"]
                data_text.pop("y", None)
                data_text_s = data_text["s"]
                data_text.pop("s", None)
                plt.figtext(data_text_x, data_text_y, data_text_s, **data_text)
            
            if data_type == "bar":
                p = ax.bar(**show_data_dict)
            elif data_type == "barh":
                p = ax.barh(**show_data_dict)
            elif data_type == "eventplot":
                p = ax.eventplot(**show_data_dict)
            elif data_type == "hist":
                p = ax.hist(**show_data_dict)
            elif data_type == "pie":
                p = ax.pie(**show_data_dict)
            elif data_type == "plot":
                data_x = show_data_dict["x"]
                show_data_dict.pop("x", None)
                data_y = show_data_dict["y"]
                show_data_dict.pop("y", None)
                p = ax.plot(data_x, data_y, **show_data_dict)
            elif data_type == "loglog":
                data_x = show_data_dict["x"]
                show_data_dict.pop("x", None)
                data_y = show_data_dict["y"]
                show_data_dict.pop("y", None)
                p = ax.loglog(data_x, data_y, **show_data_dict)
            elif data_type == "semilogx":
                data_x = show_data_dict["x"]
                show_data_dict.pop("x", None)
                data_y = show_data_dict["y"]
                show_data_dict.pop("y", None)
                p = ax.semilogx(data_x, data_y, **show_data_dict)
            elif data_type == "semilogy":
                data_x = show_data_dict["x"]
                show_data_dict.pop("x", None)
                data_y = show_data_dict["y"]
                show_data_dict.pop("y", None)
                p = ax.semilogy(data_x, data_y, **show_data_dict)
            elif data_type == "scatter":
                p = ax.scatter(**show_data_dict)
            elif data_type == "stem":
                data_x = show_data_dict["x"]
                show_data_dict.pop("x", None)
                data_y = show_data_dict["y"]
                show_data_dict.pop("y", None)
                p = ax.stem(data_x, data_y, **show_data_dict)
            elif data_type == "boxplot":
                data_x = show_data_dict["x"]
                show_data_dict.pop("x", None)
                p = ax.boxplot(data_x, **show_data_dict)
            elif data_type == "ecdf":
                data_x = show_data_dict["x"]
                show_data_dict.pop("x", None)
                p = ax.ecdf(data_x, **show_data_dict)
            elif data_type == "errorbar":
                data_x = show_data_dict["x"]
                show_data_dict.pop("x", None)
                data_y = show_data_dict["y"]
                show_data_dict.pop("y", None)
                p = ax.errorbar(data_x, data_y, **show_data_dict)
            elif data_type == "stackplot":
                data_x = show_data_dict["x"]
                show_data_dict.pop("x", None)
                data_y = show_data_dict["y"]
                show_data_dict.pop("y", None)
                p = ax.stackplot(data_x, data_y, **show_data_dict)
            elif data_type == "hexbin":
                data_x = show_data_dict["x"]
                show_data_dict.pop("x", None)
                data_y = show_data_dict["y"]
                show_data_dict.pop("y", None)
                p = ax.hexbin(data_x, data_y, **show_data_dict)
            elif data_type == "hist2d":
                data_x = show_data_dict["x"]
                show_data_dict.pop("x", None)
                data_y = show_data_dict["y"]
                show_data_dict.pop("y", None)
                p = ax.hist2d(data_x, data_y, **show_data_dict)
            elif data_type == "polar":
                data_theta = show_data_dict["theta"]
                show_data_dict.pop("theta", None)
                data_r = show_data_dict["r"]
                show_data_dict.pop("r", None)
                plt.clf()
                plt.polar(data_theta, data_r, **show_data_dict)
            elif data_type == "step":
                p = ax.step(**show_data_dict)
            
            if 'data_suptitle' in locals():
                if isinstance(data_suptitle, dict):
                    data_suptitle_label = data_suptitle["label"]
                    data_suptitle.pop("label", None)
                    plt.suptitle(data_suptitle_label, **data_suptitle)
                else:
                    plt.suptitle(data_suptitle)
            
            if 'data_title' in locals():
                if isinstance(data_title, dict):
                    data_title_label = data_title["label"]
                    data_title.pop("label", None)
                    plt.title(data_title_label, **data_title)
                else:
                    plt.title(data_title)
            
            if 'data_legend' in locals():
                plt.legend(**data_legend)
            
            if 'data_bar_label' in locals():
                plt.bar_label(p, **data_bar_label)

            plot = io.StringIO()
            plt.savefig(plot, format="svg")
            plt.close()
            out = plot.getvalue()

            display_data = {
                'data': {
                    'image/svg+xml': out
                },
                'metadata': {}}

        except Exception as exception:
            display_data = {
                'data': {
                    'text/plain': f"{self.error_ansi_escape_codes} {self.backend_data['error_prefix']} {exception}"
                },
                'metadata': {}}

        finally:
            # Send the data to the client
            self.kernel.send_response(self.kernel.iopub_socket, 'display_data', display_data)


    def handle_set_prolog_backend(self, prolog_backend):
        """The user requested to change the active Prolog backend, which needs to be handled by the kernel."""
        return self.kernel.change_prolog_backend(prolog_backend)


    def handle_widget_html(self, html_content):
        """Handle widget HTML content from Logtalk server."""
        try:
            # Ensure we have valid HTML content
            if isinstance(html_content, dict) and 'widget_html' in html_content:
                html = html_content['widget_html']
            else:
                html = str(html_content)

            # Send the widget HTML to the frontend
            self.kernel.send_response(
                self.kernel.iopub_socket,
                'display_data',
                {
                    'data': {
                        'text/html': html_content
                    },
                    'metadata': {}
                }
            )
            return False  # Success
        except Exception as e:
            self.logger.error(f"Error handling widget HTML: {e}", exc_info=True)
            return True  # Failure


class CallbackHandler(BaseHTTPRequestHandler):
    kernel_implementation = None
    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        data = json.loads(post_data.decode('utf-8'))
        
        # Process your callback here
        if data['type'] == 'number' or data['type'] == 'slider':
            code = 'jupyter_widgets::set_widget_value(\'' + data['id'] + '\', ' + data['value'] + ').'
        else:
            data['value'] = data['value'].replace("'", "\\'")
            code = 'jupyter_widgets::set_widget_value(\'' + data['id'] + '\', \'' + data['value'] + '\').'
        try:
            self.kernel_implementation.do_execute(code, True, False, {}, False)
            result = {"status": "ok", "received": code}
        except Exception as e:
            result = {"status": "error", "error": str(e)}
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
        self.wfile.write(json.dumps(result).encode())
