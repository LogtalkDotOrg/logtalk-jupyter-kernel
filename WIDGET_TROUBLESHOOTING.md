# Widget Communication Troubleshooting Guide

This guide helps diagnose and fix issues with widget value communication between the frontend and Logtalk kernel.

## Problem Description

Widgets display correctly, but when users enter values, the followup goals fail to retrieve the entered values.

## Root Cause Analysis

The issue is in the communication flow between JavaScript frontend and Logtalk backend:

1. **Widget Registration**: Widgets need to be registered with the JavaScript library
2. **Value Updates**: User interactions must trigger proper value updates to the kernel
3. **State Synchronization**: Widget state must be maintained on both frontend and backend

## Fixes Implemented

### 1. Widget Auto-Registration

**Problem**: Widgets weren't being automatically registered when created.

**Fix**: Added auto-registration script to each widget HTML:

```javascript
setTimeout(function() {
  if (typeof autoRegisterWidget === "function") {
    autoRegisterWidget("widget_id", "widget_type", "initial_value");
  }
}, 100);
```

### 2. Improved Value Escaping

**Problem**: Special characters in widget values could break the Logtalk code generation.

**Fix**: Enhanced JavaScript value escaping:

```javascript
// Properly escape the value for Logtalk
let escapedValue;
if (typeof value === 'string') {
    // Escape single quotes and backslashes for Logtalk string literals
    escapedValue = value.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
    escapedValue = `'${escapedValue}'`;
} else if (typeof value === 'boolean') {
    escapedValue = value ? 'true' : 'false';
} else {
    escapedValue = String(value);
}
```

### 3. Debug Functions

**Problem**: No way to diagnose widget state issues.

**Fix**: Added debug functions on both frontend and backend:

**JavaScript Debug**:
```javascript
LogtalkWidgets.debugWidgets();  // Check frontend widget state
```

**Logtalk Debug**:
```logtalk
jupyter::debug_widgets.         % Check backend widget state
jupyter::list_all_widgets(Widgets).  % List all widgets
```

### 4. Enhanced JavaScript Library Loading

**Problem**: JavaScript library might not be properly loaded or initialized.

**Fix**: Improved library loading with proper initialization:

```javascript
// Ensure widget library is loaded only once
if (typeof LogtalkWidgets === 'undefined') {
    // Load library code
    console.log('Logtalk widget library loaded');
} else {
    console.log('Logtalk widget library already available');
}

// Ensure kernel reference is updated
if (typeof LogtalkWidgets !== 'undefined') {
    LogtalkWidgets.init();
}
```

## Testing Steps

### Step 1: Create Debug Test Notebook

Use the provided `widget_debug_test.ipynb` notebook to test widget functionality:

1. Create a simple text widget
2. Check widget state on server
3. Try to get widget value
4. Manually set widget value
5. Verify the change

### Step 2: Browser Console Debugging

Open browser developer console and run:

```javascript
// Check if LogtalkWidgets is available
console.log('LogtalkWidgets:', typeof LogtalkWidgets);

// Debug widget state
if (typeof LogtalkWidgets !== 'undefined') {
    LogtalkWidgets.debugWidgets();
}

// Check kernel connection
if (typeof Jupyter !== 'undefined' && Jupyter.notebook) {
    console.log('Kernel available:', !!Jupyter.notebook.kernel);
}

// Manually test widget update
if (typeof updateLogtalkWidget !== 'undefined') {
    updateLogtalkWidget('test_widget', 'manual_test_value');
}
```

### Step 3: Server-Side Debugging

In Logtalk notebook cells:

```logtalk
% Check if widget handling is loaded
current_object(jupyter_widget_handling).

% Debug widget state
jupyter::debug_widgets.

% List all widgets
jupyter::list_all_widgets(Widgets).

% Manually test widget operations
jupyter_widget_handling::set_widget_value(test_widget, 'server_test_value').
jupyter_widget_handling::get_widget_value(test_widget, Value).
```

## Common Issues and Solutions

### Issue 1: "LogtalkWidgets is undefined"

**Symptoms**: JavaScript console shows `LogtalkWidgets is undefined`

**Solution**: 
- Ensure the JavaScript library is being loaded with each widget
- Check that the `logtalk_widgets.js` file exists in `kernelspec/` directory
- Verify the file path in `send_widget_html()` method

### Issue 2: "Kernel not available for widget update"

**Symptoms**: Console shows kernel warning when interacting with widgets

**Solution**:
- Check that Jupyter notebook kernel is running
- Verify the kernel initialization in JavaScript
- Ensure `LogtalkWidgets.init()` is called after kernel is ready

### Issue 3: Widget values not updating on server

**Symptoms**: `jupyter::get_widget_value/2` returns old values

**Solution**:
- Check that `updateLogtalkWidget()` function is being called
- Verify the Logtalk code generation and execution
- Use debug functions to trace the update flow

### Issue 4: Widgets not registering automatically

**Symptoms**: `LogtalkWidgets.debugWidgets()` shows empty widget list

**Solution**:
- Ensure auto-registration script is included in widget HTML
- Check that `setTimeout` delay is sufficient for library loading
- Manually register widgets if needed

## Verification Checklist

- [ ] JavaScript library loads without errors
- [ ] Widgets are automatically registered
- [ ] User interactions trigger `updateLogtalkWidget()` calls
- [ ] Logtalk code executes successfully on the server
- [ ] Widget state is updated in the server database
- [ ] `get_widget_value/2` returns current values

## Advanced Debugging

### Network Traffic Analysis

1. Open browser Network tab
2. Interact with widgets
3. Look for kernel execute requests
4. Check request/response content

### Logtalk Server Logging

Enable verbose logging to see widget operations:

```logtalk
jupyter_preferences::set_preference(verbosity, 10).
```

### JavaScript Error Monitoring

Add error handlers to catch JavaScript issues:

```javascript
window.addEventListener('error', function(e) {
    console.error('JavaScript error:', e.error);
});
```

## Performance Considerations

- Widget updates are sent as silent kernel executions
- Each interaction generates a network request
- Consider batching updates for complex forms
- Use debouncing for rapid value changes (sliders)

## Security Notes

- All widget values are validated on the server
- JavaScript execution is sandboxed
- No sensitive data should be stored in widget state
- Input sanitization prevents code injection

## Future Improvements

1. **Batch Updates**: Group multiple widget changes
2. **Real-time Sync**: WebSocket-based communication
3. **Offline Support**: Local state persistence
4. **Validation**: Client-side input validation
5. **Performance**: Optimize update frequency

## Getting Help

If issues persist:

1. Check browser console for JavaScript errors
2. Review Logtalk server logs
3. Use the debug functions provided
4. Test with the debug notebook
5. Verify all files are in correct locations

The widget system should now properly handle value updates between frontend and backend. The debug tools will help identify any remaining communication issues.
