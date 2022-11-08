
% This module provides predicates to start a loop reading and handling JSON RPC requests.

% This is done by starting a loop which:
% - Reads a message from the standard input stream with jupyter_jsonrpc:next_jsonrpc_message/1.
% - Checks if the message is a valid request with dispatch_message/3.
% - Checks the method of the request with dispatch_request/4, handles it accordingly and sends a response to the client.
%   There are five methods:
%   - call: execute any terms (handled by the module jupyter_term_handling)
%   - version: retrieve the SICStus version
%   - predicates: find built-in and exported predicates
%   - jupyter_predicate_docs: retrieve the docs of the predicates in the module jupyter
%   - enable_logging: create a log file to which log messages can be written

% In case of a call request, the request might contain multiple terms.
% They are handled one by one and the remaining ones are asserted with request_data/2.
% They need to be asserted so that "retry." terms can fail into the previous call.
% If the term produces any result, it is asserted with jupyter_term_handling:term_response/1.
% Once all terms of a request are handled, their results are sent to the client.


:- object(jupyter_request_handling).

	:- public([loop/3]).  % loop(+ContIn, +Stack, -ContOut)

	:- uses(term_io, [write_term_to_codes/3, format_to_codes/3]).
	:- uses(jupyter_logging, [create_log_file/1, log/1, log/2]).
	:- uses(jupyter_jsonrpc, [send_success_reply/2, send_error_reply/3, next_jsonrpc_message/1, parse_json_terms_request/3]).
	:- uses(jupyter_term_handling, [handle_term/6, declaration_end/1, pred_definition_specs/1, term_response/1]).
	:- uses(jupyter_query_handling, [send_reply_on_error/0, retrieve_message/2]).
	:- uses(jupyter, []).

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
		jupyter_query_handling::send_reply_on_error,
		jupyter_logging::log(MessageTerm),
		% Retract all data of the current request
		retract(request_data(_CallRequestId, _TermsAndVariables)),
		% Use catch/3, because no clauses might have been asserted
		catch(jupyter_term_handling::retractall(pred_definition_specs(_)), _, true),
		% Delete the declaration file
		declaration_end(false),
		% Send an error response
		jupyter_query_handling::retrieve_message(message_data(error, MessageTerm), ExceptionMessage),
		jupyter_jsonrpc::send_error_reply(@(null), unhandled_exception, ExceptionMessage),
		fail.


	% loop(+ContIn, +Stack, -ContOut)
	%
	% Read and process requests from the client.
	% Called to start processing requests and after calling a goal to provide the ability to compute another solution for a goal on the stack Stack.
	% Succeeds with ContOut = cut if it receives a request to cut an active goal.
	% Succeeds with ContOut = done if it receives a request to quit.
	% Fails if it receives a request to retry an active goal - this causes the call to compute the next solution.
	loop(Cont, _Stack, _ContOut) :-
		var(Cont), !,
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
		jupyter_term_handling::handle_term(Term, false, CallRequestId, Stack, Variables, Cont).
	handle_next_term_or_request(Stack, Cont) :-
		% All terms of the current request have been processed -> send their results to the client
		request_data(_CallRequestId, []),
		!,
		send_responses,
		% Read the next request
		jupyter_jsonrpc::next_jsonrpc_message(Message),
		dispatch_message(Message, Stack, Cont).
	handle_next_term_or_request(Stack, Cont) :-
		% First request
		% Read and handle the next request from the client
		jupyter_jsonrpc::next_jsonrpc_message(Message),
		dispatch_message(Message, Stack, Cont).


	% Get all term responses which were asserted as term_response(JsonResponse).
	% Send a json response object where
	% - the keys are the indices of the Prolog terms from the request starting from 1
	% - the values are json objects representing the result of the corresponding Prolog term
	send_responses :-
		% Retract all data of the current request
		retract(request_data(CallRequestId, _)),
		% Use catch/3, because no clauses might have been asserted
		catch(jupyter_term_handling::retractall(pred_definition_specs(_)), _, true),
		% If any declarations were made by the current request, load the corresponding file(s)
		declaration_end(true),
		% Collect the responses and send them to the client
		term_responses(1, TermResponses),
		send_success_reply(CallRequestId, json(TermResponses)).


	% term_responses(+CurrentNum, -TermResponses)
	term_responses(Num, [NumAtom-Response|TermResponses]) :-
		term_response(Response),
		retract(term_response(Response)),
		!,
		number_codes(Num, NumCodes),
		atom_codes(NumAtom, NumCodes),
		NextNum is Num+1,
		term_responses(NextNum, TermResponses).
	term_responses(_Num, []).


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
		jupyter_jsonrpc::send_error_reply(@(null), invalid_request, '').


	% dispatch_request(+Method, +Message, +Stack, -Cont)
	%
	% Checks the request method and handles the request accordingly.
	dispatch_request(call, Message, Stack, Cont) :-
		!,
		Message = request(_Method,CallRequestId,Params,_RPC),
		jupyter_jsonrpc::parse_json_terms_request(Params, TermsAndVariables, ParsingErrorMessageData),
		(	var(TermsAndVariables) ->
			!,
			% An error occurred when parsing the json request
			handle_parsing_error(ParsingErrorMessageData, CallRequestId),
			Cont = continue
		;	TermsAndVariables = [] ->
			!,
			% The request does not contain any term
			jupyter_jsonrpc::send_success_reply(CallRequestId, ''),
			Cont = continue
		;	TermsAndVariables = [Term-Variables] ->
			!,
			% The request contains one term
			% Normally this is a goal which is to be evaluated
			assertz(request_data(CallRequestId, [])),
			jupyter_term_handling::handle_term(Term, true, CallRequestId, Stack, Variables, Cont)
		;	% The request contains multiple terms
			% Process the first term and assert the remaining ones
			% This is needed so that "retry." terms can fail into the previous call
			TermsAndVariables = [Term-Variables|RemainingTermsAndVariables],
			assertz(request_data(CallRequestId, RemainingTermsAndVariables)),
			jupyter_term_handling::handle_term(Term, false, CallRequestId, Stack, Variables, Cont)
		).
	dispatch_request(dialect, Message, _Stack, continue) :-
		!,
		% Send the SICStus version to the client
		Message = request(_Method,CallRequestId,_Params,_RPC),
		current_prolog_flag(dialect, Dialect),
		jupyter_jsonrpc::send_success_reply(CallRequestId, Dialect).
	dispatch_request(enable_logging, Message, _Stack, continue) :-
		!,
		% Create a log file
		Message = request(_Method,CallRequestId,_Params,_RPC),
		jupyter_logging::create_log_file(IsSuccess),
		jupyter_jsonrpc::send_success_reply(CallRequestId, IsSuccess).
	dispatch_request(version, Message, _Stack, continue) :-
		!,
		% Send the backend version to the client
		Message = request(_Method,CallRequestId,_Params,_RPC),
		current_logtalk_flag(prolog_version, v(Major,Minor,Revision)),
		format_to_codes('~d.~d.~d', [Major, Minor, Revision], VersionCodes),
		atom_codes(VersionAtom, VersionCodes),
		jupyter_jsonrpc::send_success_reply(CallRequestId, VersionAtom).
	dispatch_request(jupyter_predicate_docs, Message, _Stack, continue) :-
		% Retrieve the docs of the predicates in the module jupyter and send them to the client
		Message = request(_Method,CallRequestId,_Params,_RPC),
		!,
		jupyter::predicate_docs(PredDocs),
		jupyter_jsonrpc::send_success_reply(CallRequestId, json(PredDocs)).
	dispatch_request(Method, Message, _Stack, continue) :-
		% Make sure that a 'retry' call can fail
		Method \= call,
		Message = request(_,Id,_Params,_RPC), !,
		jupyter_jsonrpc::send_error_reply(Id, method_not_found, '').


	% handle_parsing_error(+ParsingErrorMessageData, +CallRequestId)
	handle_parsing_error(ParsingErrorMessageData, CallRequestId) :-
		nonvar(ParsingErrorMessageData),
		!,
		% Parsing error when reading the terms from the request
		retrieve_message(ParsingErrorMessageData, ErrorMessage),
		jupyter_jsonrpc::send_error_reply(CallRequestId, exception, ErrorMessage).
	handle_parsing_error(_ParsingErrorMessageData, CallRequestId) :-
		% Malformed request
		jupyter_jsonrpc::send_error_reply(CallRequestId, invalid_params, '').

:- end_object.