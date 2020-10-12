:- module(rsasak_pddl_parser,[parseProblem/3,parseDomain/3]).

:- use_module(library(logicmoo_planner)).

:- style_check(-singleton).

:- meta_predicate emptyOr(//,?,?).



%% get_param_types0(+Df, +ListOfParams, -NameOrVarList, -TypeList).
%
get_param_types(Df,H,P,K):-must((get_param_types0(Df,H,P,K),length(P,L),length(K,L))).


use_default(s(var),'?'(H),H).
use_default(s(var),(H),H).
use_default(s(val),'?'(H),'?'(H)).
use_default(s(val),H,H).
use_default(Df,_,Df).

adjust_types(T,GsNs,Ps):- must((get_param_types0(T, GsNs,Ps, _))).
adjust_types(T,GsNs,L):- must((get_param_types0(T, GsNs,Ps, Ks),pairs_keys_values(L,Ps, Ks))).

get_param_types0(_,[], [] ,[]).

get_param_types0(Df,[H|T],[P1|Ps],[K|Ks]):- 
    svar_fixvarname(H,Name),!,
    P1 = '?'(Name),
    use_default(Df,P1,K),
    get_param_types0(Df,T, Ps, Ks).
get_param_types0(Df,[H|T],[P1|Ps],[K|Ks]):-
    compound(H), H =.. [K, P1],not(is_list(P1)),!,
    get_param_types0(Df,T, Ps, Ks).
get_param_types0(Df,[H|T],[P1|Ps],[K|Ks]):-
    compound(H), H =.. [K, [P1]],!,    
    get_param_types0(Df,T, Ps, Ks).
get_param_types0(Df,[H|T],[P1,P2|Ps],[K,K|Ks]):-
    compound(H), H =.. [K, [P1,P2]],!,
    get_param_types0(Df,T, Ps, Ks).

get_param_types0(Df,[H|T],[P1,P2,P3|Ps],[K,K,K|Ks]):-
    compound(H), H =.. [K, [P1,P2,P3]],!,
    get_param_types0(Df,T, Ps, Ks).


get_param_types0(Df,[H|T],[H|Ps],[K|Ks]):-  must(atom(H)),use_default(Df,H,K),
    get_param_types0(Df,T, Ps, Ks).


% FILENAME:  readFile.pl 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  read_file
%%%  This is a modified version for parsing pddl files.
%%%  Read the input file character by character and parse it
%%%  into a list. Brackets, comma, period and question marks
%%%  are treated as separate words. White spaces separed 
%%%  words. 
%%%
%%%  Similar to read_sent in Pereira and Shieber, Prolog and
%%%        Natural Language Analysis, CSLI, 1987.
%%%
%%%  Examples:
%%%           :- read_file('input.txt', L).
%%%           input.txt> The sky was blue, after the rain.
%%%           L = [the, sky, was, blue, (','), after, the, rain, '.']
%%%
%%%           :- read_file('domain.pddl', L).
%%%           domain.pddl>
%%%           (define (domain BLOCKS)
%%%             (:requirements :strips :typing :action-costs)
%%%             (:types block)
%%%             (:predicates (on ?x - block ?y - block)
%%%           ...))
%%%           L = ['(', define, '(', domain, blocks, ')', '(', :, requirements|...].

% :- expects_dialect(sicstus).

fix_wordcase(Word,WordC):-upcase_atom(Word,UC),UC=Word,!,downcase_atom(Word,WordC).
fix_wordcase(Word,Word).

:- use_module(library(wam_cl/sreader)).
%
%read_file(+File, -List).
%
read_file(string(String), Words, textDoc) :- must(open_string(String,In)),!, current_input(Old),call_cleanup(( set_input(In), get_code(C), (read_rest(C, Words))),( set_input(Old))),!.
read_file( File, Words) :- atom(File), exists_file(File), !, seeing(Old),call_cleanup(( see(File), get_code(C), (read_rest(C, Words))),( seen, see(Old))),!.
read_file(File0, Words) :- must((must_filematch(File0,File),exists_file(File),read_file( File, Words))),!.


/* Ends the input. */
read_rest(-1,[]) :- !.

/* Spaces, tabs and newlines between words are ignored. */
read_rest(C,Words) :- ( C=32 ; C=10 ; C=9 ; C=13 ; C=92 ) , !,
                     get_code(C1),
                     read_rest(C1,Words).

/* Brackets, comma, period or question marks are treated as separed words */
read_rest(C, [Char|Words]) :- ( C=40 ; C=41 ; C=44 ; C=45 ; C=46 ; C=63 ; C=58 ) , name(Char, [C]), !,
			get_code(C1),
			read_rest(C1, Words).

/* Read comments to the end of line */
read_rest(59, Words) :- get_code(Next), !, 
			      read_comment(Next, Last),
			      read_rest(Last, Words).

/* Otherwise get all of the next word. */
read_rest(C,[WordC|Words]) :- read_word(C,Chars,Next),
                             name(Word,Chars),fix_wordcase(Word,WordC),
                             read_rest(Next,Words).

/* Space, comma, newline, backspace, carriage-return, 46 , 63,  ( ) period, end-of-file or question mark separate words. */
read_word(C,[],C) :- ( C=32 ; C=44 ; C=10 ; C=9 ; C=13 ;
                         C=46 ; C=63 ; C=40 ; C=41 ; C=58 ; C= -1 ) , !.

/* Otherwise, get characters and convert to lower case. */
read_word(C,[LC|Chars],Last) :- C=LC, % lower_case(C, LC),
				get_code(Next),
                                read_word(Next,Chars,Last).

/* Convert to lower case if necessary. */
lower_case(C,C) :- ( C <  65 ; C > 90 ) , !.
lower_case(C,LC) :- LC is C + 32.


/* Keep reading as long you dont find end-of-line or end-of-file */
read_comment(10, 10) :- !.
read_comment(-1, -1) :- !.
read_comment(_, Last) :- get_code(Next),
			 read_comment(Next, Last).

%get0(C):-get_code(C), !.

/* for reference ... 
newline(10).
comma(44).
space(32).
period(46).
question_mark(63).
*/


% FILENAME:  parseDomain.pl 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% parseDomain.pl
%%   Simple parser of PDDL domain file into prolog syntax.
%% Author: Robert Sasak, Charles University in Prague
%%
%% Example: 
%% ?-parseDomain('blocks_world.pddl', O).
%%   O = domain(blocks,
%%        [strips, typing, 'action-costs'],
%%        [block],
%%        _G4108,
%%        [ on(block(?x), block(?y)),
%%	         ontable(block(?x)),
%%	         clear(block(?x)),
%%	         handempty,
%%	         holding(block(?x)) ],
%%        [number(f('total-cost', []))],
%%        _G4108,
%%        [ action('pick-up', [block(?x)],       %parameters
%%		      [clear(?x), ontable(?x), handempty], %preconditions
%%		      [holding(?x)],                       %positiv effects
%%          [ontable(?x), clear(?x), handempty], %negativ effects
%%          [increase('total-cost', 2)]),        %numeric effects
%%         ...],
%%       ...)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% parseDomain(+File, -Output).
% Parse PDDL domain File and return it rewritten prolog syntax.   
parseDomain(F, O):- parseDomain(F, O, _).
% parseDomain(+File, -Output, -RestOfFile)
% The same as above and also return rest of file. Can be useful when domain and problem are in one file.
parseDomain(File, Output, R) :-
		read_file(File, List),
		domainBNF(Output, List, R).

% Support for reading file as a list.
% :-[readFile].


% Defining operator ?. It is a syntax sugar for marking variables: ?x
:-op(300, fy, ?).


dcgStructSetOpt(Struct,Name,DCG,H,T) :- call(DCG,Value,H,T)-> prop_set(Name,Struct,Value); H=T.

dcgStructSetOptTraced(Struct,Name,DCG,H,T) :-(( call(DCG,Value,H,T)-> prop_set(Name,Struct,Value); H=T)).

% domainBNF_dcg(domain(N, R, T, C, P, F, C, S))
%
% List of DCG rules describing structure of domain file in language PDDL.
% BNF description was obtain from http://www.cs.yale.edu/homes/dvm/papers/pddl-bnf.pdf
% This parser do not fully NOT support PDDL 3.0
% However you will find comment out lines ready for futher development.
domainBNF(domain(N, R, T, C, P, F, C, S))
			--> ['(','define', '(','domain'], name(N), [')'],
                             (require_def(R)	; []),
                             (types_def(T)    	; []), %:typing
                             (constants_def(C) 	; []),
                             (predicates_def(P)	; []),
                             (functions_def(F)	; []), %:fluents
%                             (constraints(C)	; []),    %:constraints
                             zeroOrMore(structure_def, S),
			     [')'].

require_def(R)		--> ['(',':','requirements'], oneOrMore(require_key, R), [')'].
require_key(strips)								--> [':strips'].
require_key(typing)								--> [':typing'].
%require_key('negative-preconditions')		--> [':negative-preconditions'].
%require_key('disjunctive-preconditions')	--> [':disjunctive-preconditions'].
require_key(equality)							--> [':equality'].
require_key('existential-preconditions')	--> [':existential-preconditions'].
require_key('universal-preconditions')		--> [':universal-preconditions'].
require_key('quantified-preconditions')	--> [':quantified-preconditions'].
require_key('conditional-effects')			--> [':conditional-effects'].
require_key(fluents)								--> [':fluents'].
require_key(adl)									--> [':adl'].
require_key('durative-actions')				--> [':durative-actions'].
require_key('derived-predicates')			--> [':derived-predicates'].
require_key('timed-initial-literals')		--> [':timed-initial-literals'].
require_key(preferences)						--> [':preferences'].
require_key(constraints)						--> [':constraints'].
% Universal requirements
require_key(R)		--> [':', R].

types_def(L)			--> ['(',':',types],      typed_list(name, L), [')'].
constants_def(L)		--> ['(',':',constants],  typed_list(name, L), [')'].
predicates_def(P)		--> ['(',':',predicates], oneOrMore(atomic_formula_skeleton, P), [')'].

atomic_formula_skeleton(F)
				--> ['('], predicate(P), typed_list(variable, L), [')'], {F =.. [P|L]}.
predicate(P)			--> name(P).

variable(V)			--> ['?'], name(N), {V =.. [?, N]}.
atomic_function_skeleton(f(S, L))
				--> ['('], function_symbol(S), typed_list(variable, L), [')'].
function_symbol(S)		--> name(S).
functions_def(F)		--> ['(',':',functions], function_typed_list(atomic_function_skeleton, F), [')'].	%:fluents
%constraints(C)		--> ['(',':',constraints], con_GD(C), [')'].	%:constraints
structure_def(A)		--> action_def(A).
%structure_def(D)		--> durative_action_def(D).	%:durativeactions
%structure_def(D)		--> derived_def(D).		%:derivedpredicates
%typed_list(W, G)		--> oneOrMore(W, N), ['-'], type(T), {G =.. [T, N]}.
typed_list(W, [G|Ns])		--> oneOrMore(W, N), ['-'], type(T), !, typed_list(W, Ns), {G =.. [T,N]}.
typed_list(W, N)		--> zeroOrMore(W, N).

primitive_type(N)		--> name(N).
type(either(PT))		--> ['(',either], !, oneOrMore(primitive_type, PT), [')'].
type(PT)			--> primitive_type(PT).
function_typed_list(W, [F|Ls])
				--> oneOrMore(W, L), ['-'], !, function_type(T), function_typed_list(W, Ls), {F =.. [T|L]}.	%:typing
function_typed_list(W, L)	--> zeroOrMore(W, L).

function_type(number)		--> [number].

emptyOr(_)			--> ['(',')'].
emptyOr(W)			--> W.

% Actions definitons
action_def(action(S, L, Precon, Pos, Neg, Assign))
				--> ['(',':',action], action_symbol(S),
						[':',parameters,'('], typed_list(variable, L), [')'],
						action_def_body(Precon, Pos, Neg, Assign),
					[')'].
action_symbol(N)		--> name(N).
action_def_body(P, Pos, Neg, Assign)
				--> (([':',precondition], emptyOr(pre_GD(P)))	; []),
				    (([':',effect],       emptyOr(effect(Pos, Neg, Assign)))	; []).
pre_GD([F])			--> atomic_formula(term, F), !.
pre_GD(P)			--> pref_GD(P).
pre_GD(P)			--> ['(',and], pre_GD(P), [')'].
%pre_GD(forall(L, P))		--> ['(',forall,'('], typed_list(variable, L), [')'], pre_GD(P), [')'].		%:universal-preconditions
%pref_GD(preference(N, P))	--> ['(',preference], (pref_name(N); []), gd(P), [')'].				%:preferences
pref_GD(P)			--> gd(P).
pref_name(N)			--> name(N).
gd(F)				--> atomic_formula(term, F).	%: this option is covered by gd(L)
%gd(L)				--> literal(term, L).								%:negative-preconditions
gd(P)				--> ['(',and],  zeroOrMore(gd, P), [')'].
%gd(or(P))			--> ['(',or],   zeroOrMore(gd ,P), [')'].					%:disjuctive-preconditions
%gd(not(P))			--> ['(',not],  gd(P), [')'].							%:disjuctive-preconditions
%gd(imply(P1, P2))		--> ['(',imply], gd(P1), gd(P2), [')'].						%:disjuctive-preconditions
%gd(exists(L, P))		--> ['(',exists,'('], typed_list(variable, L), [')'], gd(P), [')'].		%:existential-preconditions
%gd(forall(L, P))		--> ['(',forall,'('], typed_list(variable, L), [')'], gd(P), [')'].		%:universal-preconditions
gd(F)				--> f_comp(F).	%:fluents
f_comp(compare(C, E1, E2))	--> ['('], binary_comp(C), f_exp(E1), f_exp(E2), [')'].
literal(T, F)			--> atomic_formula(T, F).
literal(T, not(F))		--> ['(',not], atomic_formula(T, F), [')'].
atomic_formula(_, F)		--> ['('], predicate(P), zeroOrMore(term, T), [')'], {F =.. [P|T]}.		% cheating, maybe wrong


term(N)				--> name(N).
term(V)				--> variable(V).
f_exp(N)			--> number(N).
f_exp(op(O, E1, E2))		--> ['('],binary_op(O), f_exp(E1), f_exp(E2), [')'].
f_exp('-'(E))			--> ['(','-'], f_exp(E), [')'].
f_exp(H)			--> f_head(H).
f_head(F)			--> ['('], function_symbol(S), zeroOrMore(term, T), [')'], { F =.. [S|T] }.
f_head(S)				--> function_symbol(S).
binary_op(O)			--> multi_op(O).
binary_op(45)			--> [45]. % 45 = minus = '-' 
binary_op('/')			--> ['/'].
multi_op('*')			--> ['*'].
multi_op('+')			--> ['+'].
binary_comp('>')		--> ['>'].
binary_comp('<')		--> ['<'].
binary_comp('=')		--> ['='].
binary_comp('>=')		--> ['>='].
binary_comp('<=')		--> ['<='].
number(N)			--> [N], {integer(N)}.
number(N)			--> [N], {float(N)}.
effect(P, N, A)			--> ['(',and], c_effect(P, N, A), [')'].
effect(P, N, A)			--> c_effect(P, N, A).
%c_effect(forall(E))		--> ['(',forall,'('], typed-list(variable)∗) effect(E), ')'.	%:conditional-effects
%c_effect(when(P, E))		--> ['(',when], gd(P), cond_effect(E), [')'].			%:conditional-effects
c_effect(P, N, A)		--> p_effect(P, N, A).
p_effect([], [], [])		--> [].
p_effect(Ps, Ns, [F|As])
				--> ['('], assign_op(O), f_head(H), f_exp(E), [')'], p_effect(Ps, Ns, As), {F =.. [O, H, E]}.
