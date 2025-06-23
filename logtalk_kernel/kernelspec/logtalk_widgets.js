/**
 * Logtalk Jupyter Kernel Widget Support
 */

// Core widget system
window.LogtalkWidgets = {
    widgets: new Map(),
    kernelReady: false,
    __widgetQueue: [],

    updateWidgetValue: async function(widgetId, value) {
        return this._updateWidgetValue(widgetId, value);
    },

    autoRegisterWidget: async function(widgetId) {
        return this._registerWidget(widgetId);
    },
};

window.autoRegisterWidget = async function(widgetId) {
    if (window.LogtalkWidgets && window.LogtalkWidgets._registerWidget) {
        return window.LogtalkWidgets._registerWidget(widgetId);
    }
    console.warn('Widget registration queued:', widgetId);
    window.__widgetQueue.push({ type: 'register', widgetId });
    return false;
};

// Initialize core widget system
window.LogtalkWidgets = {
    widgets: new Map(),
    kernelReady: false,

    init: function() {
        console.log('Initializing LogtalkWidgets...');
        // Process any queued operations
        while (window.__widgetQueue && window.__widgetQueue.length > 0) {
            const op = window.__widgetQueue.shift();
            if (op.type === 'register') {
                this._registerWidget(op.widgetId);
            } else if (op.type === 'update') {
                this._updateWidgetValue(op.widgetId, op.value);
            }
        }
        console.log('LogtalkWidgets initialization complete');
    },

    // Register a widget
    _registerWidget: async function(widgetId) {
        console.log('Registering widget:', widgetId);
        if (this.widgets.has(widgetId)) {
            console.log('Widget already registered:', widgetId);
            return true;
        }

        const container = document.getElementById('container_' + widgetId);
        if (!container) {
            console.error('Widget container not found:', widgetId);
            return false;
        }

        const element = container.querySelector('input, select, textarea, button');
        if (!element) {
            console.error('Widget element not found:', widgetId);
            return false;
        }

        this.widgets.set(widgetId, {
            container,
            element,
            value: element.value
        });
        
        console.log('✅ Widget registered:', widgetId);
        return true;
    },

    // Update widget value
    _updateWidgetValue: async function(widgetId, value) {
        if (!this.widgets.has(widgetId)) {
            console.error('Widget not registered:', widgetId);
            return false;
        }

        const widget = this.widgets.get(widgetId);
        try {
            const element = widget.element;

            // Normalize value based on widget type
            let normalizedValue;
            let formattedValue;

            switch (element.type) {
                case 'checkbox':
                    normalizedValue = Boolean(value === true || value === 'true');
                    formattedValue = normalizedValue ? 'true' : 'false';
                    element.checked = normalizedValue;
                    break;

                case 'number':
                case 'range':
                    normalizedValue = Number.isFinite(parseFloat(value)) ? parseFloat(value) : 0;
                    formattedValue = String(normalizedValue);
                    element.value = normalizedValue;
                    
                    // Update display for sliders
                    if (element.type === 'range') {
                        const valueDisplay = document.getElementById(`${widgetId}_value`);
                        if (valueDisplay) {
                            valueDisplay.textContent = normalizedValue;
                        }
                    }
                    break;

                case 'button':
                    normalizedValue = 'clicked';
                    formattedValue = "'clicked'";
                    break;

                default: // text, select
                    normalizedValue = String(value);
                    formattedValue = `'${normalizedValue}'`;
                    element.value = normalizedValue;
            }

            // Update widget state
            widget.value = normalizedValue;

            // Notify kernel
            const code = `jupyter_widget_handling::set_widget_value('${widgetId}', ${formattedValue}).`;
            const result = await jupyter.notebook.kernel.do_execute(code, {
                silent: true,
                store_history: false
            });

            console.log(`Widget ${widgetId} updated:`, {
                type: element.type,
                value: normalizedValue,
                formattedValue,
                result: result.status
            });

            return result && result.status === 'ok';
        } catch (error) {
            console.error('Error updating widget:', error);
            return false;
        }
    }
};

// Ensure widget system functions are always initialized first
const WidgetSystem = {
    updateWidgetValue: async function(widgetId, value) {
        if (window.LogtalkWidgets && window.LogtalkWidgets._updateWidgetValue) {
            return window.LogtalkWidgets._updateWidgetValue(widgetId, value);
        }
        return false;
    },
    autoRegisterWidget: async function(widgetId) {
        if (window.LogtalkWidgets && window.LogtalkWidgets._registerWidget) {
            return window.LogtalkWidgets._registerWidget(widgetId);
        }
        return false;
    }
};

window.updateWidgetValue = WidgetSystem.updateWidgetValue;
window.autoRegisterWidget = WidgetSystem.autoRegisterWidget;

// Initialize the kernel interface
(async function() {
    console.log('Initializing Logtalk widget system...');
    
    // Wait for kernel interface
    let retries = 0;
    while (!jupyter.notebook.kernel && retries < 50) {
        await new Promise(resolve => setTimeout(resolve, 100));
        retries++;
    }

    if (!jupyter.notebook.kernel) {
        console.error('Kernel interface not available after retries');
        return;
    }

    // Test kernel connection
    try {
        const result = await jupyter.notebook.kernel.do_execute('true.', {
            silent: true,
            store_history: false
        });
        
        if (result && result.status === 'ok') {
            window.LogtalkWidgets.kernelReady = true;
            console.log('✅ Widget system initialization complete');
        } else {
            console.error('❌ Kernel test failed');
        }
    } catch (error) {
        console.error('Error initializing kernel:', error);
    }
})();
