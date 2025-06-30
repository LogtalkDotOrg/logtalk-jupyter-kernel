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


% There are three main types of terms.
% For each of the types there are terms which need to be handled specially.
% The following types of terms are differentiated:
% - directives:
%   - any other directive
% - clause definitions:
%   - Head :- Body
%   - Head --> Body
%   - Head (if the request contains more than one term)
% - queries:
%   - retry or jupyter::retry
%   - halt or jupyter::halt
%   - a call of a special jupyter predicate:
%     - jupyter::print_table/1 or jupyter:print_table/2
%     - jupyter::print_sld_tree/1
%     - jupyter::print_transition_graph/1,3,4
%     - jupyter::show_graph/2  % alternative name for print_transition_graph with Node and Edge predicate
%     - jupyter::set_prolog_backend/1
%     - jupyter::update_completion_data/0
%   - a call of trace: trace/0, trace/1 or trace/2
%   - a call of leash/1
%   - any other term which is the only one of a request


:- object(jupyter_term_handling).

	:- info([
		version is 0:10:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2025-06-27,
		comment is 'This object provides predicates to handle terms received from the client, compute their results and assert them with term_response/1.'
	]).

	%:- public(assert_sld_data/4).
	% assert_sld_data(Port, Goal, Frame, ParentFrame)

	:- public(handle_term/5).
	:- mode(handle_term(+callable, +integer, +list(atom), +list, -term), one).
	:- info(handle_term/5, [
		comment is '.',
		argnames is ['Term', 'CallRequestId', 'Stack', 'Bindings', 'Cont']
	]).

	:- public(term_response/1).
	:- dynamic(term_response/1).
	:- mode(term_response(+json), zero_or_more).
	:- info(term_response/1, [
		comment is 'JSON term response table.',
		argnames is ['JsonResponse']
	]).

	:- public(assert_success_response/4).
	:- mode(assert_success_response(+atom, +list(pair), +atom, +list(pair)), one).
	:- info(assert_success_response/4, [
		comment is 'Asserts a success response.',
		argnames is ['Type', 'Bindings', 'Output', 'AdditionalData']
	]).
	
	:- public(assert_error_response/4).
	:- mode(assert_error_response(+atom, +compound, +atom, +list(pair)), one).
	:- info(assert_error_response/4, [
		comment is 'Asserts an error response.',
		argnames is ['ErrorCode', 'ErrorMessageData', 'Output', 'AdditionalData']
	]).

	:- public(findall_results_and_var_names/4).
	:- meta_predicate(findall_results_and_var_names(*, *, *, *)).
	:- mode(findall_results_and_var_names(+callable, +list, -list, -list(atom)), one).
	:- info(findall_results_and_var_names/4, [
		comment is 'Finds all solutions to a goal returning the binding values and the variable names.',
		argnames is ['Goal', 'Bindings', 'Results', 'VarNames']
	]).

	:- public(get_data/3).
	:- meta_predicate(get_data(*, *, *)).
	:- mode(get_data(+callable, +list, -term), one).
	:- info(get_data/3, [
		comment is 'Proves a goal and returns the binding for the ``Data`` or ``_Data`` variable.',
		argnames is ['Goal', 'Bindings', 'Data']
	]).

	:- public(dot_subnode/3).

	:- public(dot_subtree/3).

%	:- meta_predicate(call_with_sld_failure_handling(*, *)).

	:- uses(debugger, [debug/0, trace/0, notrace/0]).
	:- uses(term_io, [write_term_to_atom/3, write_term_to_codes/3, format_to_codes/3, read_term_from_codes/3]).
	:- uses(list, [append/2, append/3, delete/3, length/2,  member/2, nth1/3]).
	:- uses(logtalk, [print_message(debug, jupyter, Message) as dbg(Message)]).
	:- uses(meta, [map/3 as maplist/3]).
	:- uses(user, [atomic_list_concat/2]).

	:- uses(jupyter_logging, [log/1, log/2]).
	:- uses(jupyter_query_handling, [call_with_output_to_file/3, call_query_with_output_to_file/7, redirect_output_to_file/0]).
	:- uses(jupyter_jsonrpc, [json_error_term/5]).
	:- uses(jupyter_request_handling, [loop/3]).
	:- uses(jupyter_preferences, [set_preference/3, get_preference/2]).
	:- uses(jupyter_variable_bindings, [term_with_stored_var_bindings/4, store_var_bindings/1]).

	:- private(is_retry/1).
	:- dynamic(is_retry/1).
	:- mode(is_retry(-boolean), one).
	:- info(is_retry/1, [
		comment is 'True iff we are backtracking into a query.',
		argnames is ['IsRetry']
	]).

	% handle_term(+Term, +CallRequestId, +Stack, +Bindings, -Cont)
	%
	% Bindings is a list of Name=Var pairs, where Name is the name of a variable Var occurring in the term Term.
	% Check which type of term Term is and handle it accordingly.
	% Queries
	handle_term(Query, CallRequestId, Stack, Bindings, Cont) :-
		handle_query_term(Query, CallRequestId, Stack, Bindings, continue, Cont).

	format_to_atom(_, _, Atom) :-
		get_preference(verbosity, Level),
		Level < 2,
		!,
		Atom = ''.
	format_to_atom(Msg, Args, Atom) :-
		format_to_codes(Msg, Args, Codes),
		atom_codes(Atom, Codes).


	% Queries

	% In case of any other query not handled by any of the predicates defined above, the query is called by jupyter_query_handling::call_query_with_output_to_file/7.
	% Before calling it, any $Var terms are replaced by corresponding values from previous queries.
	% Additionally, the output of the goal and debugging messages are redirected to a file so that it can be read in and sent to the client.

	% jupyter_query_handling:call_query_with_output_to_file/7 leaves a choice point.
	% This way, when a 'retry' term is encountered in a future request, its failing causes the goal to be retried.

	% handle_query_term(+Term, +CallRequestId, +Stack, +Bindings, +LoopCont, -Cont)
	handle_query_term(Term, CallRequestId, Stack, Bindings, LoopCont, Cont) :-
		% Before executing a query, replace any of its subterms of the form $Var by the latest value of the variable Var from a previous query.
		replace_previous_variable_bindings(Term, Bindings, UpdatedTerm, UpdatedBindings, Exception),
		(	nonvar(Exception) ->
			assert_error_response(exception, message_data(error, Exception), '', []),
			Cont = continue
		;	% Create a term_data(TermAtom, Bindings) term.
			% If the term is a query, the term_data term is used to assert the original term data in case terms of the form $Var were replaced.
			% The term data is needed when accessing previous queries (e.g. with jupyter::print_queries/1).
			% Bindings needs to be copied so that the term can be read from the atom without any of the variables being instantiated by calling the term.
			copy_term(Bindings, BindingsCopy),
			write_term_to_atom(Term, TermAtom, [variable_names(Bindings), quoted(true)]),
			handle_query_term_(UpdatedTerm, CallRequestId, Stack, UpdatedBindings, term_data(TermAtom, BindingsCopy), LoopCont, Cont)
		).


	% replace_previous_variable_bindings(+Term, +Bindings, -UpdatedTerm, -UpdatedBindings, -Exception)
	replace_previous_variable_bindings(Term, Bindings, UpdatedTerm, UpdatedBindings, Exception) :-
		catch(term_with_stored_var_bindings(Term, Bindings, UpdatedTerm, UpdatedBindings), Exception, true).

	is_query_alias(retry, jupyter::retry).
	is_query_alias(halt, jupyter::halt).
	:- if(os::operating_system_type(windows)).
		is_query_alias(eclipse, jupyter::set_prolog_backend('eclipselgt.ps1')) :-
			\+ user::current_predicate(eclipse/0).
		is_query_alias(gnu, jupyter::set_prolog_backend('gplgt.ps1')) :-
			\+ user::current_predicate(gnu/0).
		is_query_alias(sicstus, jupyter::set_prolog_backend('sicstuslgt.ps1')) :-
			\+ user::current_predicate(sicstus/0).
		is_query_alias(swi, jupyter::set_prolog_backend('swilgt.ps1')) :-
			\+ user::current_predicate(swi/0).
		is_query_alias(trealla, jupyter::set_prolog_backend('tplgt.ps1')) :-
			\+ user::current_predicate(trealla/0).
		is_query_alias(xvm, jupyter::set_prolog_backend('xvmlgt.ps1')) :-
			\+ user::current_predicate(xvm/0).
		is_query_alias(yap, jupyter::set_prolog_backend('yaplgt.ps1')) :-
			\+ user::current_predicate(yap/0).
	:- elif((
		os::environment_variable('LOGTALKHOME', LOGTALKHOME),
		os::environment_variable('LOGTALKUSER', LOGTALKUSER),
		LOGTALKHOME == LOGTALKUSER
	)).
		is_query_alias(eclipse, jupyter::set_prolog_backend('eclipselgt.sh')) :-
			\+ user::current_predicate(eclipse/0).
		is_query_alias(gnu, jupyter::set_prolog_backend('gplgt.sh')) :-
			\+ user::current_predicate(gnu/0).
		is_query_alias(sicstus, jupyter::set_prolog_backend('sicstuslgt.sh')) :-
			\+ user::current_predicate(sicstus/0).
		is_query_alias(swi, jupyter::set_prolog_backend('swilgt.sh')) :-
			\+ user::current_predicate(swi/0).
		is_query_alias(trealla, jupyter::set_prolog_backend('tplgt.sh')) :-
			\+ user::current_predicate(trealla/0).
		is_query_alias(xvm, jupyter::set_prolog_backend('xvmlgt.sh')) :-
			\+ user::current_predicate(xvm/0).
		is_query_alias(yap, jupyter::set_prolog_backend('yaplgt.sh')) :-
			\+ user::current_predicate(yap/0).
	:- else.
		is_query_alias(eclipse, jupyter::set_prolog_backend(eclipselgt)) :-
			\+ user::current_predicate(eclipse/0).
		is_query_alias(gnu, jupyter::set_prolog_backend(gplgt)) :-
			\+ user::current_predicate(gnu/0).
		is_query_alias(sicstus, jupyter::set_prolog_backend(sicstuslgt)) :-
			\+ user::current_predicate(sicstus/0).
		is_query_alias(swi, jupyter::set_prolog_backend(swilgt)) :-
			\+ user::current_predicate(swi/0).
		is_query_alias(trealla, jupyter::set_prolog_backend(tplgt)) :-
			\+ user::current_predicate(trealla/0).
		is_query_alias(xvm, jupyter::set_prolog_backend(xvmlgt)) :-
			\+ user::current_predicate(xvm/0).
		is_query_alias(yap, jupyter::set_prolog_backend(yaplgt)) :-
			\+ user::current_predicate(yap/0).
	:- endif.
	is_query_alias(show_graph(Nodes,Edges), jupyter::show_graph(Nodes,Edges)) :-
		\+ user::current_predicate(show_graph/2).
	is_query_alias(show_term(Term), jupyter::show_graph(jupyter_term_handling::dot_subnode(_,_,Term),jupyter_term_handling::dot_subtree/3)) :-
		\+ user::current_predicate(show_term/1).
	is_query_alias(show_data(Goal), jupyter::show_data(Goal)) :-
		\+ user::current_predicate(show_data/1).
	is_query_alias(print_table(Goal), jupyter::print_table(Goal)) :-
		\+ user::current_predicate(print_table/1).
	is_query_alias(print_and_save_table(Goal,Format,File), jupyter::print_and_save_table(Goal,Format,File)) :-
		\+ user::current_predicate(print_and_save_table/3).
	is_query_alias(print_queries, jupyter::print_queries) :-
		\+ user::current_predicate(print_queries/0).
	is_query_alias(print_queries(L), jupyter::print_queries(L)) :-
		\+ user::current_predicate(print_queries/1).
