
install:
	python3 -m pip install -e .
	python3 -m prolog_kernel.install

clean:
	python3 -m pip uninstall logtalk_kernel
	jupyter kernelspec remove logtalk_kernel
