%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  This file is part of Logtalk <https://logtalk.org/>
%  SPDX-FileCopyrightText: 2025 Paulo Moura <pmoura@logtalk.org>
%  SPDX-License-Identifier: Apache-2.0
%
%  Licensed under the Apache License, Version 2.0 (the "License");
%  you may not use this file except in compliance with the License.
%  You may obtain a copy of the License at
%
%      http://www.apache.org/licenses/LICENSE-2.0
%
%  Unless required by applicable law or agreed to in writing, software
%  distributed under the License is distributed on an "AS IS" BASIS,
%  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%  See the License for the specific language governing permissions and
%  limitations under the License.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


:- object(jupyter_widgets,
	extends(jupyter_inputs)).

	:- info([
		version is 0:7:0,
		author is 'Paulo Moura',
		date is 2025-07-21,
		comment is 'Predicates for creating and managing HTML/JavaScript widgets in Logtalk notebooks.'
	]).

	:- public(create_text_input/3).
	:- mode(create_text_input(+atom, +atom, +atom), one).
	:- info(create_text_input/3, [
		comment is 'Creates a text input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue']
	]).

	:- public(create_password_input/2).
	:- mode(create_password_input(+atom, +atom), one).
	:- info(create_password_input/2, [
		comment is 'Creates a password input widget.',
		argnames is ['WidgetId', 'Label']
	]).

	:- public(create_number_input/6).
	:- mode(create_number_input(+atom, +atom, +number, +number, +number, +number), one).
	:- info(create_number_input/6, [
		comment is 'Creates a number input widget.',
		argnames is ['WidgetId', 'Label', 'Min', 'Max', 'Step', 'DefaultValue']
	]).

	:- public(create_slider/6).
	:- mode(create_slider(+atom, +atom, +number, +number, +number, +number), one).
	:- info(create_slider/6, [
		comment is 'Creates a slider widget.',
		argnames is ['WidgetId', 'Label', 'Min', 'Max', 'Step', 'DefaultValue']
	]).

	:- public(create_date_input/3).
	:- mode(create_date_input(+atom, +atom, +date), one).
	:- info(create_date_input/3, [
		comment is 'Creates a date input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue']
	]).

	:- public(create_time_input/3).
	:- mode(create_time_input(+atom, +atom, +time), one).
	:- info(create_time_input/3, [
		comment is 'Creates a time input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue']
	]).

	:- public(create_email_input/4).
	:- mode(create_email_input(+atom, +atom, +atom, +atom), one).
	:- info(create_email_input/4, [
		comment is 'Creates an email input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue', 'Pattern']
	]).

	:- public(create_url_input/4).
	:- mode(create_url_input(+atom, +atom, +atom, +atom), one).
	:- info(create_url_input/4, [
		comment is 'Creates a URL input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue', 'Pattern']
	]).

	:- public(create_file_input/2).
	:- mode(create_file_input(+atom, +atom), one).
	:- info(create_file_input/2, [
		comment is 'Creates a file input widget.',
		argnames is ['WidgetId', 'Label']
	]).

	:- public(create_color_input/3).
	:- mode(create_color_input(+atom, +atom, +boolean), one).
	:- info(create_color_input/3, [
		comment is 'Creates a color input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue']
	]).

	:- public(create_dropdown/3).
	:- mode(create_dropdown(+atom, +atom, +list), one).
	:- info(create_dropdown/3, [
		comment is 'Creates a dropdown widget.',
		argnames is ['WidgetId', 'Label', 'MenuOptions']
	]).

	:- public(create_checkbox/3).
	:- mode(create_checkbox(+atom, +atom, +boolean), one).
	:- info(create_checkbox/3, [
		comment is 'Creates a checkbox widget.',
		argnames is ['WidgetId', 'Label', 'Checked']
	]).

	:- public(create_button/2).
	:- mode(create_button(+atom, +atom), one).
	:- info(create_button/2, [
		comment is 'Creates a button widget.',
		argnames is ['WidgetId', 'Label']
	]).

	:- public(create_textarea_input/4).
	:- mode(create_textarea_input(+atom, +atom, +atom, +integer), one).
	:- info(create_textarea_input/4, [
		comment is 'Creates a textarea input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue', 'Rows']
	]).

	:- public(create_input/3).
	:- mode(create_input(+atom, +atom, +list(pair(atom,ground))), one).
	:- info(create_input/3, [
		comment is 'Creates an input widget with custom attributes.',
		argnames is ['WidgetId', 'Label', 'Attributes']
	]).

	:- public(get_widget_value/2).
	:- mode(get_widget_value(+atom, ?nonvar), zero_or_one).
	:- info(get_widget_value/2, [
		comment is 'Gets the value of a widget.',
		argnames is ['WidgetId', 'Value']
	]).

	:- public(set_widget_value/2).
	:- mode(set_widget_value(+atom, +nonvar), one).
	:- info(set_widget_value/2, [
		comment is 'Sets the value of a widget.',
		argnames is ['WidgetId', 'Value']
	]).

	:- public(remove_widget/1).
	:- mode(remove_widget(+atom), one).
	:- info(remove_widget/1, [
		comment is 'Removes a widget. Succeeds also when the widget does not exist.',
		argnames is ['WidgetId']
	]).

	:- public(remove_all_widgets/0).
	:- mode(remove_all_widgets, one).
	:- info(remove_all_widgets/0, [
		comment is 'Removes all widgets.'
	]).

	:- public(widget/1).
	:- mode(widget(-atom), zero_or_more).
	:- info(widget/1, [
		comment is 'Enumerates, by backtracking, all existing widgets.',
		argnames is ['WidgetId']
	]).

	:- public(widgets/0).
	:- mode(widgets, one).
	:- info(widgets/0, [
		comment is 'Pretty-prints all widgets.'
	]).

	:- public(widgets/1).
	:- mode(widgets(-list(atom)), one).
	:- info(widgets/1, [
		comment is 'Returns a list of all the widgets.',
		argnames is ['Widgets']
	]).

	:- private(widget_state_/3).
	:- dynamic(widget_state_/3).
	:- mode(widget_state_(?atom, ?atom, ?nonvar), zero_or_more).
	:- info(widget_state_/3, [
		comment is 'Table of widgets state.',
		argnames is ['WidgetId', 'Type', 'Value']
	]).

	:- uses(jupyter_term_handling, [assert_success_response/4]).
	:- uses(format, [format/2]).
	:- uses(list, [member/2]).
	:- uses(type, [check/2]).
	:- uses(user, [atomic_list_concat/2]).

	:- multifile(type::type/1).
	type::type(widget_id).

	:- multifile(type::check/2).
	type::check(widget_id, Term) :-
		(	var(Term) ->
			throw(instantiation_error)
		;	\+ atom(Term) ->
			throw(type_error(atom, Term))
		;	widget_state_(Term, _, _) ->
			throw(permission_error(create, widget_id, Term))
		;	true
		).

	create_text_input(WidgetId, Label, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, text_input, DefaultValue)),
		create_text_input_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_textarea_input(WidgetId, Label, DefaultValue, Rows) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, textarea, DefaultValue)),
		create_textarea_input_html(WidgetId, Label, DefaultValue, Rows, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_password_input(WidgetId, Label) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, password_input, '')),
		create_password_input_html(WidgetId, Label, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_number_input(WidgetId, Label, Min, Max, Step, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, number_input, DefaultValue)),
		create_number_input_html(WidgetId, Label, Min, Max, Step, DefaultValue, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_slider(WidgetId, Label, Min, Max, Step, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, slider, DefaultValue)),
		create_slider_html(WidgetId, Label, Min, Max, Step, DefaultValue, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_date_input(WidgetId, Label, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, date_input, DefaultValue)),
		create_date_input_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_time_input(WidgetId, Label, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, time_input, DefaultValue)),
		create_time_input_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_email_input(WidgetId, Label, DefaultValue, Pattern) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, email_input, DefaultValue)),
		create_email_input_html(WidgetId, Label, DefaultValue, Pattern, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_url_input(WidgetId, Label, DefaultValue, Pattern) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, url_input, DefaultValue)),
		create_url_input_html(WidgetId, Label, DefaultValue, Pattern, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_file_input(WidgetId, Label) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, file_input, '')),
		create_file_input_html(WidgetId, Label, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_color_input(WidgetId, Label, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, color_input, DefaultValue)),
		create_color_input_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_dropdown(WidgetId, Label, MenuOptions) :-
		check(widget_id, WidgetId),
		MenuOptions = [FirstMenuOption|_],
		assertz(widget_state_(WidgetId, dropdown, FirstMenuOption)),
		create_dropdown_html(WidgetId, Label, MenuOptions, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_checkbox(WidgetId, Label, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, checkbox, DefaultValue)),
		create_checkbox_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_button(WidgetId, Label) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, button, false)),
		create_button_html(WidgetId, Label, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	create_input(WidgetId, Label, Attributes) :-
		check(widget_id, WidgetId),
		% Extract the type attribute to determine the widget type and default value
		(	member(type-Type, Attributes) ->
			true
		;	Type = text  % default to text input if no type specified
		),
		% Determine default value based on type
		(	member(value-DefaultValue, Attributes) ->
			true
		;	input_type_default_value(Type, DefaultValue)
		),
		assertz(widget_state_(WidgetId, Type, DefaultValue)),
		create_input_html(WidgetId, Label, Attributes, HTML),
		assert_success_response(widget, [], '', [input_html-HTML]).

	widget(WidgetId) :-
		widget_state_(WidgetId, _, _).

	get_widget_value(WidgetId, Value) :-
		widget_state_(WidgetId, _, Value).

	set_widget_value(WidgetId, Value) :-
		retract(widget_state_(WidgetId, Type, _)),
		asserta(widget_state_(WidgetId, Type, Value)).

	remove_widget(WidgetId) :-
		retractall(widget_state_(WidgetId, _, _)).

	remove_all_widgets :-
		retractall(widget_state_(_, _, _)).

	% Print all widgets
	widgets :-
		write('=== Widget Debug Information ==='), nl,
		(	widget_state_(WidgetId, Type, Value),
			format('Widget ~w: Type=~w, Value=~w~n', [WidgetId, Type, Value]),
			fail
		;	true
		),
		write('=== End Widget Debug ==='), nl.

	% List of all widgets
	widgets(Widgets) :-
		findall(widget(WidgetId, Type, Value), widget_state_(WidgetId, Type, Value), Widgets).

	% HTML generation predicates

	create_update_handler(WidgetId, Type, Value, Handler) :-
		^^webserver(IP, Port),
		atomic_list_concat([
			'fetch(\'http://', IP, ':', Port, '\', {',
			'  method: \'POST\',',
			'  headers: {\'Content-Type\': \'application/json\'},',
			'  body: JSON.stringify({type: \'', Type, '\', id: \'', WidgetId, '\', value: ', Value, '})',
			'})',
			'.then(response => response.json())'
			%'.then(data => console.log(\'Response:\', data))'
		], Handler).

	create_text_input_html(WidgetId, Label, DefaultValue, HTML) :-
		create_update_handler(WidgetId, text, 'String(this.value)', Handler),
		default_style(text, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="text" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'onchange="', Handler, '" ',
			'style="', Style, '"/>',
			'</div>'
		], HTML).

	create_textarea_input_html(WidgetId, Label, DefaultValue, Rows, HTML) :-
		create_update_handler(WidgetId, textarea, 'String(this.value)', Handler),
		default_style(textarea, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<textarea id="', WidgetId, '" ',
			'class="logtalk-widget-textarea" ',
			'rows="', Rows, '" ',
			'onchange="', Handler, '" ',
			'style="', Style, '">',
			DefaultValue,
			'</textarea>',
			'</div>'
		], HTML).

	create_password_input_html(WidgetId, Label, HTML) :-
		create_update_handler(WidgetId, password, 'String(this.value)', Handler),
		default_style(password, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="password" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'onchange="', Handler, '" ',
			'style="', Style, '"/>',
			'</div>'
		], HTML).

	create_number_input_html(WidgetId, Label, Min, Max, Step, DefaultValue, HTML) :-
		create_update_handler(WidgetId, number, 'this.value', Handler),
		default_style(number, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="number" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'min="', Min, '" max="', Max, '" step="', Step, '" value="', DefaultValue, '" ',
			'onchange="', Handler, '" ',
			'style="', Style, '"/>',
			'</div>'
		], HTML).

	create_slider_html(WidgetId, Label, Min, Max, Step, DefaultValue, HTML) :-
		create_update_handler(WidgetId, slider, 'this.value', Handler),
		default_style(slider, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">',
			Label, ': <span class="logtalk-widget-value" id="', WidgetId, '_value">', DefaultValue, '</span>',
			'</label><br>',
			'<input type="range" id="', WidgetId, '" ',
			'class="logtalk-widget-slider" ',
			'min="', Min, '" max="', Max, '" step="', Step, '" value="', DefaultValue, '" ',
			'oninput="document.getElementById(\'', WidgetId, '_value\').textContent = this.value" ',
			'onchange="', Handler, '" ',
			'style="', Style, '"/>',
			'</div>'
		], HTML).

	create_date_input_html(WidgetId, Label, DefaultValue, HTML) :-
		create_update_handler(WidgetId, date, 'String(this.value)', Handler),
		default_style(date, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="date" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'onchange="', Handler, '" ',
			'style="', Style, '"/>',
			'</div>'
		], HTML).

	create_time_input_html(WidgetId, Label, DefaultValue, HTML) :-
		create_update_handler(WidgetId, time, 'String(this.value)', Handler),
		default_style(time, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="time" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'onchange="', Handler, '" ',
			'style="', Style, '"/>',
			'</div>'
		], HTML).

	create_email_input_html(WidgetId, Label, DefaultValue, Pattern, HTML) :-
		create_update_handler(WidgetId, url, 'String(this.value)', Handler),
		default_style(email, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="email" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'pattern="', Pattern, '" ',
			'onblur="', Handler, '" ',
			'style="', Style, '"/>',
			'</div>'
		], HTML).

	create_url_input_html(WidgetId, Label, DefaultValue, Pattern, HTML) :-
		create_update_handler(WidgetId, url, 'String(this.value)', Handler),
		default_style(url, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="url" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'pattern="', Pattern, '" ',
			'onblur="', Handler, '" ',
			'style="', Style, '"/>',
			'</div>'
		], HTML).

	create_file_input_html(WidgetId, Label, HTML) :-
		create_update_handler(WidgetId, file, 'String(this.files[0].name)', Handler),
		default_style(file, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="file" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'onchange="', Handler, '" ',
			'style="', Style, '"/>',
			'</div>'
		], HTML).

	create_color_input_html(WidgetId, Label, DefaultValue, HTML) :-
		create_update_handler(WidgetId, color, 'String(this.value)', Handler),
		default_style(color, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="color" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'onchange="', Handler, '" ',
			'style="', Style, '"/>',
			'</div>'
		], HTML).

	create_dropdown_html(WidgetId, Label, MenuOptions, HTML) :-
		create_update_handler(WidgetId, dropdown, 'String(this.value)', Handler),
		create_menu_option_elements(MenuOptions, MenuOptionElements),
		default_style(dropdown, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<select id="', WidgetId, '" ',
			'class="logtalk-widget-select" ',
			'onchange="', Handler, '" ',
			'style="', Style, '">',
			MenuOptionElements,
			'</select>',
			'</div>'
		], HTML).

	create_checkbox_html(WidgetId, Label, DefaultValue, HTML) :-
		create_update_handler(WidgetId, checkbox, 'this.checked ? \'true\' : \'false\'', Handler),
		(DefaultValue == true -> Checked = 'checked' ; Checked = ''),
		default_style(checkbox, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<input type="checkbox" id="', WidgetId, '" ',
			'class="logtalk-widget-checkbox" ',
			Checked, ' ',
			'onchange="', Handler, '" ',
			'style="', Style, '"/>',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label>',
			'</div>'
		], HTML).

	create_button_html(WidgetId, Label, HTML) :-
		create_update_handler(WidgetId, button, '\'true\'', Handler),
		default_style(button, Style),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<button id="', WidgetId, '" ',
			'class="logtalk-widget-button" ',
			'onclick="', Handler, '" ',
			'style="', Style, '">',
			Label,
			'</button>',
			'</div>'
		], HTML).

	create_input_html(WidgetId, Label, Attributes, HTML) :-
		% Extract the type attribute to determine the value expression
		(	member(type-Type, Attributes) ->
			true
		;	Type = text  % default to text input if no type specified
		),
		input_type_value_expression(Type, ValueExpression),
		create_update_handler(WidgetId, Type, ValueExpression, Handler),
		% Build the input attributes string
		^^create_input_attributes_string(Attributes, AttributesString),
		% Determine the event handler based on input type
		(	Type = checkbox ->
			EventHandler = 'onchange'
		;	Type = button ->
			EventHandler = 'onclick'
		;	member(Type, [email, url]) ->
			EventHandler = 'onblur'
		;	EventHandler = 'onchange'
		),
		% Use provided style or default style for the widget type
		(	member(style-Style, Attributes) ->
			true
		;	default_style(Type, Style)
		),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			AttributesString, ' ',
			EventHandler, '="', Handler, '" ',
			'style="', Style, '"/>',
			'</div>'
		], HTML).

	% auxiliary predicates

	% Default styles for different widget types
	default_style(text, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(password, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(number, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(email, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(url, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(tel, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(search, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(date, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(time, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style('datetime-local', 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(month, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(week, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(color, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(file, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(range, 'margin: 5px; width: 200px;').
	default_style(slider, 'margin: 5px; width: 200px;').
	default_style(checkbox, 'margin: 5px;').
	default_style(radio, 'margin: 5px;').
	default_style(dropdown, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;').
	default_style(textarea, 'margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px; resize: vertical; font-family: inherit;').
	default_style(button, 'margin: 5px; padding: 8px 16px; background-color: #007cba; color: white; border: none; border-radius: 3px; cursor: pointer;').

	create_menu_option_elements(Options, Elements) :-
		create_menu_option_elements_list(Options, Elements0),
		atomic_list_concat(Elements0, Elements).

	create_menu_option_elements_list([], []).
	create_menu_option_elements_list([Option| Options], [Element| Elements]) :-
		atomic_list_concat(['<option value="', Option, '">', Option, '</option>'], Element),
		create_menu_option_elements_list(Options, Elements).

	% Determine the appropriate JavaScript value expression based on input type
	input_type_value_expression(text, 'String(this.value)').
	input_type_value_expression(password, 'String(this.value)').
	input_type_value_expression(email, 'String(this.value)').
	input_type_value_expression(url, 'String(this.value)').
	input_type_value_expression(tel, 'String(this.value)').
	input_type_value_expression(search, 'String(this.value)').
	input_type_value_expression(date, 'String(this.value)').
	input_type_value_expression(time, 'String(this.value)').
	input_type_value_expression('datetime-local', 'String(this.value)').
	input_type_value_expression(month, 'String(this.value)').
	input_type_value_expression(week, 'String(this.value)').
	input_type_value_expression(color, 'String(this.value)').
	input_type_value_expression(number, 'this.value').
	input_type_value_expression(range, 'this.value').
	input_type_value_expression(checkbox, 'this.checked ? \'true\' : \'false\'').
	input_type_value_expression(radio, 'String(this.value)').
	input_type_value_expression(file, 'String(this.files[0] ? this.files[0].name : \'\')').
	input_type_value_expression(slider, 'this.value').
	input_type_value_expression(dropdown, 'String(this.value)').
	input_type_value_expression(textarea, 'String(this.value)').
	input_type_value_expression(button, '\'true\'').

	% Determine default values based on input type
	input_type_default_value(text, '').
	input_type_default_value(password, '').
	input_type_default_value(email, '').
	input_type_default_value(url, '').
	input_type_default_value(tel, '').
	input_type_default_value(search, '').
	input_type_default_value(date, '').
	input_type_default_value(time, '').
	input_type_default_value('datetime-local', '').
	input_type_default_value(month, '').
	input_type_default_value(week, '').
	input_type_default_value(color, '#000000').
	input_type_default_value(number, 0).
	input_type_default_value(range, 0).
	input_type_default_value(checkbox, false).
	input_type_default_value(radio, '').
	input_type_default_value(file, '').
	input_type_default_value(slider, 0).
	input_type_default_value(dropdown, '').
	input_type_default_value(textarea, '').
	input_type_default_value(button, false).

:- end_object.
