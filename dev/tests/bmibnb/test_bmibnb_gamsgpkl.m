function tests = test_global_bmibnb_gamsgpkl
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
x1 = S.sdpvar(1,1);
x2 = S.sdpvar(1,1);
t = S.sdpvar(1,1);

F = ([x1;x2]>=0);
F = F + (- x1 + x2 <= 1);
F = F + (x1 - x2 <= 1);
F = F + (- x1 + 2*x2 <= 3);
F = F + (2*x1 - x2 <= 3);
obj = (2*x1 - 2*x1*x1 + 2*x1*x2 + 3*x2 - 2*x2*x2);
F = F + (obj<=t);
sol = optimize(F,obj,sdpsettings('solver','bmibnb'))
testCase.assertTrue(abs(value(obj, sol)--3) <= 1e-4)