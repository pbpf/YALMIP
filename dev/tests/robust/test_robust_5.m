function tests = test_robust_5
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
% Problem with two separable polytope uncertainties
randn('seed',0);
A1 = randn(8,2);
A2 = randn(8,2);
x0 = randn(2,1);
b1 = A1*x0+1;
b2 = A2*x0+1;

w2 = S.sdpvar(2,1);
w1 = S.sdpvar(2,1);
x = S.sdpvar(1,1);

sol1 = optimize([uncertain([w1;w2]), x+sum(w1)+sum(w2)<=0,A1*w1 <= b1, A2*w2 <= b2],-x,sdpsettings('verbose',0));
obj1 = value(-x, sol1);
sol2 = optimize([A1*w1 <= b1,A2*w2 <= b2],-sum(w1)-sum(w2),sdpsettings('verbose',0));
obj2 = value(-sum(w1)-sum(w2), sol2);

testCase.assertTrue(sol1.problem == 0);
testCase.assertTrue(abs(obj1+obj2) <= 1e-4)

function test2(testCase)
S = yalmip.Session();
% 2 balls
x = S.sdpvar(1);
w = S.sdpvar(3,1); 
q = S.sdpvar(2,1);
sol = optimize([x+sum(w)+sum(q)<=1,-1<=w<=3,uncertain(w),uncertain(q),q'*q<=2],-x,sdpsettings('verbose',0));
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(abs(value(x, sol)--10) <= 1e-5)

function test3(testCase)
S = yalmip.Session();
% 2 polytopic
x = S.sdpvar(1);
w = S.sdpvar(3,1); 
q = S.sdpvar(2,1);
sol = optimize([x+sum(w)+sum(q)<=1,-1<=w<=3,uncertain(w),uncertain(q),q'*q<=2,q>=0,w>=0],-x,sdpsettings('verbose',0));
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(abs(value(x, sol)--10) <= 1e-5)

function test4(testCase)
S = yalmip.Session();
% Messy with uncertain auxilliary variables
x = S.sdpvar(1);
w1 = S.sdpvar(1);
w2 = S.sdpvar(1);
t = S.sdpvar(1);
A = [1 1;-1 0;0 -2;-1 -1;0 -1/2];
b = [.1;.1;.1;.1;.1];
c = randn(2,1);
ops = sdpsettings('verbose',0,'robust.auxreduce','enumeration');
sol = optimize([x+max(x+c'*[w1;w2],norm([x*w1 + A*[w1;w2]],2))+norm([x - A*[w1;w2]],1)<=t,uncertain([w1;w2]),A*[w1;w2] <= b],t,ops)
o1 = value(t, sol);

v = [-.1 -.05 .15 -.1;
     0 -0.05 -0.05 0.2]';
C = [];
for i = 1:size(v,1)
C = [C,x+max(x+c'*v(i,:)',norm(x*v(i,1) + A*v(i,:)',2))+norm(x - A*v(i,:)',1)<=t];
end
optsol = optimize(C,t,sdpsettings('verbose',0));
o2 = value(t, optsol);
testCase.assertTrue(abs(o1-o2) <= 1e-5)


function test5(testCase)
S = yalmip.Session();
% Messy with uncertain auxilliary variables
x = S.sdpvar(1);
w1 = S.sdpvar(1);
w2 = S.sdpvar(1);
t = S.sdpvar(1);
A = [1 1;-1 0;0 -2;-1 -1;0 -1/2];
b = [.1;.1;.1;.1;.1];
c = randn(2,1);
ops = sdpsettings('verbose',1,'robust.auxreduce','enumeration');
sol = optimize([x+max(x+c'*[w1;w2],norm([x*w1 + A*[w1;w2]],1))+norm([x - A*[w1;w2]],1)<=t,uncertain([w1;w2]),A*[w1;w2] <= b],t,ops);
o1 = value(t, sol);

v = [-.1 -.05 .15 -.1;
     0 -0.05 -0.05 0.2]';
C = [];
for i = 1:size(v,1)
C = [C,x+max(x+c'*v(i,:)',norm(x*v(i,1) + A*v(i,:)',1))+norm(x - A*v(i,:)',1)<=t];
end
optsol = optimize(C,t,sdpsettings('verbose',0));
o2 = value(t, optsol);
testCase.assertTrue(abs(o1-o2) <= 1e-5)

function test6(testCase)
S = yalmip.Session();
% Should yield 27
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+norm(w+1,1) <= 30];
W = [uncertain(w),norm(w+.5,1) + norm(w,1)<=3];
ops = sdpsettings('verbose',0,'robust.auxreduce','enumeration');
sol = optimize([C,W],-x,ops);
testCase.assertTrue(abs(value(x, sol) - 27) <= 1e-5)

function test7(testCase)
S = yalmip.Session();
% Simple explicit maximization
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+w(1)+w(2) <= 1];
W = [uncertain(w),norm(w,1)<=2];
sol = optimize([C,W],-x,sdpsettings('verbose',0));
testCase.assertTrue(abs(value(x, sol)--1) <= 1e-5)

function test8(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+w(1)+w(2) <= 1];
W = [uncertain(w),norm(w,2)<=2];
sol = optimize([C,W],-x,sdpsettings('verbose',0));
testCase.assertTrue(abs(value(x, sol)--1.8284) <= 1e-2)

function test9(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+w(1)+w(2) <= 1];
W = [uncertain(w),norm(w,inf)<=2];
sol = optimize([C,W],-x,sdpsettings('verbose',0));
testCase.assertTrue(abs(value(x, sol)--3)<=1e-2)

function test10(testCase)
S = yalmip.Session();
% Missing term in explicit expression
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+2*w(2) <= 1];
W = [uncertain(w),norm(w,1)<=2];
sol = optimize([C,W],-x,sdpsettings('verbose',0));
testCase.assertTrue(abs(value(x, sol)--3)<=1e-5)

function test11(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+2*w(1) <= 1];
W = [uncertain(w),norm(w,2)<=2];
sol = optimize([C,W],-x,sdpsettings('verbose',0));
testCase.assertTrue(abs(value(x, sol)--3)<=1e-5)

function test12(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+2*w(1) <= 1];
W = [uncertain(w),norm(w,inf)<=2];
sol = optimize([C,W],-x,sdpsettings('verbose',0));
testCase.assertTrue(abs(value(x, sol)--3)<=1e-5)

function test13(testCase)
S = yalmip.Session();
% Enumeration of 6 vertices
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+norm(w,2) <= 1];
W = [uncertain(w),norm(w,1)<=2];
sol = optimize([C,W],-x,sdpsettings('verbose',1,'solver','sedumi'))
value(x, sol)
testCase.assertTrue((abs(value(x, sol)--1)<=1e-1) || (sol.problem == 4))

function test14(testCase)
S = yalmip.Session();
% Projection + explicit maximization
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+norm(w,1) <= 1];
W = [uncertain(w),norm(w,2)<=2];
sol = optimize([C,W],-x,sdpsettings('verbose',0,'robust.auxreduce','projection'));
testCase.assertTrue(abs(value(x, sol)--1.8284) <= 1e-3)

function test15(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+norm(w,2) <= 1];
W = [uncertain(w),norm(w,2)<=2];
sol = optimize([C,W],-x,sdpsettings('verbose',1,'robust.auxreduce','projection','sedumi.free',0));
testCase.assertTrue(abs(value(x, sol)--1) <= 1e-1)

function test16(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+norm(w,2)+norm(w,1) <= 1];
W = [uncertain(w),norm(w,2)+norm(w,1)<=2];
sol = optimize([C,W],-x,sdpsettings('verbose',0,'robust.auxreduce','projection','sedumi.free',0));
testCase.assertTrue(abs(value(x, sol)--1) <= 1e-1)

function test17(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
w = S.sdpvar(2,1);
C = [x+norm(w,1)+norm(w,2) <= 1];
W = [uncertain(w),norm(w,2)<=2];
sol = optimize([C,W],-x,sdpsettings('verbose',0,'robust.auxreduce','projection'));
testCase.assertTrue(abs(value(x, sol)--3.8284) <= 1e-1)

function test18(testCase)
S = yalmip.Session();
x = S.sdpvar(1);
w = S.sdpvar(1);
C = [1<=x<=4];
W = [uncertain(w),-10<=w<=2];
sol = optimize([C,W],x*w^2,sdpsettings('verbose',0));
testCase.assertTrue(sol.problem==1 | sol.problem == 12)

C = [1<=x<=4];
W = [uncertain(w),-10<=w<=2];
sol = optimize([C,W],x*w,sdpsettings('verbose',0));
testCase.assertTrue(abs(value(x, sol)-1)<=1e-1)