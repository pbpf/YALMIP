function tests = test_robust_15
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
x = S.sdpvar(2,1);
w = S.sdpvar(2,1);
P = eye(2);
S = [120 140;140 180]/4;

w = S.sdpvar(2,1);
x = S.sdpvar(2,1);

sol = optimize([(x+w)'*P*(x+w)<=1,w'*S*w <= 1,uncertain(w)],x(1),sdpsettings('verbose',1))
value(x, sol)

testCase.assertTrue((sol.problem == 0) || (sol.problem == 4));
testCase.assertTrue(abs(value(x(1), sol)--0.4) <= 1e-3);

M = cone([1;chol(P)*(x+w)]);
W = cone([1;chol(S)*w]);
sol = optimize([M,W,uncertain(w)],x(1),sdpsettings('verbose',1))
value(x, sol)

testCase.assertTrue((sol.problem == 0) || (sol.problem == 4));
testCase.assertTrue(abs(value(x(1), sol)--0.4) <= 1e-3);


