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


:- object(jupyter_jsonrpc).

	:- info([
		version is 0:3:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2025-03-10,
		comment is 'This object andles all reading, writing, and parsing of JSON messages. It is based on jsonrpc_server.pl and jsonrpc_client.pl from SICStus 4.5.1.'
	]).

	:- public(json_error_term/5).
	:- mode(json_error_term(+integer, +compound, +atom, +list(pair), -json), one).
	:- info(json_error_term/5, [
		comment is 'Returns a JSON representation of the given error.',
		argnames is ['ErrorCode', 'ErrorMessageData', 'Output', 'AdditionalData', 'JsonErrorTerm']
	]).

	:- public(next_jsonrpc_message/1).
	:- mode(next_jsonrpc_message(-json), one).
	:- info(next_jsonrpc_message/1, [
		comment is 'Returns the next JSON-RPC message.',
		argnames is ['Message']
	]).

	:- public(parse_json_terms_request/3).
	:- mode(parse_json_terms_request(+json, -list(pair), -compound), one).
	:- info(parse_json_terms_request/3, [
		comment is 'Parses a JSON message.',
		argnames is ['Params', 'TermsAndVariables', 'ParsingErrorMessageData']
	]).

	:- public(send_error_reply/3).
	:- mode(send_error_reply(+integer, +integer, +atom), one).
	:- info(send_error_reply/3, [
		comment is 'Sends an error reply.',
		argnames is ['Id', 'ErrorCode', 'ErrorMessage']
	]).

	:- public(send_json_request/6).
	:- mode(send_json_request(+atom, +list, +integer, +stream_or_alias, +stream_or_alias, -json), one).
	:- info(send_json_request/6, [
		comment is 'Sends a JSON request by writing it to the input stream and reading the response from the output stream.',
		argnames is ['Method', 'Params', 'Id', 'InputStream', 'OutputStream', 'Reply']
	]).

	:- public(send_success_reply/2).
	:- mode(send_success_reply(+integer, +nonvar), one).
	:- info(send_success_reply/2, [
		comment is 'Sends a successful request result.',
		argnames is ['Id', 'Result']
	]).

	:- uses(list, [append/3, member/2]).
	:- uses(os, [null_device_path/1]).
	:- uses(term_io, [read_term_from_codes/4, write_term_to_atom/3]).
	:- uses(jupyter_query_handling, [retrieve_message/2]).
	:- uses(jupyter_logging, [log/1]).
	:- uses(json(list,dash,atom), [
		generate(stream(Stream),JSON) as json_write(Stream,JSON),
		parse(line(Stream),JSON) as json_read(Stream,JSON)
	]).

	% Create JSON-RPC objects

	% Create a JSON-RPC Request object (http://www.jsonrpc.org/specification#request_object)
	jsonrpc_request(Method, Params, Id, json([jsonrpc-'2.0',id-Id,method-Method,params-Params])).

	% Create a JSON-RPC success Response object (http://www.jsonrpc.org/specification#response_object)
	jsonrpc_response(Result, Id, json([jsonrpc-'2.0',id-Id,result-Result])).

	% Create a JSON-RPC error Response object (http://www.jsonrpc.org/specification#response_object)
	jsonrpc_error_response(Error, Id, json([jsonrpc-'2.0',id-Id,error-Error])).

	% Create a JSON-RPC Error object (http://www.jsonrpc.org/specification#error_object)
	jsonrpc_error(Code, Message, Data, json([code-Code,message-Message,data-Data])).

	% Create a JSON-RPC Error object (http://www.jsonrpc.org/specification#error_object)
	jsonrpc_error(Code, Message, json([code-Code,message-Message])).


	% json_error_term(+ErrorCode, +ErrorMessageData, +Output, +AdditionalData, -JsonErrorTerm)
	%
	% ErrorCode is one of the error codes defined by error_object_code/3 (e.g. exception).
	% ErrorMessageData is a term of the form message_data(Kind, Term) so that the actual error message can be retrieved with print_message(Kind, jupyter, Term)
	% Output is the output of the term which was executed.
	% AdditionalData is a list containing Key-Value pairs providing additional data for the client.
	json_error_term(ErrorCode, ErrorMessageData, Output, AdditionalData, JsonErrorTerm) :-
		jupyter_query_handling::retrieve_message(ErrorMessageData, LogtalkMessage),
		error_data(LogtalkMessage, Output, AdditionalData, ErrorData),
		error_object_code(ErrorCode, NumericErrorCode, JsonRpcErrorMessage),
		jsonrpc_error(NumericErrorCode, JsonRpcErrorMessage, ErrorData, JsonErrorTerm).


	% error_data(+LogtalkMessage, +Output, +AdditionalData, -ErrorData)
	error_data(LogtalkMessage, Output, AdditionalData, json([logtalk_message-LogtalkMessage|AdditionalData])) :-
		var(Output),
		!.
	error_data(LogtalkMessage, '', AdditionalData, json([logtalk_message-LogtalkMessage|AdditionalData])) :- !.
	error_data(LogtalkMessage, Output, AdditionalData, json([logtalk_message-LogtalkMessage, output-Output|AdditionalData])).


	% Send responses

	send_success_reply(Id, Result) :-
		nonvar(Id),
		!,
		jsonrpc_response(Result, Id, JSONResponse),
		write_message(JSONResponse).


	% send_error_reply(+Id, +ErrorCode, +LogtalkMessage)
	%
	% ErrorCode is one of the error codes defined by error_object_code/3 (e.g. exception).
	% LogtalkMessage is an error message as output by print_message/3.
	send_error_reply(Id, ErrorCode, LogtalkMessage) :-
		error_object_code(ErrorCode, NumericErrorCode, JsonRpcErrorMessage),
		json_error_term(NumericErrorCode, JsonRpcErrorMessage, json([logtalk_message-LogtalkMessage]), RPCError),
		jsonrpc_error_response(RPCError, Id, RPCResult),
		write_message(RPCResult).


	% json_error_term(+NumericErrorCode, +JsonRpcErrorMessage, +Data, -RPCError)
	json_error_term(NumericErrorCode, JsonRpcErrorMessage, Data, RPCError) :-
		nonvar(Data),
		!,
		jsonrpc_error(NumericErrorCode, JsonRpcErrorMessage, Data, RPCError).
	json_error_term(NumericErrorCode, JsonRpcErrorMessage, _Data, RPCError) :-
		jsonrpc_error(NumericErrorCode, JsonRpcErrorMessage, RPCError).


	% error_object_code(ErrorCode, NumericErrorCode, JsonRpcErrorMessage)
	%
	% Pre-defined errorserror_object_code(parse_error, -32700, 'Invalid JSON was received by the server.').
	error_object_code(invalid_request,       -32600, 'The JSON sent is not a valid Request object.').
	error_object_code(method_not_found,      -32601, 'The method does not exist / is not available.').
	error_object_code(invalid_params,        -32602, 'Invalid method parameter(s).').
	error_object_code(internal_error,        -32603, 'Internal JSON-RPC error.').
	% Prolog specific errors
	error_object_code(failure,               -4711, 'Failure').
	error_object_code(exception,             -4712, 'Exception').
	error_object_code(no_active_call,        -4713, 'No active call').
	error_object_code(invalid_json_response, -4714, 'The Response object is no valid JSON object').
	error_object_code(unhandled_exception,   -4715, 'Unhandled exception').


	send_json_request(Method, Params, Id, InputStream, OutputStream, Reply) :-
		jsonrpc_request(Method, Params, Id, Request),
		% Send the request
		json_write(InputStream, Request),
		nl(InputStream),
		flush_output(InputStream),
		% Read the response
		json_read(OutputStream, Reply).


	% Read and write json messages

	% next_jsonrpc_message(-Message)
	%
	% Reads the next message from the standard input stream and parses it.
	next_jsonrpc_message(Message) :-
		read_message(RPC),
		parse_message(RPC, Message).

	% read_message(-JsonRpcMessage)
	:- if(current_logtalk_flag(prolog_dialect, eclipse)).

		read_message(JsonRpcMessage) :-
			current_input(In),
			(	at_end_of_stream(In) ->
				peek_code(In, _)
			;	true
			),
			json_read(In, JsonRpcMessage).

		flush_message(Stream) :-
			% write lf instead of crlf always (allows running on Windows)
			set_stream_property(Stream, end_of_line, lf),
			% Terminate the line (assuming single-line output).
			nl(Stream),
			flush_output(Stream).

	:- else.

		read_message(JsonRpcMessage) :-
			current_input(In),
			json_read(In, JsonRpcMessage).

		flush_message(Stream) :-
			% Terminate the line (assuming single-line output).
			nl(Stream),
			flush_output(Stream).

	:- endif.

	% parse_message(+RPC, -Message)
	parse_message(RPC, Message) :-
		json_member(RPC, 'method', Method),
		json_member(RPC, 'id', _NoId, Id),
		json_member(RPC, 'params', [], Params),
		!,
		Message = request(Method,Id,Params,RPC).
	parse_message(RPC, Message) :-
		% RPC is not valid JSON-RPC 2.0
		Message = invalid(RPC).


	% write_message(+JSON)
	write_message(JSON) :-
		log(JSON),
		% If sending the JSON message to the client directly fails (because the term JSON might not be parsable to JSON),
		%  the client would receive an incomplete message.
		% Instead, try writing JSON to a file and send an error reply if this fails.
		% Otherwise, send the JSON message to the client.
		null_device_path(NullPath),
		open(NullPath, write, NullStream),
		catch(json_write(NullStream, JSON), Exception, true),
		close(NullStream),
		(	nonvar(Exception) ->
			write_term_to_atom(Exception, ExceptionAtom, [quoted(true)]),
			send_error_reply(@(null), invalid_json_response, ExceptionAtom)
		;	current_output(Out),
			json_write(Out, JSON),
			flush_message(Out)
		).


	% Parse json messages

	% parse_json_terms_request(+Params, -TermsAndVariables, -ParsingErrorMessageData)
	%
	% Reads terms from the given 'code' string in Params.
	% In general, the code needs to be valid Logtalk syntax.
	% However, if a missing terminating full-stop causes the only syntax error (in case of SICStus Prolog), the terms can be parsed anyway.
	% Does not bind TermsAndVariables if the code parameter in Params is malformed or if there is an error when reading the terms.
	% If an error occurred while reading Prolog terms from the 'code' parameter, ParsingErrorMessageData is bound.
	parse_json_terms_request(Params, TermsAndVariables, ParsingErrorMessageData) :-
		Params = json(_),
		json_member(Params, code, GoalSpec),
		atom(GoalSpec),
		!,
		terms_from_atom(GoalSpec, TermsAndVariables, ParsingErrorMessageData).
	parse_json_terms_request(_Params, _TermsAndVariables, _ParsingErrorMessageData).


	% terms_from_atom(+TermsAtom, -TermsAndVariables, -ParsingErrorMessageData)
	%
	% The atom TermsAtom should form valid Logtalk term syntax (the last term does not need to be terminated by a full-stop).
	% Reads all terms from TermsAtom.
	% TermsAndVariables is a list with elements of the form Term-Variables.
	% Variables is a list of variable name and variable mappings (of the form [Name-Var, ...]) which occur in the corresponding term Term.
	% ParsingErrorMessageData is instantiated to a term of the form message_data(Kind, Term) if a syntax error was encountered when reading the terms.
	% ParsingErrorMessageData can be used to print the actual error message with print_message(Kind, jupyter, Term).
	% In case of a syntax error, TermsAndVariables is left unbound.
	%
	% Examples:
	% - terms_from_atom("hello(world).", [hello(world)-[]], _ParsingError).
	% - terms_from_atom("member(E, [1,2,3]).", [member(_A,[1,2,3])-['E'-_A]], _ParsingError).
	% - terms_from_atom("hello(world)", _TermsAndVariables, parsing_error(error(syntax_error('operator expected after expression'),syntax_error(read_term('$stream'(140555796879536),_A,[variable_names(_B)]),1,'operator expected after expression',[atom(hello)-1,'('-1,atom(world)-1,')'-1],0)),'! Syntax error in read_term/3\n! operator expected after expression\n! in line 1\n! hello ( world ) \n! <<here>>')).

	terms_from_atom(TermsAtom, TermsAndVariables, ParsingErrorMessageData) :-
		atom_codes(TermsAtom, GoalCodes),
		% Try reading the terms from the codes
		terms_from_codes(GoalCodes, TermsAndVariables, ParsingErrorMessageData),
		(	nonvar(ParsingErrorMessageData)
		->	% No valid Logtalk syntax
			% The error might have been caused by a missing terminating full-stop
			(	append(_, [46], GoalCodes) % NOTE: the dot could be on a comment line.
			;	% If the last code of the GoalCodes list does not represent a full-stop, add one and try reading the term(s) again
				append(GoalCodes, [10, 46], GoalCodesWithFullStop), % The last line might be a comment -> add a new line code as well
				terms_from_codes(GoalCodesWithFullStop, TermsAndVariables, _NewParsingErrorMessageData)
			)
		;	true
		).

	% terms_from_codes(+Codes, -TermsAndVariables, -ParsingErrorMessageData)
	terms_from_codes(Codes, TermsAndVariables, ParsingErrorMessageData) :-
		catch(
			read_terms_and_vars(Codes, TermsAndVariables),
			Exception,
			ParsingErrorMessageData = message_data(error, Exception)
		).

	% read_terms_and_vars(+Codes, -TermsAndVariables)
	read_terms_and_vars(Codes, NewTermsAndVariables) :-
		read_term_from_codes(Codes, Term, Tail, [variable_names(Variables)]),
		(	Term == end_of_file ->
			NewTermsAndVariables = []
		;	NewTermsAndVariables = [Term-Variables|TermsAndVariables],
			read_terms_and_vars(Tail, TermsAndVariables)
		).

	% json_member(+Object, +Name, -Value)
	%
	% If Object is a JSON object, with a member named Name, then bind Value to the corresponding value.
	% Otherwise, fail.
	json_member(Object, Name, Value) :-
		nonvar(Object),
		Object = json(Members),
		member(Name-V, Members),
		!,
		Value = V.

	% json_member(+Object, +Name, +Default, -Value)
	%
	% If Object is a JSON object, with a member named Name, then bind Value to the corresponding value.
	% Otherwise, e.g. if there is no such member or Object is not an object, bind Value to Default.
	json_member(Object, Name, _Default, Value) :-
		nonvar(Object),
		Object = json(Members),
		member(Name-V, Members),
		!,
		Value = V.
	json_member(_Object, _Name, Default, Value) :-
		Value = Default.

:- end_object.
