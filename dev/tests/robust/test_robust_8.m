function tests = test_robust_8
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

ops = sdpsettings('verbose',0);

n = 3;
r = 4;
m = 4;

x = S.sdpvar(n,1);
w = S.sdpvar(m,1);
t = S.sdpvar(1,1);

A = randn(r,n);
b = randn(r,1);
C = randn(r,m);

A1 = randn(2*r,m/2);
A2 = randn(2*r,m/2);
b1 = rand(2*r,1)*5;
b2 = rand(2*r,1)*5;

[xc,R] = chebyball(A1*w(1:m/2) <= b1);
while isinf(R) | R==0
    A1 = randn(2*r,m/2);
    b1 = rand(2*r,1)*5;
    [xc,R] = chebyball(A1*w(1:m/2) <= b1);
end
[xc,R] = chebyball(A2*w(m/2+1:m) <= b2);
while isinf(R) | R==0
    A2 = randn(2*r,m/2);
    b2 = rand(2*r,1)*5;
    [xc,R] = chebyball(A2*w(m/2+1:end) <= b2);
end

% Exact automatic
objective = norm(A*x + b + C*w,1);
model = [uncertain(w), A1*w(1:m/2)<=b1, A2*w(m/2+1:m)<=b2];
[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','none'));
sol = optimize(F1,h,ops) ;
o1 = value(t, sol);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','affine'));
optsol = optimize(F1,h,ops) ;
o2 = value(t, optsol);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','projection','robust.lplp','enumeration'));
optsol2 = optimize(F1,h,ops) ;
o3 = value(t, optsol2);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','projection','robust.lplp','duality'));
optsol3 = optimize(F1,h,ops) ;
o4 = value(t, optsol3);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','enumeration'));
optsol4 = optimize(F1,h,ops) ;
o5 = value(t, optsol4);


testCase.assertTrue(abs(o4-o5) <= 1e-4);
testCase.assertTrue(abs(o3-o5) <= 1e-4);
testCase.assertTrue(o2<o1);
testCase.assertTrue(o3<o1);


% Exact automatic
model = [uncertain(w), norm(w,1) <= 1];
[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','none'));
optsol5 = optimize(F1,h,ops) ;
o1 = value(t, optsol5);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','affine'));
optsol6 = optimize(F1,h,ops) ;
o2 = value(t, optsol6);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','projection','robust.lplp','enumeration'));
optsol7 = optimize(F1,h,ops) ;
o3 = value(t, optsol7);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','projection','robust.lplp','duality'));
optsol8 = optimize(F1,h,ops) ;
o4 = value(t, optsol8);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','enumeration'));
optsol9 = optimize(F1,h,ops) ;
o5 = value(t, optsol9);


testCase.assertTrue(abs(o4-o5) <= 1e-5);
testCase.assertTrue(abs(o3-o5) <= 1e-5);
testCase.assertTrue(o2<o1);
testCase.assertTrue(o3<o1);


% Exact automatic
model = [uncertain(w), norm(w,1)+norm(w,1) <= 1];
[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','none'));
optsol10 = optimize(F1,h,ops) ;
o1 = value(t, optsol10);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','affine'));
optsol11 = optimize(F1,h,ops) ;
o2 = value(t, optsol11);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','projection','robust.lplp','enumeration'));
optsol12 = optimize(F1,h,ops) ;
o3 = value(t, optsol12);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','projection','robust.lplp','duality'));
optsol13 = optimize(F1,h,ops) ;
o4 = value(t, optsol13);

[F1,h] = robustify([model,objective <= t],t,sdpsettings('verbose',0,'robust.auxreduce','enumeration'));
optsol14 = optimize(F1,h,ops) ;
o5 = value(t, optsol14);

testCase.assertTrue(abs(o4-o5) <= 1e-5);
testCase.assertTrue(abs(o3-o5) <= 1e-5);
testCase.assertTrue(o2<o1);
testCase.assertTrue(o3<o1);
