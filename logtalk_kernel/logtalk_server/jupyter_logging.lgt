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


:- object(jupyter_logging).

	:- info([
		version is 0:2:0,
		author is 'Anne Brecklinghaus, Michael Leuschel, and Paulo Moura',
		date is 2025-03-05,
		comment is 'Logging support.'
	]).

	:- public(create_log_file/1).
	:- mode(create_log_file(-boolean), zero_or_one).
	:- info(create_log_file/1, [
		comment is 'Creates a log file if possible. Each running backend uses its own log file.',
		argnames is ['IsSuccess']
	]).

	:- public(log/1).
	:- mode(log(@term), one).
	:- info(log/1, [
		comment is 'Logs a term.',
		argnames is ['Term']
	]).

	:- public(log/2).
	:- mode(log(+atom, @term), one).
	:- info(log/2, [
		comment is 'Logs arguments after the given format.',
		argnames is ['Format', 'Arguments']
	]).

	:- uses(format, [format/3]).

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

	log(Term) :-
		log('~w~n', [Term]).

	log(Format, Arguments) :-
		% Write to the log file
		stream_property(_, alias(log_stream)),
		!,
		format(log_stream, Format, Arguments),
		flush_output(log_stream).
	log(_Control, _Arguments).
	% No new log file could be opened

:- end_object.
