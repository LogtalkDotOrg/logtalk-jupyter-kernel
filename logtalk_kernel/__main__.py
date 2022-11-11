from ipykernel.kernelapp import IPKernelApp
from logtalk_kernel.kernel import LogtalkKernel

IPKernelApp.launch_instance(kernel_class=LogtalkKernel)
