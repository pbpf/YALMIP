function tests = test_chance
tests = functiontests(localfunctions);

function test1(testCase)
S = yalmip.Session();

testCase.assertTrue(true)
return

a=S.sdpvar(1,1);
t = S.sdpvar(1,1);

Model = [probability(a >= t) >= 0.5,uncertain(a,'normal',[0],eye(1))];
sol = optimize(derandomize(Model),-t)
mbg_asserttolequal(value(t, sol), 0, 1e-5);

Model = [probability(a >= t) >= 0.5,uncertain(a,'normalf',[0],eye(1))];
optsol = optimize(derandomize(Model),-t)
mbg_asserttolequal(value(t, optsol), 0, 1e-5);

Model = [probability(a >= t) >= 0.95,uncertain(a,'normal',[0],4)];
optsol2 = optimize(derandomize(Model),-t)
mbg_asserttolequal(value(t, optsol2), -3.2897, 1e-5);

Model = [probability(a >= t) >= 0.95,uncertain(a,'normalf',[0],2)];
optsol3 = optimize(derandomize(Model),-t)
mbg_asserttolequal(value(t, optsol3), -3.2897, 1e-5);

% worst case should be R = 1
R = S.sdpvar(1,1);
Model = [probability(a >= t) >= 0.95,uncertain(a,'normalf',[0],1+R)];
Model = [Model, uncertain(R),0<=R<=1];
optsol4 = optimize(derandomize(Model),-t)
mbg_asserttolequal(value(t, optsol4), -3.2897, 1e-4);
