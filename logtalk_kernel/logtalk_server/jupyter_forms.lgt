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
		version is 0:1:0,
		author is 'Paulo Moura',
		date is 2025-07-15,
		comment is 'Predicates for creating and managing HTML forms for data input in Logtalk notebooks.',
		remarks is [
			'Field specifications' - 'Each field specification is a compound term. Field names and labels should be atoms.',
			'Text field' - '``text_field(Name, Label, DefaultValue)``.',
			'Email field' - '``email_field(Name, Label, DefaultValue)``.',
			'Password field' - '``password_field(Name, Label)``.',
			'Number field' - '``number_field(Name, Label, DefaultValue)``.',
			'Textarea field' - '``textarea_field(Name, Label, DefaultValue, Rows)``.',
			'Select field' - '``select_field(Name, Label, Options, DefaultValue)``.',
			'Checkbox field' - '``checkbox_field(Name, Label, DefaultValue)``.',
			'Form options' - 'The form options are compound terms with a single atom argument.',
			'Title option' - '``title(Title)``.',
			'Submit button label option' - '``submit_label(Label)``.',
			'Cancel button label option' - '``cancel_label(Label)``.',
			'Style option' - '``style(Style)`` (not including the ``<style>`` and ``</style>`` tags).'
		]
	]).

	:- public(create_input_form/2).
	:- mode(create_input_form(+atom, +list(compound)), one).
	:- info(create_input_form/2, [
		comment is 'Create an input form with default options.',
		argnames is ['FormId', 'FieldSpecs']
	]).

	:- public(create_input_form/3).
	:- mode(create_input_form(+atom, +list(compound), +list(compound)), one).
	:- info(create_input_form/3, [
		comment is 'Create an input form with specified options.',
		argnames is ['FormId', 'FieldSpecs', 'Options']
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
		comment is 'Get the data submitted for a form.',
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

	create_input_form(FormId, FieldSpecs) :-
		create_input_form(FormId, FieldSpecs, []).

	create_input_form(FormId, FieldSpecs, Options) :-
		check(form_id, FormId),
		assertz(form_data_(FormId, [])),
		create_form_html(FormId, FieldSpecs, Options, HTML),
		assert_success_response(form, [], '', [input_html-HTML]).

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

	% Extract form options
	extract_form_options([], 'Input Form', 'Submit', 'Cancel', Style) :-
		default_style(Style).
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

	% Create form submit handler (similar to widget update handler)
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
			'.clear-btn {',
			'  background-color: #6c757d;',
			'  color: white;',
			'}',
			'.clear-btn:hover {',
			'  background-color: #545b62;',
			'}'
		], Style).

:- end_object.
