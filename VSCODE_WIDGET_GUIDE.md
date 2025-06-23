# VS Code Compatible Widget Guide

## Overview

Since VS Code doesn't support HTML/JavaScript execution in non-Python kernels, this implementation provides **text-based interactive widgets** that work perfectly with the Logtalk kernel in VS Code.

## Key Features

✅ **Works in VS Code** - No HTML/JavaScript required  
✅ **Interactive prompts** - Real user input during execution  
✅ **Type validation** - Automatic number parsing and validation  
✅ **Default values** - Sensible defaults for quick testing  
✅ **State management** - Values persist between cells  
✅ **Multiple input types** - Text, numbers, choices, yes/no  

## Widget Types

### 1. Text Input Widget

```logtalk
jupyter::prompt_text_input(WidgetId, Prompt, DefaultValue).
```

**Example:**
```logtalk
jupyter::prompt_text_input(user_name, 'What is your name?', 'John Doe').
```

**Output:**
```
=== TEXT INPUT ===
Widget ID: user_name
What is your name?
Default: John Doe
Enter your value (or press Enter for default): [USER TYPES HERE]
Value set: [ENTERED VALUE]
==================
```

### 2. Number Input Widget

```logtalk
jupyter::prompt_number_input(WidgetId, Prompt, DefaultValue).
```

**Example:**
```logtalk
jupyter::prompt_number_input(user_age, 'What is your age?', 25).
```

**Features:**
- Automatic number validation
- Falls back to default for invalid input
- Supports integers and floats

### 3. Choice Widget

```logtalk
jupyter::prompt_choice(WidgetId, Prompt, OptionsList).
```

**Example:**
```logtalk
jupyter::prompt_choice(favorite_color, 'Choose your favorite color:', [red, green, blue, yellow]).
```

**Output:**
```
=== CHOICE INPUT ===
Widget ID: favorite_color
Choose your favorite color:
Options:
  1. red
  2. green
  3. blue
  4. yellow
Enter option number (1-4): [USER TYPES NUMBER]
Value set: [SELECTED OPTION]
==================
```

### 4. Yes/No Widget

```logtalk
jupyter::prompt_yes_no(WidgetId, Prompt).
```

**Example:**
```logtalk
jupyter::prompt_yes_no(likes_programming, 'Do you like programming?').
```

**Accepts:** y, yes, true, 1, n, no, false, 0 (case insensitive)

## Widget Management

### Get Widget Value

```logtalk
jupyter_vscode_widgets::get_widget_value(WidgetId, Value).
```

### Set Widget Value Directly

```logtalk
jupyter_vscode_widgets::set_widget_value(WidgetId, Value).
```

### Check if Widget Exists

```logtalk
jupyter_vscode_widgets::widget_exists(WidgetId).
```

### List All Widgets

```logtalk
jupyter::list_widgets.
```

### Clear All Widgets

```logtalk
jupyter::clear_widgets.
```

## Complete Example

### Step 1: Collect Information

```logtalk
% Collect user profile
collect_profile :-
    jupyter::prompt_text_input(name, 'Enter your name:', 'Anonymous'),
    jupyter::prompt_number_input(age, 'Enter your age:', 25),
    jupyter::prompt_choice(country, 'Select country:', [usa, canada, uk, germany, france]),
    jupyter::prompt_yes_no(newsletter, 'Subscribe to newsletter?').
```

### Step 2: Use the Information

```logtalk
% Display profile
show_profile :-
    jupyter_vscode_widgets::get_widget_value(name, Name),
    jupyter_vscode_widgets::get_widget_value(age, Age),
    jupyter_vscode_widgets::get_widget_value(country, Country),
    jupyter_vscode_widgets::get_widget_value(newsletter, Newsletter),
    
    format('Profile: ~w, ~w years old, from ~w~n', [Name, Age, Country]),
    (   Newsletter == true ->
        format('Subscribed to newsletter~n', [])
    ;   format('Not subscribed to newsletter~n', [])
    ).
```

### Step 3: Execute

```logtalk
collect_profile.
show_profile.
```

## Advanced Usage

### Survey System

```logtalk
programming_survey :-
    jupyter::prompt_text_input(participant_id, 'Participant ID:', 'P001'),
    jupyter::prompt_choice(experience, 'Experience level:', [beginner, intermediate, advanced]),
    jupyter::prompt_number_input(years, 'Years coding:', 0),
    jupyter::prompt_choice(language, 'Primary language:', [python, java, javascript, prolog, logtalk]),
    jupyter::prompt_yes_no(enjoys, 'Enjoy programming?').

analyze_survey :-
    jupyter_vscode_widgets::get_widget_value(participant_id, ID),
    jupyter_vscode_widgets::get_widget_value(experience, Level),
    jupyter_vscode_widgets::get_widget_value(years, Years),
    jupyter_vscode_widgets::get_widget_value(language, Lang),
    jupyter_vscode_widgets::get_widget_value(enjoys, Enjoys),
    
    format('Participant ~w: ~w level, ~w years, uses ~w, enjoys: ~w~n', 
           [ID, Level, Years, Lang, Enjoys]).
```

