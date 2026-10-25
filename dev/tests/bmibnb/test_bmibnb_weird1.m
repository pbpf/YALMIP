function tests = test_bmibnb_weird1
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,1);
sol = optimize((-pi <= x <= pi),2^sin(x),sdpsettings('solver','bmibnb'))
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(x, sol)--pi/2) <= 1e-3)