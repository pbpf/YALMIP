function tests = test_bnb_miexoticcones
tests = functiontests(localfunctions);

function test_miexoticcones(testCase)
S = yalmip.Session();
x = S.sdpvar(1,1);
y = S.sdpvar(1,1);
z = S.sdpvar(1,1);
sol = optimize([expcone([pi*x;y;z]),-5<=[x y]<=5, z<=10],-x-y-z,sdpsettings('solver','bnb','bnb.solver','fmincon'))
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(norm(value([x;y;z]-[1.1032;5;10], sol)) <= 1e-4);

x = S.intvar(1,1);
y = S.intvar(1,1);
z = S.intvar(1,1);
M = pcone([5*pi*x;y;z-1-x;z+2;0.7]);
ops = sdpsettings('solver','bnb','bnb.solver','fmincon');
sol = optimize([M,-5 <= y <= 5],-x+y,ops);
testCase.assertTrue(sol.problem == 0);
testCase.assertTrue(norm(value([x;y;z]-[9799;5;4899], sol)) <= 1e-4);

%% Interesting case (infeasible nodes)
if 0
    x = S.intvar(1,1);
    y = S.intvar(1,1);
    z = S.intvar(1,1);
    M = pcone([5*pi*x;y;z-1-x;z+2;0.7]);
    ops = sdpsettings('solver','bnb','bnb.solver','knitro','verbose',1);
    sol = optimize([M,-5 <= y <= 5,[200 x;x 1]>=0],-x+y,ops);
    testCase.assertTrue(sol.problem == 0);
    testCase.assertTrue(norm(value([x;y;z]-[9799;5;4899], sol)) <= 1e-4);
end