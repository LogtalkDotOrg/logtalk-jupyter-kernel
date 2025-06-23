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


% This object provides predicates for creating and managing HTML forms
% for data input in Logtalk Jupyter notebooks.


:- object(jupyter_form_handling).

	:- info([
		version is 0:1:0,
		author is 'Paulo Moura',
		date is 2025-01-27,
		comment is 'This object provides predicates for creating and managing HTML forms for data input in Logtalk notebooks.'
	]).

	:- public([
		create_input_form/2,        % create_input_form(+FormId, +FieldSpecs)
		create_input_form/3,        % create_input_form(+FormId, +FieldSpecs, +Options)
		get_form_data/2,            % get_form_data(+FormId, -Data)
		clear_form_data/1,          % clear_form_data(+FormId)
		form_exists/1               % form_exists(+FormId)
	]).

	:- uses(jupyter_logging, [log/1, log/2]).
	:- uses(jupyter_term_handling, [assert_success_response/4]).

	% Dynamic predicate to store form data
	:- dynamic(form_data/2).  % form_data(FormId, Data)

	% Form counter for generating unique IDs
	:- dynamic(form_counter/1).
	form_counter(0).

	% Generate unique form ID
	generate_form_id(FormId) :-
		retract(form_counter(N)),
		N1 is N + 1,
		assertz(form_counter(N1)),
		atomic_list_concat(['form_', N1], FormId).

	% Create input form with default options
	create_input_form(FormId, FieldSpecs) :-
		create_input_form(FormId, FieldSpecs, []).

	% Create input form with options
	create_input_form(FormId, FieldSpecs, Options) :-
		(	var(FormId) ->
			generate_form_id(FormId)
		;	true
		),
		% Initialize form data storage
		assertz(form_data(FormId, [])),
		% Generate form HTML
		create_form_html(FormId, FieldSpecs, Options, HTML),
		assert_success_response(form, [], '', [widget_html-HTML]).

	% Get form data
	get_form_data(FormId, Data) :-
		form_data(FormId, Data).

	% Clear form data
	clear_form_data(FormId) :-
		retractall(form_data(FormId, _)).

	% Check if form exists
	form_exists(FormId) :-
		form_data(FormId, _).

	% Generate form HTML
	create_form_html(FormId, FieldSpecs, Options, HTML) :-
		extract_form_options(Options, Title, SubmitLabel, CancelLabel, Style),
		create_field_elements(FieldSpecs, FieldElements),
		atomic_list_concat([
			'<div class="logtalk-form" id="', FormId, '_container">',
			'<form id="', FormId, '" onsubmit="submitLogtalkForm(\'', FormId, '\'); return false;">',
			'<h3>', Title, '</h3>',
			FieldElements,
			'<div class="form-buttons">',
			'<button type="submit" class="submit-btn">', SubmitLabel, '</button>',
			'<button type="button" class="cancel-btn" onclick="cancelLogtalkForm(\'', FormId, '\')">', CancelLabel, '</button>',
			'</div>',
			'</form>',
			'</div>',
			'<script>',
			'function submitLogtalkForm(formId) {',
			'  const form = document.getElementById(formId);',
			'  const formData = new FormData(form);',
			'  const data = {};',
			'  for (let [key, value] of formData.entries()) {',
			'    data[key] = value;',
			'  }',
			'  const code = `jupyter_form_handling::update_form_data(\'${formId}\', ${JSON.stringify(data)}).`;',
			'  if (typeof Jupyter !== "undefined" && Jupyter.notebook && Jupyter.notebook.kernel) {',
			'    Jupyter.notebook.kernel.execute(code, {silent: true, store_history: false});',
			'  }',
			'  document.getElementById(formId + "_container").style.display = "none";',
			'}',
			'function cancelLogtalkForm(formId) {',
			'  document.getElementById(formId + "_container").style.display = "none";',
			'}',
			'</script>',
			'<style>',
			'.logtalk-form {',
			'  max-width: 500px;',
			'  margin: 20px 0;',
			'  padding: 20px;',
			'  border: 1px solid #ddd;',
			'  border-radius: 8px;',
			'  background-color: #f9f9f9;',
			'  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;',
			'}',
			'.logtalk-form h3 {',
			'  margin-top: 0;',
			'  color: #333;',
			'}',
			'.form-field {',
			'  margin-bottom: 15px;',
			'}',
			'.form-field label {',
			'  display: block;',
			'  margin-bottom: 5px;',
			'  font-weight: 500;',
			'  color: #555;',
			'}',
			'.form-field input, .form-field select, .form-field textarea {',
			'  width: 100%;',
			'  padding: 8px 12px;',
			'  border: 1px solid #ccc;',
			'  border-radius: 4px;',
			'  font-size: 14px;',
			'  box-sizing: border-box;',
			'}',
			'.form-field input:focus, .form-field select:focus, .form-field textarea:focus {',
			'  outline: none;',
			'  border-color: #007cba;',
			'  box-shadow: 0 0 0 2px rgba(0, 124, 186, 0.2);',
			'}',
			'.form-buttons {',
			'  margin-top: 20px;',
			'  text-align: right;',
			'}',
			'.form-buttons button {',
			'  margin-left: 10px;',
			'  padding: 10px 20px;',
			'  border: none;',
			'  border-radius: 4px;',
			'  cursor: pointer;',
			'  font-size: 14px;',
			'}',
			'.submit-btn {',
			'  background-color: #007cba;',
			'  color: white;',
			'}',
			'.submit-btn:hover {',
			'  background-color: #005a87;',
			'}',
			'.cancel-btn {',
			'  background-color: #6c757d;',
			'  color: white;',
			'}',
			'.cancel-btn:hover {',
			'  background-color: #545b62;',
			'}',
			'</style>'
		], HTML).

	% Extract form options
	extract_form_options([], 'Input Form', 'Submit', 'Cancel', '').
	extract_form_options([title(Title)|Rest], Title, SubmitLabel, CancelLabel, Style) :-
		extract_form_options(Rest, _, SubmitLabel, CancelLabel, Style).
	extract_form_options([submit_label(Label)|Rest], Title, Label, CancelLabel, Style) :-
		extract_form_options(Rest, Title, _, CancelLabel, Style).
	extract_form_options([cancel_label(Label)|Rest], Title, SubmitLabel, Label, Style) :-
		extract_form_options(Rest, Title, SubmitLabel, _, Style).
	extract_form_options([style(Style)|Rest], Title, SubmitLabel, CancelLabel, Style) :-
		extract_form_options(Rest, Title, SubmitLabel, CancelLabel, _).
	extract_form_options([_|Rest], Title, SubmitLabel, CancelLabel, Style) :-
		extract_form_options(Rest, Title, SubmitLabel, CancelLabel, Style).

	% Create field elements
	create_field_elements([], '').
	create_field_elements([FieldSpec|Rest], FieldElements) :-
		create_field_element(FieldSpec, FieldElement),
		create_field_elements(Rest, RestElements),
		atomic_list_concat([FieldElement, RestElements], FieldElements).

	% Create individual field element
	create_field_element(text_field(Name, Label, DefaultValue), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="text" id="', Name, '" name="', Name, '" value="', DefaultValue, '">',
			'</div>'
		], Element).

	create_field_element(number_field(Name, Label, DefaultValue), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="number" id="', Name, '" name="', Name, '" value="', DefaultValue, '">',
			'</div>'
		], Element).

	create_field_element(email_field(Name, Label, DefaultValue), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="email" id="', Name, '" name="', Name, '" value="', DefaultValue, '">',
			'</div>'
		], Element).

	create_field_element(password_field(Name, Label), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="password" id="', Name, '" name="', Name, '">',
			'</div>'
		], Element).

	create_field_element(textarea_field(Name, Label, DefaultValue, Rows), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<textarea id="', Name, '" name="', Name, '" rows="', Rows, '">', DefaultValue, '</textarea>',
			'</div>'
		], Element).

	create_field_element(select_field(Name, Label, Options, DefaultValue), Element) :-
		create_select_options(Options, DefaultValue, OptionElements),
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<select id="', Name, '" name="', Name, '">',
			OptionElements,
			'</select>',
			'</div>'
		], Element).

	create_field_element(checkbox_field(Name, Label, DefaultValue), Element) :-
		(	DefaultValue == true ->
			CheckedAttr = 'checked'
		;	CheckedAttr = ''
		),
		atomic_list_concat([
			'<div class="form-field">',
			'<input type="checkbox" id="', Name, '" name="', Name, '" value="true" ', CheckedAttr, '>',
			'<label for="', Name, '">', Label, '</label>',
			'</div>'
		], Element).

	% Create select options
	create_select_options([], _, '').
	create_select_options([Option|Rest], DefaultValue, OptionElements) :-
		(	Option == DefaultValue ->
			SelectedAttr = 'selected'
		;	SelectedAttr = ''
		),
		atomic_list_concat(['<option value="', Option, '" ', SelectedAttr, '>', Option, '</option>'], OptionElement),
		create_select_options(Rest, DefaultValue, RestElements),
		atomic_list_concat([OptionElement, RestElements], OptionElements).

	% Update form data (called from JavaScript)
	update_form_data(FormId, DataJSON) :-
		retractall(form_data(FormId, _)),
		assertz(form_data(FormId, DataJSON)).

:- end_object.