%	is_query_alias(show_sld_tree(L), jupyter::print_sld_tree(L)) :-
%		\+ user::current_predicate(show_sld_tree/1).

	% handle_query_term_(+Query, +CallRequestId, +Stack, +Bindings, +OriginalTermData, +LoopCont, -Cont)
	handle_query_term_(Call, CallRequestId, Stack, Bindings, OriginalTermData, LoopCont, Cont) :-
		% log('Call: ~w~n',[Call]),
		is_query_alias(Call,Alias),
		!,
		handle_query_term_(Alias, CallRequestId, Stack, Bindings, OriginalTermData, LoopCont, Cont).
	% retry
	handle_query_term_(jupyter::retry, _CallRequestId, Stack, _Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_retry(Stack).
	% halt
	handle_query_term_(jupyter::halt, _CallRequestId, _Stack, _Bindings, _OriginalTermData, _LoopCont, done) :- !,
		% By unifying Cont=done, the loop reading and handling messages is stopped
		handle_halt.
	% jupyter predicates
%	handle_query_term_(jupyter::print_sld_tree(Goal), _CallRequestId, _Stack, Bindings, _OriginalTermData, _LoopCont, continue) :- !,
%		handle_print_sld_tree(Goal, Bindings).
	handle_query_term_(jupyter::show_data(Goal), _CallRequestId, _Stack, Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_show_data(Bindings, Goal).
	handle_query_term_(jupyter::print_table(Goal), _CallRequestId, _Stack, Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_print_table_with_findall(Bindings, Goal).
	handle_query_term_(jupyter::print_and_save_table(Goal,Format,File), _CallRequestId, _Stack, Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_print_and_save_table_with_findall(Bindings, Goal, Format, File).
	handle_query_term_(jupyter::print_table(ValuesLists, VariableNames), _CallRequestId, _Stack, Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_print_table(Bindings, ValuesLists, VariableNames).
	handle_query_term_(jupyter::print_transition_graph(PredSpec, FromIndex, ToIndex, LabelIndex), _CallRequestId, _Stack, _Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_print_transition_graph(true,PredSpec, FromIndex, ToIndex, LabelIndex).
	handle_query_term_(jupyter::print_transition_graph(PredSpec, FromIndex, ToIndex), _CallRequestId, _Stack, _Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_print_transition_graph(true,PredSpec, FromIndex, ToIndex, 0).
	handle_query_term_(jupyter::show_graph(NodeSpec,PredSpec), _CallRequestId, _Stack, _Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_print_transition_graph(NodeSpec,PredSpec).
	handle_query_term_(jupyter::set_prolog_backend(Backend), _CallRequestId, _Stack, _Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_set_prolog_backend(Backend).
	handle_query_term_(jupyter::update_completion_data, _CallRequestId, _Stack, _Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_update_completion_data.
	handle_query_term_(jupyter::set_preference(Pref,Value), _CallRequestId, _Stack, _Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_set_preference(Pref,Value).
	% trace
	handle_query_term_(trace, _CallRequestId, _Stack, _Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		handle_trace(trace/0).
	% leash/1
	handle_query_term_(debugger::leash(_Ports), _CallRequestId, _Stack, _Bindings, _OriginalTermData, _LoopCont, continue) :- !,
		assert_error_response(exception, message_data(error, jupyter(leash_pred)), '', []).
	% Any other query
	handle_query_term_(Query, CallRequestId, Stack, Bindings, OriginalTermData, LoopCont, Cont) :-
		handle_query(Query, CallRequestId, Stack, Bindings, OriginalTermData, LoopCont, Cont).

	% handle_query(+Goal, +CallRequestId, +Stack, +Bindings, +OriginalTermData, +LoopCont, -Cont)
	%
	% Goal is the current term of the request which is to be handled.
	%  In that case, no variable bindings are sent to the client.
	% CallRequestId is the ID of the current call request.
	%  It is needed for juypter:print_queries/1.
	% Stack is a list containing atoms representing the previous queries which might have exited with a choicepoint and can therefore be retried.
	%  It is needed for retry/0 queries.
	% Bindings is a list of Name=Var pairs, where Name is the name of a variable Var occurring in the goal Goal.
	% LoopCont is one of continue and cut.
	%  If LoopCont = cut, the recurse loop (jupyter_request_handling::loop/3) will exit right away without making retries of a term possible.
	% Cont will be processed by jupyter_request_handling::loop/3.
	handle_query(Goal, CallRequestId, Stack, Bindings, OriginalTermData, LoopCont, Cont) :-
		% In order to send the goal to the client, it has to be converted to an atom
		% This has to be done before calling it causes variables to be bound
		write_term_to_atom(Goal, GoalAtom, [variable_names(Bindings)]),
		RecStack = [GoalAtom|Stack],
		retractall(is_retry(_)),
		asserta(is_retry(false)),
		% Call the goal Goal
		call_query_with_output_to_file(Goal, CallRequestId, Bindings, OriginalTermData, Output, ErrorMessageData, IsFailure),
		retry_message_and_output(GoalAtom, Output, RetryMessageAndOutput),
		% Exception, failure or success from Goal
		(	nonvar(ErrorMessageData) -> % Exception
			!,
			assert_error_response(exception, ErrorMessageData, RetryMessageAndOutput, []),
			Cont = continue
		;	IsFailure == true -> % Failure
			!,
			% Also happens when 'retry' message requested a new solution and found none.
			assert_error_response(failure, null, RetryMessageAndOutput, []),
			Cont = continue
		;	% Success
			handle_result_variable_bindings(Bindings, ResultBindings),
			assert_success_response(query, ResultBindings, RetryMessageAndOutput, []),
			% Start a new recursive loop so that the current goal can be retried
			% The loop will
			% - exit right away if LoopCont=cut
			% - fail if it receives a request to retry Goal
			loop(LoopCont, RecStack, RecCont),
			(	RecCont = cut,
				!,
				Cont = continue
			;	% Possibly 'done'
				Cont = RecCont
			)
		),
		!.

	% output_and_failure_message(+Output, +FailureMessage, -OutputAndFailureMessage)
	output_and_failure_message('', FailureMessage, FailureMessage) :- !.
	output_and_failure_message(Output, FailureMessage, OutputAndFailureMessage) :-
		atom_concat('\n', FailureMessage, FailureMessageWithNl),
		atom_concat(Output, FailureMessageWithNl, OutputAndFailureMessage).


	update_variable_bindings(BindingsWithoutSingletons) :-
		store_var_bindings(BindingsWithoutSingletons).


	% retry_message_and_output(+GoalAtom, +Output, -RetryMessageAndOutput)
	%
	% If the current term was 'retry', a retry message is prepended to the output of the goal.
	retry_message_and_output(GoalAtom, Output, RetryMessageAndOutput) :-
		% The Id can be from the initial 'call' request or from a subsequent 'retry' request.
		retract(is_retry(IsRetry)),
		retry_message(IsRetry, GoalAtom, RetryMessage),
		atom_concat(RetryMessage, Output, RetryMessageAndOutput).


	% retry_message(+IsRetry, +GoalAtom, -RetryMessage)
	%
	% If the current term was a 'retry' term (IsRetry=true), a retry message is sent to the client.
	% This message contains the goal which was retried.
	retry_message(true, GoalAtom, RetryMessage) :-
		!,
		format_to_atom('% Retrying goal: ~w~n', [GoalAtom], RetryMessage).
	retry_message(_IsRetry, _GoalAtom, '').


	% handle_result_variable_bindings(+Bindings, -ResultBindings)
	handle_result_variable_bindings(Bindings, ResultBindings) :-
		% Update the stored variable bindings
		remove_singleton_variables(Bindings, BindingsWithoutSingletons),
		update_variable_bindings(BindingsWithoutSingletons),
		% Convert the variable values to json parsable terms
		json_parsable_vars(BindingsWithoutSingletons, Bindings, ResultBindings).


	% remove_singleton_variables(+Bindings, -BindingsWithoutSingletons)
	%
	% Bindings is a list of Name=Var pairs, where Name is the name of a variable Var occurring in the term currently being handled.
	% BindingsWithoutSingletons contains the elements of Bindings except for (named) singleton variables starting with '_'
	remove_singleton_variables([], []) :- !.
	remove_singleton_variables([Name=_Var|Bindings], BindingsWithoutSingletons) :-
		% Name starts with '_'
		sub_atom(Name, 0, 1, _After, '_'),
		!,
		remove_singleton_variables(Bindings, BindingsWithoutSingletons).
	remove_singleton_variables([Binding|Bindings], [Binding|BindingsWithoutSingletons]) :-
		remove_singleton_variables(Bindings, BindingsWithoutSingletons).

	% json_parsable_vars(+NonParsableVars, +Bindings, -JsonParsableVars)
	%
	% NonParsableVars and Bindings are lists of Name=Var pairs, where Name is the name of a variable Var occurring in the term currently being handled.
	% As not all of the values can be parsed to JSON (e.g. uninstantiated variables and compounds), they need to be made JSON parsable first.
	% Bindings is needed in case any variable term needs to be converted to an atom and contains other variables.
	% By using Bindings, the names of the variables can be preserved.
	% In case of domain variables with bounded domains (lower and upper bound exist) which are not bound to a single value,
	%  the value returned to the client is a list of lists where each of those lists contains a lower and upper bound of a range the variable can be in.
	json_parsable_vars([], _Variables, []) :- !.
	json_parsable_vars([VarName=Var|RemainingBindings], Bindings, JsonParsableBindings) :-
		var(Var),
		same_var(RemainingBindings, Var),
		!,
		% The list of Name=Var pairs contains at least one element OtherName=Var where Var is uninstantiated
		% Unify the variable Var with VarName
		Var=VarName,
		json_parsable_vars(RemainingBindings, Bindings, JsonParsableBindings).
	json_parsable_vars([_VarName=Var|RemainingBindings], Bindings, JsonParsableBindings) :-
		var(Var),
		!,
		% The variable is uninstantiated and therefore not included in the result list
		json_parsable_vars(RemainingBindings, Bindings, JsonParsableBindings).
	json_parsable_vars([VarName=Var|RemainingBindings], Bindings, [VarName-VarAtom|JsonParsableBindings]) :-
		% Convert the value to an atom as it may be compound and cannot be parsed to JSON otherwise
		write_term_to_atom(Var, VarAtom, [variable_names(Bindings), quoted(true)]),
		json_parsable_vars(RemainingBindings, Bindings, JsonParsableBindings).

	% same_var(+BindingsWithoutSingletons, +Var)
	%
	% BindingsWithoutSingletons is a list of Name=Var pairs, where Name is the name of a variable Var occurring in the term currently being handled.
	% Fails if BindingsWithoutSingletons does not contain any element VarName=Var1 where Var1 and Var are identical (==).
	same_var([], _Var) :- fail.
	same_var([_VarName=Var1|_BindingsWithoutSingletons], Var2) :-
		Var1 == Var2, !.
	same_var([_Binding|BindingsWithoutSingletons], Var) :-
		same_var(BindingsWithoutSingletons, Var).

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Handling the different types of queries

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Retry

	% If there is no active goal, an error message is sent to the client.
	% Otherwise, in order to retry an active previous goal, fails into the caller (jupyter_query_handling:call_query_with_output_to_file/7).
	% The goal which is retried is output.

	% handle_retry(+CallRequestId, +Stack)
	handle_retry(Stack) :-
		(	Stack = [_ActiveGoal|_RemainingStack] ->
			% Tell caller that the current query is a retry
			asserta(is_retry(true)),
			% Redirect all output to a file
			redirect_output_to_file,
			fail
		;	% No active call
			assert_error_response(no_active_call, null, '', [])
		).


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Halt

	% If the server is to be halted, the loop reading and handling messages is stopped so that the server process is stopped.
	% The type of the success reply sent to the client indicates that the server was halted and needs to be restarted for the next execution request.

	handle_halt :-
		assertz(term_response(json([status-halt]))).

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	handle_show_data(Bindings, Goal) :-
		call_with_output_to_file(jupyter_term_handling::get_data(Goal, Bindings, Data), Output, ErrorMessageData),
		!,
		% Success or exception from findall_results_and_var_names/4
		(	nonvar(ErrorMessageData) ->
			assert_error_response(exception, ErrorMessageData, '', [])
		;	ground(Data),
			handle_result_variable_bindings(Bindings, ResultBindings),
			convert_data_to_json(Data, JSON) ->
			% success
			assert_success_response(query, ResultBindings, Output, [show_data-JSON])
		;	% invalid data format
			assert_error_response(exception, 'Invalid Data format', '', [])
		).

	handle_show_data(_Bindings, _Goal) :-
		% findall_results_and_var_names/4 failed
		assert_error_response(failure, null, '', []).

	convert_data_to_json(Pairs0, json(Pairs)) :-
		convert_data_pairs_to_json(Pairs0, Pairs).

	convert_data_pairs_to_json([], []).
	convert_data_pairs_to_json([Key-Value0| Pairs0], [Key-Value| Pairs]) :-
		(	Value0 = [_-_| _] ->
			convert_data_pairs_to_json(Value0, Value1),
			Value = json(Value1)
		;	Value = Value0
		),
		convert_data_pairs_to_json(Pairs0, Pairs).

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	% Print result table
	
	% The client requested a response which can be used to print a table.
	% The client expects the result to contain a member 'print_table' of which the value is a dictionary with the following members:
	% - ValuesLists: a list of lists where each list corresponds to one line of the table
	% - VariableNames: a list of names used as the header for the table; one of
	%   - []: if no names are provided, the header will contain capital letters as names
	%   - a list of ground terms of the same length as the values lists


	% handle_print_table_with_findall(+Bindings, +Goal)
	%
	% The values need to be computed with findall/3 for the goal Goal.
	% The header of the table will contain the names of the variables occurring in Goal.
	% Bindings is a list of Name=Var pairs, where Name is the name of a variable Var occurring in the goal Goal.
	handle_print_table_with_findall(Bindings, Goal) :-
		call_with_output_to_file(jupyter_term_handling::findall_results_and_var_names(Goal, Bindings, Results0, VarNames0), Output, ErrorMessageData),
		!,
		% Success or exception from findall_results_and_var_names/4
		(	nonvar(ErrorMessageData) ->
			assert_error_response(exception, ErrorMessageData, '', [])
		;	% success
			% Return the additional 'print_table' data
			filter_ignored_variable_results(Results0, VarNames0, Results),
			filter_ignored_variable_names(VarNames0, VarNames),
			assert_success_response(query, [], Output, [print_table-json(['ValuesLists'-Results, 'VariableNames'-VarNames])])
		).
	handle_print_table_with_findall(_Bindings, _Goal) :-
		% findall_results_and_var_names/4 failed
		assert_error_response(failure, null, '', []).

	handle_print_and_save_table_with_findall(Bindings, Goal, Format, File) :-
		call_with_output_to_file(jupyter_term_handling::findall_results_and_var_names(Goal, Bindings, Results0, VarNames0), Output, ErrorMessageData),
		!,
		% Success or exception from findall_results_and_var_names/4
		(	nonvar(ErrorMessageData) ->
			assert_error_response(exception, ErrorMessageData, '', [])
		;	% success
			% Return the additional 'print_and_save_table' data
			filter_ignored_variable_results(Results0, VarNames0, Results),
			filter_ignored_variable_names(VarNames0, VarNames),
			assert_success_response(query, [], Output, [print_and_save_table-json(['ValuesLists'-Results, 'VariableNames'-VarNames, 'Format'-Format, 'File'-File])])
		).
	handle_print_and_save_table_with_findall(_Bindings, _Goal, _Format, _File) :-
		% findall_results_and_var_names/4 failed
		assert_error_response(failure, null, '', []).
		
	filter_ignored_variable_results([], _, []).
	filter_ignored_variable_results([Result0| Results0], VarNames0, [Result| Results]) :-
		filter_ignored_variables(VarNames0, Result0, Result),
		filter_ignored_variable_results(Results0, VarNames0, Results).

	filter_ignored_variables([], [], []).
	filter_ignored_variables([VarName0| VarNames0], [_| Results0], Results) :-
		sub_atom(VarName0, 0, 1, _, '_'),
		!,
		filter_ignored_variables(VarNames0, Results0, Results).
	filter_ignored_variables([_| VarNames0], [Result0| Results0], [Result0| Results]) :-
		filter_ignored_variables(VarNames0, Results0, Results).

	filter_ignored_variable_names([], []).
	filter_ignored_variable_names([VarName0| VarNames0], VarNames) :-
		sub_atom(VarName0, 0, 1, _, '_'),
		!,
		filter_ignored_variable_names(VarNames0, VarNames).
	filter_ignored_variable_names([VarName0| VarNames0], [VarName0| VarNames]) :-
		filter_ignored_variable_names(VarNames0, VarNames).

	% handle_print_table(+Bindings, +ValuesLists, +VariableNames)
	%
	% Bindings is a list of Name=Var pairs, where Name is the name of a variable Var occurring in the goal Goal.
	% ValuesLists is expected to be a list of lists of the same lengths.
	% It contains the data which is to be printed in the table.
	% VariableNames is [] or a list of ground terms which need to be of the same length as the values lists.
	handle_print_table(_Bindings, [], VariableNames) :-
		!,
		assert_success_response(query, [], '', [print_table-json(['ValuesLists'-[], 'VariableNames'-VariableNames])]).
	handle_print_table(Bindings, ValuesLists, VariableNames) :-
		% Get the length of the first list and make sure that all other lists have the same length
		ValuesLists = [ValuesList| RemainingValuesLists],
		length(ValuesList, Length),
		(	forall(member(List, RemainingValuesLists), length(List, Length)) ->
			% Make sure that VariableNames is valid
			(	table_variable_names(VariableNames, Length, TableVariableNames) ->
				% As not all of the values can be parsed to JSON (e.g. uninstantiated variables and compounds), they need to be made JSON parsable first by converting them to atoms
				findall(ValuesAtomList, (member(Values, ValuesLists), convert_to_atom_list(Values, Bindings, ValuesAtomList)), JsonParsableValuesLists),
				% Return the additional 'print_table' data
				assert_success_response(query, [], '', [print_table-json(['ValuesLists'-JsonParsableValuesLists, 'VariableNames'-TableVariableNames])])
			;	% The variable names are invalid
				assert_error_response(exception, message_data(error, jupyter(invalid_table_variable_names)), '', [])
			)
		;	% Not all lists in ValuesLists are of the same length
			assert_error_response(exception, message_data(error, jupyter(invalid_table_values_lists_length)), '', [])
		).


	% table_variable_names(+VariableNames, +Length, -TableVariableNames)
	table_variable_names([], Length, TableVariableNames) :-
		% If no variable names are provided, capital letters are used instead
		Letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
		% TableVariableNames is a list containing the first Length letters
		length(TableVariableNames, Length),
		append(TableVariableNames, _, Letters).
	table_variable_names(VariableNames, Length, VariableNames) :-
		% Check that the number of variable names is correct and that all of them are ground
		length(VariableNames, Length),
		forall(member(VariableName, VariableNames), ground(VariableName)),
		!.

	% convert_to_atom_list(+List, +Bindings, -AtomList)
	%
	% AtomList contains the elements of List after converting them to atoms.
	convert_to_atom_list(List, Bindings, AtomList) :-
		findall(
			ElementAtom,
			(	member(Element, List),
				write_term_to_atom(Element, ElementAtom, [variable_names(Bindings), quoted(true)])
			),
			AtomList
		).

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	% trace
	
	% trace/0, trace/1 and trace/2 cannot be used with this server, because the debugging messages are not printed in a way that they can be read in and sent to the client.
	% Instead, jupyter::trace(Goal) can be used to print the trace of the goal Goal.
	
	% handle_trace(+TracePredSpec)
	handle_trace(TracePredSpec) :-
		assert_error_response(exception, message_data(error, jupyter(trace_pred(TracePredSpec))), '', []).
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	% Print data
	
	get_data(Goal, Bindings, Data) :-
		once((
			member('Data'=Data, Bindings)
		;	member('_Data'=Data, Bindings)
		)),
		{Goal}.

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	% Print tables
	
	% findall_results_and_var_names(+Goal, +Bindings, -Results, -VarNames)
	%
	% Bindings is a list of Name=Var pairs, where Name is the name of a variable Var occurring in the goal Goal.
	% Uses findall to find all results (ResultsLists) of the goal Goal.
	% ResultsLists contains lists containing values for each variable in Bindings.
	% VarNames is the list of variable names from Bindings.
	findall_results_and_var_names(Goal, Bindings, JsonParsableResultsLists, VarNames) :-
		var_names_and_values(Bindings, VarNames, Vars),
		% avoid a linter warning and ensure Goal is called in "user"
		{findall(Vars, Goal, ResultsLists)},
		json_parsable_results_lists(ResultsLists, VarNames, Bindings, JsonParsableResultsLists).
	
	
	% var_names_and_values(+Bindings, -VarNames, -Vars)
	var_names_and_values([], [], []).
	var_names_and_values([VarName=Var|Bindings], [VarName|VarNames], [Var|Vars]) :-
		var_names_and_values(Bindings, VarNames, Vars).
	
	
	% json_parsable_results_lists(+ResultsLists, +VarNames, +Bindings, -JsonParsableResultsLists)
	%
	% ResultsLists is a list containing lists of values of the variables with names in VarNames.
	% As not all of the terms in ResultsLists can be parsed to JSON (e.g. uninstantiated variables and compounds), they need to be made JSON parsable first.
	% Bindings is a list of Name=Var pairs, where Name is the name of a variable Var occurring in the goal which was called to get the results.
	% Bindings is needed to preserve the variable names when converting a result to an atom.
	json_parsable_results_lists([], _VarNames, _Bindings, []).
	json_parsable_results_lists([Results|ResultsLists], VarNames, Bindings, [JsonParsableResults|JsonParsableResultsLists]) :-
		json_parsable_results(Results, VarNames, VarNames, Bindings, JsonParsableResults),
		json_parsable_results_lists(ResultsLists, VarNames, Bindings, JsonParsableResultsLists).
	
	
	% json_parsable_results(+Results, +VarNames, +Bindings, -JsonParsableResult)
	json_parsable_results([], _VarNames, _AllVarNames, _Bindings, []).
	json_parsable_results([Result|Results], [VarName|VarNames], AllVarNames, Bindings, [Result|JsonParsableResults]) :-
		% If the result is a variable, unify it with its name
		var(Result),
		!,
		Result = VarName,
		json_parsable_results(Results, VarNames, AllVarNames, Bindings, JsonParsableResults).
	json_parsable_results([Result|Results], [_VarName|VarNames], AllVarNames, Bindings, [ResultAtom|JsonParsableResults]) :-
		% Convert the value to an atom as it may be compound and cannot be parsed to JSON otherwise
		(	member(Result, AllVarNames) ->
			% 
			ResultAtom = Result
		;	write_term_to_atom(Result, ResultAtom, [variable_names(Bindings), quoted(true)])
		),
		json_parsable_results(Results, VarNames, AllVarNames, Bindings, JsonParsableResults).

/*
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Print SLD Trees

% Create content for a file representing a graph resembling the SLD tree of an execution that can be rendered with DOT.
% The collection of the data uses Logtalk trace events. SLD data is collected when a clause collect_sld_data/0 exists.

% So far, data is collected for call ports only and no leaves are shown marking a successful or failing branch.
% In order to add such leaves, data needs to be collected for other ports as well.
% Then, to add a failure/success leaf, the first fail/exit port for a call needs to be determined.

% The graph file content is created like the following.
% Nodes are defined by their ID and labelled with the goal.
% Directed edges are added from a parent invocation to the child invocation.
% This may look like the following:
%   digraph {
%       "4" [label="app([1,2],[3],A)"]
%       "5" [label="app([2],[3],B)"]
%       "6" [label="app([],[3],C)"]
%       "4" -> "5"
%       "5" -> "6"
%   }


:- private(collect_sld_data/0).
:- dynamic(collect_sld_data/0).

% sld_data(GoalCodes, Current, Parent)
:- private(sld_data/3).
:- dynamic(sld_data/3).


% assert_sld_data(+Port, +MGoal, +Current, +Parent)
%
% Assert the data which is needed to create a dot file representing the SLD tree.
% For SICStus Prolog, Current and Parent are invocation numbers of the current invovation and the parent invocation.
% For SWI-Prolog, Current and Parent are integer references to the frame.
assert_sld_data(call, MGoal, Current, Parent) :-
	collect_sld_data, % SLD data is to be collected
	!,
	% If the goal is module name expanded with the user module, remove the module expansion
	(	MGoal = user::Goal ->
		true
	;	MGoal = Goal
	),
	% Assert the goal as character codes so that the variable names can be preserved and replaced consistently
	write_term_to_codes(Goal, GoalCodes, [quoted(true)]),
	assertz(sld_data(GoalCodes, Current, Parent)).
assert_sld_data(_Port, _MGoal, _Current, _Parent) :-
	collect_sld_data. % SLD data is to be collected, but not for ports other than call


% handle_print_sld_tree(+Goal, +Bindings)
handle_print_sld_tree(Goal, Bindings) :-
	% Assert collect_sld_data/0 so that SLD data is collected during tracing (needed for SWI-Prolog)
	assertz(collect_sld_data),
	% Retract previous data
	catch(retractall(sld_data(_GoalCodes, _Inv, _ParentInv)), _GoalInvDataException, true),
	% Call the goal and collect the needed data
	call_query_with_output_to_file(
	     jupyter_term_handling::call_with_sld_data_collection(Goal, Exception, IsFailure), 0, Bindings,
	                                                 _OriginalTermData, Output, _ExceptionMessage, _IsFailure),
	retractall(collect_sld_data),
	% Compute the graph file content
	catch(safe_call_without_sending_error_replies(sld_graph_file_content(GraphFileContentAtom)),InternalException,true),
	% Assert the result response
	(	nonvar(InternalException) ->
		!,
		assert_error_response(exception, message_data(error, InternalException), Output, [])
	;	nonvar(Exception) -> % Exception
		!,
		assert_error_response(exception, message_data(error, Exception), Output, [print_sld_tree-GraphFileContentAtom])
	;	IsFailure == true -> % Failure
		!,
		assert_error_response(failure, null, Output, [print_sld_tree-GraphFileContentAtom])
	;	% Success
		handle_result_variable_bindings(Bindings, ResultBindings),
		assert_success_response(query, ResultBindings, Output, [print_sld_tree-GraphFileContentAtom])
	).


	% call_with_sld_data_collection(+Goal, -Exception -IsFailure)
	call_with_sld_data_collection(Goal, Exception, IsFailure) :-
		catch(call_with_sld_failure_handling(Goal, IsFailure), Exception, notrace).


	% call_with_sld_failure_handling(+Goal, -IsFailure)
	call_with_sld_failure_handling(Goal, IsFailure) :-
		trace,
		(	call(Goal) ->
			notrace,
			IsFailure = false
		;	notrace,
			IsFailure = true
		).


	% sld_graph_file_content(-GraphFileContentAtom)
	%
	% GraphFileContentAtom is an atom representing the content of a graph file which would represent the SLD tree of the current execution.
	% Collects the data which was asserted as sld_data/3.
	% For each element (except the ones for the toplevel call and remove_breakpoints/1), an atom is created representing one of the lines of the file.
	sld_graph_file_content(GraphFileContentAtom) :-
		findall(GoalCodes-Id-ParentId, sld_data(GoalCodes, Id, ParentId), SldData),
		clean_sld_data(SldData, CleanSldData),
		% Compute nodes content
		sld_tree_node_atoms(CleanSldData, 'A', [], Nodes),
		% Compute edges content
		% The first element corresponds to a call from the toplevel
		% SldDataWithoutToplevelCalls contains all elements from CleanSldData which do not correspond to toplevel calls with the same ParentId
		CleanSldData = [_Goal-_CurrentId-ToplevelId|_],
		delete_all_occurrences(CleanSldData, _G-_Id-ToplevelId, SldDataWithoutToplevelCalls),
		sld_tree_edge_atoms(SldDataWithoutToplevelCalls, Edges),
		% Build the file content atom
		% Append elements to the list with which the remaining file content is added
		append(Edges, ['}'], EdgesWithClosingBracket),
		append(Nodes, EdgesWithClosingBracket, NodesAndEdgesWithClosingBracket),
		atomic_list_concat(['digraph {\n'|NodesAndEdgesWithClosingBracket], GraphFileContentAtom).


% clean_sld_data(+SldData, -CleanSldData)
%
% For SIW- and SICStus Prolog, the list of SLD tree data needs to be handled differently before it can be used to compute graph file content.

clean_sld_data(SldData, CleanSldData) :-
	compute_unique_ids(SldData, 1, [], CleanSldData).


% compute_unique_ids(+SldData, +CurrentId, +ActiveIds, -SldDataWithUniqueIds)
%
% SldData is a list with elements of the form GoalCodes-CurrentFrame-ParentFrame.
% CurrentFrame and ParentFrame are integer references to the local stack frame.
% Since these are not unique, they cannot be used to compute the graph file and instead, unique IDs need to be computed.
% ActiveIds is a list of Frame-Id pairs.
% Every element in SldData is assigned a ID (CurrentId).
% For every element, checks if an element CurrentFrame-Id is contained in ActiveIds.
%   If so, there was another goal on the same level as the current one.
%   In that case, the element in SldData is "replaced" with CurrentFrame-CurrentId.
%   Otherwise, a new element CurrentFrame-NewID is added to SldData.
% For every element in SldData, ActiveIds contains an element ParentFrame-ParentId (except for the toplevel goals)
% SldDataWithUniqueIds contains GoalCodes-CurrentId-ParentId elements.
compute_unique_ids([], _CurrentId, _ActiveIds, []).
compute_unique_ids([GoalCodes-CurrentFrame-ParentFrame|SldData], CurrentId, ActiveIds, [GoalCodes-CurrentId-ParentId|SldDataWithUniqueIds]) :-
	(	member(CurrentFrame-PreviousId, ActiveIds) ->
		% A goal on the same level was already encountered
		% The corresponding element needs to be replaced in the active ID list
		delete(ActiveIds, CurrentFrame-PreviousId, ReaminingActiveIds),
		NewActiveIds = [CurrentFrame-CurrentId|ReaminingActiveIds]
	;	NewActiveIds = [CurrentFrame-CurrentId|ActiveIds]
	),
	% Retrieve the parent's ID
	(	member(ParentFrame-Id, ActiveIds) ->
		ParentId = Id
	;	% For the toplevel calls, there is no parent ID
		ParentId = 0
	),
	NextId is CurrentId + 1,
	compute_unique_ids(SldData, NextId, NewActiveIds, SldDataWithUniqueIds).


% sld_tree_node_atoms(+SldData, +CurrentReplacementAtom +VariableNameReplacements, -NodeAtoms)
%
% SldData is a list with elements of the form GoalCodes-Current-Parent.
% For each of the elements, NodeAtoms contains an atom of the following form: '"Current" [label="Goal"]'
% All variable names, which are of the form _12345 are replaced by names starting with 'A'.
% CurrentReplacementAtom is the atom the next variable name is to be replaced with.
% In order to keep the renaming consistent for all terms, VariableNameReplacements is a list with VarName=NameReplacement pairs for name replacements which were made for the previous terms.
sld_tree_node_atoms([], _CurrentReplacementAtom, _VariableNameReplacements, []) :- !.
sld_tree_node_atoms([GoalCodes-Current-_Parent|SldData], CurrentReplacementAtom, VariableNameReplacements, [Node|Nodes]) :-
	% Read the goal term from the codes with the option variable_names/1 so that variable names can be replaced consistently
	append(GoalCodes, [46], GoalCodesWithFullStop),
	safe_read_term_from_codes_with_vars(GoalCodesWithFullStop, GoalTerm, [variable_names(VariableNames)]),
	% Replace the variable names
	replace_variable_names(VariableNames, CurrentReplacementAtom, VariableNameReplacements, NextReplacementAtom, NewVariableNameReplacements),
	% Create the atom
	format_to_codes('    \"~w\" [label=\"~w\"]~n', [Current, GoalTerm], NodeCodes),
	atom_codes(Node, NodeCodes),
	sld_tree_node_atoms(SldData, NextReplacementAtom, NewVariableNameReplacements, Nodes).

% catch exceptions; ensure that we do not have to restart server if some internal mishap occurs
% e.g., due to missing quoting, unicode issues or change in operator declarations
safe_read_term_from_codes_with_vars(GoalCodesWithFullStop, GoalTerm, VariableNames) :-
	catch(
		read_term_from_codes(GoalCodesWithFullStop, GoalTerm, [variable_names(VariableNames)]),
		Exception,
		(VariableNames = [], GoalTerm = Exception)
	).

% replace_variable_names(+VariableNames, +CurrentReplacementAtom, +VariableNameReplacements, -NextReplacementAtom, -NewVariableNameReplacements)
replace_variable_names([], CurrentReplacementAtom, VariableNameReplacements, CurrentReplacementAtom, VariableNameReplacements) :- !.
replace_variable_names([Var=Name|VariableNames], CurrentReplacementAtom, VariableNameReplacements, NextReplacementAtom, NewVariableNameReplacements) :-
	member(Var=ReplacementAtom, VariableNameReplacements),
	!,
	% The variable has already been assigned a new name
	Name = ReplacementAtom,
	replace_variable_names(VariableNames, CurrentReplacementAtom, VariableNameReplacements, NextReplacementAtom, NewVariableNameReplacements).
replace_variable_names([Var=Name|VariableNames], CurrentReplacementAtom, VariableNameReplacements, OutputReplacementAtom, NewVariableNameReplacements) :-
	% The variable has not been assigned a new name
	Name = CurrentReplacementAtom,
	next_replacement_atom(CurrentReplacementAtom, NextReplacementAtom),
	replace_variable_names(VariableNames, NextReplacementAtom, [Var=CurrentReplacementAtom|VariableNameReplacements], OutputReplacementAtom, NewVariableNameReplacements).


% next_replacement_atom(+CurrentReplacementAtom, -NextReplacementAtom)
%
% In order to compute the next replacement atom, CurrentReplacementAtom is converted into a list of character codes.
% If the last code does not equal 90 (i.e. 'Z'), the code is increased and the codes are converted into NextReplacementAtom.
% Otherwise, the code cannot be increased further, so a new character code for 'A' is added to the list.
next_replacement_atom(CurrentReplacementAtom, NextReplacementAtom) :-
	atom_codes(CurrentReplacementAtom, CurrentCodes),
	append(PrecedingCodes, [LastCode], CurrentCodes),
	% Compute the next last code(s)
	(	LastCode == 90 ->
		% The code 90 corresponds to 'Z' and cannot simply be increased
		% Instead, an additional character code needs to be added
		NextCodeList = [90, 65]
	;	NextCode is LastCode + 1,
		NextCodeList = [NextCode]
	),
	% Compute the new code list and atom
	(	PrecedingCodes == [] ->
		NextReplacementCodes = NextCodeList
	;	append(PrecedingCodes, NextCodeList, NextReplacementCodes)
	),
	atom_codes(NextReplacementAtom, NextReplacementCodes).


% delete_all_occurrences(+List, +DeleteElement, -NewList)
%
% NewList is a list containing all elements of the List which are not equal to DeleteElement.
% In order to not bind any variables, copy_term/2 is used.
delete_all_occurrences([], _DeleteElement, []) :- !.
delete_all_occurrences([Element|List], DeleteElement, NewList) :-
	copy_term(DeleteElement, CopyDeleteElement),
	Element = CopyDeleteElement,
	!,
	delete_all_occurrences(List, DeleteElement, NewList).
delete_all_occurrences([Element|List], DeleteElement, [Element|NewList]) :-
	delete_all_occurrences(List, DeleteElement, NewList).


% sld_tree_edge_atoms(+SldData, -Edges)
%
% SldData is a list with elements of the form GoalCodes-Current-Parent.
% For each of these elements, Edges contains an atom of the following form: '    "Parent" -> "Current"~n'
sld_tree_edge_atoms([], []) :- !.
sld_tree_edge_atoms([_GoalCodes-Current-Parent|SldData], [EdgeAtom|Edges]) :-
	format_to_codes('    \"~w\" -> \"~w\"~n', [Parent, Current], EdgeCodes),
	atom_codes(EdgeAtom, EdgeCodes),
	sld_tree_edge_atoms(SldData, Edges).
*/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Print Transition Graph

% Create content for a file representing a graph of transitions between the clauses of a given predicate.
% In addition to a predicate specification, indices need to be provided for the arguments which are used for the edges and their optional labels.
% The predicate results are used to create lines for the edges of one of the following forms:
% - '    "From" -> "To" [label="Label"]~n'
% - '    "From" -> "To"~n'


% handle_print_transition_graph(+NodePredSpec, +EdgePredSpec, +FromIndex, +ToIndex, +LabelIndex)
%
% NodePredSpec needs to be a predicate spec of the form true or Object::PredName/PredArity or PredName/PredArity.
% The first argument is the internal name of the node, passed on to EdgePredSpec, the second arg can be a dot attribute list
% EdgePredSpec needs to be a predicate specification of the form Object::PredName/PredArity or PredName/PredArity.
% FromIndex, ToIndex, and LabelIndex need to be less or equal to PredArity.
% FromIndex and ToIndex point to predicate arguments used as nodes.
% LabelIndex points to the argument providing a label for an edge.
% If LabelIndex=0, the edges are not labelled.
handle_print_transition_graph(NodePredSpec, EdgePredSpec, FromIndex, ToIndex, LabelIndex) :-
	% Check that the predicate specification and indices are correct
	expanded_pred_spec(EdgePredSpec, Object::PredName/PredArity,PredTerm),
	check_indices(PredArity, FromIndex, ToIndex, LabelIndex),
	!,
	PredTerm =.. [PredName| ArgList],
	% compute all possible nodes
	(	NodePredSpec == true
	->	EdgeCall = Object::PredTerm
	;	findall(
			node(NodeName, NodeDotDesc),
			get_transition_graph_node_atom(NodePredSpec, NodeName, NodeDotDesc),
			Nodes
		),
		sort(Nodes,SNodes),
		maplist(get_node_desc,SNodes,NodeDescAtoms),
		nth1(FromIndex, ArgList, FromNode),
		nth1(ToIndex, ArgList, ToNode),
		EdgeCall = (member(node(FromNode,_),SNodes), Object::PredTerm, member(node(ToNode,_),SNodes))
		% only take nodes into account which are declared, % TO DO: we could only apply restriction to FromNode
	),
	% Compute all possible transitions
	findall(ArgList, EdgeCall, Results),
	% Compute the graph file content
	transition_graph_edge_atoms(Results, FromIndex, ToIndex, LabelIndex, EdgeDescAtoms),
	append([NodeDescAtoms,EdgeDescAtoms, ['}']], EdgesWithClosingBracket),
	atomic_list_concat(['digraph {\n'|EdgesWithClosingBracket], GraphFileContentAtom),
	% Assert the result response
	assert_success_response(query, [], '', [print_transition_graph-GraphFileContentAtom]).
handle_print_transition_graph(_NodePredSpec,_EdgePredSpec, _FromIndex, _ToIndex, _LabelIndex).
% If some requirements are not fulfilled, the first clause asserts an error response and fails

get_node_desc(node(_,Desc),Desc).

% generate dot node name and dot description atom
% example fact for NodePredSpec:
% node(a,[label/'A',shape/rect, style/filled, fillcolor/yellow]).
get_transition_graph_node_atom(NodePredSpec, NodeName, NodeDotDesc) :-
	expanded_pred_spec(NodePredSpec, Object::PredName/_PredArity, NodeCall),
	NodeCall =.. [PredName|ArgList],
	% first argument is the identifier/name of the node
	ArgList = [NodeName|ArgTail],
	% generate solutions for the node predicate
	Object::NodeCall,
	(	ArgTail = [DotList|_],
		% we have a potential argument with infos about the style, label, ...
		findall(dot_attr(Attr,Val),get_dot_node_attribute(Attr,Val,DotList),Attrs),
		Attrs = [_|_]
		% we have found at least one attribute
	->	phrase(gen_dot_node_desc(NodeName,Attrs),Codes),
		atom_codes(NodeDotDesc,Codes)
	;	NodeDotDesc = ''
	).



% provide a default version of the command which automatically sets from,to and label index.
% e.g. we can call jupyter::print_transition_graph(edge/2).
handle_print_transition_graph(NodePredSpec, EdgePredSpec) :-
	expanded_pred_spec(EdgePredSpec, _Object::_PredName/PredArity, _),
	FromIndex = 1, ToIndex = PredArity,
	(	PredArity =< 2 ->
		LabelIndex = 0
	;	LabelIndex = 2
	),
	handle_print_transition_graph(NodePredSpec, EdgePredSpec, FromIndex, ToIndex, LabelIndex).

% expand module name to determine arity and provide a predicate call
% can be called with M:p/n or p/n or M:p or M:p(arg1,...)
% in the latter case the call arguments are passed through
% TODO: maybe get rid of this using meta_predicate annotations
% expanded_pred_spec(+PredSpec, -MPredSpec)
expanded_pred_spec(PredSpec, Object::PredName/PredArity, PredCall) :-
	get_object(PredSpec, Object, PredName/PredArity),
	!,
	functor(PredCall, PredName, PredArity).
expanded_pred_spec(PredSpec, Object::PredName/PredArity, PredCall) :-
	get_object(PredSpec, Object, PredName),
	atom(PredName),  % just predicate name w/o arity
	Object::current_predicate(PredName/Arity),
	!,
	PredArity = Arity,
	functor(PredCall,PredName,PredArity).
expanded_pred_spec(PredSpec, Object::PredName/PredArity, PredCall) :-
	get_object(PredSpec, Object, PredCall),
	functor(PredCall, PredName, PredArity),
	PredArity > 0,
	!.
expanded_pred_spec(PredSpec, _ , _) :-
	assert_error_response(exception, message_data(error, jupyter(print_transition_graph_pred_spec(PredSpec))), '', []),
	fail.

get_object(Object0::Term0, Object, Term) :-
	!,
	Object = Object0,
	Term = Term0.
get_object(Term, user, Term).

% check_indices(+PredArity, +FromIndex, +ToIndex, +LabelIndex)
check_indices(PredArity, FromIndex, ToIndex, LabelIndex) :-
	% All indices need to be less or equal to the predicate arity
	integer(FromIndex), FromIndex =< PredArity,
	integer(ToIndex), ToIndex =< PredArity,
	(atom(LabelIndex) -> true ; integer(LabelIndex), LabelIndex >= 0, LabelIndex =< PredArity),
	!.
check_indices(PredArity, _FromIndex, _ToIndex, _LabelIndex) :-
	assert_error_response(exception, message_data(error, jupyter(print_transition_graph_indices(PredArity))), '', []),
	fail.


% transition_graph_edge_atoms(+Results, +FromIndex, +ToIndex, +LabelIndex, -EdgeAtoms)
%
% Results is a list of lists where each of those lists corresponds to the arguments of a clause.
% FromIndex, ToIndex, and LabelIndex are pointers to these arguments.
% For each of the lists, the list EdgeAtoms contains an atom.
% If LabelIndex=0, EdgeAtoms contains atoms of the following form: '    "From" -> "To"~n'
% Otherwise, the atoms are of the following form:                  '    "From" -> "To" [label="Label"]~n'
transition_graph_edge_atoms([], _FromIndex, _ToIndex, _LabelIndex, []) :- !.
transition_graph_edge_atoms([Result|Results], FromIndex, ToIndex, LabelIndex, [EdgeAtom|EdgeAtoms]) :-
	nth1(FromIndex, Result, From),
	nth1(ToIndex, Result, To),
	(	get_label(LabelIndex, Result, Label) ->
		(	get_line_colour_style(LabelIndex, Result, Color,Style)
		->	format_to_codes('    \"~w\" -> \"~w\" [label=\"~w\", color=\"~w\", style=\"~w\"]~n',
		                    [From, To, Label, Color, Style], EdgeCodes)
		;	format_to_codes('    \"~w\" -> \"~w\" [label=\"~w\"]~n', [From, To, Label], EdgeCodes)
		)
	;	%Label=0 -> do not show any label
		format_to_codes('    \"~w\" -> \"~w\"~n', [From, To], EdgeCodes)
	),
	%TODO: we should probably escape the labels, ...
	atom_codes(EdgeAtom, EdgeCodes),
	transition_graph_edge_atoms(Results, FromIndex, ToIndex, LabelIndex, EdgeAtoms).

% we also accept graph definitions of the following form, where LabelIndex=2
% edg(a,[label/i, color/red, style/dotted],b).
% edg(b,[label/j, color/chartreuse, style/solid], c).
get_label(0,_,_) :- !, fail.
get_label(LabelIndex,_,Label) :- atom(LabelIndex),!, % allows one to use an atom as label index
	Label=LabelIndex.
get_label(List,_,Label) :- List=[_|_], !, get_line_label(List,Label).
get_label(LabelIndex,Result,Label) :-
	nth1(LabelIndex, Result, ArgVal),
	(get_line_label(ArgVal,ListLabel) -> Label=ListLabel ; Label=ArgVal).

get_line_label(List,Label) :- bind_member(label,Label,List).

get_line_colour_style(List,_,Col,Style) :- List=[_|_], !, % style list provided directly in jupyter call
	get_line_colour(List,Col),
	get_line_style(List,Style).
get_line_colour_style(LabelIndex,Result,Col,Style) :- integer(LabelIndex),
	nth1(LabelIndex, Result, List), % the LabelIndex argument is a list containing dot/graphviz infos
	get_line_colour(List,Col),
	get_line_style(List,Style).

get_line_colour(List,Col) :- bind_member(colour,C,List),!,Col=C.
get_line_colour(List,Col) :- bind_member(color,C,List),!,Col=C.
get_line_colour(_,'black'). % default

get_line_style(List,Style) :- bind_member(style,C,List),valid_dot_line_style(C), !,Style=C.
get_line_style(_,'solid'). % default

valid_dot_line_style(bold).
valid_dot_line_style(dashed).
valid_dot_line_style(dotted).
valid_dot_line_style(invis).
valid_dot_line_style(solid).

%get_shape(List,Style) :- bind_member(Style,C,List),!,Style=C.
%get_shape(_,'none').

bind_member(Label,Value,List) :-
	member(Binding,List),
	binding(Binding,Label,Value).

% we accept various ways to specify bindings:
binding('='(Label,Value),Label,Value).
binding('/'(Label,Value),Label,Value).
binding('-'(Label,Value),Label,Value).

get_dot_node_attribute(Attr2,Value,List) :-
	bind_member(Attr,Value,List),
	valid_dot_node_attribute(Attr,Attr2).

valid_dot_node_attribute(label,label).
valid_dot_node_attribute(color,color).
valid_dot_node_attribute(colour,color).
valid_dot_node_attribute(fillcolor,fillcolor).
valid_dot_node_attribute(shape,shape).
valid_dot_node_attribute(style,style).

valid_dot_shape('Mcircle').
valid_dot_shape('Mdiamond').
valid_dot_shape('Msquare').
valid_dot_shape(box).
valid_dot_shape(box3d). % requires newer version of graphviz
valid_dot_shape(cds). % requires newer version of graphviz
valid_dot_shape(circle).
valid_dot_shape(component). % requires newer version of graphviz
valid_dot_shape(cylinder). % requires newer version of graphviz
valid_dot_shape(diamond).
valid_dot_shape(doublecircle).
valid_dot_shape(doubleoctagon).
valid_dot_shape(egg).
valid_dot_shape(ellipse).
valid_dot_shape(folder). % requires newer version of graphviz
valid_dot_shape(hexagon).
valid_dot_shape(house).
valid_dot_shape(invhouse).
valid_dot_shape(invtrapez).
valid_dot_shape(invtrapezium).
valid_dot_shape(invtriangle).
valid_dot_shape(larrow). % requires newer version of graphviz
valid_dot_shape(lpromoter). % requires newer version of graphviz
valid_dot_shape(none).
valid_dot_shape(note). % requires newer version of graphviz
valid_dot_shape(octagon).
valid_dot_shape(oval).
valid_dot_shape(parallelogram).
valid_dot_shape(pentagon).
valid_dot_shape(plain).
valid_dot_shape(plaintext).
valid_dot_shape(point).
valid_dot_shape(promoter). % requires newer version of graphviz
valid_dot_shape(record).
valid_dot_shape(rarrow). % requires newer version of graphviz
valid_dot_shape(rect).
valid_dot_shape(rectangle).
valid_dot_shape(rpromoter). % requires newer version of graphviz
valid_dot_shape(septagon).
valid_dot_shape(square).
valid_dot_shape(star). % requires newer version of graphviz
valid_dot_shape(tab). % requires newer version of graphviz
valid_dot_shape(trapezium).
valid_dot_shape(triangle).
valid_dot_shape(tripleoctagon).

valid_dot_node_style(bold).
valid_dot_node_style(dashed).
valid_dot_node_style(diagonals).
valid_dot_node_style(dotted).
valid_dot_node_style(filled).
valid_dot_node_style(rounded).
valid_dot_node_style(solid).
valid_dot_node_style(striped).
valid_dot_node_style(wedged).
valid_dot_node_style(none).

% generate a node description as list of codes
% | ?- jupyter_term_handling::gen_node_desc(a,[dot_attr(label,b),dot_attr(color,c)],A,[]), format("~s~n",[A]).
% a [label="b", color="c"]
gen_dot_node_desc(NodeName,Attrs) -->
	"\"", call(gen_atom(NodeName)), "\" [", gen_node_attr_codes(Attrs),"]", [10].

gen_node_attr_codes([]) -->
	"".
gen_node_attr_codes([dot_attr(Attr,Val)]) -->
	!, call(gen_atom(Attr)), "=\"", call(gen_atom(Val)), "\"".
gen_node_attr_codes([dot_attr(Attr,Val)|Tail]) -->
   call(gen_atom(Attr)), "=\"", call(gen_atom(Val)), "\", ", gen_node_attr_codes(Tail).

gen_atom(Atom, In, Out) :-
	format_to_codes('~w', [Atom], Codes),
	append(Codes, Out, In).

% Convenience predicates for visualising Prolog terms (show_term/1) using show_graph:
% jupyter::show_graph(dot_subnode(_,_,Term),dot_subtree/3)

dot_subtree(Term,Nr,SubTerm) :-
	nonvar(Term),
	% obtain arguments of the term
	Term =.. [_|ArgList],
	% get sub-argument and its position number
	nth1(Nr,ArgList,SubTerm).

% recursive and transitive closure of subtree
dot_rec_subtree(Term, Sub) :-
	Term = Sub.
dot_rec_subtree(Term, Sub) :-
	dot_subtree(Term, _, X),
	dot_rec_subtree(X, Sub).

% the node predicate for all subterms of a formula
dot_subnode(Sub,[shape/S, label/F],Formula) :-
	dot_rec_subtree(Formula,Sub), % any sub-formula Sub of Formula is a node in the graphical rendering
	(	var(Sub) ->
		S = ellipse, F=Sub
	;	functor(Sub,F,_), (atom(Sub) -> S = egg ; number(Sub) -> S = oval ; S = rect)
	).

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Change the Prolog backend

	% The user requested to change the active Prolog backend.
	% The actual changing of the implementation is handled by the client (the Jupyter kernel).
	% It expects an 'set_prolog_backend' item to be part of the result.

	% handle_set_prolog_backend(+Backend)
	handle_set_prolog_backend(Backend) :-
		atom(Backend),
		!,
		assert_success_response(query, [], '', [set_prolog_backend-Backend]).
	handle_set_prolog_backend(_Backend) :-
		assert_error_response(exception, message_data(error, jupyter(prolog_backend_no_atom)), '', []).

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Change a Jupyter Prolog preference

	handle_set_preference(Pref,Value) :-
		set_preference(Pref,Old,Value),
		!,
		format_to_atom('% Changing preference ~w from ~w to ~w~n', [Pref,Old,Value], Msg),
		assert_success_response(query, [], Msg, []).
	handle_set_preference(Pref,Value) :-
		assert_error_response(exception, message_data(error, jupyter(set_preference(Pref,Value))), '', []).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Reload the completion data

% The user requested to reload the data used for code completion.
% Finds all predicates which are built-in or exported by a loaded module.
% The client expects these to be part of the result as 'predicate_atoms'.


handle_update_completion_data.
%handle_update_completion_data :-
%  % Find all callable (built-in and exported) predicates and send them to the client
%  findall(Pred, generate_built_in_pred(Pred), BuiltInPreds),
%  findall(Pred, generate_exported_pred(Pred), ExportedPreds),
%  append(ExportedPreds, BuiltInPreds, CurrentPreds),
%  % convert the predicates into atoms so that they are JSON parsable
%  findall(PredAtom, (member(CurPred, CurrentPreds), predicate_atom(CurPred, PredAtom)), PredAtoms),
%  assert_success_response(query, [], '', [predicate_atoms=PredAtoms]).


%% generate_built_in_pred(-PredicateHead)
%:- if(swi).
%generate_built_in_pred(Head) :-
%  predicate_property(system:Head, built_in),
%  functor(Head, Name, _Arity),
%  % Exclude reserved names
%  \+ sub_atom(Name, 0, _, _, $).
%:- else.
%generate_built_in_pred(Head) :-
%  predicate_property(Head, built_in),
%  functor(Head, Name, _Arity),
%  % Exclude the 255 call predicates
%  Name \= call.
%generate_built_in_pred(call(_)).
%:- endif.


%	% generate_exported_pred(-ModuleNameExpandedPredicateHead)
%	generate_exported_pred(Module:Pred) :-
%		ServerModules = [jupyter_jsonrpc, jupyter_logging, jupyter_query_handling, jupyter_request_handling, jupyter_server, jupyter_term_handling, jupyter_variable_bindings],
%		predicate_property(Module:Pred, exported),
%		% Exclude exported predicates from any of the modules used for this server except for 'jupyter'
%		\+ member(Module, ServerModules).


%	% predicate_atom(+Predicate, -PredicateAtom)
%	%
%	% PredicateAtom is an atom created from Predicate by replacing all variables in it with atoms starting from 'A'.
%	predicate_atom(Predicate, PredicateAtom) :-
%		% Create a Name=Var pairs list as can be used for write_term_to_codes/3
%		term_variables(Predicate, Variables),
%		name_var_pairs(Variables, 65, Bindings), % 65 is the ASCII code for 'A'
%		write_term_to_codes(Predicate, PredicateCodes, [variable_names(Bindings)]),
%		atom_codes(PredicateAtom, PredicateCodes).


%	% name_var_pairs(+Variables, +CurrentCharacterCode, -Bindings)
%	name_var_pairs([], _CurrentCharacterCode, []) :- !.
%	name_var_pairs([Variable|Variables], CurrentCharacterCode, [NameAtom=Variable|Bindings]) :-
%		atom_codes(NameAtom, [CurrentCharacterCode]),
%		NextCharacterCode is CurrentCharacterCode + 1,
%		name_var_pairs(Variables, NextCharacterCode, Bindings).


	% Assert the term responses

	% For each term which is processed and produces a result, this result is asserted.
	% This way, all results can be sent to the client when all terms of a request have been handled.

	% assert_success_response(+Type, +Bindings, +Output, +AdditionalData)
	%
	% Type is the type of the term read from the client.
	% It is one of: directive, clause_definition, query
	% Bindings is a list of Name=Var pairs, where Name is the name of a variable Var occurring in the term.
	% Output is the output of the term which was executed.
	% AdditionalData is a list containing Key=Value pairs providing additional data for the client.
	assert_success_response(Type, Bindings, Output, AdditionalData) :-
		dbg('Success ~w:~n ~w~n~w~n ~w~n'+[Type,Bindings,Output,AdditionalData]),
		% use a catch/3 to succeed in case of assert error due to cyclic terms in TermData by discarding the bindings
		catch(
			assertz(term_response(json([status-success, type-Type, bindings-json(Bindings), output-Output|AdditionalData]))),
			_,
			assertz(term_response(json([status-success, type-Type, bindings-json([]), output-Output|AdditionalData])))
	).

	% assert_error_response(+ErrorCode, +ErrorMessageData, +Output, +AdditionalData)
	%
	% ErrorCode is one of the error codes defined by error_object_code/3 (e.g. exception; see the jupyter_jsonrpc object).
	% ErrorMessageData is a term of the form message_data(Kind, Term) so that the actual error message can be retrieved with print_message(Kind, jupyter, Term)
	% Output is the output of the term which was executed.
	% AdditionalData is a list containing Key=Value pairs providing additional data for the client.
	assert_error_response(ErrorCode, ErrorMessageData, Output, AdditionalData) :-
		dbg('ERROR ~w:~n ~w~n~w~n ~w~n'+[ErrorCode,ErrorMessageData,Output,AdditionalData]),
		json_error_term(ErrorCode, ErrorMessageData, Output, AdditionalData, ErrorData),
		assertz(term_response(json([status-error, error-ErrorData]))).

:- end_object.
