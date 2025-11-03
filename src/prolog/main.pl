
% Enable (á, ã, ç) type chars
:- encoding(utf8).

% Delete previous created dynamic predicates
:- abolish(w_wall/2).       % wall position
:- abolish(w_hunter/3).     % hunter position
:- abolish(w_wumpus/2).     % wumpus position
:- abolish(w_pit/2).        % pit position
:- abolish(w_gold/2).       % gold position
:- abolish(w_goal/1).       % hunter goal complete?
:- abolish(w_cells/1).      % available cells
:- abolish(h_arrow/1).      % arrow available?
:- abolish(h_score/1).      % hunter score
:- abolish(a_costs/3).      % cells costs
:- abolish(a_visited/2).    % visited cells
:- abolish(a_stench_at/2).  % stench cells
:- abolish(a_breeze_at/2).  % breeze cells
:- abolish(no_logs/1).      % show/hide logs

% ============================================================================
% NEW: Enhanced gameplay features
% ============================================================================
:- abolish(sound_event/4).      % sound events (X, Y, Loudness, Duration)
:- abolish(wumpus_state/2).     % wumpus AI state (ID, State)
:- abolish(wumpus_target/3).    % wumpus target (ID, X, Y)
:- abolish(wumpus_alert_turns/2). % wumpus alert counter
:- abolish(h_rocks/1).          % rock count
:- abolish(rock_pickup/2).      % rock pickup locations
:- abolish(chest/4).            % treasure chests (ID, X, Y, Type)
:- abolish(chest_opened/1).     % opened chest IDs
:- abolish(player_stunned/1).   % player stun turns remaining
:- abolish(fog_revealed/2).     % fog of war - revealed cells
:- abolish(fog_visible/2).      % fog of war - currently visible cells

% Create dynamic data to store info later.
:- dynamic ([
    w_wall/2, 
    w_hunter/3, 
    w_wumpus/2, 
    w_pit/2, 
    w_gold/2, 
    w_goal/1, 
    w_cells/1,
    h_score/1, 
    h_arrow/1,
    a_costs/3,
    a_visited/2,
    a_stench_at/2,
    a_breeze_at/2,
    no_logs/1,
    % NEW: Enhanced features
    sound_event/4,
    wumpus_state/2,
    wumpus_target/3,
    wumpus_alert_turns/2,
    h_rocks/1,
    rock_pickup/2,
    chest/4,
    chest_opened/1,
    player_stunned/1,
    fog_revealed/2,
    fog_visible/2
]).

clearWorld :-
    /**
        @descr Delete all stored data from dynamic data related to 
        world structure.
    */
    retractall(w_wall(_,_)),
    retractall(w_hunter(_,_,_)),
    retractall(w_wumpus(_,_)),
    retractall(w_pit(_,_)),
    retractall(w_gold(_,_)),
    retractall(h_arrow(_)),
    retractall(w_goal(_)),
    retractall(h_score(_)),
    retractall(w_cells(_)),
    retractall(a_costs(_,_,_)),
    retractall(a_visited(_,_)),
    retractall(a_stench_at(_,_)),
    retractall(a_breeze_at(_,_)),
    retractall(no_logs(_)),
    % NEW: Clear enhanced features
    retractall(sound_event(_,_,_,_)),
    retractall(wumpus_state(_,_)),
    retractall(wumpus_target(_,_,_)),
    retractall(wumpus_alert_turns(_,_)),
    retractall(h_rocks(_)),
    retractall(rock_pickup(_,_)),
    retractall(chest(_,_,_,_)),
    retractall(chest_opened(_)),
    retractall(player_stunned(_)),
    retractall(fog_revealed(_,_)),
    retractall(fog_visible(_,_)). 

buildWalls :-
    /**
        @descr Build the world 4x4 structure by setting the walls.
    */
    assert(w_wall(0,0)),
    assert(w_wall(0,1)),
    assert(w_wall(0,2)),
    assert(w_wall(0,3)),
    assert(w_wall(0,4)),
    assert(w_wall(0,5)),
    assert(w_wall(1,5)),
    assert(w_wall(2,5)),
    assert(w_wall(3,5)),
    assert(w_wall(4,5)),
    assert(w_wall(5,5)),
    assert(w_wall(5,4)),
    assert(w_wall(5,3)),
    assert(w_wall(5,2)),
    assert(w_wall(5,1)),
    assert(w_wall(5,0)),
    assert(w_wall(4,0)),
    assert(w_wall(3,0)),
    assert(w_wall(2,0)),
    assert(w_wall(1,0)).

selectCell(X,Y) :-
    /**
        @type helper
        @descr Select a random cell from the available cell(w_cells)
        and store what's left back into w_cells.
        @return Cell X coordinate.
        @return Cell Y coordinate.
    */
    w_cells(Cells),
	random_select(Cell,Cells,NewCells),
    Cell = [X,Y],
	retract(w_cells(_)),
	assert(w_cells(NewCells)).

buildWumpus :- 
    /**
        @descr Build wumpus in a random available cell.
    */
    selectCell(X,Y),
    assert(w_wumpus(X,Y)).

buildPits :-
    /**
        @descr Build pits in a random available cell.
    */
    selectCell(X1,Y1),
    assert(w_pit(X1,Y1)),
    selectCell(X2,Y2),
    assert(w_pit(X2,Y2)),
    selectCell(X3,Y3),
    assert(w_pit(X3,Y3)).

buildGold :-
    /**
        @descr Build gold in a random available cell.
    */
    selectCell(X,Y),
    (
        (X \= 1, X \= 4, Y \= 1, Y \= 4, true) -> 
            true, assert(w_gold(X,Y)); 
        buildGold, true
        ). 

createWorld :-
    /**
        @descr Create all the wumpus world structure and some basic
        initial state info like hunter goal and score.
    */    
    assert(w_cells([[1,3],[1,4],[2,2],[2,3],[2,4],[3,1],
        [3,2],[3,3],[3,4],[4,1],[4,2],[4,3],[4,4]])),
    buildWalls,
    buildGold,
    buildWumpus,
    buildPits,
    assert(w_hunter(1,1,right)),
    assert(h_arrow(1)),
    assert(w_goal(0)),
    assert(h_score(0)),
    % NEW: Initialize enhanced features
    init_rocks,
    generate_rock_pickups,
    generate_chests,
    init_wumpus_ai,
    init_fog,
    update_fog.

