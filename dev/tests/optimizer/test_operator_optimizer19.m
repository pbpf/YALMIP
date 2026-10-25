function tests = test_operator_optimizer19
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();
if 0
    x = S.sdpvar(1,1);
    a = S.sdpvar(1,1);
    b = S.sdpvar(1,1);
    c = S.sdpvar(1,1);
    y = S.sdpvar(1,1);
    optsol = optimize([0 <= [x y] <= 10, x + y <= 5],(x-3)^2+5*(y-4)^2,sdpsettings('verbose',0));
    sol = value([x y], optsol)
    testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);
end

x = S.sdpvar(1,1);
a = S.sdpvar(1,1);
b = S.sdpvar(1,1);
c = S.sdpvar(1,1);
y = S.sdpvar(1,1);
ops = sdpsettings('solver','gurobi,quadprog');
P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,sdpsettings('solver','gurobi,quadprog'),{a,b,c},[x y]);
PA = P{{3,[],[]}};
PB = PA{{4,[]}};
sol = PB{{5}}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);
PC = PB{{5},'nosolve'};
sol = PC{[]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);

P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,ops,{c,b,a},[x y]);
PC = P{{5,[],[]}};
PB = PC{{4,[]}};
sol = PB{{3}}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);
PA = PB{{3},'nosolve'};
sol = PA{[]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);

P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,ops,{b,c,a},[x y]);
PC = P{{[4],[],[]}};
PB = PC{{5,[]}};
sol = PB{{3}}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);
PA = PB{{3},'nosolve'};
sol = PA{[]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);

P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,ops,{a,c,b},[x y]);
PC = P{{[3],[],[]}};
PB = PC{{5,[]}};
sol = PB{{4}}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);
PA = PB{{4},'nosolve'};
sol = PA{[]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);

x = S.sdpvar(1,1);
b = S.sdpvar(1,1);
c = S.sdpvar(1,1);
y = S.sdpvar(1,1);
a = S.sdpvar(1,1);
P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,ops,{a,c,b},[x y]);
PC = P{{[3],[],[]}};
PB = PC{{5,[]}};
sol = PB{{4}}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);

PA = PB{{4},'nosolve'};
sol = PA{[]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);

b = S.sdpvar(1,1);
x = S.sdpvar(1,1);
c = S.sdpvar(1,1);
y = S.sdpvar(1,1);
a = S.sdpvar(1,1);
P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,ops,{a,c,b},[x y]);
PC = P{{[3],[],[]}};
PB = PC{{5,[]}};
PA = PB{{4}}
PA = PB{{4},'nosolve'};
sol = PA{[]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);


b = S.sdpvar(1,1);
x = S.sdpvar(1,1);
c = S.sdpvar(1,1);
y = S.sdpvar(1,1);
a = S.sdpvar(1,1);
P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,ops,{a,c,b},[x y]);
PC = P{{[3],[],[]}};
PB = PC{{5,[]}};
PA = PB{{4},'nosolve'};
sol = PA{[]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);


b = S.sdpvar(1,1);
x = S.sdpvar(1,1);
c = S.sdpvar(1,1);
y = S.sdpvar(1,1);
a = S.sdpvar(1,1);
P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,ops,{a,c,b},[x y]);
PC = P{{[3],[5],[]}};
PA = PC{{4},'nosolve'};
sol = PA{[]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);


b = S.sdpvar(1,1);
x = S.sdpvar(1,1);
c = S.sdpvar(1,1);
y = S.sdpvar(1,1);
a = S.sdpvar(1,1);
P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,ops,{a,c,b},[x y]);
PC = P{{[3],[],[]}};
PA = PC{{5,4},'nosolve'};
sol = PA{[]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);


b = S.sdpvar(1,1);
x = S.sdpvar(1,1);
c = S.sdpvar(1,1);
y = S.sdpvar(1,1);
a = S.sdpvar(1,1);
P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,ops,{a,c,b},[x y]);
PC = P{{[3],[5],[]}};
PA = PC{{4},'nosolve'};
sol = PA{[]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);


P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,ops,{a,c,b},[x y]);
PA = P{[a == 3]};
PB = PA{[b == 4]};
sol = PB{[c == 5]}

P = optimizer([0 <= [x y] <= 10, x + y <= c],(x-a)^2+5*(y-b)^2,ops,{a,c,b},[x y]);
PC = P{[c == 5]};
sol = PC{[a == 3, -b == -4]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);

x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
a = S.sdpvar(1,1);
b = S.sdpvar(1,1);
c = S.sdpvar(1,1);
ops = sdpsettings('solver','gurobi,quadprog');
P = optimizer([0 <= [x y] <= 10, x + y <= exp(c)],(x-a)^2+5*(y-exp(b))^2,ops,{a,b,c},[x y]);
PC = P{[a == 3]}
sol = PC{[c == log(5), b == log(4)]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);

x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
a = S.sdpvar(1,1);
b = S.sdpvar(1,1);
c = S.sdpvar(1,1);
ops = sdpsettings('solver','gurobi,quadprog');
P = optimizer([0 <= [x y] <= 10, x + y <= exp(c)],(x-a)^2+5*(y-exp(b))^2,ops,{a,b,c},[x y]);
PC = P{[a == 3,c == log(5)]}
sol = PC{[b == log(4)]}
testCase.assertTrue(norm(sol-[1 + 1/3;3 + 2/3]') <= 1e-2);