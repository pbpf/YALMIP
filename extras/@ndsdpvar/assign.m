function X = assign(X, value, sol)
%ASSIGN (overloaded) assign numeric values to an n-D SDPVAR

s = sdpvar(X);
s = assign(s, value, sol);
X = ndsdpvar(s);
