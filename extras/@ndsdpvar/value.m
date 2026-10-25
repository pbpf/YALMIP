function X = value(X, sol)
% VALUE (overloaded) evaluate an n-D SDPVAR at a solution payload

X = reshape(value(sdpvar(X), sol), X.dim);
