function tests = test_sdpvar_norm
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% To improve performance, we don't introduce auxilliary variables for
% elements which are fixed
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,1, sol);
testCase.assertTrue(abs(value(norm([x;-3],1), sol) - 4)<= 1e-8)
optsol = optimize(norm([x;-3],1)<=y,y);
testCase.assertTrue(norm(value(y, optsol) - 3)<= 1e-8)
testCase.assertTrue(norm(value(x, optsol) - 0)<= 1e-8)
