% VS Code compatible widgets using cell-based input

:- object(jupyter_vscode_widgets).

	:- public([
		create_input_cell/3,        % create_input_cell(+WidgetId, +Prompt, +DefaultValue)
		create_choice_cell/3,       % create_choice_cell(+WidgetId, +Prompt, +Options)
		create_number_cell/3,       % create_number_cell(+WidgetId, +Prompt, +DefaultValue)
		create_boolean_cell/2,      % create_boolean_cell(+WidgetId, +Prompt)
		set_widget_value/2,         % set_widget_value(+WidgetId, +Value)
		get_widget_value/2,         % get_widget_value(+WidgetId, -Value)
		widget_exists/1,            % widget_exists(+WidgetId)
		list_widgets/0,             % list_widgets
		clear_widgets/0,            % clear_widgets
		% Helper predicates for user input
		input_text/2,               % input_text(+WidgetId, +Value)
		input_number/2,             % input_number(+WidgetId, +Value)
		input_choice/2,             % input_choice(+WidgetId, +Choice)
		input_boolean/2             % input_boolean(+WidgetId, +Value)
	]).

	% Dynamic predicates to store widget values and metadata
	:- dynamic(widget_value/2).     % widget_value(WidgetId, Value)
	:- dynamic(widget_metadata/4).  % widget_metadata(WidgetId, Type, Prompt, Options)

	% Create text input cell
	create_input_cell(WidgetId, Prompt, DefaultValue) :-
		retractall(widget_metadata(WidgetId, _, _, _)),
		assertz(widget_metadata(WidgetId, text, Prompt, DefaultValue)),
		retractall(widget_value(WidgetId, _)),
		assertz(widget_value(WidgetId, DefaultValue)),
		format('~n=== TEXT INPUT WIDGET ===~n', []),
		format('Widget ID: ~w~n', [WidgetId]),
		format('Prompt: ~w~n', [Prompt]),
		format('Default Value: ~w~n', [DefaultValue]),
		format('~nTo set a value, run in a new cell:~n', []),
		format('  jupyter_vscode_widgets::input_text(~w, ''your_value_here'').~n', [WidgetId]),
		format('~nTo get the current value:~n', []),
		format('  jupyter_vscode_widgets::get_widget_value(~w, Value).~n', [WidgetId]),
		format('===========================~n~n', []).

	% Create number input cell
	create_number_cell(WidgetId, Prompt, DefaultValue) :-
		retractall(widget_metadata(WidgetId, _, _, _)),
		assertz(widget_metadata(WidgetId, number, Prompt, DefaultValue)),
		retractall(widget_value(WidgetId, _)),
		assertz(widget_value(WidgetId, DefaultValue)),
		format('~n=== NUMBER INPUT WIDGET ===~n', []),
		format('Widget ID: ~w~n', [WidgetId]),
		format('Prompt: ~w~n', [Prompt]),
		format('Default Value: ~w~n', [DefaultValue]),
		format('~nTo set a value, run in a new cell:~n', []),
		format('  jupyter_vscode_widgets::input_number(~w, 42).~n', [WidgetId]),
		format('~nTo get the current value:~n', []),
		format('  jupyter_vscode_widgets::get_widget_value(~w, Value).~n', [WidgetId]),
		format('============================~n~n', []).

	% Create choice input cell
	create_choice_cell(WidgetId, Prompt, Options) :-
		retractall(widget_metadata(WidgetId, _, _, _)),
		assertz(widget_metadata(WidgetId, choice, Prompt, Options)),
		Options = [FirstOption|_],
		retractall(widget_value(WidgetId, _)),
		assertz(widget_value(WidgetId, FirstOption)),
		format('~n=== CHOICE INPUT WIDGET ===~n', []),
		format('Widget ID: ~w~n', [WidgetId]),
		format('Prompt: ~w~n', [Prompt]),
		format('Options: ~w~n', [Options]),
		format('Default Value: ~w~n', [FirstOption]),
		format('~nTo set a value, run in a new cell:~n', []),
		format('  jupyter_vscode_widgets::input_choice(~w, option_name).~n', [WidgetId]),
		format('~nTo get the current value:~n', []),
		format('  jupyter_vscode_widgets::get_widget_value(~w, Value).~n', [WidgetId]),
		format('============================~n~n', []).

	% Create boolean input cell
	create_boolean_cell(WidgetId, Prompt) :-
		retractall(widget_metadata(WidgetId, _, _, _)),
		assertz(widget_metadata(WidgetId, boolean, Prompt, false)),
		retractall(widget_value(WidgetId, _)),
		assertz(widget_value(WidgetId, false)),
		format('~n=== BOOLEAN INPUT WIDGET ===~n', []),
		format('Widget ID: ~w~n', [WidgetId]),
		format('Prompt: ~w~n', [Prompt]),
		format('Default Value: false~n', []),
		format('~nTo set a value, run in a new cell:~n', []),
		format('  jupyter_vscode_widgets::input_boolean(~w, true).~n', [WidgetId]),
		format('  jupyter_vscode_widgets::input_boolean(~w, false).~n', [WidgetId]),
		format('~nTo get the current value:~n', []),
		format('  jupyter_vscode_widgets::get_widget_value(~w, Value).~n', [WidgetId]),
		format('=============================~n~n', []).

	% Input text value
	input_text(WidgetId, Value) :-
		(	widget_metadata(WidgetId, text, _, _) ->
			retractall(widget_value(WidgetId, _)),
			assertz(widget_value(WidgetId, Value)),
			format('✅ Text widget ~w set to: ~w~n', [WidgetId, Value])
		;	format('❌ Error: Widget ~w is not a text input widget~n', [WidgetId])
		).

	% Input number value
	input_number(WidgetId, Value) :-
		(	widget_metadata(WidgetId, number, _, _) ->
			(	number(Value) ->
				retractall(widget_value(WidgetId, _)),
				assertz(widget_value(WidgetId, Value)),
				format('✅ Number widget ~w set to: ~w~n', [WidgetId, Value])
			;	format('❌ Error: ~w is not a valid number~n', [Value])
			)
		;	format('❌ Error: Widget ~w is not a number input widget~n', [WidgetId])
		).

	% Input choice value
	input_choice(WidgetId, Choice) :-
		(	widget_metadata(WidgetId, choice, _, Options) ->
			(	memberchk(Choice, Options) ->
				retractall(widget_value(WidgetId, _)),
				assertz(widget_value(WidgetId, Choice)),
				format('✅ Choice widget ~w set to: ~w~n', [WidgetId, Choice])
			;	format('❌ Error: ~w is not a valid choice. Options: ~w~n', [Choice, Options])
			)
		;	format('❌ Error: Widget ~w is not a choice input widget~n', [WidgetId])
		).

	% Input boolean value
	input_boolean(WidgetId, Value) :-
		(	widget_metadata(WidgetId, boolean, _, _) ->
			(	memberchk(Value, [true, false]) ->
				retractall(widget_value(WidgetId, _)),
				assertz(widget_value(WidgetId, Value)),
				format('✅ Boolean widget ~w set to: ~w~n', [WidgetId, Value])
			;	format('❌ Error: ~w is not a valid boolean (use true or false)~n', [Value])
			)
		;	format('❌ Error: Widget ~w is not a boolean input widget~n', [WidgetId])
		).

	% Set widget value directly
	set_widget_value(WidgetId, Value) :-
		retractall(widget_value(WidgetId, _)),
		assertz(widget_value(WidgetId, Value)),
		format('Widget ~w set to: ~w~n', [WidgetId, Value]).

	% Get widget value
	get_widget_value(WidgetId, Value) :-
		widget_value(WidgetId, Value).

	% Check if widget exists
	widget_exists(WidgetId) :-
		widget_value(WidgetId, _).

	% List all widgets
	list_widgets :-
		format('~n=== WIDGET VALUES ===~n', []),
		(	widget_value(WidgetId, Value) ->
			widget_metadata(WidgetId, Type, Prompt, _),
			format('~w (~w): ~w~n  Prompt: ~w~n', [WidgetId, Type, Value, Prompt]),
			fail
		;	true
		),
		format('====================~n~n', []).

	% Clear all widgets
	clear_widgets :-
		retractall(widget_value(_, _)),
		retractall(widget_metadata(_, _, _, _)),
		format('All widget values cleared.~n', []).

:- end_object.