p_effect(Ps, [F|Ns], As)	--> ['(',not], atomic_formula(term,F), [')'], p_effect(Ps, Ns, As).
p_effect([F|Ps], Ns, As)	--> atomic_formula(term, F), p_effect(Ps, Ns, As).
%p_effect(op(O, H, E))		--> ['('], assign_op(O), f_head(H), f_exp(E), [')'].	%:fluents , What is difference between rule 3 lines above???
%cond_effect(E)		--> ['(',and], zeroOrMore(p_effect, E), [')'].				%:conditional-effects
%cond_effect(E)			--> p_effect(E).						%:conditional-effects
assign_op(assign)		--> [assign].
assign_op(scale_up)		--> [scale_up].
assign_op(scale_down)		--> [scale_down].
assign_op(increase)		--> [increase].
assign_op(decrease)		--> [decrease].


% BNF description include operator <term>+ to mark zero or more replacements.
% This DCG extension to overcome this. 
oneOrMore(W, [R|Rs], A, C) :- F =.. [W, R, A, B], F, (
					oneOrMore(W, Rs, B, C) ;
					(Rs = [] , C = B) 
				).
% BNF operator <term>*
zeroOrMore(W, R)		--> oneOrMore(W, R).
zeroOrMore(_, [])		--> [].

