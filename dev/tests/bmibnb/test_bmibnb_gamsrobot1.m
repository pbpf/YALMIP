function tests = test_global_bmibnb_gamsrobot1
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
x1 = S.sdpvar(1,1);
x2 = S.sdpvar(1,1);
x3 = S.sdpvar(1,1);
x4 = S.sdpvar(1,1);
t = S.sdpvar(1,1);
p = x1 - x2 - x3 - x1*x3 + x1*x4 + x2*x3 - x2*x4;
F = (x1+4*x2 <= 8) + (4*x1+x2 <= 12) + (3*x1+4*x2 <= 12) + (2*x3+x4 <= 8) + (x3+2*x4 <= 8) + (x3+x4 <= 5)+([x1;x2;x3;x4]>=0);
F = F+(p<=t);
obj = t;

sol = optimize(F,obj,sdpsettings('solver','bmibnb'))

testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(obj, sol)--13) <= 1e-5)