
:- object(jupyter_logging).

	:- info([
		version is 0:1:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2022-11-12,
		comment is 'Logging support.'
	]).

	:- public([
		create_log_file/1,  % create_log_file(-IsSuccess)
		log/1,              % log(+Term)
		log/2               % log(+Control, +Arguments)
	]).

	:- uses(format, [format/3]).
	:- uses(list, [valid/1 as is_list/1]).

	% create_log_file(-IsSuccess)
	create_log_file(true) :-
		% Open a log file (jupyter_logging to stdout would send the messages to the client)
		% On Windows platforms, opening a file with SICStus which is alread opened by another process (i.e. another Prolog server) fails
		% Therefore separate log files are created for each Prolog backend
		current_logtalk_flag(prolog_dialect, Dialect),
		atom_concat('.logtalk_server_log_', Dialect, LogFileName),
		catch(open(LogFileName, write, _Stream, [alias(log_stream)]), _Exception, fail),
		!.
	create_log_file(false).
	% No new log file could be opened

	log(List) :-
		is_list(List),
		!,
		log('~w~n', [List]).
	log(Term) :-
		log('~w~n', Term).

	log(Format, Arguments) :-
		% Write to the log file
		stream_property(_, alias(log_stream)),
		!,
		format(log_stream, Format, Arguments),
		flush_output(log_stream).
	log(_Control, _Arguments).
	% No new log file could be opened

:- end_object.