% Name is everything that is not number, bracket or question mark.
% Those rules are not necessary, but rapidly speed up parsing process.
name(N)				--> [N], {integer(N), !, fail}.
name(N)				--> [N], {float(N), !, fail}.
name(N)				--> [N], {N=')', !, fail}.
name(N)				--> [N], {N='(', !, fail}.
name(N)				--> [N], {N='?', !, fail}.
name(N)				--> [N], {N='-', !, fail}.
name(N)				--> [N].



% FILENAME:  parseProblem.pl 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% parseDomain.pl
%%   Simple parser of PDDL domain file into prolog syntax.
%% Author: Robert Sasak, Charles University in Prague
%%
%% Example: 
%% ?-parseProblem('problem.pddl', O).
%%   O = problem('blocks-4-0',							%name
%%              blocks,										%domain name
%%              _G1443,                            %require definition
%%              [block(d, b, a, c)],					%object declaration
%%              [ clear(c), clear(a), clear(b), clear(d), ontable(c), %initial state
%%                ontable(a), ontable(b), ontable(d), handempty,
%%                set('total-cost', 0)	],
%%              [on(d, c), on(c, b), on(b, a)],		%goal
%%              _G1447,										%constraints-not implemented
%%              metric(minimize, 'total-cost'),		%metric
%%              _G1449										%length_specification-not implemented
%%              )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parseProblem(+File, -Output).
%
% Parse PDDL problem File and return rewritten prolog syntax. 
%
parseProblem(F, O):-parseProblem(F, O, _).

