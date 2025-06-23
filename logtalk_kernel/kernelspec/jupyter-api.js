// Jupyter API for Logtalk Kernel
(function(global) {
    if (typeof global.define !== 'function') {
        global.define = function(deps, callback) {
            if (typeof callback === 'function') {
                return callback();
            }
            return {};
        };
    }

    if (typeof global.requirejs !== 'function') {
        global.requirejs = global.define;
    }

    class JupyterKernel {
        constructor() {
            this.name = 'logtalk';
            this.id = crypto.randomUUID();
            this.status = 'idle';
            this._callbacks = new Map();
        }

        async kernel_info() {
            return {
                content: {
                    status: 'ok',
                    protocol_version: '5.3',
                    implementation: 'logtalk',
                    implementation_version: '1.0',
                    language_info: {
                        name: 'logtalk',
                        version: '1.0',
                        mimetype: 'text/x-logtalk',
                        file_extension: '.lgt'
                    }
                }
            };
        }

        addEventListener(event, callback) {
            if (!this._callbacks.has(event)) {
                this._callbacks.set(event, new Set());
            }
            this._callbacks.get(event).add(callback);
        }

        removeEventListener(event, callback) {
            if (this._callbacks.has(event)) {
                this._callbacks.get(event).delete(callback);
            }
        }

        _emit(event, data) {
            if (this._callbacks.has(event)) {
                for (const callback of this._callbacks.get(event)) {
                    callback(data);
                }
            }
        }
    }

    class JupyterUtils {
        static requireKernel(callback) {
            if (callback && typeof callback === 'function') {
                setTimeout(callback, 0);
            }
        }
    }

    // Export Jupyter namespace and ensure it's on window
    const jupyter = {
        notebook: {
            kernel: new JupyterKernel()
        },
        utils: new JupyterUtils(),
        events: new EventTarget()
    };
    
    // Make sure it's available both on global and window
    global.Jupyter = jupyter;
    if (typeof window !== 'undefined') {
        window.Jupyter = jupyter;
    }

    // Define window.JUPYTER_KERNEL
    const jupyterKernelInstance = jupyter.notebook.kernel;
    global.JUPYTER_KERNEL = jupyterKernelInstance;
    if (typeof window !== 'undefined') {
        window.JUPYTER_KERNEL = jupyterKernelInstance;
    }

    // Export jQuery-like selector
    if (typeof global.$ !== 'function') {
        global.$ = function(selector) {
            return {
                ready: function(callback) {
                    if (document.readyState === 'complete') {
                        callback();
                    } else {
                        document.addEventListener('DOMContentLoaded', callback);
                    }
                }
            };
        };
    }
})(typeof self !== 'undefined' ? self : this);
