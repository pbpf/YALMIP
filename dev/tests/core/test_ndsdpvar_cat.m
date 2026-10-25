function tests = test_ndsdpvar_cat
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,2,3);
p = randn(1,2,3);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,p, sol);

testCase.assertTrue(isequal(value(cat(1,x,x), sol),cat(1,p,p)))
testCase.assertTrue(isequal(value(cat(2,x,x), sol),cat(2,p,p)))
testCase.assertTrue(isequal(value(cat(3,x,x), sol),cat(3,p,p)))

testCase.assertTrue(isequal(value(cat(1,x,x,x), sol),cat(1,p,p,p)))
testCase.assertTrue(isequal(value(cat(2,x,x,x), sol),cat(2,p,p,p)))
testCase.assertTrue(isequal(value(cat(3,x,x,x), sol),cat(3,p,p,p)))

y = S.sdpvar(1,2,3);
q = randn(1,2,3);
sol = assign(y,q, sol);
testCase.assertTrue(isequal(value(cat(1,x,y), sol),cat(1,p,q)))
testCase.assertTrue(isequal(value(cat(2,x,y), sol),cat(2,p,q)))
testCase.assertTrue(isequal(value(cat(3,x,y), sol),cat(3,p,q)))

testCase.assertTrue(isequal(value(cat(1,p,y), sol),cat(1,p,q)))
testCase.assertTrue(isequal(value(cat(2,p,y), sol),cat(2,p,q)))
testCase.assertTrue(isequal(value(cat(3,p,y), sol),cat(3,p,q)))

testCase.assertTrue(isequal(value(cat(1,x,q), sol),cat(1,p,q)))
testCase.assertTrue(isequal(value(cat(2,x,q), sol),cat(2,p,q)))
testCase.assertTrue(isequal(value(cat(3,x,q), sol),cat(3,p,q)))

z = S.sdpvar(1,2);
r = randn(1,2);
sol = assign(z,r, sol);
testCase.assertTrue(isequal(value(cat(3,x,z), sol),cat(3,p,r)))