% parseProblem(+File, -Output, -RestOfFile).
% The same as above and also return rest of file. Can be useful when domain and problem are in one file.
parseProblem(F, O, R) :-
	read_file(F, L),
	problem(O, L, R).

% Support for reading file as a list.
% :-[readFile].



% DCG rules describing structure of problem file in language PDDL.
%
% BNF description was obtain from http://www.cs.yale.edu/homes/dvm/papers/pddl-bnf.pdf
% This parser do not fully NOT support PDDL 3.0
% However you will find comment out lines ready for futher development.
% Some of the rules are already implemented in parseDomain.pl
%
% :-[parseDomain]. %make sure that it is loaded.
problem(problem(Name, Domain, R, OD, I, G, _, MS, LS))   
				--> ['(',define,'(',problem,Name,')',
							'(',':',domain, Domain,')'],
                     (require_def(R)		; []),
							(object_declaration(OD)	; []),
							init(I),
							goal(G),
%                     (constraints(C)		; []), %:constraints
							(metric_spec(MS)	; []),
                     (length_spec(LS)	; []),
				[')'].

object_declaration(L)		--> ['(',':',objects], typed_list_as_list(name, L),[')'].

typed_list_as_list(W, [G|Ns])           --> oneOrMore(W, N), ['-'], type(T), !, typed_list_as_list(W, Ns), {G =.. [T,N]}.
typed_list_as_list(W, N)                --> zeroOrMore(W, N).



