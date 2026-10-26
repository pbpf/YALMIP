% YALMIP
% Version 26-June-2025
%
% Stateless architecture: all modelling state lives in a yalmip.Session object
% and symbolic objects carry a reference to it. See REFACTORING.md for the
% design and MIGRATION.md for the old-to-new API table.
%
%   S = yalmip.Session();
%   x = S.sdpvar("x",[3 1]);
%   sol = optimize(constraints, objective, sdpsettings);
%   v = value(x, sol)
%
% Help on http://yalmip.github.io
