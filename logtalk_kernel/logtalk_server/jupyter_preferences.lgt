%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Copyright (c) 2022-2025 Paulo Moura  
%  Copyright (c) 2022 Anne Brecklinghaus, Michael Leuschel, dgelessus
%  SPDX-License-Identifier: MIT
%
%  Permission is hereby granted, free of charge, to any person obtaining a copy
%  of this software and associated documentation files (the "Software"), to deal
%  in the Software without restriction, including without limitation the rights
%  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%  copies of the Software, and to permit persons to whom the Software is
%  furnished to do so, subject to the following conditions:
%
%  The above copyright notice and this permission notice shall be included in all
%  copies or substantial portions of the Software.
%
%  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%  SOFTWARE.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


:- object(jupyter_preferences).

	:- info([
		version is 0:12:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2025-03-05,
		comment is 'Preferences management.'
	]).

	:- initialization(init_preferences).

	:- public(set_preference/2).
	:- mode(set_preference(+atom, +nonvar), one).
	:- info(set_preference/2, [
		comment is 'Sets a preference value.',
		argnames is ['Preference', 'Value']
	]).

	:- public(set_preference/3).
	:- mode(set_preference(+atom, -nonvar, +nonvar), one).
	:- info(set_preference/3, [
		comment is 'Sets a preference value.',
		argnames is ['Preference', 'OldValue', 'NewValue']
	]).

	:- public(get_preference/2).
	:- mode(get_preference(+atom, -nonvar), one).
	:- info(get_preference/2, [
		comment is 'Returns a preference value.',
		argnames is ['Preference', 'Value']
	]).

	:- public(get_preferences/1).
	:- mode(get_preferences(-list(pair(atom,nonvar))), one).
	:- info(get_preferences/1, [
		comment is 'Returns a list of all preferences.',
		argnames is ['Preferences']
	]).

	:- public(reset_preferences/0).
	:- mode(reset_preferences, one).
	:- info(reset_preferences/0, [
		comment is 'Reset preferences.'
	]).

	:- private(preference_value_/2).
	:- dynamic(preference_value_/2).
	:- mode(preference_value_(?atom, ?nonvar), zero_or_more).
	:- info(preference_value_/2, [
		comment is 'Table of preference values.',
		argnames is ['Preference', 'Value']
	]).

	:- uses(logtalk, [
		print_message(debug, jupyter, Message) as dbg(Message)
	]).

	preference_definition(verbosity, 1, natural, 'Verbosity level, 0=off, 10=maximal').

	set_preference(Name, Value) :-
		set_preference(Name, _Old, Value).

	set_preference(Name, OldValue, NewValue) :-
		preference_definition(Name, _, Type, _Desc),
		check_type(Type, NewValue),
		retract(preference_value_(Name, OldValue)), !,
		dbg('Changing preference ~w from ~w to ~w~n'+[Name, OldValue, NewValue]),
		assertz(preference_value_(Name, NewValue)).

	check_type(natural,Val) :- integer(Val), Val >= 0.
	check_type(integer,Val) :- integer(Val).
	check_type(boolean,true).
	check_type(boolean,false).

	get_preference(Name, Value) :-
		preference_value_(Name, Value).

	get_preferences(List) :-
		findall(P-V,get_preference(P,V),L),
		sort(L,List).

	init_preferences :-
		preference_definition(Name, Default, _Type, _Desc),
		\+ preference_value_(Name, _), % not already defined
		dbg('Initialising preference ~w to ~w~n'+[Name,Default]),
		assertz(preference_value_(Name,Default)),
		fail.
	init_preferences.

	reset_preferences :-
		retractall(preference_value_(_,_)),
		preference_definition(Name,Default,_Type,_Desc),
		dbg('Resetting preference ~w to ~w~n'+[Name,Default]),
		assertz(preference_value_(Name,Default)),
		fail.
	reset_preferences.

:- end_object.
