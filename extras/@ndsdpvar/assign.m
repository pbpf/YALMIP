function sol = assign(x, y, sol)
%ASSIGN (overloaded) assign numeric values to an n-D SDPVAR
%
%   Returns the updated solution payload (stateless refactor).

sol = assign(sdpvar(x), y(:), sol);
