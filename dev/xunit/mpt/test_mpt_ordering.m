function test_mpt_ordering
S = yalmip.Session();

yalmip clear
x1 = S.sdpvar(1,1);
x3 = S.sdpvar(1,1);
x2 = S.sdpvar(1,1);

F = [1<=x1<=1.1; 2<=x2<=2.2; x3==x1-x2 ];
cost = x1+x2+x3;
sol = solvemp(F, cost, [], [x1; x2], x3); 
% Correct
F1 = full(sol{1}.Fi{1});

% Wrong
sol = solvemp(F, cost, [], [x2; x1], x3); 
F2 = full(sol{1}.Fi{1});

assert(norm(F1-fliplr(F2)) <= 1e-5)


