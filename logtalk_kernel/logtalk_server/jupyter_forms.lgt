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


:- object(jupyter_forms,
	extends(jupyter_inputs)).

	:- info([
		version is 0:5:0,
		author is 'Paulo Moura',
		date is 2025-07-21,
		comment is 'Predicates for creating and managing HTML forms for data input in Logtalk notebooks.',
		remarks is [
			'Field specifications' - 'Each field specification is a compound term with the same arguments as the corresponding widget predicates. Field names and labels should be atoms.',
			'Text field' - '``text_field(Name, Label, DefaultValue)``.',
			'Textarea field' - '``textarea_field(Name, Label, DefaultValue, Rows)``.',
			'Email field' - '``email_field(Name, Label, DefaultValue, Pattern)``.',
			'URL field' - '``url_field(Name, Label, DefaultValue, Pattern)``.',
			'Password field' - '``password_field(Name, Label)``.',
			'Number field' - '``number_field(Name, Label, Min, Max, Step, DefaultValue)``.',
			'Slider field' - '``slider_field(Name, Label, Min, Max, Step, DefaultValue)``.',
			'Dropdown field' - '``dropdown_field(Name, Label, MenuOptions)``.',
			'Checkbox field' - '``checkbox_field(Name, Label, Checked)``.',
			'Date field' - '``date_field(Name, Label, DefaultValue)``.',
			'Time field' - '``time_field(Name, Label, DefaultValue)``.',
			'Color field' - '``color_field(Name, Label, DefaultValue)``.',
			'File field' - '``file_field(Name, Label)``.',
			'Generic input field' - '``input_field(Name, Label, Attributes)``.',
			'Form options' - 'The form options are compound terms with a single atom argument.',
			'Title option' - '``title(Title)``. Default is "Input Form".',
			'Submit button label option' - '``submit_label(Label)``. Default is "Submit".',
			'Cancel button label option' - '``cancel_label(Label)``. Default is "Cancel".',
			'Style option' - '``style(Style)`` (not including the ``<style>`` and ``</style>`` tags).'
		]
	]).

	:- public(create_input_form/3).
	:- mode(create_input_form(+atom, +list(compound), +list(compound)), one).
	:- info(create_input_form/3, [
		comment is 'Creates an input form with specified options.',
		argnames is ['FormId', 'FieldSpecs', 'Options']
	]).

	:- public(create_input_form/2).
	:- mode(create_input_form(+atom, +list(compound)), one).
	:- info(create_input_form/2, [
		comment is 'Creates an input form with default options.',
		argnames is ['FormId', 'FieldSpecs']
	]).

	:- public(form/1).
	:- mode(form(-atom), zero_or_more).
	:- info(form/1, [
		comment is 'Enumerates, by backtracking, all existing forms.',
		argnames is ['FormId']
	]).

	:- public(get_form_data/2).
	:- mode(get_form_data(+atom, -list(pair(atom,ground))), zero_or_one).
	:- info(get_form_data/2, [
		comment is 'Gets the data submitted for a form.',
		argnames is ['FormId', 'Data']
	]).

	:- public(set_form_data/2).
	:- mode(set_form_data(+atom, +list(pair(atom,ground))), one).
	:- info(set_form_data/2, [
		comment is 'Sets the data for a form. Called by the callback server when form is submitted.',
		argnames is ['FormId', 'FormData']
	]).

	:- public(remove_form/1).
	:- mode(remove_form(+atom), one).
	:- info(remove_form/1, [
		comment is 'Removes a form. Succeeds also when the form does not exist.',
		argnames is ['FormId']
	]).

	:- public(remove_all_forms/0).
	:- mode(remove_all_forms, one).
	:- info(remove_all_forms/0, [
		comment is 'Clears all forms.'
	]).

	:- private(form_data_/2).
	:- dynamic(form_data_/2).
	:- mode(form_data_(?atom, ?list(pair(atom,ground))), zero_or_more).
	:- info(form_data_/2, [
		comment is 'Table of forms data.',
		argnames is ['FormId', 'Data']
	]).

	:- uses(jupyter_term_handling, [assert_success_response/4]).
	:- uses(type, [check/2]).
	:- uses(user, [atomic_list_concat/2]).

	:- multifile(type::type/1).
	type::type(form_id).

	:- multifile(type::check/2).
	type::check(form_id, Term) :-
		(	var(Term) ->
			throw(instantiation_error)
		;	\+ atom(Term) ->
			throw(type_error(atom, Term))
		;	form_data_(Term, _) ->
			throw(permission_error(create, form_id, Term))
		;	true
		).

	create_input_form(FormId, FieldSpecs, Options) :-
		check(form_id, FormId),
		assertz(form_data_(FormId, [])),
		create_form_html(FormId, FieldSpecs, Options, HTML),
		assert_success_response(form, [], '', [input_html-HTML]).

	create_input_form(FormId, FieldSpecs) :-
		create_input_form(FormId, FieldSpecs, []).

	form(FormId) :-
		form_data_(FormId, _).

	get_form_data(FormId, Data) :-
		form_data_(FormId, Data).

	set_form_data(FormId, Data) :-
		retractall(form_data_(FormId, _)),
		assertz(form_data_(FormId, Data)).

	remove_form(FormId) :-
		retractall(form_data_(FormId, _)).

	remove_all_forms :-
		retractall(form_data_(_, _)).

	create_form_html(FormId, FieldSpecs, Options, HTML) :-
		extract_form_options(Options, Title, SubmitLabel, CancelLabel, Style),
		create_field_elements(FieldSpecs, FieldElements),
		create_form_submit_handler(FormId, SubmitHandler),
		atomic_list_concat([
			'<div class="logtalk-form" id="', FormId, '_container">',
			'<form id="', FormId, '">',
			'<h3>', Title, '</h3>',
			FieldElements,
			'<div class="form-buttons">',
			'<button type="button" class="submit-btn" onclick="',
			'(function() {',
			'  const form = document.getElementById(\'', FormId, '\');',
			'  const formData = new FormData(form);',
			'  const data = {};',
			'  for (let [key, value] of formData.entries()) {',
			'    data[key] = value;',
			'  }',
			SubmitHandler,
			'})();">', SubmitLabel, '</button>',
			'<button type="button" class="clear-btn" onclick="document.getElementById(\'', FormId, '\').reset();">',CancelLabel,'</button>',
			'</div>',
			'</form>',
			'</div>',
			'<style>',
			Style,
			'</style>'
		], HTML).

	extract_form_options([], 'Input Form', 'Submit', 'Cancel', Style) :-
		default_style(Style).
	extract_form_options([title(Title)| Options], Title, SubmitLabel, CancelLabel, Style) :-
		extract_form_options(Options, _, SubmitLabel, CancelLabel, Style).
	extract_form_options([submit_label(Label)| Options], Title, Label, CancelLabel, Style) :-
		extract_form_options(Options, Title, _, CancelLabel, Style).
	extract_form_options([cancel_label(Label)| Options], Title, SubmitLabel, Label, Style) :-
		extract_form_options(Options, Title, SubmitLabel, _, Style).
	extract_form_options([style(Style)| Options], Title, SubmitLabel, CancelLabel, Style) :-
		extract_form_options(Options, Title, SubmitLabel, CancelLabel, _).
	extract_form_options([_| Options], Title, SubmitLabel, CancelLabel, Style) :-
		extract_form_options(Options, Title, SubmitLabel, CancelLabel, Style).

	create_field_elements(Specs, Elements) :-
		create_field_elements_list(Specs, Elements0),
		atomic_list_concat(Elements0, Elements).

	create_field_elements_list([], []).
	create_field_elements_list([Spec| Specs], [Element| Elements]) :-
		create_field_element(Spec, Element),
		create_field_elements_list(Specs, Elements).

	create_field_element(text_field(Name, Label, DefaultValue), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="text" id="', Name, '" name="', Name, '" value="', DefaultValue, '">',
			'</div>'
		], Element).

	create_field_element(number_field(Name, Label, Min, Max, Step, DefaultValue), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="number" id="', Name, '" name="', Name, '" min="', Min, '" max="', Max, '" step="', Step, '" value="', DefaultValue, '">',
			'</div>'
		], Element).

	create_field_element(email_field(Name, Label, DefaultValue, Pattern), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="email" id="', Name, '" name="', Name, '" value="', DefaultValue, '" pattern="', Pattern, '">',
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

	create_field_element(dropdown_field(Name, Label, MenuOptions), Element) :-
		create_select_options(MenuOptions, '', OptionElements),
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<select id="', Name, '" name="', Name, '">',
			OptionElements,
			'</select>',
			'</div>'
		], Element).

	create_field_element(input_field(Name, Label, Attributes), Element) :-
		^^create_input_attributes_string(Attributes, AttributesString),
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input id="', Name, '" name="', Name, '" ', AttributesString, '>',
			'</div>'
		], Element).

	create_field_element(checkbox_field(Name, Label, DefaultValue), Element) :-
		(	DefaultValue == true ->
			CheckedAttr = 'checked'
		;	CheckedAttr = ''
		),
		atomic_list_concat([
			'<div class="form-field checkbox-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="checkbox" id="', Name, '" name="', Name, '" value="true" ', CheckedAttr, '>',
			'</div>'
		], Element).

	create_field_element(slider_field(Name, Label, Min, Max, Step, DefaultValue), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="range" id="', Name, '" name="', Name, '" min="', Min, '" max="', Max, '" step="', Step, '" value="', DefaultValue, '">',
			'</div>'
		], Element).

	create_field_element(date_field(Name, Label, DefaultValue), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="date" id="', Name, '" name="', Name, '" value="', DefaultValue, '">',
			'</div>'
		], Element).

	create_field_element(time_field(Name, Label, DefaultValue), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="time" id="', Name, '" name="', Name, '" value="', DefaultValue, '">',
			'</div>'
		], Element).

	create_field_element(color_field(Name, Label, DefaultValue), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="color" id="', Name, '" name="', Name, '" value="', DefaultValue, '">',
			'</div>'
		], Element).

	create_field_element(url_field(Name, Label, DefaultValue, Pattern), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="url" id="', Name, '" name="', Name, '" value="', DefaultValue, '" pattern="', Pattern, '">',
			'</div>'
		], Element).

	create_field_element(file_field(Name, Label), Element) :-
		atomic_list_concat([
			'<div class="form-field">',
			'<label for="', Name, '">', Label, '</label>',
			'<input type="file" id="', Name, '" name="', Name, '">',
			'</div>'
		], Element).

	create_select_options(Options, DefaultValue, OptionElements) :-
		create_select_options_list(Options, Option, OptionElements0),
		atomic_list_concat(OptionElements0, OptionElements).

	create_select_options_list([], _, []).
	create_select_options_list([Option| Options], DefaultValue, [Element| Elements]) :-
		(	Option == DefaultValue ->
			atomic_list_concat(['<option value="', Option, '" selected>', Option, '</option>'], Element)
		;	atomic_list_concat(['<option value="', Option, '">', Option, '</option>'], Element)
		),
		create_select_options_list(Options, DefaultValue, Elements).

	create_form_submit_handler(FormId, Handler) :-
		^^webserver(IP, Port),
		atomic_list_concat([
			'  fetch(\'http://', IP, ':', Port, '\', {',
			'    method: \'POST\',',
			'    headers: {\'Content-Type\': \'application/json\'},',
			'    body: JSON.stringify({type: \'form\', id: \'', FormId, '\', value: data})',
			'  })',
			'  .then(response => response.json());'
		], Handler).

	default_style(Style) :-
		atomic_list_concat([
			'.logtalk-form {',
			'  max-width: 500px;',
			'  margin: 20px 0;',
			'  padding: 20px;',
			'  border: 1px solid #ddd;',
			'  border-radius: 8px;',
			'  background-color: #f9f9f9;',
			'  font-family: system-ui, "Segoe UI", "Liberation Sans", Arial, "Noto Sans", Roboto, sans-serif;',
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
			'.checkbox-field {',
			'  display: flex;',
			'  align-items: center;',
			'  gap: 10px;',
			'}',
			'.checkbox-field label {',
			'  display: inline;',
			'  margin-bottom: 0;',
			'  flex: 1;',
			'}',
			'.checkbox-field input[type="checkbox"] {',
			'  width: auto;',
			'  margin: 0;',
			'  flex-shrink: 0;',
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
			'.clear-btn {',
			'  background-color: #6c757d;',
			'  color: white;',
			'}',
			'.clear-btn:hover {',
			'  background-color: #545b62;',
			'}'
		], Style).

:- end_object.
