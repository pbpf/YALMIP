function tests = test_global_bmibnb_gamsrobot2
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
x1 = S.sdpvar(1,1);
x2 = S.sdpvar(1,1);
x3 = S.sdpvar(1,1);
x4 = S.sdpvar(1,1);
x5 = S.sdpvar(1,1);
t = S.sdpvar(1,1);
p = 42*x1-50*x1^2+44*x2-50*x2^2+45*x3-50*x3^2+47*x4-50*x4^2+47.5*x5-50*x5^2;
F = ([20 12 11 7 4]*[x1;x2;x3;x4;x5] <= 40) + (0<=[x1;x2;x3;x4;x5]<=1);
obj = p;

sol = optimize(F,obj,sdpsettings('solver','bmibnb'))

testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(obj, sol)--17) <= 1e-3)
