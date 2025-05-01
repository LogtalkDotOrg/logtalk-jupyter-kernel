%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Copyright (c) 2022-2023 Paulo Moura  
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


% It is based on the module toplevel_variables from SWI-Prolog (version 8.4.2).

% Define $ to be an operator.
% This is needed so that terms containing terms of the form $Var can be read without any exceptions.
:- op(1, fx, '$').


:- object(jupyter_variable_bindings).

	:- info([
		version is 0:5:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2025-05-01,
		comment is 'This object provides predicates to reuse previous values of variables in a query.'
	]).

	:- public(store_var_bindings/1).
	:- mode(store_var_bindings(+list), one).
	:- info(store_var_bindings/1, [
		comment is 'Stores variable bindings.',
		argnames is ['Bindings']
	]).

	:- public(term_with_stored_var_bindings/4).
	:- mode(term_with_stored_var_bindings(+term, +list, -term, -list), one).
	:- info(term_with_stored_var_bindings/4, [
		comment is 'Expands ``Term`` by replacing all ``$Var`` terms with the latest value of the ``Var`` variables from a previous execution.',
		argnames is ['Term', 'Bindings', 'ExpandedTerm', 'UpdatedBindings']
	]).

	:- public(var_bindings/1).
	:- dynamic(var_bindings/1).
	:- mode(var_bindings(-list), one).
	:- info(var_bindings/1, [
		comment is 'Variable bindings (``Name=Var`` pairs where ``Name`` is the name of the variable ``Var`` of the latest query in which a variable of this name was assigned a value).',
		argnames is ['Bindings']
	]).

	var_bindings([]).

	:- uses(list, [append/3, delete/3, member/2]).

	:- multifile(logtalk::message_tokens//2).
	:- dynamic(logtalk::message_tokens//2).

	logtalk::message_tokens(jupyter(invalid_var_reference(VarName)), jupyter) -->
		['$~w is not a valid variable reference'-[VarName]], [nl].
	logtalk::message_tokens(jupyter(no_var_binding(VarName)), jupyter) -->
		['$~w was not bound by a previous query~n'-[VarName]], [nl].

	% Store variable var_bindings

	% store_var_bindings(+Bindings)
	%
	% Bindings is a list of Name=Var pairs, where Name is the name of a variable Var occurring in the term Term.
	% Updates the previously stored variable bindings with the new values if the variables are instantiated.
	store_var_bindings(Bindings) :-
		retract(var_bindings(StoredBindings)),
		!,
		updated_variables(StoredBindings, Bindings, UpdatedBindings),
		assertz(var_bindings(UpdatedBindings)).
	store_var_bindings(Bindings) :-
		% There are no previously stored variables
		% Call updated_variables/3 anyway to make sure that only instantiated values are stored
		updated_variables([], Bindings, BoundBindings),
		assertz(var_bindings(BoundBindings)).

	% Reuse stored variable bindings
	
	% term_with_stored_var_bindings(+Term, +Bindings, -ExpandedTerm, -UpdatedBindings)
	%
	% ExpandedTerm results from expanding the term Term by replacing all terms of the form $Var
	%  with the latest value of the variable Var from a previous execution.
	% Bindings is a list of Name=Var pairs, where Name is the name of a variable Var occurring in the term Term.
	% If any term $Var was replaced, UpdatedBindings contains the corresponding value.
	% If there is no previous value for one of the variables, an exception is thrown.
	term_with_stored_var_bindings(Term, Bindings, ExpandedTerm, UpdatedBindings) :-
		expand_term(Term, Bindings, ExpandedTerm, StoredBindings),
		updated_variables(Bindings, StoredBindings, UpdatedBindings).

	% expand_term(+Term, +Bindings, -ExpandedTerm, -StoredBindings)
	expand_term(Var, _Bindings, Var, []) :-
		var(Var),
		!.
	expand_term(Atomic, _Bindings, Atomic, []) :-
		atomic(Atomic),
		!.
	expand_term($(Var), _Bindings, _Value, _) :-
		nonvar(Var),
		throw(jupyter(invalid_var_reference(Var))).
	expand_term($(Var), Bindings, Value, [Name=Value]) :-
		!,
		% Get the name of the variable to get the previous value
		var_name(Bindings, Var, Name),
		stored_variable_binding(Name, Value).
	expand_term(Term, Bindings, ExpandedTerm, StoredBindings) :-
		functor(Term, Name, Arity),
		!,
		functor(ExpandedTerm, Name, Arity),
		expand_args(1, Bindings, Term, ExpandedTerm, StoredBindings).

	% expand_args(+ArgNum, +Bindings, +Term, +ExpandedTerm, -StoredBindings)
	expand_args(ArgNum, Bindings, Term, ExpandedTerm, StoredBindings) :-
		arg(ArgNum, Term, Arg),
		arg(ArgNum, ExpandedTerm, ExpandedArg),
		!,
		NextArgNum is ArgNum + 1,
		expand_term(Arg, Bindings, ExpandedArg, TermBindings),
		append(TermBindings, ArgsBindings, StoredBindings),
		expand_args(NextArgNum, Bindings, Term, ExpandedTerm, ArgsBindings).
	expand_args(_ArgNum, _Bindings, _Term, _ExpandedTerm, []).

	% var_name(+Bindings, +Var, -Name)
	%
	% Bindings is a list of Name=Var pairs, where Name is the name of a variable Var.
	var_name([Name=SameVar|_Bindings], Var, Name) :-
		Var == SameVar,
		!.
	var_name([_Binding|Bindings], Var, Name) :-
		var_name(Bindings, Var, Name).

	% stored_variable_binding(+VarName, -VarValue)
	%
	% VarValue is the latest value of the variable with name VarName.
	% If there is no previous value, an exception is thrown.
	stored_variable_binding(VarName, VarValue) :-
		var_bindings(Bindings),
		member(VarName=VarValue, Bindings),
		!.
	stored_variable_binding(VarName, _VarValue) :-
		throw(jupyter(no_var_binding(VarName))).

	% Update variable list

	% updated_variables(+BindingsToUpdate, +BindingsToUpdateWith, -UpdatedBindings)
	%
	% The arguments are lists of Name=Var pairs, where Name is the name of a variable Var occurring in the term Term.
	% UpdatedBindings contains all elements of BindingsToUpdateWith if the corresponding variables are instantiated.
	% It also contains those elements of BindingsToUpdate for which there is no instantiated element with the same variable name in BindingsToUpdateWith.
	updated_variables([], [], []) :- !.
	updated_variables([], [Name=Value|BindingsToUpdateWith], [Name=Value|UpdatedBindings]) :-
		nonvar(Value),
		acyclic_term(Value),
		!,
		updated_variables([], BindingsToUpdateWith, UpdatedBindings).
	updated_variables([], [_Name=_Value|BindingsToUpdateWith], UpdatedBindings) :-
		updated_variables([], BindingsToUpdateWith, UpdatedBindings).
	updated_variables([Name=_Var|BindingsToUpdate], BindingsToUpdateWith, [Name=Value|UpdatedBindings]) :-
		member(Name=Value, BindingsToUpdateWith),
		nonvar(Value),
		acyclic_term(Value),
		% There is a value Value for the variable with name Name in BindingsToUpdateWith -> use that value
		!,
		% Delete the entry from the list BindingsToUpdateWith as it has been processed
		delete(BindingsToUpdateWith, Name=Value, RemainingBindings),
		updated_variables(BindingsToUpdate, RemainingBindings, UpdatedBindings).
	updated_variables([Name=Var|BindingsToUpdate], BindingsToUpdateWith, [Name=Var|UpdatedBindings]) :-
		% There is no new value for the variable with name Name
		updated_variables(BindingsToUpdate, BindingsToUpdateWith, UpdatedBindings).

:- end_object.