createTWorld :-
    /**
        @descr Create all the wumpus world structure and some basic
        initial state info like hunter goal and score for the 
        traditional wumpus world map.
    */    
    assert(w_cells([[1,3],[1,4],[2,2],[2,3],[2,4],[3,1],
        [3,2],[3,3],[3,4],[4,1],[4,2],[4,3],[4,4]])),
    buildWalls,
    assert(w_wumpus(1,3)),
    assert(w_pit(3,1)),
    assert(w_pit(3,3)),
    assert(w_pit(4,4)),
    assert(w_gold(2,3)),
    assert(w_hunter(1,1,right)),
    assert(h_arrow(1)),
    assert(w_goal(0)),
    assert(h_score(0)),
    % NEW: Initialize enhanced features
    init_rocks,
    generate_rock_pickups,
    generate_chests,
    init_wumpus_ai,
    init_fog,
    update_fog.

welcome :-
    /**
        @descr Print welcome message to the user if user want to play.
    */
    format('\n\n~`=t~60|\n'),
    format(
        ' |~t~a~t~58+| ', 
        ['[PROLOG] Wumpus-world AI Agent']
        ),
    format('\n~`=t~60|'),
    format(
        '\n |~t~a~t~58+| ', 
        ['GOAL: get the gold and return to this position']
        ),
    format(
        '\n |~t~a~t~58+| ', 
        ['ACTIONS: ready, move, left, right, grab, shoot, climb']
        ),
    format(
        '\n |~t~a~t~58+| ', 
        ['AVOID: wumpus, the walls and all the pits in the map']
        ),
    format(
        '\n |~t~a~t~58+| \n\n', 
        ['BONUS: aim to the wumpus and kill it with the arrow']
        ).

/** @descr wait for a ready. command from user */
init :- 
    write('Type "ready." to start the game: '), read(X), X = ready, !.
init :- init.

/** 
    @descr take action if hunter hit some obstacle.
    @params [wumpus, pit, wall]
*/
hunterHit([0,0,0]).
hunterHit([1, _, _]):- 
    h_score(SCORE), 
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nGAME OVER: Wumpus killed you!\n'); 
        true
        ), 
    h_score(A), B is A-1000, retract(h_score(_)), assert(h_score(B)),
    (
        no_logs(NL), NL \= 1 -> 
            format('YOUR SCORE: ~d point(s).\n',[SCORE]); 
        true
        ), !, fail.
hunterHit([_, 1, _]):-
    h_score(SCORE), 
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nGAME OVER: You fell into a pit!\n'); 
        true
        ), 
    h_score(A), B is A-1000, retract(h_score(_)), assert(h_score(B)),
    (
        no_logs(NL), NL \= 1 -> 
            format('YOUR SCORE: ~d point(s).\n',[SCORE]); 
        true
        ), !, fail.
hunterHit([_, _, 1]):-
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nWARNING: You hit the wall!'); 
        true
        ), w_hunter(X,Y,FACING),
    (
        FACING = up, N_Y is Y-1, N_X is X;
        FACING = down, N_Y is Y+1, N_X is X;
        FACING = left, N_X is X+1, N_Y is Y;
        FACING = right, N_X is X-1, N_Y is Y
    ),
    retract(w_hunter(_,_,_)),
    assert(w_hunter(N_X,N_Y,FACING)).

getColisions(P_goal) :-
    /**
        @descr check if hunter it some obstacle.
        @return is goal complete?.
    */
    w_hunter(X,Y,_),
    (w_wumpus(X,Y) -> P_wumpus is 1; P_wumpus is 0),
    (w_pit(X,Y) -> P_pit is 1; P_pit is 0),
    (w_wall(X,Y) -> P_wall is 1; P_wall is 0),
    (w_hunter(1,1,_), w_goal(1) -> P_goal is 1; P_goal is 0),
    hunterHit([P_wumpus,P_pit,P_wall]).

printHunterPosition :- 
    /**
        @descr Print the hunter position to the console.
    */
    w_hunter(X,Y,FACING), 
    format('\nHunter position: (~d,~d), facing ~s.\n', [X, Y, FACING]).

printScore :-
    /**
        @descr Print the hunter score to the console.
    */ 
    h_score(SCORE), format('Current score: ~d point(s).\n', [SCORE]).

stench(X,Y) :-
    /**
        @descr Check if the X,Y match a stench cell.
        @params X,Y current cell coordinates. 
        */
    w_wumpus(A,B),
    (
        X is A,(Y is B-1;Y is B+1);
	    Y is B,(X is A-1;X is A+1)
        ).

breeze(X,Y) :-
    /**
        @descr Check if the X,Y match a breeze cell.
        @params X,Y current cell coordinates. 
        */
    w_pit(A,B),
    (
        X is A,(Y is B-1;Y is B+1);
        Y is B,(X is A-1;X is A+1)
        ).

glitter(X,Y) :- 
    /**
        @descr Check if the X,Y match a glitter cell.
        @params X,Y current cell coordinates. 
        */
    w_gold(X,Y).

getSensors(SENSORS) :-
    /**
        @descr check if hunter position match any stench, breeze 
        or glitter.
        @return SENSORS list of perceptions.
    */
    w_hunter(X,Y,_),
    (stench(X,Y) -> S_stench is 1; S_stench is 0),
    (breeze(X,Y) -> S_breeze is 1; S_breeze is 0),
    (glitter(X,Y) -> S_glitter is 1; S_glitter is 0),
    SENSORS = [S_stench, S_breeze, S_glitter].

printInfo(SENSORS) :- 
    /**
        @descr Print the hunter info to the console.
        @params SENSORS list of perceptions.
    */
    format('stench: ~d breeze: ~d glitter: ~d\n', SENSORS).

move :- 
    /**
        @descr Move the hunter to the next cell in the current direction.
    */
    h_score(A), B is A-1, retract(h_score(_)), assert(h_score(B)),
    w_hunter(X,Y,FACING),
    (
        FACING = up, N_Y is Y + 1, N_X is X;
        FACING = down, N_Y is Y - 1, N_X is X;
        FACING = left, N_X is X - 1, N_Y is Y;
        FACING = right, N_X is X + 1, N_Y is Y
    ),
	retract(w_hunter(_,_,_)),
	assert(w_hunter(N_X, N_Y, FACING)). 

left :-
    /**
        @descr Turn the hunter to the left.
    */
    h_score(A), B is A-1, retract(h_score(_)), assert(h_score(B)),
    w_hunter(X,Y,FACING),
    (
        FACING = up, NEW_FACING = left;
        FACING = down, NEW_FACING = right;
        FACING = left, NEW_FACING = down;
        FACING = right, NEW_FACING = up
    ),
    retract(w_hunter(_,_,_)),
    assertz(w_hunter(X,Y,NEW_FACING)).

