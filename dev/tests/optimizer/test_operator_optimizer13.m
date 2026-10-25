function tests = test_operator_optimizer13
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Testing nonlinearly parameterized SDP
A = S.sdpvar(3,3,'full');
P = S.sdpvar(3,3);
A0 = randn(3);A0 = -A0*A0';
C =  [A'*P+P*A <= -eye(3), P>=0];
M = optimizer(C,trace(P),sdpsettings('solver','sedumi,mosek','verbose',2),A,P);
P0 = M{A0};
sol = optimize([A0'*P+P*A0 <= -eye(3), P>=0],trace(P));
testCase.assertTrue(abs(trace(P0)-trace(value(P, sol))) <= 1e-3)

Q0 = randn(3);Q0 = Q0*Q0';
Q = S.sdpvar(3);
M = optimizer(C,trace(Q*P),sdpsettings('solver','sedumi,mosek'),{A,Q},P);
P0 = M{{A0,Q0}};
optsol = optimize([A0'*P+P*A0 <= -eye(3), P>=0],trace(Q0*P));
testCase.assertTrue(abs(trace(Q0*P0)-trace(Q0*value(P, optsol))) <= 1e-3)

function test2(testCase)
S = yalmip.Session();
% Test a case where an SDP constraint boils down to a semidefinite constant
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
P = optimizer([[y*x y;y 1] >=0, [x 1;1 2]>=0],x,sdpsettings('solver','sedumi,mosek'),y,x);
testCase.assertTrue(abs(P{0}-.5) <= 1e-4);