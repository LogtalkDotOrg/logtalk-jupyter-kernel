
:- object(jupyter_logging).

	:- info([
		version is 0:1:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2022-11-11,
		comment is 'Logging support.'
	]).

	:- public([
		create_log_file/1,  % create_log_file(-IsSuccess)
		log/1,              % log(+Term)
		log/2               % log(+Control, +Arguments)
	]).

	:- private(log_stream/1).
	:- dynamic(log_stream/1).

	:- uses(format, [format/3]).
	:- uses(list, [valid/1 as is_list/1]).

	% create_log_file(-IsSuccess)
	create_log_file(true) :-
		% Open a log file (jupyter_logging to stdout would send the messages to the client)
		% On Windows platforms, opening a file with SICStus which is alread opened by another process (i.e. another Prolog server) fails
		% Therefore separate log files are created for each Prolog backend
		current_logtalk_flag(prolog_dialect, Dialect),
		atom_concat('.logtalk_server_log_', Dialect, LogFileName),
		catch(open(LogFileName, write, Stream), _Exception, fail),
		!,
		assertz(log_stream(Stream)).
	create_log_file(false).
	% No new log file could be opened

	log(List) :-
		is_list(List),
		!,
		log('~w~n', [List]).
	log(Term) :-
		log('~w~n', Term).

	log(Control, Arguments) :-
		% Write to the log file
		log_stream(Stream),
		!,
		format(Stream, Control, Arguments),
		flush_output(Stream).
	log(_Control, _Arguments).
	% No new log file could be opened

:- end_object.