right :-
    /**
        @descr Turn the hunter to the right.
    */
    h_score(A), B is A-1, retract(h_score(_)), assert(h_score(B)),
    w_hunter(X,Y,FACING),
    (
        FACING = up, NEW_FACING = right;
        FACING = down, NEW_FACING = left;
        FACING = left, NEW_FACING = up;
        FACING = right, NEW_FACING = down
    ),
    retract(w_hunter(_,_,_)),
    assertz(w_hunter(X,Y,NEW_FACING)).

grab(_) :- 
    /**
        @descr Grab the gold.
        @params GOAL check if the goal is complete and if it is then 
        there's no more gold to grab, otherwise grab it.
    */
    h_score(A), B is A-1, retract(h_score(_)), assert(h_score(B)), fail.
grab(1) :- 
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nGOAL: You already grabbed all the gold.'); 
        true
        ), !.
grab(0) :-
    w_hunter(X,Y,_),
    w_gold(X,Y),
    retract(w_gold(X,Y)),
    assert(w_gold(0,0)),
    retract(w_goal(0)),
    assert(w_goal(1)),
    h_score(A), B is A+1000, retract(h_score(_)), assert(h_score(B)),
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nGOAL: You grabbed the gold!. '),
            write('Now get out of the cave.'); 
        true
        ), !.
