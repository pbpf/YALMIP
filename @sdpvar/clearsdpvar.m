function clearsdpvar(X,value)
% CLEARSDPVAR Clear solution

S = X.sess;
sol = S.getsolution();
x_lmi_variables = X.lmi_variables;
keep_these = find(~ismember(sol.variables,x_lmi_variables));
sol.optvar = [sol.optvar(keep_these)];
sol.variables = [sol.variables(keep_these)];
S.setallsolution(sol);