### Data Validation

```logtalk
validate_age(Age) :-
    Age >= 0,
    Age =< 150.

collect_valid_age :-
    jupyter::prompt_number_input(age, 'Enter age (0-150):', 25),
    jupyter_vscode_widgets::get_widget_value(age, Age),
    (   validate_age(Age) ->
        format('Valid age: ~w~n', [Age])
    ;   format('Invalid age, please try again~n', []),
        collect_valid_age
    ).
```

### Conditional Logic

```logtalk
adaptive_survey :-
    jupyter::prompt_yes_no(is_programmer, 'Are you a programmer?'),
    jupyter_vscode_widgets::get_widget_value(is_programmer, IsProgrammer),
    
    (   IsProgrammer == true ->
        jupyter::prompt_choice(language, 'Primary language:', [python, java, cpp, prolog]),
        jupyter::prompt_number_input(years, 'Years experience:', 0)
    ;   jupyter::prompt_choice(interest, 'Interest in programming:', [high, medium, low, none])
    ).
```

## Best Practices

### 1. Use Descriptive Widget IDs

```logtalk
% Good
jupyter::prompt_text_input(user_full_name, 'Full name:', '').

% Avoid
jupyter::prompt_text_input(x, 'Name:', '').
```

### 2. Provide Sensible Defaults

```logtalk
% Good - realistic default
jupyter::prompt_number_input(age, 'Age:', 25).

% Avoid - meaningless default
jupyter::prompt_number_input(age, 'Age:', 0).
```

### 3. Clear and Specific Prompts

```logtalk
% Good
jupyter::prompt_choice(experience, 'Programming experience level:', [beginner, intermediate, advanced]).

% Avoid
jupyter::prompt_choice(exp, 'Level:', [1, 2, 3]).
```

### 4. Validate Input When Needed

```logtalk
collect_email :-
    jupyter::prompt_text_input(email, 'Email address:', ''),
    jupyter_vscode_widgets::get_widget_value(email, Email),
    (   sub_atom(Email, _, _, _, '@') ->
        format('Email set: ~w~n', [Email])
    ;   format('Invalid email format~n', []),
        collect_email
    ).
```

## Troubleshooting

### Widget Values Not Persisting

**Problem:** Widget values disappear between cells.

**Solution:** Make sure you're using the correct predicates:
```logtalk
% Correct
jupyter_vscode_widgets::get_widget_value(widget_id, Value).

% Not this
jupyter::get_widget_value(widget_id, Value).  % This is for HTML widgets
```

### Input Not Being Captured

**Problem:** Prompts appear but input isn't captured.

**Solution:** Ensure you're running cells individually and waiting for prompts to complete.

### Invalid Number Input

**Problem:** Number widgets not accepting input.

**Solution:** The system automatically handles invalid input by using the default value. Check the output for validation messages.

## Comparison with HTML Widgets

| Feature | VS Code Widgets | HTML Widgets |
|---------|----------------|--------------|
| **Environment** | VS Code, Terminal | Jupyter Notebook, JupyterLab |
| **Interaction** | Text prompts | Visual controls |
| **JavaScript** | Not required | Required |
| **Real-time** | Sequential | Immediate |
| **Validation** | Server-side | Client + Server |
| **Accessibility** | High | Medium |

## Integration with Existing Code

The VS Code widgets integrate seamlessly with existing Logtalk code:

```logtalk
% Existing predicate
process_user_data(Name, Age, Country) :-
    format('Processing: ~w (~w) from ~w~n', [Name, Age, Country]).

% Enhanced with widgets
interactive_process :-
    jupyter::prompt_text_input(name, 'Name:', ''),
    jupyter::prompt_number_input(age, 'Age:', 0),
    jupyter::prompt_choice(country, 'Country:', [usa, canada, uk]),
    
    jupyter_vscode_widgets::get_widget_value(name, Name),
    jupyter_vscode_widgets::get_widget_value(age, Age),
    jupyter_vscode_widgets::get_widget_value(country, Country),
    
    process_user_data(Name, Age, Country).
```

This VS Code-compatible widget system provides a robust solution for interactive data input in Logtalk notebooks without requiring HTML/JavaScript support.
