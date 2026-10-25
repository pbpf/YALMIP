function tests = test_rcone
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
y = S.sdpvar(1);
z = S.sdpvar(3,1);

sol = optimize([z>=1, rcone(z,x,y)],x+y);
testCase.assertTrue(abs(value(x*y, sol)-1.5) <= 1e-4);

function test2(testCase)
S = yalmip.Session();
x = S.sdpvar(4,1);
z = S.sdpvar(1,1);
y = S.sdpvar(1,1);
sol = optimize([(x-1)'*(x-1) <= y*z,y>=0,z>=0], y + z)
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(all(abs(value(x, sol)-1)<1e-4));
testCase.assertTrue(abs(value(y+z, sol))<1e-4);