init(I)                      	--> ['(',':',init], zeroOrMore(init_el, I), [')'].

init_el(I)			--> literal(name, I).
init_el(set(H,N))		--> ['(','='], f_head(H), number(N), [')'].					%fluents
init_el(at(N, L))		--> ['(',at], number(N), literal(name, L), [')'].				% timed-initial literal
goal(G)				--> ['(',':',goal], pre_GD(G),[')'].
%constraints(C)			--> ['(',':',constraints], pref_con_GD(C), [')'].				% constraints
pref_con_GD(and(P))		--> ['(',and], zeroOrMore(pref_con_GD, P), [')'].
%pref_con_GD(foral(L, P))	--> ['(',forall,'('], typed_list(variable, L), [')'], pref_con_GD(P), [')'].	%universal-preconditions
%pref_con_GD(prefernce(N, P))	--> ['(',preference], (pref_name(N) ; []), con_GD(P), [')'].			%prefernces
pref_con_GD(P)			--> con_GD(P).

con_GD(and(L))			--> ['(',and], zeroOrMore(con_GD, L), [')'].
con_GD(forall(L, P))		--> ['(',forall,'('], typed_list(variable, L),[')'], con_GD(P), [')'].
con_GD(at_end(P))		--> ['(',at,end],	gd(P), [')'].
con_GD(always(P))		--> ['(',always],	gd(P), [')'].
con_GD(sometime(P))		--> ['(',sometime],	gd(P), [')'].
con_GD(within(N, P))            --> ['(',within], number_sas(N), gd(P), [')'].

