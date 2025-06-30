#############################################################################
#
#  Copyright (c) 2022-2025 Paulo Moura  
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
A Logtalk Jupyter kernel communicating with a Logtalk server with JSON-RPC 2.0 messages.
The communication is based on 'jsonrpc_client.py' from SICStus Prolog 4.5.1.

Several Prolog backends are supported. By default, the SWI-Prolog backend is used.
By defining a 'logtalk_kernel_config.py' file, the Prolog backend to be used can be defined.
In addition to providing an backend (the name of the used Logtalk integration script),
further implementation specific data (a dictionary 'backend_data' with the backend as key) can be defined.
This includes the command line arguments with which the Logtalk server can be started.

Additionally, there is the Logtalk predicate 'jupyter::set_prolog_backend(+Backend)' with which the implementation can be changed
(the argument is the name of the used Logtalk integration script).
In order for this to work, the configured 'backend_data' dictionary needs to contain data for more than one Prolog backend.

An example of a configuration file with an explanation of the options and their default values commented out can be found in the current directory.
When defined, this file needs to be present in one of the Jupyter config paths (can be retrieved with 'jupyter --paths') or the current working directory.

The actual kernel code is not implemented by this kernel class itself.
Instead, there is the file 'logtalk_kernel_base_implementation.py' which defines the class 'LogtalkKernelBaseImplementation'.
When the kernel is started, a (sub)object of this class is created.
It handles the starting of and communication with the Logtalk server.
For all requests (execution, shutdown, completion, inspection) the kernel receives, a 'LogtalkKernelBaseImplementation' method is called.
By creating a subclass of this and defining the path to it as 'kernel_backend_path', the actual implementation code can be replaced.

If no such path is defined, the path itself or the defined class is invalid, a default implementation is used instead.
In case of SWI- and SICStus Prolog, the files 'swi_kernel_implementation.py' and 'sicstus_kernel_implementation.py' are used, which can be found in the current directory.
Otherwise, the base implementation from the file 'logtalk_kernel_base_implementation.py' is loaded.

