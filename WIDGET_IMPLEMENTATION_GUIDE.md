# Logtalk Jupyter Kernel Widget Implementation Guide

This guide provides detailed implementation plans for adding data input widgets to the Logtalk Jupyter kernel.

## Overview

Two approaches have been implemented for data input widgets in Logtalk notebooks:

1. **HTML/JavaScript Widgets** - Individual interactive widgets
2. **Form-Based Input System** - Structured forms for complex data collection

## Approach 1: HTML/JavaScript Widgets

### Architecture

The HTML/JavaScript widget system consists of:

- **Logtalk Server Components**: Widget handling predicates in `jupyter_widget_handling.lgt`
- **JavaScript Library**: Client-side widget management in `logtalk_widgets.js`
- **Python Integration**: Widget HTML rendering in the kernel implementation
- **Communication Layer**: Bidirectional data flow between frontend and kernel

### Implementation Components

#### 1. Logtalk Widget Handling (`jupyter_widget_handling.lgt`)

Provides predicates for creating and managing widgets:

```logtalk
% Create widgets
jupyter_widget_handling::create_text_input(WidgetId, Label, DefaultValue).
jupyter_widget_handling::create_number_input(WidgetId, Label, DefaultValue, Options).
jupyter_widget_handling::create_slider(WidgetId, Label, Min, Max, DefaultValue).
jupyter_widget_handling::create_dropdown(WidgetId, Label, Options).
jupyter_widget_handling::create_checkbox(WidgetId, Label, DefaultValue).
jupyter_widget_handling::create_button(WidgetId, Label).

% Manage widget state
jupyter_widget_handling::get_widget_value(WidgetId, Value).
jupyter_widget_handling::set_widget_value(WidgetId, Value).
jupyter_widget_handling::remove_widget(WidgetId).
```

#### 2. JavaScript Widget Library (`logtalk_widgets.js`)

Handles client-side widget functionality:

- Widget registration and state management
- Communication with Jupyter kernel
- DOM manipulation and event handling
- CSS styling for consistent appearance

#### 3. Python Kernel Integration

Extended `LogtalkKernelBaseImplementation` with:

- `send_widget_html()` method for rendering widgets
- `handle_widget_html()` method for processing widget data
- Integration with existing display data pipeline

### Usage Examples

```logtalk
% Create a text input widget
jupyter::create_text_input(name_input, 'Enter your name:', 'Default Name').

% Get the widget value
jupyter::get_widget_value(name_input, Name).

% Create a slider
jupyter::create_slider(temperature, 'Temperature', 0, 100, 25).

% Create a dropdown
jupyter::create_dropdown(color, 'Choose color:', [red, green, blue]).
```

## Approach 2: Form-Based Input System

### Architecture

The form-based system provides structured data collection through HTML forms:

- **Form Definition**: Declarative field specifications
- **HTML Generation**: Automatic form rendering
- **Data Collection**: JSON-based data submission
- **State Management**: Form data persistence

### Implementation Components

#### 1. Logtalk Form Handling (`jupyter_form_handling.lgt`)

Provides predicates for creating and managing forms:

```logtalk
% Create forms
jupyter_form_handling::create_input_form(FormId, FieldSpecs).
jupyter_form_handling::create_input_form(FormId, FieldSpecs, Options).

% Manage form data
jupyter_form_handling::get_form_data(FormId, Data).
jupyter_form_handling::clear_form_data(FormId).
```

#### 2. Field Types

Supported field types:

- `text_field(Name, Label, DefaultValue)`
- `number_field(Name, Label, DefaultValue)`
- `email_field(Name, Label, DefaultValue)`
- `password_field(Name, Label)`
- `textarea_field(Name, Label, DefaultValue, Rows)`
- `select_field(Name, Label, Options, DefaultValue)`
- `checkbox_field(Name, Label, DefaultValue)`

### Usage Examples

```logtalk
% Create a contact form
jupyter::create_input_form(contact_form, [
    text_field(name, 'Full Name:', ''),
    email_field(email, 'Email:', ''),
    number_field(age, 'Age:', 0),
    select_field(country, 'Country:', [usa, uk, canada], usa),
    textarea_field(message, 'Message:', '', 4)
], [
    title('Contact Information'),
    submit_label('Submit'),
    cancel_label('Cancel')
]).

% Get form data
jupyter::get_form_data(contact_form, Data).
```

