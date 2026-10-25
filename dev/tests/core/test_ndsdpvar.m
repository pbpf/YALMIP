function tests = test_ndsdpvar
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

x = S.sdpvar(1,2,3);
p = randn(1,2,3);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(x,p, sol)

testCase.assertTrue(isequal(value(x, sol),p))
testCase.assertTrue(isequal(value(x(:), sol),p(:)))

testCase.assertTrue(isequal(value(sum(x), sol),sum(p)))
testCase.assertTrue(isequal(value(sum(x,1), sol),sum(p,1)))
testCase.assertTrue(isequal(value(sum(x,2), sol),sum(p,2)))
testCase.assertTrue(isequal(value(sum(x,3), sol),sum(p,3)))

testCase.assertTrue(isequal(value(diff(x), sol),diff(p)))
testCase.assertTrue(isequal(value(diff(x,1), sol),diff(p,1)))
testCase.assertTrue(norm(sum(value(diff(x,2), sol)-diff(p,2))) <= 1e-4)
testCase.assertTrue(norm(sum(value(diff(x,3), sol)-diff(p,3))) <= 1e-4)

testCase.assertTrue(isequal(value(diff(x), sol),diff(p)))
testCase.assertTrue(isequal(value(diff(x,1,1), sol),diff(p,1,1)))
testCase.assertTrue(isequal(value(diff(x,2,1), sol),diff(p,2,1)))
testCase.assertTrue(isequal(value(diff(x,3,1), sol),diff(p,3,1)))

testCase.assertTrue(isequal(value(diff(x), sol),diff(p)))
testCase.assertTrue(isequal(value(diff(x,1,2), sol),diff(p,1,2)))
testCase.assertTrue(isequal(value(diff(x,2,2), sol),diff(p,2,2)))
testCase.assertTrue(isequal(value(diff(x,3,2), sol),diff(p,3,2)))

x = S.sdpvar(1,2,3);
y = S.sdpvar(1,2,3);
p1 = randn(1,2,3);
p2 = randn(1,2,3);
sol = assign(x,p1, sol)
sol = assign(y,p2, sol)
z =  x - y;
testCase.assertTrue(isequal(value(z(:), sol),p1(:)-p2(:)))

x = S.sdpvar(1,2,3);
y = S.sdpvar(1,1);
p1 = randn(1,2,3);
p2 = randn(1);
sol = assign(x,p1, sol)
sol = assign(y,p2, sol)
z =  x - y;
testCase.assertTrue(isequal(value(z(:), sol),p1(:)-p2(:)))

X = randn(2,3,4);
Xv = S.sdpvar(2,3,4);
sol = assign(Xv,X, sol);
testCase.assertTrue(norm(value(max(Xv,[],3), sol)-max(X,[],3)) <= 1e-6);
s1 = value(max(Xv,[],2), sol);
s2 = max(X,[],2);
testCase.assertTrue(norm(s1(:)-s2(:)) <= 1e-6);
s1 = value(max(Xv,[],1), sol);
s2 = max(X,[],1);
testCase.assertTrue(norm(s1(:)-s2(:)) <= 1e-6);
X = randn(4,2,3,2);
Xv = S.sdpvar(4,2,3,2);
sol = assign(Xv,X, sol);
s1 = value(max(Xv,[],4), sol);
s2 = max(X,[],4);
testCase.assertTrue(norm(s1(:)-s2(:)) <= 1e-6);
s1 = value(max(Xv,[],3), sol);
s2 = max(X,[],3);
testCase.assertTrue(norm(s1(:)-s2(:)) <= 1e-6);
s1 = value(max(Xv,[],2), sol);
s2 = max(X,[],2);
testCase.assertTrue(norm(s1(:)-s2(:)) <= 1e-6);
s1 = value(max(Xv,[],1), sol);
s2 = max(X,[],1);
testCase.assertTrue(norm(s1(:)-s2(:)) <= 1e-6);

function r = isequal(a,b)
r = (norm(a(:)-b(:)) < 1e-12) & all(size(a) == size(b));