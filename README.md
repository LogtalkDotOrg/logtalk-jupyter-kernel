
# Hercutalk - A Jupyter Kernel for Logtalk

A [Jupyter](https://jupyter.org/) kernel for [Logtalk](https://logtalk.org/) based on [prolog-jupyter-kernel](https://github.com/hhu-stups/prolog-jupyter-kernel) and [IPython kernel](https://github.com/ipython/ipykernel).

This project is a fork of the [prolog-jupyter-kernel](https://github.com/hhu-stups/prolog-jupyter-kernel) project (developed by Anne Brecklinghaus in her Master's thesis at the University of Düsseldorf under the supervision of Michael Leuschel and Philipp Körner) and still under development. It includes back-ports of recent patches and improvements by Michael Leuschel, dgelessus, and Silas Kraume. Major changes are committed and more are expected. Furthermore, no liability is accepted for correctness and completeness (see the [LICENSE](LICENSE) file).

🙏 Sponsored by [Permion](https://permion.ai/) and [GitHub Sponsors](https://github.com/sponsors/pmoura).


## Supported Logtalk version

Logtalk 3.81.0 (or later version) plus at least one of the supported Prolog backends. The `LOGTALKHOME` and `LOGTALKUSER` environment variables **must** be defined.


## Supported Prolog backends and versions

- [ECLiPSe 7.0 #57 or later](http://eclipseclp.org/)
- [GNU Prolog 1.6.0 or later](http://www.gprolog.org/) (use git version until 1.6.0 is released)
- [SICStus Prolog 4.5.1 or later](https://sicstus.sics.se/)
- [SWI-Prolog 8.4.3 or later](https://www.swi-prolog.org/) (default)
- [Trealla Prolog 2.65.5 or later](https://github.com/trealla-prolog/trealla)
- [XVM 10.0.0 or later](https://permion.ai/)
- [YAP 7.2.1 or later](https://github.com/vscosta)

Note that a public online use of this kernel (instead of private or local) may be restricted to a subset of these backends (notably, due to some systems requiring commercial licenses).

The kernel is implemented in a way that basically all functionality except the loading of configuration files can easily be overridden. This is especially useful for **extending the kernel for further Prolog backends** or running code with a different version of a backend. For further information about this, see [Configuration](#configuration).

Also see the [JupyterLab Logtalk CodeMirror Extension](https://github.com/LogtalkDotOrg/jupyterlab-logtalk-codemirror-extension) for *syntax highlighting* of Logtalk code in JupyterLab (forked from the [JupyterLab Prolog CodeMirror Extension](https://github.com/hhu-stups/jupyterlab-prolog-codemirror-extension)).


## Examples

The directory [notebooks](./notebooks) contains some example Juypter notebooks, including a Logtalk short tutorial and a notebook giving an overview of the kernel's features and its implementation. Note that all of them can be viewed with [nbviewer](https://nbviewer.org/) without having to install the kernel.


## Install

The kernel is provided as a Python package on the Python Package Index and can be installed with `pip`:

	python3 -m pip install --upgrade logtalk-jupyter-kernel
	python3 -m logtalk_kernel.install

There are the following options which can be seen when running `python3 -m logtalk_kernel.install --help`

- `--user`: install to the per-user kernel registry instead of `sys.prefix` (use if you get permission errors during installation)
- `--prefix PREFIX`: install to the given prefix: `PREFIX/share/jupyter/kernels/`


## Uninstall

	python3 -m pip uninstall logtalk_kernel
	jupyter kernelspec remove logtalk_kernel


## Running

Logtalk notebooks can be run using JupyterLab, JupyterLab Desktop, Jupyter notebook, or VSCode.

### Running using JupyterLab

Simply start JupyterLab (e.g. by typing `jupyter-lab` in a shell) and then click on the Logtalk Notebook (or Logtalk Console) icon in the Launcher or open an existing notebook.

### Running using JupyterLab Desktop

On macOS, JupyterLab Desktop **must** be started from a shell where the `LOGTALKHOME` and `LOGTALKUSER` environment variables are defined so that they are inherited by the JupyterLab Desktop process. Typically:

	$ open /Applications/JupyterLab.app

This is not an issue on Linux or Windows where, assuming that the `LOGTALKHOME` and `LOGTALKUSER` environment variables are defined, JupyterLab Desktop can be started by double-clicking its icon.

### Running using Jupyter notebook

Simply start Jupyter notebook (e.g. by typing `jupyter notebook` in a shell) and then open an existing notebook.

### Running using VSCode

Simply open an existing notebook. Ensure that the [Logtalk plug-in for VSCode](https://github.com/LogtalkDotOrg/logtalk-for-vscode) is also installed for syntax highlighting in code cells.

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
- `backend`: The name of the **Prolog backend integration script** with which the server is started.
- `backend_data`: The **Prolog backend-specific data** which is needed to run the server for code execution.
  - This is required to be a dictionary containing at least an entry for the configured `backend`.
  - Each entry needs to define values for
    - `failure_response`: The output which is displayed if a query **fails**
    - `success_response`: The output which is displayed if a query **succeeds without any variable bindings**
    - `error_prefix`: The prefix that is output for **error messages**
    - `informational_prefix`: The prefix that is output for **informational messages**
    - `program_arguments`: **Command line arguments** with which the Logtalk server can be started
      - All supported Prolog backends can be used by configuring the string `"default"`.
  - Additionally, a `kernel_implementation_path` can be provided, which needs to be an **absolute path to a Python file**:
    - The corresponding module is required to define a subclass of `LogtalkKernelBaseImplementation` named `LogtalkKernelImplementation`. This can be used to override some of the kernel's basic behavior (see [Overriding the Kernel Implementation](#overriding-the-kernel-implementation)).

If the given **`program_arguments` are invalid**, the kernel waits for a response from the server which it will never receive. In that state it is **not able to log any exception** and instead, nothing happens. To facilitate finding the cause of the error, before trying to start the Logtalk server, the arguments and the directory from which they are tried to be executed are logged.


### Defining environment variables for notebooks

Notebooks may require defining environment variables. For example, a notebook running one of the Java integration examples found in the Logtalk distribution may require  the `CLASSPATH` environment variable to be set. This can be easily accomplished by adding a `logtalk_kernel_config.py` file to the notebook directory and using the `os.environ` Python dictionary. For the Logtalk `document_converter` example, which uses Apache Tika, assuming we copied the JAR file to the notebook directory, we could write:

	os.environ['CLASSPATH'] = './tika-app-2.8.0.jar'


### Using virtual environment for Logtalk packs

Notebooks may require loading Logtalk packs. Ideally, when sharing notebooks with other users, those packs should be installed in a virtual environment to avoid any conflicts with user installed packs or pack versions. The `lgtenv` script provided by the Logtalk distribution can be used to create the packs virtual environment in the same directory as the notebook. For example:

	$ cd my_notebook_directory
	$ lgtenv -p logtalk_packs

The packs can be pre-installed before sharing e.g. an archive with the notebook directory contents. Alternatively, installing the packs can be left to the user by providing a `requirements.lgt` file. For example:

	registry(talkshow, 'https://github.com/LogtalkDotOrg/talkshow').
	pack(talkshow, lflat, 2:1:0).

In this case, the user will need to run (possibly from a notebook code cell) the query:

	?- logtalk_load(packs(loader)), packs::restore('requirements.lgt').

We also must ensure that the virtual environment will be used when the notebook runs. The best solution is to create a `settings.lgt` file in the same directory as the notebook defining the `logtalk_packs` library alias. For example, assuming a `logtalk_packs` sub-directory for the virtual environment:

	:- multifile(logtalk_library_path/2).
	:- dynamic(logtalk_library_path/2).

	:- initialization((
		logtalk_load_context(directory, Directory),
		atom_concat(Directory, logtalk_packs, VirtualEnvironment),
		asserta(logtalk_library_path(logtalk_packs, VirtualEnvironment))
	)).


### Changing the Prolog backend in the fly

In most cases, the following shortcuts can be used:

- ECLiPSe: `eclipse`
- GNU Prolog: `gnu`
- SICStus Prolog: `sicstus`
- SWI-Prolog (default backend): `swi` 
- Trealla Prolog: `trealla`
- XVM : `xvm`
- YAP: `yap`

If the shortcuts don't work due to some unusal Logtalk or Prolog backend setup, the `jupyter::set_prolog_backend(+Backend)` predicate is provided. In order for this to work, the configured `backend_data` dictionary needs to contain data for more than one Prolog backend. For example (in a notebook code cell):

	jupyter::set_prolog_backend('xvmlgt.sh').

The predicate argument is the name of the integration script used to run Logtalk. On Windows, always use the PowerShell scripts (e.g. `sicstuslgt.ps1`). On POSIX systems, use the ones that work for your Logtalk installation (e.g. if you're using Logtalk with Trealla Prolog with a setup that requires the `.sh` extension when running the integration script, then use `tplgt.sh` instead of just `tplgt`).


## Development

### Requirements

- At least **Python** 3.7
  - Tested with Python 3.11.7
- **Jupyter** installation with JupyterLab and/or Juypter Notebook
  - Tested with
    - `jupyter_core`: 5.7.2
    - `jupyterlab`: 4.2.3
    - `notebook`: 7.2.1
	- `jupytext`: 1.16.7
- Logtalk and one or more supported Prolog backends (see above)
- Installing **Graphviz** with `python3 -m pip` may not suffice (notably, on Windows)
  - Also run the Graphviz [installer](https://graphviz.org/download/) and add its executables to the `PATH` (a reboot may be required afterwards)

The installation was tested with macOS 14.5, Ubuntu 20.0.4, and Windows 10.

### Install

	python3 -m pip install --upgrade jupyterlab
	git clone https://github.com/LogtalkDotOrg/logtalk-jupyter-kernel
	cd logtalk-jupyter-kernel
	make install

By default, `make install` uses `sys.prefix`. If it fails with a permission error, you can retry using either `sudo make install` or repeat its last step using `python3 -m logtalk_kernel.install --user` or `python3 -m logtalk_kernel.install --prefix PREFIX`.

On Ubuntu, if `make install` fails with an error, try to update `pip` to its latest version by running `python3 -m pip install --upgrade pip`.

### Uninstall

	cd logtalk-jupyter-kernel
	make clean

### Local Changes

In general, in order for local code adjustments to take effect, the kernel needs to be reinstalled. When installing the local project in *editable* mode with `python3 -m pip install -e .` (e.g. by running `make`), restarting the kernel suffices.

Adjustments of the Logtalk server code are loaded when the server is restarted. Thus, when changing Logtalk code only, instead of restarting the whole kernel, it can be interrupted, which causes the Logtalk server to be restarted.

### Building and publishing

Make sure that both the `pyproject.toml` file and the `jupyter` object (in the `logtalk_kernel/logtalk_server/jupyter.lgt` file) report the same kernel version. 

	python3 -m build .
	twine upload dist/logtalk_jupyter_kernel-VERSION.tar.gz dist/logtalk_jupyter_kernel-VERSION-py3-none-any.whl

### Debugging

If you get a `Failed to start the Kernel.` error after selecting the Logtalk kernel, make sure that the `LOGTALKHOME` and `LOGTALKUSER` environment variables are defined.

Usually, if the execution of a goal causes an exception, the corresponding Logtalk error message is captured and displayed in the Jupyter frontend. However, in case something goes wrong unexpectedly or the query does not terminate, the **Logtalk server might not be able to send a response to the client**. In that case, the user can only see that the execution does not terminate without any information about the error or output that might have been produced. However, it is possible to write logging messages and access any potential output, which might facilitate finding the cause of the error.

Debugging the server code is not possible in the usual way by tracing invocations. Furthermore, all messages exchanged with the client are written to the standard streams. Therefore, printing helpful debugging messages does not work either. Instead, if `server_logging` is configured, **messages can be written to a log file** by calling `log/1` or `log/2` from the `jupyter_logging` object. By default, only the responses sent to the client are logged.

When a query is executed, all its output is written to a file named `.server_output`, which is deleted afterwards by `jupyter_query_handling::delete_output_file`. If an error occurs during the actual execution, the file cannot be deleted and thus, the **output of the goal can be accessed**. Otherwise, the deletion might be prevented.

Furthermore, the server might send a response which the client cannot handle. In that case, **logging for the Python code** can be enabled by configuring `jupyter_logging`. For instance, the client logs the responses received from the server.

When the Logtalk code makes calls to foreign language libraries (notably C or C++ code), it's possible that output is generated that is not diverted to a file when the kernel redirects the Prolog output streams. This unexpected output is most likely not a valid JSON payload and thus breaks communication between the notebook and the kernel. In this case, the notebook displays the following error:

	Something went wrong
	The Logtalk server needs to be restarted

These issues can be debugged by running the problematic query in a terminal after diverting the Prolog output streams to a file. For example, assuming in the Prolog backend you're using the stream redirecting uses a `set_stream/2` predicate:

	?- open(out, write, S),
	   set_stream(S, alias(current_output)),
	   set_stream(S, alias(user_output)),
	   set_stream(S, alias(user_error)),
	   goal,
	   close(S).

If you get any output while the goal is running (e.g. foreign library debugging messages), you will need to find a way to turn off that output.

### Prolog backend requirements

Adding support for other Prolog backends requires:

- Command-line option(s) to silence (quiet) any banner and informative messages.
- Programatic solution to check if a quiet command-line option was used to start the Logtalk/Prolog process (e.g. by checking a boolean Prolog flag).
- Ability to redirect current output (including `user_output` and `user_error`) to a different stream and restoring the previous stream when the redirection is terminated.

### Overriding the Kernel Implementation

The actual kernel code determining the handling of requests is not implemented by the kernel class itself. Instead, there is the file [logtalk_kernel_base_implementation.py](./logtalk_kernel/logtalk_kernel_base_implementation.py) which defines the class `LogtalkKernelBaseImplementation`. When the kernel is started, a (sub)object of this class is created. It handles the starting of and communication with the Logtalk server. For all requests (execution, shutdown, completion, inspection) the kernel receives, a `LogtalkKernelBaseImplementation` method is called. By **creating a subclass** of this and defining the path to it as `kernel_implementation_path`, the **actual implementation code can be replaced**. If no such path is defined, the path itself or the defined class is invalid, a **default implementation** is used instead.
