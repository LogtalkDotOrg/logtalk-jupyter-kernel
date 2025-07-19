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


:- object(jupyter_inputs).

	:- info([
		version is 0:2:0,
		author is 'Paulo Moura',
		date is 2025-07-19,
		comment is 'Common functionality for HTML/JavaScript based input widgets and forms in Logtalk notebooks.'
	]).

	:- public(webserver/2).
	:- mode(webserver(?atom, ?positive_integer), zero_or_one).
	:- info(webserver/2, [
		comment is 'Input callback webserver IP address and port. Only available after being set automatically by the kernel.',
		argnames is ['IP', 'Port']
	]).

	:- public(set_webserver/2).
	:- mode(set_webserver(+atom, +positive_integer), one).
	:- info(set_webserver/2, [
		comment is 'Sets the input callback webserver IP address and port. Called automatically by the kernel.',
		argnames is ['IP', 'Port']
	]).

	:- private(webserver_/2).
	:- dynamic(webserver_/2).
	:- mode(webserver_(?atom, ?positive_integer), zero_or_one).
	:- info(webserver_/2, [
		comment is 'Input callback webserver IP address and port.',
		argnames is ['IP', 'Port']
	]).

	:- protected(create_input_attributes_string/2).
	:- mode(create_input_attributes_string(+list(pair(atom,ground)), -atom), one).
	:- info(create_input_attributes_string/2, [
		comment is 'Converts a list of attributes to a HTML attributes string.',
		argnames is ['Attributes', 'String']
	]).

	webserver(IP, Port) :-
		webserver_(IP, Port).

	set_webserver(IP, Port) :-
		retractall(webserver_(_, _)),
		assertz(webserver_(IP, Port)).

	create_input_attributes_string([], '').
	create_input_attributes_string([Key-Value|Rest], AttributesString) :-
		atomic_list_concat([Key, '="', Value, '"'], AttributeString),
		create_input_attributes_string(Rest, RestAttributesString),
		(	RestAttributesString = '' ->
			AttributesString = AttributeString
		;	atomic_list_concat([AttributeString, ' ', RestAttributesString], AttributesString)
		).

:- end_object.
