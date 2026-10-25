function tests = test_global_bmibnb_sin1
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,1);
obj = sin(10*x)+abs(x)
sol = optimize((-pi <= x <= pi),obj,sdpsettings('solver','bmibnb'));

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(obj, sol)--0.84792) <= 1e-4)