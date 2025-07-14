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


:- object(jupyter).

	:- info([
		version is 0:19:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2025-07-14,
		comment is 'This object provides special predicates which can be used in call requests by the client. Some of these predicates need to be the only goal of a query. Otherwise, they cannot be determined as special predicates and do not work as expected.'
	]).

	:- initialization(debugger::leash(none)).

	:- public(help/0).
	:- mode(help, one).
	:- info(help/0, [
		comment is 'Prints the documentation for all public predicates defined in ``jupyter`` object.'
	]).

	:- public(version/0).
	:- mode(version, one).
	:- info(version/0, [
		comment is 'Prints the kernel version.'
	]).

	:- public(versions/0).
	:- mode(versions, one).
	:- info(versions/0, [
		comment is 'Prints the Logtalk, Prolog backend, and kernel versions.'
	]).

	:- public(version/4).
	:- mode(version(-integer, -integer, -integer, -atom), one).
	:- info(version/4, [
		comment is 'Returns the current version.',
		argnames is ['Major', 'Minor', 'Patch', 'Status']
	]).

	:- public(set_prolog_backend/1).
	:- mode(set_prolog_backend(+atom), zero_or_more).
	:- info(set_prolog_backend/1, [
		comment is 'Activates the given Prolog backend. Must be the only goal of a query.',
		argnames is ['Backend']
	]).

	:- public(magic/0).
	:- mode(magic, one).
	:- info(magic/0, [
		comment is 'Prints the documentation of all cell and line magic.'
	]).

	:- public(trace/1).
	:- mode(trace(+callable), zero_or_more).
	:- info(trace/1, [
		comment is 'Prints the trace of the goal ``Goal``.',
		argnames is ['Goal']
	]).

	:- public(pwd/0).
	:- mode(pwd, one).
	:- info(pwd/0, [
		comment is 'Prints the current working directory.'
	]).

	:- public(cd/1).
	:- mode(cd(+atom), zero_or_more).
	:- info(cd/1, [
		comment is 'Changes the current working directory.',
		argnames is ['Directory']
	]).

	:- public(retry/0).
	:- mode(retry, one).
	:- info(retry/0, [
		comment is 'Causes backtracking of the latest active query. Must be the only goal of a query.'
	]).

	:- public(print_queries/0).
	:- mode(print_queries, one).
	:- info(print_queries/0, [
		comment is 'Prints previous queries.'
	]).

	:- public(print_queries/1).
	:- mode(print_queries(?list(callable)), one).
	:- info(print_queries/1, [
		comment is 'Prints previous queries which were executed in requests with IDs in ``Ids``.',
		argnames is ['Ids']
	]).

	:- public(print_query_time/0).
	:- mode(print_query_time, one).
	:- info(print_query_time/0, [
		comment is 'Prints previous query execution time.'
	]).

	:- public(print_variable_bindings/0).
	:- mode(print_variable_bindings, one).
	:- info(print_variable_bindings/0, [
		comment is 'Prints variable bindings from previous queries. For each variable, the latest value it was bound to is shown. The variable value can be accessed with a ``$Var`` term by any query. In that case, the term is replaced by the value. If there is no previous value, an error message is printed.'
	]).

	:- public(print_table/1).
	:- mode(print_table(+callable), one).
	:- info(print_table/1, [
		comment is 'Computes all solutions of the goal using ``findall/3`` and prints a table with the solution variable bindings. Values for variable names starting with an underscore are omitted. Must be the only goal of a query.',
		argnames is ['Goal']
	]).

	:- public(print_and_save_table/3).
	:- mode(print_and_save_table(+callable, +atom, +atom), one).
	:- info(print_and_save_table/3, [
		comment is 'Same as the ``print_table/1`` predicate but also saves the table to a file. Supported formats are ``csv`` and ``tsv``. Must be the only goal of a query.',
		argnames is ['Goal', 'Format', 'File']
	]).

	:- public(print_table/2).
	:- mode(print_table(@list(term), @list(atom)), one).
	:- info(print_table/2, [
		comment is 'Prints a table of the values using the variable names to fill the header of the table. Must be the only goal of a query.',
		argnames is ['Values', 'VariableNames']
	]).

	:- public(show_term/1).
	:- mode(show_term(@term), one).
	:- info(show_term/1, [
		comment is 'Displays a term as a graph. Must be the only goal of a query.',
		argnames is ['Term']
	]).

	:- public(show_data/1).
	:- mode(show_data(+callable), one).
	:- info(show_data/1, [
		comment is 'Displays data produced by a goal. Expects a variable named Data or _Data to be bound to a list fo pairs. Must be the only goal of a query.',
		argnames is ['Goal']
	]).

	:- public([
		%halt/0,
		predicate_docs/1,
		%print_sld_tree/1,          % print_sld_tree(+Goal)
		print_transition_graph/4    % print_transition_graph(+PredSpec, +FromIndex, +ToIndex, +LabelIndex)
%		update_completion_data/0
	]).

	:- uses(debugger, [leash/1, trace/0, notrace/0]).
	:- uses(format, [format/2]).
	:- uses(list, [append/3, last/2, member/2]).
	:- uses(term_io, [read_term_from_codes/3]).
	:- uses(user, [atomic_list_concat/2]).
	:- uses(jupyter_logging, [log/1, log/2]).
	:- uses(jupyter_query_handling, [query_data/4]).
	:- uses(jupyter_variable_bindings, [var_bindings/1]).

	version :-
		version(Major, Minor, Patch, Status),
		%log('Version ~w.~w.~w-~w~n',[Major,Minor,Patch,Status]),
		format('Logtalk Jupyter kernel ~w.~w.~w-~w~n', [Major, Minor, Patch, Status]).

	versions :-
		current_logtalk_flag(version_data, logtalk(LogtalkMajor, LogtalkMinor, LogtalkPatch, LogtalkStatus)),
		format('Logtalk ~w.~w.~w-~w~n', [LogtalkMajor, LogtalkMinor, LogtalkPatch, LogtalkStatus]),
		current_logtalk_flag(prolog_dialect, Backend),
		backend(Backend, BackendName),
		current_logtalk_flag(prolog_version, v(BackendMajor, BackendMinor, BackendPatch)),
		format('~w ~w.~w.~w~n', [BackendName, BackendMajor, BackendMinor, BackendPatch]),
		version.

	version(0, 33, 0, beta).

	backend(b,       'B-Prolog').
	backend(ciao,    'Ciao Prolog').
	backend(cx,      'CxProlog').
	backend(eclipse, 'ECLiPSe').
	backend(gnu,     'GNU Prolog').
	backend(ji,      'JIProlog').
	backend(quintus, 'Quintus Prolog').
	backend(sicstus, 'SICStus Prolog').
	backend(swi,     'SWI-Prolog').
	backend(tau,     'Tau Prolog').
	backend(trealla, 'Trealla Prolog').
	backend(xsb,     'XSB').
	backend(xvm,     'XVM').
	backend(yap,     'YAP').

	% Help

	% jupyter::predicate_docs(-PredDocs)
	%
	% PredDocs is a list with elements of the form Pred=Doc, where Pred is a predicate exported by this module and Doc is its documentation as an atom.
	predicate_docs(PredDocs) :-
		findall(Pred=Doc, predicate_doc(Pred, Doc), PredDocs).

	% Prints the documentation for all predicates defined in jupyter object.
	help :-
		predicate_docs(PredDocs),
		log(PredDocs),
		print_pred_docs(PredDocs).

	print_pred_docs([]) :- !.
	print_pred_docs([_Pred=Doc]) :-
		!,
		format('~w', [Doc]).
	print_pred_docs([_Pred=Doc|PredDocs]) :-
		format('~w~n~n--------------------------------------------------------------------------------~n~n', [Doc]),
		print_pred_docs(PredDocs).

	magic :-
		format('Cell magic:~n~n', []),
		format('    %%load FILE.EXT~n', []),
		format('        Saves and loads a file using the logtalk_load/2 predicate~n', []),
		format('    %%save FILE.EXT~n', []),
		format('        Saves a file~n', []),
		format('    %%file FILE.EXT~n', []),
		format('        Saves and loads a file using the logtalk_load/2 predicate~n', []),
		format('    %%file+ FILE.EXT~n', []),
		format('        Appends to a file and loads it using the logtalk_load/2 predicate~n', []),
		format('    %%user~n', []),
		format('        Saves and loads a user.lgt file using the logtalk_load/2 predicate~n', []),
		format('    %%user+~n', []),
		format('        Appends to a user.lgt file and loads it using the logtalk_load/2 predicate~n~n', []),
		format('    %%table~n', []),
		format('        Prints a table with a column per variable binding for all goal solutions~n', []),
		format('    %%csv FILE.csv~n', []),
		format('        Prints a table with a column per variable binding for all goal solutions but also saves it to a CSV file~n', []),
		format('    %%tsv FILE.tsv~n', []),
		format('        Prints a table with a column per variable binding for all goal solutions but also saves it to a TSV file~n', []),
		format('    %%data~n', []),
		format('        Data visualization for a goal binding a variable named Data or _Data with a list of pairs~n', []),
		format('    %%tree~n', []),
		format('        Prints a tree representation of a term~n~n', []),
		format('    %%highlight~n', []),
		format('        Highlights cell contents as Logtalk code~n~n', []),
		format('Line magic:~n~n', []),
		format('    %bindings~n', []),
		format('        Prints variable bindings from previous queries~n', []),
		format('    %queries~n', []),
		format('        Prints previous queries~n~n', []),
		format('    %pwd~n', []),
		format('        Prints the current working directory~n~n', []),
		format('    %help~n', []),
		format('        Prints documentation for all predicates from object jupyter~n', []),
		format('    %versions~n', []),
		format('        Prints Logtalk, Prolog backend, and Jupyter kernel versions~n', []),
		format('    %flags~n', []),
		format('        Prints a table with all Logtalk flags and their values~n~n', []),
		format('    %magic~n', []),
		format('        Prints help in using cell and line magic~n', []).

	predicate_doc('jupyter::halt/0', Doc) :-
		atomic_list_concat([
			'jupyter::halt or halt',
			'\n\n    Shuts down the running Logtalk process.',
			'\n\n    The next time code is to be executed, a new process is started.',
			'\n    Everything defined in the database before does not exist anymore.',
			'\n\n    Corresponds to the functionality of halt/0.',
			'\n    Has the same effect as interrupting or restarting the Jupyter kernel.'
		], Doc).
	predicate_doc('jupyter::help/0', Doc) :-
		atomic_list_concat([
			'jupyter::help',
			'\n\n    Outputs the documentation for all predicates from object jupyter.'
		], Doc).
	predicate_doc('jupyter::versions/0', Doc) :-
		atomic_list_concat([
			'jupyter::versions',
			'\n\n    Prints Logtalk, Prolog backend, and Jupyter kernel versions.'
		], Doc).
	predicate_doc('jupyter::magic/0', Doc) :-
		atomic_list_concat([
			'jupyter::magic',
			'\n\n    Outputs the documentation for all cell and line magic.'
		], Doc).
	predicate_doc('jupyter::print_query_time', Doc) :-
		atomic_list_concat([
			'jupyter::print_query_time',
			'\n\n    Prints the previous query and its runtime in seconds.'
		], Doc).
	predicate_doc('jupyter::print_queries/1', Doc) :-
		atomic_list_concat([
			'jupyter::print_queries(+Ids)',
			'\n\n    Prints previous queries which were executed in requests with IDs in Ids.',
			'\n\n    Any $Var terms might be replaced by the variable\'s name.',
			'\n    This is the case if a previous query with ID in Ids contains Var.',
			'\n    Otherwise, $Var is not replaced.'
		], Doc).
