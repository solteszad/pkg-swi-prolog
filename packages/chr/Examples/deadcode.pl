/*  $Id$

    Part of CHR (Constraint Handling Rules)

    Author:        Tom Schrijvers
    E-mail:        Tom.Schrijvers@cs.kuleuven.be
    WWW:           http://www.swi-prolog.org
    Copyright (C): 2003-2004, K.U. Leuven

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    As a special exception, if you link this library with other files,
    compiled with a Free Software compiler, to produce an executable, this
    library does not by itself cause the resulting executable to be covered
    by the GNU General Public License. This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/

:- module(deadcode,[deadcode/2]).

:- use_module(library(chr)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
:- constraints
	defined_predicate(+any),
	calls(+any,+any),
	live(+any),
	print_dead_predicates.

defined_predicate(P) \ defined_predicate(P) <=> true.

calls(P,Q) \ calls(P,Q) <=> true.

live(P) \ live(P) <=> true.

live(P), calls(P,Q) ==> live(Q).

print_dead_predicates \ live(P), defined_predicate(P) <=> true.
print_dead_predicates \ defined_predicate(P) <=>
	writeln(P).
print_dead_predicates \ calls(_,_) <=> true.
print_dead_predicates \ live(_) <=> true.
print_dead_predicates <=> true.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

deadcode(File,Starts) :-
	readfile(File,Clauses),
	exported_predicates(Clauses,Exports),
	findall(C, ( member(C,Clauses), C \= (:- _) , C \= (?- _)), Cs),
	process_clauses(Cs),
	append(Starts,Exports,Alive),
	live_predicates(Alive),
	print_dead_predicates.

exported_predicates(Clauses,Exports) :-
	( member( (:- module(_, Exports)), Clauses) ->
		true
	;
		Exports = []
	).
process_clauses([]).
process_clauses([C|Cs]) :-
	hb(C,H,B),
	extract_predicates(B,Ps,[]),
	functor(H,F,A),
	defined_predicate(F/A),
	calls_predicates(Ps,F/A),
	process_clauses(Cs).

calls_predicates([],FA).
calls_predicates([P|Ps],FA) :-
	calls(FA,P),
	calls_predicates(Ps,FA).

hb(C,H,B) :-
	( C = (H :- B) ->
		true
	;
		C = H,
		B = true
	).

live_predicates([]).
live_predicates([P|Ps]) :-
	live(P),
	live_predicates(Ps).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
extract_predicates(!,L,L) :- ! .
extract_predicates(_ < _,L,L) :- ! .
extract_predicates(_ = _,L,L) :- ! .
extract_predicates(_ =.. _ ,L,L) :- ! .
extract_predicates(_ =:= _,L,L) :- ! .
extract_predicates(_ == _,L,L) :- ! .
extract_predicates(_ > _,L,L) :- ! .
extract_predicates(_ \= _,L,L) :- ! .
extract_predicates(_ \== _,L,L) :- ! .
extract_predicates(_ is _,L,L) :- ! .
extract_predicates(arg(_,_,_),L,L) :- ! .
extract_predicates(atom_concat(_,_,_),L,L) :- ! .
extract_predicates(atomic(_),L,L) :- ! .
extract_predicates(b_getval(_,_),L,L) :- ! .
extract_predicates(call(_),L,L) :- ! .
extract_predicates(compound(_),L,L) :- ! .
extract_predicates(copy_term(_,_),L,L) :- ! .
extract_predicates(del_attr(_,_),L,L) :- ! .
extract_predicates(fail,L,L) :- ! .
extract_predicates(functor(_,_,_),L,L) :- ! .
extract_predicates(get_attr(_,_,_),L,L) :- ! .
extract_predicates(length(_,_),L,L) :- ! .
extract_predicates(nb_setval(_,_),L,L) :- ! .
extract_predicates(nl,L,L) :- ! .
extract_predicates(nonvar(_),L,L) :- ! .
extract_predicates(once(G),L,T) :- !,
	( nonvar(G) ->
		extract_predicates(G,L,T)
	;
		L = T
	).
extract_predicates(op(_,_,_),L,L) :- ! .
extract_predicates(prolog_flag(_,_),L,L) :- ! .
extract_predicates(prolog_flag(_,_,_),L,L) :- ! .
extract_predicates(put_attr(_,_,_),L,L) :- ! .
extract_predicates(read(_),L,L) :- ! .
extract_predicates(see(_),L,L) :- ! .
extract_predicates(seen,L,L) :- ! .
extract_predicates(setarg(_,_,_),L,L) :- ! .
extract_predicates(tell(_),L,L) :- ! .
extract_predicates(term_variables(_,_),L,L) :- ! .
extract_predicates(told,L,L) :- ! .
extract_predicates(true,L,L) :- ! .
extract_predicates(var(_),L,L) :- ! .
extract_predicates(write(_),L,L) :- ! .
extract_predicates((G1,G2),L,T) :- ! ,
	extract_predicates(G1,L,T1),
	extract_predicates(G2,T1,T).
extract_predicates((G1->G2),L,T) :- !,
	extract_predicates(G1,L,T1),
	extract_predicates(G2,T1,T).
extract_predicates((G1;G2),L,T) :- !,
	extract_predicates(G1,L,T1),
	extract_predicates(G2,T1,T).
extract_predicates(\+ G, L, T) :- !,
	extract_predicates(G, L, T).
extract_predicates(findall(_,G,_),L,T) :- !,
	extract_predicates(G,L,T).
extract_predicates(bagof(_,G,_),L,T) :- !,
	extract_predicates(G,L,T).
extract_predicates(_^G,L,T) :- !,
	extract_predicates(G,L,T).
extract_predicates(_:Call,L,T) :- !,
	extract_predicates(Call,L,T).
extract_predicates(Call,L,T) :-
	( var(Call) ->
		L = T
	;
		functor(Call,F,A),
		L = [F/A|T]
	).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% File Reading

readfile(File,Declarations) :-
	see(File),
	readcontent(Declarations),
	seen.

readcontent(C) :-
	read(X),
	( X = (:- op(Prec,Fix,Op)) ->
		op(Prec,Fix,Op)
	;
		true
	),
	( X == end_of_file ->
		C = []
	;
		C = [X | Xs],
		readcontent(Xs)
	).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