con_GD(at_most_once(P))		--> ['(','at-most-once'], gd(P),[')'].
con_GD(some_time_after(P1, P2))	--> ['(','sometime-after'], gd(P1), gd(P2), [')'].
con_GD(some_time_before(P1, P2))--> ['(','sometime-before'], gd(P1), gd(P2), [')'].
con_GD(always_within(N, P1, P2))--> ['(','always-within'], number(N), gd(P1), gd(P2), [')'].
con_GD(hold_during(N1, N2, P))	--> ['(','hold-during'], number(N1), number(N2), gd(P), [')'].
con_GD(hold_after(N, P))	--> ['(','hold-after'], number(N), gd(P),[')'].

metric_spec(metric(O, E))	--> ['(',':',metric], optimization(O), metric_f_exp(E), [')'].

optimization(minimize)		--> [minimize].
optimization(maximize)		--> [maximize].

metric_f_exp(E)			--> ['('], binary_op(O), metric_f_exp(E1), metric_f_exp(E2), [')'], {E =..[O, E1, E2]}.
metric_f_exp(multi_op(O,[E1|E]))--> ['('], multi_op(O), metric_f_exp(E1), oneOrMore(metric_f_exp, E), [')']. % I dont see meanful of this rule, in additional is missing in f-exp
metric_f_exp(E)			--> ['(','-'], metric_f_exp(E1), [')'], {E=..[-, E1]}.
metric_f_exp(N)                 --> number_sas(N).
metric_f_exp(F)                 --> ['('], function_symbol(S), zeroOrMore(name, Ns), [')'], { F=..[S|Ns]}.%concat_atom_iio([S|Ns], '-', F) }.
metric_f_exp(function(S))	--> function_symbol(S).
metric_f_exp(total_time)	--> ['total-time'].
metric_f_exp(is_violated(N))	--> ['(','is-violated'], pref_name(N), [')'].

% Work arround
metric_f_exp(is_violated(N,V))    --> ['(','*','(','is-violated'], pref_name(N), [')'],number_sas(V),[')'].

% Work arround
length_spec([])			--> [not_defined].	% there is no definition???
