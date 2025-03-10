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


% This is done by starting a loop which:
% - Reads a message from the standard input stream with jupyter_jsonrpc::next_jsonrpc_message/1.
% - Checks if the message is a valid request with dispatch_message/3.
% - Checks the method of the request with dispatch_request/4, handles it accordingly and sends a response to the client.
%   There are five methods:
%   - call: execute any terms (handled by the object jupyter_term_handling)
%   - version: retrieve the Prolog backend version
%   - jupyter_predicate_docs: retrieve the docs of the predicates in the object jupyter
%   - enable_logging: create a log file to which log messages can be written

% In case of a call request, the request might contain multiple terms.
% They are handled one by one and the remaining ones are asserted with request_data/2.
% They need to be asserted so that "retry." terms can fail into the previous call.
% If the term produces any result, it is asserted with jupyter_term_handling::term_response/1.
% Once all terms of a request are handled, their results are sent to the client.


:- object(jupyter_request_handling).

	:- info([
		version is 0:11:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2025-03-10,
		comment is 'This object provides predicates to start a loop reading and handling JSON RPC requests.'
	]).

	:- public(loop/3).
	:- mode(loop(+callable, +atom, +atom), zero_or_one).
	:- info(loop/3, [
		comment is 'Reads and processes requests from the client. Fails if it receives a request to retry an active goal - this causes the call to compute the next solution.',
		argnames is ['ContIn', 'Stack', 'ContOut']
	]).

	:- uses(term_io, [format_to_atom/3, write_term_to_atom/3]).
	:- uses(user, [atomic_list_concat/2]).

	:- uses(jupyter_logging, [create_log_file/1, log/1]).
	:- uses(jupyter_jsonrpc, [send_success_reply/2, send_error_reply/3, next_jsonrpc_message/1, parse_json_terms_request/3]).
	:- uses(jupyter_term_handling, [handle_term/5, term_response/1]).
	:- uses(jupyter_query_handling, [send_reply_on_error/0, retrieve_message/2]).
	:- uses(jupyter, [predicate_docs/1]).

	% Assert the terms which were read from the current request so that "retry." terms can fail into the previous call
	:- private(request_data/2).
	:- dynamic(request_data/2).  % request_data(CallRequestId, TermsAndVariables)
	% TermsAndVariables is a list with elements of the form Term-Bindings.
	% Each of the terms Term can be a directive, clause definition, or query.
	% Bindings is a list of variable name and variable mappings (of the form Name=Var) which occur in the corresponding term Term.

	:- multifile(logtalk::message_hook/4).
	:- dynamic(logtalk::message_hook/4).

	logtalk::message_hook(MessageTerm, error, _, _Lines) :-
		handle_unexpected_exception(MessageTerm).


	% handle_unexpected_exception(+MessageTerm)
	%
	% Handle an unexpected exception.
	% Send an error reply to let the client know that the server is in a state from which it cannot recover and therefore needs to be killed and restarted.
	handle_unexpected_exception(MessageTerm) :-
		send_reply_on_error,
		log(MessageTerm),
		% Retract all data of the current request
		retract(request_data(_CallRequestId, _TermsAndVariables)),
		% Send an error response
		retrieve_message(message_data(error, MessageTerm), ExceptionMessage),
		send_error_reply(@(null), unhandled_exception, ExceptionMessage),
		fail.


	% loop(+ContIn, +Stack, -ContOut)
	%
	% Read and process requests from the client.
	% Called to start processing requests and after calling a goal to provide the ability to compute another solution for a goal on the stack Stack.
	% Succeeds with ContOut = cut if it receives a request to cut an active goal.
	% Succeeds with ContOut = done if it receives a request to quit.
	% Fails if it receives a request to retry an active goal - this causes the call to compute the next solution.
	loop(Cont, _Stack, _ContOut) :-
		var(Cont),
		!,
		fail.
	loop(done, _Stack, done) :-
		!,
		send_responses.
	loop(cut, _Stack, cut) :- !.
	loop(continue, Stack, ContOut) :-
		handle_next_term_or_request(Stack, Cont),
		loop(Cont, Stack, ContOut).


	% handle_next_term_or_request(+Stack, -Cont)
	%
	% Handles the next term or request.
	% One call request can contain more than one term.
	% Terms of the current request which have not been processed yet are asserted as request_data(CallRequestId, TermsAndVariables).
	handle_next_term_or_request(Stack, Cont) :-
		request_data(CallRequestId, TermsAndVariables),
		TermsAndVariables = [Term-Variables|RemainingTermsAndVariables],
		!,
		% Continue processing terms of the current request
		retract(request_data(CallRequestId, TermsAndVariables)),
		assertz(request_data(CallRequestId, RemainingTermsAndVariables)),
		handle_term(Term, CallRequestId, Stack, Variables, Cont).
	handle_next_term_or_request(Stack, Cont) :-
		% All terms of the current request have been processed -> send their results to the client
		request_data(_CallRequestId, []),
		!,
		send_responses,
		% Read the next request
		next_jsonrpc_message(Message),
		dispatch_message(Message, Stack, Cont).
	handle_next_term_or_request(Stack, Cont) :-
		% First request
		% Read and handle the next request from the client
		next_jsonrpc_message(Message),
		dispatch_message(Message, Stack, Cont).


	% Get all term responses which were asserted as term_response(JsonResponse).
	% Send a json response object where
	% - the keys are the indices of the Prolog terms from the request starting from 1
	% - the values are json objects representing the result of the corresponding Prolog term
	send_responses :-
		% Retract all data of the current request
		retract(request_data(CallRequestId, _)),
		% Collect the responses and send them to the client
		term_responses(1, TermResponses),
		send_success_reply(CallRequestId, json(TermResponses)).


	% term_responses(+CurrentNum, -TermResponses)
	term_responses(Num, [NumAtom-Response|TermResponses]) :-
		retract(term_response(Response)),
		!,
		number_codes(Num, NumCodes),
		atom_codes(NumAtom, NumCodes),
		NextNum is Num + 1,
		term_responses(NextNum, TermResponses).
	term_responses(_Num, []).

	% Request handling

	% dispatch_message(+Message, +Stack, -Cont)
	%
	% Checks if the message is a valid request message.
	% If so, handles the request.
	% Otherwise, an error response is sent.
	dispatch_message(Message, Stack, Cont) :-
		Message = request(Method,_Id,_Params,_RPC), !,
		dispatch_request(Method, Message, Stack, Cont).
	dispatch_message(invalid(_RPC), _Stack, continue) :-
		% Malformed -> the Id must be null
		send_error_reply(@(null), invalid_request, '').

	% dispatch_request(+Method, +Message, +Stack, -Cont)
	%
	% Checks the request method and handles the request accordingly.
	dispatch_request(call, Message, Stack, Cont) :-
		Message = request(_Method,CallRequestId,Params,_RPC),
		Params = json([code-Code]),
		file_cell_magic(Code, File, Mode, Terms, Action),
		!,
		assertz(request_data(CallRequestId, [])),
		(	Action == none ->
			Cont = continue
		;	open(File, Mode, Stream),
			write(Stream, Terms),
			close(Stream),
			(	Action == load ->	
				handle_term(logtalk_load(File, [reload(always)]), CallRequestId, Stack, [], Cont)
			;	Cont = continue
			)
		).
	dispatch_request(call, Message, Stack, Cont) :-
		Message = request(Method,CallRequestId,Params,RPC),
		Params = json([code-Code]),
		goal_cell_magic(Code, Rest),
		!,
		RestMessage = request(Method,CallRequestId,json([code-Rest]),RPC),
		dispatch_request(call, RestMessage, Stack, Cont).
	dispatch_request(call, Message, Stack, Cont) :-
		Message = request(Method,CallRequestId,Params,RPC),
		Params = json([code-Code]),
		line_magic(Code, Rest),
		!,
		RestMessage = request(Method,CallRequestId,json([code-Rest]),RPC),
		dispatch_request(call, RestMessage, Stack, Cont).
	dispatch_request(call, Message, Stack, Cont) :-
		!,
		Message = request(_Method,CallRequestId,Params,_RPC),
		parse_json_terms_request(Params, TermsAndVariables, ParsingErrorMessageData),
		(	var(TermsAndVariables) ->
			!,
			% An error occurred when parsing the json request
			handle_parsing_error(ParsingErrorMessageData, CallRequestId),
			Cont = continue
		;	TermsAndVariables == [] ->
			!,
			% The request does not contain any term
			send_success_reply(CallRequestId, ''),
			Cont = continue
		;	TermsAndVariables = [Term-Variables] ->
			!,
			% The request contains one term
			% Normally this is a goal which is to be evaluated
			assertz(request_data(CallRequestId, [])),
			handle_term(Term, CallRequestId, Stack, Variables, Cont)
		;	% The request contains multiple terms
			% Process the first term and assert the remaining ones
			% This is needed so that "retry." terms can fail into the previous call
			TermsAndVariables = [Term-Variables|RemainingTermsAndVariables],
			assertz(request_data(CallRequestId, RemainingTermsAndVariables)),
			handle_term(Term, CallRequestId, Stack, Variables, Cont)
		).
	dispatch_request(backend, Message, _Stack, continue) :-
		!,
		Message = request(_Method,CallRequestId,_Params,_RPC),
		current_logtalk_flag(prolog_dialect, Dialect),
		send_success_reply(CallRequestId, Dialect).
	dispatch_request(enable_logging, Message, _Stack, continue) :-
		!,
		% Create a log file
		Message = request(_Method,CallRequestId,_Params,_RPC),
		create_log_file(IsSuccess),
		send_success_reply(CallRequestId, IsSuccess).
	dispatch_request(version, Message, _Stack, continue) :-
		!,
		% Send the backend version to the client
		Message = request(_Method,CallRequestId,_Params,_RPC),
		current_logtalk_flag(prolog_version, v(Major,Minor,Patch)),
		format_to_atom('~d.~d.~d', [Major, Minor, Patch], VersionAtom),
		send_success_reply(CallRequestId, VersionAtom).
	dispatch_request(jupyter_predicate_docs, Message, _Stack, continue) :-
		% Retrieve the docs of the predicates in the object jupyter and send them to the client
		Message = request(_Method,CallRequestId,_Params,_RPC),
		!,
		predicate_docs(PredDocs),
		send_success_reply(CallRequestId, json(PredDocs)).
	dispatch_request(Method, Message, _Stack, continue) :-
		% Make sure that a 'retry' call can fail
		Method \= call,
		Message = request(_,Id,_Params,_RPC), !,
		write_term_to_atom(Method, MethodAtom, [quoted(true)]),
		send_error_reply(Id, method_not_found, MethodAtom).


	% handle_parsing_error(+ParsingErrorMessageData, +CallRequestId)
	handle_parsing_error(ParsingErrorMessageData, CallRequestId) :-
		nonvar(ParsingErrorMessageData),
		!,
		% Parsing error when reading the terms from the request
		retrieve_message(ParsingErrorMessageData, ErrorMessage),
		send_error_reply(CallRequestId, exception, ErrorMessage).
	handle_parsing_error(_ParsingErrorMessageData, CallRequestId) :-
		% Malformed request
		send_error_reply(CallRequestId, invalid_params, '').

	% cell magic

	file_cell_magic(Code, 'user.lgt', append, Terms, load) :-
		sub_atom(Code, 0, _, _, '%%user+\n'),
		sub_atom(Code, 8, _, 0, Terms0),
		atom_concat('\n\n', Terms0, Terms),
		!.
	file_cell_magic(Code, 'user.lgt', write, Terms, load) :-
		sub_atom(Code, 0, _, _, '%%user\n'),
		sub_atom(Code, 7, _, 0, Terms),
		!.
	file_cell_magic(Code, File, append, Terms, load) :-
		sub_atom(Code, 0, _, _, '%%file+ '),
		sub_atom(Code, Before, _, _, '\n'),
		Length is Before - 8,
		sub_atom(Code, 8, Length, _, File),
		Rest is 8 + Length + 1,
		sub_atom(Code, Rest, _, 0, Terms0),
		atom_concat('\n\n', Terms0, Terms),
		!.
	file_cell_magic(Code, File, write, Terms, load) :-
		sub_atom(Code, 0, _, _, '%%file '),
		sub_atom(Code, Before, _, _, '\n'),
		Length is Before - 7,
		sub_atom(Code, 7, Length, _, File),
		Rest is 7 + Length + 1,
		sub_atom(Code, Rest, _, 0, Terms),
		!.
	file_cell_magic(Code, File, write, Terms, save) :-
		sub_atom(Code, 0, _, _, '%%save '),
		sub_atom(Code, Before, _, _, '\n'),
		Length is Before - 7,
		sub_atom(Code, 7, Length, _, File),
		Rest is 7 + Length + 1,
		sub_atom(Code, Rest, _, 0, Terms),
		!.
	file_cell_magic(Code, File, write, Terms, load) :-
		sub_atom(Code, 0, _, _, '%%load '),
		sub_atom(Code, Before, _, _, '\n'),
		Length is Before - 7,
		sub_atom(Code, 7, Length, _, File),
		Rest is 7 + Length + 1,
		sub_atom(Code, Rest, _, 0, Terms),
		!.
	file_cell_magic(Code, none, none, [], none) :-
		sub_atom(Code, 0, _, _, '%%highlight\n'),
		!.

	goal_cell_magic(Code, Rest) :-
		atom_concat('%%table\n', Goal0, Code),
		(	sub_atom(Goal0, _, 1, 0, '.') ->
			sub_atom(Goal0, 0, _, 1, Goal)
		;	Goal = Goal0
		),
		!,
		atomic_list_concat(['print_table((', Goal, ')).'], Rest).
	goal_cell_magic(Code, Rest) :-
		sub_atom(Code, 0, _, _, '%%csv '),
		sub_atom(Code, Before, _, _, '\n'),
		Length is Before - 6,
		sub_atom(Code, 6, Length, _, File),
		Start is 6 + Length + 1,
		sub_atom(Code, Start, _, 0, Goal0),
		(	sub_atom(Goal0, _, 1, 0, '.') ->
			sub_atom(Goal0, 0, _, 1, Goal)
		;	Goal = Goal0
		),
		!,
		atomic_list_concat(['print_and_save_table((', Goal, '),csv,\'', File, '\').'], Rest).
	goal_cell_magic(Code, Rest) :-
		sub_atom(Code, 0, _, _, '%%tsv '),
		sub_atom(Code, Before, _, _, '\n'),
		Length is Before - 6,
		sub_atom(Code, 6, Length, _, File),
		Start is 6 + Length + 1,
		sub_atom(Code, Start, _, 0, Goal0),
		(	sub_atom(Goal0, _, 1, 0, '.') ->
			sub_atom(Goal0, 0, _, 1, Goal)
		;	Goal = Goal0
		),
		!,
		atomic_list_concat(['print_and_save_table((', Goal, '),tsv,\'', File, '\').'], Rest).
	goal_cell_magic(Code, Rest) :-
		atom_concat('%%tree\n', Term0, Code),
		(	sub_atom(Term0, _, 1, 0, '.') ->
			sub_atom(Term0, 0, _, 1, Term)
		;	Term = Term0
		),
		!,
		atomic_list_concat(['show_term(', Term, ').'], Rest).
	goal_cell_magic(Code, Rest) :-
		atom_concat('%%data\n', Goal0, Code),
		(	sub_atom(Goal0, _, 1, 0, '.') ->
			sub_atom(Goal0, 0, _, 1, Goal)
		;	Goal = Goal0
		),
		!,
		atomic_list_concat(['show_data((', Goal, ')).'], Rest).

	line_magic('%bindings', 'jupyter::print_variable_bindings.').
	line_magic('%queries',  'jupyter::print_queries.').
	line_magic('%help',     'jupyter::help.').
	line_magic('%pwd',      'jupyter::pwd.').
	line_magic('%magic',    'jupyter::magic.').
	line_magic('%versions', 'jupyter::versions.').
	line_magic('%flags',    'jupyter::print_table(current_logtalk_flag(Name,Value)).').

:- end_object.
