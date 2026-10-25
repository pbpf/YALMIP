function tests = test_dualize_sdp
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% TEST 1
A = randn(3,3);A = -A*A';
P = S.sdpvar(3,3);
t = S.sdpvar(1,1);
y = S.sdpvar(1,1);
F = (A'*P+P*A <= -eye(3));
F = F + (P >= A*A') + (P(3,3)>=0) + (t+y >= 7) + (P(2,2)>=4)+(P(1,1:2)>=t) + (t>=12);
obj = trace(P)+y;
    
sol1  = optimize(F,obj,sdpsettings('verbose',0));
obj1 = value(obj, sol1);
p1   = check(F, sol1);

sol2 = optimize(F,obj,sdpsettings('dualize',1,'verbose',0));
obj2 = value(obj, sol2);
p2   = check(F, sol2);

testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(sol2.problem == 0);
testCase.assertTrue(abs(obj1 - obj2) <= 1e-4);
testCase.assertTrue(abs(min(p1))<= 1e-4)
testCase.assertTrue(abs(min(p2))<= 1e-4)


function test2(testCase)
S = yalmip.Session();

A = randn(3,3);A = -A*A';
P = S.sdpvar(3,3);
t = S.sdpvar(1,1);
y = S.sdpvar(1,1);
F = (A'*P+P*A <= -eye(3));
F = F + (P >= 0) + (P(3,3)>=0) + (t+y >= 7) + (P(2,2)>=4)+(P(1,1:2)>=t) + (t>=12);
obj = trace(P)+y;
    
sol1  = optimize(F,obj,sdpsettings('verbose',0));
obj1 = value(obj, sol1);
p1   = check(F, sol1);

sol2 = optimize(F,obj,sdpsettings('dualize',1,'verbose',0));
obj2 = value(obj, sol2);
p2   = check(F, sol2);
testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(sol2.problem == 0);
testCase.assertTrue(abs(obj1 - obj2) <= 1e-3);
testCase.assertTrue(abs(min(p1))<= 1e-3)
testCase.assertTrue(abs(min(p2))<= 1e-3)

function test3(testCase)
S = yalmip.Session();

A = randn(3,3);A = -A*A';
P = S.sdpvar(3,3);
t = S.sdpvar(1,1);
y = S.sdpvar(1,1);
F = (A'*P+P*A <= -eye(3));
F = F + (P >= 0) + (P(3,3)>=0) + (t+y >= 7) + (P(2,2)>=4)+(P(1,1:2)>=t) + (t>=0);
obj = trace(P)+y;

sol1  = optimize(F,obj,sdpsettings('verbose',0));
obj1 = value(obj, sol1);
p1   = check(F, sol1);

sol2 = optimize(F,obj,sdpsettings('dualize',1,'verbose',0));
obj2 = value(obj, sol2);
p2   = check(F, sol2);

testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(sol2.problem == 0);
testCase.assertTrue(abs(obj1 - obj2) <= 1e-4);
testCase.assertTrue(abs(min(p1))<= 1e-4)
testCase.assertTrue(abs(min(p2))<= 1e-4)


function test4(testCase)
S = yalmip.Session();

A = randn(3,3);A = -A*A';
P = S.sdpvar(3,3);
t = S.sdpvar(1,1);
y = S.sdpvar(1,1);
F = (A'*P+P*A <= -eye(3));
F = F + (P >= 0) + (P(3,3)>=0) + (t-y >= 7) + (P(2,2)>=4)+(P(1,1:2)>=t) + (t>=0);
obj = trace(P);

sol1  = optimize(F,obj,sdpsettings('verbose',0));
obj1 = value(obj, sol1);
p1   = check(F, sol1);

sol2 = optimize(F,obj,sdpsettings('dualize',1,'verbose',0));
obj2 = value(obj, sol2);
p2   = check(F, sol2);

testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(sol2.problem == 0);
testCase.assertTrue(abs(obj1 - obj2) <= 1e-4);
testCase.assertTrue(abs(min(p1))<= 1e-4)
testCase.assertTrue(abs(min(p2))<= 1e-4)


function test5(testCase)
S = yalmip.Session();

A = magic(3) - eye(3)*16;%randn(3,3);A = -A*A';
P = S.sdpvar(3,3);
t = S.sdpvar(1,1);
y = S.sdpvar(1,1);
F = (A'*P+P*A <= -eye(3));
F = F + (P >= A*A') + (P(3,3)>=0) + (t+y >= 7) + (P(2,2)>=4)+(P(1,1:2)>=t) + (t>=12)+(t>=-12);
obj = trace(P)+y;

sol1  = optimize(F,obj,sdpsettings('verbose',0));
obj1 = value(obj, sol1);
p1   = check(F, sol1);

sol2 = optimize(F,obj,sdpsettings('dualize',1,'verbose',0));
obj2 = value(obj, sol2);
p2   = check(F, sol2);

testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(sol2.problem == 0);
testCase.assertTrue(abs(obj1 - obj2) <= 1e-4);
testCase.assertTrue(abs(min(p1))<= 1e-4)
testCase.assertTrue(abs(min(p2))<= 1e-4)


function test6(testCase)
S = yalmip.Session();

t = S.sdpvar(1,1);
y = S.sdpvar(1,1);
A = randn(3,3);A = -A*A';
P = S.sdpvar(3,3);
F = (A'*P+P*A <= -eye(3));
F = F + (P >= A*A') + (P(3,3)>=0) + (t+y >= 7) + (P(2,2)>=4)+(P(1,1:2)>=t) + (t>=12)+(t>=-12);
obj = trace(P)+y+t;

sol1  = optimize(F,obj,sdpsettings('verbose',0));
obj1 = value(obj, sol1);
p1   = check(F, sol1);

sol2 = optimize(F,obj,sdpsettings('dualize',1,'verbose',0));
obj2 = value(obj, sol2);
p2   = check(F, sol2);

testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(sol2.problem == 0);
testCase.assertTrue(abs(obj1 - obj2) <= 1e-4);
testCase.assertTrue(abs(min(p1))<= 1e-4)
testCase.assertTrue(abs(min(p2))<= 1e-4)


function test7(testCase)
S = yalmip.Session();
A =(magic(3)-eye(3)*16);
P = S.sdpvar(3,3);
t = S.sdpvar(1,1);
y = S.sdpvar(1,1);
F = (A'*P+P*A <= -eye(3));
F = F + (P >= A*A') + (P(3,3)>=0) + (P>=0) + (t+y >= 7) + (P(2,2)>=4)+(P(1,1:2)>=t) + (t>=12)+(t>=-12);
obj = trace(P)+y+t;

sol1  = optimize(F,obj,sdpsettings('verbose',0));
obj1 = value(obj, sol1);
p1   = check(F, sol1);

sol2 = optimize(F,obj,sdpsettings('dualize',1,'verbose',0));
obj2 = value(obj, sol2);
p2   = check(F, sol2);

testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(sol2.problem == 0);
testCase.assertTrue(abs(obj1 - obj2) <= 1e-4);
testCase.assertTrue(abs(min(p1))<= 1e-4)
testCase.assertTrue(abs(min(p2))<= 1e-4)


function test8(testCase)
S = yalmip.Session();

t = S.sdpvar(1,1);
A = randn(3,3);A = -A*A';
P = S.sdpvar(3,3);
%t = sdpvar(1,1);
y = S.sdpvar(1,1);
F = (A'*P+P*A <= -eye(3));
F = F + (P >= A*A') + (P(3,3)>=0) + (P>=0) + (t+y >= 7) + (t+y >= 7) + (P(2,2)>=4)+(P(1,1:2)>=t) + (t>=12)+(t>=-12);
obj = trace(P)+y+t;

sol1  = optimize(F,obj,sdpsettings('verbose',0));
obj1 = value(obj, sol1);
p1   = check(F, sol1);

sol2 = optimize(F,obj,sdpsettings('dualize',1,'verbose',0));
obj2 = value(obj, sol2);
p2   = check(F, sol2);

testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(sol2.problem == 0);
testCase.assertTrue(abs(obj1 - obj2) <= 1e-4);
testCase.assertTrue(abs(min(p1))<= 1e-4)
testCase.assertTrue(abs(min(p2))<= 1e-4)


function test9(testCase)
S = yalmip.Session();

A = randn(3,3);A = -A*A';
P = S.sdpvar(3,3);
t = S.sdpvar(1,1);
y = S.sdpvar(1,1);
F = (A'*P+P*A <= -eye(3));
F = F + (2*P >= A*A') + (P(3,3)>=0) + (P>=0) + (t+y >= 7) + (t+y >= 7) + (P(2,2)>=4)+(P(1,1:2)>=t) + (t>=12)+(t>=-12);
obj = trace(P)+y+t;

sol1  = optimize(F,obj,sdpsettings('verbose',0));
obj1 = value(obj, sol1);
p1   = check(F, sol1);

sol2 = optimize(F,obj,sdpsettings('dualize',1,'verbose',0));
obj2 = value(obj, sol2);
p2   = check(F, sol2);

testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(sol2.problem == 0);
testCase.assertTrue(abs(obj1 - obj2) <= 1e-4);
testCase.assertTrue(abs(min(p1))<= 1e-4)
testCase.assertTrue(abs(min(p2))<= 1e-4)

function test10(testCase)
S = yalmip.Session();

K = S.sdpvar(4);
sol = optimize([K>=0,K(2,3)==1],trace(K)+norm(K(:)),sdpsettings('dualize',1,'verbose',0));

testCase.assertTrue(sol.problem == 0);

function test11(testCase)
S = yalmip.Session();

N = 2;
X = S.sdpvar(N,N,'hermitian','complex');
x = S.sdpvar(3,1);
t = S.sdpvar(1,1);
obj = t;
F = [X>=0,x>=1, X(1)+x(3) == 7];
F = [F,cone([1;t])];
opts = sdpsettings('dualize',0,'verbose',0);
sol1 = optimize(F,-obj,opts);
o1 = value(obj, sol1);
opts = sdpsettings('dualize',1,'verbose',0);
sol2 = optimize(F,-obj,opts);
o2 = value(obj, sol2);
testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(sol2.problem == 0);
testCase.assertTrue(abs(o1 - o2) <= 1e-4);


function test12(testCase)
S = yalmip.Session();

N = 2;
X = S.sdpvar(N,N,'hermitian','complex');
x = S.sdpvar(3,1);
t = S.sdpvar(1,1);
obj = t;
F = [X>=0, X(1)+x(3) == 7];
F = [F,cone([1;t]),cone([30;X(:)])];
opts = sdpsettings('dualize',1,'verbose',1,'sedumi.free',0);
sol1 = optimize(F,-obj,opts);
o1 = value(obj, sol1);
opts = sdpsettings('dualize',0,'verbose',1,'sedumi.free',0);
sol2 = optimize(F,-obj,opts);
o2 = value(obj, sol2);
testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(sol2.problem == 0);
testCase.assertTrue(abs(o1 - o2) <= 1e-4);

function test13(testCase)
S = yalmip.Session();
N = 5;
X = S.sdpvar(N,N,'hermitian','complex');
F = [X>=0, X(1) == 2];
opts = sdpsettings('dualize',1,'verbose',1);
sol = optimize(F,trace(X),opts);
testCase.assertTrue(sol.problem == 0);
