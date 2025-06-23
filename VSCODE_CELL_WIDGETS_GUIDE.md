# VS Code Cell-Based Widget System

## ✅ **WORKING SOLUTION FOR VS CODE**

This is a **cell-based widget system** that works perfectly in VS Code with the Logtalk kernel. No HTML/JavaScript required, no stdin reading issues.

## How It Works

1. **Create Widget**: Run a cell to create a widget definition
2. **Set Value**: Run another cell to set the widget's value  
3. **Get Value**: Run a cell to retrieve and use the value

## Widget Types

### 1. Text Input Widget

**Create:**
```logtalk
jupyter::create_input_cell(widget_id, 'Prompt text', 'default_value').
```

**Set Value:**
```logtalk
jupyter::input_text(widget_id, 'your_text_here').
```

**Get Value:**
```logtalk
jupyter_vscode_widgets::get_widget_value(widget_id, Value).
```

### 2. Number Input Widget

**Create:**
```logtalk
jupyter::create_number_cell(widget_id, 'Enter a number', 42).
```

**Set Value:**
```logtalk
jupyter::input_number(widget_id, 123).
```

### 3. Choice Widget

**Create:**
```logtalk
jupyter::create_choice_cell(widget_id, 'Choose option', [red, green, blue]).
```

**Set Value:**
```logtalk
jupyter::input_choice(widget_id, red).
```

### 4. Boolean Widget

**Create:**
```logtalk
jupyter::create_boolean_cell(widget_id, 'Yes or no?').
```

**Set Value:**
```logtalk
jupyter::input_boolean(widget_id, true).
jupyter::input_boolean(widget_id, false).
```

## Complete Example

### Step 1: Create Widgets

```logtalk
% Create text input
jupyter::create_input_cell(user_name, 'What is your name?', 'Anonymous').

% Create number input  
jupyter::create_number_cell(user_age, 'What is your age?', 25).

% Create choice input
jupyter::create_choice_cell(favorite_color, 'Favorite color?', [red, green, blue, yellow]).

% Create boolean input
jupyter::create_boolean_cell(likes_programming, 'Do you like programming?').
```

### Step 2: Set Values

```logtalk
% Set your name
jupyter::input_text(user_name, 'Alice').

% Set your age
jupyter::input_number(user_age, 30).

% Choose color
jupyter::input_choice(favorite_color, blue).

% Answer question
jupyter::input_boolean(likes_programming, true).
```

### Step 3: Use Values

```logtalk
% Get all values and display profile
jupyter_vscode_widgets::get_widget_value(user_name, Name),
jupyter_vscode_widgets::get_widget_value(user_age, Age),
jupyter_vscode_widgets::get_widget_value(favorite_color, Color),
jupyter_vscode_widgets::get_widget_value(likes_programming, Likes),

format('Profile: ~w, ~w years old, likes ~w, programming: ~w~n', 
       [Name, Age, Color, Likes]).
```

## Widget Management

### List All Widgets
```logtalk
jupyter::list_widgets.
```

### Clear All Widgets
```logtalk
jupyter::clear_widgets.
```

### Check if Widget Exists
```logtalk
jupyter_vscode_widgets::widget_exists(widget_id).
```

## Features

✅ **Works in VS Code** - No special requirements  
✅ **No stdin issues** - Uses cell execution only  
✅ **Type validation** - Automatic validation for numbers and choices  
✅ **Error messages** - Clear feedback for invalid inputs  
✅ **State persistence** - Values persist between cells  
✅ **Easy to use** - Simple predicate calls  

## Error Handling

The system provides clear error messages:

```logtalk
% Wrong widget type
jupyter::input_number(text_widget, 42).
% Output: ❌ Error: text_widget is not a number input widget

% Invalid number
jupyter::input_number(age_widget, 'not_a_number').
% Output: ❌ Error: not_a_number is not a valid number

% Invalid choice
jupyter::input_choice(color_widget, purple).
% Output: ❌ Error: purple is not a valid choice. Options: [red, green, blue]

% Invalid boolean
jupyter::input_boolean(bool_widget, maybe).
% Output: ❌ Error: maybe is not a valid boolean (use true or false)
```

## Advanced Usage

### Survey System

