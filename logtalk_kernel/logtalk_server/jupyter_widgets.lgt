%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  This file is part of Logtalk <https://logtalk.org/>
%  SPDX-FileCopyrightText: 1998-2025 Paulo Moura <pmoura@logtalk.org>
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


:- object(jupyter_widgets).

	:- info([
		version is 0:2:0,
		author is 'Paulo Moura',
		date is 2025-07-14,
		comment is 'This object provides predicates for creating and managing HTML/JavaScript widgets in Logtalk notebooks.'
	]).

	:- public(webserver_port/1).
	:- mode(webserver_port(+positive_integer), zero_or_one).
	:- info(webserver_port/1, [
		comment is 'Widget callback webserver port. Only available after being set automatically by the kernel.',
		argnames is ['Port']
	]).

	:- public(set_webserver_port/1).
	:- mode(set_webserver_port(+positive_integer), one).
	:- info(set_webserver_port/1, [
		comment is 'Set the widget callback webserver port. Called automatically by the kernel.',
		argnames is ['Port']
	]).

	:- public(create_text_input/3).
	:- mode(create_text_input(+atom, +atom, +atom), one).
	:- info(create_text_input/3, [
		comment is 'Create a text input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue']
	]).

	:- public(create_password_input/2).
	:- mode(create_password_input(+atom, +atom), one).
	:- info(create_password_input/2, [
		comment is 'Create a password input widget.',
		argnames is ['WidgetId', 'Label']
	]).

	:- public(create_number_input/6).
	:- mode(create_number_input(+atom, +atom, +number, +number, +number, +number), one).
	:- info(create_number_input/6, [
		comment is 'Create a number input widget.',
		argnames is ['WidgetId', 'Label', 'Min', 'Max', 'Step', 'DefaultValue']
	]).

	:- public(create_slider/6).
	:- mode(create_slider(+atom, +atom, +number, +number, +number, +number), one).
	:- info(create_slider/6, [
		comment is 'Create a slider widget.',
		argnames is ['WidgetId', 'Label', 'Min', 'Max', 'Step', 'DefaultValue']
	]).

	:- public(create_date_input/3).
	:- mode(create_date_input(+atom, +atom, +date), one).
	:- info(create_date_input/3, [
		comment is 'Create a date input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue']
	]).

	:- public(create_time_input/3).
	:- mode(create_time_input(+atom, +atom, +time), one).
	:- info(create_time_input/3, [
		comment is 'Create a time input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue']
	]).

	:- public(create_email_input/4).
	:- mode(create_email_input(+atom, +atom, +atom, +atom), one).
	:- info(create_email_input/4, [
		comment is 'Create an email input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue', 'Pattern']
	]).

	:- public(create_url_input/4).
	:- mode(create_url_input(+atom, +atom, +atom, +atom), one).
	:- info(create_url_input/4, [
		comment is 'Create a URL input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue', 'Pattern']
	]).

	:- public(create_file_input/2).
	:- mode(create_file_input(+atom, +atom), one).
	:- info(create_file_input/2, [
		comment is 'Create a file input widget.',
		argnames is ['WidgetId', 'Label']
	]).

	:- public(create_color_input/3).
	:- mode(create_color_input(+atom, +atom, +boolean), one).
	:- info(create_color_input/3, [
		comment is 'Create a color input widget.',
		argnames is ['WidgetId', 'Label', 'DefaultValue']
	]).

	:- public(create_dropdown/3).
	:- info(create_dropdown/3, [
		comment is 'Create a dropdown widget.',
		argnames is ['WidgetId', 'Label', 'MenuOptions']
	]).

	:- public(create_checkbox/3).
	:- mode(create_checkbox(+atom, +atom, +boolean), one).
	:- info(create_checkbox/3, [
		comment is 'Create a checkbox widget.',
		argnames is ['WidgetId', 'Label', 'Checked']
	]).

	:- public(create_button/2).
	:- mode(create_button(+atom, +atom), one).
	:- info(create_button/2, [
		comment is 'Create a button widget.',
		argnames is ['WidgetId', 'Label']
	]).

	:- public(get_widget_value/2).
	:- mode(get_widget_value(+atom, ?nonvar), zero_or_one).
	:- info(get_widget_value/2, [
		comment is 'Get the value of a widget.',
		argnames is ['WidgetId', 'Value']
	]).

	:- public(set_widget_value/2).
	:- mode(set_widget_value(+atom, +nonvar), one).
	:- info(set_widget_value/2, [
		comment is 'Set the value of a widget.',
		argnames is ['WidgetId', 'Value']
	]).

	:- public(remove_widget/1).
	:- mode(remove_widget(+atom), one).
	:- info(remove_widget/1, [
		comment is 'Remove a widget. Succeeds also when the widget does not exist.',
		argnames is ['WidgetId']
	]).

	:- public(remove_all_widgets/0).
	:- mode(remove_all_widgets, one).
	:- info(remove_all_widgets/0, [
		comment is 'Clear all widgets.'
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
		comment is 'Pretty-print all widgets.'
	]).

	:- public(widgets/1).
	:- mode(widgets(-list(atom)), one).
	:- info(widgets/1, [
		comment is 'Returns a list of all the widgets.',
		argnames is ['Widgets']
	]).

	:- private(webserver_port_/1).
	:- dynamic(webserver_port_/1).
	:- mode(webserver_port_(?positive_integer), zero_or_one).
	:- info(webserver_port_/1, [
		comment is 'Widget callback webserver port.',
		argnames is ['Port']
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

	webserver_port(Port) :-
		webserver_port_(Port).

	set_webserver_port(Port) :-
		retractall(webserver_port_(_)),
		assertz(webserver_port_(Port)).

	create_text_input(WidgetId, Label, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, text_input, DefaultValue)),
		create_text_input_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_password_input(WidgetId, Label) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, password_input, '')),
		create_password_input_html(WidgetId, Label, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_number_input(WidgetId, Label, Min, Max, Step, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, number_input, DefaultValue)),
		create_number_input_html(WidgetId, Label, Min, Max, Step, DefaultValue, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_slider(WidgetId, Label, Min, Max, Step, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, slider, DefaultValue)),
		create_slider_html(WidgetId, Label, Min, Max, Step, DefaultValue, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_date_input(WidgetId, Label, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, date_input, DefaultValue)),
		create_date_input_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_time_input(WidgetId, Label, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, time_input, DefaultValue)),
		create_time_input_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_email_input(WidgetId, Label, DefaultValue, Pattern) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, email_input, DefaultValue)),
		create_email_input_html(WidgetId, Label, DefaultValue, Pattern, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_url_input(WidgetId, Label, DefaultValue, Pattern) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, url_input, DefaultValue)),
		create_url_input_html(WidgetId, Label, DefaultValue, Pattern, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_file_input(WidgetId, Label) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, file_input, '')),
		create_file_input_html(WidgetId, Label, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_color_input(WidgetId, Label, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, color_input, DefaultValue)),
		create_color_input_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_dropdown(WidgetId, Label, MenuOptions) :-
		check(widget_id, WidgetId),
		MenuOptions = [FirstMenuOption|_],
		assertz(widget_state_(WidgetId, dropdown, FirstMenuOption)),
		create_dropdown_html(WidgetId, Label, MenuOptions, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_checkbox(WidgetId, Label, DefaultValue) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, checkbox, DefaultValue)),
		create_checkbox_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	create_button(WidgetId, Label) :-
		check(widget_id, WidgetId),
		assertz(widget_state_(WidgetId, button, false)),
		create_button_html(WidgetId, Label, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	get_widget_value(WidgetId, Value) :-
		widget_state_(WidgetId, _, Value).

	% Set widget value
	set_widget_value(WidgetId, Value) :-
		retract(widget_state_(WidgetId, Type, _)),
		asserta(widget_state_(WidgetId, Type, Value)).

	% Remove widget
	remove_widget(WidgetId) :-
		retractall(widget_state_(WidgetId, _, _)).

	% Remove all widgets
	remove_all_widgets :-
		retractall(widget_state_(_, _, _)).

	% Enumerate all widgets or check if a widget exists
	widget(WidgetId) :-
		widget_state_(WidgetId, _, _).

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
		webserver_port_(Port),
		atomic_list_concat([
			'fetch(\'http://127.0.0.1:', Port, '\', {',
			'  method: \'POST\',',
			'  headers: {\'Content-Type\': \'application/json\'},',
			'  body: JSON.stringify({type: \'', Type, '\', id: \'', WidgetId, '\', value: ', Value, '})',
			'})',
			'.then(response => response.json())'
			%'.then(data => console.log(\'Response:\', data))'
		], Handler).

	create_text_input_html(WidgetId, Label, DefaultValue, HTML) :-
		create_update_handler(WidgetId, text, 'String(this.value)', Handler),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="text" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'onchange="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;"/>',
			'</div>'
		], HTML).

	create_password_input_html(WidgetId, Label, HTML) :-
		create_update_handler(WidgetId, password, 'String(this.value)', Handler),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="password" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'onchange="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;"/>',
			'</div>'
		], HTML).

	create_number_input_html(WidgetId, Label, Min, Max, Step, DefaultValue, HTML) :-
		create_update_handler(WidgetId, number, 'this.value', Handler),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="number" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'min="', Min, '" max="', Max, '" step="', Step, '" value="', DefaultValue, '" ',
			'onchange="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;"/>',
			'</div>'
		], HTML).

	create_slider_html(WidgetId, Label, Min, Max, Step, DefaultValue, HTML) :-
		create_update_handler(WidgetId, slider, 'this.value', Handler),
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
			'style="margin: 5px; width: 200px;"/>',
			'</div>'
		], HTML).

	create_date_input_html(WidgetId, Label, DefaultValue, HTML) :-
		create_update_handler(WidgetId, date, 'String(this.value)', Handler),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="date" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'onchange="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;"/>',
			'</div>'
		], HTML).

	create_time_input_html(WidgetId, Label, DefaultValue, HTML) :-
		create_update_handler(WidgetId, time, 'String(this.value)', Handler),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="time" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'onchange="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;"/>',
			'</div>'
		], HTML).

	create_email_input_html(WidgetId, Label, DefaultValue, Pattern, HTML) :-
		create_update_handler(WidgetId, url, 'String(this.value)', Handler),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="email" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'pattern="', Pattern, '" ',
			'onblur="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;"/>',
			'</div>'
		], HTML).

	create_url_input_html(WidgetId, Label, DefaultValue, Pattern, HTML) :-
		create_update_handler(WidgetId, url, 'String(this.value)', Handler),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="url" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'pattern="', Pattern, '" ',
			'onblur="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;"/>',
			'</div>'
		], HTML).

	create_file_input_html(WidgetId, Label, HTML) :-
		create_update_handler(WidgetId, file, 'String(this.files[0].name)', Handler),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="file" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'onchange="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;"/>',
			'</div>'
		], HTML).

	create_color_input_html(WidgetId, Label, DefaultValue, HTML) :-
		create_update_handler(WidgetId, color, 'String(this.value)', Handler),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="color" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			'onchange="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;"/>',
			'</div>'
		], HTML).

	create_dropdown_html(WidgetId, Label, MenuOptions, HTML) :-
		create_update_handler(WidgetId, dropdown, 'String(this.value)', Handler),
		create_menu_option_elements(MenuOptions, MenuOptionElements),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<select id="', WidgetId, '" ',
			'class="logtalk-widget-select" ',
			'onchange="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;">',
			MenuOptionElements,
			'</select>',
			'</div>'
		], HTML).

	create_checkbox_html(WidgetId, Label, DefaultValue, HTML) :-
		create_update_handler(WidgetId, checkbox, 'this.checked ? \'true\' : \'false\'', Handler),
		(DefaultValue == true -> Checked = 'checked' ; Checked = ''),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<input type="checkbox" id="', WidgetId, '" ',
			'class="logtalk-widget-checkbox" ',
			Checked, ' ',
			'onchange="', Handler, '" ',
			'style="margin: 5px;"/>',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label>',
			'</div>'
		], HTML).

	create_button_html(WidgetId, Label, HTML) :-
		create_update_handler(WidgetId, button, '\'true\'', Handler),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<button id="', WidgetId, '" ',
			'class="logtalk-widget-button" ',
			'onclick="', Handler, '" ',
			'style="margin: 5px; padding: 8px 16px; background-color: #007cba; color: white; border: none; border-radius: 3px; cursor: pointer;">',
			Label,
			'</button>',
			'</div>'
		], HTML).

	% auxiliary predicates

	create_menu_option_elements([], '').
	create_menu_option_elements([Option|Rest], OptionElements) :-
		atomic_list_concat(['<option value="', Option, '">', Option, '</option>'], OptionElement),
		create_menu_option_elements(Rest, RestElements),
		atomic_list_concat([OptionElement, RestElements], OptionElements).

:- end_object.
