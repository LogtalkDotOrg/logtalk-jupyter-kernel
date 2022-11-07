
% This is the main module of the SICStus server.
% The predicate jupyter_server_start/0 can be called to start the server which enters a loop handling requests from a client.
% The requests and corresponding replies are JSON-RPC 2.0 (https://www.jsonrpc.org/specification) messages sent over the standard streams.
% The handling of those is based on code from 'jsonrpc_server.pl' from SICStus 4.5.1


:- object(jupyter_server).

	:- public([
		jupyter_server_start/0,
     	jupyter_server_start/1
	]).

	:- uses(jupyter_logging, [log/1, log/2]).
	:- uses(jupyter, []).
	:- uses(jupyter_request_handling, [loop/3]).
	:- uses(jupyter_term_handling, [assert_sld_data/4]).
	:- uses(jupyter_preferences, [set_preference/2]).

	jupyter_server_start :-
		jupyter_server_start(1).

	jupyter_server_start(JupyterKernelVerbosityLevel) :-
		setup,
		set_preference(verbosity,JupyterKernelVerbosityLevel), % useful for testing purposes
		% Start the loop handling requests from the client
		jupyter_request_handling::loop(continue, [], _ContOut).

	setup :-
		% The tests in jupyter_server_tests.pl need to be started without printing informational messages
		% In order for those messages to be printed during an execution, a corresponding Prolog flag has to be set
		set_logtalk_flag(report, on).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Handle error messages which might be sent by the sub modules

	:- multifile(logtalk::message_tokens//2).
	logtalk::message_tokens(jupyter(JupyterMessageTerm), _) -->
		juypter_message(JupyterMessageTerm).


	juypter_message(goal_failed(Goal)) -->
		['~w - goal failed'-[Goal]], [nl].

	juypter_message(invalid_table_values_lists_length) -->
		['The values lists need to be of the same length'-[]], [nl].
	juypter_message(invalid_table_variable_names) -->
		['The list of names needs to be empty or of the same length as the values lists and contain ground terms only'-[]], [nl].
	juypter_message(leash_pred) -->
		['The leash mode cannot be changed in a Jupyter application as no user interaction can be provided at a breakpoint'-[]], [nl].
	juypter_message(no_single_goal(Predicate)) -->
		['~w needs to be the only goal in a term'-[Predicate]], [nl].
	juypter_message(print_transition_graph_indices(Arity)) -->
		['All indices need to be less or equal to the provided predicate arity ~w'-[Arity]], [nl].
	juypter_message(print_transition_graph_pred_spec(PredSpec)) -->
		['Incorrect predicate specification: ~w'-[PredSpec]], [nl],
		['It needs to be of the form PredName/PredArity or Module:PredName/PredArity'-[]], [nl].
	juypter_message(prolog_impl_id_no_atom) -->
		['The Prolog implementation ID needs to be an atom'-[]], [nl].
	juypter_message(single_test_directive) -->
		['The definition of a unit test cannot be split across multiple cells'-[]], [nl].
	juypter_message(trace_pred(TracePredSpec)) -->
		['~w cannot be used in a Jupyter application'-[TracePredSpec]], [nl],
		['However, there is juypter:trace(Goal)'-[]], [nl].
	juypter_message(no_answer_given) -->
		% Used for the code stub for manually graded tasks of nbgrader assignments
		['No answer given'-[]], [nl].

:- end_object.