## Installation Steps

### 1. File Structure

Ensure the following files are in place:

```
logtalk_kernel/
├── logtalk_server/
│   ├── jupyter_widget_handling.lgt
│   ├── jupyter_form_handling.lgt
│   └── jupyter.lgt (updated)
├── kernelspec/
│   └── logtalk_widgets.js
└── logtalk_kernel_base_implementation.py (updated)
```

### 2. Load Widget Objects

Update the Logtalk server startup to load widget handling objects:

```logtalk
% In the server initialization
:- logtalk_load([
    jupyter_widget_handling,
    jupyter_form_handling
]).
```

### 3. JavaScript Integration

The JavaScript library is automatically included when widgets are rendered. No additional setup is required.

## Features and Capabilities

### HTML/JavaScript Widgets

**Advantages:**
- Real-time interactivity
- Individual widget management
- Lightweight implementation
- Immediate feedback

**Supported Widgets:**
- Text input with validation
- Number input with min/max/step constraints
- Range sliders with live value display
- Dropdown selections
- Checkboxes for boolean input
- Clickable buttons

### Form-Based Input System

**Advantages:**
- Structured data collection
- Multiple field types in one interface
- Built-in validation
- Professional appearance

**Supported Features:**
- Multiple field types
- Form validation
- Custom styling
- Data persistence
- Configurable options

## Communication Protocol

### Widget to Kernel Communication

1. User interacts with widget in frontend
2. JavaScript event handler captures change
3. Data sent to kernel via `execute` request
4. Logtalk predicate updates widget state
5. Response sent back to frontend

### Kernel to Widget Communication

1. Logtalk predicate creates/updates widget
2. HTML content generated on server
3. Content sent via `display_data` message
4. Frontend renders widget
5. JavaScript initializes widget state

## Error Handling

### Widget Creation Errors

- Invalid widget parameters
- Missing required fields
- JavaScript execution errors

### Data Validation Errors

- Type mismatches
- Range violations
- Required field validation

### Communication Errors

- Network connectivity issues
- Kernel restart scenarios
- JavaScript runtime errors

## Performance Considerations

### Widget Rendering

- HTML generation is server-side
- JavaScript execution is client-side
- Minimal network overhead for updates

### State Management

- Widget state stored in Logtalk database
- Efficient lookup and update operations
- Automatic cleanup on widget removal

## Security Considerations

### Input Validation

- Server-side validation of all input
- Type checking and range validation
- XSS prevention in HTML generation

### JavaScript Execution

- Sandboxed execution environment
- No access to sensitive browser APIs
- Limited to widget functionality

## Testing and Debugging

### Widget Testing

1. Create widgets with various parameters
2. Test user interactions
3. Verify data persistence
4. Check error handling

### Form Testing

1. Create forms with all field types
2. Test form submission
3. Verify data collection
4. Test validation rules

### Debug Tools

- Browser developer console for JavaScript errors
- Logtalk server logs for backend issues
- Network tab for communication debugging

## Future Enhancements

### Planned Features

- Additional widget types (date picker, file upload)
- Advanced validation rules
- Widget styling customization
- Data export capabilities

### Integration Possibilities

- Database connectivity
- External API integration
- Real-time data visualization
- Collaborative editing features

## Troubleshooting

### Common Issues

1. **Widgets not displaying**: Check JavaScript console for errors
2. **Data not updating**: Verify kernel connectivity
3. **Styling issues**: Check CSS conflicts
4. **Form submission failing**: Validate field specifications

### Debug Commands

```logtalk
% Check widget state
jupyter_widget_handling::widget_exists(WidgetId).
jupyter_widget_handling::get_widget_value(WidgetId, Value).

% Check form state
jupyter_form_handling::form_exists(FormId).
jupyter_form_handling::get_form_data(FormId, Data).
```

## Conclusion

The widget implementation provides two complementary approaches for data input in Logtalk notebooks:

1. **HTML/JavaScript widgets** for simple, interactive controls
2. **Form-based input** for structured data collection

Both approaches integrate seamlessly with the existing Logtalk Jupyter kernel architecture and provide a foundation for building interactive notebook applications.
