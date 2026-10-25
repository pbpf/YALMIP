function tests = test_operator_implies
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

% Binary variable implies LP constriants
y = S.sdpvar(1,1);
u = S.sdpvar(1,1);
x = S.binvar(1,1);
sol = optimize([-10<=u<=10,implies(x,u>=3+2*x)],-x);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(x, sol)-1) <= 1e-4);
testCase.assertTrue(value(u, sol)>4.999);

function test2(testCase)
S = yalmip.Session();

% Binary variable implies LP constriants
y = S.sdpvar(1,1);
u = S.sdpvar(1,1);
x = S.binvar(1,1);
sol = optimize([-10<=u<=10,-6 <= y <= 6,implies(x,[u>=3+2*x, y >= u])],-x);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(x, sol)-1) <= 1e-4);
testCase.assertTrue(value(u, sol)>4.999);
testCase.assertTrue(value(y-u, sol)>-0.0001);

function test3(testCase)
S = yalmip.Session();

% Binary variable implies LP constriants
y = S.sdpvar(1,1);
u = S.sdpvar(1,1);
x = S.binvar(1,1);
sol = optimize([-10<=u<=10,-4 <= y <= 4,implies(x,[u>=3+2*x, y >= u])],-x);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(x, sol)-0) <= 1e-4);
testCase.assertTrue(value(u, sol)>=-10);
testCase.assertTrue(value(y, sol)>=-4);

function test4(testCase)
S = yalmip.Session();
x = S.binvar(1,1);
u = S.sdpvar(1,1);
y = S.sdpvar(1,1);
sol = optimize([-10<=u<=10,-4 <= y <= 4,implies(x,[u==3+2*x])],-x);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(x, sol)-1) <= 1e-4);
testCase.assertTrue(abs(value(u, sol)-5) <= 1e-4);

function test5(testCase)
S = yalmip.Session();
x = S.binvar(1,1);
u = S.sdpvar(1,1);
y = S.sdpvar(1,1);
sol = optimize([-10<=u<=10,-4 <= y <= 4,implies(x,[u==3+2*x, y >= 2])],-x);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(x, sol)-1) <= 1e-4);
testCase.assertTrue(abs(value(u, sol)-5) <= 1e-4);
testCase.assertTrue(value(y, sol)>=2);

function test6(testCase)
S = yalmip.Session();
x = S.binvar(1,1);
u = S.sdpvar(1,1);
y = S.sdpvar(1,1);
sol = optimize([-10<=u<=10,-4 <= y <= 4,implies(1-x, u==0.3),implies(x,[u==3+2*x, y >= 6])],-x);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(x, sol)-0) <= 1e-4);
testCase.assertTrue(abs(value(u, sol)-0.3) <= 1e-4);

function test7(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
u = S.sdpvar(1,1);
sol = optimize([-10<=u<=10,-1<=x<=1,implies(x>=0,u==-x),implies(x<=0,u==-2*x)],x);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(x, sol)--1) <= 1e-4);
testCase.assertTrue(abs(value(u, sol)-2) <= 1e-4);

function test8(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
u = S.sdpvar(1,1);
sol = optimize([-10<=u<=10,-1<=x<=1,implies(x>=0,u==-x),implies(x<=0,u==-2*x)],-x);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(x, sol)-1) <= 1e-4);
testCase.assertTrue(abs(value(u, sol)--1) <= 1e-4);

function test9(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
u = S.sdpvar(1,1);
sol = optimize([-.5<=u<=.5,-1<=x<=1,implies(x>=0,u==-x),implies(x<=0,u==-2*x)],-x);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(x, sol)-.5) <= 1e-4);
testCase.assertTrue(abs(value(u, sol)--.5) <= 1e-4);

function test11(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
u = S.sdpvar(1,1);
ops = sdpsettings;
x = S.sdpvar(2,1);
sol = optimize([-10<=u<=10,-1<=x<=1,implies(x>=0,u==-x(1)),implies(x<=0,u==-2*x(1))],(x+.1)'*(x+.1),ops)
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(u, sol)-.2) <= 1e-4);

sol = optimize([-10<=u<=10,-1<=x<=1,implies(x>=0,u==-x(1)),implies(x<=0,u==-2*x(1))],(x-.1)'*(x-.1),ops);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(abs(value(u, sol)--.1) <= 1e-4);

sol = optimize([-10<=u<=10,-1<=x<=1,implies(x>=0,u==-x(1)),implies(x<=0,u==-2*x(1))],(x-[.1;-.1])'*(x-[.1;-.1])+u^2,ops);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(norm(value(x, sol)-[.1;-0.1]) <= 1e-4);
testCase.assertTrue(abs(value(u, sol)-0) <= 1e-4);

function test12(testCase)
S = yalmip.Session();
ops = sdpsettings('quadprog.Algorithm','interior-point-convex');
x = S.sdpvar(2,1);
u = S.sdpvar(1);
sol = optimize([-10 <= [x;u] <= 10,implies(x==0.5,u == pi)],(x-.5)'*(x-.5),ops)
testCase.assertTrue(norm(value(x, sol)-.5) <= 1e-3);

optsol = optimize([-10 <= [x;u] <= 10,implies(x==0.5,u == 15,1e-3)],(x-.5)'*(x-.5),ops)
testCase.assertTrue(~any(abs(value(x, optsol)-0.5)>1e-3));


