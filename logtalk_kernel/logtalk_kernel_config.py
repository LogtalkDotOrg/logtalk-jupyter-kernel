import platform

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
    #c.LogtalkKernel.backend_id = "eclipselgt.ps1"
    #c.LogtalkKernel.backend_id = "gplgt.ps1"
    #c.LogtalkKernel.backend_id = "lvmlgt.ps1"
    #c.LogtalkKernel.backend_id = "sicstuslgt.ps1"
    c.LogtalkKernel.backend_id = "swilgt.ps1"
    #c.LogtalkKernel.backend_id = "tplgt.ps1"
    #c.LogtalkKernel.backend_id = "yaplgt.ps1"
elif 'LOGTALKHOME' in os.environ and 'LOGTALKUSER' in os.environ and os.environ['LOGTALKHOME'] == os.environ['LOGTALKUSER']:
    #c.LogtalkKernel.backend_id = "eclipselgt.sh"
    #c.LogtalkKernel.backend_id = "gplgt.sh"
    #c.LogtalkKernel.backend_id = "lvmlgt.sh"
    #c.LogtalkKernel.backend_id = "sicstuslgt.sh"
    c.LogtalkKernel.backend_id = "swilgt.sh"
    #c.LogtalkKernel.backend_id = "tplgt.sh"
    #c.LogtalkKernel.backend_id = "yaplgt.sh"
else:
    #c.LogtalkKernel.backend_id = "eclipselgt"
    #c.LogtalkKernel.backend_id = "gplgt"
    #c.LogtalkKernel.backend_id = "lvmlgt"
    #c.LogtalkKernel.backend_id = "sicstuslgt"
    c.LogtalkKernel.backend_id = "swilgt"
    #c.LogtalkKernel.backend_id = "tplgt"
    #c.LogtalkKernel.backend_id = "yaplgt"

## The implementation specific data which is needed to run the Logtalk server for code execution.
## This is required to be a dictionary containing at least an entry for the configured backend_id.
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
# c.LogtalkKernel.backend_data = {
#    "eclipselgt": {
#        "failure_response": "No",
#        "success_response": "Yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "eclipselgt.sh": {
#        "failure_response": "No",
#        "success_response": "Yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "eclipselgt.ps1": {
#        "failure_response": "No",
#        "success_response": "Yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "gplgt": {
#        "failure_response": "no",
#        "success_response": "yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "gplgt.sh": {
#        "failure_response": "no",
#        "success_response": "yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "gplgt.ps1": {
#        "failure_response": "no",
#        "success_response": "yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "lvmlgt": {
#        "failure_response": "false",
#        "success_response": "true",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "lvmlgt.sh": {
#        "failure_response": "false",
#        "success_response": "true",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "lvmlgt.ps1": {
#        "failure_response": "false",
#        "success_response": "true",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "sicstuslgt": {
#        "failure_response": "no",
#        "success_response": "yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "sicstuslgt.sh": {
#        "failure_response": "no",
#        "success_response": "yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "sicstuslgt.ps1": {
#        "failure_response": "no",
#        "success_response": "yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "swilgt": {
#        "failure_response": "false",
#        "success_response": "true",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "swilgt.sh": {
#        "failure_response": "false",
#        "success_response": "true",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "swilgt.ps1": {
#        "failure_response": "false",
#        "success_response": "true",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "tplgt": {
#        "failure_response": "false",
#        "success_response": "true",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "tplgt.sh": {
#        "failure_response": "false",
#        "success_response": "true",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "tplgt.ps1": {
#        "failure_response": "false",
#        "success_response": "true",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "yaplgt": {
#        "failure_response": "no",
#        "success_response": "yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "yaplgt.sh": {
#        "failure_response": "no",
#        "success_response": "yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    },
#    "yaplgt.ps1": {
#        "failure_response": "no",
#        "success_response": "yes",
#        "error_prefix": "!     ",
#        "informational_prefix": "% ",
#        "program_arguments": "default"
#    }
# }
