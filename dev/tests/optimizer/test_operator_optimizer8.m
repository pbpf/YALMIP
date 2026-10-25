function tests = test_operator_optimizer8
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

% Make sure vectorized multiple-call works
x = S.sdpvar(1,1);
u = S.sdpvar(1,1);
P = optimizer([x <= u],-x,[],u,x)
U = P{[7 8 9]};
testCase.assertTrue(norm([7 8 9]-U)<1e-7);