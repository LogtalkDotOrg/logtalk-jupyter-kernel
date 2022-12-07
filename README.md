
# Hercutalk - A Jupyter Kernel for Logtalk

A [Jupyter](https://jupyter.org/) kernel for [Logtalk](https://logtalk.org/) based on [prolog-jupyter-kernel](https://github.com/hhu-stups/prolog-jupyter-kernel) and [IPython kernel](https://github.com/ipython/ipykernel).

This project is a fork of the [prolog-jupyter-kernel](https://github.com/hhu-stups/prolog-jupyter-kernel) project (developed by Anne Brecklinghaus in her Master's thesis at the University of Düsseldorf under the supervision of Michael Leuschel and Philipp Körner) and still under development. It includes back-ports of recent patches and improvements by Michael Leuschel, David Geleßus, and Silas Kraume. Major changes are committed and more are expected. Furthermore, no liability is accepted for correctness and completeness.


## Supported Prolog backends

- [ECLiPSe 7.0 #57 or later](http://eclipseclp.org/)
- [GNU Prolog 1.5.1 or later](http://www.gprolog.org/)
- [LVM 5.0.0 or later](https://graphstax.ai/)
- [SICStus Prolog 4.5.1 or later](https://sicstus.sics.se/)
- [SWI-Prolog 8.4.3 or later](https://www.swi-prolog.org/) (default)
- [Trealla Prolog 2.6.9 or later](https://github.com/trealla-prolog/trealla)
- [YAP 7.2.1 or later](https://github.com/vscosta) (requires Logtalk git version)

The kernel is implemented in a way that basically all functionality except the loading of configuration files can easily be overridden. This is especially useful for **extending the kernel for further Prolog backends** or running code with a different version of a backend. For further information about this, see [Configuration](#configuration).

Also see the [JupyterLab Logtalk CodeMirror Extension](https://github.com/LogtalkDotOrg/jupyterlab-logtalk-codemirror-extension) for *syntax highlighting* of Logtalk code in JupyterLab (forked from the [JupyterLab Prolog CodeMirror Extension](https://github.com/hhu-stups/jupyterlab-prolog-codemirror-extension)).


## Examples

The directory [notebooks](./notebooks) contains some example Juypter notebooks, including a Logtalk short tutorial and a notebook giving an overview of the kernel's features and its implementation. Note that all of them can be viewed with [nbviewer](https://nbviewer.org/) without having to install the kernel.


## Installation

### Requirements

- At least **Python** 3.5
  - Tested with Python 3.10.8
- **Jupyter** installation with JupyterLab and/or Juypter Notebook
  - Tested with
    - `jupyter_core`: 5.1.0
    - `jupyterlab`: 3.5.0
    - `notebook`: 6.5.2
- Logtalk 3.60.0 or later version
- One or more supported Prolog backends (see above)
- For Windows, installing **Graphviz** with `python3 -m pip` does not suffice
  - Instead, it can be installed from [here](https://graphviz.org/download/) and added to the `PATH` (a reboot is required afterwards)

The installation was tested with macOS 12.6.1, Ubuntu 20.0.4, and Windows 10.


### Install

1. `python3 -m pip install --upgrade jupyterlab`
2. `git clone https://github.com/LogtalkDotOrg/logtalk-jupyter-kernel`
3. `cd logtalk-jupyter-kernel`
4. `make install`

By default, `make install` uses `sys.prefix`. If it fails with a permission error, you can retry using either `sudo make install` or repeat its last step using `python3 -m logtalk_kernel.install --user` or `python3 -m logtalk_kernel.install --prefix PREFIX`.


### Uninstall

1. `cd logtalk-jupyter-kernel`
2. `make clean`


## Running

Logtalk notebooks can be run using JupyterLab, Jupyter notebook, or VSCode.

### Running using JupyterLab

Simply start JupyterLab (e.g. by typing `jupyter-lab` in a shell) and then click on the Logtalk Notebook (or Logtalk Console) icon in the Launcher or open an existing notebook.

### Running using Jupyter notebook

Simply start Jupyter notebook (e.g. by typing `jupyter notebook` in a shell) and then open an existing notebook.

### Running using VSCode

Simply open an existing notebook. Ensure that the [Logtalk plug-in for VSCode](https://github.com/jacobfriedman/vsc-logtalk) for syntax highlighting in code cells.

### Configuration

The kernel can be configured by defining a Python config file named `logtalk_kernel_config.py`. The kernel will look for this file in the Jupyter config path (can be retrieved with `jupyter --paths`) and the current working directory. An **example** of such a configuration file with an explanation of the options and their default values commented out can be found [here](./logtalk_kernel/logtalk_kernel_config.py).

**Note:** If a config file exists in the current working directory, it overrides values from other configuration files.

In general, the kernel can be configured to use a different Prolog backend (which is responsible for code execution) or kernel implementation. Furthermore, it can be configured to use another Prolog backend altogether which might not be supported by default. The following options can be configured:
- `jupyter_logging`: If set to `True`, the logging level is set to DEBUG by the kernel so that **Python debugging messages** are logged.
  - Note that this way, logging debugging messages can only be enabled after reading a configuration file. Therefore, for instance, the user cannot be informed that no configuration file was loaded if none was defined at one of the expected locations.
  - In order to switch on debugging messages by default, the development installation described in the GitHub repository can be followed and the logging level set to `DEBUG` in the file `kernel.py` (which contains a corresponding comment).
  - However, note that this causes messages to be printed in the Jupyter console applications, which interferes with the other output.

- `server_logging`: If set to `True`, a **Logtalk server log file** is created.
  - The name of the file consists of the implementation ID preceded by `.logtalk_server_log_`.
- `backend_id`: The ID of the **Prolog backend integration script** with which the server is started.
- `backend_data`: The **Prolog backend-specific data** which is needed to run the server for code execution.
  - This is required to be a dictionary containing at least an entry for the configured `backend_id`.
  - Each entry needs to define values for
    - `failure_response`: The output which is displayed if a query **fails**
    - `success_response`: The output which is displayed if a query **succeeds without any variable bindings**
    - `error_prefix`: The prefix that is output for **error messages**
    - `informational_prefix`: The prefix that is output for **informational messages**
    - `program_arguments`: **Command line arguments** with which the Logtalk server can be started
      - All supported Prolog backends can be used by configuring the string `"default"`.
  - Additionally, a `kernel_implementation_path` can be provided, which needs to be an **absolute path to a Python file**:
    - The corresponding module is required to define a subclass of `LogtalkKernelBaseImplementation` named `LogtalkKernelImplementation`. This can be used to override some of the kernel's basic behavior (see [Overriding the Kernel Implementation](#overriding-the-kernel-implementation)).

### Changing the Prolog backend in the fly

In most cases, the following shortcuts can be used:

- ECLiPSe: `eclipse`
- GNU Prolog: `gnu`
- LVM : `lvm`
- SICStus Prolog: `sicstus`
- SWI-Prolog (default backend): `swi` 
- Trealla Prolog: `trealla`
- YAP: `yap`

If the shortcuts don't work due to some unusal Logtalk or Prolog backend setup, the `jupyter::set_prolog_backend(+Backend)` predicate is provided. In order for this to work, the configured `backend_data` dictionary needs to contain data for more than one Prolog backend. For example (in a notebook code cell):

	jupyter::set_prolog_backend('lvmlgt.sh').

The predicate argument is the name of the integration script used to run Logtalk. On Windows, always use the PowerShell scripts (e.g. `sicstuslgt.ps1`). On POSIX systems, use the ones that work for your Logtalk installation (e.g. if you're using Logtalk with Trealla Prolog with a setup that requires the `.sh` extension when running the integration script, then use `tplgt.sh` instead of just `tplgt`).

**Troubleshooting:**
In case of SICStus Prolog, if the given **`program_arguments` are invalid** (e.g. if the Prolog code file does not exist), the kernel waits for a response from the server which it will never receive. In that state it is **not able to log any exception** and instead, nothing happens.
To facilitate finding the cause of the error, before trying to start the Logtalk server, the arguments and the directory from which they are tried to be executed are logged.

### Overriding the Kernel Implementation

The actual kernel code determining the handling of requests is not implemented by the kernel class itself. Instead, there is the file [logtalk_kernel_base_implementation.py](./logtalk_kernel/logtalk_kernel_base_implementation.py) which defines the class `LogtalkKernelBaseImplementation`. When the kernel is started, a (sub)object of this class is created. It handles the starting of and communication with the Logtalk server. For all requests (execution, shutdown, completion, inspection) the kernel receives, a `LogtalkKernelBaseImplementation` method is called. By **creating a subclass** of this and defining the path to it as `kernel_implementation_path`, the **actual implementation code can be replaced**. If no such path is defined, the path itself or the defined class is invalid, a **default implementation** is used instead.


## Development

### Local Changes

In general, in order for local code adjustments to take effect, the kernel needs to be reinstalled. When installing the local project in *editable* mode with `python3 -m pip install -e .` (e.g. by running `make`), restarting the kernel suffices.

Adjustments of the Logtalk server code are loaded when the server is restarted. Thus, when changing Logtalk code only, instead of restarting the whole kernel, it can be interrupted, which causes the Logtalk server to be restarted.

### Debugging

Usually, if the execution of a goal causes an exception, the corresponding Logtalk error message is computed and displayed in the Jupyter frontend. However, in case something goes wrong unexpectedly or the query does not terminate, the **Logtalk server might not be able to send a response to the client**. In that case, the user can only see that the execution does not terminate without any information about the error or output that might have been produced. However, it is possible to write logging messages and access any potential output, which might facilitate finding the cause of the error.

Debugging the server code is not possible in the usual way by tracing invocations. Furthermore, all messages exchanged with the client are written to the standard streams. Therefore, printing helpful debugging messages does not work either. Instead, if `server_logging` is configured, **messages can be written to a log file** by calling `log/1` or `log/2` from the `jupyter_logging` object. By default, only the responses sent to the client are logged.

When a query is executed, all its output is written to a file named `.server_output`, which is deleted afterwards by `jupyter_query_handling::delete_output_file`. If an error occurs during the actual execution, the file cannot be deleted and thus, the **output of the goal can be accessed**. Otherwise, the deletion might be prevented.

Furthermore, the server might send a response which the client cannot handle. In that case, **logging for the Python code** can be enabled by configuring `jupyter_logging`. For instance, the client logs the responses received from the server.
