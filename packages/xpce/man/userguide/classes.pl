/*  $Id$

    Part of XPCE --- The SWI-Prolog GUI toolkit

    Author:        Jan Wielemaker and Anjo Anjewierden
    E-mail:        jan@swi.psy.uva.nl
    WWW:           http://www.swi.psy.uva.nl/projects/xpce/
    Copyright (C): 1985-2002, University of Amsterdam

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

:- module(classdoc,
	  [ process/2
	  ]).

:- use_module(library(pce_manual)).
:- pce_autoload(man_inheritance_tree, library('man/v_inherit')).

process(In, Out) :-
	manpce,
	send(@display, font_alias, normal, font(times, roman,  10), @on),
	send(@display, font_alias, bold,   font(times, bold,   10), @on),
	send(@display, font_alias, italic, font(times, italic, 10), @on),
	new(FIN, file(In)),
	new(FOUT, file(Out)),
	send(FIN, open, read),
	send(FOUT, open, write),
	do_process(FIN, FOUT),
	send(FIN, close),
	send(FOUT, close).

do_process(In, Out) :-
	between(1, 1000000, LineNo),
	(   get(In, read_line, Line)
	->  (   get(Line, character, 0, 0'#)
	    ->  get(Line, value, LineAtom),
	        atom_codes(LineAtom, LineChars),
		process_line(LineChars, LineNo, Converted),
		atom_codes(ConvertedAtom, Converted),
		send(Out, format, '%s', ConvertedAtom)
	    ;   send(Out, format, '%s', Line)
	    ),
	    fail
        ;   !
	),
	make_diagrams('figs/class'),
	no_summary.

:- dynamic
	diagram/3.			% LineNo, file, classes

need_diagram(Class, _, Line, '*') :-
	PrevLine is Line - 1,
	retract(diagram(PrevLine, File, Classes0)), !,
	append(Classes0, [Class], Classes),
	asserta(diagram(Line, File, Classes)).
need_diagram(Class, File, Line, '') :-
	asserta(diagram(Line, File, [Class])).

make_diagrams(Dir) :-
	diagram(_, File, Classes),
	    format('(~w', [Classes]), flush,
	    new(I, man_inheritance_tree),
	    send(I, level_gap, 15),
	    forall(member(C, Classes), send(I, show, C, @off)),
	    send(I, compute),
	    file_name_extension(File, eps, PsFile),
	    get(directory(Dir), file, PsFile, F),
	    send(F, open, write),
	    send(F, append, I?postscript),
	    send(F, close),
	    format(') ', []), flush,
	fail ; true.

no_summary :-
	findall(X, diagram(_,_,X), Xs),
	flatten(Xs, Flat),
	sort(Flat, Done),
	new(S, chain),
	send(@classes, for_all,
	     if(@arg2?creator == built_in,
		message(S, append, @arg1))),
	send(S, sort),
	send(S, subtract, Done),
	(   send(S, empty)
	->  true
	;   format('The following classes have no summary:~n'),
	    send(S, for_all, message(@pce, format, '\t%s\n', @arg1))
	).

process_line(In, LineNo, Out) :-
	phrase(line(Class, _Header, PS), In),
	init_args(Class, Header),
	need_diagram(Class, PS, LineNo, Cont),
	class_to_tex(Class, TexClass),
	substitute(Class, TexClass, Header, TexHeader),
	sformat(S, '\\classsummary~w{~w}{~w}{~w}~n',
		[Cont, TexClass, TexHeader, PS]),
	string_to_list(S, Out).

line(Class, Header, PS) -->
	"#class",
	blanks,
	word(Class),
	blanks,
	"""", string(S), """", !,
	{atom_codes(Header, S)},
	blanks,
	(   word(PS)
	->  {true}
	;   {class_to_ps(Class, PS)}
	),
	blanks.

blanks -->
	[X], {X =< 32}, !,
	blanks.
blanks -->
	[].

word(W) -->
	nonblanks(Chars), {Chars \== []},
	{atom_codes(W, Chars)}.

nonblanks([X|T]) -->
	[X], {X > 32}, !,
	nonblanks(T).
nonblanks([]) -->
	[].

string([]) -->
	[].
string([C|T]) -->
	[C],
	string(T).

class_to_ps(CN, PS) :-
	atom_codes(CN, Chars),
	delete(Chars, 0'_, C2),
 	atom_codes(PS, C2).


class_to_tex(Name, TeXName) :-
	atom_codes(Name, Chars),
	member(C, Chars),
	\+ alnum(C), !,
	atomic_list_concat(['{\\tt\\string', Name, '}'], TeXName).
class_to_tex(Name, Name).

alnum(C) :-
	between(0'a, 0'z, C).
alnum(C) :-
	between(0'A, 0'Z, C).
alnum(0'_).

substitute(F, T, I, O) :-
	atom_codes(F, SF),
	atom_codes(T, ST),
	atom_codes(I, SI),
	substitute_string(SF, ST, SI, SO), !,
	atom_codes(O, SO).
substitute(_, _, I, I).

substitute_string(F, T, I, O) :-
	append(Pr, S0, I),
	append(F, Po, S0), !,
	append(Pr, T, S1),
	substitute_string(F, T, Po, Po2),
	append(S1, Po2, O).
substitute_string(_, _, I, I).

		 /*******************************
		 *	    INIT METHOD		*
		 *******************************/

init_args(ClassName, Descr) :-
	get(@pce, convert, ClassName, class, Class),
	get(Class, send_method, initialise, SM),
	get(SM, man_summary, Summary),
	new(R, regex('.*:\\s +\\(.*\\)\t.*')),
	send(R, match, Summary), !,
	get(R, register_value, Summary, 1, name, D0),
	substitute('|', '$|$', D0, Descr).
init_args(_, '').

