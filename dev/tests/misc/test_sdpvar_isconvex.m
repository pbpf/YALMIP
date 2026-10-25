function tests = test_isconvex
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
testCase.assertTrue(isconvex(x+y));
testCase.assertTrue(isconvex(x+y^2));
testCase.assertTrue(isconvex(exp(x+y)));
testCase.assertTrue(isconvex(max(x,exp(x+y))));
testCase.assertTrue(~isconvex(-exp(x+y)));
testCase.assertTrue(~isconvex(-max(x,exp(x+y))));
testCase.assertTrue(isnan(isconvex(max(x,min(x,-x)))));






 
