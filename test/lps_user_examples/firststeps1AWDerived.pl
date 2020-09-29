<div class="notebook">

<div class="nb-cell markdown" name="md1">
---+++ Computation in LPS

Computation in LPS generates a sequence of states and  events, using laws of cause and effect.
States are sets of facts (also called fluents, because they can change with time).
Events cause state transitions by initiating facts and terminating facts.
For example:
</div>

<div class="nb-cell program" name="p1">
% This is a comment, preceeded by %. 
% The following two sentences declare the fluents and events in this example.
% 
fluents lightOn, lightOff.
events switch.

% The following sentence describes the facts that are true at time 1.
%
initially lightOff.

% The following three sentences describe events taking place in the transition from one time point to the next.
%
observe switch from 1 to 2.
observe switch from 3 to 4.
observe switch from 10 to 11.

% The following four sentences describe the laws of cause and effect for this example.
%
switch initiates 	lightOn 	if lightOff.
switch terminates 	lightOff 	if lightOff.
switch initiates 	lightOff 	if lightOn.
switch terminates 	lightOn 	if lightOn.
</div>

<div class="nb-cell markdown" name="md2">
To run this program, put go(Timeline). into the query window.
</div>

<div class="nb-cell query" name="q1">
go(Timeline).
</div>

<div class="nb-cell markdown" name="md3">
Ignore the warning. It is there because most LPS programs have reactive rules. They are missing in this example, but are introduced in the next notebook.

The output is a timeline of states and events, which if not specified otherwise, ends at time 20. To change the end of time, insert a declaration, maxTime(time). at the beginning of your program. For example:
</div>

<div class="nb-cell program" name="p2">
maxTime(15).

fluents lightOn, lightOff.
events switch.

initially lightOff.

observe switch from 1 to 2.
observe switch from 3 to 4.
observe switch from 10 to 11.

switch initiates 	lightOn 	if lightOff.
switch terminates 	lightOff 	if lightOff.
switch initiates 	lightOff 	if lightOn.
switch terminates 	lightOn 	if lightOn.
</div>

<div class="nb-cell query" name="q2">
go(Timeline).
</div>

<div class="nb-cell markdown" name="md4">
The timeline generated by a computation is the main component of a world model.
The timestamped sentences belonging to the model describe the basic (also called atomic) sentences that are true in the model.
These atomic sentences determine whether or not more complicated sentences are also true in the same model.
For example, in the model generated by this program, the sentence:

	for all times T1 and T2 (between and including 1 and 15) 
    	if lightOn at T1 and not switch from T1 to T2
    	then lightOn at T2.

is also true.
</div>

</div>