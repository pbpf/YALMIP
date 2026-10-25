function tests = test_logic_constraint_eq_1
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
a = S.binvar(1,1);
b = S.binvar(1,1);
x = S.intvar(1,1);
ops=sdpsettings('verbose',0);
F = [ a == (b & (x<=4.5)), -15 <= x <= 15];
sol = optimize(F,a^2,ops);
testCase.assertTrue(sol.problem == 0);
% Since a is 0, b has to be false or constraint violated
testCase.assertTrue(value(a, sol)==0 && (value(b, sol)==0 || value(x, sol)>=5));

F = true(or(0,a));
sol = optimize(F,a,ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(value(a, sol)==1);

F = true(and(0,a));
sol = optimize(F,a,ops);
testCase.assertTrue(sol.problem == 1);

F = true(xor(0,a));
sol = optimize(F,a,ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(value(a, sol)==1);

F = true(xor(1,a));
sol = optimize(F,-a,ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(value(a, sol)==0);

F = [ a == (b & (x<=4.5)), -15 <= x <= 15];
sol = optimize(F,x^2 + 1-b,ops);
testCase.assertTrue(value(a, sol)==1 && (value(b, sol)==1 || value(x, sol)==0));

dX = S.binvar(1);
dY = S.binvar(1);
sys = [iff(dX,a), iff(dY,[b & (x<=4.5)]), dX == dY];
F = [sys, -15 <= x <= 15];
sol = optimize(F,x^2 + 1-b,ops);
testCase.assertTrue(value(a, sol)==1 && (value(b, sol)==1 || value(x, sol)==0));

a = S.binvar(3,2);
b = S.binvar(3,2);
sol = optimize([b(1)==0, true(or(a,b))],sum(sum(a-b)),ops);
testCase.assertTrue(value(sum(sum(a-b)), sol)==-4);

optsol = optimize([b(1)==1, true(and(a,b))],sum(sum(a-b)),ops);
testCase.assertTrue(value(sum(sum(a-b)), optsol)==0);

optsol2 = optimize([b(1)==1, true(xor(a,b))],sum(sum(-a-b)),ops);
testCase.assertTrue(value(sum(sum(-a-b)), optsol2)==-6);

optsol3 = optimize([true(a & (~b))],sum(sum(a-b)),ops);
testCase.assertTrue(value(sum(sum(a-b)), optsol3)==6);

function test2(testCase)
S = yalmip.Session();
ops=sdpsettings('verbose',0);

x = S.binvar(1,1);
y = S.binvar(1,1);
sol = optimize(iff(x,y <= 0.5),2*x+y,ops);
testCase.assertTrue(abs(value(x, sol)) <= 1e-4);
testCase.assertTrue(abs(value(y, sol)-1)<= 1e-4);
optsol = optimize(iff(x,y <= 0.5),x+2*y,ops);
testCase.assertTrue(abs(value(x, optsol)-1) <= 1e-4);
testCase.assertTrue(abs(value(y, optsol)) <= 1e-4);

optsol2 = optimize(iff(x,y == 1),x+y,ops);
testCase.assertTrue(abs(value(x, optsol2))<=1e-4)
testCase.assertTrue(abs(value(y, optsol2))<=1e-4)

optsol3 = optimize(iff(x,y == 1),-2*x+y,ops);
testCase.assertTrue(abs(value(x, optsol3)-1) <= 1e-4);
testCase.assertTrue(abs(value(y, optsol3)-1)<= 1e-4);
optsol4 = optimize(iff(x,y == 1),x-2*y,ops);
testCase.assertTrue(abs(value(x, optsol4)-1) <= 1e-4);
testCase.assertTrue(abs(value(y, optsol4)-1)<= 1e-4);

optsol5 = optimize(iff(x,y == 0),x,ops);
testCase.assertTrue(abs(value(x, optsol5))<=1e-4)
testCase.assertTrue(abs(value(y, optsol5)-1)<= 1e-4);
optsol6 = optimize(iff(x,y == 0),y,ops);
testCase.assertTrue(abs(value(x, optsol6)-1) <= 1e-4);
testCase.assertTrue(abs(value(y, optsol6))<=1e-4)

optsol7 = optimize(iff(x,y == 0),2*x+y,ops);
testCase.assertTrue(abs(value(x, optsol7))<=1e-4)
testCase.assertTrue(abs(value(y, optsol7)-1)<= 1e-4);
optsol8 = optimize(iff(x,y == 0),x+2*y,ops);
testCase.assertTrue(abs(value(x, optsol8)-1)<=1e-4)
testCase.assertTrue(abs(value(y, optsol8))<=1e-4)

% Polytopic i.f.f binary equality
x = S.sdpvar(1,1);
y = S.binvar(1,1);
optsol9 = optimize([iff([-0.1 <= x <= 0.1],y == 1),-3<=x<=3],y,ops);
testCase.assertTrue(abs(value(x, optsol9))>.0999);
testCase.assertTrue(abs(value(y, optsol9)) <= 1e-3);
optsol10 = optimize([iff([-0.1 <= x <= 0.1],y == 1),-3<=x<=3],x^2,ops);
testCase.assertTrue(abs(value(x, optsol10))<=1e-3)
testCase.assertTrue(abs(value(y, optsol10)-1)<=1e-3)

optsol11 = optimize([iff([-0.1 <= x <= 0.1],y == 1),-3<=x<=3],200*x^2+y,ops);
testCase.assertTrue(abs(value(x, optsol11))<=1e-3)
testCase.assertTrue(abs(value(y, optsol11)-1)<=1e-3)

optsol12 = optimize([iff([-0.1 <= x <= 0.1],y == 1),-3<=x<=3],-x,ops);
testCase.assertTrue(abs(value(x, optsol12)-3)<=1e-3)
testCase.assertTrue(abs(value(y, optsol12))<=1e-3)

optsol13 = optimize([iff([-0.1 <= x <= 0.1],y == 1),-3<=x<=3],x,ops);
testCase.assertTrue(abs(value(x, optsol13)--3)<=1e-3)
testCase.assertTrue(abs(value(y, optsol13))<=1e-3)

optsol14 = optimize([iff([-0.1 <= x <= 0.1],y == 1),-3<=x<=3],x-y,ops);
testCase.assertTrue(abs(value(x, optsol14)--3)<=1e-3)
testCase.assertTrue(abs(value(y, optsol14))<=1e-3)


% Polytopic x equality iff binary
x = S.sdpvar(1,1);
y = S.binvar(1,1);
z = S.binvar(1,1);
optsol15 = optimize([iff([-0.1 <= x <= 0.1, z==1],y == 1),-3<=x<=3,-10<=z<=10],y,ops);
testCase.assertTrue(abs(value(y, optsol15))<=1e-3)
testCase.assertTrue(abs(value(z, optsol15))<=1e-3)

optsol16 = optimize([iff([-0.1 <= x <= 0.1, z==1],y == 1),-3 <= x <= 3,-10<=z<=10],-y,ops);
testCase.assertTrue(abs(value(y, optsol16)-1)<=1e-3)
testCase.assertTrue(abs(value(z, optsol16)-1)<=1e-3)

optsol17 = optimize([iff([-0.1 <= x <= 0.1, z==1],y == 1),-3 <= x <= 3,-10<=z<=10],x,ops);
testCase.assertTrue(abs(value(y, optsol17))<=1e-3)

optsol18 = optimize([iff([-0.1 <= x <= 0.1, z==1],y == 1),-3 <= x <= 3,-10<=z<=10],x-y,ops);
testCase.assertTrue(abs(value(y, optsol18))<=1e-3)
testCase.assertTrue(abs(value(x, optsol18)--3)<=1e-3)

optsol19 = optimize([iff([-0.1 <= x <= 0.1, z==1],y == 1),-3 <= x <= 3,-10<=z<=10],x-5*y,ops);
testCase.assertTrue(abs(value(y, optsol19)-1)<=1e-3)
testCase.assertTrue(abs(value(z, optsol19)-1)<=1e-3)

optsol20 = optimize([iff([x == 2, z==1],y == 1),-3 <= x <= 3,-10<=z<=10],-y,ops);
testCase.assertTrue(abs(value(y, optsol20)-1)<=1e-3)
testCase.assertTrue(abs(value(z, optsol20)-1)<=1e-3)
testCase.assertTrue(abs(value(x, optsol20)-2)<=1e-3)

optsol21 = optimize([iff([x == 2, z==1],y == 1),-3 <= x <= 3,-10<=z<=10],-z+x,ops);
testCase.assertTrue(abs(value(y, optsol21))<=1e-3)
testCase.assertTrue(abs(value(z, optsol21)-1)<=1e-3)
testCase.assertTrue(abs(value(x, optsol21)--3)<=1e-3)

optsol22 = optimize([iff([x == 2, z==1],y == 1),-3 <= x <= 3,-10<=z<=10],z,ops);
testCase.assertTrue(abs(value(y, optsol22))<=1e-3)
testCase.assertTrue(abs(value(z, optsol22))<=1e-3)

optsol23 = optimize([iff([x == 2, z==1],y == 1),-3 <= x <= 3,-10<=z<=10],z+x,ops);
testCase.assertTrue(abs(value(y, optsol23))<=1e-3)
testCase.assertTrue(abs(value(z, optsol23))<=1e-3)
testCase.assertTrue(abs(value(x, optsol23)--3)<=1e-3)

z = S.sdpvar(1,1);
optsol24 = optimize([iff([x <= 2, z >= 1],y == 1),-3 <= x <= 3,-10<=z<=10],z,ops);
testCase.assertTrue(abs(value(y, optsol24))<=1e-3)
testCase.assertTrue(abs(value(z, optsol24)--10)<=1e-3)

optsol25 = optimize([iff([x <= 2, z >= 1],y == 1),-3 <= x <= 3,-10<=z<=10],-z+x,ops);
testCase.assertTrue(abs(value(y, optsol25)-1)<=1e-3)
testCase.assertTrue(abs(value(z, optsol25)-10)<=1e-3)
testCase.assertTrue(abs(value(x, optsol25)--3)<=1e-3)

function test3(testCase)
S = yalmip.Session();
d1 = S.binvar(1,1);
d2 = S.binvar(1,1);
ops=sdpsettings('verbose',0);

sol =  optimize(~(d1==d2),d2,ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(abs(value(d1 + d2, sol)-1) <= 1e-3)

sol =  optimize((d1~=d2),d1+d2,ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(abs(value(d1 + d2, sol)-1) <= 1e-3)

sol =  optimize(iff(d1,d2),d1+d2,ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(abs(value(d1 + d2, sol)-0) <= 1e-3)

sol =  optimize(iff(d1,d2),d1,ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(abs(value(d2, sol)-0) <= 1e-3)

function test4(testCase)
S = yalmip.Session();
ops=sdpsettings('verbose',0);

x = S.binvar(1,1);
y = S.binvar(1,1);
sol = optimize([0 <= [x,y] <= 1, x+y~=1],(x+y-1)^2-10*x,ops);
testCase.assertTrue(abs(value(x, sol)-1) <= 1e-4)
testCase.assertTrue(abs(value(y, sol)-1) <= 1e-4)

x = S.binvar(1,1);
y = S.binvar(1,1);
optsol = optimize([0 <= [x,y] <= 1, x+y~=1],(x+y-1)^2,ops);
testCase.assertTrue(abs(value((x+y-1)^2, optsol)-1) <= 1e-4)

x1 = S.binvar(1,1);
y1 = S.binvar(1,1);
x2 = S.binvar(1,1);
y2 = S.binvar(1,1);
optsol2 = optimize([0 <= [x1,y1,x2,y2] <= 1, [x1;x2]'+[y1;y2]'~=1],(x1+y1-1)^2-10*x1+(x2+y2-1)^2-10*x2,ops);
testCase.assertTrue(abs(value(x1, optsol2)-1) <= 1e-4)
testCase.assertTrue(abs(value(y1, optsol2)-1) <= 1e-4)

function test5(testCase)
S = yalmip.Session();
ops=sdpsettings('verbose',0);

x = S.sdpvar(4,1);
sol = optimize((-10 <= x <= 10) + (nnz(x)==3),(x-2)'*(x-2),ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(norm(sort(value(x, sol))-sort([2;2;2;0])) < 1e-3)

sol = optimize((-10 <= x <= 10) + (nnz(x)<=3),(x-2)'*(x-2),ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(norm(sort(value(x, sol))-sort([2;2;2;0])) < 1e-3)

x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
z = S.sdpvar(1,1);
sol = optimize((200>=[x y z] >= -20) + (nnz([x;y;z] == 3) >= 2),2*x+y+z,ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(norm(value([x y z] - [-20 3 3], sol)) < 1e-3)


function test7(testCase)
S = yalmip.Session();
ops=sdpsettings('verbose',0);

aa = S.binvar(1,1);
ba = S.binvar(1,1);
ca = S.binvar(1,1);
da = S.binvar(1,1);
ea = S.binvar(1,1);
fa = S.binvar(1,1);
F = (true((aa & ba & ca) | (da & ea & fa)));
sol = optimize(F,[],ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue( all(value([aa ba ca], sol)== [1 1 1])  | all(value([da ea fa], sol)== [1 1 1]) )


function test8(testCase)
S = yalmip.Session();
ops=sdpsettings('verbose',0);

randn('seed',12345);
rand('seed',12345);

A1 = randn(8,2);
b1 = rand(8,1)*2-A1*[3;3];
A2 = randn(8,2);
b2 = rand(8,1)*2-A2*[-3;3];
A3 = randn(8,2);
b3 = rand(8,1)*2-A3*[3;-3];
A4 = randn(8,2);
b4 = rand(8,1)*2-A4*[-3;-3];

inp1 = S.binvar(1,1);
inp2 = S.binvar(1,1);
inp3 = S.binvar(1,1);
inp4 = S.binvar(1,1);
F = true(inp1 | inp2 | inp3 | inp4);
x = S.sdpvar(2,1);
F = F + (iff(inp1,A1*x <= b1));
F = F + (iff(inp2,A2*x <= b2));
F = F + (iff(inp3,A3*x <= b3));
F = F + (iff(inp4,A4*x <= b4));
F = F + (-100 <= x <= 100);
sol = optimize(F,-x(2),ops);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(norm(value(x, sol) - [1.89084694511033   4.32311245145436]') <= 1e-6)
testCase.assertTrue(norm(value([inp1 inp2 inp3 inp4], sol) - [0 0 0 1]) <= 1e-6)

F = true(inp1 | inp2 | inp3 | inp4);
F = F + (inp1 == (A1*x <= b1));
F = F + (inp2 == (A2*x <= b2));
F = F + (inp3 == (A3*x <= b3));
F = F + (inp4 == (A4*x <= b4));
F = F + (-100 <= x <= 100);
sol = optimize(F,-x(2),ops);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(norm(value(x, sol) - [1.89084694511033   4.32311245145436]') <= 1e-6)
testCase.assertTrue(norm(value([inp1 inp2 inp3 inp4], sol) - [0 0 0 1]) <= 1e-6)

F = true(inp1 | inp2 | inp3 | inp4);
F = F + (implies(inp1,A1*x <= b1));
F = F + (implies(inp2,A2*x <= b2));
F = F + (implies(inp3,A3*x <= b3));
F = F + (implies(inp4,A4*x <= b4));
F = F + (-100 <= x <= 100);
sol = optimize(F,-x(2),ops);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(norm(value(x, sol) - [1.89084694511033   4.32311245145436]') <= 1e-6)
testCase.assertTrue(norm(value([inp1 inp2 inp3 inp4], sol) - [0 0 0 1]) <= 1e-6)

F = ( (A1*x <= b1) | (A2*x <= b2) | (A3*x <= b3) | (A4*x <= b4));
F = F + (-100 <= x <= 100);
sol = optimize(F,-x(2),ops);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(norm(value(x, sol) - [1.89084694511033   4.32311245145436]') <= 1e-6)
testCase.assertTrue(norm(value([inp1 inp2 inp3 inp4], sol) - [0 0 0 1]) <= 1e-6)

x = S.sdpvar(2,1);
bounds(x,-100,100);
F = ( (A1*x <= b1) | (A2*x <= b2) | (A3*x <= b3) | (A4*x <= b4));
F = F + (-100 <= x <= 100);
sol = optimize(F,-x(2),ops);
testCase.assertTrue(sol.problem == 0)
testCase.assertTrue(norm(value(x, sol) - [1.89084694511033   4.32311245145436]') <= 1e-6)
testCase.assertTrue(norm(value([inp1 inp2 inp3 inp4], sol) - [0 0 0 1]) <= 1e-6)

ii = S.sdpvar(1,1);
jj = S.sdpvar(1,1);
x = S.sdpvar(1,8);
p = [0 1 7 2 3 4 3 20];
sol = optimize((-100 <= [x(:);ii;jj] <= 100) + (x == p)+(x([ii jj]) <= 3)+(ii~=jj),-ii-jj,ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(fix(min(value([ii jj], sol))) == [5]);
testCase.assertTrue(fix(max(value([ii jj], sol))) == [7]);



