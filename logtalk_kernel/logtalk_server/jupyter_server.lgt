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


% This is the main object of the backend server.
% The predicate start/0 can be called to start the server which enters a loop handling requests from a client.
% The requests and corresponding replies are JSON-RPC 2.0 (https://www.jsonrpc.org/specification) messages sent over the standard streams.
% The handling of those is based on code from 'jsonrpc_server.pl' from SICStus 4.5.1


:- object(jupyter_server).

	:- info([
		version is 0:5:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2025-03-10,
		comment is 'Main object of the server.'
	]).

	:- public(start/0).
	:- mode(start, one).
	:- info(start/0, [
		comment is 'Starts the server at the default verbosity level (1).'
	]).

	:- public(start/1).
	:- mode(start(+integer), one).
	:- info(start/1, [
		comment is 'Starts the server at the given verbosity level (0..10).',
		argnames is ['VerbosityLevel']
	]).

	:- uses(jupyter_request_handling, [loop/3]).
%	:- uses(jupyter_term_handling, [assert_sld_data/4]).
	:- uses(jupyter_preferences, [set_preference/2]).

	start :-
		start(1).

	start(JupyterKernelVerbosityLevel) :-
		set_preference(verbosity, JupyterKernelVerbosityLevel), % useful for testing purposes
		% Start the loop handling requests from the client
		loop(continue, [], _ContOut).

%	:- multifile(logtalk::trace_event/2).
%	:- dynamic(logtalk::trace_event/2).
%
%	% the Logtalk runtime calls all defined logtalk::trace_event/2 hooks using
%	% a failure-driven loop; thus we don't have to worry about handling all
%	% events or failing after handling an event to give other hooks a chance
%	logtalk::trace_event(top_goal(Goal, _), _) :-
%		assert_sld_data(call, Goal, _Frame, _ParentFrame).
%	logtalk::trace_event(goal(Goal, _), _) :-
%		assert_sld_data(call, Goal, _Frame, _ParentFrame).

	:- multifile(logtalk::message_prefix_stream/4).
	:- dynamic(logtalk::message_prefix_stream/4).

	logtalk::message_prefix_stream(Kind, jupyter, Prefix, Stream) :-
		message_prefix_stream(Kind, Prefix, Stream).

	message_prefix_stream(information, '% ',     user_output).
	message_prefix_stream(comment,     '% ',     user_output).
	message_prefix_stream(warning,     '*     ', user_output).
	message_prefix_stream(error,       '!     ', user_output).

	:- multifile(logtalk::message_tokens//2).
	:- dynamic(logtalk::message_tokens//2).

	logtalk::message_tokens(jupyter(JupyterMessageTerm), jupyter) -->
		message_tokens(JupyterMessageTerm).
	logtalk::message_tokens(MessageTerm, jupyter) -->
		message_tokens(MessageTerm).

	message_tokens(goal_failed(Goal)) -->
		['~w - goal failed'-[Goal]], [nl].

	message_tokens(set_preference(Preference,Value)) -->
		['Invalid preference or preference value: ~q - ~q'-[Preference, Value]], [nl].
	message_tokens(invalid_table_values_lists_length) -->
		['The values lists need to be of the same length'-[]], [nl].
	message_tokens(invalid_table_variable_names) -->
		['The list of names needs to be empty or of the same length as the values lists and contain ground terms only'-[]], [nl].
	message_tokens(leash_pred) -->
		['The leash mode cannot be changed in a Jupyter application as no user interaction can be provided at a breakpoint'-[]], [nl].
	message_tokens(print_transition_graph_indices(Arity)) -->
		['All indices need to be less or equal to the provided predicate arity ~w'-[Arity]], [nl].
	message_tokens(print_transition_graph_pred_spec(PredSpec)) -->
		['Incorrect predicate specification: ~w'-[PredSpec]], [nl],
		['It needs to be of the form PredName/PredArity or Object::PredName/PredArity'-[]], [nl].
	message_tokens(prolog_backend_no_atom) -->
		['The Prolog backend ID must be an atom'-[]], [nl].
	message_tokens(trace_pred(TracePredSpec)) -->
		['~w cannot be used in a Jupyter application'-[TracePredSpec]], [nl],
		['However, there is juypter:trace(Goal)'-[]], [nl].
	message_tokens(no_answer_given) -->
		% Used for the code stub for manually graded tasks of nbgrader assignments
		['No answer given'-[]], [nl].

	message_tokens(error(Error, Context)) -->
		['Error:   ~q'-[Error], nl],
		['Context: ~q'-[Context], nl].

:- end_object.
