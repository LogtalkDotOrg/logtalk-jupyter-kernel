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


% This object provides predicates for creating and managing HTML/JavaScript widgets
% in Logtalk Jupyter notebooks.


:- object(jupyter_widget_handling).

	:- info([
		version is 0:1:0,
		author is 'Paulo Moura',
		date is 2025-01-27,
		comment is 'This object provides predicates for creating and managing HTML/JavaScript widgets in Logtalk notebooks.'
	]).

	:- public([
		create_text_input/3,        % create_text_input(+WidgetId, +Label, +DefaultValue)
		create_number_input/4,      % create_number_input(+WidgetId, +Label, +DefaultValue, +Options)
		create_slider/6,            % create_slider(+WidgetId, +Label, +Min, +Max, +Step, +DefaultValue)
		create_dropdown/3,          % create_dropdown(+WidgetId, +Label, +Options)
		create_checkbox/3,          % create_checkbox(+WidgetId, +Label, +DefaultValue)
		create_button/2,            % create_button(+WidgetId, +Label)
		get_widget_value/2,         % get_widget_value(+WidgetId, -Value)
		set_widget_value/2,         % set_widget_value(+WidgetId, +Value)
		remove_widget/1,            % remove_widget(+WidgetId)
		clear_all_widgets/0,        % clear_all_widgets
		widget/1,                   % widget(?WidgetId)
		widgets/0,                  % widgets
		widgets/1                   % widgets(-Widgets)
	]).

	:- uses(jupyter_logging, [log/1, log/2]).
	:- uses(jupyter_term_handling, [assert_success_response/4]).

	% Dynamic predicate to store widget state
	:- private(widget_state/3).  % widget_state(WidgetId, Type, Value)
	:- dynamic(widget_state/3).  % widget_state(WidgetId, Type, Value)

	% Widget counter for generating unique IDs
	:- dynamic(widget_counter/1).
	widget_counter(0).

	% Generate unique widget ID
	generate_widget_id(WidgetId) :-
		retract(widget_counter(N)),
		N1 is N + 1,
		assertz(widget_counter(N1)),
		atomic_list_concat(['widget_', N1], WidgetId).

	% Create text input widget
	create_text_input(WidgetId, Label, DefaultValue) :-
		(	var(WidgetId) ->
			generate_widget_id(WidgetId)
		;	true
		),
		assertz(widget_state(WidgetId, text_input, DefaultValue)),
		create_text_input_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	% Create number input widget
	create_number_input(WidgetId, Label, DefaultValue, Options) :-
		(	var(WidgetId) ->
			generate_widget_id(WidgetId)
		;	true
		),
		assertz(widget_state(WidgetId, number_input, DefaultValue)),
		create_number_input_html(WidgetId, Label, DefaultValue, Options, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	% Create slider widget
	create_slider(WidgetId, Label, Min, Max, Step, DefaultValue) :-
		(	var(WidgetId) ->
			generate_widget_id(WidgetId)
		;	true
		),
		assertz(widget_state(WidgetId, slider, DefaultValue)),
		create_slider_html(WidgetId, Label, Min, Max, Step, DefaultValue, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	% Create dropdown widget
	create_dropdown(WidgetId, Label, Options) :-
		(	var(WidgetId) ->
			generate_widget_id(WidgetId)
		;	true
		),
		Options = [FirstOption|_],
		assertz(widget_state(WidgetId, dropdown, FirstOption)),
		create_dropdown_html(WidgetId, Label, Options, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	% Create checkbox widget
	create_checkbox(WidgetId, Label, DefaultValue) :-
		(	var(WidgetId) ->
			generate_widget_id(WidgetId)
		;	true
		),
		assertz(widget_state(WidgetId, checkbox, DefaultValue)),
		create_checkbox_html(WidgetId, Label, DefaultValue, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	% Create button widget
	create_button(WidgetId, Label) :-
		(	var(WidgetId) ->
			generate_widget_id(WidgetId)
		;	true
		),
		assertz(widget_state(WidgetId, button, clicked)),
		create_button_html(WidgetId, Label, HTML),
		assert_success_response(widget, [], '', [widget_html-HTML]).

	% Get widget value
	get_widget_value(WidgetId, Value) :-
		widget_state(WidgetId, _, Value).

	% Set widget value
	set_widget_value(WidgetId, Value) :-
		retract(widget_state(WidgetId, Type, _)),
		asserta(widget_state(WidgetId, Type, Value)).

	% Remove widget
	remove_widget(WidgetId) :-
		retractall(widget_state(WidgetId, _, _)).

	% Clear all widgets
	clear_all_widgets :-
		retractall(widget_state(_, _, _)).

	% Check if widget exists
	widget(WidgetId) :-
		widget_state(WidgetId, _, _).

	% Pprint all widgets
	widgets :-
		write('=== Widget Debug Information ==='), nl,
		(	widget_state(WidgetId, Type, Value),
			format('Widget ~w: Type=~w, Value=~w~n', [WidgetId, Type, Value]),
			fail
		;	true
		),
		write('=== End Widget Debug ==='), nl.

	% List all widgets
	widgets(Widgets) :-
		findall(widget(WidgetId, Type, Value), widget_state(WidgetId, Type, Value), Widgets).

	% HTML generation predicates

	% Base widget container HTML with direct event handling
	create_widget_container(WidgetId, Contents, HTML) :-
		atomic_list_concat([
			'<div class="logtalk-widget-wrapper">',
			'<div class="logtalk-widget" id="container_', WidgetId, '">',
			Contents,
			'</div>',
			'<script>',
			'(function() {',
			'    function setupWidget() {',
			'        const container = document.getElementById("container_', WidgetId, '");',
			'        if (!container) return;',
			'        const widget = container.querySelector("input, select, button");',
			'        if (!widget) return;',
			'        ',
			'        function sendUpdate(value) {',
%			'            if (!window.JUPYTER_KERNEL) return;',
			'            const code = `jupyter_widget_handling::set_widget_value(\'', WidgetId, '\', ${value}).`;',
			'            window.JUPYTER_KERNEL.do_execute(code, { silent: true, store_history: false });',
			'        }',
			'        ',
			'        if (widget.type === "checkbox") {',
			'            widget.addEventListener("change", () => sendUpdate(widget.checked));',
			'        } else if (widget.type === "button") {',
			'            widget.addEventListener("click", () => sendUpdate("\'clicked\'"));',
			'        } else if (widget.type === "range") {',
			'            widget.addEventListener("input", () => {',
			'                const display = document.getElementById("', WidgetId, '_value");',
			'                if (display) display.textContent = widget.value;',
			'            });',
			'            widget.addEventListener("change", () => sendUpdate(widget.value));',
			'        } else {',
			'            widget.addEventListener("change", () => sendUpdate(`\'${widget.value}\'`));',
			'        }',
			'    }',
			'    ',
			'    if (document.readyState === "loading") {',
			'        document.addEventListener("DOMContentLoaded", setupWidget);',
			'    } else {',
			'        setupWidget();',
			'    }',
			'})();',
			'</script>',
			'</div>'
		], HTML).

	% Common update handler for all widgets
	create_update_handler(WidgetId, Type, Value, Handler) :-
		atomic_list_concat([
			'fetch(\'http://127.0.0.1:8998\', {',
    		'	method: \'POST\',',
    		'	headers: {\'Content-Type\': \'application/json\'},',
    		'	body: JSON.stringify({type: \'', Type, '\', id: \'', WidgetId, '\', value: ', Value, '})',
			'})',
			'.then(response => response.json())',
			'.then(data => console.log(\'Response:\', data))'
		], Handler).

	% Generate simple text input HTML
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

	% Generate number input HTML
	create_number_input_html(WidgetId, Label, DefaultValue, Options, HTML) :-
		create_update_handler(WidgetId, number, 'Number.isFinite(parseFloat(this.value)) ? parseFloat(this.value) : 0', Handler),
		extract_number_options(Options, MinAttr, MaxAttr, StepAttr),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<input type="number" id="', WidgetId, '" ',
			'class="logtalk-widget-input" ',
			'value="', DefaultValue, '" ',
			MinAttr, ' ', MaxAttr, ' ', StepAttr, ' ',
			'onchange="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;"/>',
			'</div>'
		], HTML).

	% Create slider HTML
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

	% Create dropdown HTML
	create_dropdown_html(WidgetId, Label, Options, HTML) :-
		create_update_handler(WidgetId, dropdown, 'String(this.value)', Handler),
		create_option_elements(Options, OptionElements),
		atomic_list_concat([
			'<div class="logtalk-input-group">',
			'<label class="logtalk-widget-label" for="', WidgetId, '">', Label, '</label><br>',
			'<select id="', WidgetId, '" ',
			'class="logtalk-widget-select" ',
			'onchange="', Handler, '" ',
			'style="margin: 5px; padding: 5px; border: 1px solid #ccc; border-radius: 3px;">',
			OptionElements,
			'</select>',
			'</div>'
		], HTML).

	% Create checkbox HTML
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

	% Create button HTML
	create_button_html(WidgetId, Label, HTML) :-
		create_update_handler(WidgetId, button, '\'clicked\'', Handler),
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

	% Helper predicates

	% Extract number input options
	extract_number_options([], '', '', '').
	extract_number_options([min(Min)|Rest], MinAttr, MaxAttr, StepAttr) :-
		atomic_list_concat(['min="', Min, '"'], MinAttr),
		extract_number_options(Rest, _, MaxAttr, StepAttr).
	extract_number_options([max(Max)|Rest], MinAttr, MaxAttr, StepAttr) :-
		atomic_list_concat(['max="', Max, '"'], MaxAttr),
		extract_number_options(Rest, MinAttr, _, StepAttr).
	extract_number_options([step(Step)|Rest], MinAttr, MaxAttr, StepAttr) :-
		atomic_list_concat(['step="', Step, '"'], StepAttr),
		extract_number_options(Rest, MinAttr, MaxAttr, _).
	extract_number_options([_|Rest], MinAttr, MaxAttr, StepAttr) :-
		extract_number_options(Rest, MinAttr, MaxAttr, StepAttr).

	% Create option elements for dropdown
	create_option_elements([], '').
	create_option_elements([Option|Rest], OptionElements) :-
		atomic_list_concat(['<option value="', Option, '">', Option, '</option>'], OptionElement),
		create_option_elements(Rest, RestElements),
		atomic_list_concat([OptionElement, RestElements], OptionElements).

:- end_object.
