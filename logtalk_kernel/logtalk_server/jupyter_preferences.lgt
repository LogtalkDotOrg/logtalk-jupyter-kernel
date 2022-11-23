
:- object(jupyter_preferences).

	:- info([
		version is 0:1:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2022-11-23,
		comment is 'Preferecnes management.'
	]).

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

	:- public(version/4).
	:- mode(version(-integer, -integer, -integer, -atom), one).
	:- info(version/4, [
		comment is 'Returns the current version.',
		argnames is ['Major', 'Minor', 'Patch', 'Status']
	]).

	:- initialization(init_preferences).

	:- private(preference_value_/2).
	:- dynamic(preference_value_/2).

	:- uses(logtalk, [
		print_message(debug, jupyter, Message) as dbg(Message)
	]).

	version(0, 1, 0, 'nightly').

	preference_definition(verbosity, 1, natural, 'Verbosity level, 0=off, 10=maximal').

	set_preference(Name, Value) :-
		set_preference(Name, _Old, Value).

	set_preference(Name, OldValue, NewValue) :-
		preference_definition(Name, _, Type, _Desc),
		check_type(Type, Value),
		retract(preference_value_(Name, OldValue)), !,
		dbg('Changing preference ~w from ~w to ~w~n'+[Name, OldValue, NewValue]),
		assertz(preference_value_(Name, Value)).

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