The Logtalk Jupyter kernel is implemented in a way that basically all functionality except the loading of the configuration can easily be overridden.
This is especially useful for extending the kernel for further Prolog backends.
"""


import importlib.util
import logging
import os
import platform
import sys

from inspect import getmembers, isclass
from ipykernel.kernelbase import Kernel
from jupyter_core.paths import jupyter_config_path
from traitlets import Bool, Dict, Unicode
from traitlets.config.loader import ConfigFileNotFound, PyFileConfigLoader

#import logtalk_kernel.swi_kernel_implementation
#import logtalk_kernel.sicstus_kernel_implementation

from logtalk_kernel.logtalk_kernel_base_implementation import CallbackHandler, LogtalkKernelBaseImplementation

from threading import Thread
from http.server import HTTPServer
import socket
import socketserver
from contextlib import closing

# Constants
DEFAULT_ERROR_PREFIX = "!     "
DEFAULT_INFORMATIONAL_PREFIX = "% "
DEFAULT_PROGRAM_ARGS = "default"


class LogtalkKernel(Kernel):
    """Jupyter kernel implementation for Logtalk."""

    kernel_name = 'logtalk_kernel'
    implementation = kernel_name
    implementation_version = '1.0'
    language_info = {
        'name': 'Logtalk',
        'file_extension': '.lgt',
        'mimetype': 'text/x-logtalk',
        'codemirror_mode': 'logtalk',
    }
    banner = kernel_name

    active_kernel_implementation = None

    # Define default configuration options

    # If set to True, the logging level is set to DEBUG by the kernel so that Python debugging messages are logged.
    jupyter_logging = Bool(False).tag(config=True)

    # If set to True, a log file is created by the Logtalk server.
    server_logging = Bool(False).tag(config=True)

    # The Prolog backend integration script with which the server is started.
    # It is required that the backend_data dictionary contains an item with the script name.
    if platform.system() == "Windows":
        EXTENSION = ".ps1"
    elif (
        "LOGTALKHOME" in os.environ
        and "LOGTALKUSER" in os.environ
        and os.environ["LOGTALKHOME"] == os.environ["LOGTALKUSER"]
    ):
        EXTENSION = ".sh"
    else:
        EXTENSION = ""

    # backend = Unicode('eclipselgt' + EXTENSION).tag(config=True)
    # backend = Unicode('gplgt' + EXTENSION).tag(config=True)
    # backend = Unicode('sicstuslgt' + EXTENSION).tag(config=True)
    backend = Unicode('swilgt' + EXTENSION).tag(config=True)
    # backend = Unicode('tplgt' + EXTENSION).tag(config=True)
    # backend = Unicode('xvmlgt' + EXTENSION).tag(config=True)
    # backend = Unicode('yaplgt' + EXTENSION).tag(config=True)

    # The default program arguments for supported Prolog backends
    default_program_arguments = {
        "eclipselgt": ["eclipselgt",
                "-P",
                "-e", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt.",
                "--", "--quiet"],
        "eclipselgt.sh": ["eclipselgt.sh",
                "-P",
                "-e", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt.",
                "--", "--quiet"],
        "eclipselgt.ps1": ["eclipselgt.ps1",
                "-P",
                "-e", "\"set_logtalk_flag`(report`,off`)`,logtalk_load`(`'logtalk_server/loader.lgt`'`)`,'::'`(jupyter_server`,start`);halt.\"",
                "--%", "--quiet"],
        "gplgt": ["gplgt",
                "--quiet",
                "--entry-goal", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt"],
        "gplgt.sh": ["gplgt.sh",
                "--quiet",
                "--entry-goal", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt"],
        "gplgt.ps1": ["gplgt.ps1",
                "--quiet",
                "--entry-goal", "\"set_logtalk_flag`(report`,off`)`,logtalk_load`(`'logtalk_server/loader.lgt`'`)`,'::'`(jupyter_server`,start`);halt\""],
        "sicstuslgt": ["sicstuslgt",
                "--noinfo",
                "--goal", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt.",
                "--nologo"],
        "sicstuslgt.sh": ["sicstuslgt.sh",
                "--noinfo",
                "--goal", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt.",
                "--nologo"],
        "sicstuslgt.ps1": ["sicstuslgt.ps1",
                "--noinfo",
                "--goal", "\"set_logtalk_flag`(report`,off`)`,logtalk_load`(`'logtalk_server/loader.lgt`'`)`,`'::`'`(jupyter_server`,start`);halt.\"",
                "--nologo"],
        "swilgt": ["swilgt",
                "-q",
                "-g", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt"],
        "swilgt.sh": ["swilgt.sh",
                "-q",
                "-g", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt"],
        "swilgt.ps1": ["swilgt.ps1",
                "-q",
                "-g", "\"set_logtalk_flag`(report`,off`)`,logtalk_load`(`'logtalk_server/loader.lgt`'`)`,'::'`(jupyter_server`,start`);halt\""],
        "tplgt": ["tplgt",
                "-q",
                "-g", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt"],
        "tplgt.sh": ["tplgt.sh",
                "-q",
                "-g", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt"],
        "tplgt.ps1": ["tplgt.ps1",
                "-q",
                "-g", "\"set_logtalk_flag`(report`,off`)`,logtalk_load`(`'logtalk_server/loader.lgt`'`)`,'::'`(jupyter_server`,start`);halt\""],
        "xvmlgt": ["xvmlgt",
                "-q",
                "-g", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt."],
        "xvmlgt.sh": ["xvmlgt.sh",
                "-q",
                "-g", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt."],
        "xvmlgt.ps1": ["xvmlgt.ps1",
                "-q",
                "-g", "\"set_logtalk_flag`(report`,off`)`,logtalk_load`(`'logtalk_server/loader.lgt`'`)`,'::'`(jupyter_server`,start`);halt.\""],
        "yaplgt": ["yaplgt",
                "-q",
                "-g", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt"],
        "yaplgt.sh": ["yaplgt.sh",
                "-q",
                "-g", "set_logtalk_flag(report,off),logtalk_load('logtalk_server/loader.lgt'),'::'(jupyter_server,start);halt"],
        "yaplgt.ps1": ["yaplgt.ps1",
                "-q",
                "-g", "\"set_logtalk_flag`(report`,off`)`,logtalk_load`(`'logtalk_server/loader.lgt`'`)`,'::'`(jupyter_server`,start`);halt\""],
    }

    # The implementation specific data which is needed to run the Logtalk server for code execution.
    # This is required to be a dictionary containing at least an entry for the configured backend.
    # Each entry needs to define values for
    # - "failure_response": The output which is displayed if a query fails
    # - "success_response": The output which is displayed if a query succeeds without any variable bindings
    # - "error_prefix": The prefix output for error messages
    # - "informational_prefix": The prefix output for informational messages
    # - "program_arguments": The command line arguments (a list of strings) with which the Logtalk server can be started
    # Additionally, a "kernel_backend_path" can be provided, which needs to be an absolute path to a Python file.
    # The corresponding module is required to define a subclass of LogtalkKernelBaseImplementation named LogtalkKernelImplementation.
    # This can be used to override some of the kernel's basic behavior.
    backend_data = Dict({
        "eclipselgt": {
            "failure_response": "No",
            "success_response": "Yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "eclipselgt.sh": {
            "failure_response": "No",
            "success_response": "Yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "eclipselgt.ps1": {
            "failure_response": "No",
            "success_response": "Yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "gplgt": {
            "failure_response": "no",
            "success_response": "yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "gplgt.sh": {
            "failure_response": "no",
            "success_response": "yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "gplgt.ps1": {
            "failure_response": "no",
            "success_response": "yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "sicstuslgt": {
            "failure_response": "no",
            "success_response": "yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "sicstuslgt.sh": {
            "failure_response": "no",
            "success_response": "yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "sicstuslgt.ps1": {
            "failure_response": "no",
            "success_response": "yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "swilgt": {
            "failure_response": "false",
            "success_response": "true",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "swilgt.sh": {
            "failure_response": "false",
            "success_response": "true",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "swilgt.ps1": {
            "failure_response": "false",
            "success_response": "true",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "tplgt": {
            "failure_response": "false",
            "success_response": "true",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "tplgt.sh": {
            "failure_response": "false",
            "success_response": "true",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "tplgt.ps1": {
            "failure_response": "false",
            "success_response": "true",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "xvmlgt": {
            "failure_response": "false",
            "success_response": "true",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "xvmlgt.sh": {
            "failure_response": "false",
            "success_response": "true",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "xvmlgt.ps1": {
            "failure_response": "false",
            "success_response": "true",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "yaplgt": {
            "failure_response": "no",
            "success_response": "yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "yaplgt.sh": {
            "failure_response": "no",
            "success_response": "yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        },
        "yaplgt.ps1": {
            "failure_response": "no",
            "success_response": "yes",
            "error_prefix": DEFAULT_ERROR_PREFIX,
            "informational_prefix": DEFAULT_INFORMATIONAL_PREFIX,
            "program_arguments": DEFAULT_PROGRAM_ARGS
        }
    }).tag(config=True)

    # The keys which are required for each entry in the backend_data dict.
    required_backend_data_keys = [
        "failure_response",
        "success_response",
        "error_prefix",
        "informational_prefix",
        "program_arguments"
    ]

    logger = None

    # A dictionary with implementation ids as keys and the corresponding LogtalkKernelBaseImplementation as value.
    # When a Prolog backend is started, it is added to the dictionary.
    # On kernel shutdown or interruption, all implementations are shutdown/interrupted.
    active_kernel_implementations = {}

    # Store references to callback webservers for proper shutdown
    webservers = []


    def __init__(self, **kwargs):
        """Initialize the kernel with logging and configuration."""
        super().__init__(**kwargs)

        # Configure logging
        logging.basicConfig(
            format='[%(asctime)s] {%(filename)s:%(lineno)d} %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)
        # For development, the logging level can be set to level DEBUG, so that all debug messages (including the ones about loading a configuration file) are output
        #self.logger.setLevel(logging.DEBUG)

        # Load configuration and backend data
        self.load_config_file()
        load_exception_message = self.load_backend_data(self.backend)
        if load_exception_message:
            # The configured backend_data is invalid
            raise Exception(load_exception_message)

        # Create an implementation object which starts the Logtalk server
        self.load_kernel_implementation()


    def load_config_file(self):
        """Load Logtalk kernel configuration from config files.
        
        Searches Jupyter config paths and current directory for logtalk_kernel_config.py.
        Config in current directory overrides other locations.
        """
        CONFIG_FILE = 'logtalk_kernel_config.py'
        
        # Get config search paths
        config_paths = jupyter_config_path()
        config_paths.insert(0, os.getcwd())
    
        # Find existing config files
        existing_paths = [
            p for p in config_paths 
            if os.path.exists(os.path.join(p, CONFIG_FILE))
        ]
        existing_paths.reverse()  # Higher priority paths first
    
        if not existing_paths:
            self.logger.debug(
                f"No {CONFIG_FILE} found in: {config_paths}. Using defaults."
            )
            return
    
        # Load each config file
        for path in existing_paths:
            loader = PyFileConfigLoader(
                CONFIG_FILE, 
                path=path,
                log=self.logger
            )
    
            try:
                config = loader.load_config()
            except ConfigFileNotFound:
                self.logger.error(
                    f"Config file not found: {os.path.join(path, CONFIG_FILE)}", 
                    exc_info=True
                )
            except Exception:
                self.logger.error(
                    f"Error loading config: {os.path.join(path, CONFIG_FILE)}", 
                    exc_info=True
                )
            else:
                self.update_config(config)
                if self.jupyter_logging:
                    self.logger.setLevel(logging.DEBUG)
                self.logger.debug(f"Loaded config: {loader.full_filename}")


    def load_backend_data(self, backend):
        """
        Tries to set the implementation data for the Prolog backend with ID backend.
        If no such data is provided for the given backend ID or the dictionary does not contain all required keys, a corresponding message is returned.
        """

        # Check if there is an item for the backend
        if backend not in self.backend_data:
            return f"No configured backend_data entry for Prolog backend '{backend}'"

        # Check if all required keys are contained in the dictionary
        missing_keys = [
            key for key in self.required_backend_data_keys 
            if key not in self.backend_data[backend]
        ]

        if missing_keys == []:
            # The implementation data is valid
            self.active_backend_data = self.backend_data[backend]
        elif len(missing_keys) == 1:
            return f"Backend data for '{backend}' missing entry '{missing_keys[0]}'"
        else:
            return f"Backend data for '{backend}' missing entries: {', '.join(missing_keys)}"


    def load_kernel_implementation(self):
        """
        In order for the kernel to be able to execute code, a (sub)object of 'LogtalkKernelBaseImplementation' is needed.
        If the configured backend_data contains an entry for 'kernel_backend_path', tries to load the corresponding module and create a 'LogtalkKernelImplementation' defined in it.
        This causes the Logtalk server to be started so that code can be executed.

        If no 'kernel_backend_path' is given or it is invalid, a default implementation is used instead.
        For the Prolog backends with ID 'swi' or 'sicstus', there is a module defining the class 'LogtalkKernelImplementation' in the current directory.
        Otherwise, the 'LogtalkKernelBaseImplementation' is used.
        """

        use_default = False

        if 'kernel_backend_path' in self.active_backend_data:
            file_path = self.active_backend_data['kernel_backend_path']

            if not os.path.exists(file_path):
                use_default = True
                self.logger.debug("The configured kernel_backend_path '" + str(file_path) + "' does not exist")
            else:
                self.logger.debug("Loading kernel specific code from '" + str(file_path) + "'")
                # Load the module from the specified file
                (module_name, file_extension)= os.path.splitext(os.path.basename(file_path))
                spec = importlib.util.spec_from_file_location(module_name, file_path)
                kernel_implementation_module = importlib.util.module_from_spec(spec)
                sys.modules[module_name] = kernel_implementation_module
                spec.loader.exec_module(kernel_implementation_module)

                # Try to get the class with name 'LogtalkKernelImplementation' and check if it is valid
                implementation_classes = list(class_pair[1] for class_pair in getmembers(kernel_implementation_module, isclass) if class_pair[0]=='LogtalkKernelImplementation')
                if len(implementation_classes) == 0:
                    use_default = True
                    self.logger.debug("The module at the configured kernel_backend_path needs to define the class 'LogtalkKernelImplementation'")
                else:
                    # Try loading the specific implementation
                    try:
                        self.active_kernel_implementation = kernel_implementation_module.LogtalkKernelImplementation(self)
                        if not isinstance(self.active_kernel_implementation, kernel_implementation_module.LogtalkKernelBaseImplementation):
                            use_default = True
                            self.logger.debug("The class 'LogtalkKernelImplementation' needs to be a subclass of 'LogtalkKernelBaseImplementation'")
                    except Exception:
                        use_default = True
                        self.logger.debug("Exception while creating a 'LogtalkKernelImplementation' object" , exc_info=True)
        else:
            use_default = True
            self.logger.debug('No kernel_backend_path configured')

        if use_default:
            # The configured implementation could not be loaded
            # A default implementation is used instead
#            if self.backend == 'swi':
#                self.logger.debug("Using the default implementation for SWI-Prolog")
#                self.active_kernel_implementation = logtalk_kernel.swi_kernel_implementation.LogtalkKernelImplementation(self)
#            elif self.backend == 'sicstus':
#                self.logger.debug("Using the default implementation for SICStus Prolog")
#                self.active_kernel_implementation = logtalk_kernel.sicstus_kernel_implementation.LogtalkKernelImplementation(self)
#            else:
                self.logger.debug("Using the base implementation")
                self.active_kernel_implementation = LogtalkKernelBaseImplementation(self)

        # Add the Prolog backend specific implementation class to the dictionary of active implementations
        self.active_kernel_implementations[self.backend] = self.active_kernel_implementation

        # Start server in background thread
        port = self.start_webserver_threaded('127.0.0.1', 8900, 8999)
        if port is not None:
            do_execute_code = f"jupyter_widgets::set_webserver_port({port})."
            self.active_kernel_implementation.do_execute(do_execute_code, False, True, None, False)


    def change_prolog_backend(self, prolog_backend):
        """
        Change the Prolog backend to the one with ID prolog_backend.
        If there is a running server for that backend, it is activated.
        Otherwise, the backend-specific data is loaded (which starts a new server) and set as the active one.
        Returns False if the new backend is successfully used, True otherwise.
        """

        self.logger.debug(f'Change Prolog backend to {prolog_backend}')

        if prolog_backend in self.active_kernel_implementations:
            # There is a running Logtalk server for the provided implementation ID
            # Make it the active one
            self.backend = prolog_backend
            self.active_kernel_implementation = self.active_kernel_implementations[self.backend]
        else:
            # Try to load the implementation specific data
            load_exception_message = self.load_backend_data(prolog_backend)
            if load_exception_message:
                self.logger.debug(load_exception_message)
                # The configured backend_data is invalid
                # Display an error message
                error_message = self.active_backend_data["error_prefix"] + load_exception_message

                display_data = {
                    'data': {
                        'text/plain': error_message,
                        'text/markdown': '<pre style="' + self.active_kernel_implementation.output_text_style + 'color:red">' + error_message + '</pre>'                    },
                    'metadata': {}}
                self.send_response(self.iopub_socket, 'display_data', display_data)
                return True
            else:
                self.backend = prolog_backend
                # Create an implementation object which starts the Logtalk server
                self.load_kernel_implementation()
                return False


    def interrupt_all(self):
        # Interrupting the kernel interrupts the running Logtalk processes, so all of them need to be restarted
        for backend, kernel_implementation in self.active_kernel_implementations.items():
            kernel_implementation.kill_logtalk_server()


    def start_webserver_threaded(self, host, start_port, end_port):
        """Start a web server in a separate thread."""
        
        port = self.find_available_port(host, start_port, end_port)
        
        if port is None:
            print(f"No available ports found in range {start_port}-{end_port}")
            return None
        
        try:
            server = HTTPServer((host, port), CallbackHandler)
            CallbackHandler.kernel_implementation = self.active_kernel_implementation
            Thread(target=server.serve_forever, daemon=True).start()
            # Store the server instance for later shutdown
            self.webservers.append(server)
            self.logger.debug(f"Widget callback server started at http://{host}:{port}")
            return port
            
        except Exception as e:
            print(f"Error starting widget callback server: {e}")
            return None


    def is_port_available(self, host, port):
        """Check if a port is available on the given host."""
        with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
            sock.settimeout(1)
            result = sock.connect_ex((host, port))
            return result != 0


    def find_available_port(self, host, start_port, end_port):
        """Find the first available port in the given range."""
        for port in range(start_port, end_port + 1):
            if self.is_port_available(host, port):
                return port
        return None


    ############################################################################
    # Overridden kernel methods
    ############################################################################


    def do_shutdown(self, restart):
        # Shutdown all callback webservers first
        for server in getattr(self, 'webservers', []):
            try:
                server.shutdown()
                server.server_close()
            except Exception as e:
                self.logger.debug(f"Exception shutting down webserver: {e}")
        self.webservers.clear()
        # Shutdown all active Logtalk servers so that no processes are kept running
        for kernel_implementation in self.active_kernel_implementations.values():
            kernel_implementation.do_shutdown(restart)

        return {'status': 'ok', 'restart': restart}


    def do_execute(self, code, silent, store_history=True, user_expressions=None, allow_stdin=False):
        return self.active_kernel_implementation.do_execute(code, silent, store_history, user_expressions, allow_stdin)


    def do_complete(self, code, cursor_pos):
        return self.active_kernel_implementation.do_complete(code, cursor_pos)


    def do_inspect(self, code, cursor_pos, detail_level=0, omit_sections=()):
        return self.active_kernel_implementation.do_inspect(code, cursor_pos, detail_level, omit_sections)
