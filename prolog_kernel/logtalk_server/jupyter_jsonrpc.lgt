
% This module handles all reading, writing, and parsing of JSON messages.
% It is based on jsonrpc_server.pl and jsonrpc_client.pl from SICStus 4.5.1


:- object(jupyter_jsonrpc).

	:- public([
		json_error_term/5,           % json_error_term(+ErrorCode, +ErrorMessageData, +Output, +AdditionalData, -JsonErrorTerm)
		next_jsonrpc_message/1,      % next_jsonrpc_message(-Message)
		parse_json_terms_request/3,  % parse_json_terms_request(+Params, -TermsAndVariables, -ParsingErrorMessageData)
		send_error_reply/3,          % send_error_reply(+Id, +ErrorCode, +ErrorMessage)
		send_json_request/6,         % send_json_request(+Method, +Params, +Id, +InputStream, +OutputStream, -Reply)
		send_success_reply/2         % send_success_reply(+Id, +Result)
	]).

	:- uses(list, [append/3, member/2]).
	:- uses(os, [null_device_path/1]).
	:- uses(user, [open(File,read,Stream) as open_codes_stream(File,Stream)]).
	:- uses(jupyter_query_handling, [retrieve_message/2]).
	:- uses(jupyter_logging, [log/1, log/2]).

	:- uses(json(codes), [
		generate(stream(Stream),Term) as json_write(Stream,Term),
		parse(stream(Stream),Term) as json_read(Stream,Term)
	]).

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Create JSON-RPC objects


	% Create a JSON-RPC Request object (http://www.jsonrpc.org/specification#request_object)
	jsonrpc_request(Method, Params, Id, json([jsonrpc-'2.0',id-Id,method-Method,params-Params])).

	jsonrpc_request(Method, Id, json([jsonrpc-'2.0',id-Id,method-Method])).


	% Create a JSON-RPC success Response object (http://www.jsonrpc.org/specification#response_object)
	jsonrpc_response(Result, Id, json([jsonrpc-'2.0',id-Id,result-Result])).


	% Create a JSON-RPC error Response object (http://www.jsonrpc.org/specification#response_object)
	jsonrpc_error_response(Error, Id, json([jsonrpc-'2.0',id-Id,error-Error])).

	% Create a JSON-RPC error Response object (http://www.jsonrpc.org/specification#response_object)
	jsonrpc_error_response(Error, json([jsonrpc-'2.0',id- @(null),error-Error])).


	% Create a JSON-RPC Error object (http://www.jsonrpc.org/specification#error_object)
	jsonrpc_error(Code, Message, Data, json([code-Code,message-Message,data-Data])).

	% Create a JSON-RPC Error object (http://www.jsonrpc.org/specification#error_object)
	jsonrpc_error(Code, Message, json([code-Code,message-Message])).


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% json_error_term(+ErrorCode, +ErrorMessageData, +Output, +AdditionalData, -JsonErrorTerm)
	%
	% ErrorCode is one of the error codes defined by error_object_code/3 (e.g. exception).
	% ErrorMessageData is a term of the form message_data(Kind, Term) so that the acutal error message can be retrieved with print_message(Kind, Term)
	% Output is the output of the term which was executed.
	% AdditionalData is a list containing Key-Value pairs providing additional data for the client.
	json_error_term(ErrorCode, ErrorMessageData, Output, AdditionalData, JsonErrorTerm) :-
		jupyter_query_handling::retrieve_message(ErrorMessageData, PrologMessage),
		error_data(PrologMessage, Output, AdditionalData, ErroData),
		error_object_code(ErrorCode, NumericErrorCode, JsonRpcErrorMessage),
		jsonrpc_error(NumericErrorCode, JsonRpcErrorMessage, ErroData, JsonErrorTerm).


	% error_data(+PrologMessage, +Output, +AdditionalData, -ErrorData)
	error_data(PrologMessage, Output, AdditionalData, json([prolog_message-PrologMessage|AdditionalData])) :-
		var(Output),
		!.
	error_data(PrologMessage, '', AdditionalData, json([prolog_message-PrologMessage|AdditionalData])) :- !.
	error_data(PrologMessage, Output, AdditionalData, json([prolog_message-PrologMessage, output-Output|AdditionalData])).


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Send responses

	% send_success_reply(+Id, +Result)
	send_success_reply(Id, Result) :-
		nonvar(Id),
		!,
		jsonrpc_response(Result, Id, JSONResponse),
		write_message(JSONResponse).


	% send_error_reply(+Id, +ErrorCode, +PrologMessage)
	%
	% ErrorCode is one of the error codes defined by error_object_code/3 (e.g. exception).
	% PrologMessage is an error message as output by print_message/2.
	send_error_reply(Id, ErrorCode, PrologMessage) :-
		error_object_code(ErrorCode, NumericErrorCode, JsonRpcErrorMessage),
		json_error_term(NumericErrorCode, JsonRpcErrorMessage, json([prolog_message-PrologMessage]), RPCError),
		jsonrpc_error_response(RPCError, Id, RPCResult),
		write_message(RPCResult).


	% json_error_term(+NumericErrorCode, +JsonRpcErrorMessage, +Data, -RPCError)
	json_error_term(NumericErrorCode, JsonRpcErrorMessage, Data, RPCError) :-
		nonvar(Data),
		!,
		jsonrpc_error(NumericErrorCode, JsonRpcErrorMessage, Data, RPCError).
	json_error_term(NumericErrorCode, JsonRpcErrorMessage, _Data, RPCError) :-
		jsonrpc_error(NumericErrorCode, JsonRpcErrorMessage, RPCError).


	% error_object_code(+Name, -Code)
	error_object_code(Name, Code) :-
		error_object_code(Name, Code, _Description).

	% error_object_code(ErrorCode, NumericErrorCode, JsonRpcErrorMessage)
	%
	% Pre-defined errorserror_object_code(parse_error, -32700, 'Invalid JSON was received by the server.').
	error_object_code(invalid_request, -32600, 'The JSON sent is not a valid Request object.').
	error_object_code(method_not_found, -32601, 'The method does not exist / is not available.').
	error_object_code(invalid_params, -32602, 'Invalid method parameter(s).').
	error_object_code(internal_error, -32603, 'Internal JSON-RPC error.').
	% Prolog specific errors
	error_object_code(failure, -4711, 'Failure').
	error_object_code(exception, -4712, 'Exception').
	error_object_code(no_active_call, -4713, 'No active call').
	error_object_code(invalid_json_response, -4714, 'The Response object is no valid JSON object').
	error_object_code(unhandled_exception, -4715, 'Unhandled exception').


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Send json request and read the response

	% send_json_request(+Method, +Params, +Id, +InputStream, +OutputStream, -Reply)
	%
	% Sends a request by writing it to the input stream and reads the response from the output stream.
	% Used for the tests in jupyter_server_tests.pl.
	send_json_request(Method, Params, Id, InputStream, OutputStream, Reply) :-
		jsonrpc_request(Method, Params, Id, Request),
		% Send the request
		json_write(InputStream, Request),
		nl(InputStream),
		flush_output(InputStream),
		% Read the response
		json_read(OutputStream, Reply).


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Read and write json messages

	% next_jsonrpc_message(-Message)
	%
	% Reads the next message from the standard input stream and parses it.
	next_jsonrpc_message(Message) :-
		read_message(RPC),
		parse_message(RPC, Message).

	% read_message(-JsonRpcMessage)
	read_message(JsonRpcMessage) :-
		current_input(In),
		json_read(In, JsonRpcMessage).

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
		jupyter_logging::log(JSON),
		% If sending the JSON message to the client directly fails (because the term JSON might not be parsable to JSON),
		%  the client would receive an imcomplete message.
		% Instead, try writing JSON to a file and send an error reply if this fails.
		% Otherwise, send the JSON message to the client.
		null_device_path(NullPath),
		open(NullPath, write, NullStream),
		catch(json_write(NullStream, JSON), Exception, true),
		close(NullStream),
		(	nonvar(Exception) ->
			send_error_reply(@(null), invalid_json_response, '')
		;	current_output(Out),
			json_write(Out, JSON),
			% Terminate the line (assuming single-line output).
%			nl(Out),
			flush_output(Out)
		).


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Parse json messages

	% parse_json_terms_request(+Params, -TermsAndVariables, -ParsingErrorMessageData)
	%
	% Reads Prolog terms from the given 'code' string in Params.
	% In general, the code needs to be valid Prolog syntax.
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
	% The atom TermsAtom should form valid Prolog term syntax (the last term does not need to be terminated by a full-stop).
	% Reads all Prolog terms from TermsAtom.
	% TermsAndVariables is a list with elements of the form Term-Variables.
	% Variables is a list of variable name and variable mappings (of the form [Name-Var, ...]) which occur in the corresponding term Term.
	% ParsingErrorMessageData is instantiated to a term of the form message_data(Kind, Term) if a syntax error was encountered when reading the terms.
	% ParsingErrorMessageData can be used to print the actual error message with print_message(Kind, Term).
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
		->	% No valid Prolog syntax
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
		open_codes_stream(Codes, Stream),
		(	catch(
				read_terms_and_vars(Stream, TermsAndVariables),
				Exception,
				(close(Stream), ParsingErrorMessageData = message_data(error, Exception))
			) ->
			close(Stream)
		;	close(Stream),
			fail
		).


	% read_terms_and_vars(+Stream, -TermsAndVariables)
	read_terms_and_vars(Stream, NewTermsAndVariables) :-
		read_term(Stream, Term, [variable_names(Variables)]),
		(	Term == end_of_file ->
			NewTermsAndVariables = []
		;	NewTermsAndVariables = [Term-Variables|TermsAndVariables],
			read_terms_and_vars(Stream, TermsAndVariables)
		).


	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
