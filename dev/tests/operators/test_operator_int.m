function tests = test_operator_int
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

% Ordering should not make difference
x1 = S.sdpvar(1,1);
x2 = S.sdpvar(1,1);
p = 4*x1^4 + x1*x2;
I1 = int(p,[x2 x1],[0 2],[1 5]);
I2 = int(p,[x1 x2],[2 0],[5 1]);
testCase.assertTrue(I1 == I2)

x1 = S.sdpvar(1,1);
x2 = S.sdpvar(1,1);
u = S.sdpvar(1,1);
p = 4*x1^4 + x1*x2;
I1 = int(p,[x2 x1],[0 2],[1 u]);
I2 = int(p,[x1 x2],[2 0],[u 1]);
testCase.assertTrue((I1-I2) == 0);

I1 = int(p,[x2 x1]);
I2 = 0.2500*x1^2*x2^2+0.8000*x1^5*x2;
testCase.assertTrue((I1-I2) == 0);