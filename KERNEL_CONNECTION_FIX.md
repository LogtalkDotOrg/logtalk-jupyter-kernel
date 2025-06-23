# Kernel Connection Fix for Widget Communication

## Problem
Widgets display correctly but show the error: "Kernel not available for widget update" when users interact with them.

## Root Cause
The JavaScript widget library cannot find a reference to the Jupyter kernel, which is needed to send widget value updates back to the Logtalk server.

## Solution Implemented

### 1. Enhanced Kernel Detection

The widget library now tries multiple methods to find the kernel:

```javascript
// Method 1: Direct Jupyter reference
if (typeof Jupyter !== 'undefined' && Jupyter.notebook && Jupyter.notebook.kernel) {
    this.kernel = Jupyter.notebook.kernel;
}
// Method 2: Parent window Jupyter
else if (typeof window.parent !== 'undefined' && window.parent.Jupyter && 
         window.parent.Jupyter.notebook && window.parent.Jupyter.notebook.kernel) {
    this.kernel = window.parent.Jupyter.notebook.kernel;
}
// Method 3: IPython fallback
else if (typeof window.IPython !== 'undefined' && window.IPython.notebook && 
         window.IPython.notebook.kernel) {
    this.kernel = window.IPython.notebook.kernel;
}
// Method 4: Retry with delay
else {
    setTimeout(() => this.init(), 500);
}
```

### 2. Robust Initialization Strategy

Multiple initialization approaches:

- DOM ready event
- Jupyter kernel ready event
- Jupyter kernel connected event
- Periodic retry attempts
- Fallback initialization

### 3. Runtime Kernel Recovery

The `sendWidgetUpdate` function now attempts to reconnect if the kernel is lost:

```javascript
// Try to get kernel if not available
if (!this.kernel) {
    this.init();
}

if (!this.kernel) {
    // Try alternative execution methods
    if (typeof Jupyter !== 'undefined' && Jupyter.notebook && Jupyter.notebook.kernel) {
        this.kernel = Jupyter.notebook.kernel;
    }
}
```

### 4. Manual Connection Function

Added a global function for manual debugging:

```javascript
// Available in browser console
connectLogtalkWidgetsToKernel();
```

## Testing Steps

### Step 1: Create a Widget and Test

```logtalk
jupyter::create_text_input(test_widget, 'Test Input:', 'initial_value').
```

### Step 2: Check Browser Console

Open browser developer console and look for:
- "Logtalk widget library loaded"
- "Kernel found via [method]"
- Any error messages

### Step 3: Manual Connection (if needed)

If you still see kernel errors, run in browser console:

```javascript
// Check status
console.log('LogtalkWidgets:', typeof LogtalkWidgets);
console.log('Jupyter:', typeof Jupyter);
console.log('Kernel:', Jupyter && Jupyter.notebook && Jupyter.notebook.kernel);

// Manual connection
connectLogtalkWidgetsToKernel();

// Test widget update
updateLogtalkWidget('test_widget', 'manual_test_value');
```

### Step 4: Verify Server-Side Update

```logtalk
jupyter::get_widget_value(test_widget, Value),
write('Widget value: '), write(Value), nl.
```

## Debug HTML Cell

Use this HTML cell to run comprehensive debugging:

```html
%%html
<script>
console.log('=== Logtalk Widget Debug ===');
console.log('LogtalkWidgets available:', typeof LogtalkWidgets !== 'undefined');
console.log('Jupyter available:', typeof Jupyter !== 'undefined');
console.log('Kernel available:', typeof Jupyter !== 'undefined' && Jupyter.notebook && !!Jupyter.notebook.kernel);

// Try manual connection
if (typeof connectLogtalkWidgetsToKernel !== 'undefined') {
    const connected = connectLogtalkWidgetsToKernel();
    console.log('Manual connection result:', connected);
}

// Debug widget state
if (typeof LogtalkWidgets !== 'undefined') {
    LogtalkWidgets.debugWidgets();
}

// Test widget update
if (typeof updateLogtalkWidget !== 'undefined') {
    updateLogtalkWidget('test_widget', 'javascript_test_value');
}
</script>
```

## Expected Behavior After Fix

1. **Widget Creation**: Widget displays with auto-registration
2. **User Interaction**: JavaScript captures events without kernel errors
3. **Value Update**: Updates sent to Logtalk server successfully
4. **Value Retrieval**: `jupyter::get_widget_value/2` returns current values

## Troubleshooting

### If kernel connection still fails:

1. **Check Jupyter Version**: Ensure compatible Jupyter notebook version
2. **Restart Kernel**: Try restarting the Logtalk kernel
3. **Reload Page**: Refresh the notebook page
4. **Check Console**: Look for JavaScript errors
5. **Manual Connection**: Use the debug functions provided

### Common Issues:

- **Timing**: Kernel might not be ready when widgets load
- **Context**: Widgets might be in different iframe context
- **Version**: Different Jupyter versions have different APIs

### Verification Commands:

```javascript
// In browser console
LogtalkWidgets.kernel !== null  // Should be true
LogtalkWidgets.debugWidgets()   // Shows registered widgets
```

```logtalk
% In Logtalk notebook
jupyter::debug_widgets.         % Shows server-side widget state
```

## Files Modified

1. `logtalk_kernel/kernelspec/logtalk_widgets.js` - Enhanced kernel detection
2. `notebooks/widget_debug_test.ipynb` - Added debug HTML cell

The widget communication should now work reliably with proper kernel connection and error recovery.