grab(0) :-
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nWARNING: There`s no gold to grab where you are.'); 
        true
        ).

shoot :- 
    /**
        @descr Shoot the arrow if there's an arrow and kill the wumpus 
        if it's alive and in the direction hunter is facing.
    */
    h_score(A), B is A-10, retract(h_score(_)), assert(h_score(B)), fail.
shoot :- 
    h_arrow(0), 
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nWARNING: You have no arrows to shoot.'); 
        true
        ), !.
shoot :- 
    w_hunter(X,Y,FACING),
    w_wumpus(A,B),
    retract(h_arrow(1)),
    assert(h_arrow(0)),
    (
        FACING = up, X = A, Y < B;
        FACING = down, X = A, Y > B;
        FACING = left, Y = B, X > A;
        FACING = right, Y = B, X < A
    ),
    retract(w_wumpus(_,_)),
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nBONUS: Wumpus scream which means you killed him!'); 
        true
        ), !.
shoot :-
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nWARNING: Your arrow missed the wumpus!'); 
        true
        ).

climb(_):- 
    /**
        @descr Climb the ladder and get out of the cave if hunter is 
        in the same position as the ladder and the goal has been
        completed.
        @params GOAL check if the goal is complete and if it is then it
        means that the hunter is allowed to climb the ladder.
    */ 
    h_score(A), B is A-1, retract(h_score(_)), assert(h_score(B)), fail.
climb(0) :- 
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nWARNING: '),
            write('You are in no conditions to get out of the cave.'); 
        true
        ), !.
climb(1):-
    h_score(SCORE),
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nWINNER: '),
            write('You managed to get out of the cave with the gold!\n'); 
        true
        ),
    (
        no_logs(NL), NL \= 1 -> 
            format('YOUR SCORE: ~d point(s).\n',[SCORE]); 
        true
        ).

action(move,_) :- 
    /**
     *  @descr take the action passed as first parameter and execute it.
        @params action to be executed.
        @params goal to be checked in case action is grab orr climb.
    */
    move, !.
action(left,_) :- left, !.
action(right,_) :- right, !.
action(grab,GOAL) :- grab(GOAL), !.
action(shoot,_) :- shoot, !.
action(climb,GOAL) :- (GOAL = 1 -> climb(GOAL), !, fail; climb(GOAL), !).
action(_,_) :- 
    write('UNKNOWN ACTION: '),
    write('Please use move, left, right, grab or shoot.\n').

menu :-
    /**
        @descr keeps printing the menu to the console in USER TEST mode.
    */
    getColisions(GOAL),     % check if hunter it something.
    printHunterPosition,    % print the hunter position.
    getSensors(SENSORES),   % get the sensors of the hunter.
    printInfo(SENSORES),    % print the sensors.
    printScore,             % print the score.
    write('Next action: '), % ask user for next action.
    read(OPTION),           % read the action from user.
    action(OPTION, GOAL),   % execute the action.
    menu.                   % repeat the process.

getStep(HX, HY, up, [NX, NY], ACTION) :- 
    /**
        @descr get the agent next action.
        @params hunter position.
        @params hunter is facing up.
        @params coords after the action step is executed.
        @return action to be executed.
    */
    NX is HX, NY is HY + 1, ACTION = move, !.
getStep(HX, HY, up, [NX, NY], ACTION) :- 
    NX is HX, NY is HY - 1, ACTION = right, 
    retract(a_costs(HX,HY,COST)), 
    NC is COST-25, assert(a_costs(HX,HY,NC)), !.
getStep(HX, HY, up, [NX, NY], ACTION) :- 
    NX is HX - 1, NY is HY, ACTION = left, 
    retract(a_costs(HX,HY,COST)), NC is COST-25, 
    assert(a_costs(HX,HY,NC)), !.
getStep(HX, HY, up, [NX, NY], ACTION) :- 
    NX is HX + 1, NY is HY, ACTION = right, 
    retract(a_costs(HX,HY,COST)), NC is COST-25, 
    assert(a_costs(HX,HY,NC)), !.

getStep(HX, HY, right, [NX, NY], ACTION) :-  
    /**
        @descr get the agent next action.
        @params hunter position.
        @params hunter is facing right.
        @params coords after the action step is executed.
        @return action to be executed.
    */
    NX is HX + 1, NY is HY, ACTION = move, !.
getStep(HX, HY, right, [NX, NY], ACTION) :- 
    NX is HX, NY is HY - 1, ACTION = right, 
    retract(a_costs(HX,HY,COST)), NC is COST-25, 
    assert(a_costs(HX,HY,NC)), !.
getStep(HX, HY, right, [NX, NY], ACTION) :- 
    NX is HX, NY is HY + 1, ACTION = left, 
    retract(a_costs(HX,HY,COST)), NC is COST-25, 
    assert(a_costs(HX,HY,NC)), !.
getStep(HX, HY, right, [NX, NY], ACTION) :- 
    NX is HX - 1, NY is HY, ACTION = right, 
    retract(a_costs(HX,HY,COST)), NC is COST-25, 
    assert(a_costs(HX,HY,NC)), !.

getStep(HX, HY, down, [NX, NY], ACTION) :-  
    /**
        @descr get the agent next action.
        @params hunter position.
        @params hunter is facing down.
        @params coords after the action step is executed.
        @return action to be executed.
    */
    NX is HX, NY is HY -1, ACTION = move, !.
getStep(HX, HY, down, [NX, NY], ACTION) :- 
    NX is HX, NY is HY + 1, ACTION = right, 
    retract(a_costs(HX,HY,COST)), NC is COST-25, 
    assert(a_costs(HX,HY,NC)), !.
getStep(HX, HY, down, [NX, NY], ACTION) :- 
    NX is HX + 1, NY is HY, ACTION = left, 
    retract(a_costs(HX,HY,COST)), NC is COST-25, 
    assert(a_costs(HX,HY,NC)), !.
getStep(HX, HY, down, [NX, NY], ACTION) :- 
    NX is HX - 1, NY is HY, ACTION = right, 
    retract(a_costs(HX,HY,COST)), NC is COST-25, 
    assert(a_costs(HX,HY,NC)), !.

getStep(HX, HY, left, [NX, NY], ACTION) :- 
    /**
        @descr get the agent next action.
        @params hunter position.
        @params hunter is facing left.
        @params coords after the action step is executed.
        @return action to be executed.
    */
    NX is HX - 1, NY is HY, ACTION = move, !.
getStep(HX, HY, left, [NX, NY], ACTION) :- 
    NX is HX, NY is HY + 1, ACTION = right, 
    retract(a_costs(HX,HY,COST)), NC is COST-25, 
    assert(a_costs(HX,HY,NC)), !.
getStep(HX, HY, left, [NX, NY], ACTION) :- 
    NX is HX, NY is HY - 1, ACTION = left, 
    retract(a_costs(HX,HY,COST)), NC is COST-25, 
    assert(a_costs(HX,HY,NC)), !.
getStep(HX, HY, left, [NX, NY], ACTION) :- 
    NX is HX + 1, NY is HY, ACTION = right, 
    retract(a_costs(HX,HY,COST)), NC is COST-25, 
    assert(a_costs(HX,HY,NC)), !.

cellsCost(X,Y, up, 0, COST) :- 
    /**
        @descr get the cost of the adjacent cell on the (2nd parameter)
        when reaching gold.
        @params cell position.
        @params hunter .
        @return cost of the cell.
    */
    U is Y+1, \+w_wall(X,U), a_costs(X,U,COST).
cellsCost(X,Y, down, 0, COST) :- 
    D is Y-1, \+w_wall(X,D), a_costs(X,D,COST).
cellsCost(X,Y, left, 0, COST) :- 
    L is X-1, \+w_wall(L,Y), a_costs(L,Y,COST).
cellsCost(X,Y, right, 0, COST) :- 
    R is X+1, \+w_wall(R,Y), a_costs(R,Y,COST).
cellsCost(X,Y, _, 0, COST) :- 
    L is X-1, \+w_wall(L,Y), a_costs(L,Y,COST).
cellsCost(X,Y, _, 0, COST) :- 
    U is Y+1, \+w_wall(X,U), a_costs(X,U,COST).
cellsCost(X,Y, _, 0, COST) :- 
    R is X+1, \+w_wall(R,Y), a_costs(R,Y,COST).
cellsCost(X,Y, _, 0, COST) :- 
    D is Y-1, \+w_wall(X,D), a_costs(X,D,COST).

cellsCost(X,Y, up, 1, COST) :-  
    /**
        @descr get the cost of the adjacent cell on the (2nd parameter)
        when reaching the ladder to get out of the cave.
        @params cell position.
        @params hunter .
        @return cost of the cell.
    */
    U is Y+1, \+w_wall(X,U), a_visited(X,U), a_costs(X,U,COST).
cellsCost(X,Y, down, 1, COST) :- 
    D is Y-1, \+w_wall(X,D), a_visited(X,D), a_costs(X,D,COST).
cellsCost(X,Y, left, 1, COST) :- 
    L is X-1, \+w_wall(L,Y), a_visited(L,Y), a_costs(L,Y,COST).
cellsCost(X,Y, right, 1, COST) :- 
    R is X+1, \+w_wall(R,Y), a_visited(R,Y), a_costs(R,Y,COST).
cellsCost(X,Y, _, 1, COST) :- 
    L is X-1, \+w_wall(L,Y), a_visited(L,Y), a_costs(L,Y,COST).
cellsCost(X,Y, _, 1, COST) :- 
    U is Y+1, \+w_wall(X,U), a_visited(X,U), a_costs(X,U,COST).
cellsCost(X,Y, _, 1, COST) :- 
    R is X+1, \+w_wall(R,Y), a_visited(R,Y), a_costs(R,Y,COST).
cellsCost(X,Y, _, 1, COST) :- 
    D is Y-1, \+w_wall(X,D), a_visited(X,D), a_costs(X,D,COST).

findCell(X,Y,up,COST,CELL) :- 
    /**
        @descr find the cell with the giving cost as third parameter.
        @params cell position.
        @params hunter facing.
        @params cost of the cell we are looking for.
        @return cell coords with given cost.
    */
    a_costs(NX, NY, COST), 
    NX = X, TY is Y + 1, NY = TY, CELL = [NX, NY], !.
findCell(X,Y,right,COST,CELL) :- 
    a_costs(NX, NY, COST), 
    TX is X + 1, NX = TX, NY = Y, CELL = [NX, NY], !.
findCell(X,Y,down,COST,CELL) :- 
    a_costs(NX, NY, COST), 
    NX = X, TY is Y - 1, NY = TY, CELL = [NX, NY], !.
findCell(X,Y,left,COST,CELL) :- 
    a_costs(NX, NY, COST), 
    TX is X - 1, NX = TX, NY = Y, CELL = [NX, NY], !.
findCell(X,Y,_,COST,CELL) :- 
    a_costs(NX, NY, COST), 
    TX is X - 1, NX = TX, NY = Y, CELL = [NX, NY], !.
findCell(X,Y,_,COST,CELL) :- 
    a_costs(NX, NY, COST), 
    NX = X, TY is Y + 1, NY = TY, CELL = [NX, NY], !.
findCell(X,Y,_,COST,CELL) :- 
    a_costs(NX, NY, COST), 
    TX is X + 1, NX = TX, NY = Y, CELL = [NX, NY], !.
findCell(X,Y,_,COST,CELL) :- 
    a_costs(NX, NY, COST), 
    NX = X, TY is Y - 1, NY = TY, CELL = [NX, NY], !.

nextMove(ACTION, GOAL) :- 
    /**
        @descr finds the next step based on the goal.
        @return action to be executed.
        @params goal is completed already?.
    */
    w_hunter(X,Y,FACING),
    % find all possible moves
    findall(C, cellsCost(X, Y, FACING, GOAL, C), COSTS),
    % find the lower cost cell which fits the goal
    (GOAL = 0 -> min_list(COSTS, COST); max_list(COSTS, COST)),
    % find the adjacent cell with the lowest cost
    findCell(X, Y, FACING, COST, CELL),
    % get the action needed to go the wanted cell
    getStep(X,Y, FACING, CELL, ACTION).

has_pit(X, Y, 1000) :-
    /**
        @descr return specific cost if the cell has a pit.
        @params cell position.
        @return COST.
    */
    E is X + 1, N is Y + 1, a_breeze_at(E, Y), a_breeze_at(X, N), !;
    N is Y + 1, W is X - 1, a_breeze_at(X, N), a_breeze_at(W, Y), !;
    W is X - 1, S is Y - 1, a_breeze_at(W, Y), a_breeze_at(X, S), !;
    S is Y - 1, E is X + 1, a_breeze_at(X, S), a_breeze_at(E, Y), !;
    N is Y + 1, S is Y - 1, a_breeze_at(X, N), a_breeze_at(X, S), !;
    E is X + 1, W is Y + 1, a_breeze_at(E, Y), a_breeze_at(W, Y), !.
has_pit(X, Y, 150) :-
    /**
        @descr return specific cost if the cell maybe has a pit.
        @params cell position.
        @return COST.
    */
    E is X + 1, a_breeze_at(E, Y), !;
    N is Y + 1, a_breeze_at(X, N), !;
    W is X - 1, a_breeze_at(W, Y), !;
    S is Y - 1, a_breeze_at(X, S), !.

has_wumpus(X, Y, 1100) :-
    /**
        @descr return specific cost if the cell has a wumpus.
        @params cell position.
        @return COST.
    */
    E is X + 1, N is Y + 1, a_stench_at(E, Y), a_stench_at(X, N), !;
    N is Y + 1, W is X - 1, a_stench_at(X, N), a_stench_at(W, Y), !;
    W is X - 1, S is Y - 1, a_stench_at(W, Y), a_stench_at(X, S), !;
    S is Y - 1, E is X + 1, a_stench_at(X, S), a_stench_at(E, Y), !;
    N is Y + 1, S is Y - 1, a_stench_at(X, N), a_stench_at(X, S), !;
    E is X + 1, W is Y + 1, a_stench_at(E, Y), a_stench_at(W, Y), !.
has_wumpus(X, Y, 100) :-
    /**
        @descr return specific cost if the cell maybe has a wumpus.
        @params cell position.
        @return COST.
    */
    E is X + 1, a_stench_at(E, Y), !;
    N is Y + 1, a_stench_at(X, N), !;
    W is X - 1, a_stench_at(W, Y), !;
    S is Y - 1, a_stench_at(X, S), !.

has_none(X, Y, 10) :- 
    /**
        @descr return specific cost if the cell probably has nothing.
        @params cell position.
        @return COST.
    */
    E is X + 1, N is Y + 1, a_breeze_at(E, Y), a_stench_at(X, N), !;
    N is Y + 1, W is X - 1, a_breeze_at(X, N), a_stench_at(W, Y), !;
    W is X - 1, S is Y - 1, a_breeze_at(W, Y), a_stench_at(X, S), !;
    S is Y - 1, E is X + 1, a_breeze_at(X, S), a_stench_at(E, Y), !;
    N is Y + 1, S is Y - 1, a_breeze_at(X, N), a_stench_at(X, S), !;
    E is X + 1, W is Y + 1, a_breeze_at(E, Y), a_stench_at(W, Y), !;
    E is X + 1, N is Y + 1, a_stench_at(E, Y), a_breeze_at(X, N), !;
    N is Y + 1, W is X - 1, a_stench_at(X, N), a_breeze_at(W, Y), !;
    W is X - 1, S is Y - 1, a_stench_at(W, Y), a_breeze_at(X, S), !;
    S is Y - 1, E is X + 1, a_stench_at(X, S), a_breeze_at(E, Y), !;
    N is Y + 1, S is Y - 1, a_stench_at(X, N), a_breeze_at(X, S), !;
    E is X + 1, W is Y + 1, a_stench_at(E, Y), a_breeze_at(W, Y), !.

refreshCells(X,Y) :-
    /**
        @descr update knowledge cost agent database.
        @params cell position.
    */
    (
        a_costs(_,_,0) -> 
            (
                a_costs(X,Y,_) -> 
                    retract(a_costs(X,Y,_)); 
                true
                ), assert(a_costs(X,Y,5000)), !, fail
        ; true
        ),
    (
        has_none(X,Y, COST) -> 
            (
                a_costs(X,Y,_) -> 
                    retract(a_costs(X,Y,_)); 
                true
                ), assert(a_costs(X,Y,COST)), !, fail; 
        true
        ), 
    (
        has_wumpus(X,Y, COST) -> 
            AUX1 is COST; 
        AUX1 is 0
        ), 
    (
        has_pit(X,Y, COST) -> 
            AUX2 is COST; 
        AUX2 is 0
        ), 
    AUX is AUX1 + AUX2, 
    (
        a_costs(X,Y,_) -> 
            retract(a_costs(X,Y,_)); 
        true
        ), assert(a_costs(X,Y,AUX)), !.
    
knowledge(X, Y, stench) :- 
    /**
        @descr update cell cost in the knowledge agent database.
        @params cell position.
        @params type of danger.
    */
    L is X - 1, \+w_wall(L,Y), \+a_visited(L,Y), refreshCells(L,Y), fail.
knowledge(X, Y, stench) :- 
    U is Y + 1, \+w_wall(X,U), \+a_visited(X,U), refreshCells(X,U), fail.
knowledge(X, Y, stench) :- 
    R is X + 1, \+w_wall(R,Y), \+a_visited(R,Y), refreshCells(R,Y), fail.
knowledge(X, Y, stench) :- 
    D is Y - 1, \+w_wall(X,D), \+a_visited(X,D), refreshCells(X,D), fail; true.

knowledge(X, Y, breeze) :- 
    L is X - 1, \+w_wall(L,Y), \+a_visited(L,Y), refreshCells(L,Y), fail.
knowledge(X, Y, breeze) :- 
    U is Y + 1, \+w_wall(X,U), \+a_visited(X,U), refreshCells(X,U), fail.
knowledge(X, Y, breeze) :- 
    R is X + 1, \+w_wall(R,Y), \+a_visited(R,Y), refreshCells(R,Y), fail.
knowledge(X, Y, breeze) :- 
    D is Y - 1, \+w_wall(X,D), \+a_visited(X,D), refreshCells(X,D), fail; true.

knowledge(X, Y, safe) :- 
    L is X - 1, \+w_wall(L,Y), \+a_visited(L,Y), 
    (
        a_costs(L,Y,_) -> 
            retract(a_costs(L,Y,_)); 
        true
        ), assert(a_costs(L,Y,0)), fail.
knowledge(X, Y, safe) :- 
    U is Y + 1, \+w_wall(X,U), \+a_visited(X,U), 
    (
        a_costs(X,U,_) -> 
            retract(a_costs(X,U,_)); 
        true
        ), assert(a_costs(X,U,0)), fail.
knowledge(X, Y, safe) :- 
    R is X + 1, \+w_wall(R,Y), \+a_visited(R,Y), 
    (
        a_costs(R,Y,_) -> 
            retract(a_costs(R,Y,_)); 
        true
        ), assert(a_costs(R,Y,0)), fail.
knowledge(X, Y, safe) :- 
    D is Y - 1, \+w_wall(X,D), \+a_visited(X,D), 
    (
        a_costs(X,D,_) -> 
            retract(a_costs(X,D,_)); 
        true
        ), assert(a_costs(X,D,0)), fail; true.


heuristic(_,_) :- 
    /**
        @descr calculate heuristic cost.
        @params sensors perception.
        @return Action to be executed next.
    */
    w_hunter(X,Y,_), w_goal(0), 
    (
        a_costs(X,Y,COST) -> 
            retract(a_costs(X,Y,COST)), 
            N_COST is COST + 25, 
            assert(a_costs(X,Y,N_COST)); 
        assert(a_costs(X,Y,25))
        ), fail.
heuristic(_,_) :- 
    w_hunter(X,Y,_), w_goal(1), 
    (
        a_costs(X,Y,COST) -> 
            retract(a_costs(X,Y,COST)), 
            N_COST is COST - 25, 
            assert(a_costs(X,Y,N_COST)); 
        assert(a_costs(X,Y,25))
        ), fail.
heuristic(_,_) :- 
    w_hunter(X,Y,_), \+a_visited(X,Y), assert(a_visited(X,Y)), fail.
heuristic([_,_,_], climb) :- w_hunter(1,1,_), w_gold(0,0), !.
heuristic([_,_,1], grab) :- !.
heuristic([_,_,_], shoot) :- fail, !.
heuristic([1,_,_], OPTION) :- 
    w_hunter(X,Y,_), 
    (
        \+a_stench_at(X,Y) -> 
            assert(a_stench_at(X,Y)); 
        true
        ), 
        knowledge(X, Y, stench), 
        w_goal(GOAL), nextMove(OPTION, GOAL), !.
heuristic([_,1,_], OPTION) :- 
    w_hunter(X,Y,_), 
    (
        \+a_breeze_at(X,Y) -> 
            assert(a_breeze_at(X,Y)); 
        true
        ), 
        knowledge(X, Y, breeze), 
        w_goal(GOAL), nextMove(OPTION, GOAL), !.
heuristic([_,_,_], OPTION) :- 
    w_hunter(X,Y,_), 
    knowledge(X, Y, safe), w_goal(GOAL), nextMove(OPTION, GOAL), !.

printRange :- 
    /**
        @descr print to the console the current costs for each 
        adjacent cell.
    */
    write('Costs: '), fail.
printRange :- 
    w_hunter(X,Y,_), L is X-1, 
    (
        a_costs(L,Y,LEFT) -> 
            format('[l: ~w] ', LEFT); 
        format('[l: NA] ')
        ), fail.
printRange :- 
    w_hunter(X,Y,_), 
    U is Y+1, 
    (
        a_costs(X,U,UP) -> 
            format('[u: ~w] ', UP); 
        format('[u: NA] ')
        ), fail.
printRange :- 
    w_hunter(X,Y,_), 
    R is X+1, 
    (
        a_costs(R,Y,RIGHT) -> 
            format('[r: ~w] ', RIGHT); 
        format('[r: NA] ')
        ), fail.
printRange :- 
    w_hunter(X,Y,_),
    D is Y-1, 
    (
        a_costs(X,D,DOWN) -> 
            format('[d: ~w].~n', DOWN); 
        format('[d: NA].~n')
        ).

runloop(STEP) :-
    /**
        @descr main loop to run the agent.
        @params step number.
    */
    getColisions(GOAL),            % get colisions 
    getSensors(SENSORES),          % get sensors perception       
    heuristic(SENSORES, OPTION),   % gets the best action to be executed
    (no_logs(NL), NL \= 1 -> printHunterPosition; true),
    (no_logs(NL), NL \= 1 -> printRange; true),
    (no_logs(NL), NL \= 1 -> printInfo(SENSORES); true),
    (no_logs(NL), NL \= 1 -> printScore; true),
    (no_logs(NL), NL \= 1 -> write('Next action: '); true),
    (no_logs(NL), NL \= 1 -> format('~p.~n', [OPTION]); true),
    action(OPTION, GOAL),           % execute the action
    STEP \= -1, N_STEP is STEP + 1, % break loop in pygame
    runloop(N_STEP).                % run the process again

% run the agent through the pygame command
run(pygame) :- clearWorld, assert(no_logs(1)), createWorld, !.
% run the agent through the pygame command on the traditional map
run(pygameMap) :- clearWorld, assert(no_logs(1)), createTWorld, !.
% play the game using CLI
run(user) :- clearWorld, assert(no_logs(0)), createWorld, welcome, init, menu, !.
% run the agent from prolog on the traditional Wumpus world map
run(map) :- clearWorld, assert(no_logs(0)), createTWorld, runloop(0), !.
% run the agent from prolog on a random map
run :- clearWorld, assert(no_logs(0)), createWorld, runloop(0). 

% ============================================================================
% SOUND SYSTEM - Enhanced Stealth Gameplay
% ============================================================================

% Sound levels for different actions
action_sound(idle, 0).
action_sound(move, 1).       % Quiet walk - 1 cell radius
action_sound(left, 0).       % Turning is silent
action_sound(right, 0).
action_sound(shoot, 2).      % Loud shooting - 2 cells radius
action_sound(throw_rock, 4). % VERY loud rock impact - 4 cells radius

% Add sound event
add_sound(X, Y, Loudness, Duration) :-
    assert(sound_event(X, Y, Loudness, Duration)).

% Decay all sounds by 1 turn
decay_sounds :-
    forall(
        sound_event(X, Y, L, D),
        (
            D > 0 ->
                (
                    retract(sound_event(X, Y, L, D)),
                    NewD is D - 1,
                    (NewD > 0 -> assert(sound_event(X, Y, L, NewD)); true)
                )
            ;
                retract(sound_event(X, Y, L, 0))
        )
    ).

% Clear all sounds
clear_sounds :-
    retractall(sound_event(_,_,_,_)).

% Check if Wumpus can hear sound
wumpus_hears_sound(WX, WY, SX, SY, Loudness) :-
    sound_event(SX, SY, Loudness, Duration),
    Duration > 0,
    grid_distance(WX, WY, SX, SY, Dist),
    Dist =< Loudness.

% ============================================================================
% WUMPUS AI STATES - Intelligent Enemy Behavior
% ============================================================================

% Initialize Wumpus AI state
init_wumpus_ai :-
    assert(wumpus_state(1, patrol)),
    assert(wumpus_alert_turns(1, 0)).

% Wumpus detects sound and switches state
wumpus_detect_sound :-
    w_wumpus(WX, WY),
    wumpus_state(1, CurrentState),
    CurrentState \= chasing,  % Chasing has priority
    % Find loudest sound in range
    findall([SX, SY, L], 
        (sound_event(SX, SY, L, D), D > 0, grid_distance(WX, WY, SX, SY, Dist), Dist =< L), 
        Sounds),
    Sounds \= [],
    % Get loudest sound (MaxL not used but needed for structure)
    max_member([MaxSX, MaxSY, _MaxL], Sounds),
    % Switch to investigating
    retract(wumpus_state(1, _)),
    assert(wumpus_state(1, investigating)),
    retractall(wumpus_target(1, _, _)),
    assert(wumpus_target(1, MaxSX, MaxSY)).

% Wumpus sees player (very close - adjacent cell)
wumpus_see_player :-
    w_wumpus(WX, WY),
    w_hunter(HX, HY, _),
    grid_distance(WX, WY, HX, HY, Dist),
    Dist =< 1,  % Adjacent cell
    % Switch to chasing
    retract(wumpus_state(1, _)),
    assert(wumpus_state(1, chasing)).

% Wumpus turn behavior
wumpus_turn :-
    wumpus_state(1, State),
    wumpus_behavior(State).

% PATROL: Random movement in safe areas
wumpus_behavior(patrol) :-
    w_wumpus(X, Y),
    random_adjacent_safe_cell(X, Y, NX, NY),
    retract(w_wumpus(X, Y)),
    assert(w_wumpus(NX, NY)).

% INVESTIGATING: Move toward sound source
wumpus_behavior(investigating) :-
    w_wumpus(WX, WY),
    wumpus_target(1, TX, TY),
    move_toward(WX, WY, TX, TY, NX, NY),
    retract(w_wumpus(WX, WY)),
    assert(w_wumpus(NX, NY)),
    % Check if reached target
    (
        (NX = TX, NY = TY) ->
            (
                retract(wumpus_state(1, _)),
                assert(wumpus_state(1, alert)),
                retract(wumpus_alert_turns(1, _)),
                assert(wumpus_alert_turns(1, 3))
            )
        ;
            true
    ).

% ALERT: Search nearby for 3 turns
wumpus_behavior(alert) :-
    wumpus_alert_turns(1, Turns),
    (
        Turns > 0 ->
            (
                w_wumpus(X, Y),
                random_adjacent_safe_cell(X, Y, NX, NY),
                retract(w_wumpus(X, Y)),
                assert(w_wumpus(NX, NY)),
                retract(wumpus_alert_turns(1, Turns)),
                NewTurns is Turns - 1,
                assert(wumpus_alert_turns(1, NewTurns))
            )
        ;
            (
                retract(wumpus_state(1, _)),
                assert(wumpus_state(1, patrol))
            )
    ).

% CHASING: Fast movement toward player (2 moves per turn!)
wumpus_behavior(chasing) :-
    w_wumpus(WX, WY),
    w_hunter(HX, HY, _),
    % First move
    move_toward(WX, WY, HX, HY, MX1, MY1),
    % Second move (if still far)
    grid_distance(MX1, MY1, HX, HY, Dist),
    (
        Dist > 1 ->
            move_toward(MX1, MY1, HX, HY, MX2, MY2)
        ;
            (MX2 is MX1, MY2 is MY1)
    ),
    retract(w_wumpus(WX, WY)),
    assert(w_wumpus(MX2, MY2)),
    % Check if still close to player
    grid_distance(MX2, MY2, HX, HY, NewDist),
    (
        NewDist > 2 ->
            (
                retract(wumpus_state(1, _)),
                assert(wumpus_state(1, patrol))
            )
        ;
            true
    ).

% ============================================================================
% UTILITY PREDICATES
% ============================================================================

% Helper: Move one cell toward target
move_toward(FromX, FromY, ToX, ToY, NewX, NewY) :-
    DX is ToX - FromX,
    DY is ToY - FromY,
    (
        (abs(DX) > abs(DY), DX > 0) -> (TestX is FromX + 1, TestY is FromY);
        (abs(DX) > abs(DY), DX < 0) -> (TestX is FromX - 1, TestY is FromY);
        (DY > 0) -> (TestX is FromX, TestY is FromY + 1);
        (DY < 0) -> (TestX is FromX, TestY is FromY - 1);
        (TestX is FromX, TestY is FromY)
    ),
    % Validate move (not wall, not pit)
    (
        (\+ w_wall(TestX, TestY), \+ w_pit(TestX, TestY)) ->
            (NewX is TestX, NewY is TestY)
        ;
            (NewX is FromX, NewY is FromY)  % Can't move, stay in place
    ).

% Helper: Random adjacent safe cell
random_adjacent_safe_cell(X, Y, NX, NY) :-
    findall([AX, AY], 
        (
            adjacent_cell(X, Y, AX, AY),
            \+ w_wall(AX, AY),
            \+ w_pit(AX, AY)
        ), 
        SafeCells
    ),
    (
        SafeCells \= [] ->
            random_member([NX, NY], SafeCells)
        ;
            (NX is X, NY is Y)  % No safe cells, stay put
    ).

% Adjacent cells (4 directions)
adjacent_cell(X, Y, AX, AY) :-
    member([DX, DY], [[0,1], [0,-1], [1,0], [-1,0]]),
    AX is X + DX,
    AY is Y + DY.

% Helper: Grid distance (Manhattan)
grid_distance(X1, Y1, X2, Y2, Dist) :-
    DX is abs(X2 - X1),
    DY is abs(Y2 - Y1),
    Dist is DX + DY.

% ============================================================================
% ROCK THROWING SYSTEM
% ============================================================================

% Initialize rocks
init_rocks :-
    assert(h_rocks(2)).  % Start with 2 rocks

% Generate rock pickups (3 pickups on map)
generate_rock_pickups :-
    selectCell(X1, Y1),
    assert(rock_pickup(X1, Y1)),
    selectCell(X2, Y2),
    assert(rock_pickup(X2, Y2)),
    selectCell(X3, Y3),
    assert(rock_pickup(X3, Y3)).

% Throw rock at target
throw_rock(TargetX, TargetY) :-
    h_rocks(Count),
    Count > 0,
    w_hunter(HX, HY, _),
    % Check range (1-4 cells)
    grid_distance(HX, HY, TargetX, TargetY, Dist),
    Dist >= 1,
    Dist =< 4,
    % Create VERY loud sound at target
    add_sound(TargetX, TargetY, 4, 3),
    % Consume rock
    retract(h_rocks(Count)),
    NewCount is Count - 1,
    assert(h_rocks(NewCount)),
    % Update score
    h_score(A), B is A - 5, retract(h_score(_)), assert(h_score(B)),
    (
        no_logs(NL), NL \= 1 -> 
            format('\n\nROCK THROWN to (~d,~d)! Created loud noise.~n', [TargetX, TargetY]); 
        true
    ).

% Collect rock pickup
collect_rock :-
    w_hunter(X, Y, _),
    rock_pickup(X, Y),
    h_rocks(Current),
    Current < 5,  % Max 5 rocks
    retract(rock_pickup(X, Y)),
    retract(h_rocks(Current)),
    NewCount is Current + 1,
    assert(h_rocks(NewCount)),
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\nCOLLECTED ROCK! '); 
        true
    ).

% ============================================================================
% TREASURE CHEST & MIMIC SYSTEM
% ============================================================================

% Generate 3 chests: 1 treasure, 2 mimics
generate_chests :-
    selectCell(X1, Y1),
    selectCell(X2, Y2),
    selectCell(X3, Y3),
    % Randomize which is treasure
    random_permutation([treasure, mimic, mimic], Types),
    nth0(0, Types, T1),
    nth0(1, Types, T2),
    nth0(2, Types, T3),
    assert(chest(1, X1, Y1, T1)),
    assert(chest(2, X2, Y2, T2)),
    assert(chest(3, X3, Y3, T3)).

% Mimic movement (when player far away)
mimic_turn(ChestID) :-
    chest(ChestID, X, Y, mimic),
    \+ chest_opened(ChestID),
    w_hunter(HX, HY, _),
    grid_distance(X, Y, HX, HY, Dist),
    Dist > 3,  % Only move if player > 3 cells away
    % Random move
    random_adjacent_safe_cell(X, Y, NX, NY),
    retract(chest(ChestID, X, Y, mimic)),
    assert(chest(ChestID, NX, NY, mimic)).

% Process all mimic movements
process_mimic_turns :-
    forall(
        (chest(ID, _, _, mimic), \+ chest_opened(ID)),
        mimic_turn(ID)
    ).

% Open chest
open_chest :-
    w_hunter(X, Y, _),
    chest(ChestID, X, Y, Type),
    \+ chest_opened(ChestID),
    assert(chest_opened(ChestID)),
    handle_chest_open(ChestID, Type, X, Y).

% Handle treasure chest (ChestID unused but kept for signature)
handle_chest_open(_ChestID, treasure, X, Y) :-
    % Found treasure!
    retract(w_gold(_, _)),
    assert(w_gold(X, Y)),
    retract(w_goal(0)),
    assert(w_goal(1)),
    h_score(A), B is A + 1000, retract(h_score(_)), assert(h_score(B)),
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\n🎉 TREASURE FOUND! Now escape to (1,1)!\n'); 
        true
    ).

% Handle mimic attack! (ChestID unused but kept for signature)
handle_chest_open(_ChestID, mimic, X, Y) :-
    % Mimic attack!
    assert(player_stunned(2)),
    % Create VERY loud sound
    add_sound(X, Y, 5, 4),
    % Wumpus switches to chasing!
    retract(wumpus_state(1, _)),
    assert(wumpus_state(1, chasing)),
    % Damage player score
    h_score(A), B is A - 500, retract(h_score(_)), assert(h_score(B)),
    (
        no_logs(NL), NL \= 1 -> 
            write('\n\n💀 MIMIC ATTACK! You are stunned for 2 turns! Wumpus is chasing!\n'); 
        true
    ).

% Process stun
process_stun :-
    (
        player_stunned(Turns),
        Turns > 0 ->
            (
                retract(player_stunned(Turns)),
                NewTurns is Turns - 1,
                (NewTurns > 0 -> assert(player_stunned(NewTurns)); true)
            )
        ;
            retractall(player_stunned(_))
    ).

% Check if player is stunned
is_player_stunned :-
    player_stunned(Turns),
    Turns > 0.

% ============================================================================
% FOG OF WAR SYSTEM
% ============================================================================

% Initialize fog (all cells hidden)
init_fog :-
    retractall(fog_revealed(_,_)),
    retractall(fog_visible(_,_)).

% Update fog based on player position
update_fog :-
    retractall(fog_visible(_,_)),
    w_hunter(HX, HY, _),
    VisionRange = 2,
    % Mark visible cells
    forall(
        (
            between(1, 4, X),
            between(1, 4, Y),
            grid_distance(HX, HY, X, Y, Dist),
            Dist =< VisionRange
        ),
        (
            assert(fog_visible(X, Y)),
            assert(fog_revealed(X, Y))
        )
    ).

% Check if cell is visible
is_visible(X, Y) :-
    fog_visible(X, Y).

% Check if cell has been revealed
is_revealed(X, Y) :-
    fog_revealed(X, Y).

% ============================================================================
% ENHANCED TURN SYSTEM
% ============================================================================

% Process player turn (with sound generation)
process_player_action(Action) :-
    % Check if stunned
    (
        is_player_stunned ->
            (
                no_logs(NL), NL \= 1 -> 
                    write('\n⚠️  STUNNED! Cannot act this turn.\n'); 
                true
            )
        ;
            (
                % Execute action
                action_sound(Action, Loudness),
                (
                    Loudness > 0 ->
                        (
                            w_hunter(HX, HY, _),
                            add_sound(HX, HY, Loudness, 1)
                        )
                    ;
                        true
                )
            )
    ).

% Process environment turn
process_environment_turn :-
    % Decay sounds
    decay_sounds,
    % Process stun
    process_stun,
    % Mimic movement
    process_mimic_turns,
    % Update fog
    update_fog,
    % Wumpus AI
    wumpus_detect_sound,
    wumpus_see_player,
    wumpus_turn. 