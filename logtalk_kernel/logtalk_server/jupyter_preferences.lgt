
:- object(jupyter_preferences).

	:- info([
		version is 0:1:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2022-11-11,
		comment is 'Preferecnes management.'
	]).

	:- public([
		set_preference/2, set_preference/3, 
		get_preference/2, get_preferences/1,
		reset_preferences/0
	]).

	:- initialization(init_preferences).

	:- private(preference_value/2).
	:- dynamic(preference_value/2).

	:- uses(logtalk, [
		print_message(debug, jupyter, Message) as dbg(Message)
	]).

	preference_definition(verbosity,1,natural,'Verbosity level, 0=off, 10=maximal').

	set_preference(Name,Value) :-
		set_preference(Name,_Old,Value).

	set_preference(Name,OldValue,Value) :-
		preference_definition(Name,_,Type,_Desc),
		check_type(Type,Value),
		retract(preference_value(Name,OldValue)),!,
		dbg('Changing preference ~w from ~w to ~w~n'+[Name,OldValue,Value]),
		assertz(preference_value(Name,Value)).

	check_type(natural,Val) :- integer(Val), Val >= 0.
	check_type(integer,Val) :- integer(Val).
	check_type(boolean,true).
	check_type(boolean,false).

	get_preference(Name,Value) :-
		preference_value(Name,Value).

	get_preferences(List) :-
		findall(P-V,get_preference(P,V),L),
		sort(L,List).

	init_preferences :-
		preference_definition(Name,Default,_Type,_Desc),
		\+ preference_value(Name,_), % not already defined
		dbg('Initialising preference ~w to ~w~n'+[Name,Default]),
		assertz(preference_value(Name,Default)),
		fail.
	init_preferences.

	reset_preferences :-
		retractall(preference_value(_,_)),
		preference_definition(Name,Default,_Type,_Desc),
		dbg('Resetting preference ~w to ~w~n'+[Name,Default]),
		assertz(preference_value(Name,Default)),
		fail.
	reset_preferences.

:- end_object.
