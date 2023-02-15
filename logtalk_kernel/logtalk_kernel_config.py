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


import platform
import os

c = get_config()

## If set to True, the logging level is set to DEBUG by the kernel so that Python debugging messages are logged.
# Default:
# c.LogtalkKernel.jupyter_logging = False

## If set to True, a log file is created by the Logtalk server
# Default:
# c.LogtalkKernel.server_logging = False

## The Prolog backend integration script with which the server is started.
# Default:
if platform.system() == 'Windows':
    #c.LogtalkKernel.backend = "eclipselgt.ps1"
    #c.LogtalkKernel.backend = "gplgt.ps1"
    #c.LogtalkKernel.backend = "lvmlgt.ps1"
    #c.LogtalkKernel.backend = "sicstuslgt.ps1"
    c.LogtalkKernel.backend = "swilgt.ps1"
    #c.LogtalkKernel.backend = "tplgt.ps1"
    #c.LogtalkKernel.backend = "yaplgt.ps1"
elif 'LOGTALKHOME' in os.environ and 'LOGTALKUSER' in os.environ and os.environ['LOGTALKHOME'] == os.environ['LOGTALKUSER']:
    #c.LogtalkKernel.backend = "eclipselgt.sh"
    #c.LogtalkKernel.backend = "gplgt.sh"
    #c.LogtalkKernel.backend = "lvmlgt.sh"
    #c.LogtalkKernel.backend = "sicstuslgt.sh"
    c.LogtalkKernel.backend = "swilgt.sh"
    #c.LogtalkKernel.backend = "tplgt.sh"
    #c.LogtalkKernel.backend = "yaplgt.sh"
else:
    #c.LogtalkKernel.backend = "eclipselgt"
    #c.LogtalkKernel.backend = "gplgt"
    #c.LogtalkKernel.backend = "lvmlgt"
    #c.LogtalkKernel.backend = "sicstuslgt"
    c.LogtalkKernel.backend = "swilgt"
    #c.LogtalkKernel.backend = "tplgt"
    #c.LogtalkKernel.backend = "yaplgt"

## The implementation specific data which is needed to run the Logtalk server for code execution.
## This is required to be a dictionary containing at least an entry for the configured backend.
## Each entry needs to define values for
## - "failure_response": The output which is displayed if a query fails
## - "success_response": The output which is displayed if a query succeeds without any variable bindings
## - "error_prefix": The prefix output for error messages
## - "informational_prefix": The prefix output for informational messages
## - "program_arguments": The command line arguments (a list of strings) with which the Logtalk server can be started
##                        For all backends, the default Logtalk server can be used by configuring the string "default"
## Additionally, a "kernel_backend_path" can be provided, which needs to be an absolute path to a Python file.
## The corresponding module is required to define a subclass of LogtalkKernelBaseImplementation named LogtalkKernelImplementation.
## This can be used to override some of the kernel's basic behavior.
# Default:
c.LogtalkKernel.backend_data = {
   "eclipselgt": {
       "failure_response": "No",
       "success_response": "Yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "eclipselgt.sh": {
       "failure_response": "No",
       "success_response": "Yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "eclipselgt.ps1": {
       "failure_response": "No",
       "success_response": "Yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "gplgt": {
       "failure_response": "no",
       "success_response": "yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "gplgt.sh": {
       "failure_response": "no",
       "success_response": "yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "gplgt.ps1": {
       "failure_response": "no",
       "success_response": "yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "lvmlgt": {
       "failure_response": "false",
       "success_response": "true",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "lvmlgt.sh": {
       "failure_response": "false",
       "success_response": "true",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "lvmlgt.ps1": {
       "failure_response": "false",
       "success_response": "true",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "sicstuslgt": {
       "failure_response": "no",
       "success_response": "yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "sicstuslgt.sh": {
       "failure_response": "no",
       "success_response": "yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "sicstuslgt.ps1": {
       "failure_response": "no",
       "success_response": "yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "swilgt": {
       "failure_response": "false",
       "success_response": "true",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "swilgt.sh": {
       "failure_response": "false",
       "success_response": "true",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "swilgt.ps1": {
       "failure_response": "false",
       "success_response": "true",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "tplgt": {
       "failure_response": "false",
       "success_response": "true",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "tplgt.sh": {
       "failure_response": "false",
       "success_response": "true",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "tplgt.ps1": {
       "failure_response": "false",
       "success_response": "true",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "yaplgt": {
       "failure_response": "no",
       "success_response": "yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "yaplgt.sh": {
       "failure_response": "no",
       "success_response": "yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   },
   "yaplgt.ps1": {
       "failure_response": "no",
       "success_response": "yes",
       "error_prefix": "!     ",
       "informational_prefix": "% ",
       "program_arguments": "default"
   }
}
