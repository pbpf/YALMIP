function tests = test_sdpvar_kronecker
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

a = [1 2 3;4 5 6];
b = [7 8 9];

A = S.sdpvar(2,3);
B = S.sdpvar(1,3);
sol = struct('eval',struct('variables',[],'optvar',[],'values',[]));
sol = assign(A,a, sol);
sol = assign(B,b, sol);

% We have special code for vector arguments.
% Make sure these work...
% Row vector
testCase.assertTrue(isequal(value(kron(A,b), sol),kron(a,b)))
testCase.assertTrue(isequal(value(kron(b,A), sol),kron(b,a)))
testCase.assertTrue(isequal(value(kron(a,B), sol),kron(a,b)))
testCase.assertTrue(isequal(value(kron(B,a), sol),kron(b,a)))
testCase.assertTrue(isequal(value(kron(A,B), sol),kron(a,b)))
% Column vector
b = [7 8 9]';
B = S.sdpvar(3,1);
sol = assign(B,b, sol);
testCase.assertTrue(isequal(value(kron(A,b), sol),kron(a,b)))
testCase.assertTrue(isequal(value(kron(b,A), sol),kron(b,a)))
testCase.assertTrue(isequal(value(kron(a,B), sol),kron(a,b)))
testCase.assertTrue(isequal(value(kron(B,a), sol),kron(b,a)))
testCase.assertTrue(isequal(value(kron(A,B), sol),kron(a,b)))

% Scalar
b = 1;
B = S.sdpvar(1,1);
sol = assign(B,b, sol);
testCase.assertTrue(isequal(value(kron(A,b), sol),kron(a,b)))
testCase.assertTrue(isequal(value(kron(b,A), sol),kron(b,a)))
testCase.assertTrue(isequal(value(kron(a,B), sol),kron(a,b)))
testCase.assertTrue(isequal(value(kron(B,a), sol),kron(b,a)))
testCase.assertTrue(isequal(value(kron(A,B), sol),kron(a,b)))

% General matrix
b = [6 7 8;9 10 11];
B = S.sdpvar(2,3);
sol = assign(B,b, sol);
testCase.assertTrue(isequal(value(kron(A,b), sol),kron(a,b)))
testCase.assertTrue(isequal(value(kron(b,A), sol),kron(b,a)))
testCase.assertTrue(isequal(value(kron(a,B), sol),kron(a,b)))
testCase.assertTrue(isequal(value(kron(B,a), sol),kron(b,a)))
testCase.assertTrue(isequal(value(kron(A,B), sol),kron(a,b)))


