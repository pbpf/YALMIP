function tests = test_global_bmibnb_integer
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,1);
obj = blackbox(x,@(x)(sin(10*x)+abs(sin(x))+x));
sol=optimize((integer(x)) + (-pi <= x <= pi),obj,sdpsettings('solver','bmibnb'));

testCase.assertTrue(sol.problem==0)
testCase.assertTrue(abs(value(x, sol)--2) <= 1e-4)