%	predicate_doc('jupyter::print_sld_tree/1', Doc) :-
%		atomic_list_concat([
%			'jupyter::print_sld_tree(+Goal)',
%			'\n\n    Executes the goal Goal and prints a graph resembling its SLD tree.',
%			'\n\n    Must be the only goal of a query.'
%		], Doc).
	predicate_doc('jupyter::print_table/1', Doc) :-
		atomic_list_concat([
			'jupyter::print_table(+Goal)',
			'\n\n    Computes all results of the goal Goal with findall/3.',
			'\n    These are printed in a table.',
			'\n    Values for variable names starting with an underscore are omitted.',
			'\n\n    Must be the only goal of a query.',
			'\n\n    Example: jupyter::print_table(current_logtalk_flag(Name, Value)).'
		], Doc).
	predicate_doc('jupyter::print_and_save_table/3', Doc) :-
		atomic_list_concat([
			'jupyter::print_and_save_table(+Goal, +Format, File)',
			'\n\n    Computes all results of the goal Goal with findall/3.',
			'\n    These are printed in a table but also saved to a file.',
			'\n    Supported file formats are csv and tsv.',
			'\n    Values for variable names starting with an underscore are omitted.',
			'\n\n    Must be the only goal of a query.',
			'\n\n    Example: jupyter::print_and_save_table(current_logtalk_flag(Name, Value), tsv, \'flags.tsv\').'
		], Doc).
	predicate_doc('jupyter::print_table/2', Doc) :-
		atomic_list_concat([
			'jupyter::print_table(+ValuesLists, +VariableNames)',
			'\n\n    Prints a table of the values in ValuesLists.',
			'\n\n    ValuesLists is a list of lists of the same length.',
			'\n    Each list corresponds to one line of the table.',
			'\n\n    VariableNames is used to fill the header of the table.',
			'\n    If VariableNames=[], capital letters are used.',
			'\n    Otherwise, VariableNames needs to be a list of ground terms.',
			'\n    It needs to be of the same length as the values lists.',
			'\n\n    Must be the only goal of a query.',
			'\n\n    Can be used with a predicate like findall/3, but not directly.',
			'\n    Instead, a previous binding can be accessed with a $Var term.',
			'\n\n    Examples:',
			'\n        jupyter::print_table([[10,100],[20,400],[30,900]], [\'X\', \'Y\']).',
			'\n        jupyter::print_table($ResultLists, []).'
		], Doc).
	predicate_doc('jupyter::print_transition_graph/4', Doc) :-
		atomic_list_concat([
			'jupyter::print_transition_graph(+PredSpec, +FromIndex, +ToIndex, +LabelIndex)',
			'\n\n    Finds all solutions of the predicate with specification PredSpec.',
			'\n    Prints a graph interpreting the solutions as transitions.',
			'\n\n    PredSpec needs to be of the form PredName/PredArity.',
			'\n\n    FromIndex and ToIndex point to predicate arguments used as nodes.',
			'\n    LabelIndex points to the argument providing a label for an edge.',
			'\n    If LabelIndex=0, no label is shown.',
			'\n\n    Must be the only goal of a query.'
		], Doc).
	predicate_doc('jupyter::show_term/1', Doc) :-
		atomic_list_concat([
			'jupyter::show_term(+Term)',
			'\n\n    Displays a term as a graph.',
			'\n\n    Must be the only goal of a query.'
		], Doc).
	predicate_doc('jupyter::show_data/1', Doc) :-
		atomic_list_concat([
			'jupyter::show_data(+Goal)',
			'\n\n    Displays data produced by a goal.',
			'\n\n    Expects a variable named Data or _Data to be bound to a list fo pairs.',
			'\n\n    Must be the only goal of a query.'
		], Doc).
   predicate_doc('jupyter::print_variable_bindings/0', Doc) :-
		atomic_list_concat([
			'jupyter::print_variable_bindings',
			'\n\n    Prints variable bindings from previous queries.',
			'\n    For each variable, the latest value it was bound to is shown.',
			'\n\n    The variable value can be accessed with a $Var term by any query.',
			'\n    In that case, the term is replaced by the value.',
			'\n    If there is no previous value, an error message is printed.'
		], Doc).
   predicate_doc('jupyter::pwd/0', Doc) :-
		atomic_list_concat([
			'jupyter::pwd',
			'\n\n    Prints the current working directory.'
		], Doc).
   predicate_doc('jupyter::cd/1', Doc) :-
		atomic_list_concat([
			'jupyter::cd(+Directory)',
			'\n\n    Changes the current working directory.'
		], Doc).
	predicate_doc('jupyter::retry/0', Doc) :-
		atomic_list_concat([
			'jupyter::retry or retry',
			'\n\n    Causes backtracking of the latest active query.',
			'\n\n    Must be the only goal of a query.'
		], Doc).
	predicate_doc('jupyter::set_prolog_backend/1', Doc) :-
		atomic_list_concat([
			'jupyter::set_prolog_backend(+Backend)',
			'\n\n    Activates the given Prolog backend.',
			'\n\n    must be the only goal of a query.'
		], Doc).
	predicate_doc('jupyter::trace/1', Doc) :-
		atomic_list_concat([
			'jupyter::trace(+Goal)',
			'\n\n    Prints the trace of the goal Goal.',
			'\n\n    Logtalk code needs to be compiled in debug mode.',
			'\n    By default, no port is leashed so that no user interaction is requested.',
			'\n    All previously set breakpoints are still active.',
			'\n\n    Must be the only goal of a query in order to work as expected.'
		], Doc).
