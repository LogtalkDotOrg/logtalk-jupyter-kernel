
install:
	pip install -e .
	python -m logtalk_kernel.install

sics_tests:
	sicstus -l logtalk_kernel/prolog_server/jupyter_server_tests.pl --goal "run_tests,halt."
swi_tests:
	swipl -l logtalk_kernel/prolog_server/jupyter_server_tests.pl -t "run_tests,halt."


clean:
	pip uninstall logtalk_kernel
	jupyter kernelspec remove logtalk_kernel
