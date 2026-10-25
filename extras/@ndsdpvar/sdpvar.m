function F = sdpvar(X)
% SDPVAR Converts a NDSDPVAR variable to standard SDPVAR

F = sdpvarFast(prod(X.dim),1,[],X.lmi_variables,X.basis,0,session(X));