%	predicate_doc('jupyter::update_completion_data/0', Doc) :-
%		atomic_list_concat([
%			'jupyter::update_completion_data',
%			'\n\n    Updates the predicate data used for code completion using Tab.',
%			'\n\n    This is done by retrieving all built-in and exported predicates.',
%			'\n    Needed to use completion for predicates from a newly loaded code.',
%			'\n\n    Must be the only goal of a query.'
%		], Doc).

	% Trace

	% trace(+Goal)
	%
	% Switch the tracer on, call the goal Goal and stop the tracer.
	% Debug mode is switched on so that any breakpoints which might exist can be activated.
	:- meta_predicate(trace(*)).
	trace(Goal) :-
		leash(none),
		trace,
		(	{Goal} ->
			notrace
		;	notrace
		),
		!.

	pwd :-
		os::working_directory(Directory),
		format('Working directory: ~q~n', [Directory]).

	cd(Directory) :-
		os::change_directory(Directory).

	% Variable bindings

	% print_variable_bindings
	%
	% Print the previous variable bindings which can be reused with a term of the form $Var.
	print_variable_bindings :-
		var_bindings(Bindings),
		(	Bindings == [] ->
			format('No previous variable bindings~n', [])
		;	print_variable_bindings(Bindings)
		).

	print_variable_bindings([]).
	print_variable_bindings([Name=Value| Bindings]) :-
		format('$~w = ~q~n', [Name, Value]),
		print_variable_bindings(Bindings).

	% print_query_time
	%
	% Prints the latest previous query and its runtime in seconds.
	print_query_time :-
		findall(
			Goal-Runtime,
			query_data(_CallRequestId, Runtime, term_data(Goal, _NameVarPairs), _OriginalTermData),
			GoalRuntimes
		),
		last(GoalRuntimes, Goal-Runtime),
		format('Query:   ~w~nRuntime: ~w s~n', [Goal, Runtime]).
	print_query_time :-
		format('* There is no previous query', []),
		fail.

	% print_queries(+Ids)
	%
	% Prints the previous queries with ids in Ids in a way that they can be
	% - copied to a cell and executed right away or
	% - expanded with a head to define a predicate
	% If a query contains a term of the form $Var and a previous query contains the variable Var, $Var is replaced by the variable name.
	print_queries :-
		print_queries(_).

	print_queries(Ids) :-
		(	var(Ids) ->
			findall(Id, query_data(Id, _, _, _),Ids0),
			% cells can contain multiple queries
			sort(Ids0, Ids)
		;	true
		),
		findall(
			TermData-OriginalTermData, 
			(member(Id, Ids), query_data(Id, _Runtime, TermData, OriginalTermData)),
			QueriesData
		),
		print_queries(QueriesData, []).

	% print_queries(+QueriesData, +PreviousNameVarPairs)
	print_queries([], _PreviousNameVarPairs).
	print_queries([QueryData], PreviousNameVarPairs) :-
		!,
		print_previous_query(QueryData, PreviousNameVarPairs, _NewPreviousNameVarPairs, QueryAtom),
		format('~w.~n', [QueryAtom]).
	print_queries([QueryData|QueriesData], PreviousNameVarPairs) :-
		print_previous_query(QueryData, PreviousNameVarPairs, NewPreviousNameVarPairs, QueryAtom),
		format('~w,~n', [QueryAtom]),
		print_queries(QueriesData, NewPreviousNameVarPairs).

	% print_previous_query(+QueryData, +PreviousNameVarPairs, -NewPreviousNameVarPairs, -QueryAtom)
	print_previous_query(term_data(QueryAtom, NameVarPairs)-same, PreviousNameVarPairs, NewPreviousNameVarPairs, QueryAtom) :-
		% There is no $Var term in the query
		append(NameVarPairs, PreviousNameVarPairs, NewPreviousNameVarPairs),
		!.
	print_previous_query(_TermData-OriginalTermData, PreviousNameVarPairs, NewPreviousNameVarPairs, ExpandedTerm) :-
		OriginalTermData = term_data(OriginalTermAtom, OriginalNameVarPairs),
		append(OriginalNameVarPairs, PreviousNameVarPairs, NewPreviousNameVarPairs),
		% Read the original term from the atom
		atom_codes(OriginalTermAtom, OriginalTermCodes),
		append(OriginalTermCodes, [46], OriginalTermCodesWithFullStop),
		read_term_from_codes(OriginalTermCodesWithFullStop, OriginalTerm, [variable_names(OriginalNameVarPairs)]),
		% Expand the term by replacing variables and terms of the form $Var
		expand_term(OriginalTerm, OriginalNameVarPairs, PreviousNameVarPairs, ExpandedTerm).


	% expand_term(+Term, +NameVarPairs, +PreviousNameVarPairs, -ExpandedTerm)
	%
	% NameVarPairs is a list of Name=Var pairs, where Name is the name of a variable Var from the current term.
	% PreviousNameVarPairs contains Name=Var pairs from previous queries.
	% The term Term is expanded to ExpandedTerm in the following way:
	% - If Term is a variable, it is replaced by its Name from NameVarPairs.
	% - If Term is of the form $Var:
	%   - If the name of the variable Var occurred in one of the previous queries (is contained in PreviousNameVarPairs), $Var is replaced by the variable name.
	%   - Otherwise, $Var is replaced by $Name where Name is the name of the variable.
	% - If Term is a compound term, its arguments are expanded.
	expand_term(Var, NameVarPairs, _PreviousNameVarPairs, Name) :-
		var(Var),
		member(Name=Var, NameVarPairs),
		!.
	expand_term(Atomic, _NameVarPairs, _PreviousNameVarPairs, Atomic) :-
		atomic(Atomic),
		!.
	expand_term($(Var), NameVarPairs, PreviousNameVarPairs, ExpandedTerm) :-
		!,
		% Get the name of the variable
		var_name(NameVarPairs, Var, Name),
		(	member(Name=_VarValue, PreviousNameVarPairs) ->
			% The variable occurred in one of the previous queries
			ExpandedTerm = Name
		;	ExpandedTerm = $(Name)
		).
	expand_term(Term, NameVarPairs, PreviousNameVarPairs, ExpandedTerm) :-
		functor(Term, Name, Arity),
		!,
		functor(ExpandedTerm, Name, Arity),
		expand_args(1, NameVarPairs, PreviousNameVarPairs, Term, ExpandedTerm).

	% expand_args(+ArgNum, +NameVarPairs, +PreviousNameVarPairs, +Term, +ExpandedTerm)
	expand_args(ArgNum, NameVarPairs, PreviousNameVarPairs, Term, ExpandedTerm) :-
		arg(ArgNum, Term, Arg),
		arg(ArgNum, ExpandedTerm, ExpandedArg),
		!,
		NextArgNum is ArgNum + 1,
		expand_term(Arg, NameVarPairs, PreviousNameVarPairs, ExpandedArg),
		expand_args(NextArgNum, NameVarPairs, PreviousNameVarPairs, Term, ExpandedTerm).
	expand_args(_ArgNum, _NameVarPairs, _PreviousNameVarPairs, _Term, _ExpandedTerm).

	% var_name(+NameVarPairs, +Var, -Name)
	%
	% NameVarPairs is a list of Name=Var pairs, where Name is the name of a variable Var.
	var_name([Name=SameVar|_NameVarPairs], Var, Name) :-
		Var == SameVar,
		!.
	var_name([_NameVarPair|NameVarPairs], Var, Name) :-
		var_name(NameVarPairs, Var, Name).

:- end_object.