```logtalk
% Create survey
create_survey :-
    jupyter::create_input_cell(participant_id, 'Participant ID:', 'P001'),
    jupyter::create_choice_cell(experience, 'Programming experience:', [beginner, intermediate, advanced]),
    jupyter::create_number_cell(years_coding, 'Years of experience:', 0),
    jupyter::create_boolean_cell(enjoys_coding, 'Enjoy programming?').

% Collect responses (run these after creating survey)
collect_responses :-
    jupyter::input_text(participant_id, 'P042'),
    jupyter::input_choice(experience, intermediate),
    jupyter::input_number(years_coding, 5),
    jupyter::input_boolean(enjoys_coding, true).

% Analyze results
analyze_survey :-
    jupyter_vscode_widgets::get_widget_value(participant_id, ID),
    jupyter_vscode_widgets::get_widget_value(experience, Level),
    jupyter_vscode_widgets::get_widget_value(years_coding, Years),
    jupyter_vscode_widgets::get_widget_value(enjoys_coding, Enjoys),
    
    format('Participant ~w: ~w level, ~w years, enjoys: ~w~n', 
           [ID, Level, Years, Enjoys]).
```

### Data Collection Workflow

```logtalk
% Step 1: Setup
setup_data_collection :-
    jupyter::create_input_cell(dataset_name, 'Dataset name:', 'experiment_1'),
    jupyter::create_number_cell(sample_size, 'Sample size:', 100),
    jupyter::create_choice_cell(method, 'Collection method:', [survey, interview, observation]).

% Step 2: Configure (edit values as needed)
configure_collection :-
    jupyter::input_text(dataset_name, 'user_study_2025'),
    jupyter::input_number(sample_size, 50),
    jupyter::input_choice(method, survey).

% Step 3: Process
process_data :-
    jupyter_vscode_widgets::get_widget_value(dataset_name, Name),
    jupyter_vscode_widgets::get_widget_value(sample_size, Size),
    jupyter_vscode_widgets::get_widget_value(method, Method),
    
    format('Processing dataset: ~w~n', [Name]),
    format('Sample size: ~w~n', [Size]),
    format('Method: ~w~n', [Method]),
    
    % Your data processing logic here
    format('Data collection configured successfully!~n', []).
```

## Best Practices

### 1. Use Descriptive Widget IDs
```logtalk
% Good
jupyter::create_input_cell(user_full_name, 'Full name:', '').

% Avoid
jupyter::create_input_cell(x, 'Name:', '').
```

### 2. Provide Clear Prompts
```logtalk
% Good
jupyter::create_choice_cell(difficulty, 'Select difficulty level:', [easy, medium, hard]).

% Avoid
jupyter::create_choice_cell(diff, 'Level:', [1, 2, 3]).
```

### 3. Use Meaningful Defaults
```logtalk
% Good
jupyter::create_number_cell(age, 'Age in years:', 25).

% Avoid
jupyter::create_number_cell(age, 'Age:', 0).
```

### 4. Group Related Operations
```logtalk
% Create all widgets first
create_user_profile_widgets :-
    jupyter::create_input_cell(name, 'Name:', ''),
    jupyter::create_number_cell(age, 'Age:', 18),
    jupyter::create_choice_cell(country, 'Country:', [usa, canada, uk]).

% Set all values together
set_user_profile :-
    jupyter::input_text(name, 'John Doe'),
    jupyter::input_number(age, 28),
    jupyter::input_choice(country, canada).
```

## Testing

Use the provided `simple_widget_test.ipynb` notebook to test the system:

1. Open the notebook in VS Code
2. Run each cell in sequence
3. Modify the input values in the `input_*` cells
4. See the results update immediately

## Comparison with Other Approaches

| Feature | Cell-Based Widgets | HTML Widgets | stdin Prompts |
|---------|-------------------|--------------|---------------|
| **VS Code Support** | ✅ Full | ❌ No | ❌ No |
| **User Experience** | ✅ Clear | ✅ Interactive | ❌ Confusing |
| **Error Handling** | ✅ Excellent | ✅ Good | ❌ Poor |
| **State Management** | ✅ Persistent | ✅ Persistent | ❌ None |
| **Type Validation** | ✅ Built-in | ✅ Custom | ❌ Manual |

This cell-based widget system provides the best solution for VS Code users who need interactive data input in Logtalk notebooks.
