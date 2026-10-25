function tests = test_global_bmibnb_sahinidis
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();


x1 = S.sdpvar(1,1);
x2 = S.sdpvar(1,1);
F = (0 <= x1 <= 6)+(0 <= x2 <= 4) + (x1*x2 <= 4); 

obj = -x1-x2;

sol = optimize(F,obj,sdpsettings('solver','bmibnb'))

testCase.assertTrue(abs(value(obj, sol)--6.66666666) <= 1e-6)