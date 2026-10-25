function tests = test_operator_optimizer12
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Tests bug #162 that made eliminatevariables flawed.
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
P = optimizer(cone([1;x])+cone([y;x])+[1 x*y;x*y x+y],x,sdpsettings('solver',''),y,x)
testCase.assertTrue(abs(P{0}) <= 1e-3)
